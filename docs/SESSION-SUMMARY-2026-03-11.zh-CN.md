# 会话总结：OpenClaw 控制平面首轮落地

日期：2026-03-11

## 本次会话产出

- 将原本分散的 OpenClaw 管理脚本与门户界面整理为独立项目。
- 建立了 `prod/test` 双环境控制流程。
- 建立了 `main/test` 双分支上线流程。
- 建立了 `promote` / `rollback` 标准动作。
- 建立了统一门户与全局命令：
  - `openclaw-codex-claude`
- 完成第一台云服务器样板部署：
  - `root@64.188.27.231`

## 关键仓库与版本

- 独立项目仓库：
  - `git@github.com:han478270576-arch/claude-codex-openclaw-aji-work-interface-.git`
- 已发版本：
  - `v1.0.0`
  - `v1.1.0`

## 关键修复

- 菜单顶层缺少纯文本兜底时，某些终端不会显示 `1/2/3`
- Claude/Codex 无 session 时，门户不应直接退出
- 全局命令通过软链接启动时，脚本必须解析真实路径
- `promote` 在 detached worktree 情况下必须真正推进 `main`
- 启动探测不能只依赖 `lsof`，需要优先用 `ss`

## 结果定义

这套项目现在不再只是“本机管理脚本”，而是一个可在其他服务器复用的 OpenClaw 控制平面。
