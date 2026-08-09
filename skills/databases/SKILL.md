---
name: databases
description: Create, inspect, update, rotate, and link Seenode MySQL/PostgreSQL databases to applications via MCP. Use when the user asks about Seenode databases, provisioning, connection wiring, password rotation, DB metrics, or renaming/moving a database. Prefer link_database_to_application — never paste DB passwords.
license: MIT
metadata:
  author: Seenode
  version: "0.2.0"
  category: databases
---

# Seenode databases

Managed engines: **MySQL** and **PostgreSQL**. Use `database_type` values `mysql` or `postgresql` (never `postgres`).

## Hard rules

- **Never** fetch, echo, or ask the user to paste raw DB passwords or full connection strings into chat.
- Wire apps with `link_database_to_application` (server-side copy into secret env vars).
- After `rotate_database_user_password`, call `link_database_to_application` again with `overwrite=true`.
- Poll `get_database_state` until ready before linking.
- Check `get_credit_balance` before paid package creates/upgrades; quote `pricePerMonthUsd` and `creditBalanceUsd` (never DIY cents→dollars).
- There is **no** delete/destroy database tool via MCP — send teardown to the dashboard.

## Discover

```
list_databases(project_id=null, page=1)
get_database(database_id=...)
get_database_state(database_id=...)
list_database_packages()
```

Secret-looking fields (passwords, connection strings) are **redacted** in MCP responses. Do not hunt for connection-details patterns — use the link tool.

## Create

```
get_credit_balance()
list_database_packages()   # optional; omit package_id for free-trial/cheapest create-enabled package
create_database(
  database_type="postgresql"|"mysql",
  database_version=null,
  custom_name=null,
  description=null,
  project_id=null,
  package_id=null
)
```

Provisioning is asynchronous. Poll:

```
get_database_state(database_id=...)
```

Then continue the **deploy** recipe (`create_application` → `link_database_to_application`) or link an existing app.

## Metrics

```
get_database_metrics(database_id=..., metric_type="storage"|"connections", range_hours=1)
```

Use for disk pressure and connection saturation while troubleshooting.

## Update metadata / package / project

```
update_database(
  database_id=...,
  custom_name=null,
  description=null,
  project_id=null,
  package_id=null   # paid tier; storage cannot be downgraded below data size
)
```

Package changes consume team credit — get explicit approval.

## Rotate password

```
rotate_database_user_password(database_id=..., user_id=..., password=null)
```

Omit `password` to let the API generate one (never returned). Then immediately:

```
link_database_to_application(
  application_id=...,
  database_id=...,
  env_prefix="DATABASE",
  overwrite=true
)
```

## Link an application

Prefer this over `set_environment_variables` for DB credentials:

```
link_database_to_application(
  application_id=...,
  database_id=...,
  env_prefix="DATABASE",   # DATABASE_HOST, _PORT, _USER, _PASSWORD, _NAME, _URL
  overwrite=true
)
```

Set `overwrite=false` only when you must fail if target keys already exist. Match `env_prefix` to what the app expects when the repo uses a non-default prefix.

Verify with app runtime logs / a successful deploy — not by echoing secrets.

## What MCP cannot do

- Delete/destroy databases
- Manage non-Seenode engines (e.g. MongoDB, Redis) as platform DBs
- Return raw passwords after rotate or create

## Relevant tools

`list_databases`, `get_database`, `get_database_state`, `list_database_packages`, `create_database`, `update_database`, `rotate_database_user_password`, `link_database_to_application`, `get_database_metrics`, `get_credit_balance`

## Related skills

- **deploy** — full deploy loop including create → state → link → wait
- **environment** — non-DB env vars; prefer link for DB secrets
- **troubleshoot** — connection error patterns
- **billing** — credit balance before paid packages
