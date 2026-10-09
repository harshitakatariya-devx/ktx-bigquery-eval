-- Period: August 2026 (2026-08-01 .. 2026-08-31)
select count(distinct order_name) d2c_orders from `sahil-devx.dev_dna_silver.d2c_orders`
where not is_deleted and order_date_key between '2026-08-01' and '2026-08-31'
