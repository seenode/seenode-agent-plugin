---
name: storage
description: Manage persistent storage volumes on Seenode applications — list volumes, create/attach storage, resize or remount, and read usage metrics. Use when the user needs disk mounts, /data volumes, storage packages, or capacity checks on a Seenode app.
license: MIT
metadata:
  author: Seenode
  version: "0.2.0"
  category: storage
---

# Application storage on Seenode

Persistent volumes attach to a single application. Apps may have **at most one** active volume. Scale must be **1** when storage is attached.

## Discover packages and volumes

```
list_storage_packages()
list_application_storage(application_id=...)
```

Use package sizes (GiB) when creating or resizing. Confirm the app’s `scale` via `get_application` before attaching storage.

## Create / attach

```
create_application_storage(
  application_id=...,
  mount_path="/data",     # absolute path required
  size=null,              # GiB from list_storage_packages; default 5
  custom_name=null
)
```

Side effect: provisions asynchronously. Confirm with the user before paid size tiers; check `get_credit_balance` when spend is a concern. Quote package `pricePerMonthUsd` / `creditBalanceUsd` only (never DIY cents→dollars).

## Update (resize / remount / rename)

```
update_application_storage(
  application_id=...,
  storage_uuid=...,
  mount_path=null,
  size=null,              # can only increase — never shrink
  custom_name=null
)
```

Resizing is asynchronous — status becomes `RESIZING` until complete. Resolve `storage_uuid` from `list_application_storage`.

## Metrics

```
get_application_storage_metrics(
  application_id=...,
  storage_uuid=...,
  range_hours=24
)
```

Use for capacity pressure while troubleshooting disk-full symptoms.

## Safety

- No delete-storage tool via MCP — remove volumes in the dashboard.
- Do not attach storage when scale > 1; do not claim shrink/downgrade is possible.
- Inspect before mutate; preserve MCP approval prompts.

## Relevant tools

`list_storage_packages`, `list_application_storage`, `create_application_storage`, `update_application_storage`, `get_application_storage_metrics`, `get_application`, `get_credit_balance`

## Related skills

- **applications** — scale and package constraints
- **deploy** — optional volume during first ship
- **troubleshoot** — disk/capacity symptoms
- **billing** — credit before paid sizes
