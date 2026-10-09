-- Period: n/a (schema check)
-- Q12 evidence: employees has no manager / reports-to column, so a reporting hierarchy cannot be built.
select column_name, data_type from `sahil-devx.dev_dna_silver.INFORMATION_SCHEMA.COLUMNS`
where table_name = 'employees' order by ordinal_position
