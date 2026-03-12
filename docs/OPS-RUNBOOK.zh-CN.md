# OpenClaw 控制平面运行手册

## 目标

这套项目用于统一管理：

- OpenClaw 生产环境
- OpenClaw 测试环境
- Claude Code 会话入口
- Codex 会话入口

## 环境定义

- `prod`：正式环境
- `test`：测试环境
- `main`：正式代码分支
- `test`：测试代码分支

## 标准流程

1. 在 `test` 完成修改与验证
2. 确认测试环境可运行
3. 执行 `promote`
4. 生产异常时执行 `rollback`

## 常用命令

```bash
bash ./bin/claude-codex-openclaw.sh
bash ./bin/openclawctl.sh status
bash ./bin/openclawctl.sh start prod
bash ./bin/openclawctl.sh start test
bash ./bin/openclawctl.sh promote
bash ./bin/openclawctl.sh rollback
```

## 版本切换原则

- 代码版本切换：
  - 使用 Git 分支、tag、commit
- OpenClaw 程序版本切换：
  - 使用 `npm i -g openclaw@<version>`

## 风险控制原则

- 升级前先备份运行态目录
- `promote` 前确保工作区干净
- secrets 和 webhook 不进入 Git
- 测试通过后再切生产

## 多服务器复用原则

- 项目本体保持一致
- 每台服务器只改 `config/local.env`
- 每台服务器都按相同 bootstrap 步骤部署

## 服务器仓库边界

- 本地 WSL 相关内容与服务器内容分仓维护
- 服务器 OpenClaw 业务仓库应使用：`git@github.com:han478270576-arch/-openclaw-workspace.git`
- 控制平面项目继续使用独立仓库：`claude-codex-openclaw-aji-work-interface-`
- 不要把服务器运行记忆、认证 runbook、生产/测试对齐记录推到本地 WSL 仓库

## 服务器工作区忽略原则

- 生产环境的自学习输出、知识图谱、报告输出应优先 `.gitignore`
- 测试环境的 `/.clawhub/` 和 `/canvas/` 视为运行态/部署副本，不反向纳入业务仓库
- 真正需要版本控制的 UI、门户、skills、Control UI 注入脚本，继续进入控制平面仓库
