# Seenode Agent Plugin

Install Seenode into Cursor, Claude Code, and OpenAI (ChatGPT / Codex) so agents can deploy and operate apps on [Seenode](https://seenode.com) through the hosted MCP at `https://mcp.seenode.com/mcp`.

This repository is a **portable Agent Plugin**: shared skills plus thin client adapters. The MCP server implementation is proprietary platform software and is **not** included here. Authentication is OAuth — no API keys or bearer tokens belong in plugin config.

## Discoverability

Use this plugin when you want an AI coding agent to:

- Deploy a GitHub or GitLab repo to Seenode as a web, worker, or private app
- Debug failed builds and runtime crashes with logs and metrics
- Manage environment variables, custom domains, projects, and existing MySQL/PostgreSQL databases

## Architecture

```text
Agent client (Cursor / Claude Code / Codex)
  └── Seenode Agent Plugin (this repo)
        ├── skills/          shared workflow instructions
        └── mcp config       → https://mcp.seenode.com/mcp (OAuth)
              └── Seenode platform API
```

## Install

| Client | Guide |
|--------|--------|
| Cursor | [docs/cursor.md](docs/cursor.md) |
| Claude Code | [docs/claude.md](docs/claude.md) |
| OpenAI ChatGPT / Codex | [docs/openai.md](docs/openai.md) |

Overview: [docs/installation.md](docs/installation.md). Marketplace publishing: [docs/publishing.md](docs/publishing.md).

After install, complete Seenode OAuth when prompted, then try a read-only smoke prompt such as “What is my current Seenode team?”

## Example prompts

- “Deploy this repository to Seenode as a web app.”
- “Why did my latest Seenode deployment fail?”
- “List my Seenode applications and their deploy status.”
- “Add `example.com` to my Seenode web app and show the DNS records.”
- “Set `DATABASE_URL` on app 123 as a secret from the value I’ll paste.”

## Skills

| Skill | Purpose |
|-------|---------|
| [`deploy`](skills/deploy/SKILL.md) | End-to-end deploy from a git repo |
| [`troubleshoot`](skills/troubleshoot/SKILL.md) | Failed deploys and apps that won’t start |
| [`applications`](skills/applications/SKILL.md) | Discover and manage web/worker/private apps |
| [`environment`](skills/environment/SKILL.md) | Env vars and secrets |
| [`databases`](skills/databases/SKILL.md) | Inspect/update existing DBs; wire apps (create via dashboard) |
| [`domains`](skills/domains/SKILL.md) | Custom domains and DNS verification |
| [`projects`](skills/projects/SKILL.md) | Team context and project grouping |

### MCP gaps skills respect

- No database **creation** via MCP — use [cloud.seenode.com](https://cloud.seenode.com)
- No delete tools for apps, databases, or domains
- No static-site / cron / blueprint / key-value product types on this MCP surface
- Poll `get_deployments` / logs instead of a wait helper

## Security

- OAuth-only MCP config (no static secrets in manifests)
- Skills instruct agents not to echo secret env values
- Vulnerability reports: see [SECURITY.md](SECURITY.md) → **help@seenode.com**

## Development

```bash
./scripts/validate.sh
```

See [docs/development.md](docs/development.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © Seenode
