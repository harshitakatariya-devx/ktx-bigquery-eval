# Build log (silver round, 2026-10-07 .. 08)

The original working notes, kept for history. Paths were updated: the project
was first at `ktx-bq-test/silver/` and the benchmark at `benchmark/`; both now
live in this repo (root and `eval/`). For current instructions see
[SETUP-AND-TEST.md](SETUP-AND-TEST.md). One metric was renamed after these
notes: `sales.net_revenue_inr` is now `sales.net_after_fees_inr`, and the
standard revenue is `sales.revenue_inr` (benchmark rule).

## Warehouse inventory (`sahil-devx`, all datasets in `asia-south1`)

| Dataset | Tables | Notes |
|---|---|---|
| `dev_dna_bronze` | 20 | Raw source tables (orders per channel, returns, shipments, masters) |
| `dev_dna_silver` | 29 | Cleaned layer — **row counts ~500–900× bronze** (see findings) + helper/backup tables |
| `dev_dna_gold` | 17 | Star schema: `fact_sales`, `fact_returns`, `fact_shipments`, `fact_inventory`, `fact_marketing_spend`, `fact_purchase_orders`, `dim_*` |

### Findings to resolve before scoring silver

1. **Silver row inflation.** Example: `d2c_orders` bronze 3,012 → silver
   2,780,076; `returns` 1,242 → 606,960. Gold `fact_sales` (10,262 rows) equals
   the sum of the bronze order tables, so gold matches bronze and silver does
   not. Confirm with Sahil whether silver was scaled up on purpose or has
   duplicate/broken joins — this decides what the "correct answer" is on silver.
2. **Helper/backup tables in silver** that no agent should query:
   `_bak_customers_master`, `_bak_d2c_emails`, `_orig_d2c_orders`,
   `_orig_returns` (0 rows), `_dupe_pairs`, `_demo_calendar`. Exclude them in
   the setup table picker.

## Steps

### ✅ 1. Service account (done)

- GCP project `sahil-devx` → IAM & Admin → Service Accounts → created
  `ktx-reader@sahil-devx.iam.gserviceaccount.com`.
- Roles: **BigQuery Data Viewer** + **BigQuery Job User**.
- JSON key stored at `~/.config/gcloud/ktx-reader.json` (`chmod 600`).
  **Never commit the key or copy it into this folder.** ktx's BigQuery
  connector only supports a service-account JSON key (no `gcloud` login).
- Verified: the key can list all three datasets and their tables.

### ✅ 2. Install ktx (done)

```bash
node --version            # needs 22+ (we have v25)
npm install -g @kaelio/ktx
ktx --version             # 0.16.0
```

### ✅ 3. Create the silver project (done 2026-10-07)

```bash
cd ktx-bigquery-eval
ktx setup
```

| Wizard step | Answer |
|---|---|
| Project | create in this folder |
| LLM | **Claude Code** (local login, no API key) |
| Embeddings | **sentence-transformers** (local, free; first run downloads a Python runtime) |
| Database | **BigQuery** |
| Connection id | `warehouse` |
| Service account JSON | `~/.config/gcloud/ktx-reader.json` |
| Location | `asia-south1` |
| Datasets | **only `dev_dna_silver`** |
| Tables | all except the 6 `_bak_` / `_orig_` / `_dupe_` / `_demo_` tables |
| Context sources | **skip** (warehouse only for round 1) |
| Build context | **yes** |
| Agent integration | **Claude Code** |

If setup exits early, rerun `ktx setup` in the same folder — it resumes.

**What actually happened:** the wizard enabled all 29 tables, so the 6 helper
tables were removed from `enabled_tables` in `ktx.yaml` by hand, then
setup was finished non-interactively:

```bash
ktx setup --no-input --yes --skip-sources --database-connection-id warehouse --target claude-code
ktx mcp start 
```

Build time: **9m31s** (23 tables). Agent config: `.mcp.json` (Claude
Code, MCP at `http://127.0.0.1:7878/mcp`). After a reboot, rerun
`ktx mcp start` before opening Claude Code.

### ✅ 4. Verify and add a cost cap (done)

```bash
ktx status
ktx connection test warehouse
```

Then add a per-query billing cap under the connection in `ktx.yaml`:

```yaml
connections:
  warehouse:
    driver: bigquery
    credentials_json: file:~/.config/gcloud/ktx-reader.json
    location: asia-south1
    dataset_ids: [dev_dna_silver]
    max_bytes_billed: 10000000000   # 10 GB per query
```

### 🔄 5. Review what ktx built

- `semantic-layer/warehouse/*.yaml` — are measures sensible? Are joins
  right? BigQuery has **no foreign keys**, so every join is inferred by ktx;
  check these first.
- `wiki/global/*.md` — are the business descriptions accurate?

**Silver round 1 output** (`semantic-layer/warehouse/_schema/dev_dna_silver.yaml`):

| What | Result |
|---|---|
| Semantic sources | 23 (one per table), listed by `ktx sl` |
| Descriptions | every column has `db` (copied from BigQuery's own column descriptions, which already exist in this warehouse) and `ai` (Claude's rewrite) |
| Joins | 25 accepted, 0 needing review, all `source: inferred` |
| Measures | **0**: no metrics are generated from the warehouse alone |
| Wiki | empty (no context sources connected) |

Joins found: every order table → `dim_date` (via `order_date_key`) and →
`item_master` (via `product_id`); `d2c_orders` → `dim_customer` via
`customer_email` (checked: `email` is unique in `dim_customer`, so this is
safe); `d2c_orders` → `dim_d2c_order` via `order_name`; `customers_master` ↔
`dim_customer`; `purchase_orders` → `suppliers`; `marketing_spend` →
`promotions`; `mrp_master`, `product_codes`, `product_bundle`,
`inventory_snapshot_expanded` → `item_master`.

Gaps to investigate:
- `returns` joins only to `dim_date`, not to orders or products.
- `shipments`, `customer`, `employees`: no joins at all.
- Only `d2c_orders` links to customers; offline/qcomm/platform/international/cafe orders have no customer join.
- No measures means business metrics (revenue, return rate, ...) must come
  from wiki notes, YAML measures, context sources, or query history.

### ✅ 5b. Smoke test: 3 questions in Claude Code (2026-10-07)

From `ktx mcp logs`: Claude called `sql_execution` 20×, `discover_data` 4×,
`connection_list` 2×, and **never** `sl_query` or `entity_details`.

| Question | What happened | Verdict |
|---|---|---|
| List tables | `discover_data("tables")` matched 1 table (it is a search tool, not a lister), so Claude queried `INFORMATION_SCHEMA` with raw SQL and listed **29** tables, including the 6 excluded ones | Raw SQL ignores `enabled_tables` |
| Revenue by channel, Aug 2026 | No revenue measure exists, so Claude picked a different revenue formula per channel from column descriptions, excluded `is_deleted`, and subtracted CANCELLED/REFUNDED/RTO lines | Transparent, but the definitions are Claude's guesses; numbers are unverified |
| Products with most returns | Claude joined `returns.original_order_ref` to each channel's order table (mapping EXPORT→INTERNATIONAL) | Found the join ktx missed. It is polymorphic (one column pointing at 6 tables), which ktx's single-target ≥90% coverage check cannot accept |

Takeaways:
- So far the value came from **column descriptions + Claude's SQL**, not from
  the semantic layer (no measures, so `sl_query` has nothing to compile).
- Each run can define revenue differently → defining measures (task 6) is
  what makes answers repeatable.
- All ~9% return rates across 18 products suggest synthetic data.

### ✅ 5c. Business metrics added (derived from gold)

Gold `fact_sales` was built from bronze (row counts match), so each channel's
revenue rule was reverse-engineered by matching gold totals to bronze formulas.
All six matched exactly:

| Channel | gross_amount_inr | net_amount_inr (= "revenue") |
|---|---|---|
| D2C | qty × line_item_price | gross + shipping_amount |
| PLATFORM | units × unit_price | gross − promo_discount − marketplace_fee |
| QCOMM | qty × mrp | gross − total_discount − delivery_fee |
| OFFLINE | qty × mrp | net_amount |
| INTERNATIONAL | qty × unit_price_usd × 83 | (gross − customs_duty_usd) × 83 (shipping not included) |
| CAFE | amount | amount |

Notes for Sahil:
- Gold's column description says net = "after discount, **including shipping**",
  but for PLATFORM, QCOMM and INTERNATIONAL the data subtracts fees/delivery/customs
  instead. The description and the data disagree.
- Gold revenue keeps CANCELLED / RTO / REFUNDED lines. Confirm that is intended.
- Silver rows are **not duplicates**: `hash_key` is unique and natural keys are
  ~unique. Silver is a larger dataset, so gold totals cannot be used as the
  correct answers for silver; only the formulas carry over.

Files added in `semantic-layer/warehouse/` (all pass `ktx sl validate`):
- Overlays with measures (soft-deleted rows excluded): `d2c_orders.yaml`,
  `platform_orders.yaml`, `qcomm_orders.yaml`, `offline_orders.yaml`,
  `international_orders.yaml`, `cafe_sales.yaml`, `returns.yaml` (rn = 1 only).
- `sales.yaml`: a SQL-defined source that unions all six channels with the gold
  rules (like gold `fact_sales`). Measures: `net_revenue_inr`,
  `gross_revenue_inr`, `discount_inr`, `units_sold`, `sales_lines`.

After editing these files run `ktx admin reindex` so agents' search sees them.

Check: `ktx sl --connection-id warehouse query --measure sales.net_revenue_inr --dimension sales.channel_code --filter "sales.order_date_key >= '2026-08-01'" --filter "sales.order_date_key < '2026-09-01'" --execute`

| Channel (Aug 2026, silver) | ktx `sales.net_revenue_inr` | Claude's earlier guess (no measures) |
|---|---|---|
| PLATFORM | ₹2,90,72,562 | ₹2,82,97,641 (dropped refunds, kept fee) |
| D2C | ₹2,79,26,750 | ₹2,67,95,722 (no shipping) |
| QCOMM | ₹2,19,73,079 | ₹1,33,56,645 (selling_price, dropped cancelled/RTO) |
| OFFLINE | ₹1,39,23,821 | ₹1,39,23,821 ✓ |
| INTERNATIONAL | ₹1,21,79,423 | $160,720 USD (no conversion, no customs) |
| CAFE | ₹79,24,732 | ₹79,24,732 ✓ |

Only 2 of 6 channels matched: without defined metrics the agent's definitions
drift from the official ones.

**Re-test in a fresh Claude session** (same question, after the measures were
added): Claude called `discover_data` → `connection_list` → `sl_read_source(sales)`
→ **`sl_query`**, with no raw SQL. All 6 channel numbers matched the official rules
exactly. It took 25s and 4 tool calls; before the measures it took 66s and many
raw `sql_execution` calls. It also explained the rules (D2C adds shipping,
INTERNATIONAL at 83 INR/USD, all statuses included).

Testing rule learned: ask each test question in a **fresh session** (`/clear`),
otherwise Claude reuses earlier answers from the conversation.

### 🔄 6. Test correctness

Using the team's 15-question benchmark: see [eval/README.md](../eval/README.md)
(ground truth recomputed and SQL saved; all 11 computable answers match the
original doc). The semantic layer's standard **revenue** now follows the
benchmark definition (`revenue_inr`; Aug 2026 = ₹11,89,35,989.67, exact);
gold's rule is kept as `net_after_fees_inr`.

Original plan:

1. Write ~20 test questions with hand-written correct SQL and saved results
   (single-table, multi-join, metric definitions, date grains).
2. Ask each question three ways and score correct / wrong / different
   definition:
   - **A:** Gemini in BigQuery Studio
   - **B:** Claude Code **without** ktx
   - **C:** Claude Code **with** ktx (opened in this repo)
3. Also query the semantic layer directly with `ktx sl query`.
4. Fix wrong measures/joins in the YAML or add wiki notes, then rerun the
   failed questions.

### ⬜ 7. Measure efficiency

| Metric | How |
|---|---|
| Ingest time | time `ktx ingest` / the setup build |
| Accuracy | % correct, A vs B vs C |
| Agent cost | turns + tokens per question, B vs C |
| BigQuery cost | bytes billed per answer from `region-asia-south1.INFORMATION_SCHEMA.JOBS_BY_PROJECT` |
| Latency | seconds per answer |

### ⬜ 8. Repeat for gold

Same steps for gold, choosing only `dev_dna_gold`. Compare accuracy
silver vs gold.

## Results

_Fill in as rounds complete._

| Round | Ingest time | Accuracy A / B / C | Notes |
|---|---|---|---|
| silver | | | |
| gold | | | |
