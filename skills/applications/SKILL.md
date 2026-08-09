---
name: applications
description: Discover and manage Seenode web, worker, and private applications — list/get apps, packages, build settings, restart/duplicate, scale, and trigger deployments. Use when the user asks about their Seenode apps, runtimes, build/start commands, ports, auto-deploy, or redeploys.
license: MIT
metadata:
  author: Seenode
  version: "0.2.2"
  category: applications
---

# Manage Seenode applications

## Types

| Type | Public URL | Custom domains | Port |
|------|------------|----------------|------|
| `web` | Yes (`*.seenode.app`) | Yes | Required |
| `worker` | No | No | Usually omit |
| `private` | No (internal only) | No | Required |

`list_applications` filters by type and defaults to `web`. Call again with `worker` / `private` when needed — there is no all-types list.

## Discovery

```
get_current_team()
list_applications(application_type="web", project_id=null, page=1)
get_application(application_id=...)
get_build_settings(application_id=...)
get_deployments(application_id=...)
list_images(image_type="application")
list_application_packages()
list_storage_packages()
```

Always `get_application` / `get_build_settings` before mutating so omitted fields can be carried forward.

## Update metadata / package / scale

```
update_application(
  application_id=...,
  custom_name=null,
  description=null,
  project_id=null,
  package_id=null,    # paid tier from list_application_packages — needs credit approval
  scale=null,         # 1–10 instance multiplier; must be 1 when storage is attached
  auto_deploy=null    # deploy-on-push toggle
)
```

Build/run commands, runtime image, port, root directory, and git branch are **not** here — use `update_build_settings`. Package ≠ runtime.

## Update build settings (redeploys)

```
update_build_settings(
  application_id=...,
  build_command=null,
  run_command=null,
  image_id=null,        # from list_images
  root_directory=null,
  port=null,
  git_branch=null
)
```

Side effect: starts a new build/deployment immediately. Prefer `wait_for_deployment` afterwards; use `get_application_logs` on failure.

Runtime changes mean changing `image_id` / creating with `runtime` — never via env vars named `RUNTIME`.

## Restart (no rebuild)

```
restart_application(application_id=...)
```

Restarts running instances without rebuilding from git. Requires at least one prior successful deployment. Env-var changes already trigger a similar restart.

## Duplicate

```
duplicate_application(application_id=...)
```

Clones settings, env vars, and domains into a new application and starts a deploy. Follow with `wait_for_deployment` / `get_deployments` on the new app id.

## Redeploy without settings changes

```
create_deployment(application_id=..., git_commit_sha=null)
wait_for_deployment(application_id=...)
```

Omit `git_commit_sha` for the newest commit on the configured branch; pass a SHA to redeploy/roll back to that commit. Cancel a stuck build with `cancel_deployment`.

## Create

Prefer the **deploy** skill for new apps (`create_application`, optional `create_database` → `link_database_to_application`). Require pushed GitHub/GitLab repo + connected provider (`get_git_connections`). Use `inspect_repository` when build/run hints are unclear.

## Storage

Persistent volumes: see the **storage** skill (`list_application_storage`, `create_application_storage`, …). Size tiers come from `list_storage_packages`.

## Safety

- No delete-application tool — send destructive cleanup to the dashboard.
- Package upgrades cost credit — confirm with the user first; quote `pricePerMonthUsd` and `get_credit_balance`’s `creditBalanceUsd`.
- Never invent application IDs; resolve via list/get.

## Relevant tools

`list_applications`, `get_application`, `create_application`, `update_application`, `restart_application`, `duplicate_application`, `list_application_packages`, `list_storage_packages`, `get_build_settings`, `list_images`, `update_build_settings`, `get_deployments`, `create_deployment`, `wait_for_deployment`, `cancel_deployment`, `get_git_connections`, `inspect_repository`, `get_credit_balance`
