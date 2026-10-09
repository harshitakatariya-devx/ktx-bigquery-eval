# Costs

**Short answer: this PoC created no extra bill.** The only metered service is
BigQuery. The queries we measured came to about 2.4 GB, far inside the free
1 TiB/month; the project owner can confirm the exact total with the query
at the end.

## What each part costs

| Part | Billed? | Why |
|---|---|---|
| ktx | **Free** | Open source (Apache 2.0), runs on the laptop |
| Embeddings (search) | **Free** | Local model (`all-MiniLM-L6-v2`) on the laptop; no API |
| Claude (questions, descriptions, ktx's curator) | **No extra bill** | ktx uses Claude Code's existing subscription login (`llm.provider.backend: claude-code`), not an API key. Usage counts toward the plan's normal limits |
| BigQuery | **Only when SQL runs** | On-demand price $6.25 per TiB scanned; the **first 1 TiB per month is free** (shared with everything else on the same billing account). Search, indexing and reading YAML never touch BigQuery |
| GitHub (private repo) | Free | |

## What we used

| Activity | BigQuery | Claude (API-equivalent) |
|---|---|---|
| ktx setup scan, 23 tables (9 min 31 s) | Schema reads + 10k-row samples for join profiling | Not measured (subscription) |
| Benchmark Run A, 15 questions (8.5 min) | Not measured per query (the read-only key cannot list jobs; see the check below), capped at 10 GB per query | **$5.16** total, **$0.34 per question** if it had been billed through the API (reported by Claude Code) |
| Ground truth + semantic-layer audit | ≈ **2.4 GB** in total, measured per query | Not applicable |
| Whole PoC | **Expected to be a few GB, far below the free 1 TiB**; confirm with the check below | |

At list price, even 10 GB would be about $0.06.

## Safety limits

- `max_bytes_billed: 10000000000` in `ktx.yaml`: BigQuery refuses any single
  ktx query that would bill more than 10 GB.
- The service account is read-only (BigQuery Data Viewer + Job User): it can
  run queries but cannot change data.

## Exact billing check (needs the project owner)

The read-only key cannot list jobs (`bigquery.jobs.list` is not granted, by
design). Someone with project-level access can see exactly what this PoC
billed:

```sql
SELECT
  DATE(creation_time, 'Asia/Kolkata') AS day,
  COUNT(*) AS queries,
  ROUND(SUM(total_bytes_billed) / POW(1024, 3), 3) AS gib_billed,
  ROUND(SUM(total_bytes_billed) / POW(1024, 4) * 6.25, 4) AS usd_at_list_price
FROM `sahil-devx`.`region-asia-south1`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE user_email = 'ktx-reader@sahil-devx.iam.gserviceaccount.com'
  AND job_type = 'QUERY'
GROUP BY day
ORDER BY day;
```

## In production (not a PoC)

A team using this every day would pay for:

- **Claude through the API** instead of a personal subscription: about
  **$0.34 per question** with the model used here (Run A); cheaper models cost
  less.
- **BigQuery scans**, as with any BI tool. Defined metrics help because ktx
  writes one filtered query instead of the agent exploring with many queries.

ktx itself stays free.
