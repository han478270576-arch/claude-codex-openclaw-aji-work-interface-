# claude-codex-openclaw 阿吉工作界面 / OpenClaw 控制平面 v1.1.0

发布日期: `2026-03-11`

版本标签: `v1.1.0`

## 版本定位

这是控制平面仓库从“独立界面”推进到“可跨服务器复用的 OpenClaw 控制平面”的第一版稳定发布。

本版重点不只是 UI，而是把下面这套能力真正打通：

- OpenClaw `prod/test` 双环境
- `main/test` 双分支工作流
- `promote/rollback` 上线与回退
- 控制平面仓库独立管理
- 第一台云服务器样板部署验证

## 本版新增

### 控制平面能力

- 新增主机初始化脚本：
  - `scripts/bootstrap-openclaw-host.sh`
- 新增测试环境初始化脚本：
  - `scripts/setup-test-env.sh`
- 新增服务器部署文档：
  - `docs/DEPLOY-OPENCLAW-HOST.zh-CN.md`
- 新增服务器落地检查清单：
  - `docs/SERVER-ROLL-OUT-CHECKLIST.zh-CN.md`
- 新增路线图：
  - `ROADMAP.md`

### 版本控制与运维流程

- 固化 `prod/test` 双环境控制逻辑
- 固化 `main/test` 双分支工作流
- 固化备份、提升、回退流程
- 支持控制平面独立仓库管理

### 门户与入口

- 顶层菜单增加纯文本兜底
- 缺少 Claude/Codex session 目录时不再退出
- 支持全局软链接启动入口
- 修复全局启动时软链接路径解析问题

## 本版修复

- 修复测试环境生成时环境变量未完整传递的问题
- 修复测试 `openclaw.json` 残留无效字段导致无法启动的问题
- 修复备份脚本对不存在目录过于严格的问题
- 修复 `promote` 在 detached worktree 中未真正推进 `main` 的问题
- 修复菜单在部分终端环境中只显示头图不显示选择项的问题

## 样板机验证

已在云服务器完成首台样板部署验证：

- 目标主机：`64.188.27.231`
- 生产环境监听：`18789`
- 测试环境监听：`18790`
- 全局命令入口：
  - `openclaw-codex-claude`

已验证通过：

- 控制平面仓库部署
- 测试环境初始化
- 测试环境启动
- 生产环境启动
- 真实 `promote` 上线
- 生产 `main` 与测试 `test` 对齐

## 当前建议使用方式

```bash
openclaw-codex-claude
```

或：

```bash
cd /path/to/claude-codex-openclaw-aji-work-interface
bash ./bin/claude-codex-openclaw.sh
```

## 后续建议

### v1.2.0

- 加入更强的环境 doctor / health-check
- 增加更多 bootstrap 前置校验
- 增加 service manager 集成选项

### v2.0.0

- 完整模块化控制平面
- 多主机模板和批量落地规范
- 更正式的主题和 UI 结构
