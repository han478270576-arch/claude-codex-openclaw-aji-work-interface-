# OpenClaw 控制平面部署说明

## 目标

把一台新的 OpenClaw 服务器快速纳入统一控制平面，获得：

- `prod/test` 双环境
- `main/test` 双分支
- `promote/rollback` 上线回退
- 统一启动脚本
- 统一门户界面

## 适用前提

目标服务器至少已经具备：

- Node / npm
- OpenClaw 已安装
- 生产状态目录已存在
- 生产 workspace 已是 git 仓库

## 推荐部署顺序

### 1. clone 控制平面仓库

```bash
git clone <control-plane-repo>
cd claude-codex-openclaw-aji-work-interface
```

### 2. 创建本机配置

```bash
cp config/local.env.example config/local.env
```

重点修改：

- `OPENCLAW_PROD_STATE_DIR`
- `OPENCLAW_TEST_STATE_DIR`
- `OPENCLAW_PROD_PORT`
- `OPENCLAW_TEST_PORT`
- `OPENCLAW_PROD_TOKEN`
- `OPENCLAW_TEST_TOKEN`
- `OPENCLAW_BACKUP_BASE`

### 3. 执行主机初始化

```bash
bash ./scripts/bootstrap-openclaw-host.sh
```

这一步会做：

- 检查生产环境是否存在
- 生成生产 gateway 启动脚本（如果缺失）
- 创建测试环境目录
- 复制测试环境 `.env/gateway.env`
- 初始化测试 workspace
- 生成测试 `openclaw.json`
- 生成测试 `start-gateway.sh`

### 4. 启动并验证

```bash
bash ./bin/openclawctl.sh start test
bash ./bin/openclawctl.sh status
```

验证通过后再运行：

```bash
bash ./bin/openclawctl.sh start prod
```

## 日常工作流

### 开发与验证

```bash
bash ./bin/openclawctl.sh start test
bash ./bin/openclawctl.sh tui test
```

### 上线

```bash
bash ./bin/openclawctl.sh promote
```

### 回退

```bash
bash ./bin/openclawctl.sh rollback
```

## 设计原则

- 生产环境只跑 `main`
- 测试环境只跑 `test`
- 所有改动先在测试环境验证
- 生产上线前必须先备份
- secrets 不进入 Git，只放 `config/local.env`

## 配套清单

正式落地到一台新服务器时，建议同时使用：

- `docs/SERVER-ROLL-OUT-CHECKLIST.zh-CN.md`
