# Skills Console 集成计划

## 当前已确认的 live 结构

- 静态页目录：
  - `/root/.openclaw-test/workspace/canvas/skills`
- API：
  - `/skills/api/* -> 127.0.0.1:18795`
- live 文件：
  - `index.html`
  - `skills-api.js`
  - `build-data.sh`
  - `data/skills.json`

## 本次收编目标

1. 把 live skills 页面纳入控制平面仓库
2. 拆掉单文件 HTML，形成可维护结构
3. 去掉前端硬编码 token
4. 为后续和 Lobster Console 统一导航做准备

## 新目录规划

- `site/skills-console/`
  - `index.html`
  - `styles.css`
  - `app.js`
  - `data/skills.json`
- `services/skills-console/`
  - `skills-api.js`
  - `build-data.sh`

## 当前阶段原则

- 先保持功能等价
- 不立即大改视觉
- 不立即改 API 协议
- 先解决结构和版本控制问题

## 下一阶段

1. 统一到 Lobster 控制台导航
2. 在技能详情里增加 agent/chat 入口
3. 把技能页从“技能管理器”升级成“技能任务甲板”
