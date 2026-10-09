-- Period: current (no period)
-- Q11 evidence: how many distinct identities each possible key gives across the 1,600 customers_master records.
select count(*) records,
       count(distinct lower(trim(email))) distinct_emails,
       count(distinct regexp_replace(phone, r'\D', '')) distinct_phones,
       count(distinct lower(trim(customer_name))) distinct_names,
       count(distinct concat(lower(trim(customer_name)), '|', lower(trim(city)))) distinct_name_city
from `sahil-devx.dev_dna_silver.customers_master` where not is_deleted
