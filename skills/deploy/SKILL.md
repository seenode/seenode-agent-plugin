---
name: deploy
description: Deploy a GitHub or GitLab repository to Seenode end-to-end — analyze the codebase, create or update a web/worker/private application, wire env vars, poll deployments and logs, and return the *.seenode.app URL. Use when the user wants to deploy, host, publish, or ship an app on Seenode.
license: MIT
metadata:
  author: Seenode
  version: "0.1.0"
  category: deployment
---

# Deploy to Seenode

Drive a full deploy loop with the **Seenode MCP** until the deployment reaches `SUCCESSFUL` or you hit the fix budget. Prefer MCP tools over guesses. Never invent credentials.

## Product model (MCP surface)

Seenode hosts:

- **web** — public HTTP; gets a default `*.seenode.app` domain
- **worker** — background process; no public URL
- **private** — internal network only; no public URL / custom domains
- **MySQL / PostgreSQL** — managed databases (inspect/update via MCP; **create in the dashboard**)

Apps deploy from **GitHub** or **GitLab**. Team context comes from the OAuth token — call `get_current_team` when you need to confirm where resources will land.

### MCP capability gaps (do not invent workarounds)

| Gap | What to do |
|-----|------------|
| No `create_database` | Ask the user to create MySQL/PostgreSQL at [cloud.seenode.com](https://cloud.seenode.com), then wire connection env from values they provide (or dashboard copy). Never invent passwords. |
| No delete app/DB/domain | Do not claim you can delete; send destructive cleanup to the dashboard. |
| No wait helper | Poll `get_deployments` with short pauses; on failure read `get_application_logs`. |
| No static-site / cron / blueprint / key-value product types | Stay within web/worker/private + managed DBs. |

## Prerequisites

1. **MCP auth** — Call read-only `get_current_team` or `list_applications`. If auth fails, ask the user to complete Seenode OAuth for the plugin, then retry.
2. **Git remote pushed** — `git remote -v` and ensure the branch is on GitHub/GitLab. Seenode does not create repos or push code.
3. **Git provider connected** — `get_git_connections`. If a provider is disconnected, `connect_git_provider` → show `authorizationUrl` for the user to open → re-check with `get_git_connections`.

## Workflow

### 1. Confirm team and auth

```
get_current_team()
list_applications(application_type="web")
```

### 2. Analyze the local codebase

Inspect language, framework, package manager, build/start commands, listen port, Dockerfile (if any), env needs, and DB signals. Follow [references/codebase-analysis.md](references/codebase-analysis.md).

### 3. Resolve git source

```
get_git_connections()
list_git_repositories(provider="github"|"gitlab", query="<name>")
list_git_branches(repository="owner/repo", provider="...")
```

Use `owner/repo` (GitHub) or full namespace path (GitLab). Prefer the branch the user is on, else the repo `default_branch`.

### 4. Map runtime images

```
list_images(image_type="application")
```

Prefer explicit tags such as `node-22`, `python-3.12` (pass as `runtime` string) or the matching `image_id`. Runtime is **not** an environment variable.

### 5. Database (if needed)

If the app needs a DB:

1. `list_databases` — reuse an existing team DB when appropriate.
2. If none exists: tell the user to create MySQL or PostgreSQL in the [Seenode dashboard](https://cloud.seenode.com). Pause until they confirm and provide connection details (or paste from the dashboard).
3. Wire env on create (`environment_variables` + `secret_keys`) or later via `set_environment_variables`. Common keys: `DATABASE_URL` / `DATABASE_URI`, or `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASSWORD` / `DB_NAME` as the repo expects. Mark secrets in `secret_keys`. **Never echo secret values.**

### 6. Propose one plan, then create

Summarize for approval: app type, repo/branch, runtime, build/run commands, port, env keys (names only), DB wiring. Then:

```
create_application(
  git_repository="owner/repo",
  git_provider="github"|"gitlab",
  git_branch="<branch>|null",
  application_type="web"|"worker"|"private",
  runtime="node-22"|...,   # or image_id
  build_command="...",
  run_command="...",
  port=<int for web/private>,
  root_directory=null|"apps/web",
  environment_variables={...},
  secret_keys=["..."],
  project_id=null|<id>,
  custom_name=null|"..."
)
```

For an existing app: `get_application` → `update_build_settings` and/or `set_environment_variables` → `create_deployment` as needed.

### 7. Poll until terminal state

```
get_deployments(application_id=...)
```

States: `NEW`, `RUNNING`, `SUCCESSFUL`, `FAILED`, `CANCELLED`, `LIMITS`. On failure:

```
get_application_logs(application_id=..., log_types=["build","runtime"], limit=100)
```

Fix with the right tool (`update_build_settings`, `set_environment_variables`, local code + push + `create_deployment`), then poll again. **At most 3 fix cycles** per request; then explain root cause and ask before continuing.

### 8. Report success

On `SUCCESSFUL`, summarize with a markdown link to the default domain, e.g. [Open app](https://example.seenode.app). Mention DB wiring without secrets.

## Safety

- Inspect before mutate; describe the plan before side-effecting tools.
- Preserve MCP approval prompts — do not bypass user consent.
- Never delete production resources via MCP (unsupported); never invent credentials.
- Never paste secret env values into chat; say they were set.
- Env-var changes **restart** instances; they do **not** rebuild from git. Build/runtime/port/command changes use `update_build_settings` and **do** redeploy.

## Related skills

- **troubleshoot** — failed deploys / won't start
- **applications** — discover and manage existing apps
- **environment** — env vars and secrets
- **databases** — existing DBs and wiring
- **domains** — custom domains + DNS
- **projects** — team/project grouping
