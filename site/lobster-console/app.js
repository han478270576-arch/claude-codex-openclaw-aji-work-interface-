const searchInput = document.querySelector("#searchInput");
const resultCount = document.querySelector("#resultCount");
const agentGrid = document.querySelector("#agentGrid");
const template = document.querySelector("#agentCardTemplate");
const filterChips = Array.from(document.querySelectorAll(".filter-chip"));

const detailName = document.querySelector("#detailName");
const detailSubtitle = document.querySelector("#detailSubtitle");
const detailSummary = document.querySelector("#detailSummary");
const detailSkills = document.querySelector("#detailSkills");
const detailSource = document.querySelector("#detailSource");
const detailBadge = document.querySelector("#detailBadge");
const detailRoute = document.querySelector("#detailRoute");
const chatButton = document.querySelector("#chatButton");

let registry = [];
let currentFilter = "all";
let selectedId = null;
const params = new URLSearchParams(window.location.search);

const laneCopy = {
  orchestration: "主控与编排",
  engineering: "工程研发",
  markets: "金融分析",
  intelligence: "情报研究",
  strategy: "团队策略",
  delivery: "交付实现",
  business: "业务分析",
  research: "研究支持"
};

const stateCopy = {
  ready: "Core Ready",
  "team-ready": "Team Ready"
};

function readControlSettings() {
  try {
    const raw = window.localStorage.getItem("openclaw.control.settings.v1");
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function persistControlSettings() {
  const token = params.get("token");
  if (!token) return;

  const current = readControlSettings();
  const next = {
    ...current,
    token,
    gatewayUrl: current.gatewayUrl || `${window.location.protocol === "https:" ? "wss" : "ws"}://${window.location.host}`,
    baseUrl: current.baseUrl || window.location.origin
  };

  window.localStorage.setItem("openclaw.control.settings.v1", JSON.stringify(next));
}

function getEffectiveToken() {
  const settings = readControlSettings();
  return params.get("token") || settings.token || "";
}

function buildPortalUrl(path) {
  const url = new URL(path, window.location.href);
  const token = getEffectiveToken();
  if (token) {
    url.searchParams.set("token", token);
  }
  return url.toString();
}

function initPortalNav() {
  document.querySelector("#portal-home-link").href = buildPortalUrl("./");
  document.querySelector("#nav-agents-link").href = buildPortalUrl("./");
  document.querySelector("#nav-skills-link").href = buildPortalUrl("./skills/");
  document.querySelector("#nav-chat-link").href = buildPortalUrl("../chat?session=main");
  document.querySelector("#moduleAgentsLink").href = buildPortalUrl("./");
  document.querySelector("#moduleSkillsLink").href = buildPortalUrl("./skills/");
  document.querySelector("#moduleChatLink").href = buildPortalUrl("../chat?session=main");
  document.querySelector("#token-banner").hidden = Boolean(getEffectiveToken());
}

function buildChatHref(agentId) {
  const query = new URLSearchParams({ agent: agentId });
  const token = getEffectiveToken();
  if (token) {
    query.set("token", token);
  }
  return `./chat.html?${query.toString()}`;
}

async function loadRegistry() {
  const response = await fetch("./agents.json", { cache: "no-store" });
  if (!response.ok) {
    throw new Error(`Failed to load registry: ${response.status}`);
  }
  registry = await response.json();
  selectedId = registry[0]?.id ?? null;
  render();
}

function matches(agent, query) {
  const haystack = [
    agent.name,
    agent.title,
    agent.handle,
    agent.group,
    agent.lane,
    agent.summary,
    ...(agent.specialties || [])
  ]
    .join(" ")
    .toLowerCase();
  return haystack.includes(query);
}

function getFilteredAgents() {
  const query = searchInput.value.trim().toLowerCase();
  return registry.filter((agent) => {
    const groupOk = currentFilter === "all" ? true : agent.group === currentFilter;
    const queryOk = query ? matches(agent, query) : true;
    return groupOk && queryOk;
  });
}

function render() {
  const filtered = getFilteredAgents();
  resultCount.textContent = `${filtered.length} agents online in registry`;

  if (!filtered.some((agent) => agent.id === selectedId)) {
    selectedId = filtered[0]?.id ?? null;
  }

  renderGrid(filtered);
  renderDetail(filtered.find((agent) => agent.id === selectedId) || registry[0] || null);
}

function renderGrid(agents) {
  agentGrid.innerHTML = "";

  if (!agents.length) {
    const empty = document.createElement("div");
    empty.className = "empty-state";
    empty.textContent = "当前筛选结果为空。试试切换分组，或减少搜索关键词。";
    agentGrid.append(empty);
    return;
  }

  agents.forEach((agent) => {
    const fragment = template.content.cloneNode(true);
    const card = fragment.querySelector(".agent-hit");
    const article = fragment.querySelector(".agent-card");
    const icon = fragment.querySelector(".agent-icon");
    const state = fragment.querySelector(".agent-state");
    const group = fragment.querySelector(".agent-group");
    const title = fragment.querySelector(".agent-title");
    const handle = fragment.querySelector(".agent-handle");
    const summary = fragment.querySelector(".agent-summary");
    const skills = fragment.querySelector(".agent-skills");

    article.dataset.agentId = agent.id;
    card.classList.toggle("is-selected", agent.id === selectedId);
    article.classList.add(`accent-${agent.accent}`);
    card.classList.add(`accent-${agent.accent}`);

    icon.textContent = agent.icon;
    state.textContent = stateCopy[agent.state] || agent.state;
    group.textContent = `${agent.group.toUpperCase()} · ${laneCopy[agent.lane] || agent.lane}`;
    title.textContent = `${agent.name} · ${agent.title}`;
    handle.textContent = agent.handle;
    summary.textContent = agent.summary;

    agent.specialties.slice(0, 3).forEach((skill) => {
      const li = document.createElement("li");
      li.textContent = skill;
      skills.append(li);
    });

    card.addEventListener("click", () => {
      selectedId = agent.id;
      render();
    });

    agentGrid.append(fragment);
  });
}

function renderDetail(agent) {
  if (!agent) {
    detailName.textContent = "没有可显示的 Agent";
    return;
  }

  detailName.textContent = `${agent.name} · ${agent.title}`;
  detailSubtitle.textContent = `${agent.handle} · ${laneCopy[agent.lane] || agent.lane}`;
  detailSummary.textContent = agent.summary;
  detailSource.textContent = agent.promptSource;
  detailBadge.textContent = `${agent.group === "core" ? "Core Lane" : "Team Lane"} · ${stateCopy[agent.state] || agent.state}`;
  detailBadge.className = `detail-badge accent-${agent.accent}`;
  const chatHref = buildChatHref(agent.id);
  detailRoute.href = chatHref;
  detailRoute.textContent = tokenPreview(chatHref);
  chatButton.href = chatHref;
  chatButton.textContent = `进入 ${agent.handle} 聊天页`;

  detailSkills.innerHTML = "";
  agent.specialties.forEach((skill) => {
    const li = document.createElement("li");
    li.textContent = skill;
    detailSkills.append(li);
  });
}

filterChips.forEach((chip) => {
  chip.addEventListener("click", () => {
    currentFilter = chip.dataset.filter;
    filterChips.forEach((item) => item.classList.toggle("is-active", item === chip));
    render();
  });
});

searchInput.addEventListener("input", render);

function tokenPreview(href) {
  return href.includes("&token=")
    ? `已附带 token · ${href.replace(/([?&]token=)[^&]+/, "$1***")}`
    : `未检测到 token · ${href}`;
}

persistControlSettings();
initPortalNav();

loadRegistry().catch((error) => {
  resultCount.textContent = "registry load failed";
  agentGrid.innerHTML = `<div class=\"empty-state\">${error.message}</div>`;
});
