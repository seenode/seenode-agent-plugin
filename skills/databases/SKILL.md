---
name: databases
description: Inspect and update existing Seenode MySQL/PostgreSQL databases, review metrics, and wire connection settings into applications. Use when the user asks about Seenode databases, connection env vars, DB metrics, or renaming/moving a database. Cannot create databases via MCP — guide users to the dashboard.
license: MIT
metadata:
  author: Seenode
  version: "0.1.0"
  category: databases
---

# Seenode databases

Managed engines: **MySQL** and **PostgreSQL**.

## Hard limit: no create via MCP

There is **no** `create_database` tool on the Seenode MCP. When a new database is required:

1. Tell the user to create MySQL or PostgreSQL in the [Seenode dashboard](https://cloud.seenode.com).
2. Wait until they confirm creation.
3. `list_databases` / `get_database` to locate it.
4. Wire connection details they provide into the app with `set_environment_variables` (secrets in `secret_keys`).

Never invent hosts, users, or passwords. Never claim you created a database through MCP.

## Discover

```
list_databases(project_id=null, page=1)
get_database(database_id=...)
```

Secret-looking fields (passwords, connection strings) are **redacted** in MCP responses. Obtain real credentials from the user or dashboard UI when wiring apps.

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

## Wire an application

1. Confirm DB exists (`list_databases`).
2. Ask the user for connection values from the dashboard (URL or host/port/user/password/name).
3. Match the repo’s expected env shape (`DATABASE_URL` vs `DB_HOST`…).
4. Set via create-time `environment_variables` or:

```
set_environment_variables(
  application_id=...,
  variables={"DATABASE_URL": "..."},
  secret_keys=["DATABASE_URL"]
)
```

5. Verify with app runtime logs / a successful deploy — not by echoing secrets.

## What MCP cannot do

- Create or delete databases
- Reset passwords programmatically (use dashboard)
- Manage non-Seenode engines (e.g. MongoDB, Redis) as platform DBs

## Related skills

- **deploy** — full deploy loop including DB gating
- **environment** — env var mechanics
- **troubleshoot** — connection error patterns
