# Setup and test guide

How to clone this repo, connect it to BigQuery and re-run the benchmark
yourself. About 15 minutes. Everything is read-only on BigQuery.

These steps were tested on 2026-10-09 with a fresh clone (macOS, Node 25,
ktx 0.16.0, Claude Code 2.1). The clone answered benchmark Q6 exactly
(₹11,89,35,989.67) in 28 s. The machine already had ktx's Python runtime
installed, so step 3 was not timed from zero.

## What you need

| Need | Notes |
|---|---|
| Node.js 22+ | `node --version` |
| Claude Code, logged in | `claude` works in a terminal. A subscription login is enough; no API key needed |
| A BigQuery service-account key for `sahil-devx` | Ask the project owner for your **own** key. Roles: **BigQuery Data Viewer** + **BigQuery Job User** (nothing more; read-only) |
| git | to clone |

## 1. Install ktx

```bash
npm install -g @kaelio/ktx@0.16.0
ktx --version        # @kaelio/ktx 0.16.0
```

Use this exact version: the results were produced with it.

## 2. Clone and add the key

```bash
git clone <repo-url> ktx-bigquery-eval
cd ktx-bigquery-eval

mkdir -p ~/.config/gcloud
mv ~/Downloads/<your-key>.json ~/.config/gcloud/ktx-reader.json
chmod 600 ~/.config/gcloud/ktx-reader.json
```

`ktx.yaml` reads the key from `~/.config/gcloud/ktx-reader.json`. **Never put
the key inside this repo.**

Optional: turn off ktx's anonymous usage telemetry for this terminal:

```bash
export KTX_TELEMETRY_DISABLED=1
```

## 3. Start ktx's local Python runtime

ktx uses a small local Python service for search embeddings and SQL
generation. Install it once per machine, then start it:

```bash
ktx admin runtime install --feature local-embeddings --yes
ktx admin runtime start --feature local-embeddings
```

## 4. Build the local search index

The YAML and markdown files are in git; the search index (`.ktx/db.sqlite`) is
not, so build it:

```bash
ktx admin reindex
```

Expected: `scanned=29 … embeddings=29`. If it says
**"Embeddings: not configured — indexing lexical only"**, the runtime from
step 3 is not running: start it and run `ktx admin reindex --force`.

This step does not touch BigQuery and costs nothing.

## 5. Check BigQuery access and one metric

```bash
ktx connection test warehouse
# Connection test passed: warehouse

ktx sl --connection-id warehouse query \
  --measure sales.revenue_inr \
  --filter "sales.order_date_key >= '2026-08-01'" \
  --filter "sales.order_date_key < '2026-09-01'" \
  --execute
# "rows": [[118935989.67]]   (= benchmark Q6 ground truth)
```

## 6. Start the ktx MCP server

```bash
ktx mcp start          # serves http://127.0.0.1:7878/mcp
```

This is how Claude Code talks to ktx (configured in `.mcp.json`).

## 7. Try it in Claude Code

```bash
claude
```

Approve the `ktx` MCP server when asked, then check with `/mcp` that `ktx`
shows as connected. Ask, for example:

```
Use ktx: What was our total revenue in August 2026 across all channels?
```

Start a fresh session (`/clear`) for every new test question; otherwise
Claude reuses earlier answers from the conversation.

## 8. Re-run the benchmark

```bash
eval/run.sh my-run            # all 15 questions, ~10 minutes
eval/run.sh my-run 6 13       # only some questions
```

Each question runs in a fresh Claude Code session that can only use ktx tools
(no files, shell or web). Results go to `eval/runs/my-run/`. Compare the
answers with the ground truth in [eval/README.md](../eval/README.md); Run A's
scoring is in [eval/runs/run-a/SCORES.md](../eval/runs/run-a/SCORES.md).

`.claude/settings.json` blocks Claude from reading `eval/`, so it cannot see
the expected answers.

## After a reboot

```bash
cd ktx-bigquery-eval
ktx admin runtime start --feature local-embeddings
ktx mcp start
```

## Things to know

- **ktx changes this repo by itself.** When Claude learns something in a
  conversation it may call ktx's `memory_ingest`, which writes a wiki page or
  a semantic-layer file and **commits it to git**. Check `git log` and
  `git status` after testing. ktx's own commits are authored by
  `ktx <ktx@example.com>`.
- **Commit your own edits before asking questions.** A ktx save can reset
  uncommitted edits to files it tracks (this happened to the `ktx.yaml` cost
  cap during the evaluation).
- **Do not run `ktx setup` or `ktx ingest` unless you mean to re-scan.** A
  re-scan reads BigQuery again and uses Claude to rewrite descriptions. The
  committed `semantic-layer/` files are what the results are based on.
- **Cost cap.** `max_bytes_billed: 10000000000` in `ktx.yaml` makes BigQuery
  refuse any single query that would bill more than 10 GB.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Embeddings: not configured — indexing lexical only` | Step 3 (`ktx admin runtime start …`), then `ktx admin reindex --force` |
| `Access Denied` / `permission` from BigQuery | Your key needs BigQuery Data Viewer + Job User on `sahil-devx` |
| Key not found | The key must be at `~/.config/gcloud/ktx-reader.json` |
| `/mcp` shows ktx failed / Claude has no ktx tools | Run `ktx mcp start` in the repo folder, then restart Claude Code |
| Port 7878 already in use | Another ktx project is serving: `ktx mcp stop` there, or start this one with `--port 7879` and change `.mcp.json` locally |
| BigQuery error about the bytes-billed limit | The 10 GB safety cap worked; narrow the question (date range, fewer tables) |
| `ktx` commands act on the wrong project | Run them from the repo root, or add `--project-dir <path>` |
