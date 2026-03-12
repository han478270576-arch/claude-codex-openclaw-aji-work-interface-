const agentName = document.querySelector("#agentName");
const agentLead = document.querySelector("#agentLead");
const agentBadge = document.querySelector("#agentBadge");
const agentTitle = document.querySelector("#agentTitle");
const agentHandle = document.querySelector("#agentHandle");
const agentSummary = document.querySelector("#agentSummary");
const agentSkills = document.querySelector("#agentSkills");
const sessionKeyNode = document.querySelector("#sessionKey");
const tokenStateNode = document.querySelector("#tokenState");
const routeAgentNode = document.querySelector("#routeAgent");
const routeSessionNode = document.querySelector("#routeSession");
const routeUrlNode = document.querySelector("#routeUrl");
const warningBox = document.querySelector("#warningBox");
const openFullChat = document.querySelector("#openFullChat");
const jumpButton = document.querySelector("#jumpButton");

const params = new URLSearchParams(window.location.search);
const requestedAgentId = params.get("agent") || "aji-master";
const explicitToken = params.get("token");

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

function showWarning(message) {
  warningBox.hidden = false;
  warningBox.textContent = message;
}

function readControlSettings() {
  try {
    const raw = window.localStorage.getItem("openclaw.control.settings.v1");
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function hasPairedDevice() {
  return Boolean(window.localStorage.getItem("openclaw-device-identity-v1"));
}

function hasDeviceAuthToken() {
  return Boolean(window.localStorage.getItem("openclaw.device.auth.v1"));
}

function buildSessionKey(agentId) {
  return `agent:${agentId}:main`;
}

function buildChatUrl(sessionKey, token) {
  const query = new URLSearchParams({ session: sessionKey });
  if (token) {
    query.set("token", token);
  }
  return `/chat?${query.toString()}`;
}

function renderAgent(agent, sessionKey, chatUrl, token) {
  const lane = laneCopy[agent.lane] || agent.lane;
  const badgeText = `${agent.group === "core" ? "Core Lane" : "Team Lane"} · ${lane}`;

  agentName.textContent = `${agent.name} · 龙虾聊天壳`;
  agentLead.textContent =
    `当前会话已锁定到 ${agent.handle}。你在这个页面里看的仍然是官方 OpenClaw Chat，` +
    `但会话键已经切到 ${sessionKey}，因此聊天会直接落在该 agent 的主会话里。`;
  agentBadge.textContent = badgeText;
  agentBadge.className = `detail-badge accent-${agent.accent}`;

  agentTitle.textContent = `${agent.name} · ${agent.title}`;
  agentHandle.textContent = `${agent.handle} · ${lane}`;
  agentSummary.textContent = agent.summary;

  agentSkills.innerHTML = "";
  agent.specialties.forEach((skill) => {
    const li = document.createElement("li");
    li.textContent = skill;
    agentSkills.append(li);
  });

  sessionKeyNode.textContent = `session: ${sessionKey}`;
  tokenStateNode.textContent = token ? "token: ready" : "token: not found";
  routeAgentNode.textContent = agent.id;
  routeSessionNode.textContent = sessionKey;
  routeUrlNode.textContent = chatUrl;
  openFullChat.href = chatUrl;
  jumpButton.href = chatUrl;
}

async function loadAgents() {
  const response = await fetch("./agents.json", { cache: "no-store" });
  if (!response.ok) {
    throw new Error(`Failed to load agents.json: ${response.status}`);
  }
  return response.json();
}

async function boot() {
  try {
    const registry = await loadAgents();
    const agent = registry.find((item) => item.id === requestedAgentId) || registry[0];

    if (!agent) {
      throw new Error("No agent found in registry.");
    }

    const settings = readControlSettings();
    const token = explicitToken || settings.token || "";
    const sessionKey = buildSessionKey(agent.id);
    const chatUrl = buildChatUrl(sessionKey, token);

    renderAgent(agent, sessionKey, chatUrl, token);

    if (!token) {
      showWarning("当前页面没读到 token。测试环境现在已经放宽设备认证，但仍建议从带 token 的入口进入。");
      return;
    }

    if (!hasPairedDevice() || !hasDeviceAuthToken()) {
      showWarning("测试环境已放宽设备认证，当前将直接跳转到官方 Chat。生产环境仍建议保留配对。");
    }

    window.setTimeout(() => {
      window.location.href = chatUrl;
    }, 350);
  } catch (error) {
    showWarning(error instanceof Error ? error.message : String(error));
    agentName.textContent = "Agent Chat Unavailable";
  }
}

boot();
