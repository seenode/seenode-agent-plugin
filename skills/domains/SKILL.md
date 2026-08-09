---
name: domains
description: Attach custom domains to Seenode web applications, show DNS records, and poll verification until DNS/TLS/routing are ready. Use when the user wants a custom domain, DNS setup, SSL status, or to check if a domain is live on Seenode.
license: MIT
metadata:
  author: Seenode
  version: "0.1.0"
  category: networking
---

# Custom domains on Seenode

Only **`web`** applications support custom domains. Workers and private apps do not.

Web apps already receive a default `*.seenode.app` domain on creation — use this skill for **custom** domains.

## List current domains

```
list_domains(application_id=...)
```

Unverified domains include `dnsSetup` with the exact CNAME/A records to create. Never describe an unverified domain as working.

## Add a domain

```
add_domain(
  application_id=...,
  domain_name="example.com",
  default=false
)
```

Notes:

- For an apex like `example.com`, Seenode also attaches `www.example.com` (and vice versa). Expect **multiple** records — each needs DNS.
- `default=true` makes this the application’s primary domain.
- Side effects: creates domain records and queues background DNS verification. The domain is **not** live until DNS + TLS + routing succeed.

Report every returned DNS record to the user clearly (type, name, value).

## Verify / poll status

After the user creates DNS records:

```
check_domain_status(
  application_id=...,
  domain_name="example.com"|null,
  domain_id=null
)
```

Per domain flags:

| Field | Meaning |
|-------|---------|
| `dnsReady` | DNS verified by Seenode |
| `sslReady` | Certificate READY |
| `routeReady` | Attached to the running app |
| `ready` | All three true |

When not ready, use `pending` and `dnsSetup`. There is **no** force re-check — wait between polls. Only claim success when `ready` is true.

## Safety

- Do not claim the domain works until `ready`.
- No delete-domain tool via MCP — remove domains in the dashboard.
- Confirm the target app is `web` via `get_application` before adding.
