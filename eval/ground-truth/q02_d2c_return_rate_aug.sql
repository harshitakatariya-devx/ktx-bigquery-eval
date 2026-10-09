-- Period: August 2026 orders (cohort)
-- Cohort: returns (latest version, not deleted) whose original D2C order was placed in Aug 2026 / D2C orders in Aug 2026.
with o as (select distinct order_name from `sahil-devx.dev_dna_silver.d2c_orders` where not is_deleted and order_date_key between '2026-08-01' and '2026-08-31'),
r as (select distinct return_id, original_order_ref from `sahil-devx.dev_dna_silver.returns` where rn = 1 and not is_deleted and channel_code = 'D2C')
select (select count(*) from o) orders,
       (select count(distinct return_id) from r join o on r.original_order_ref = o.order_name) cohort_returns,
       round(100 * (select count(distinct return_id) from r join o on r.original_order_ref = o.order_name) / (select count(*) from o), 3) cohort_rate_pct,
       (select count(distinct return_id) from `sahil-devx.dev_dna_silver.returns` where rn = 1 and not is_deleted and channel_code = 'D2C' and return_date_key between '2026-08-01' and '2026-08-31') returns_initiated_in_aug
