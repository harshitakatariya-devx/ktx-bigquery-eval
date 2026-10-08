---
summary: customers_master has ~1,600 distinct people; dim_customer (1,496 rows) is NOT a full mirror — joining facts via dim_customer drops 104 customer_master_ids.
usage_mode: auto
sort_order: 0
tags:
  - customer
  - data-quality
refs:
  - d2c-loyalty-tier
sl_refs:
  - customers_master
  - dim_customer
connections:
  - warehouse
---

## Customer Identity & Deduplication — customers_master vs dim_customer

### Record counts (as of 2026-10-08 analysis)
- `customers_master`: 1,600 rows — all unique on `customer_master_id` and `phone`; 1,496 distinct emails (lower/trim); 1,575 distinct names. None flagged `is_deleted`.
- `dim_customer`: 1,496 rows — **one row per distinct email address**, NOT one row per `customer_master_id`.
  - 104 `customer_master_id` values exist in `customers_master` but are **absent from `dim_customer`**.

### Critical join warning
- **Do NOT join fact tables to `dim_customer` by `customer_master_id` to count or segment all customers.** You will silently drop the 104 records not present in `dim_customer`.
- Use `customers_master` as the base when you need complete customer coverage; join `dim_customer` only when email-level attributes are needed and the 104-record gap is acceptable.

### Email collisions — not true duplicates
- 103 email addresses are shared by 207 `customers_master` records (max 3 records per email).
- None of the sharing groups match on **both** name and phone. Cities, states, channels, and signup dates also differ.
- Treat these as email collisions (synthetic/shared addresses), **not** the same person.

### Name collisions — coincidental
- 26 pairs of records share a name; none share phone or email (1 shares city).
- Treat as coincidental same names, not duplicates.

### Best estimate of distinct people
- **~1,600 distinct people.** No record pair matches on more than one identity key (email + phone + name).
- 1,496 (dim_customer row count) is a **lower bound** only — it treats email as the sole identity key, which is incorrect given the collision pattern above.

### Recommended identity key
- `customer_master_id` (from `customers_master`) is the most reliable unique identifier; it is 1:1 per row and has no collisions.

