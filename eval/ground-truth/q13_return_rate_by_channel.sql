-- Period: all time (2025-06-11 .. 2026-08-31)
-- Distinct returns (rn = 1, not deleted) matched to their original order / distinct orders, per channel.
-- Returns label international orders EXPORT. unmatched_returns = returns whose original_order_ref has no order in that channel.
with orders as (
  select 'D2C' ch, order_name ref from `sahil-devx.dev_dna_silver.d2c_orders` where not is_deleted
  union distinct select 'PLATFORM', order_id from `sahil-devx.dev_dna_silver.platform_orders` where not is_deleted
  union distinct select 'QCOMM', platform_order_id from `sahil-devx.dev_dna_silver.qcomm_orders` where not is_deleted
  union distinct select 'OFFLINE', invoice_no from `sahil-devx.dev_dna_silver.offline_orders` where not is_deleted
  union distinct select 'INTERNATIONAL', order_ref from `sahil-devx.dev_dna_silver.international_orders` where not is_deleted
  union distinct select 'CAFE', concat(store_location, '|', bill_no) from `sahil-devx.dev_dna_silver.cafe_sales` where not is_deleted),
r as (select distinct if(channel_code = 'EXPORT', 'INTERNATIONAL', channel_code) ch, return_id, original_order_ref ref
      from `sahil-devx.dev_dna_silver.returns` where rn = 1 and not is_deleted),
o as (select ch, count(*) orders from orders group by 1),
m as (select r.ch, count(distinct r.return_id) matched, count(distinct if(orders.ref is null, r.return_id, null)) unmatched
      from r left join orders on orders.ch = r.ch and orders.ref = r.ref group by 1)
select o.ch channel, o.orders, coalesce(m.matched - m.unmatched, 0) returns_matched, coalesce(m.unmatched, 0) unmatched_returns,
       round(100 * coalesce(m.matched - m.unmatched, 0) / o.orders, 3) return_rate_pct
from o left join m on m.ch = o.ch order by return_rate_pct desc
