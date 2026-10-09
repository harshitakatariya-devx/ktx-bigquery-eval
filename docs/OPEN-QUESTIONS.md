# Open questions for the data owner

Decisions only the data owner can make. Some change the benchmark's "correct"
answers; others are data issues found by the
[semantic-layer audit](SEMANTIC-LAYER-AUDIT.md). All numbers are from
`sahil-devx.dev_dna_silver`, October 2026.

## Change the benchmark's correct answers

| # | Question | Evidence | Affects |
|---|---|---|---|
| 1 | **What is a customer?** Distinct emails (**1,496**) or customer records (**1,600**)? | `_dupe_pairs` shows 100 customers' emails were overwritten with another customer's email; their names, phones and cities still differ | Q5, Q11 (Run A's only WRONG answer) |
| 2 | **What is revenue?** Benchmark rule (Aug 2026 **₹11.89 Cr**) or gold's net after fees (**₹11.30 Cr**)? | Both are defined in `sales.yaml`: `revenue_inr` and `net_after_fees_inr` | Q6–Q10 |
| 3 | Should revenue include CANCELLED / RTO / REFUNDED lines? | Gold keeps them; the benchmark keeps them | All revenue questions |

## Data issues

| # | Question | Evidence |
|---|---|---|
| 4 | D2C `line_total`: should it include shipping? | It does on some lines only |
| 5 | QCOMM: which price is right? | `selling_price` ≠ `mrp − discount` on 189,412 lines |
| 6 | `dim_customer` deduplication | For the 103 shared emails it keeps an arbitrary record (48 keep the original id, 52 the changed one), so loyalty-tier attribution is arbitrary |
| 7 | Reused return ids | 94 `return_id`s are used by different returns; `exchange_order_ref` matches 0 of 182,127 orders |
| 8 | BigQuery column descriptions | All 19 example-value lists in the descriptions are wrong, and 8 descriptions point to tables that only exist in gold. Fix at the source? |
| 9 | Data volume | August 2026 is ~9× smaller than July (₹11.89 Cr vs ₹106.93 Cr) although data runs to 2026-08-31; silver rows are 500–900× bronze. Intended? |
| 10 | Legacy `customer` table (2010–2011 data) | Should it stay in silver? |
| 11 | Gold's `net_amount_inr` description says "including shipping" | For PLATFORM, QCOMM and INTERNATIONAL the data subtracts fees / delivery / customs instead |

## Access

| # | Request |
|---|---|
| 12 | Run the billing query in [COSTS.md](COSTS.md#exact-billing-check-needs-the-project-owner) to confirm what the PoC billed |
