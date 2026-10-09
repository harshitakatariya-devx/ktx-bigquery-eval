-- Period: n/a (schema check)
-- Q14 evidence: no lot / batch column exists in any silver table, so units cannot be traced to a supplier lot.
select table_name, column_name from `sahil-devx.dev_dna_silver.INFORMATION_SCHEMA.COLUMNS`
where regexp_contains(lower(column_name), r'lot|batch|serial')
union all
select '(none found)', '' from (select 1) where not exists (
  select 1 from `sahil-devx.dev_dna_silver.INFORMATION_SCHEMA.COLUMNS` where regexp_contains(lower(column_name), r'lot|batch|serial'))
