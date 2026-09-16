# Seenode error patterns

Classify log lines, then apply the matching fix. Prefer one coherent fix pass over many tiny redeploys when the same class repeats.

## MISSING_ENV_VAR

**Signals:** `KeyError`, `process.env.X is undefined`, `required environment variable`, `config validation failed`, Django `ImproperlyConfigured`, Zod/env schema errors.

**Checks:**

```
list_environment_variables(application_id=...)
```

Compare keys to `.env.example` / app config. Missing non-DB secrets: ask the user for values. Missing DB keys: prefer `link_database_to_application`.

**Fix:**

```
set_environment_variables(
  application_id=...,
  variables={"KEY": "value"},
  secret_keys=["KEY"]   # when credential-like
)
```

Or for managed DBs:

```
link_database_to_application(application_id=..., database_id=..., overwrite=true)
```

Env updates restart instances; they do not rebuild. If the app needs a new build artifact, follow with `create_deployment` / `wait_for_deployment`. **Static:** env is always build-time — always follow with `create_deployment`.

## PORT_BINDING

**Signals:** `EADDRINUSE`, `listen EACCES`, connection refused on health, app only on `127.0.0.1`, "port already in use", platform cannot reach the process.

**Checks:** `get_build_settings` → `port`. Code must listen on `0.0.0.0` and the configured port (or `process.env.PORT` matching build settings).

**Fix:** Align code + `update_build_settings(..., port=<correct>)`. Workers should omit public ports.

## BUILD_FAILURE / MISSING_DEPENDENCY

**Signals:** `npm ERR!`, `Cannot find module`, `ModuleNotFoundError`, `command not found`, lockfile mismatch, TypeScript compile errors, `pip`/`poetry` failures.

**Checks:** `get_application_logs(..., log_types=["build"])`. Verify lockfile matches install command (`npm ci` vs `pnpm`).

**Fix:** Repair package manifests locally and push, and/or correct `build_command` via `update_build_settings`. Then `wait_for_deployment` (or poll `get_deployments`).

## WRONG_RUNTIME

**Signals:** syntax features not supported, native module ABI errors, wrong Python/Node version in logs.

**Checks:** `list_images(image_type="application")`, `get_build_settings`.

**Fix:** `update_build_settings(application_id=..., image_id=<id>)` (or recreate with correct `runtime`). Do **not** set `RUNTIME` as an env var expecting a language change.

## DATABASE_CONNECTION

**Signals:** `ECONNREFUSED`, `password authentication failed`, `SSL required`, `timeout connecting to`, `unknown database`, Prisma `P1001` / `P1000`.

**Checks:**

```
list_databases()
get_database(database_id=...)
get_database_state(database_id=...)
list_environment_variables(application_id=...)
get_database_metrics(database_id=..., metric_type="connections")
```

**Fix:** Prefer `link_database_to_application(..., overwrite=true)` — never invent or paste passwords. If no DB exists, `create_database` → poll `get_database_state` → link. After `rotate_database_user_password`, link again with `overwrite=true`. Confirm readiness via `get_database_state`, not by echoing secrets.

## START_COMMAND

**Signals:** build succeeds, runtime exits immediately, `npm start` missing script, wrong module path (`dist/main` missing).

**Fix:** Correct `run_command` (and build output paths) via `update_build_settings`. Ensure build actually emits the files the start command expects. If settings look correct but the process is wedged, try `restart_application` (not for static).

## OUT_OF_MEMORY

**Signals:** exit code `137`, `JavaScript heap out of memory`, process killed, OOM killer.

**Checks:**

```
get_application_metrics(application_id=..., metric_type="memory", range_hours=1)
```

**Fix:** Reduce memory use in code/build; or discuss package/scale changes via `update_application` / `list_application_packages` (package changes consume team credit). Do not silently upgrade paid tiers without user approval.

## LIMITS

**Signals:** deployment `state` = `LIMITS`, quota errors in API responses.

**Fix:** Explain with `get_team_limits` / `get_credit_balance` / **billing** skill. Do not invent credits.

## HEALTH / HTTP 5xx AFTER SUCCESSFUL DEPLOY

**Signals:** `lastDeployment.state` is `SUCCESSFUL` but users see 502/503 or empty responses.

**Checks:** runtime + request logs; port binding; required env; DB connectivity (`link_database_to_application`); metrics; optional `restart_application`.

**Fix:** Treat as runtime misconfiguration (often port, env, or DB link), not a failed build.

## GIT / AUTHORIZATION

**Signals:** cannot list repositories, clone/auth errors, provider not connected.

**Checks:** `get_git_connections` → `connect_git_provider` → user completes browser flow → re-check. Ensure the repo is within the installed GitHub App / GitLab permissions. `inspect_repository` can also surface provider auth failures.

## STUCK_DEPLOY

**Signals:** deployment stays `NEW`/`RUNNING` far too long; user wants to abort.

**Fix:** `cancel_deployment(application_id=..., deployment_uuid=...)` then investigate logs and redeploy with `create_deployment` / `wait_for_deployment` if appropriate.

## STATIC_PUBLISH_DIR

**Signals:** empty publish directory after SUCCESSFUL deploy, origin 404s for every path, build logs say no files uploaded.

**Checks:** `get_build_settings` → `publishDirectory`. Confirm the build emits that folder relative to `rootDirectory`.

**Fix:** `update_build_settings(..., publish_directory="<correct>")` then `wait_for_deployment`.

## STATIC_SPA_REWRITE

**Signals:** `/` works but client-side routes 404 on refresh; deep links fail.

**Fix:** `update_application` with `static_routes=[{type:"rewrite", source:"/*", destination:"/index.html"}]` (no rebuild), or create with `client_side_routing=true`.

## STATIC_NO_CONTAINER

**Signals:** `restart_application`, storage, scale, or application metrics return 400.

**Fix:** Do not restart a static site. Env changes need `create_deployment`. Storage/scale/runtime metrics are unsupported.

## Fix budget

After **3** mutate → redeploy → verify cycles without success, stop, report the best root-cause hypothesis with log evidence, and ask before continuing.
