#!/usr/bin/env node
// Skills Management API - Zero dependency Node.js server
const http = require('http');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PORT = 18795;
const WORKSPACE_SKILLS = '/root/.openclaw/workspace/skills';
const REPO_SKILLS = '/root/hanji/openclaw/skills';
const OPENCLAW_JSON = '/root/.openclaw-test/openclaw.json';
const BUILD_SCRIPT = '/root/.openclaw-test/workspace/canvas/skills/build-data.sh';
const API_TOKEN = '21b91dedc2411853d2257b3241672c7139e8dfb64ab97a50';

// Protected skills that cannot be uninstalled
const PROTECTED = new Set(['skill-vetter', 'magic_commands']);

// --- Helpers ---

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, 'utf-8'));
}

function writeJson(p, obj) {
  // Backup before write
  const bak = p + '.bak';
  if (fs.existsSync(p)) fs.copyFileSync(p, bak);
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + '\n');
}

function rebuildData() {
  try {
    execSync(`bash ${BUILD_SCRIPT}`, { timeout: 10000 });
  } catch (e) {
    console.error('rebuild failed:', e.message);
  }
}

function getInstalledSkills() {
  if (!fs.existsSync(WORKSPACE_SKILLS)) return [];
  return fs.readdirSync(WORKSPACE_SKILLS, { withFileTypes: true })
    .filter(d => d.isDirectory() && !d.name.startsWith('.') && d.name !== '__pycache__' && d.name !== 'node_modules')
    .map(d => d.name);
}

function getRepoSkills() {
  if (!fs.existsSync(REPO_SKILLS)) return [];
  return fs.readdirSync(REPO_SKILLS, { withFileTypes: true })
    .filter(d => d.isDirectory() && !d.name.startsWith('.') && d.name !== '__pycache__' && d.name !== 'node_modules')
    .map(d => d.name);
}

function getDisabledSkills() {
  try {
    const cfg = readJson(OPENCLAW_JSON);
    const skillsCfg = cfg.skills?.config || {};
    return Object.entries(skillsCfg)
      .filter(([, v]) => v?.enabled === false)
      .map(([k]) => k);
  } catch { return []; }
}

function setSkillEnabled(id, enabled) {
  const cfg = readJson(OPENCLAW_JSON);
  if (!cfg.skills) cfg.skills = {};
  if (!cfg.skills.config) cfg.skills.config = {};
  if (enabled) {
    delete cfg.skills.config[id];
    // Clean up empty
    if (Object.keys(cfg.skills.config).length === 0) delete cfg.skills.config;
    if (Object.keys(cfg.skills).length === 0) delete cfg.skills;
  } else {
    cfg.skills.config[id] = { enabled: false };
  }
  writeJson(OPENCLAW_JSON, cfg);
}

function respond(res, status, data) {
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
  });
  res.end(JSON.stringify(data));
}

function parseBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', c => { body += c; if (body.length > 1e5) reject(new Error('too large')); });
    req.on('end', () => { try { resolve(JSON.parse(body || '{}')); } catch { resolve({}); } });
  });
}

function checkAuth(req) {
  const auth = req.headers.authorization || '';
  const token = auth.replace(/^Bearer\s+/i, '').trim();
  if (token === API_TOKEN) return true;
  // Also check query param
  const url = new URL(req.url, `http://localhost:${PORT}`);
  return url.searchParams.get('token') === API_TOKEN;
}

// --- Handlers ---

async function handleList(req, res) {
  const installed = new Set(getInstalledSkills());
  const repoAll = new Set(getRepoSkills());
  const disabled = new Set(getDisabledSkills());

  const skills = [];

  // Installed skills
  for (const id of installed) {
    skills.push({
      id,
      status: disabled.has(id) ? 'disabled' : 'installed',
      protected: PROTECTED.has(id),
      source: repoAll.has(id) ? 'repo' : 'local'
    });
  }

  // Available (in repo but not installed)
  for (const id of repoAll) {
    if (!installed.has(id)) {
      skills.push({ id, status: 'available', protected: false, source: 'repo' });
    }
  }

  respond(res, 200, { ok: true, skills });
}

async function handleInstall(req, res) {
  if (!checkAuth(req)) return respond(res, 401, { ok: false, error: 'unauthorized' });
  const { id } = await parseBody(req);
  if (!id) return respond(res, 400, { ok: false, error: 'missing id' });

  const src = path.join(REPO_SKILLS, id);
  const dst = path.join(WORKSPACE_SKILLS, id);

  if (!fs.existsSync(src)) return respond(res, 404, { ok: false, error: `skill "${id}" not found in repo` });
  if (fs.existsSync(dst)) return respond(res, 409, { ok: false, error: `skill "${id}" already installed` });

  try {
    execSync(`cp -r ${JSON.stringify(src)} ${JSON.stringify(dst)}`, { timeout: 30000 });
    rebuildData();
    respond(res, 200, { ok: true, message: `installed "${id}"` });
  } catch (e) {
    respond(res, 500, { ok: false, error: e.message });
  }
}

async function handleDisable(req, res) {
  if (!checkAuth(req)) return respond(res, 401, { ok: false, error: 'unauthorized' });
  const { id } = await parseBody(req);
  if (!id) return respond(res, 400, { ok: false, error: 'missing id' });

  const installed = getInstalledSkills();
  if (!installed.includes(id)) return respond(res, 404, { ok: false, error: `skill "${id}" not installed` });

  try {
    setSkillEnabled(id, false);
    rebuildData();
    respond(res, 200, { ok: true, message: `disabled "${id}"` });
  } catch (e) {
    respond(res, 500, { ok: false, error: e.message });
  }
}

async function handleEnable(req, res) {
  if (!checkAuth(req)) return respond(res, 401, { ok: false, error: 'unauthorized' });
  const { id } = await parseBody(req);
  if (!id) return respond(res, 400, { ok: false, error: 'missing id' });

  try {
    setSkillEnabled(id, true);
    rebuildData();
    respond(res, 200, { ok: true, message: `enabled "${id}"` });
  } catch (e) {
    respond(res, 500, { ok: false, error: e.message });
  }
}

async function handleUninstall(req, res) {
  if (!checkAuth(req)) return respond(res, 401, { ok: false, error: 'unauthorized' });
  const { id } = await parseBody(req);
  if (!id) return respond(res, 400, { ok: false, error: 'missing id' });

  if (PROTECTED.has(id)) return respond(res, 403, { ok: false, error: `skill "${id}" is protected` });

  const dst = path.join(WORKSPACE_SKILLS, id);
  if (!fs.existsSync(dst)) return respond(res, 404, { ok: false, error: `skill "${id}" not installed` });

  try {
    execSync(`rm -rf ${JSON.stringify(dst)}`, { timeout: 10000 });
    // Also clean config
    try { setSkillEnabled(id, true); } catch {}
    rebuildData();
    respond(res, 200, { ok: true, message: `uninstalled "${id}"` });
  } catch (e) {
    respond(res, 500, { ok: false, error: e.message });
  }
}

// --- Router ---

const server = http.createServer(async (req, res) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Authorization, Content-Type',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
    });
    return res.end();
  }

  const url = new URL(req.url, `http://localhost:${PORT}`);
  const route = url.pathname.replace(/\/+$/, '');

  try {
    switch (route) {
      case '/api/list':      return await handleList(req, res);
      case '/api/install':   return await handleInstall(req, res);
      case '/api/disable':   return await handleDisable(req, res);
      case '/api/enable':    return await handleEnable(req, res);
      case '/api/uninstall': return await handleUninstall(req, res);
      default: return respond(res, 404, { ok: false, error: 'not found' });
    }
  } catch (e) {
    console.error('handler error:', e);
    respond(res, 500, { ok: false, error: 'internal error' });
  }
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Skills API listening on http://127.0.0.1:${PORT}`);
});
