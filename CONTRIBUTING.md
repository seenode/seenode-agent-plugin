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
- Invented MCP tools or unsupported product types (e.g. claiming `create_database` exists)
- A `.cursor-plugin/` directory (Cursor loads the portable Agent Plugin format)

## Skills guidelines

- Keep `SKILL.md` action-oriented; put deep checklists in `references/`
- Frontmatter must include `name` and `description`; `name` must match the directory
- Document MCP gaps honestly (no database create, no deletes, poll instead of wait helpers)
- Prefer inspect → plan → mutate → verify

## Pull requests

- Keep changes focused; update `CHANGELOG.md` for user-visible changes
- Ensure `./scripts/validate.sh` passes
- Do not commit `.app.json` with a real OpenAI app ID unless intentionally publishing that mapping (use `.app.json.example` for the template)

## License

By contributing, you agree that your contributions are licensed under the MIT License.
