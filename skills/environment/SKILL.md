---
name: environment
description: Manage Seenode application environment variables and secrets — list (masked), reveal non-secrets when needed, set/update, and delete keys. Prefer link_database_to_application for database credentials instead of pasting passwords. Use when configuring API keys, feature flags, NODE_ENV, or diagnosing missing env configuration.
license: MIT
metadata:
  author: Seenode
  version: "0.3.0"
  category: configuration
---

# Environment variables on Seenode

## Semantics (critical)

- **Set/delete env vars** on container apps applies config to the **running** application and **restarts** instances.
- Env changes do **not** rebuild from git for web/worker/private.
- **Static:** env is **build-time**. `set_environment_variables` does not restart a container — follow with `create_deployment` / `wait_for_deployment`.
- Changing runtime image, build/start command, port, root directory, publish directory, or branch requires **`update_build_settings`** (redeploy), not env vars.
- Secrets marked via `secret_keys` are write-only — they cannot be read back.
- For managed databases, prefer **`link_database_to_application`** over pasting `DATABASE_URL` / `DB_PASSWORD` into `set_environment_variables`.

## List (preferred)

```
list_environment_variables(application_id=...)
```

Returns keys, `isSecret`, masked `valuePreview`, and `unprotectedKeys` (credential-like names that should be marked secret).

## Reveal (cautious)

```
reveal_environment_variables(application_id=..., keys=["KEY"]|null)
```

Only for **non-secret** values, and only when the user explicitly needs plaintext or diagnosis is impossible without it. Treat anything revealed as exposed — recommend rotating and re-storing with `secret_keys`. Secret keys appear in `withheldSecretKeys`.

## Set / update

```
set_environment_variables(
  application_id=...,
  variables={"KEY": "value", "OTHER": "..."},
  secret_keys=["KEY"]
)
```

- Merges by key: omitted keys keep current values.
- Keys in `secret_keys` must also appear in `variables`.
- Once secret, a key stays secret; to make it non-secret, delete and recreate (destructive for the old value).
- Never echo secret values back to the user — confirm that they were set.

## Delete (destructive)

```
delete_environment_variables(application_id=..., keys=["KEY"])
```

Missing keys are reported in `notFound`. Deleting a secret destroys the value permanently. This is the only delete tool on the MCP surface for app config — confirm before removing production keys.

## Common workflows

1. **Wire a managed database** — use `link_database_to_application` (default prefix `DATABASE` → `DATABASE_HOST` / `_PORT` / `_USER` / `_PASSWORD` / `_NAME` / `_URL`). Do not ask the user to paste DB passwords. After `rotate_database_user_password`, link again with `overwrite=true`.
2. **Non-DB secrets** — set API keys and similar via `set_environment_variables` with `secret_keys`.
3. **Missing env after failed boot** — `list_environment_variables` → compare to `.env.example` → set missing keys (or re-link DB) → verify with runtime logs (`get_application_logs`).
4. **Mark unprotected secrets** — if `unprotectedKeys` lists credential-like names, re-set those keys with `secret_keys` populated.

## Safety

- Prefer masked list over reveal.
- Do not paste secrets into chat, commits, or skill logs.
- Suspended applications reject env mutations — report that clearly.
- Prefer `link_database_to_application` over manually setting DB credential keys.

## Relevant tools

`list_environment_variables`, `reveal_environment_variables`, `set_environment_variables`, `delete_environment_variables`, `link_database_to_application`, `get_application_logs`, `update_build_settings`
