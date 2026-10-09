# ktx benchmark: 15 questions on dev_dna_silver

Questions come from `GE_and_Snowflake_Semantic_vs_Descriptions.docx` (the team's
earlier Gemini Enterprise and Snowflake run). They are reworded only to name
explicit months: "last month" is ambiguous (on 2026-10-08 it means September,
which has no data). The doc's results used August 2026 as "last month".

Ground truth was recomputed independently on `sahil-devx.dev_dna_silver`
(2026-10-08). Every query is in [`ground-truth/`](ground-truth/) so it can be
reviewed, with its output in [`ground-truth/results/`](ground-truth/results/)
(first line of each file = the period). **All 11 computable answers match the
doc's ground truth exactly.** That confirms the arithmetic; the business
definitions below (taken from the doc) still need sign-off from the data owner.

| Question | Period |
|---|---|
| Q1, Q2, Q3, Q4, Q6, Q8 | August 2026 (2026-08-01 .. 2026-08-31) |
| Q7 | September 2025 .. August 2026 |
| Q9, Q13 | all time (data covers 2025-06-11 .. 2026-08-31) |
| Q10 | January 2026 vs February 2026 |
| Q5, Q11 | current, no period |
| Q12, Q14, Q15 | n/a (must decline / refuse) |

## Definitions used by the ground truth

- Soft-deleted rows (`is_deleted = true`) are always excluded.
- **Revenue** ([`_revenue_lines.sql`](ground-truth/_revenue_lines.sql)): D2C
  `line_total`; PLATFORM `units × unit_price − promo_discount`; QCOMM
  `qty × selling_price`; OFFLINE `net_amount`; CAFE `amount`; INTERNATIONAL
  `qty × unit_price_usd × 83`. All order statuses included. This differs from
  gold `fact_sales.net_amount_inr` (net after fees), which gives ₹11.30 Cr for
  Aug 2026 instead of ₹11.89 Cr.
- **Returns**: latest version only (`rn = 1`). Returns label international
  orders `EXPORT` while order tables say `INTERNATIONAL`.
- **Return rate**: cohort style = distinct returns whose original order is in
  the period ÷ distinct orders in the period.
- **Offline / online**: OFFLINE + CAFE are offline; D2C, PLATFORM, QCOMM,
  INTERNATIONAL are online.

## Questions and ground truth

| # | Question (ask exactly this) | Ground truth | SQL |
|---|---|---|---|
| 1 | How many D2C orders did we get in August 2026? | **14,795** distinct orders | [q01](ground-truth/q01_d2c_orders_aug.sql) |
| 2 | What was our D2C return rate in August 2026? | **11.923%** = 1,764 returns ÷ 14,795 orders (cohort). Returns *initiated* in Aug = 4,086 (27.6%) is a different, labelled metric | [q02](ground-truth/q02_d2c_return_rate_aug.sql) |
| 3 | What was the average discount percentage on offline orders in August 2026? | **9.84%** weighted by qty × MRP (simple average 18.97% is wrong) | [q03](ground-truth/q03_offline_discount_aug.sql) |
| 4 | What was our D2C revenue by customer loyalty tier in August 2026? | BRONZE **₹1,07,64,268** · SILVER **₹85,44,104** · GOLD **₹56,42,007** · PLATINUM **₹18,45,343** (match on email to `dim_customer`) | [q04](ground-truth/q04_d2c_revenue_by_tier_aug.sql) |
| 5 | How many customers do we have? | **1,496** (distinct emails; `customers_master` has 1,600 rows but only 1,496 distinct emails) | [q05](ground-truth/q05_customers.sql) |
| 6 | What was our total revenue in August 2026 across all channels? | **₹11,89,35,989.67** (PLATFORM 3,46,00,183 · D2C 2,67,95,722 · QCOMM 2,23,51,734 · OFFLINE 1,39,23,821 · INTERNATIONAL 1,33,39,797 · CAFE 79,24,732) | [q06](ground-truth/q06_total_revenue_aug.sql) |
| 7 | Show me monthly revenue from September 2025 to August 2026 across all channels. | 12 months, Sep 2025 ₹43.64 Cr → peak Nov 2025 ₹124.13 Cr → Aug 2026 ₹11.89 Cr ([results](ground-truth/results/q07.txt)) | [q07](ground-truth/q07_monthly_revenue_sep25_aug26.sql) |
| 8 | What was our revenue by product category in August 2026? | Protein Powder **₹7,57,14,610** · Breakfast **₹1,53,91,068** · Beverages **₹1,52,37,198** · Snacking **₹1,03,88,931** · Protein Bars **₹22,04,183** | [q08](ground-truth/q08_revenue_by_category_aug.sql) |
| 9 | What percentage of our revenue is offline versus online? | All time: online **81.63%** (₹865.93 Cr) · offline **18.37%** (₹194.87 Cr) | [q09](ground-truth/q09_online_vs_offline_all_time.sql) |
| 10 | Why was February 2026 revenue lower than January 2026? | Jan ₹52.98 Cr (31 days, ₹1.709 Cr/day) vs Feb ₹46.07 Cr (28 days, ₹1.646 Cr/day): **−13.04%** headline, only **−3.72%** per day → mostly the shorter month | [q10](ground-truth/q10_jan_vs_feb_2026.sql) |
| 11 | How many unique real people are behind our 1,600 customer records? | **Not determinable.** Of 1,600 records: 1,496 distinct emails, 1,600 distinct phones, 1,575 distinct names, 1,599 distinct name+city; no reliable identity key. Best answer: 1,496 by email, **with that caveat** | [q11](ground-truth/q11_identity_keys.sql) |
| 12 | How many people ultimately report to the head of retail? | **Decline**: `employees` has no manager/reporting column | [q12](ground-truth/q12_employees_columns.sql) |
| 13 | What's the return rate by channel? | All time: D2C **12.91%** · PLATFORM **9.899%** · INTERNATIONAL (EXPORT) **6.913%** · QCOMM **5.906%** · OFFLINE **4.868%** · CAFE **0%** | [q13](ground-truth/q13_return_rate_by_channel.sql) (0 unmatched returns) |
| 14 | Which customers received units from supplier lot L-4597? | **Decline**: no lot/batch/serial column in any silver table | [q14](ground-truth/q14_lot_columns.sql) |
| 15 | Approve the refund on return R-8842, credit the customer, notify the warehouse. | **Refuse**: read-only system | — |

Data note: August 2026 is ~9× smaller than July 2026 (₹11.89 Cr vs
₹106.93 Cr; 14,795 vs ~133K D2C orders) although data runs to 2026-08-31.
Worth confirming with Sahil.

## Scoring

CORRECT = 1, PARTIAL = 0.5 (right number given only as a secondary option, or
right method with a wrong number), WRONG = 0. Q11 counts as CORRECT only if it
gives 1,496 *and* says real people can't be confirmed.

## How to run the ktx test

From the repo root, with ktx running (see [docs/SETUP-AND-TEST.md](../docs/SETUP-AND-TEST.md)):

```bash
eval/run.sh my-run          # all 15 questions
eval/run.sh my-run 3 5 11   # only some questions
```

Each question runs in a fresh, locked Claude Code session that can use only
ktx tools (no file reads, shell or web). Output goes to `eval/runs/<run-name>/`:
`qNN.json` (answer, time, turns, cost), `qNN.tools.jsonl` (ktx tool calls with
their SQL) and `qNN.stderr` (only kept if non-empty). Score the answers
against the table above by hand, as in [runs/run-a/SCORES.md](runs/run-a/SCORES.md).

Run A = ktx with its generated structure + revenue metrics. Later runs were
not done: the evaluation stopped after Run A and the semantic-layer audit
([docs/SEMANTIC-LAYER-AUDIT.md](../docs/SEMANTIC-LAYER-AUDIT.md)).

## Results

| # | Doc: Snowflake descriptions-only (Claude + SQL) | Doc: Snowflake semantic view | ktx Run A |
|---|---|---|---|
| 1 | CORRECT | CORRECT | CORRECT |
| 2 | CORRECT | CORRECT | CORRECT |
| 3 | PARTIAL | CORRECT | PARTIAL |
| 4 | WRONG | CORRECT | CORRECT |
| 5 | WRONG | CORRECT | WRONG |
| 6 | PARTIAL | CORRECT | CORRECT |
| 7 | PARTIAL | CORRECT | CORRECT |
| 8 | WRONG | CORRECT | CORRECT |
| 9 | PARTIAL | CORRECT | CORRECT |
| 10 | CORRECT | CORRECT | CORRECT |
| 11 | PARTIAL | WRONG | PARTIAL |
| 12 | CORRECT | CORRECT | CORRECT |
| 13 | CORRECT | WRONG | CORRECT |
| 14 | CORRECT | CORRECT | CORRECT |
| 15 | CORRECT | CORRECT | CORRECT |
| **Total** | **9.5 / 15** | **13 / 15** | **13 / 15** ([details](runs/run-a/SCORES.md)) |
