# Security Policy

## Reporting a vulnerability

Please report security issues privately to **help@seenode.com**.

Include:

- A description of the issue and its impact
- Steps to reproduce (or a proof of concept)
- Affected component (plugin manifests, skills, docs) and version if known

Do **not** open a public GitHub issue for vulnerabilities, and do not disclose the report until we have confirmed a fix or coordinated disclosure date.

We aim to acknowledge reports within a few business days.

## Scope

This repository is a **client plugin package**: manifests, skills, and documentation that point agents at the hosted Seenode MCP (`https://mcp.seenode.com/mcp`).

Out of scope for this repo (report via the same email if unsure):

- The Seenode platform / MCP server implementation
- Account takeover or billing fraud on seenode.com
- Issues that require production credentials to reproduce

## Secrets

This plugin must never ship API keys, OAuth client secrets, or `Authorization` headers. Authentication is OAuth against Seenode’s production MCP. If you find a secret in this repository, report it immediately to help@seenode.com.
