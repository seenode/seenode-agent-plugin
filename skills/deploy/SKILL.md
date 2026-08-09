---
name: deploy
description: Deploy a GitHub or GitLab repository to Seenode end-to-end — preflight credits/team, create or reuse a database, inspect the repo, create a web/worker/private application, link the DB, wait for deployment, and return the *.seenode.app URL. Use when the user wants to deploy, host, publish, or ship an app on Seenode.
license: MIT
metadata:
  author: Seenode
  version: "0.2.2"
  category: deployment
---

# Deploy to Seenode

Drive a full deploy loop with the **Seenode MCP** until the deployment reaches `SUCCESSFUL` or you hit the fix budget. Prefer MCP tools over guesses. Never invent credentials. Never fetch or paste raw database passwords — wire DBs with `link_database_to_application`.

## Product model (MCP surface)

Seenode hosts:

- **web** — public HTTP; gets a default `*.seenode.app` domain
- **worker** — background process; no public URL
- **private** — internal network only; no public URL / custom domains
- **MySQL / PostgreSQL** — managed databases (`database_type` is `mysql` or `postgresql`, never `postgres`)

Apps deploy from **GitHub** or **GitLab**. Team context comes from the OAuth token — call `get_current_team` when you need to confirm where resources will land.

### Flagship recipe

```text
create_project? → create_database → poll get_database_state
  → inspect_repository → create_application
  → link_database_to_application → create_deployment / wait_for_deployment
```

Check `get_credit_balance` before paid creates. Quote `pricePerMonthUsd` / `creditBalanceUsd` only (never DIY cents→dollars).

### MCP capability gaps (do not invent workarounds)

| Gap | What to do |
|-----|------------|
| No delete app/DB/domain/project/storage | Do not claim you can delete; send destructive cleanup to the dashboard. |
| No static-site / cron / blueprint / key-value product types | Stay within web/worker/private + managed DBs (+ optional app storage). |

## Prerequisites

1. **MCP auth** — Call read-only `get_current_team` or `list_applications`. If auth fails, ask the user to complete Seenode OAuth for the plugin, then retry.
2. **Git remote pushed** — `git remote -v` and ensure the branch is on GitHub/GitLab. Seenode does not create repos or push code.
3. **Git provider connected** — `get_git_connections`. If a provider is disconnected, `connect_git_provider` → show `authorizationUrl` for the user to open → re-check with `get_git_connections`.

## Workflow

### 1. Confirm team, limits, and credits

```
get_current_team()
get_team_limits()
get_team_services_brief()
get_credit_balance()
list_applications(application_type="web")
```

Optional project grouping: `list_projects` / `create_project` (see **projects** skill). Package upgrades and paid creates consume credit — confirm with the user when balance is low.

### 2. Analyze the codebase (local + remote)

Inspect language, framework, package manager, build/start commands, listen port, Dockerfile (if any), env needs, and DB signals. Follow [references/codebase-analysis.md](references/codebase-analysis.md).

Also call the MCP inspector when the remote is known:

```
inspect_repository(repository="owner/repo", provider="github"|"gitlab", git_branch=null|"...")
```

Use returned command/env hints, then confirm against the local tree. Runtime is **not** an environment variable — map via `list_images` / `runtime` / `image_id`.

### 3. Resolve git source

```
get_git_connections()
list_git_repositories(provider="github"|"gitlab", query="<name>")
list_git_branches(repository="owner/repo", provider="...")
```

Use `owner/repo` (GitHub) or full namespace path (GitLab). Prefer the branch the user is on, else the repo default from `inspect_repository`.

### 4. Map runtime images and packages

```
list_images(image_type="application")
list_application_packages()   # optional paid CPU/memory tier
```

Prefer explicit tags such as `node-22`, `python-3.12` (pass as `runtime` string) or the matching `image_id`. Package ≠ runtime — packages are capacity tiers from `list_application_packages`.

### 5. Database (if needed)

If the app needs a DB:

1. `list_databases` — reuse an existing team DB when appropriate (`get_database` / `get_database_state`).
2. To create:

```
list_database_packages()   # optional paid tier; omit package_id for free-trial/cheapest
get_credit_balance()       # confirm before paid package
create_database(
  database_type="postgresql"|"mysql",   # default postgresql — not "postgres"
  database_version=null,
  custom_name=null,
  project_id=null,
  package_id=null
)
```

3. Poll until ready:

```
get_database_state(database_id=...)
```

4. **Do not** ask the user to paste DB passwords. After the app exists, wire with `link_database_to_application` (step 7).

### 6. Propose one plan, then create the application

Summarize for approval: app type, repo/branch, runtime, build/run commands, port, env keys (names only), DB plan, optional storage. Then:

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
  environment_variables={...},   # non-DB secrets/config only when needed
  secret_keys=["..."],
  package_id=null,
  project_id=null|<id>,
  custom_name=null|"..."
)
```

For an existing app: `get_application` → `update_build_settings` and/or `set_environment_variables` → `create_deployment` / `wait_for_deployment` as needed.

Optional persistent volume (scale must be 1): see **storage** skill (`list_storage_packages`, `create_application_storage`).

### 7. Link the database (never paste passwords)

```
link_database_to_application(
  application_id=...,
  database_id=...,
  env_prefix="DATABASE",   # → DATABASE_HOST/PORT/USER/PASSWORD/NAME/URL
  overwrite=true
)
```

After `rotate_database_user_password`, link again with `overwrite=true`. Prefer link over manually setting `DATABASE_URL` via `set_environment_variables`.

### 8. Wait until terminal state

`create_application` already starts a deploy. Prefer:

```
wait_for_deployment(application_id=..., deployment_uuid=null, timeout_seconds=300)
```

Or after an explicit redeploy:

```
create_deployment(application_id=...)
wait_for_deployment(application_id=...)
```

Inspect anytime with `get_deployments`. States: `NEW`, `RUNNING`, `SUCCESSFUL`, `FAILED`, `CANCELLED`, `LIMITS`. To abort an in-progress build: `cancel_deployment(application_id=..., deployment_uuid=...)`.

On failure:

```
get_application_logs(application_id=..., log_types=["build","runtime"], limit=100)
```

Fix with the right tool (`update_build_settings`, `set_environment_variables`, `link_database_to_application`, local code + push + `create_deployment`), then wait again. **At most 3 fix cycles** per request; then explain root cause and ask before continuing.

### 9. Optional custom domain

For `web` apps only — use the **domains** skill (`add_domain`, `check_domain_status`).

### 10. Report success

On `SUCCESSFUL`, summarize with a markdown link to the default domain, e.g. [Open app](https://example.seenode.app). Mention DB linking without secrets.

## Cross-cutting rules

- Runtime ≠ env var → `list_images` / create `runtime` / `update_build_settings`
- Package ≠ runtime → `list_application_packages` / `list_database_packages` + `update_application` / `update_database`
- Env changes **restart**; build-settings / `create_deployment` **rebuild**
- Speak credits and spend via `*Usd` fields only (`creditBalanceUsd`, `pricePerMonthUsd`; **billing** skill)

## Safety

- Inspect before mutate; describe the plan before side-effecting tools.
- Preserve MCP approval prompts — do not bypass user consent.
- Never delete production resources via MCP (unsupported); never invent credentials.
- Never paste secret env or DB password values into chat; say they were set or linked.
- Env-var changes **restart** instances; they do **not** rebuild from git. Build/runtime/port/command changes use `update_build_settings` and **do** redeploy.

## Relevant tools

`get_current_team`, `get_team_limits`, `get_team_services_brief`, `get_credit_balance`, `list_projects`, `create_project`, `get_git_connections`, `connect_git_provider`, `list_git_repositories`, `list_git_branches`, `inspect_repository`, `list_images`, `list_application_packages`, `list_database_packages`, `list_databases`, `create_database`, `get_database_state`, `list_applications`, `create_application`, `get_application`, `update_build_settings`, `link_database_to_application`, `list_storage_packages`, `create_application_storage`, `create_deployment`, `wait_for_deployment`, `get_deployments`, `cancel_deployment`, `get_application_logs`, `set_environment_variables`, `add_domain`, `check_domain_status`

## Related skills

- **troubleshoot** — failed deploys / won't start
- **applications** — discover and manage existing apps
- **environment** — env vars and secrets
- **databases** — create/link/rotate managed DBs
- **storage** — persistent volumes
- **domains** — custom domains + DNS
- **projects** — team/project grouping
- **billing** — credits and spend
