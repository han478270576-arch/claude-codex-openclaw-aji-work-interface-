# 安装与迁移说明

## 1. 准备项目

进入项目目录：

```bash
cd /path/to/claude-codex-openclaw-aji-work-interface
```

复制本地配置模板：

```bash
cp config/local.env.example config/local.env
```

按你的机器环境修改：

- Claude 路径
- Codex 路径
- OpenClaw 生产/测试目录
- 端口
- Token
- WSL 发行版名
- Windows 同步目录

## 2. 直接在 WSL 里运行

```bash
bash ./bin/claude-codex-openclaw.sh
```

## 3. 生成 Windows 启动器

```bash
bash ./scripts/install-launchers.sh
```

默认会安装到 `config/local.env` 里定义的 `AJI_WINDOWS_SYNC_DIR`。

也可以指定目标目录：

```bash
bash ./scripts/install-launchers.sh /mnt/g/WSL
```

## 4. 迁移到新机器

建议步骤：

1. 克隆仓库
2. 复制 `config/local.env.example` 为 `config/local.env`
3. 根据新机器修改路径和端口
4. 执行 `bash ./scripts/install-launchers.sh`
5. 运行 `bash ./bin/claude-codex-openclaw.sh`

## 5. 注意

- `config/local.env` 不要提交到 Git
- 真正的 secrets、token、私有路径只放在 `config/local.env`
- 如果新机器的 OpenClaw/Claude/Codex 安装路径不同，只改配置，不改脚本

