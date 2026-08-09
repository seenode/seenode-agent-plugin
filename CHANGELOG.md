# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.2] - 2026-08-09

### Changed

- Docs point account setup at `seenode.com/dashboard` (replacing `cloud.seenode.com`)
- Align package and skill `metadata.version` fields to `0.2.2` (fixes billing skill left at `0.3.0`)

## [0.2.1] - 2026-08-09

### Changed

- Billing and related skills quote MCP `*Usd` fields only; stop DIY cents→dollars conversion
- Aligns with hosted MCP USD-first money shaping (`creditBalanceUsd`, `totalCostUsd`, `pricePerMonthUsd`, etc.)

## [0.2.0] - 2026-08-09

### Changed

- Skills and docs track the expanded Seenode MCP (create/link databases, wait/cancel deployments, inspect repository, restart/duplicate apps, team limits, project assign/update)
- Deploy recipe rewritten: `create_database` → `get_database_state` → `inspect_repository` → `create_application` → `link_database_to_application` → `wait_for_deployment`
- Environment and database guidance prefers `link_database_to_application` over pasting DB passwords
- Removed public references to non-production MCP URLs and outdated “cannot create database” / “no wait helper” claims

### Added

- `storage` and `billing` workflow skills
- Example prompts for create/link DB, wait-for-deploy, and credit balance

## [0.1.0] - 2026-08-09

### Added

- Portable Agent Plugins 1.0 manifests (`plugin.json`, `mcp.json`) pointing at `https://mcp.seenode.com/mcp`
- Claude Code adapter (`.claude-plugin/`, `.mcp.json`, marketplace entry with `source: "."`)
- OpenAI Codex adapter (`.codex-plugin/plugin.json`) and `.app.json.example` placeholder
- Shared skills: `deploy`, `troubleshoot`, `applications`, `environment`, `databases`, `domains`, `projects`
- Documentation under `docs/`, MIT license, security and contributing guides
- `scripts/validate.sh` and GitHub Actions validation workflow
- Brand assets exported from Seenode website favicon/logo
