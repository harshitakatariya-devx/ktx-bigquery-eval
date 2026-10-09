-- Step 5: verify the factual claims in files ktx wrote by itself during Run A.
-- employees.yaml: "multiple rows per employee (SCD-style)"; measure active_employee_count = distinct employee_id where rn = 1 and not deleted
select 'employees' grp, 'rows / distinct employee_id / rn values / deleted' k,
  concat(cast(count(*) as string), ' / ', cast(count(distinct employee_id) as string), ' / ', string_agg(distinct cast(rn as string)), ' / ', cast(countif(is_deleted) as string)) v
from `sahil-devx.dev_dna_silver.employees`
union all
select 'employees', concat('employment_status=', employment_status), cast(count(distinct employee_id) as string)
from `sahil-devx.dev_dna_silver.employees` where rn = 1 and not is_deleted group by employment_status
union all
-- customer-identity-dedup page: "103 emails shared by 207 records", "26 name pairs share a name"
select 'identity', 'emails shared by >1 record: emails / records', concat(cast(count(*) as string), ' / ', cast(sum(n) as string))
from (select lower(trim(email)) e, count(*) n from `sahil-devx.dev_dna_silver.customers_master` group by 1 having count(*) > 1)
union all
select 'identity', 'names shared by >1 record: names / records', concat(cast(count(*) as string), ' / ', cast(sum(n) as string))
from (select lower(trim(customer_name)) e, count(*) n from `sahil-devx.dev_dna_silver.customers_master` group by 1 having count(*) > 1)
union all
-- revenue-calendar-normalization page: "weekends and a month-end window run at ~2x a normal day"
select 'calendar', day_type, concat('avg/day ', cast(round(avg(rev)) as string), ' over ', cast(count(*) as string), ' days')
from (
  select d, sum(r) rev,
    case when extract(dayofweek from d) in (1, 7) then 'weekend'
         when d >= date_sub(last_day(d), interval 6 day) then 'weekday, last 7 days of month'
         else 'weekday, rest of month' end day_type
  from (
    select order_date_key d, line_total r from `sahil-devx.dev_dna_silver.d2c_orders` where not is_deleted
    union all select order_date_key, units*unit_price - promo_discount from `sahil-devx.dev_dna_silver.platform_orders` where not is_deleted
    union all select order_date_key, qty*selling_price from `sahil-devx.dev_dna_silver.qcomm_orders` where not is_deleted
    union all select order_date_key, net_amount from `sahil-devx.dev_dna_silver.offline_orders` where not is_deleted
    union all select order_date_key, amount from `sahil-devx.dev_dna_silver.cafe_sales` where not is_deleted
    union all select order_date_key, qty*unit_price_usd*83 from `sahil-devx.dev_dna_silver.international_orders` where not is_deleted)
  where d between '2026-01-01' and '2026-06-30'
  group by d)
group by day_type
order by 1, 2
