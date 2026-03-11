Claude Codex OpenClaw 门户使用说明

一、入口文件

1. Windows 双击入口
- /mnt/g/WSL/claude-codex-openclaw.bat

2. WSL 终端入口
```bash
bash /mnt/g/WSL/claude-codex-openclaw.sh
```

二、设计结构

这个新脚本是独立门户，不覆盖原来的 OpenClaw 菜单。

一级主菜单只有 3 个入口：
- 1. OpenClaw
- 2. Claude Code
- 3. Codex

一级主菜单特点：
- 3 个入口全部居中显示
- 带颜色分组卡片
- 带快捷键提示
- 顶部显示系统状态总线和 session 数量

三、OpenClaw 子菜单

OpenClaw 子菜单当前支持：
- 启动生产环境
- 停止生产环境
- 启动测试环境
- 停止测试环境
- 查看状态
- 打开生产环境 TUI
- 打开测试环境 TUI
- 测试提升到生产
- 回退到最近一次生产备份

安全保护：
- 提升到生产前要求输入 YES
- 回退前要求输入 ROLLBACK

四、Claude Code 子菜单

Claude Code 当前支持：
- 选择最近 Session
- 选择全部 Session
- 继续当前目录最近会话
- 新建 Claude 会话

本机会话来源：
- /home/hanji/.claude/usage-data/session-meta
- /home/hanji/.claude/projects

恢复命令逻辑：
- 恢复指定 session: claude -r <session-id>
- 继续当前目录最近会话: claude -c
- 新建会话: claude

五、Codex 子菜单

Codex 当前支持：
- 选择最近 Session
- 选择全部 Session
- 恢复最近一次会话
- 新建 Codex 会话

本机会话来源：
- /home/hanji/.codex/sessions
- /home/hanji/.codex/session_index.jsonl

恢复命令逻辑：
- 恢复指定 session: codex resume <session-id>
- 恢复最近一次: codex resume --last
- 新建会话: codex

六、Session 列表界面

Claude 和 Codex 的 session 选择页都会显示：
- 编号
- Session 短 ID
- 项目或工作目录
- 开始时间
- 会话摘要

操作方式：
- 输入当前页编号恢复对应 session
- 输入快捷字母执行辅助操作
- 输入 b 返回上一级

补充说明：
- “最近 Session” 当前显示最近 20 条
- “全部 Session” 会列出本机扫描到的全部 session
- 列表会按当前启动门户所在目录优先排序
- 列表已支持分页，每页 10 条
- 输入 `[` 上一页，输入 `]` 下一页
- R 列中:
  `*` 表示与当前目录完全匹配
  `+` 表示与当前目录相关

七、视觉说明

门户保留以下视觉元素：
- 两侧动态代码雨开场
- 中间三只动态 3D ASCII 风格红色龙虾主视觉
- 中间主龙虾更大，左右龙虾更小，带前中后景纵深和霓虹描边
- 三只龙虾采用不同节奏动态变化，不是同步摆动
- 两侧代码雨有亮暗双层，增强矩阵屏幕纵深感
- 居中标题布局
- 底部欢迎语：欢迎来到阿吉超级个体工作室
- 开场最后一帧两侧会停在 `HELLO AI`

八、与旧菜单的关系

旧 OpenClaw 菜单仍然保留，不受影响。

旧入口：
- /mnt/g/WSL/openclaw-menu.sh
- /mnt/g/WSL/openclaw-menu.bat

旧版本归档目录：
- /home/hanji/openclaw-scripts/archive/openclaw-menu-20260311-153958
