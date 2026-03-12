# claude-codex-openclaw 阿吉工作界面 / OpenClaw 控制平面

这是一个独立项目版本的阿吉工作界面，同时也是 OpenClaw 的控制平面仓库，用于统一管理：

- OpenClaw
- Claude Code
- Codex

## 项目目标

- 从现有 OpenClaw 仓库中抽离
- 形成可迁移的独立终端门户
- 形成可跨服务器复用的 OpenClaw 控制平面
- 保留双环境 OpenClaw 管理
- 提供 Claude/Codex Session 统一入口

## 目录结构

- `bin/` 运行脚本
- `config/` 默认配置和本地覆盖配置
- `docs/` 使用说明
- `lib/` 公共配置加载逻辑
- `site/` 对外落地页和静态站点资源
- `scripts/` 主机初始化与启动器安装

## 运行方式

```bash
bash ./bin/claude-codex-openclaw.sh
```

## 主机初始化

```bash
bash ./scripts/bootstrap-openclaw-host.sh
```

## 安装启动器

```bash
bash ./scripts/install-launchers.sh
```

## 配置方式

复制并修改：

- `config/local.env.example`

本机私有配置写入：

- `config/local.env`

`config/local.env` 已被 `.gitignore` 忽略，不会进入仓库。

更多安装和迁移说明见：

- `docs/INSTALL.zh-CN.md`
- `docs/DEPLOY-OPENCLAW-HOST.zh-CN.md`
- `docs/SERVER-ROLL-OUT-CHECKLIST.zh-CN.md`
- `docs/HTTPS-DOMAIN-SETUP.zh-CN.md`

## 当前状态

这一版是从你当前已可用的界面抽离出的独立项目骨架，下一步可以直接初始化独立 Git 仓库并推送到新的 GitHub 仓库。

## 附加文档

- `README.en.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `RELEASE-v1.0.0.md`
