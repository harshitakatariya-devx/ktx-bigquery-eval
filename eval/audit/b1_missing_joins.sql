-- Step 2: joins ktx did not create (or rejected). All counts on full tables.
with orders as (
  select 'D2C' ch, order_name ref from `sahil-devx.dev_dna_silver.d2c_orders`
  union distinct select 'PLATFORM', order_id from `sahil-devx.dev_dna_silver.platform_orders`
  union distinct select 'QCOMM', platform_order_id from `sahil-devx.dev_dna_silver.qcomm_orders`
  union distinct select 'OFFLINE', invoice_no from `sahil-devx.dev_dna_silver.offline_orders`
  union distinct select 'INTERNATIONAL', order_ref from `sahil-devx.dev_dna_silver.international_orders`),
any_order as (select distinct ref from orders),
dd as (select min(date_key) lo, max(date_key) hi from `sahil-devx.dev_dna_silver.dim_date`)
-- 1. returns.original_order_ref: per channel, and against ANY channel (why ktx's single-target test fails)
select '1 returns.original_order_ref' grp, r.channel_code k,
       count(*) n, countif(o.ref is not null) matched_same_channel, countif(a.ref is not null) matched_any_channel
from `sahil-devx.dev_dna_silver.returns` r
left join orders o on o.ref = r.original_order_ref and o.ch = if(r.channel_code = 'EXPORT', 'INTERNATIONAL', r.channel_code)
left join any_order a on a.ref = r.original_order_ref
group by 2
union all
select '2 returns.exchange_order_ref', 'non-null', countif(exchange_order_ref is not null),
       countif(exists (select 1 from any_order a where a.ref = r.exchange_order_ref)), null
from `sahil-devx.dev_dna_silver.returns` r
union all
-- 3. shipments.order_ref per channel
select '3 shipments.order_ref', s.channel_code, count(*),
       countif(o.ref is not null), countif(a.ref is not null)
from `sahil-devx.dev_dna_silver.shipments` s
left join orders o on o.ref = s.order_ref and o.ch = s.channel_code
left join any_order a on a.ref = s.order_ref
group by 2
union all
-- 4. rejected: qcomm_orders.platform_order_id -> platform_orders.order_id
select '4 rejected qcomm.platform_order_id in platform_orders.order_id', 'distinct ids',
       count(distinct q.platform_order_id), count(distinct p.order_id), null
from `sahil-devx.dev_dna_silver.qcomm_orders` q left join (select distinct order_id from `sahil-devx.dev_dna_silver.platform_orders`) p on p.order_id = q.platform_order_id
union all
-- 5. date columns not linked to dim_date: rows inside the dim_date range
select '5 date in dim_date range', 'purchase_orders.po_date', count(*), countif(po_date between (select lo from dd) and (select hi from dd)), null from `sahil-devx.dev_dna_silver.purchase_orders`
union all select '5 date in dim_date range', 'marketing_spend.spend_date', count(*), countif(spend_date between (select lo from dd) and (select hi from dd)), null from `sahil-devx.dev_dna_silver.marketing_spend`
union all select '5 date in dim_date range', 'inventory.snapshot_date', count(*), countif(snapshot_date between (select lo from dd) and (select hi from dd)), null from `sahil-devx.dev_dna_silver.inventory_snapshot_expanded`
union all select '5 date in dim_date range', 'shipments.dispatch_date', count(*), countif(dispatch_date between (select lo from dd) and (select hi from dd)), null from `sahil-devx.dev_dna_silver.shipments`
union all select '5 date in dim_date range', concat('dim_date covers ', cast((select lo from dd) as string), '..', cast((select hi from dd) as string)), null, null, null
union all
-- 6. employees.store_id overlap with store codes used in sales tables
select '6 employees.store_id', e.channel_code, count(distinct e.store_id),
       count(distinct if(e.store_id in (select store_code from `sahil-devx.dev_dna_silver.offline_orders`), e.store_id, null)),
       count(distinct if(e.store_id in (select store_location from `sahil-devx.dev_dna_silver.cafe_sales`) or e.store_id in (select dark_store from `sahil-devx.dev_dna_silver.qcomm_orders`), e.store_id, null))
from `sahil-devx.dev_dna_silver.employees` e group by 2
union all
-- 7. customer links for non-D2C channels: qcomm mobile -> customers_master.phone (digits only)
select '7 qcomm.cust_mobile in customers_master.phone', 'distinct mobiles', count(distinct q.cust_mobile),
       count(distinct if(c.p is not null, q.cust_mobile, null)), null
from `sahil-devx.dev_dna_silver.qcomm_orders` q
left join (select distinct right(regexp_replace(phone, r'\D', ''), 10) p from `sahil-devx.dev_dna_silver.customers_master`) c
  on c.p = right(regexp_replace(q.cust_mobile, r'\D', ''), 10)
union all
-- 8. legacy customer table
select '8 legacy customer table', concat(cast(min(date(invoice_date)) as string), '..', cast(max(date(invoice_date)) as string), ' channel=', string_agg(distinct channel_code)), count(*), null, null
from `sahil-devx.dev_dna_silver.customer`
order by 1, 2
