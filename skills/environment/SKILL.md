---
name: environment
description: Manage Seenode application environment variables and secrets — list (masked), reveal non-secrets when needed, set/update, and delete keys. Use when configuring DATABASE_URL, API keys, feature flags, NODE_ENV, or diagnosing missing env configuration.
license: MIT
metadata:
  author: Seenode
  version: "0.1.0"
  category: configuration
---

# Environment variables on Seenode

## Semantics (critical)

- **Set/delete env vars** applies config to the **running** application and **restarts** instances.
- Env changes do **not** rebuild from git.
- Changing runtime image, build/start command, port, root directory, or branch requires **`update_build_settings`** (redeploy), not env vars.
- Secrets marked via `secret_keys` are write-only — they cannot be read back.

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

## Delete

```
delete_environment_variables(application_id=..., keys=["KEY"])
```

Missing keys are reported in `notFound`. Deleting a secret destroys the value permanently.

## Common workflows

1. **Wire a database** — set `DATABASE_URL` (or split `DB_*` keys) with password/URL in `secret_keys`, using values the user or dashboard provides. MCP cannot create databases.
2. **Missing env after failed boot** — `list_environment_variables` → compare to `.env.example` → set missing keys → verify with runtime logs (`get_application_logs`).
3. **Mark unprotected secrets** — if `unprotectedKeys` lists credential-like names, re-set those keys with `secret_keys` populated.

## Safety

- Prefer masked list over reveal.
- Do not paste secrets into chat, commits, or skill logs.
- Suspended applications reject env mutations — report that clearly.
