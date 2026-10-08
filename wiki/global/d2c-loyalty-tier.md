---
summary: loyalty_tier on dim_customer reflects the customer's CURRENT tier (not the tier at time of order); tiers are BRONZE, SILVER, GOLD, PLATINUM.
usage_mode: auto
sort_order: 0
tags:
  - d2c
  - customer
  - loyalty
sl_refs:
  - d2c_orders
  - d2c_orders.revenue_inr
  - dim_customer
connections:
  - warehouse
---

## D2C Revenue by Loyalty Tier

### loyalty_tier semantics
- `dim_customer.loyalty_tier` is the customer's **current** tier — it is **not** the tier the customer held when the order was placed.
- When grouping D2C revenue by loyalty tier, results reflect where customers stand today, not historically.
- Known tier values (uppercase): `BRONZE`, `SILVER`, `GOLD`, `PLATINUM`.

### Join path
- Join `d2c_orders` → `dim_customer` on `d2c_orders.customer_email = dim_customer.email` (relationship: many_to_one).
- This join is already registered in the semantic layer.

### Revenue measure
- Use `d2c_orders.revenue_inr` for D2C net revenue grouped by loyalty tier.
- The measure excludes soft-deleted order rows; every active order is expected to match a customer row via the email join (no unmatched orders observed).

### Validation note
- Validated Aug 2026: sum of `d2c_orders.revenue_inr` across all loyalty tiers equals the unsplit D2C total exactly — confirming the join produces no row duplication and no unmatched orders.

