---
name: projects
description: Work with Seenode team context and optional project grouping — list teams, limits, and services brief; list/get/create/update projects; assign apps or databases; inspect project resources. Use when organizing resources, confirming which team the MCP token uses, or creating a project before deploy.
license: MIT
metadata:
  author: Seenode
  version: "0.3.0"
  category: organization
---

# Teams and projects on Seenode

## Team context

The OAuth / API token pins a **single team**. Most tools operate inside that team.

```
get_current_team()          # preferred — team + user for this token
list_teams()                # every team the token can reach (rarely needed)
get_team_limits()           # free-tier service limits
get_team_services_brief()   # short list of apps + databases on the team
```

Call `get_current_team` when confirming where new apps, databases, or projects will be created. Use `get_team_limits` / `get_team_services_brief` before large creates when capacity is in doubt.

## Projects

Projects are optional groupings. Creating a project has **no cost** and does **not** deploy anything.

### List / get / resources

```
list_projects()
get_project(project_id=...)
get_project_resources(project_id=...)
```

### Create

```
create_project(
  name="my-project",          # min 3 chars, unique in the team
  description=null,
  environment="production"|"development"|"staging"|"testing"|null,
  icon=null
)
```

### Update

```
update_project(
  project_id=...,
  name=null,
  description=null,
  environment=null,
  icon=null
)
```

### Assign resources

```
assign_project_services(
  project_id=...,
  application_ids=[...],   # optional
  database_ids=[...]       # optional — pass at least one list
)
```

Moves listed services onto this project (does not un-assign omitted ids). You can also pass `project_id` when:

- `create_application(..., project_id=...)`
- `update_application(..., project_id=...)`
- `create_database(..., project_id=...)`
- `update_database(..., project_id=...)`
- Filtering: `list_applications(..., project_id=...)`, `list_databases(project_id=...)`

## Typical flow before a deploy

1. `get_current_team()` — confirm team
2. Optionally `get_team_limits()` / `get_team_services_brief()`
3. `list_projects()` — reuse, `create_project`, or `update_project`
4. Continue with the **deploy** skill, passing `project_id` into `create_application` / `create_database` when desired
5. Or `assign_project_services` for existing resources; verify with `get_project_resources`

## Safety

- Do not invent team or project IDs.
- Project creation is organizational only — still require git + `create_application` to ship code.
- No delete-project tool via MCP — send teardown to the dashboard.

## Relevant tools

`list_teams`, `get_current_team`, `get_team_limits`, `get_team_services_brief`, `list_projects`, `get_project`, `get_project_resources`, `create_project`, `update_project`, `assign_project_services`
