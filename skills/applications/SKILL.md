---
name: applications
description: Discover and manage Seenode web, worker, and private applications — list/get apps, inspect and update build settings, metadata, scale, and trigger deployments. Use when the user asks about their Seenode apps, runtimes, build/start commands, ports, auto-deploy, or redeploys.
license: MIT
metadata:
  author: Seenode
  version: "0.1.0"
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
```

Always `get_application` / `get_build_settings` before mutating so omitted fields can be carried forward.

## Update metadata / package / scale

```
update_application(
  application_id=...,
  custom_name=null,
  description=null,
  project_id=null,
  package_id=null,    # paid tier; needs team credit — get approval
  scale=null,         # 1–10 instance multiplier
  auto_deploy=null    # deploy-on-push toggle
)
```

Build/run commands, runtime image, port, root directory, and git branch are **not** here — use `update_build_settings`.

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

Side effect: starts a new build/deployment immediately. Poll `get_deployments` and use `get_application_logs` on failure.

Runtime changes mean changing `image_id` / creating with `runtime` — never via env vars named `RUNTIME`.

## Redeploy without settings changes

```
create_deployment(application_id=..., git_commit_sha=null)
```

Omit `git_commit_sha` for the newest commit on the configured branch; pass a SHA to redeploy/roll back to that commit.

## Create

Prefer the **deploy** skill for new apps (`create_application`). Require pushed GitHub/GitLab repo + connected provider (`get_git_connections`).

## Safety

- No delete-application tool — send destructive cleanup to the dashboard.
- Package upgrades cost credit — confirm with the user first.
- Never invent application IDs; resolve via list/get.
