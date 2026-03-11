# claude-codex-openclaw 阿吉工作界面 v1.0.0

发布日期: `2026-03-11`

版本标签: `v1.0.0`

提交版本: `e4f0fb0`

## 版本定位

这是 `claude-codex-openclaw 阿吉工作界面` 作为独立项目的首个发布版本。

该版本从现有 OpenClaw 工作流中抽离，形成单独仓库，便于后续迁移到新的：

- Codex
- Claude Code
- OpenClaw

组合环境。

## 本版包含内容

- 一级主菜单
  - `OpenClaw`
  - `Claude Code`
  - `Codex`
- OpenClaw 双环境控制
  - 生产环境
  - 测试环境
  - 状态查看
  - TUI 入口
  - Promote
  - Rollback
- Claude Code Session 管理
  - 最近 Session
  - 全部 Session
  - 当前目录优先排序
  - 分页选择
- Codex Session 管理
  - 最近 Session
  - 全部 Session
  - 当前目录优先排序
  - 分页选择
- 配置驱动结构
  - `config/default.env`
  - `config/local.env.example`
  - `config/local.env` 本地覆盖
- 安装与迁移支持
  - 独立 README
  - 中文安装文档
  - Windows 启动器安装脚本

## 项目入口

- WSL:
  - `bash ./bin/claude-codex-openclaw.sh`
- Windows 启动器安装:
  - `bash ./scripts/install-launchers.sh`

## 项目结构

- `bin/`
- `config/`
- `docs/`
- `lib/`
- `scripts/`

## 说明

- `config/local.env` 不进入 Git
- 本版重点是独立化和可迁移化
- 不包含真实私有 token 和本机私有 secrets

## 后续建议

- `v1.1.0`
  - Session 搜索过滤
  - 更完整的 ChangeLog
  - 更强的状态面板
- `v2.0.0`
  - 模块化 UI/主题系统
  - 更多工作流接入
  - 更完整的跨机器迁移体验
