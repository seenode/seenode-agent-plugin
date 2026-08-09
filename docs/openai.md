# OpenAI (ChatGPT / Codex)

OpenAI packaging uses [`.codex-plugin/plugin.json`](../.codex-plugin/plugin.json) with:

- `"skills": "./skills/"`
- `"mcpServers": "./.mcp.json"`
- Interface metadata (display name **Seenode**, privacy/terms URLs, starter prompts)
- **No** `"apps"` entry until a real ChatGPT app / connector ID exists

## App ID placeholder

[`.app.json.example`](../.app.json.example) shows the mapping shape:

```json
{
  "apps": {
    "seenode": {
      "id": "plugin_asdk_app_REPLACE_ME",
      "required": true
    }
  }
}
```

When Seenode receives a real `plugin_asdk_app_*` (or connector) ID from OpenAI registration:

1. Copy `.app.json.example` → `.app.json` and replace the placeholder.
2. Add `"apps": "./.app.json"` to `.codex-plugin/plugin.json`.
3. Follow [publishing.md](publishing.md) for ChatGPT / Codex submission.

Until then, **do not claim** end-to-end ChatGPT or Codex marketplace validation.

## Local Codex use (skills + MCP)

Depending on your Codex / ChatGPT developer workflow:

- Point the client at this plugin directory so it loads `.codex-plugin/plugin.json`
- Ensure `.mcp.json` is reachable for the Seenode HTTP MCP
- Complete OAuth when prompted

Exact install UX varies by OpenAI product surface; treat registration + store listing as manual steps owned by Seenode.

## Starter prompts (shipped in interface metadata)

- Deploy this repository to Seenode as a web app
- Why did my latest Seenode deployment fail?
- List my Seenode applications and their deploy status
- Add a custom domain to my Seenode web app and show DNS records
