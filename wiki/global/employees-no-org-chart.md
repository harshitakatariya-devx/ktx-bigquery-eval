---
summary: employees table has no manager_id / reporting hierarchy — org-chart questions cannot be answered from this warehouse.
usage_mode: auto
sort_order: 0
tags:
  - data-quality
  - hr
sl_refs:
  - employees
  - employees.active_employee_count
connections:
  - warehouse
---

## Employees — No Reporting Hierarchy

### Key limitation
- `employees` has **no `manager_id`, `reports_to`, or supervisor column**.
- Org-chart questions ("how many people report to X", "who is the head of retail?") **cannot be answered** from this warehouse.

### Active-record filter
- The table is SCD-style; multiple rows may exist per employee.
- Filter `rn = 1 AND is_deleted = false` to get the current active snapshot.
- `employment_status` column tracks individual status within active rows.

### Known roles (as of 2026-10-08)
Barista, Cafe Manager, Cashier, Customer Success Rep, Dark Store Ops Lead, Export Ops Coordinator, Marketplace Account Manager, Picker, Sales Associate, Store Manager.

- **No "Head of Retail" or executive role** exists in the data.

### Source table
`sahil-devx.dev_dna_silver.employees` — surfaced in the semantic layer as the `employees` source.

