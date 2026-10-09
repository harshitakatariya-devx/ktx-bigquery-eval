# Run A scores (2026-10-08)

Setup: Claude Code (Opus 5.5) headless, one fresh session per question, only
`mcp__ktx__*` tools allowed (no file reads, shell or web; 0 blocked-tool
attempts). ktx state: generated structure + descriptions + joins, plus the
revenue measures (`sales.revenue_inr`, per-channel overlays, `returns`).
Raw answers: `qNN.json`; ktx tool calls with SQL: `qNN.tools.jsonl`.

| # | Verdict | ktx answer | Tools (key) |
|---|---|---|---|
| 1 | CORRECT | 14,795 | sl_query |
| 2 | CORRECT | 11.9% (cohort), 27.6% shown as labelled alternative | sl_query + SQL |
| 3 | PARTIAL | Led with 18.97% simple average; 9.84% weighted given second | SQL (no discount-% measure) |
| 4 | CORRECT | Exact on all 4 tiers; noted tier is current, not historical | sl_query |
| 5 | WRONG | 1,600 (customers_master); ground truth 1,496 | SQL (no customer-count measure) |
| 6 | CORRECT | ₹11,89,35,989.67 exact | sl_query |
| 7 | CORRECT | All 12 months exact; flagged Aug 2026 as likely incomplete | sl_query |
| 8 | CORRECT | Exact on all 5 categories; verified no fan-out | sl_query |
| 9 | CORRECT | 81.6% / 18.4% exact; stated CAFE-as-offline assumption | sl_query |
| 10 | CORRECT | −13.0%; explained fewer high-sales days (₹17.1M→₹16.5M/day) | sl_query |
| 11 | PARTIAL | "About 1,600; 1,496 is the floor by email" with evidence | SQL |
| 12 | CORRECT | Declined (no manager column); offered labelled proxy | SQL |
| 13 | CORRECT | All 6 channels exact incl. EXPORT→INTERNATIONAL | sl_query + SQL |
| 14 | CORRECT | Declined (no lot data, searched all columns and values) | SQL |
| 15 | CORRECT | Refused (read-only); R-8842 does not exist as an id | SQL |

**Total 13 / 15** (Q1–10: 8.5 / 10; Q11–15: 4.5 / 5).

Efficiency: 8.5 min total, 34 s and 10.7 turns per question on average,
$5.16 total ($0.34 per question). `sl_query` used in 9 questions, raw SQL in 12.

Both misses are questions with no defined metric (weighted discount %,
customer count). Every question answered via an `sl_query` measure was exact.

## Ground-truth notes raised by this run

- **Q5 / Q11 are debatable.** `_dupe_pairs` shows the dataset author overwrote
  100 customers' emails with another customer's email (and changed their tier);
  names, phones and cities still differ. "Customers = distinct emails = 1,496"
  follows the author's intent; "1,600" is what the data supports on its own.
  ktx also found `dim_customer` drops 104 customer ids vs `customers_master`.
  Scored against the doc's ground truth here; the definition needs an owner.

## ktx self-learning during the run

`memory_ingest` ran after Q4, Q10, Q11, Q12, Q13, Q14: 6 wiki pages +
2 semantic-layer overlays (`dim_customer.yaml`, `employees.yaml`), committed to
this repo's git by ktx. Each was written after its own answer and none relates to the
next question, so it did not affect Run A. One wiki page (return rate by channel)
stayed on an unmerged ktx branch after a merge conflict. The audit later found
ktx's `active_employee_count` wrong (1,050 vs 641 active); `employees.yaml` was
fixed on 2026-10-09 ([audit](../../../docs/SEMANTIC-LAYER-AUDIT.md), Step 5).
