---
name: troubleshoot
description: Diagnose failed Seenode deployments and apps that will not start — inspect deployments, wait/cancel builds, build/runtime logs, metrics, env vars, build settings, restart apps, and re-link databases; apply fixes and redeploy. Use when a deploy fails, the app crashes, health checks fail, or the user mentions Seenode errors or logs.
license: MIT
metadata:
  author: Seenode
  version: "0.3.0"
  category: debugging
---

# Troubleshoot Seenode deployments

Identify the failing application, read deployment state and logs, classify the failure, fix via code and/or MCP settings, redeploy, and verify.

## Prerequisites

```
get_current_team()
list_applications(application_type="web")   # also try worker / private / static
```

If MCP auth fails, complete Seenode OAuth and retry.

## Workflow

### 1. Identify the application

```
list_applications(application_type="web"|"worker"|"private"|"static")
get_application(application_id=...)
get_build_settings(application_id=...)
```

Confirm name, type, git repo/branch, and current build settings before changing anything.

### 2. Check deployment state

```
get_deployments(application_id=...)
```

Prefer waiting instead of busy-polling:

```
wait_for_deployment(application_id=..., deployment_uuid=null, timeout_seconds=300)
```

To abort a stuck in-progress build:

```
cancel_deployment(application_id=..., deployment_uuid=...)
```

Use `liveDeployment` and `lastDeployment` plus `state`:

| State | Meaning |
|-------|---------|
| `NEW` / `RUNNING` | Still in progress — `wait_for_deployment` |
| `SUCCESSFUL` | Build/release OK; look at runtime/request logs if the app still misbehaves |
| `FAILED` | Read build then runtime logs |
| `CANCELLED` | Ask whether to redeploy |
| `LIMITS` | Team/plan limits — `get_team_limits` / **billing** skill |

### 3. Pull logs

```
get_application_logs(application_id=..., log_types=["build"], limit=100)
get_application_logs(application_id=..., log_types=["runtime"], limit=100)
get_application_logs(application_id=..., log_types=["request"], limit=50)   # if HTTP errors
```

Optional: `search` for a known string; `mode="history"` + `range_preset` for older windows.

### 4. Classify the failure

Match against [references/error-patterns.md](references/error-patterns.md). Common classes:

- Missing / wrong env vars
- Port binding (`127.0.0.1` only, wrong port)
- Build command / dependency failures
- Database connection (re-link, do not paste passwords)
- OOM / high memory (metrics) — not for static (no containers)
- Wrong runtime image
- Static: empty publish directory, missing SPA rewrite, `restart_application` 400

### 5. Check metrics when relevant

```
get_application_metrics(application_id=..., metric_type="memory", range_hours=1)
get_application_metrics(application_id=..., metric_type="cpu", range_hours=1)
```

Skip application metrics for **static** sites (no running containers).

For DB-related issues:

```
list_databases()
get_database(database_id=...)
get_database_state(database_id=...)
get_database_metrics(database_id=..., metric_type="connections"|"storage")
```

### 6. Inspect configuration (safely)

```
list_environment_variables(application_id=...)
```

Prefer masked listing. Use `reveal_environment_variables` only when the user explicitly needs plaintext non-secret values — treat revealed values as exposed.

### 7. Apply the fix

| Class | Fix tool |
|-------|----------|
| Runtime / build / start / port / branch / root dir | `update_build_settings` (triggers redeploy) |
| Missing or wrong non-DB env | `set_environment_variables` (containers restart; static: follow with `create_deployment`) |
| DB credentials / after password rotate | `link_database_to_application(..., overwrite=true)` |
| Remove bad keys | `delete_environment_variables` |
| Process needs fresh start (no rebuild) | `restart_application` (**not for static**) |
| Code bug | Fix locally → commit/push → `create_deployment` |
| Metadata / scale / auto_deploy / package | `update_application` (scale/package not for static) |
| Static routes/headers (SPA rewrite, redirects) | `update_application(..., static_routes=, static_headers=)` |
| Stuck in-progress deploy | `cancel_deployment` then redeploy if needed |

Carry forward omitted build-settings fields — the API replaces the whole record; the MCP tool carries forward omissions when used correctly.

After password rotation:

```
rotate_database_user_password(database_id=..., user_id=..., password=null)
link_database_to_application(application_id=..., database_id=..., overwrite=true)
```

### 8. Redeploy and verify

```
create_deployment(application_id=...)   # if you need a fresh git deploy
wait_for_deployment(application_id=...)
get_application_logs(application_id=..., log_types=["build","runtime"], limit=50)
```

For domain issues, use `check_domain_status` (see **domains**). Cap at **3 fix cycles**, then summarize root cause and ask before continuing.

## Safety

- Do not delete apps, databases, domains, projects, or storage (unsupported via MCP).
- Do not echo secrets or teach pasting DB passwords.
- Do not claim DNS/custom domains are live without `check_domain_status` → `ready: true` (use the **domains** skill).
- Preserve MCP approval for mutating tools.

## Relevant tools

`get_current_team`, `list_applications`, `get_application`, `get_build_settings`, `get_deployments`, `wait_for_deployment`, `cancel_deployment`, `create_deployment`, `get_application_logs`, `get_application_metrics`, `list_environment_variables`, `reveal_environment_variables`, `set_environment_variables`, `delete_environment_variables`, `update_build_settings`, `update_application`, `restart_application`, `list_databases`, `get_database`, `get_database_state`, `get_database_metrics`, `rotate_database_user_password`, `link_database_to_application`, `check_domain_status`, `get_team_limits`

## Related skills

- **deploy** — new end-to-end deploys
- **environment** — env var workflows
- **applications** — settings and discovery
- **databases** — DB create/link/rotate
- **billing** — credit / LIMITS issues
