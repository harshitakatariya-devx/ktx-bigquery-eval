-- Step 1 follow-ups.
-- (a) Join #5: which d2c_orders.order_name values are missing from dim_d2c_order?
select 'a_orphans_by_deleted' check_name, cast(c.is_deleted as string) k, count(distinct c.order_name) v
from `sahil-devx.dev_dna_silver.d2c_orders` c
where not exists (select 1 from `sahil-devx.dev_dna_silver.dim_d2c_order` p where p.order_name = c.order_name)
group by 2
union all
select 'a_orphans_date_range', concat(cast(min(c.order_date_key) as string), ' .. ', cast(max(c.order_date_key) as string)), count(distinct c.order_name)
from `sahil-devx.dev_dna_silver.d2c_orders` c
where not exists (select 1 from `sahil-devx.dev_dna_silver.dim_d2c_order` p where p.order_name = c.order_name)
union all
select 'a_active_orders_missing', 'is_deleted=false', count(distinct c.order_name)
from `sahil-devx.dev_dna_silver.d2c_orders` c
where not c.is_deleted and not exists (select 1 from `sahil-devx.dev_dna_silver.dim_d2c_order` p where p.order_name = c.order_name)
-- (b) Direction: is the child side also unique (then the join is one_to_one, not many_to_one)?
union all
select 'b_child_unique dim_customer.customer_master_id', cast(count(*) as string), count(distinct customer_master_id) from `sahil-devx.dev_dna_silver.dim_customer`
union all
select 'b_child_unique marketing_spend.promo_id', cast(count(*) as string), count(distinct promo_id) from `sahil-devx.dev_dna_silver.marketing_spend`
-- (c) Join #3 business sense: emails shared by several customers_master records -> which tier does dim_customer keep?
union all
select 'c_shared_emails_tier_differs', 'emails used by >1 customer with different tiers', count(*) from (
  select lower(email) e from `sahil-devx.dev_dna_silver.customers_master` group by 1 having count(distinct customer_master_id) > 1 and count(distinct loyalty_tier) > 1)
union all
select 'c_dim_customer_keeps_tier_of', if(d.customer_master_id = k.keep_id, 'keep_id (original owner)', if(d.customer_master_id = k.change_id, 'change_id (record whose email was overwritten)', 'other')), count(*)
from `sahil-devx.dev_dna_silver._dupe_pairs` k join `sahil-devx.dev_dna_silver.dim_customer` d on lower(d.email) = lower(k.shared_email)
group by 2
order by 1, 2
