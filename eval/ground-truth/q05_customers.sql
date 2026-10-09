-- Period: current (no period)
select (select count(distinct lower(email)) from `sahil-devx.dev_dna_silver.dim_customer` where not is_deleted) dim_customer_emails,
       (select count(*) from `sahil-devx.dev_dna_silver.customers_master` where not is_deleted) customers_master_rows,
       (select count(distinct lower(email)) from `sahil-devx.dev_dna_silver.customers_master` where not is_deleted) customers_master_emails,
       (select count(distinct regexp_replace(phone, r'\D', '')) from `sahil-devx.dev_dna_silver.customers_master` where not is_deleted) customers_master_phones
