# Publishing

Manual checklists for each distribution channel. This repository does not automate marketplace submission.

## Common preflight

- [ ] `./scripts/validate.sh` passes
- [ ] Version bumped consistently (`plugin.json`, Claude, Codex adapters, `CHANGELOG.md`)
- [ ] No secrets in git (`Bearer `, API keys, `.env`, real `.app.json` IDs committed by mistake)
- [ ] Skills only reference real MCP tools
- [ ] README / docs still match production MCP URL `https://mcp.seenode.com/mcp`
- [ ] GitHub repo description/topics set (after first push), e.g. `seenode`, `mcp`, `agent-plugins`, `cursor`, `claude-code`, `codex`

Suggested GitHub about text:

> Portable Agent Plugin for Seenode — skills + MCP config for Cursor, Claude Code, and OpenAI.

## Cursor

- [ ] Local install works via `~/.cursor/plugins/local/seenode` (symlink or copy)
- [ ] OAuth completes against production MCP
- [ ] Read-only smoke: `get_current_team` / `list_applications`
- [ ] Submit to Cursor’s plugin marketplace per current Cursor publisher docs (process is external; no automated submission from this repo)
- [ ] Confirm marketplace listing uses portable Agent Plugin layout (no `.cursor-plugin/` required)

## Claude Code

- [ ] `claude plugin validate .` succeeds with Claude Code CLI
- [ ] Marketplace add from git URL or path works (`marketplace.json` → plugin `source: "."`)
- [ ] `claude plugin install seenode@seenode` (or equivalent) loads skills + MCP
- [ ] OAuth + read-only smoke
- [ ] Publish/list per Anthropic’s current plugin marketplace process

## OpenAI (ChatGPT / Codex)

Blocked until Seenode has a real app / connector ID:

- [ ] Register the Seenode MCP / app with OpenAI; obtain `plugin_asdk_app_*` (or current connector ID)
- [ ] Create `.app.json` from `.app.json.example` with the real ID
- [ ] Add `"apps": "./.app.json"` to `.codex-plugin/plugin.json`
- [ ] Verify interface metadata (privacy/terms/homepage/logo)
- [ ] Install in ChatGPT and Codex; OAuth + read-only smoke
- [ ] Only then claim end-to-end OpenAI validation in public docs

## Post-publish smoke (mutating — optional, staging team)

- [ ] Scenario A: deploy a small test repo (`create_application`) with user approval; optionally `create_database` → `link_database_to_application` → `wait_for_deployment`
- [ ] Confirm `*.seenode.app` URL and `SUCCESSFUL` deployment
- [ ] Tear down test resources in the dashboard (destroy remains dashboard-only — no delete tools via MCP)
