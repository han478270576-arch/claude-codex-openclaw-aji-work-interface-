# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- `bootstrap-openclaw-host.sh` for reusable host initialization
- `setup-test-env.sh` for building and maintaining a test environment from an existing production OpenClaw setup
- `DEPLOY-OPENCLAW-HOST.zh-CN.md` for server rollout guidance
- `SERVER-ROLL-OUT-CHECKLIST.zh-CN.md` for operational rollout verification
- `ROADMAP.md` for version-planning and next-stage control-plane evolution

### Changed

- Project positioning expanded from standalone portal to reusable OpenClaw control plane
- Config templates now include control-plane-oriented prod/test options
- Documentation now covers host deployment and rollout acceptance workflow

## [v1.0.0] - 2026-03-11

### Added

- Initial standalone repository for the `claude-codex-openclaw` Aji work interface
- Unified terminal portal for:
  - OpenClaw
  - Claude Code
  - Codex
- OpenClaw runtime controls for:
  - production
  - test
  - status
  - TUI
  - promote
  - rollback
- Claude Code session browsing:
  - recent sessions
  - all sessions
  - current-directory prioritization
  - pagination
- Codex session browsing:
  - recent sessions
  - all sessions
  - current-directory prioritization
  - pagination
- Config-driven project layout:
  - `config/default.env`
  - `config/local.env.example`
  - ignored `config/local.env`
- Installer script for Windows/WSL launchers
- Chinese installation and usage documentation
- GitHub Release support for `v1.0.0`

### Notes

- This release focuses on extraction, portability, and project independence.
- Local machine secrets and runtime-only values are intentionally excluded from Git.
