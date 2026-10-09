-- Period: January 2026 vs February 2026
with s as (
select 'D2C' channel_code, order_date_key, product_id, line_total revenue_inr from `sahil-devx.dev_dna_silver.d2c_orders` where not is_deleted
union all select 'PLATFORM', order_date_key, product_id, units*unit_price - promo_discount from `sahil-devx.dev_dna_silver.platform_orders` where not is_deleted
union all select 'QCOMM', order_date_key, product_id, qty*selling_price from `sahil-devx.dev_dna_silver.qcomm_orders` where not is_deleted
union all select 'OFFLINE', order_date_key, product_id, net_amount from `sahil-devx.dev_dna_silver.offline_orders` where not is_deleted
union all select 'CAFE', order_date_key, product_id, amount from `sahil-devx.dev_dna_silver.cafe_sales` where not is_deleted
union all select 'INTERNATIONAL', order_date_key, product_id, qty*unit_price_usd*83 from `sahil-devx.dev_dna_silver.international_orders` where not is_deleted
)
select format_date('%Y-%m', order_date_key) month, round(sum(revenue_inr),2) revenue_inr, count(distinct order_date_key) days, round(sum(revenue_inr)/count(distinct order_date_key),2) per_day from s where order_date_key between '2026-01-01' and '2026-02-28' group by 1 order by 1
