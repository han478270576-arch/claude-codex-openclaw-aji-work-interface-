# claude-codex-openclaw Aji Work Interface

This project is a standalone terminal portal for managing:

- OpenClaw
- Claude Code
- Codex

It was extracted from an existing OpenClaw workflow and refactored into an independent, portable repository so it can be reused across future `codex + claude + openclaw` setups.

## Features

- Unified terminal entry point
- OpenClaw production and test environment controls
- Claude Code session browser
- Codex session browser
- Current-directory-aware session prioritization
- Pagination for large session lists
- Config-driven local deployment model
- Windows/WSL launcher installer

## Project Structure

- `bin/` executable scripts
- `config/` default and local configuration
- `docs/` setup and usage guides
- `lib/` shared config loading logic
- `scripts/` helper scripts

## Quick Start

Run inside WSL:

```bash
bash ./bin/claude-codex-openclaw.sh
```

Install Windows launchers:

```bash
bash ./scripts/install-launchers.sh
```

## Configuration

Start from:

- `config/local.env.example`

Then create your private machine-specific file:

- `config/local.env`

`config/local.env` is ignored by Git and should contain any local paths, tokens, or machine-specific overrides.

## Documentation

- Chinese install guide: `docs/INSTALL.zh-CN.md`
- Chinese usage guide: `docs/USAGE.zh-CN.md`
- Release notes: `RELEASE-v1.0.0.md`
- Changelog: `CHANGELOG.md`

## Current Status

`v1.0.0` is the first standalone release of the Aji work interface project.

