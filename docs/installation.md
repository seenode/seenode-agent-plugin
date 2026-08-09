# Installation

The Seenode Agent Plugin packages portable Agent Plugins 1.0 manifests, shared skills, and thin adapters for Cursor, Claude Code, and OpenAI clients. All clients talk to the same production MCP:

```text
https://mcp.seenode.com/mcp
```

Auth is **OAuth 2.1 + PKCE** against Seenode. Do not add `Authorization` headers or API keys to plugin config.

## Choose your client

| Client | Doc |
|--------|-----|
| Cursor | [cursor.md](cursor.md) |
| Claude Code | [claude.md](claude.md) |
| OpenAI (ChatGPT / Codex) | [openai.md](openai.md) |

## After install (all clients)

1. Reload or restart the client if it does not pick up the plugin automatically.
2. Complete the Seenode OAuth consent when prompted.
3. Smoke-test with a read-only prompt:
   - “Call `get_current_team` and tell me which Seenode team I’m using.”
   - or “List my Seenode web applications.”
4. Only then run mutating flows (create app or database, link DB, set secrets, add domain, billing mutations).

## Requirements

- A Seenode account ([seenode.com/dashboard](https://seenode.com/dashboard))
- For deploys: a GitHub or GitLab repository the account can connect via Seenode’s git integration
- Client support for Agent Skills and MCP (per client doc)
