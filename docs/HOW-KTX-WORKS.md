# How ktx builds and serves the semantic layer (under the hood)

Traced from the ktx 0.16.0 source (`github.com/Kaelio/ktx`). Paths are relative
to `packages/cli/src/` unless they start with `python/`. Numbers match what our
silver run printed.

## Components

| Part | Language | Role |
|---|---|---|
| `ktx` CLI (`packages/cli`) | TypeScript / Node | Orchestrates everything: scan, LLM calls, relationship detection, file writes, MCP server |
| `ktx-daemon` (`python/ktx-daemon`) | Python | Local helper process: embeddings (sentence-transformers), SQL parsing/validation, runs the semantic engine |
| `ktx-sl` (`python/ktx-sl`) | Python | Semantic-layer engine: join graph, query planner, SQL generator (sqlglot) |
| `.ktx/db.sqlite` | SQLite | Run history, enrichment state, full-text + vector search indexes |
| Project folder | git repo | Plain files (`semantic-layer/`, `wiki/`); ktx commits each file it writes |

## Build pipeline (`ktx ingest` / setup build)

Entry: `executePublicIngestTarget` (`public-ingest.ts:924`) → `runKtxScan`
(`scan.ts:338`) → `runLocalScan` (`context/scan/local-scan.ts:401`).

### 1. Read schema — "Reading database schema"
- BigQuery Node API: `dataset.getTables()` + `table.get()` per table
  (`connectors/bigquery/connector.ts:612-643`). Captures table type, row
  count, description; per column: name, type, nullability, **description**.
- Primary keys from `INFORMATION_SCHEMA.TABLE_CONSTRAINTS` + `KEY_COLUMN_USAGE`.
- BigQuery has **no foreign keys** (`foreignKeys: []`), so all joins must be inferred.
- Schema is hashed and diffed against the last run ("found 0 changes across 23
  tables"), then a structure-only `_schema` file is written.

### 2. Descriptions — "Generating descriptions N/23"
- Samples 20 rows per table, sends **5 sample rows** + table name + each
  column's name/type/existing BigQuery description to the LLM
  (`context/scan/description-generation.ts:319-357, 715-737`).
- Model role: `llm.models.candidateExtraction` (sonnet in our `ktx.yaml`).
- Output stored as `descriptions.db` (the warehouse's own text) and
  `descriptions.ai` (LLM text).
- In our silver run most meaning came from `db`: Sahil had already documented
  columns in BigQuery.

### 3. Relationship (join) detection
`discoverKtxRelationships` (`context/scan/relationship-discovery.ts:232`).

**a. Profiling ("Profiling table N/23").** One query per table over a 10k-row
sample: row count, nulls, `COUNT(DISTINCT)`, top 5 values per column
→ uniqueness = distinct/rows, null rate = nulls/rows.

**b. Candidates.** A source column must look like a key (`_id`, `_key`,
`_code`, `_uuid`, ...). A target must look like a key: a declared PK, `id`,
`<table>_id`, or profiled as ≥98% unique with ≤5% nulls. Types must be
compatible. Names are matched with singular/plural and alias rules; embedding
similarity ≥0.92 can add candidates.
Score = `0.56 + 0.65 × (0.24·name + 0.22·value-overlap + 0.22·uniqueness +
0.10·type + 0.10·embedding + 0.08·non-null + 0.04·structural)`, kept if ≥0.72.

**c. LLM proposal.** One LLM call with all tables, columns, descriptions and
profile stats. It proposes PK/FK pairs, which are **never trusted directly**
and all go to validation.

**d. Validation ("Validating candidate N/27").** Real SQL on BigQuery:
distinct child values LEFT JOIN distinct parent values →
coverage = matched/child, violations = unmatched/child.
Hard reject if target uniqueness < 0.9, coverage < 0.9, or violations > 1%.
Score = `0.2·confidence + 0.3·target-uniqueness + 0.4·coverage + 0.1·(1−violations)`
→ **≥0.85 accepted**, ≥0.55 needs review, else dropped.

**e. Graph resolver.** Scores each target as a primary key and each join as a
foreign key; keeps **one accepted target per source column**.

**f. Composite keys ("Probing composite keys N/23").** For tables without a
strong single-column key, tests 2–3 column combinations for uniqueness and
coverage.

**Cardinality is not measured.** Every inferred join is written as
`many_to_one` (FK side → key side), plus the reverse `one_to_many` on the
other table.

Our run: 27 candidates validated → **25 accepted, 0 review**.

### 4. Write the semantic layer
- One file per dataset: `semantic-layer/warehouse/_schema/dev_dna_silver.yaml`
  (tables → columns, descriptions, joins `{to, on, relationship, source: inferred}`).
- **No measures are ever generated from a warehouse scan**: the writer emits
  none, the loader forces `measures: []` for `_schema` entries, and the ingest
  instructions say "Do not invent measures".
- Each written file is a git commit (author `ktx <ktx@example.com>`).

### 5. Index for search
`.ktx/db.sqlite`: full-text (SQLite FTS5) + embeddings for semantic-layer
sources and wiki pages; refreshed on search/reindex.

## Where metrics (measures) come from

| Source | How |
|---|---|
| dbt / MetricFlow / LookML / Looker / Sigma | context-source ingest converts their metrics into measures |
| Agent conversations | the memory agent can capture definitions (`sl_capture` skill) |
| You | write an **overlay** YAML file next to `_schema` |

Overlay example (`semantic-layer/warehouse/d2c_orders.yaml`): a file with
`name:` and no `table:` composes onto the `_schema` entry of the same name and
adds measures:

```yaml
name: d2c_orders
measures:
  - name: gross_revenue
    expr: sum(amount)
```

A file with `table:` or `sql:` instead fully replaces that table's entry.

## Serving a question

```
Claude Code ──MCP──► ktx MCP server (127.0.0.1:7878)
                       ├─ wiki_search / wiki_read     → SQLite FTS + embeddings
                       ├─ sl_query                    → ktx-daemon "semantic-query"
                       │      └─ ktx-sl: join graph → planner → sqlglot SQL (BigQuery dialect)
                       ├─ sql_execution (raw SQL)     → parser check: SELECT/WITH only
                       └─ both execute via connector.executeReadOnly
                              (read-only, row limit, max_bytes_billed, timeout)
```

- **Join graph** (`python/ktx-sl/semantic_layer/graph.py`): shortest-path over
  joins; `many_to_one` costs 1, `one_to_many` costs 10 (avoids fan-out paths).
- **Fan/chasm traps** (`planner.py:976`): measures from different tables are
  pre-aggregated per table in separate CTEs, then joined, so totals are not
  double-counted.
- **SQL**: built and transpiled with `sqlglot` to the BigQuery dialect.
