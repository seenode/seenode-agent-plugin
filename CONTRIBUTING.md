# Contributing

Thanks for helping improve the Seenode Agent Plugin.

## Development setup

1. Clone this repository.
2. Read [docs/development.md](docs/development.md).
3. Run validation:

```bash
./scripts/validate.sh
```

## What belongs here

- Portable Agent Plugin manifests (`plugin.json`, `mcp.json`)
- Thin Claude Code / OpenAI Codex adapters
- Shared skills under `skills/` that use **real** Seenode MCP tool names only
- Documentation and brand assets

## What does not belong here

- MCP server source code
- Secrets, tokens, or `Authorization` headers in config
- Invented MCP tools or unsupported product types
- Operator / platform internals (OAuth DCR, k8s secrets, introspection endpoints, API-token curl recipes, non-production MCP URLs)
- A `.cursor-plugin/` directory (Cursor loads the portable Agent Plugin format)

## Skills guidelines

- Keep `SKILL.md` action-oriented; put deep checklists in `references/`
- Frontmatter must include `name` and `description`; `name` must match the directory
- Track the platform MCP tool registry (`platform/apps/mcp/service/tools/`): every registered tool should appear in at least one skill; do not invent tool names
- Document remaining gaps honestly (no destroy for apps/DBs/domains/projects/storage; no static-site/cron/blueprint/key-value types)
- Teach `create_database` → `get_database_state` → `link_database_to_application`; never teach pasting DB passwords
- Prefer `wait_for_deployment` over busy-polling; confirm before billing money mutations
- Prefer inspect → plan → mutate → verify

## Pull requests

- Keep changes focused; update `CHANGELOG.md` for user-visible changes
- Ensure `./scripts/validate.sh` passes
- Do not commit `.app.json` with a real OpenAI app ID unless intentionally publishing that mapping (use `.app.json.example` for the template)

## License

By contributing, you agree that your contributions are licensed under the MIT License.
