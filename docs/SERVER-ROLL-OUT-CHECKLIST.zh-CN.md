# OpenClaw 服务器落地检查清单

> 用途：把这套控制平面落到另一台服务器时，按顺序逐项检查。

## A. 部署前检查

- [ ] 已确认目标服务器用户名和 HOME 目录
- [ ] 已安装 `git`
- [ ] 已安装 `node` / `npm`
- [ ] 已安装 `openclaw`
- [ ] 已确认 `openclaw --version`
- [ ] 已确认生产状态目录已存在
- [ ] 已确认生产 workspace 已是 git 仓库
- [ ] 已确认生产仓库远端可访问
- [ ] 已确认测试端口未被占用
- [ ] 已准备生产 token / 测试 token
- [ ] 已确认 `~/.nvm` 或 Node 可执行路径

## B. 克隆控制平面仓库

- [ ] 执行：
  ```bash
  git clone git@github.com:han478270576-arch/claude-codex-openclaw-aji-work-interface-.git
  ```
- [ ] 进入项目目录
- [ ] 确认分支为 `main`

## C. 本机配置

- [ ] 复制模板：
  ```bash
  cp config/local.env.example config/local.env
  ```
- [ ] 已填写：
  - `OPENCLAW_PROD_STATE_DIR`
  - `OPENCLAW_TEST_STATE_DIR`
  - `OPENCLAW_PROD_PORT`
  - `OPENCLAW_TEST_PORT`
  - `OPENCLAW_PROD_TOKEN`
  - `OPENCLAW_TEST_TOKEN`
  - `OPENCLAW_BACKUP_BASE`
  - `OPENCLAW_NODE_BIN_DIR`
  - `OPENCLAW_PACKAGE_JSON`
- [ ] 已确认 `config/local.env` 不会进入 Git

## D. 初始化主机

- [ ] 执行：
  ```bash
  bash ./scripts/bootstrap-openclaw-host.sh
  ```
- [ ] 已看到生产目录检查通过
- [ ] 已看到测试环境目录创建完成
- [ ] 已看到测试 workspace 初始化完成
- [ ] 已看到测试 `openclaw.json` 生成完成
- [ ] 已看到测试 `start-gateway.sh` 生成完成

## E. 测试环境验证

- [ ] 执行：
  ```bash
  bash ./bin/openclawctl.sh start test
  ```
- [ ] 执行：
  ```bash
  bash ./bin/openclawctl.sh status
  ```
- [ ] 浏览器可打开测试环境
- [ ] 测试 TUI 可打开：
  ```bash
  bash ./bin/openclawctl.sh tui test
  ```
- [ ] Telegram / Discord / Slack 是否按预期关闭或隔离
- [ ] 测试 workspace 分支确认为 `test`

## F. 生产环境验证

- [ ] 执行：
  ```bash
  bash ./bin/openclawctl.sh start prod
  ```
- [ ] 浏览器可打开生产环境
- [ ] 生产 workspace 分支确认为 `main`
- [ ] 生产和测试端口互不冲突

## G. 上线演练

- [ ] 在测试环境做一笔小改动
- [ ] 提交到 `test`
- [ ] 执行：
  ```bash
  bash ./bin/openclawctl.sh promote
  ```
- [ ] 已看到生产备份生成
- [ ] 已看到 `main` 提升成功
- [ ] 已看到生产 gateway 重启成功

## H. 回退演练

- [ ] 执行：
  ```bash
  bash ./bin/openclawctl.sh rollback
  ```
- [ ] 已看到最近备份恢复成功
- [ ] 已确认生产环境重新可用

## I. 交付后留档

- [ ] 记录服务器名
- [ ] 记录生产端口 / 测试端口
- [ ] 记录仓库路径
- [ ] 记录最近一次成功备份目录
- [ ] 记录当前 OpenClaw 程序版本
- [ ] 记录当前控制平面仓库提交号

## J. 最终验收标准

- [ ] `prod/test` 双环境都可启动
- [ ] `main/test` 双分支关系清晰
- [ ] `promote` 可用
- [ ] `rollback` 可用
- [ ] TUI 可用
- [ ] 浏览器入口可用
- [ ] 备份目录可写
- [ ] 本机 secrets 未进入 Git

