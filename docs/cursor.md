# Cursor

Cursor loads this repository as a portable **Agent Plugin** (`plugin.json` + `mcp.json` + `skills/`). There is intentionally **no** `.cursor-plugin/` directory.

## Local install (development)

1. Clone the repo (or use your working copy):

```bash
git clone https://github.com/seenode/seenode-agent-plugin.git
```

2. Expose it under Cursor’s local plugins path:

```bash
mkdir -p ~/.cursor/plugins/local
ln -s "$(pwd)/seenode-agent-plugin" ~/.cursor/plugins/local/seenode
```

**Symlink restriction:** some Cursor builds restrict symlinked plugins. If the plugin does not appear after reload, copy instead:

```bash
rm -f ~/.cursor/plugins/local/seenode
cp -R "$(pwd)/seenode-agent-plugin" ~/.cursor/plugins/local/seenode
```

When using a copy, re-copy (or re-sync) after pulling updates.

3. Reload Cursor (Developer: Reload Window), open an agent chat, and complete Seenode OAuth when the MCP connects.

4. Smoke test:

```text
What is my current Seenode team? Use get_current_team.
```

## Marketplace

Public marketplace submission is a separate process — see [publishing.md](publishing.md). Until listed, use the local path above.

## Layout Cursor uses

| Path | Role |
|------|------|
| `plugin.json` | Agent Plugins 1.0 identity |
| `mcp.json` | `streamable-http` → `https://mcp.seenode.com/mcp` |
| `skills/*/SKILL.md` | Shared skills |

## Troubleshooting

- **MCP not authenticated** — re-run OAuth; try the MCP auth flow your Cursor build exposes for the Seenode server.
- **Skills missing** — confirm the plugin directory contains `skills/` with seven children and that Cursor reloaded.
- **Symlink ignored** — switch to the copy fallback above.
