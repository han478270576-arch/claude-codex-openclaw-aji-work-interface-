# 龙虾控制台开发计划

## 目标

在 `test.ajiclaw.com` 先落一套独立于 OpenClaw 内置 Control UI 的代理人控制台，用于：

- 统一展示当前可用 agent
- 按角色、分组、能力浏览 agent
- 为下一阶段的单 agent 聊天页预留明确入口

## Phase 1

本阶段只做列表与选择，不直接接入聊天后端。

交付内容：

- `site/lobster-console/agents.json`
  - 结构化 agent 注册表
- `site/lobster-console/index.html`
  - 控制台首页
- `site/lobster-console/styles.css`
  - 视觉风格与响应式规则
- `site/lobster-console/app.js`
  - 列表渲染、搜索、筛选、详情联动

## 数据来源

- 核心分身：
  - `workspace/aji-switch.py`
- 团队 agent：
  - `workspace/team/agents/*/SOUL.md`

## 页面结构

1. 顶部 Hero
   - 控制台定位
   - 当前阶段说明
   - Agent 总数与阶段指标
2. 筛选栏
   - 搜索
   - 核心分身 / 团队 agent 过滤
3. 左侧 Agent Registry
   - 卡片化展示所有 agent
4. 右侧 Detail Panel
   - 展示当前选中的 agent 详情
   - 预留 Phase 2 聊天入口

## Phase 2 方向

下一阶段接入：

- `/lobster/chat/<agent-id>` 或 `/lobster/chat?agent=<agent-id>`
- 单 agent 聊天壳
- 与 OpenClaw gateway 的会话桥接

## 原则

- 先在测试环境落地
- 不直接魔改 OpenClaw 原生前端
- 先建立稳定的数据模型，再接聊天后端
