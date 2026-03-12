#!/usr/bin/env node
const http = require("http");
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const PORT = Number(process.env.SKILLS_API_PORT || 18795);
const WORKSPACE_SKILLS = process.env.SKILLS_WORKSPACE_DIR || "/root/.openclaw/workspace/skills";
const REPO_SKILLS = process.env.SKILLS_REPO_DIR || "/root/hanji/openclaw/skills";
const OPENCLAW_JSON = process.env.SKILLS_OPENCLAW_JSON || "/root/.openclaw-test/openclaw.json";
const BUILD_SCRIPT = process.env.SKILLS_BUILD_SCRIPT || "/root/.openclaw-test/workspace/canvas/skills/build-data.sh";
const API_TOKEN = process.env.SKILLS_API_TOKEN || "";

const PROTECTED = new Set(["skill-vetter", "magic_commands"]);

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf-8"));
}

function writeJson(file, obj) {
  const backup = `${file}.bak`;
  if (fs.existsSync(file)) fs.copyFileSync(file, backup);
  fs.writeFileSync(file, `${JSON.stringify(obj, null, 2)}\n`);
}

function rebuildData() {
  try {
    execSync(`bash ${JSON.stringify(BUILD_SCRIPT)}`, { timeout: 10000, stdio: "pipe" });
  } catch (error) {
    console.error("rebuild failed:", error.message);
  }
}

function listDirs(base) {
  if (!fs.existsSync(base)) return [];
  return fs.readdirSync(base, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && !entry.name.startsWith(".") && entry.name !== "__pycache__" && entry.name !== "node_modules")
    .map((entry) => entry.name);
}

function getInstalledSkills() {
  return listDirs(WORKSPACE_SKILLS);
}

function getRepoSkills() {
  return listDirs(REPO_SKILLS);
}

function getDisabledSkills() {
  try {
    const cfg = readJson(OPENCLAW_JSON);
    const skillsCfg = cfg.skills?.config || {};
    return Object.entries(skillsCfg)
      .filter(([, value]) => value && value.enabled === false)
      .map(([id]) => id);
  } catch {
    return [];
  }
}

function setSkillEnabled(id, enabled) {
  const cfg = readJson(OPENCLAW_JSON);
  if (!cfg.skills) cfg.skills = {};
  if (!cfg.skills.config) cfg.skills.config = {};
  if (enabled) {
    delete cfg.skills.config[id];
    if (Object.keys(cfg.skills.config).length === 0) delete cfg.skills.config;
    if (Object.keys(cfg.skills).length === 0) delete cfg.skills;
  } else {
    cfg.skills.config[id] = { enabled: false };
  }
  writeJson(OPENCLAW_JSON, cfg);
}

function respond(res, status, data) {
  res.writeHead(status, {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS"
  });
  res.end(JSON.stringify(data));
}

function parseBody(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 1e5) reject(new Error("too large"));
    });
    req.on("end", () => {
      try {
        resolve(JSON.parse(body || "{}"));
      } catch {
        resolve({});
      }
    });
  });
}

function checkAuth(req) {
  if (!API_TOKEN) return true;
  const auth = req.headers.authorization || "";
  const token = auth.replace(/^Bearer\s+/i, "").trim();
  if (token === API_TOKEN) return true;
  const url = new URL(req.url, `http://localhost:${PORT}`);
  return url.searchParams.get("token") === API_TOKEN;
}

async function handleList(req, res) {
  const installed = new Set(getInstalledSkills());
  const repo = new Set(getRepoSkills());
  const disabled = new Set(getDisabledSkills());
  const skills = [];

  for (const id of installed) {
    skills.push({
      id,
      status: disabled.has(id) ? "disabled" : "installed",
      protected: PROTECTED.has(id),
      source: repo.has(id) ? "repo" : "local"
    });
  }

  for (const id of repo) {
    if (!installed.has(id)) {
      skills.push({ id, status: "available", protected: false, source: "repo" });
    }
  }

  respond(res, 200, { ok: true, skills });
}

async function handleInstall(req, res) {
  if (!checkAuth(req)) return respond(res, 401, { ok: false, error: "unauthorized" });
  const { id } = await parseBody(req);
  if (!id) return respond(res, 400, { ok: false, error: "missing id" });

  const src = path.join(REPO_SKILLS, id);
  const dst = path.join(WORKSPACE_SKILLS, id);
  if (!fs.existsSync(src)) return respond(res, 404, { ok: false, error: `skill "${id}" not found in repo` });
  if (fs.existsSync(dst)) return respond(res, 409, { ok: false, error: `skill "${id}" already installed` });

  try {
    execSync(`cp -r ${JSON.stringify(src)} ${JSON.stringify(dst)}`, { timeout: 30000 });
    rebuildData();
    respond(res, 200, { ok: true, message: `installed "${id}"` });
  } catch (error) {
    respond(res, 500, { ok: false, error: error.message });
  }
}

async function handleDisable(req, res) {
  if (!checkAuth(req)) return respond(res, 401, { ok: false, error: "unauthorized" });
  const { id } = await parseBody(req);
  if (!id) return respond(res, 400, { ok: false, error: "missing id" });
  if (!getInstalledSkills().includes(id)) return respond(res, 404, { ok: false, error: `skill "${id}" not installed` });

  try {
    setSkillEnabled(id, false);
    rebuildData();
    respond(res, 200, { ok: true, message: `disabled "${id}"` });
  } catch (error) {
    respond(res, 500, { ok: false, error: error.message });
  }
}

async function handleEnable(req, res) {
  if (!checkAuth(req)) return respond(res, 401, { ok: false, error: "unauthorized" });
  const { id } = await parseBody(req);
  if (!id) return respond(res, 400, { ok: false, error: "missing id" });

  try {
    setSkillEnabled(id, true);
    rebuildData();
    respond(res, 200, { ok: true, message: `enabled "${id}"` });
  } catch (error) {
    respond(res, 500, { ok: false, error: error.message });
  }
}

async function handleUninstall(req, res) {
  if (!checkAuth(req)) return respond(res, 401, { ok: false, error: "unauthorized" });
  const { id } = await parseBody(req);
  if (!id) return respond(res, 400, { ok: false, error: "missing id" });
  if (PROTECTED.has(id)) return respond(res, 403, { ok: false, error: `skill "${id}" is protected` });

  const dst = path.join(WORKSPACE_SKILLS, id);
  if (!fs.existsSync(dst)) return respond(res, 404, { ok: false, error: `skill "${id}" not installed` });

  try {
    execSync(`rm -rf ${JSON.stringify(dst)}`, { timeout: 10000 });
    try { setSkillEnabled(id, true); } catch {}
    rebuildData();
    respond(res, 200, { ok: true, message: `uninstalled "${id}"` });
  } catch (error) {
    respond(res, 500, { ok: false, error: error.message });
  }
}

const server = http.createServer(async (req, res) => {
  if (req.method === "OPTIONS") {
    res.writeHead(204, {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Authorization, Content-Type",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS"
    });
    return res.end();
  }

  const url = new URL(req.url, `http://localhost:${PORT}`);
  const route = url.pathname.replace(/\/+$/, "");

  try {
    switch (route) {
      case "/api/list": return handleList(req, res);
      case "/api/install": return handleInstall(req, res);
      case "/api/disable": return handleDisable(req, res);
      case "/api/enable": return handleEnable(req, res);
      case "/api/uninstall": return handleUninstall(req, res);
      default: return respond(res, 404, { ok: false, error: "not found" });
    }
  } catch (error) {
    console.error("handler error:", error);
    return respond(res, 500, { ok: false, error: "internal error" });
  }
});

server.listen(PORT, "127.0.0.1", () => {
  console.log(`Skills API listening on http://127.0.0.1:${PORT}`);
});
