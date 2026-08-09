---
name: billing
description: Inspect Seenode team credits, usage, spending, orders, and ledger; open billing portal or checkout; settle unbilled usage. Use when the user asks about balance, spend, top-ups, LIMITS, invoices, or payment methods. Confirm before any money mutation; prefer portal/checkout URLs over handling Stripe client secrets in chat.
license: MIT
metadata:
  author: Seenode
  version: "0.2.0"
  category: billing
---

# Billing and credits on Seenode

All amounts should be presented to users in **USD**. API fields often use cents — prefer `creditBalanceUsd` (and convert other cent fields) when summarizing.

## Read-only overview (start here)

```
get_credit_balance()        # prepaid balance (not MTD spend)
get_team_usage()            # unbilled usage + month-end projection
get_spending(range="this_month")   # this_month | last_month | last_7_days | custom
list_billing_orders(page=1)
list_credit_ledger(page=1, kind=null, period_from=null, period_to=null)
get_billing_information()
get_bonus_credit_rate()
```

For `get_spending` with `range="custom"`, pass `period_start` and `period_end` (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SS`).

Use this skill before paid creates (`create_database`, paid packages, storage) when balance may be insufficient. Deployment `LIMITS` often pairs with `get_team_limits` (see **projects**) plus credit checks here.

## Browser flows (preferred mutations)

Prefer sending the user a URL over handling Stripe secrets in chat:

```
get_billing_portal_url()                 # manage payment methods / address / tax
create_checkout_session(price=null)      # top up prepaid credits; price in dollars, min 10 when set
```

Show `checkoutSessionUrl` / portal URL as a markdown link. Links may be short-lived.

## Money mutations (confirm first)

Always summarize what will happen and get explicit approval:

```
pay_now()                 # settle current unbilled usage against prepaid credits
create_setup_intent()     # returns clientSecret for Stripe.js — avoid unless portal/checkout cannot work
```

Before `pay_now`, show `get_credit_balance` + `get_team_usage` so the user knows the charge. Prefer `get_billing_portal_url` / `create_checkout_session` over `create_setup_intent` — do not paste or linger on `clientSecret` in chat; if returned, tell the user to complete setup in a proper Stripe UI rather than treating chat as a card form.

## Safety

- Confirm before `pay_now`, `create_checkout_session`, and `create_setup_intent`.
- Never invent balances or claim deletes/refunds the MCP cannot perform.
- Do not document operator Stripe keys, webhook secrets, or platform billing internals.
- Speak credits and spend in USD.

## Relevant tools

`get_credit_balance`, `get_team_usage`, `get_spending`, `list_billing_orders`, `list_credit_ledger`, `get_billing_information`, `get_billing_portal_url`, `create_checkout_session`, `create_setup_intent`, `pay_now`, `get_bonus_credit_rate`

## Related skills

- **deploy** / **databases** / **storage** — check balance before paid creates
- **troubleshoot** — `LIMITS` deployment state
- **projects** — `get_team_limits`
