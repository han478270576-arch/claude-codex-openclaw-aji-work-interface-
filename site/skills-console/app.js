const API_BASE = "/skills/api";

let SKILLS_DATA = { skills: [], categories: {} };
let SKILL_STATUS = {};
let currentCat = "all";
let currentSearch = "";
let currentDetailId = null;
let toastTimer = null;
let confirmResolve = null;

function readControlSettings() {
  try {
    const raw = window.localStorage.getItem("openclaw.control.settings.v1");
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function getApiToken() {
  const params = new URLSearchParams(window.location.search);
  const settings = readControlSettings();
  return params.get("token") || settings.token || "";
}

const API_TOKEN = getApiToken();

const ParticleEngine = (() => {
  const canvas = document.getElementById("particles");
  const ctx = canvas.getContext("2d");
  let particles = [];
  let mouse = { x: -1000, y: -1000 };
  let width;
  let height;
  const PARTICLE_COUNT = 120;
  const MAX_DIST = 130;
  const MOUSE_RADIUS = 180;
  let frameCount = 0;
  let lastFpsTime = performance.now();

  class Particle {
    constructor() {
      this.reset();
    }

    reset() {
      this.x = Math.random() * width;
      this.y = Math.random() * height;
      this.vx = (Math.random() - 0.5) * 0.5;
      this.vy = (Math.random() - 0.5) * 0.5;
      this.r = Math.random() * 2 + 0.5;
      this.alpha = Math.random() * 0.5 + 0.2;
    }

    update() {
      const dx = this.x - mouse.x;
      const dy = this.y - mouse.y;
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist < MOUSE_RADIUS && dist > 0) {
        const force = ((MOUSE_RADIUS - dist) / MOUSE_RADIUS) * 0.02;
        this.vx += (dx / dist) * force;
        this.vy += (dy / dist) * force;
      }

      this.vx *= 0.995;
      this.vy *= 0.995;
      this.x += this.vx;
      this.y += this.vy;

      if (this.x < 0) this.x = width;
      if (this.x > width) this.x = 0;
      if (this.y < 0) this.y = height;
      if (this.y > height) this.y = 0;
    }
  }

  function resize() {
    width = canvas.width = window.innerWidth;
    height = canvas.height = window.innerHeight;
  }

  function draw() {
    ctx.clearRect(0, 0, width, height);

    for (const particle of particles) {
      particle.update();
      ctx.beginPath();
      ctx.arc(particle.x, particle.y, particle.r, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(0,240,255,${particle.alpha})`;
      ctx.fill();
    }

    for (let i = 0; i < particles.length; i += 1) {
      for (let j = i + 1; j < particles.length; j += 1) {
        const dx = particles[i].x - particles[j].x;
        const dy = particles[i].y - particles[j].y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < MAX_DIST) {
          ctx.beginPath();
          ctx.moveTo(particles[i].x, particles[i].y);
          ctx.lineTo(particles[j].x, particles[j].y);
          ctx.strokeStyle = `rgba(0,240,255,${(1 - dist / MAX_DIST) * 0.15})`;
          ctx.lineWidth = 0.6;
          ctx.stroke();
        }
      }
    }

    frameCount += 1;
    const now = performance.now();
    if (now - lastFpsTime >= 1000) {
      document.getElementById("st-fps").textContent = `${frameCount} FPS`;
      document.getElementById("st-particles").textContent = `${particles.length} Particles`;
      frameCount = 0;
      lastFpsTime = now;
    }

    requestAnimationFrame(draw);
  }

  function init() {
    resize();
    particles = Array.from({ length: PARTICLE_COUNT }, () => new Particle());
    window.addEventListener("resize", resize);
    document.addEventListener("mousemove", (event) => {
      mouse.x = event.clientX;
      mouse.y = event.clientY;
    });
    document.addEventListener("mouseleave", () => {
      mouse.x = -1000;
      mouse.y = -1000;
    });
    requestAnimationFrame(draw);
  }

  return { init };
})();

async function apiCall(endpoint, body) {
  const headers = { "Content-Type": "application/json" };
  if (API_TOKEN) {
    headers.Authorization = `Bearer ${API_TOKEN}`;
  }

  const response = await fetch(API_BASE + endpoint, {
    method: body ? "POST" : "GET",
    headers,
    body: body ? JSON.stringify(body) : undefined
  });
  return response.json();
}

async function loadData() {
  const response = await fetch("./data/skills.json", { cache: "no-store" });
  SKILLS_DATA = await response.json();
}

async function loadStatusMap() {
  try {
    const data = await apiCall("/list");
    if (data.ok) {
      SKILL_STATUS = {};
      for (const skill of data.skills) {
        SKILL_STATUS[skill.id] = { status: skill.status, protected: skill.protected };
      }
    }
  } catch (error) {
    console.warn("status API unavailable:", error);
  }
}

function getStatus(id) {
  return SKILL_STATUS[id] || { status: "installed", protected: false };
}

function showToast(message, type) {
  const toast = document.getElementById("toast");
  toast.textContent = message;
  toast.className = `toast show ${type}`;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove("show"), 3000);
}

function showConfirm(title, message) {
  return new Promise((resolve) => {
    confirmResolve = resolve;
    document.getElementById("confirm-title").textContent = title;
    document.getElementById("confirm-msg").textContent = message;
    document.getElementById("confirm-overlay").classList.add("open");
  });
}

const STATUS_LABELS = { installed: "ACTIVE", disabled: "OFF", available: "NEW" };

function renderTabs() {
  const tabs = document.getElementById("cat-tabs");
  const counts = { all: SKILLS_DATA.skills.length };

  for (const skill of SKILLS_DATA.skills) {
    counts[skill.category] = (counts[skill.category] || 0) + 1;
  }

  let html = `<div class="cat-tab active" data-cat="all">ALL<span class="count">${counts.all}</span></div>`;
  for (const [id, cat] of Object.entries(SKILLS_DATA.categories)) {
    html += `<div class="cat-tab" data-cat="${id}">${cat.emoji} ${cat.label}<span class="count">${counts[id] || 0}</span></div>`;
  }
  tabs.innerHTML = html;

  tabs.querySelectorAll(".cat-tab").forEach((tab) => {
    tab.addEventListener("click", () => {
      tabs.querySelectorAll(".cat-tab").forEach((item) => item.classList.remove("active"));
      tab.classList.add("active");
      currentCat = tab.dataset.cat;
      renderGrid();
    });
  });
}

function renderGrid() {
  const grid = document.getElementById("hex-grid");
  const filtered = SKILLS_DATA.skills.filter((skill) => {
    if (currentCat !== "all" && skill.category !== currentCat) return false;
    if (!currentSearch) return true;
    const query = currentSearch.toLowerCase();
    return (
      skill.name.toLowerCase().includes(query) ||
      skill.id.toLowerCase().includes(query) ||
      skill.description.toLowerCase().includes(query) ||
      (skill.tags || []).some((tag) => tag.toLowerCase().includes(query))
    );
  });

  grid.innerHTML = filtered
    .map((skill) => {
      const runtime = getStatus(skill.id);
      const status = skill.status || runtime.status || "installed";
      const label = STATUS_LABELS[status] || status;
      return `
        <div class="hex-card" data-cat="${skill.category}" data-id="${skill.id}" data-status="${status}">
          <span class="hex-status ${status}">${label}</span>
          <div class="hex-border"></div>
          <div class="hex-inner">
            <div class="hex-emoji">${skill.emoji}</div>
            <div class="hex-name" title="${skill.name}">${skill.name}</div>
            <div class="hex-ver">v${skill.version}</div>
          </div>
        </div>
      `;
    })
    .join("");

  grid.querySelectorAll(".hex-card").forEach((card, index) => {
    setTimeout(() => card.classList.add("visible"), 60 * index);
    card.addEventListener("click", () => openDetail(card.dataset.id));
  });
}

function openDetail(id) {
  currentDetailId = id;
  const skill = SKILLS_DATA.skills.find((item) => item.id === id);
  if (!skill) return;

  const category = SKILLS_DATA.categories[skill.category] || {};
  const runtime = getStatus(id);
  const status = skill.status || runtime.status || "installed";

  document.getElementById("detail-emoji").textContent = skill.emoji;
  document.getElementById("detail-title").textContent = skill.name;
  document.getElementById("detail-meta").innerHTML =
    `<span>v${skill.version}</span>` +
    `<span style="color:${category.color || "#00f0ff"}">${category.emoji || ""} ${category.label || skill.category}</span>` +
    `<span class="hex-status ${status}" style="font-size:10px">${STATUS_LABELS[status] || status}</span>`;

  let bodyHtml = `<div class="detail-section">
    <div class="detail-section-title">&#128203; Description</div>
    <div class="detail-desc">${escapeHtml(skill.description)}</div>
  </div>`;

  if (skill.tags && skill.tags.length) {
    bodyHtml += `<div class="detail-section">
      <div class="detail-section-title">&#127991;&#65039; Tags</div>
      <div class="detail-tags">${skill.tags.map((tag) => `<span class="detail-tag">${escapeHtml(tag)}</span>`).join("")}</div>
    </div>`;
  }

  bodyHtml += `<div class="detail-section">
    <div class="detail-section-title">&#128193; Source</div>
    <div class="detail-path">${escapeHtml(skill.path)}</div>
  </div>`;

  document.getElementById("detail-body").innerHTML = bodyHtml;
  renderActions(id, status, runtime.protected);

  const overlay = document.getElementById("detail-overlay");
  overlay.style.display = "flex";
  requestAnimationFrame(() => overlay.classList.add("open"));
}

function renderActions(id, status, isProtected) {
  const actions = document.getElementById("detail-actions");
  let html = "";

  if (status === "available") {
    html += `<button class="act-btn install" data-action="install" data-id="${id}">&#128229; Install</button>`;
  } else if (status === "installed") {
    html += `<span class="act-btn installed-badge">&#9989; Installed</span>`;
    html += `<button class="act-btn disable" data-action="disable" data-id="${id}">&#9208;&#65039; Disable</button>`;
    if (!isProtected) {
      html += `<button class="act-btn uninstall" data-action="uninstall" data-id="${id}">&#128465;&#65039; Uninstall</button>`;
    }
  } else if (status === "disabled") {
    html += `<button class="act-btn enable" data-action="enable" data-id="${id}">&#9654;&#65039; Enable</button>`;
    if (!isProtected) {
      html += `<button class="act-btn uninstall" data-action="uninstall" data-id="${id}">&#128465;&#65039; Uninstall</button>`;
    }
  }

  if (isProtected) {
    html += `<span class="act-status">&#128274; Protected</span>`;
  }

  actions.innerHTML = html;
  actions.querySelectorAll("[data-action]").forEach((button) => {
    button.addEventListener("click", () => handleAction(button.dataset.action, button.dataset.id, button));
  });
}

async function handleAction(action, id, button) {
  if (action === "uninstall") {
    const ok = await showConfirm("Uninstall Skill", `Are you sure you want to uninstall "${id}"? This will remove all skill files.`);
    if (!ok) return;
  }

  const originalHtml = button.innerHTML;
  button.disabled = true;
  button.innerHTML = `<span class="act-spinner"></span> ${action}...`;

  try {
    const result = await apiCall(`/${action}`, { id });
    if (result.ok) {
      showToast(result.message || `${action} success`, "success");
      await Promise.all([loadData(), loadStatusMap()]);
      renderTabs();
      renderGrid();
      if (action === "uninstall") {
        closeDetail();
      } else {
        openDetail(id);
      }
    } else {
      showToast(result.error || `${action} failed`, "error");
      button.disabled = false;
      button.innerHTML = originalHtml;
    }
  } catch (error) {
    showToast(`Network error: ${error.message}`, "error");
    button.disabled = false;
    button.innerHTML = originalHtml;
  }
}

function closeDetail() {
  currentDetailId = null;
  const overlay = document.getElementById("detail-overlay");
  overlay.classList.remove("open");
  setTimeout(() => {
    overlay.style.display = "none";
  }, 300);
}

function escapeHtml(text) {
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

function wireDialogs() {
  document.getElementById("confirm-cancel").onclick = () => {
    document.getElementById("confirm-overlay").classList.remove("open");
    if (confirmResolve) confirmResolve(false);
  };

  document.getElementById("confirm-yes").onclick = () => {
    document.getElementById("confirm-overlay").classList.remove("open");
    if (confirmResolve) confirmResolve(true);
  };

  document.getElementById("detail-close").addEventListener("click", closeDetail);
  document.getElementById("detail-overlay").addEventListener("click", (event) => {
    if (event.target === event.currentTarget) closeDetail();
  });
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeDetail();
  });
}

async function boot() {
  ParticleEngine.init();
  await Promise.all([loadData(), loadStatusMap()]);

  document.getElementById("skill-version").textContent = `${SKILLS_DATA.skills.length} Skills`;
  document.getElementById("st-skills").textContent = `${SKILLS_DATA.skills.length} Skills`;
  document.getElementById("st-cats").textContent = `${Object.keys(SKILLS_DATA.categories).length} Categories`;

  renderTabs();
  renderGrid();
  wireDialogs();

  document.getElementById("search-input").addEventListener("input", (event) => {
    currentSearch = event.target.value.trim();
    renderGrid();
  });

  setTimeout(() => {
    const overlay = document.getElementById("loading-overlay");
    overlay.classList.add("fade-out");
    setTimeout(() => overlay.remove(), 600);
  }, 1500);
}

boot();
