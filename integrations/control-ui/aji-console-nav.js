(function () {
  const CONTROL_GROUP_LABELS = ["控制", "Control"];
  const FALLBACK_ITEM_LABELS = ["代理人", "Agents", "技能", "Skills", "节点", "Nodes"];

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

  function buildConsoleUrl() {
    const url = new URL("/lobster/", window.location.origin);
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
      syncNav(app);
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

  function syncNav(app) {
    const group = findControlGroup(app);
    if (!group) return;

    const items = group.querySelector(".nav-group__items");
    if (!items) return;

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
        window.location.assign(buildConsoleUrl());
      });
      items.appendChild(nav);
    }

    nav.setAttribute("href", buildConsoleUrl());
    nav.setAttribute("title", "进入阿吉统一门户");
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
