# Semantic layer audit

Checks whether the semantic layer in `semantic-layer/warehouse/` is correct,
using full-table SQL on `sahil-devx.dev_dna_silver` (read-only). Evidence SQL
and outputs are in [`eval/audit/`](../eval/audit/).

Verdicts: ✅ PASS · ⚠️ WARN (works, but has a caveat or should be improved) ·
❌ FAIL (gives wrong answers).

## Summary (2026-10-08)

| Area | Result |
|---|---|
| Joins ktx found (25) | ✅ All safe: no duplicated or dropped active rows on full tables |
| Joins ktx rejected (2) | ✅ Both correctly rejected |
| Joins ktx missed | ❌ 3 real links: returns → order, shipments → order (one column pointing at 5 tables), QCOMM orders → customer (by phone) |
| Our metrics (32) | ✅ All compute exactly what they define; `sales` matches per-channel on 18/18 checks |
| Missing metrics | ❌ Order count, return rate, weighted discount %, customer count, AOV, marketing, inventory, purchasing, shipments |
| Descriptions | ❌ All 19 example-value lists are wrong; 8 point to gold-only tables; `dim_customer` mislabelled |
| ktx value dictionary | ❌ Incomplete (looks capped at 5 sampled values); `returns.channel_code` shows only D2C |
| ktx self-written changes | ⚠️ 7 of 10 claims correct; one wrong metric (`active_employee_count` = 1,050, real 641) |

**Bottom line:** the semantic layer ktx built is *structurally* sound (every
join it accepted is correct and it rejected the traps), and every metric we
defined calculates correctly. The weak points are what ktx can't infer on its
own (polymorphic links, business metrics), descriptions inherited from
BigQuery that are wrong, an incomplete value dictionary, and unreviewed
self-learning.

## Step 1: the 25 joins ktx accepted

Each join was tested on the full tables (ktx itself profiled 10k-row samples):
coverage (share of child rows with a matching parent), orphan key values,
null keys, duplicate keys on the parent side, and fan-out (rows added by the
join; must be 0). Query: [`a1_join_tests.sql`](../eval/audit/a1_join_tests.sql),
output: [`results/a1_join_tests.json`](../eval/audit/results/a1_join_tests.json).
359 MB billed.

**Result: 25 / 25 joins are safe. No join duplicates rows or drops active rows.**

| # | Join | Coverage | Verdict |
|---|---|---|---|
| 1, 4, 9, 10, 15, 17, 23 | every order table `.order_date_key` → `dim_date.date_key` | 100% | ✅ |
| 25 | `returns.return_date_key` → `dim_date.date_key` | 100% | ✅ |
| 2, 6, 11, 16, 18, 24 | every order table `.product_id` → `item_master.product_id` | 100% | ✅ |
| 12, 14, 19, 20, 21 | inventory, MRP, bundle, product codes, purchase orders → `item_master` | 100% | ✅ |
| 22 | `purchase_orders.supplier_id` → `suppliers` | 100% | ✅ |
| 13 | `marketing_spend.promo_id` → `promotions` | 100% | ✅ |
| 8 | `dim_d2c_order.customer_email` → `dim_customer.email` | 100% | ✅ |
| 5 | `d2c_orders.order_name` → `dim_d2c_order.order_name` | 99.38% | ✅ the 16,720 unmatched orders are **all soft-deleted**; active orders match 100% |
| 7 | `dim_customer.customer_master_id` → `customers_master` | 100% | ⚠️ labelled `many_to_one`, but both sides are unique, so it is really `one_to_one` (harmless) |
| 3 | `d2c_orders.customer_email` → `dim_customer.email` | 100% | ⚠️ mechanically safe, but see the tier-attribution caveat below |

Follow-up query: [`a2_join_followups.sql`](../eval/audit/a2_join_followups.sql).

### Caveat on join 3: loyalty tier for shared emails is arbitrary

- 103 emails are used by more than one `customers_master` record, and in all
  103 cases those records have **different loyalty tiers**.
- `dim_customer` keeps one row per email. For the 100 pairs listed in
  `_dupe_pairs`, it kept the original owner's record 48 times and the record
  whose email was overwritten 52 times: no consistent rule.
- So "D2C revenue by loyalty tier" assigns those customers' orders to an
  arbitrary tier. The join is correct; the data model behind `dim_customer`
  is the issue. This also affects the Q4 ground truth. Data-owner question.

### ktx's join direction assumption

ktx writes every inferred join as `many_to_one` without measuring it. Here
that was right for 24 of 25; join 7 is actually one-to-one, which does not
change any result.

## Step 2: joins ktx did not create, and the 2 it rejected

Query: [`b1_missing_joins.sql`](../eval/audit/b1_missing_joins.sql), output:
[`results/b1_missing_joins.json`](../eval/audit/results/b1_missing_joins.json). 276 MB billed.

| Link | Evidence | Verdict |
|---|---|---|
| `returns.original_order_ref` → the originating order | 100% of returns match an order **in their own channel** (D2C 179,146 · PLATFORM 211,804 · QCOMM 117,929 · OFFLINE 64,660 · EXPORT 33,421). One column points at 5 different tables, keyed by `channel_code` (`EXPORT` = INTERNATIONAL) | ❌ **Missing.** Return-rate questions must hand-write this join every time |
| `shipments.order_ref` → the originating order | 100% match in their own channel (D2C 504 · PLATFORM 577 · QCOMM 569 · OFFLINE 350 · INTERNATIONAL 320). Note shipments says `INTERNATIONAL` where returns says `EXPORT` | ❌ **Missing**, same pattern |
| `qcomm_orders.cust_mobile` → `customers_master.phone` | All 1,600 distinct mobiles match a customer phone (last 10 digits); `phone` is unique | ❌ **Missing.** QCOMM orders can be linked to customers, but nothing tells the agent |
| `returns.exchange_order_ref` → any order | 182,127 non-null values, **0** match any order table | ⚠️ Dangling reference: the exchange orders are not in this dataset |
| `purchase_orders.po_date`, `marketing_spend.spend_date`, `inventory_snapshot_expanded.snapshot_date`, `shipments.dispatch_date` → `dim_date` | 100% inside `dim_date` (2025-06-01 .. 2026-10-13) | ⚠️ Optional: not linked because the names don't end in `_key`; the dates can still be filtered directly |
| `employees.store_id` → stores | Every employee `store_id` (OFFLINE 72, CAFE 69, QCOMM 79) matches an `offline_orders.store_code` value; none match cafe `store_location` or QCOMM `dark_store` | ⚠️ No store dimension exists; the match for CAFE/QCOMM staff looks like a shared synthetic code range, not a real link |
| `customer` (legacy table) | 531,225 rows from 2010-12-01 .. 2011-12-09, channel `ONLINE_RETAIL`, no link to anything | ⚠️ Unrelated legacy data inside the enabled scope; an agent could mix it into "customer" questions |
| Rejected: `qcomm_orders.platform_order_id` → `platform_orders.order_id` | 1,938,203 distinct QCOMM ids, **0** found in `platform_orders` | ✅ Correctly rejected: the names match, the data doesn't |
| Rejected: `shipments.order_ref` → `d2c_orders.order_name` | Only the D2C rows match (21.7% coverage in ktx's check) | ✅ Correctly rejected as a single-table join; the real link is the polymorphic one above |

### Why ktx missed these

- **Polymorphic references** (`returns`, `shipments`): ktx's join model needs
  one column → one table with ≥ 90% coverage. A column whose target depends on
  `channel_code` can never pass that test. ktx also only considers columns
  named like keys (`_id`, `_key`, `_code`, ...); `original_order_ref` and
  `order_ref` don't qualify.
- **Different names for the same thing** (`cust_mobile` vs `phone`): no key-like
  suffix, so no candidate was generated.

### Proposed fix (for review)

Add one SQL-defined `orders` source: one row per order across the five order
channels, with `channel_code` and the order reference. Then join `returns` and
`shipments` to it on channel + reference (mapping `EXPORT` → `INTERNATIONAL`),
and add an order-count measure. Add `qcomm_orders.cust_mobile` →
`customers_master.phone` as a declared join. Exclude or clearly mark the legacy
`customer` table.

## Step 3: metrics (measures)

Every measure was executed through ktx (`ktx sl query --execute`, all time) and
compared with independent SQL written without the semantic layer. Queries:
[`c2_measures_independent.sql`](../eval/audit/c2_measures_independent.sql),
[`c3_returns_duplicates.sql`](../eval/audit/c3_returns_duplicates.sql); ktx output:
[`results/c1_ktx_measures.json`](../eval/audit/results/c1_ktx_measures.json)
(includes the SQL ktx generated). 595 MB billed.

**Result: 32 / 32 measures return exactly what their definition says, and the
combined `sales` source matches the per-channel measures on all 18 checks
(revenue, net-after-fees and units for 6 channels).** Run A already showed
`sales.revenue_inr` reproduces the Q6, Q7, Q8 and Q9 ground truth exactly.

### Findings

| Finding | Evidence | Verdict |
|---|---|---|
| `returns.return_count` counts distinct `return_id`, but 94 ids are shared by two *different* current returns (different orders and refund amounts; 47 span two channels) | 577,810 current return rows vs 577,716 distinct ids | ⚠️ Undercounts by 94 (0.016%). Count rows (`rn = 1`) instead; `refund_amount_inr` is already correct |
| D2C `line_total` is not consistently defined | Of 2,675,606 active lines, 638,485 have `line_total` ≠ qty × price; 1,023,042 have `line_total` = qty × price + shipping (this count includes lines with zero shipping). Across all lines the total equals qty × price within ₹131 | ⚠️ D2C `revenue_inr` (= `line_total`, the benchmark rule) adds up correctly overall, but individual lines mix different meanings. Data-owner question |
| QCOMM `selling_price` vs `mrp − total_discount` disagree | 189,412 lines where qty × MRP − discount ≠ qty × selling_price | ⚠️ The two QCOMM revenue views (`revenue_inr` vs gross − discount) will never reconcile. Data-owner question |
| CAFE `amount` vs `qty × rate` | 0 of 923,000 lines differ | ✅ Consistent. (A Claude answer during the smoke test claimed 23% differ; that was wrong) |
| INTERNATIONAL converted at a fixed 83 INR/USD | hard-coded in 3 measures and in `sales.yaml` | ⚠️ Matches gold and the benchmark, but the rate lives in several places; a change must update all of them |

### Metrics that don't exist yet

These are the questions the agent currently answers with hand-written SQL
(which is where both Run A misses came from):

| Missing metric | Needed for | Note |
|---|---|---|
| Order count per channel | Q1, AOV, return rate | count distinct order key, excluding deleted |
| Return rate | Q2, Q13 | needs the `orders` source from Step 2 |
| Average discount % (weighted) | Q3 | `discount_inr / gross_revenue_inr` per channel |
| Customer count | Q5 | blocked on the 1,496 vs 1,600 definition |
| Average order value | common question | revenue ÷ order count |
| Marketing spend, impressions, clicks, CTR | marketing questions | `marketing_spend` has no measures |
| Units on hand | inventory questions | **semi-additive**: must take the latest snapshot, never sum across dates |
| PO units and value | purchasing questions | `qty × unit_cost` |
| Shipments delivered, delivery days, RTO rate | logistics questions | needs `orders` link for channel/customer |

## Step 4: columns and descriptions

Scripts: [`d1_descriptions_scan.py`](../eval/audit/d1_descriptions_scan.py)
(reads the `_schema` YAML), [`d2_description_claims.py`](../eval/audit/d2_description_claims.py)
→ [`d2_description_claims.sql`](../eval/audit/d2_description_claims.sql),
[`d3_dictionary_completeness.sql`](../eval/audit/d3_dictionary_completeness.sql).
252 MB billed. Scope: 23 tables, 317 columns.

| Finding | Evidence | Verdict |
|---|---|---|
| **Example values in descriptions are wrong** | All 19 descriptions that list example values (`(e.g. ...)`) disagree with the data: wrong case (`Cancelled` vs `CANCELLED`, `Bronze` vs `BRONZE`) or values that don't exist (`Placed`, `Refund`, `Store Credit`, `Apparel`, `Electronics`, `Amazon` vs `AMAZON_IN`). See [`results/d2_description_claims.json`](../eval/audit/results/d2_description_claims.json) | ❌ An agent copying an example into a filter (`order_status = 'Cancelled'`) silently gets 0 rows. These come from the BigQuery column descriptions (`db`) |
| **ktx's value dictionary is incomplete** | It looks capped at 5 values per column and is built from sampled rows. Missing: `returns.channel_code` lists only `D2C` (real: D2C, EXPORT, OFFLINE, PLATFORM, QCOMM); `employees` misses OFFLINE; `marketing_spend` misses D2C; `promotions` misses INTERNATIONAL; `product_codes` misses QCOMM; `suppliers.category` misses Co-Packing | ❌ The dictionary is the agent's safeguard against wrong examples. For `returns.channel_code` it reinforces the "returns are D2C-only" mistake that cost both Gemini agents Q13 |
| Descriptions point to tables not in scope | `channel_code` on 7 tables says "joins to `dim_channels`"; `customers_master.customer_master_id` says "joins to `dim_customers_master`". Both exist only in **gold** | ⚠️ The agent may look for a table that isn't there (seen in Run A Q9) |
| `dim_customer` described as a "mirror of `customers_master`" | 1,496 rows vs 1,600 (one row per email; 104 customers missing) | ⚠️ Misleading; Run A Q5 trusted `customers_master` instead |
| Columns described as unique | 10 of 13 are unique. `returns.return_id` is not (history rows plus 94 collisions); `product_bundle.bundle_id` has 4 values on 9 rows (one row per component); `international_orders.order_ref` repeats on 499 multi-line orders | ⚠️ Descriptions should say what the row grain is |
| Pipeline columns visible to the agent | 115 columns (`hash_key`, `insert_timestamp`, `modified_timestamp`, `source_name`, `rn`, `is_deleted`) have no `visibility` setting | ⚠️ `hash_key` etc. add noise; `rn` and `is_deleted` must stay visible because correct filters need them |
| No table declares a primary key | BigQuery has no declared PKs here, so ktx falls back to using every column as the grain (e.g. `d2c_orders` grain = `hash_key`, `order_name`, `created_at`, ...) | ⚠️ Declaring the real grain for the main tables (`hash_key` or the business key) would make the row meaning explicit |
| Column types | dates typed `time`, amounts `number`, flags `boolean` | ✅ |

## Step 5: files ktx wrote by itself during Run A

Query: [`e1_ktx_written_claims.sql`](../eval/audit/e1_ktx_written_claims.sql),
output: [`results/e1_ktx_written_claims.json`](../eval/audit/results/e1_ktx_written_claims.json). 306 MB billed.

| File (written by ktx) | Claim | Evidence | Verdict |
|---|---|---|---|
| `semantic-layer/.../employees.yaml` | measure `active_employee_count` = distinct `employee_id` where `rn = 1 and not is_deleted` | ktx returns **1,050**; only **641** employees have `employment_status = ACTIVE` (211 ON LEAVE, 198 RESIGNED) | ❌ **Wrong**: the "active" filter never looks at `employment_status`, so "how many active employees?" would answer 1,050 |
| same file | "SCD-style; multiple rows per employee" | 1,050 rows, 1,050 distinct ids, `rn` is always 1, 0 deleted | ⚠️ False claim (the filter is harmless, but the description is invented) |
| `semantic-layer/.../dim_customer.yaml` | tier values BRONZE/SILVER/GOLD/PLATINUM; join on email | matches the data | ✅ |
| same file | `loyalty_tier` is the *current* tier, not the tier at order time | no tier history exists to check this | ⚠️ Plausible (BigQuery's description says "current"), but stated as fact |
| `wiki/.../revenue-calendar-normalization.md` | weekend and month-end days run at ~2× a normal day | Jan–Jun 2026: weekend ₹3.08 Cr/day = **1.58×** a normal weekday (₹1.94 Cr); last-7-day weekdays ₹2.26 Cr = **1.17×** | ⚠️ Overstated: generalised from Jan–Feb only |
| `wiki/.../customer-identity-dedup-warehouse.md` | 1,600 records, 1,496 emails, 103 emails shared by 207 records, 26 same-name pairs | 103 / 207 ✓; 24 shared names over 49 records (= 26 pairs) ✓ | ✅ facts · ⚠️ its conclusion "~1,600 distinct people" takes a side on the open customer definition |
| `wiki/.../d2c-loyalty-tier.md` | tiers sum exactly to the D2C total | matches ground truth Q4 | ✅ |
| `wiki/.../employees-no-org-chart.md` | no manager column; list of 10 roles | matches the data | ✅ |
| `wiki/.../no-lot-batch-traceability-warehouse.md` | no lot/batch column anywhere | matches ground truth Q14 | ✅ |
| unmerged branch: `returns` notes + return-rate page | `EXPORT` = INTERNATIONAL; order key per channel | matches Step 2 and ground truth Q13 | ✅ worth merging |

**Takeaway:** ktx's self-learning is mostly accurate (7 of 10 claims fully
correct), but it also wrote one wrong metric and two overstated claims, and
committed them without review. Self-written changes need human review like
any other code change.

## Proposed fixes

Only the `employees.yaml` part of A8 has been applied (2026-10-09). The rest are proposals; the evaluation was closed without applying them.

### A. Fix in this repo's semantic layer (overlay files, so a re-scan can't overwrite them)

| # | Fix | Addresses |
|---|---|---|
| A1 | New `orders` source (one row per order across channels) with `order_count`; join `returns` and `shipments` to it on channel + order reference (`EXPORT` → INTERNATIONAL); add `return_rate` | Step 2 missing joins; Q1, Q2, Q13 |
| A2 | Declare `qcomm_orders.cust_mobile` → `customers_master.phone` | Step 2 |
| A3 | `returns.return_count` counts current rows instead of distinct `return_id` | Step 3 (94 undercount) |
| A4 | Weighted discount % per channel (discount ÷ gross) and average order value | Step 3; Q3 |
| A5 | Correct the 19 wrong example lists and 8 `dim_channels`/`dim_customers_master` references via `column_overrides`; add full `enum_values` for the 6 incomplete dictionary columns; describe `dim_customer` accurately | Step 4 |
| A6 | Hide `hash_key`, `insert_timestamp`, `modified_timestamp`, `source_name` from the agent (`visibility: internal`) | Step 4 |
| A7 | Remove the 2010–2011 legacy `customer` table from `enabled_tables` in `ktx.yaml` | Step 2 |
| A8 | Review ktx's own changes: fix `active_employee_count` (filter `employment_status = 'ACTIVE'`), drop the false SCD claim, soften the calendar wiki page, make the identity wiki page neutral until the customer definition is decided, merge the unmerged `returns` branch | Step 5. **Applied 2026-10-09:** `employees.yaml` fixed (active_employee_count = 641, new employee_count = 1,050, SCD claim removed), verified with `ktx sl query --execute`. Rest not applied. |
| A9 | Marketing, inventory (latest snapshot only), purchasing and shipment metrics | Step 3 (optional, beyond the benchmark) |

### B. Data-owner decisions (Sahil)

1. Customer count: distinct emails (1,496) or customer records (1,600)?
2. Revenue: benchmark rule (₹11.89 Cr for Aug 2026) or gold's net-after-fees (₹11.30 Cr)?
3. D2C `line_total`: should it include shipping? It currently does on some lines only.
4. QCOMM: `selling_price` disagrees with MRP − discount on 189,412 lines. Which is right?
5. `dim_customer` keeps an arbitrary record for the 103 shared emails, so tier attribution is arbitrary.
6. 94 `return_id`s are reused by different returns; `exchange_order_ref` points to orders not in the data.
7. Fix the example values in the BigQuery column descriptions at the source.
8. August 2026 volume is ~9× below July; silver rows are 500–900× bronze.
9. Should the legacy `customer` table stay in silver at all?

### C. ktx limitations to report upstream

1. Polymorphic references (one column → several tables by a type column) are never detected.
2. Join candidates require key-like names (`_id`, `_key`, `_code`); `_ref` and differently named columns (`cust_mobile` ↔ `phone`) are missed.
3. Join cardinality is assumed (`many_to_one`), not measured.
4. The value dictionary keeps a few sampled values per column, so rare or late-sorted values are missing.
5. Saving self-learned notes can reset uncommitted edits to tracked files (our `ktx.yaml` cost cap was lost this way).
6. Self-learning commits new metrics and wiki claims without review; one was wrong here.
