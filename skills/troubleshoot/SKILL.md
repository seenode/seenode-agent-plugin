---
name: troubleshoot
description: Diagnose failed Seenode deployments and apps that will not start — inspect deployments, build/runtime logs, metrics, env vars, and build settings; apply fixes and redeploy. Use when a deploy fails, the app crashes, health checks fail, or the user mentions Seenode errors or logs.
license: MIT
metadata:
  author: Seenode
  version: "0.1.0"
  category: debugging
---

# Troubleshoot Seenode deployments

Identify the failing application, read deployment state and logs, classify the failure, fix via code and/or MCP settings, redeploy, and verify.

## Prerequisites

```
get_current_team()
list_applications(application_type="web")   # also try worker / private
```

If MCP auth fails, complete Seenode OAuth and retry.

## Workflow

### 1. Identify the application

```
list_applications(application_type="web"|"worker"|"private")
get_application(application_id=...)
get_build_settings(application_id=...)
```

Confirm name, type, git repo/branch, and current build settings before changing anything.

### 2. Check deployment state

```
get_deployments(application_id=...)
```

Use `liveDeployment` and `lastDeployment` plus `state`:

| State | Meaning |
|-------|---------|
| `NEW` / `RUNNING` | Still in progress — wait and poll |
| `SUCCESSFUL` | Build/release OK; look at runtime/request logs if the app still misbehaves |
| `FAILED` | Read build then runtime logs |
| `CANCELLED` | Ask whether to redeploy |
| `LIMITS` | Team/plan limits — explain and point to dashboard/billing |

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
- Database connection
- OOM / high memory (metrics)
- Wrong runtime image

### 5. Check metrics when relevant

```
get_application_metrics(application_id=..., metric_type="memory", range_hours=1)
get_application_metrics(application_id=..., metric_type="cpu", range_hours=1)
```

For DB-related issues:

```
list_databases()
get_database(database_id=...)
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
| Missing or wrong env | `set_environment_variables` (restarts; no git rebuild) |
| Remove bad keys | `delete_environment_variables` |
| Code bug | Fix locally → commit/push → `create_deployment` |
| Metadata / scale / auto_deploy | `update_application` |

Carry forward omitted build-settings fields — the API replaces the whole record; the MCP tool carries forward omissions when used correctly.

### 8. Redeploy and verify

```
create_deployment(application_id=...)   # if env-only fix did not need rebuild but you need a fresh git deploy
get_deployments(application_id=...)
get_application_logs(application_id=..., log_types=["build","runtime"], limit=50)
```

Cap at **3 fix cycles**, then summarize root cause and ask before continuing.

## Safety

- Do not delete apps, databases, or domains (unsupported via MCP).
- Do not echo secrets.
- Do not claim DNS/custom domains are live without `check_domain_status` → `ready: true` (use the **domains** skill).
- Preserve MCP approval for mutating tools.

## Related skills

- **deploy** — new end-to-end deploys
- **environment** — env var workflows
- **applications** — settings and discovery
- **databases** — DB inspection and wiring
