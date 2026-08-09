---
name: projects
description: Work with Seenode team context and optional project grouping — list teams, get the current team, list/get/create projects, and assign apps or databases to projects. Use when organizing resources, confirming which team the MCP token uses, or creating a project before deploy.
license: MIT
metadata:
  author: Seenode
  version: "0.1.0"
  category: organization
---

# Teams and projects on Seenode

## Team context

The OAuth / API token pins a **single team**. Most tools operate inside that team.

```
get_current_team()   # preferred — team + user for this token
list_teams()         # every team the token can reach (rarely needed)
```

Call `get_current_team` when confirming where new apps, databases, or projects will be created.

## Projects

Projects are optional groupings. Creating a project has **no cost** and does **not** deploy anything.

### List / get

```
list_projects()
get_project(project_id=...)
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

### Assign resources

Pass `project_id` when:

- `create_application(..., project_id=...)`
- `update_application(..., project_id=...)`
- `update_database(..., project_id=...)`
- Filtering: `list_applications(..., project_id=...)`, `list_databases(project_id=...)`

## Typical flow before a deploy

1. `get_current_team()` — confirm team
2. `list_projects()` — reuse or `create_project`
3. Continue with the **deploy** skill, passing `project_id` into `create_application` when desired

## Safety

- Do not invent team or project IDs.
- Project creation is organizational only — still require git + `create_application` to ship code.
- Database **creation** still requires the dashboard; projects only group existing/new resources after the user creates the DB.
