(function () {
  const VIEW_PARAM = "view";
  const VIEW_VALUE = "aji-console";
  const SECTION_PARAM = "ajiSection";
  const DEFAULT_SECTION = "agents";
  const CONTROL_GROUP_LABELS = ["控制", "Control"];
  const FALLBACK_ITEM_LABELS = ["代理人", "Agents", "技能", "Skills", "节点", "Nodes"];
  const SECTION_CONFIG = {
    agents: {
      label: "Agents",
      title: "代理人总控台",
      subtitle: "浏览核心分身与团队 Agent，并进入对应的统一门户。",
      iframePath: "/lobster/"
    },
    skills: {
      label: "Skills",
      title: "技能任务面板",
      subtitle: "查看技能目录、技能状态与后续的 skill -> agent 集成入口。",
      iframePath: "/lobster/skills/"
    }
  };

  function getApp() {
    return document.querySelector("openclaw-app");
  }

  function readControlSettings() {
    try {
      const raw = window.localStorage.getItem("openclaw.control.settings.v1");
      return raw ? JSON.parse(raw) : {};
    } catch {
      return {};
    }
  }

  function getToken() {
    const url = new URL(window.location.href);
    const settings = readControlSettings();
    return url.searchParams.get("token") || settings.token || "";
  }

  function getSection() {
    const url = new URL(window.location.href);
    const section = url.searchParams.get(SECTION_PARAM);
    return section && SECTION_CONFIG[section] ? section : DEFAULT_SECTION;
  }

  function isConsoleView() {
    const url = new URL(window.location.href);
    return url.searchParams.get(VIEW_PARAM) === VIEW_VALUE;
  }

  function setConsoleView(enabled, section, replace) {
    const url = new URL(window.location.href);
    if (enabled) {
      url.searchParams.set(VIEW_PARAM, VIEW_VALUE);
      url.searchParams.set(SECTION_PARAM, section && SECTION_CONFIG[section] ? section : DEFAULT_SECTION);
    } else {
      url.searchParams.delete(VIEW_PARAM);
      url.searchParams.delete(SECTION_PARAM);
    }
    window.history[replace ? "replaceState" : "pushState"]({}, "", url.toString());
  }

  function buildIframeUrl(section) {
    const config = SECTION_CONFIG[section] || SECTION_CONFIG[DEFAULT_SECTION];
    const url = new URL(config.iframePath, window.location.origin);
    const token = getToken();
    if (token) {
      url.searchParams.set("token", token);
    }
    return url.toString();
  }

  function queueSync(app) {
    if (!app || app.__ajiConsoleNavQueued) return;
    app.__ajiConsoleNavQueued = true;
    queueMicrotask(function () {
      app.__ajiConsoleNavQueued = false;
      syncConsole(app);
    });
  }

  function findControlGroup(app) {
    const groups = app.querySelectorAll(".nav-group");
    for (const group of groups) {
      const label = group.querySelector(".nav-label__text");
      const text = label && label.textContent ? label.textContent.trim() : "";
      if (CONTROL_GROUP_LABELS.includes(text)) {
        return group;
      }
    }

    for (const group of groups) {
      const items = group.querySelectorAll(".nav-item__text");
      const texts = Array.from(items, function (item) {
        return item.textContent ? item.textContent.trim() : "";
      });
      if (texts.some(function (text) { return FALLBACK_ITEM_LABELS.includes(text); })) {
        return group;
      }
    }

    return null;
  }

  function hideLegacyAjiNav(app) {
    app.querySelectorAll('[data-aji-nav="true"]').forEach(function (node) {
      node.style.display = "none";
    });
  }

  function bindBuiltInNavClear(app) {
    if (app.__ajiConsoleClearBound) return;
    app.__ajiConsoleClearBound = true;
    app.addEventListener("click", function (event) {
      const item = event.target && event.target.closest ? event.target.closest(".nav-item") : null;
      if (!item || item.getAttribute("data-aji-console-nav") === "true") {
        return;
      }
      window.setTimeout(function () {
        if (isConsoleView()) {
          setConsoleView(false, DEFAULT_SECTION, true);
        }
        queueSync(app);
      }, 0);
    });
  }

  function ensureNav(app) {
    const group = findControlGroup(app);
    if (!group) return null;

    const items = group.querySelector(".nav-group__items");
    if (!items) return null;

    let nav = items.querySelector('[data-aji-console-nav="true"]');
    if (!nav) {
      nav = document.createElement("a");
      nav.className = "nav-item nav-item--aji-console";
      nav.setAttribute("data-aji-console-nav", "true");
      nav.innerHTML =
        '<span class="nav-item__icon aji-console-icon" aria-hidden="true">🦞</span>' +
        '<span class="nav-item__text">阿吉控制台</span>';
      nav.addEventListener("click", function (event) {
        event.preventDefault();
        setConsoleView(true, getSection(), false);
        queueSync(app);
      });
      items.appendChild(nav);
    }

    nav.classList.toggle("active", isConsoleView());
    nav.setAttribute("href", buildIframeUrl(getSection()));
    nav.setAttribute("title", "进入阿吉控制台");
    return nav;
  }

  function ensurePanel(app) {
    const content = app.querySelector(".content");
    if (!content) return null;

    let panel = content.querySelector(".aji-console-panel");
    if (!panel) {
      panel = document.createElement("section");
      panel.className = "aji-console-panel card";
      content.appendChild(panel);
    }
    return panel;
  }

  function renderPanel(section) {
    const config = SECTION_CONFIG[section] || SECTION_CONFIG[DEFAULT_SECTION];
    const tokenHint = getToken()
      ? '<span class="aji-console-chip"><strong>已带 token</strong><span>统一门户将沿用当前测试环境认证</span></span>'
      : '<span class="aji-console-chip aji-console-chip--warn"><strong>未检测到 token</strong><span>门户能打开，但聊天和技能动作可能受限</span></span>';

    const tabs = Object.entries(SECTION_CONFIG).map(function ([id, item]) {
      const active = id === section ? " is-active" : "";
      return (
        '<button class="aji-console-tab' + active + '" type="button" data-aji-console-section="' + id + '">' +
        item.label +
        "</button>"
      );
    }).join("");

    return (
      '<div class="aji-console-panel__hero">' +
      '<div>' +
      '<p class="aji-console-panel__eyebrow">Aji Unified Console</p>' +
      '<h2 class="aji-console-panel__title">阿吉控制台</h2>' +
      '<p class="aji-console-panel__subtitle">现在它作为 OpenClaw 官方 Control UI 的一级内页存在。左侧入口固定挂在“控制”分组下，主内容区直接承载你的统一门户。</p>' +
      "</div>" +
      '<div class="aji-console-panel__status">' +
      '<span class="aji-console-chip"><strong>当前模块</strong><span>' + config.label + "</span></span>" +
      tokenHint +
      "</div>" +
      "</div>" +
      '<div class="aji-console-panel__body">' +
      '<div class="aji-console-tabs" role="tablist" aria-label="Aji console sections">' + tabs + "</div>" +
      '<div class="aji-console-frame-head">' +
      '<div><h3>' + config.title + '</h3><p>' + config.subtitle + '</p></div>' +
      '<a class="aji-console-open" href="' + buildIframeUrl(section) + '" target="_blank" rel="noreferrer">新窗口打开</a>' +
      "</div>" +
      '<div class="aji-console-frame-wrap">' +
      '<iframe class="aji-console-frame" src="' + buildIframeUrl(section) + '" title="Aji Console ' + config.label + '" loading="lazy"></iframe>' +
      "</div>" +
      "</div>"
    );
  }

  function bindPanelEvents(app, panel) {
    if (panel.__ajiConsoleBound) return;
    panel.__ajiConsoleBound = true;
    panel.addEventListener("click", function (event) {
      const tab = event.target && event.target.closest ? event.target.closest("[data-aji-console-section]") : null;
      if (!tab) return;
      const section = tab.getAttribute("data-aji-console-section");
      if (!SECTION_CONFIG[section]) return;
      setConsoleView(true, section, false);
      queueSync(app);
    });
  }

  function syncHeader(app, active) {
    const title = app.querySelector(".page-title");
    const subtitle = app.querySelector(".page-sub");
    if (!title || !subtitle) return;
    if (active) {
      title.textContent = "阿吉控制台";
      subtitle.textContent = "统一门户已集成为官方 Control UI 一级内页。";
    }
  }

  function syncConsole(app) {
    if (!app) return;

    hideLegacyAjiNav(app);
    bindBuiltInNavClear(app);
    ensureNav(app);

    const panel = ensurePanel(app);
    const content = app.querySelector(".content");
    if (!panel || !content) return;

    const active = isConsoleView();
    content.classList.toggle("content--aji-console-view", active);
    panel.hidden = !active;

    if (!active) return;

    syncHeader(app, true);
    panel.innerHTML = renderPanel(getSection());
    bindPanelEvents(app, panel);
  }

  function install() {
    const app = getApp();
    if (app) queueSync(app);

    customElements.whenDefined("openclaw-app").then(function () {
      const ctor = customElements.get("openclaw-app");
      if (!ctor || ctor.prototype.__ajiConsoleNavInstalled) return;
      ctor.prototype.__ajiConsoleNavInstalled = true;

      const originalUpdated = ctor.prototype.updated;
      ctor.prototype.updated = function updatedPatched(changed) {
        const result = originalUpdated ? originalUpdated.call(this, changed) : undefined;
        queueSync(this);
        return result;
      };

      const originalFirstUpdated = ctor.prototype.firstUpdated;
      ctor.prototype.firstUpdated = function firstUpdatedPatched() {
        const result = originalFirstUpdated ? originalFirstUpdated.apply(this, arguments) : undefined;
        queueSync(this);
        return result;
      };

      const existing = getApp();
      if (existing) queueSync(existing);
    });

    window.addEventListener("popstate", function () {
      const current = getApp();
      if (current) queueSync(current);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", install, { once: true });
  } else {
    install();
  }
})();
