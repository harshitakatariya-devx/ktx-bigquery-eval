"""Step 4: scan semantic-layer descriptions for references to tables that don't exist, ID columns claimed unique,
internal pipeline columns, and declared primary keys. Run: uv run --with pyyaml python eval/audit/d1_descriptions_scan.py"""
import json
import re
from pathlib import Path

import yaml

schema = yaml.safe_load(Path("semantic-layer/warehouse/_schema/dev_dna_silver.yaml").read_text())["tables"]
tables = set(schema)
INTERNAL = {"hash_key", "insert_timestamp", "modified_timestamp", "source_name", "rn", "is_deleted"}
known_words = re.compile(r"\b(dim_[a-z_]+|fact_[a-z_]+|[a-z]+_master|[a-z]+_orders)\b")

missing_refs, unique_claims, internal_visible, pk_tables = [], [], 0, []
for t, entry in schema.items():
    texts = [("table", " ".join((entry.get("descriptions") or {}).values()))]
    if any(c.get("pk") for c in entry["columns"]):
        pk_tables.append(t)
    for c in entry["columns"]:
        d = c.get("descriptions") or {}
        texts.append((c["name"], " ".join(d.values())))
        if c["name"] in INTERNAL:
            internal_visible += c.get("visibility") not in ("internal", "hidden")
        if re.search(r"\bunique\b", d.get("db", ""), re.I) and not re.search(r"not (globally )?unique", d.get("db", ""), re.I):
            unique_claims.append((t, c["name"]))
    for col, text in texts:
        for ref in set(known_words.findall(text)):
            if ref not in tables:
                missing_refs.append((t, col, ref))

print(json.dumps({
    "tables": len(tables),
    "columns": sum(len(e["columns"]) for e in schema.values()),
    "tables_with_declared_pk": pk_tables,
    "internal_columns_visible_to_agent": internal_visible,
    "references_to_tables_not_in_scope": sorted(set(missing_refs)),
    "columns_described_as_unique": unique_claims,
}, indent=1))
