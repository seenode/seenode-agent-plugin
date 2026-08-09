# Development

## Layout

```text
plugin.json / mcp.json     # portable Agent Plugins 1.0
.mcp.json                  # Claude / Codex HTTP MCP adapter
.claude-plugin/            # Claude Code metadata + marketplace
.codex-plugin/             # OpenAI Codex metadata
.app.json.example          # OpenAI apps mapping template
skills/                    # shared skills (canonical)
docs/                      # human docs
scripts/validate.sh        # CI entrypoint
assets/                    # icon.png, logo.png
```

No `.cursor-plugin/`. No MCP server source.

## Validate locally

```bash
./scripts/validate.sh
```

The script:

1. Parses all JSON manifests
2. Validates `plugin.json` / `mcp.json` against pinned Agent Plugins 1.0 schemas in `schemas/` (refreshed from the [agent-plugins-spec](https://github.com/agentplugins/agent-plugins-spec) GitHub raw URLs if missing; the canonical `$id` remains on agent-plugins.org)
3. Enforces skill folder rules (`SKILL.md` + matching `name`)
4. Checks relative paths in Claude/OpenAI adapters
5. Sync-checks name/version/MCP URL across manifests
6. Runs secret heuristics (`Bearer `, obvious API keys, client secrets)
7. Optionally runs `claude plugin validate .` when `claude` is installed (non-fatal if missing)

## Editing skills

- Change only `skills/<name>/` for skill content
- Keep tool names aligned with the live Seenode MCP (see README gaps)
- Put long checklists under `references/`
- Re-run `./scripts/validate.sh`

## Editing manifests

When bumping version, update **all** of:

- `plugin.json`
- `.claude-plugin/plugin.json`
- `.codex-plugin/plugin.json`
- `CHANGELOG.md`

MCP URL must stay `https://mcp.seenode.com/mcp` in both `mcp.json` and `.mcp.json` unless intentionally changing environments (not for release).

## Brand assets

Source marks live in the Seenode website repo (`favicon.svg`, `logo-white.svg`). Regenerate PNGs into `assets/icon.png` and `assets/logo.png` if the brand changes — do not invent alternate logos.

## Manual tests

See the testing notes in [publishing.md](publishing.md) and the verify section of the project plan: local plugin load + OAuth, Claude CLI validate, OpenAI registration, and a full mutating deploy are environment-dependent.
