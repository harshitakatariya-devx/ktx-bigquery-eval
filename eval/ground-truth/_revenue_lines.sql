-- Benchmark revenue definition (reproduces the doc's Q6 exactly). Shared by Q6–Q10.
select 'D2C' channel_code, order_date_key, product_id, line_total revenue_inr from `sahil-devx.dev_dna_silver.d2c_orders` where not is_deleted
union all select 'PLATFORM', order_date_key, product_id, units*unit_price - promo_discount from `sahil-devx.dev_dna_silver.platform_orders` where not is_deleted
union all select 'QCOMM', order_date_key, product_id, qty*selling_price from `sahil-devx.dev_dna_silver.qcomm_orders` where not is_deleted
union all select 'OFFLINE', order_date_key, product_id, net_amount from `sahil-devx.dev_dna_silver.offline_orders` where not is_deleted
union all select 'CAFE', order_date_key, product_id, amount from `sahil-devx.dev_dna_silver.cafe_sales` where not is_deleted
union all select 'INTERNATIONAL', order_date_key, product_id, qty*unit_price_usd*83 from `sahil-devx.dev_dna_silver.international_orders` where not is_deleted
