# Claude Code

Claude Code uses the `.claude-plugin/` adapter and Claude-native `.mcp.json` (`type: "http"`, same production URL, no auth headers).

## Install from this repo (marketplace style)

From a clone of this repository:

```bash
claude plugin marketplace add /absolute/path/to/seenode-agent-plugin
claude plugin install seenode@seenode
```

The bundled [`.claude-plugin/marketplace.json`](../.claude-plugin/marketplace.json) registers a single plugin with `"source": "."`.

## Local testing with `--plugin-dir`

```bash
claude --plugin-dir /absolute/path/to/seenode-agent-plugin
```

Useful while iterating on skills without publishing.

## Validate (when CLI available)

```bash
claude plugin validate .
```

CI runs this check when `claude` is on `PATH`; it is non-fatal if the CLI is missing.

## MCP config

[`.mcp.json`](../.mcp.json):

```json
{
  "seenode": {
    "type": "http",
    "url": "https://mcp.seenode.com/mcp"
  }
}
```

Referenced from [`.claude-plugin/plugin.json`](../.claude-plugin/plugin.json) via `"mcpServers": "./.mcp.json"`.

Complete OAuth when Claude Code prompts for the Seenode MCP server.

## Smoke test

```text
Use get_current_team and summarize my Seenode team.
```
