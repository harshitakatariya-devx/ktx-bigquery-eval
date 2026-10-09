-- Step 1: test every join ktx accepted (full tables, no sampling).
-- fan-out = rows_after_join - child_rows (must be 0); parent duplicates = parent_rows - parent_distinct_keys (must be 0 for many_to_one).
select 1 n, 'cafe_sales.order_date_key -> dim_date.date_key' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.cafe_sales`) child_rows,
  (select countif(order_date_key is null) from `sahil-devx.dev_dna_silver.cafe_sales`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.cafe_sales` c where c.order_date_key is not null and exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) child_rows_matched,
  (select count(distinct c.order_date_key) from `sahil-devx.dev_dna_silver.cafe_sales` c where c.order_date_key is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_date`) parent_rows,
  (select count(distinct date_key) from `sahil-devx.dev_dna_silver.dim_date`) parent_distinct_keys,
  (select countif(date_key is null) from `sahil-devx.dev_dna_silver.dim_date`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.cafe_sales` c left join `sahil-devx.dev_dna_silver.dim_date` p on p.date_key = c.order_date_key) rows_after_join
union all
select 2 n, 'cafe_sales.product_id -> item_master.product_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.cafe_sales`) child_rows,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.cafe_sales`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.cafe_sales` c where c.product_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) child_rows_matched,
  (select count(distinct c.product_id) from `sahil-devx.dev_dna_silver.cafe_sales` c where c.product_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.item_master`) parent_rows,
  (select count(distinct product_id) from `sahil-devx.dev_dna_silver.item_master`) parent_distinct_keys,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.item_master`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.cafe_sales` c left join `sahil-devx.dev_dna_silver.item_master` p on p.product_id = c.product_id) rows_after_join
union all
select 3 n, 'd2c_orders.customer_email -> dim_customer.email' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.d2c_orders`) child_rows,
  (select countif(customer_email is null) from `sahil-devx.dev_dna_silver.d2c_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.d2c_orders` c where c.customer_email is not null and exists (select 1 from `sahil-devx.dev_dna_silver.dim_customer` p where p.email = c.customer_email)) child_rows_matched,
  (select count(distinct c.customer_email) from `sahil-devx.dev_dna_silver.d2c_orders` c where c.customer_email is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.dim_customer` p where p.email = c.customer_email)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_customer`) parent_rows,
  (select count(distinct email) from `sahil-devx.dev_dna_silver.dim_customer`) parent_distinct_keys,
  (select countif(email is null) from `sahil-devx.dev_dna_silver.dim_customer`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.d2c_orders` c left join `sahil-devx.dev_dna_silver.dim_customer` p on p.email = c.customer_email) rows_after_join
union all
select 4 n, 'd2c_orders.order_date_key -> dim_date.date_key' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.d2c_orders`) child_rows,
  (select countif(order_date_key is null) from `sahil-devx.dev_dna_silver.d2c_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.d2c_orders` c where c.order_date_key is not null and exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) child_rows_matched,
  (select count(distinct c.order_date_key) from `sahil-devx.dev_dna_silver.d2c_orders` c where c.order_date_key is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_date`) parent_rows,
  (select count(distinct date_key) from `sahil-devx.dev_dna_silver.dim_date`) parent_distinct_keys,
  (select countif(date_key is null) from `sahil-devx.dev_dna_silver.dim_date`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.d2c_orders` c left join `sahil-devx.dev_dna_silver.dim_date` p on p.date_key = c.order_date_key) rows_after_join
union all
select 5 n, 'd2c_orders.order_name -> dim_d2c_order.order_name' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.d2c_orders`) child_rows,
  (select countif(order_name is null) from `sahil-devx.dev_dna_silver.d2c_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.d2c_orders` c where c.order_name is not null and exists (select 1 from `sahil-devx.dev_dna_silver.dim_d2c_order` p where p.order_name = c.order_name)) child_rows_matched,
  (select count(distinct c.order_name) from `sahil-devx.dev_dna_silver.d2c_orders` c where c.order_name is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.dim_d2c_order` p where p.order_name = c.order_name)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_d2c_order`) parent_rows,
  (select count(distinct order_name) from `sahil-devx.dev_dna_silver.dim_d2c_order`) parent_distinct_keys,
  (select countif(order_name is null) from `sahil-devx.dev_dna_silver.dim_d2c_order`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.d2c_orders` c left join `sahil-devx.dev_dna_silver.dim_d2c_order` p on p.order_name = c.order_name) rows_after_join
union all
select 6 n, 'd2c_orders.product_id -> item_master.product_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.d2c_orders`) child_rows,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.d2c_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.d2c_orders` c where c.product_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) child_rows_matched,
  (select count(distinct c.product_id) from `sahil-devx.dev_dna_silver.d2c_orders` c where c.product_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.item_master`) parent_rows,
  (select count(distinct product_id) from `sahil-devx.dev_dna_silver.item_master`) parent_distinct_keys,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.item_master`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.d2c_orders` c left join `sahil-devx.dev_dna_silver.item_master` p on p.product_id = c.product_id) rows_after_join
union all
select 7 n, 'dim_customer.customer_master_id -> customers_master.customer_master_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_customer`) child_rows,
  (select countif(customer_master_id is null) from `sahil-devx.dev_dna_silver.dim_customer`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_customer` c where c.customer_master_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.customers_master` p where p.customer_master_id = c.customer_master_id)) child_rows_matched,
  (select count(distinct c.customer_master_id) from `sahil-devx.dev_dna_silver.dim_customer` c where c.customer_master_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.customers_master` p where p.customer_master_id = c.customer_master_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.customers_master`) parent_rows,
  (select count(distinct customer_master_id) from `sahil-devx.dev_dna_silver.customers_master`) parent_distinct_keys,
  (select countif(customer_master_id is null) from `sahil-devx.dev_dna_silver.customers_master`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_customer` c left join `sahil-devx.dev_dna_silver.customers_master` p on p.customer_master_id = c.customer_master_id) rows_after_join
union all
select 8 n, 'dim_d2c_order.customer_email -> dim_customer.email' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_d2c_order`) child_rows,
  (select countif(customer_email is null) from `sahil-devx.dev_dna_silver.dim_d2c_order`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_d2c_order` c where c.customer_email is not null and exists (select 1 from `sahil-devx.dev_dna_silver.dim_customer` p where p.email = c.customer_email)) child_rows_matched,
  (select count(distinct c.customer_email) from `sahil-devx.dev_dna_silver.dim_d2c_order` c where c.customer_email is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.dim_customer` p where p.email = c.customer_email)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_customer`) parent_rows,
  (select count(distinct email) from `sahil-devx.dev_dna_silver.dim_customer`) parent_distinct_keys,
  (select countif(email is null) from `sahil-devx.dev_dna_silver.dim_customer`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_d2c_order` c left join `sahil-devx.dev_dna_silver.dim_customer` p on p.email = c.customer_email) rows_after_join
union all
select 9 n, 'dim_d2c_order.order_date_key -> dim_date.date_key' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_d2c_order`) child_rows,
  (select countif(order_date_key is null) from `sahil-devx.dev_dna_silver.dim_d2c_order`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_d2c_order` c where c.order_date_key is not null and exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) child_rows_matched,
  (select count(distinct c.order_date_key) from `sahil-devx.dev_dna_silver.dim_d2c_order` c where c.order_date_key is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_date`) parent_rows,
  (select count(distinct date_key) from `sahil-devx.dev_dna_silver.dim_date`) parent_distinct_keys,
  (select countif(date_key is null) from `sahil-devx.dev_dna_silver.dim_date`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_d2c_order` c left join `sahil-devx.dev_dna_silver.dim_date` p on p.date_key = c.order_date_key) rows_after_join
union all
select 10 n, 'international_orders.order_date_key -> dim_date.date_key' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.international_orders`) child_rows,
  (select countif(order_date_key is null) from `sahil-devx.dev_dna_silver.international_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.international_orders` c where c.order_date_key is not null and exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) child_rows_matched,
  (select count(distinct c.order_date_key) from `sahil-devx.dev_dna_silver.international_orders` c where c.order_date_key is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_date`) parent_rows,
  (select count(distinct date_key) from `sahil-devx.dev_dna_silver.dim_date`) parent_distinct_keys,
  (select countif(date_key is null) from `sahil-devx.dev_dna_silver.dim_date`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.international_orders` c left join `sahil-devx.dev_dna_silver.dim_date` p on p.date_key = c.order_date_key) rows_after_join
union all
select 11 n, 'international_orders.product_id -> item_master.product_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.international_orders`) child_rows,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.international_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.international_orders` c where c.product_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) child_rows_matched,
  (select count(distinct c.product_id) from `sahil-devx.dev_dna_silver.international_orders` c where c.product_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.item_master`) parent_rows,
  (select count(distinct product_id) from `sahil-devx.dev_dna_silver.item_master`) parent_distinct_keys,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.item_master`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.international_orders` c left join `sahil-devx.dev_dna_silver.item_master` p on p.product_id = c.product_id) rows_after_join
union all
select 12 n, 'inventory_snapshot_expanded.product_id -> item_master.product_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.inventory_snapshot_expanded`) child_rows,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.inventory_snapshot_expanded`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.inventory_snapshot_expanded` c where c.product_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) child_rows_matched,
  (select count(distinct c.product_id) from `sahil-devx.dev_dna_silver.inventory_snapshot_expanded` c where c.product_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.item_master`) parent_rows,
  (select count(distinct product_id) from `sahil-devx.dev_dna_silver.item_master`) parent_distinct_keys,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.item_master`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.inventory_snapshot_expanded` c left join `sahil-devx.dev_dna_silver.item_master` p on p.product_id = c.product_id) rows_after_join
union all
select 13 n, 'marketing_spend.promo_id -> promotions.promo_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.marketing_spend`) child_rows,
  (select countif(promo_id is null) from `sahil-devx.dev_dna_silver.marketing_spend`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.marketing_spend` c where c.promo_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.promotions` p where p.promo_id = c.promo_id)) child_rows_matched,
  (select count(distinct c.promo_id) from `sahil-devx.dev_dna_silver.marketing_spend` c where c.promo_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.promotions` p where p.promo_id = c.promo_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.promotions`) parent_rows,
  (select count(distinct promo_id) from `sahil-devx.dev_dna_silver.promotions`) parent_distinct_keys,
  (select countif(promo_id is null) from `sahil-devx.dev_dna_silver.promotions`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.marketing_spend` c left join `sahil-devx.dev_dna_silver.promotions` p on p.promo_id = c.promo_id) rows_after_join
union all
select 14 n, 'mrp_master.product_id -> item_master.product_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.mrp_master`) child_rows,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.mrp_master`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.mrp_master` c where c.product_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) child_rows_matched,
  (select count(distinct c.product_id) from `sahil-devx.dev_dna_silver.mrp_master` c where c.product_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.item_master`) parent_rows,
  (select count(distinct product_id) from `sahil-devx.dev_dna_silver.item_master`) parent_distinct_keys,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.item_master`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.mrp_master` c left join `sahil-devx.dev_dna_silver.item_master` p on p.product_id = c.product_id) rows_after_join
union all
select 15 n, 'offline_orders.order_date_key -> dim_date.date_key' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.offline_orders`) child_rows,
  (select countif(order_date_key is null) from `sahil-devx.dev_dna_silver.offline_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.offline_orders` c where c.order_date_key is not null and exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) child_rows_matched,
  (select count(distinct c.order_date_key) from `sahil-devx.dev_dna_silver.offline_orders` c where c.order_date_key is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_date`) parent_rows,
  (select count(distinct date_key) from `sahil-devx.dev_dna_silver.dim_date`) parent_distinct_keys,
  (select countif(date_key is null) from `sahil-devx.dev_dna_silver.dim_date`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.offline_orders` c left join `sahil-devx.dev_dna_silver.dim_date` p on p.date_key = c.order_date_key) rows_after_join
union all
select 16 n, 'offline_orders.product_id -> item_master.product_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.offline_orders`) child_rows,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.offline_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.offline_orders` c where c.product_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) child_rows_matched,
  (select count(distinct c.product_id) from `sahil-devx.dev_dna_silver.offline_orders` c where c.product_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.item_master`) parent_rows,
  (select count(distinct product_id) from `sahil-devx.dev_dna_silver.item_master`) parent_distinct_keys,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.item_master`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.offline_orders` c left join `sahil-devx.dev_dna_silver.item_master` p on p.product_id = c.product_id) rows_after_join
union all
select 17 n, 'platform_orders.order_date_key -> dim_date.date_key' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.platform_orders`) child_rows,
  (select countif(order_date_key is null) from `sahil-devx.dev_dna_silver.platform_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.platform_orders` c where c.order_date_key is not null and exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) child_rows_matched,
  (select count(distinct c.order_date_key) from `sahil-devx.dev_dna_silver.platform_orders` c where c.order_date_key is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_date`) parent_rows,
  (select count(distinct date_key) from `sahil-devx.dev_dna_silver.dim_date`) parent_distinct_keys,
  (select countif(date_key is null) from `sahil-devx.dev_dna_silver.dim_date`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.platform_orders` c left join `sahil-devx.dev_dna_silver.dim_date` p on p.date_key = c.order_date_key) rows_after_join
union all
select 18 n, 'platform_orders.product_id -> item_master.product_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.platform_orders`) child_rows,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.platform_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.platform_orders` c where c.product_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) child_rows_matched,
  (select count(distinct c.product_id) from `sahil-devx.dev_dna_silver.platform_orders` c where c.product_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.item_master`) parent_rows,
  (select count(distinct product_id) from `sahil-devx.dev_dna_silver.item_master`) parent_distinct_keys,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.item_master`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.platform_orders` c left join `sahil-devx.dev_dna_silver.item_master` p on p.product_id = c.product_id) rows_after_join
union all
select 19 n, 'product_bundle.component_product_id -> item_master.product_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.product_bundle`) child_rows,
  (select countif(component_product_id is null) from `sahil-devx.dev_dna_silver.product_bundle`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.product_bundle` c where c.component_product_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.component_product_id)) child_rows_matched,
  (select count(distinct c.component_product_id) from `sahil-devx.dev_dna_silver.product_bundle` c where c.component_product_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.component_product_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.item_master`) parent_rows,
  (select count(distinct product_id) from `sahil-devx.dev_dna_silver.item_master`) parent_distinct_keys,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.item_master`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.product_bundle` c left join `sahil-devx.dev_dna_silver.item_master` p on p.product_id = c.component_product_id) rows_after_join
union all
select 20 n, 'product_codes.product_id -> item_master.product_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.product_codes`) child_rows,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.product_codes`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.product_codes` c where c.product_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) child_rows_matched,
  (select count(distinct c.product_id) from `sahil-devx.dev_dna_silver.product_codes` c where c.product_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.item_master`) parent_rows,
  (select count(distinct product_id) from `sahil-devx.dev_dna_silver.item_master`) parent_distinct_keys,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.item_master`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.product_codes` c left join `sahil-devx.dev_dna_silver.item_master` p on p.product_id = c.product_id) rows_after_join
union all
select 21 n, 'purchase_orders.product_id -> item_master.product_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.purchase_orders`) child_rows,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.purchase_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.purchase_orders` c where c.product_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) child_rows_matched,
  (select count(distinct c.product_id) from `sahil-devx.dev_dna_silver.purchase_orders` c where c.product_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.item_master`) parent_rows,
  (select count(distinct product_id) from `sahil-devx.dev_dna_silver.item_master`) parent_distinct_keys,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.item_master`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.purchase_orders` c left join `sahil-devx.dev_dna_silver.item_master` p on p.product_id = c.product_id) rows_after_join
union all
select 22 n, 'purchase_orders.supplier_id -> suppliers.supplier_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.purchase_orders`) child_rows,
  (select countif(supplier_id is null) from `sahil-devx.dev_dna_silver.purchase_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.purchase_orders` c where c.supplier_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.suppliers` p where p.supplier_id = c.supplier_id)) child_rows_matched,
  (select count(distinct c.supplier_id) from `sahil-devx.dev_dna_silver.purchase_orders` c where c.supplier_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.suppliers` p where p.supplier_id = c.supplier_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.suppliers`) parent_rows,
  (select count(distinct supplier_id) from `sahil-devx.dev_dna_silver.suppliers`) parent_distinct_keys,
  (select countif(supplier_id is null) from `sahil-devx.dev_dna_silver.suppliers`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.purchase_orders` c left join `sahil-devx.dev_dna_silver.suppliers` p on p.supplier_id = c.supplier_id) rows_after_join
union all
select 23 n, 'qcomm_orders.order_date_key -> dim_date.date_key' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.qcomm_orders`) child_rows,
  (select countif(order_date_key is null) from `sahil-devx.dev_dna_silver.qcomm_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.qcomm_orders` c where c.order_date_key is not null and exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) child_rows_matched,
  (select count(distinct c.order_date_key) from `sahil-devx.dev_dna_silver.qcomm_orders` c where c.order_date_key is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.order_date_key)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_date`) parent_rows,
  (select count(distinct date_key) from `sahil-devx.dev_dna_silver.dim_date`) parent_distinct_keys,
  (select countif(date_key is null) from `sahil-devx.dev_dna_silver.dim_date`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.qcomm_orders` c left join `sahil-devx.dev_dna_silver.dim_date` p on p.date_key = c.order_date_key) rows_after_join
union all
select 24 n, 'qcomm_orders.product_id -> item_master.product_id' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.qcomm_orders`) child_rows,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.qcomm_orders`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.qcomm_orders` c where c.product_id is not null and exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) child_rows_matched,
  (select count(distinct c.product_id) from `sahil-devx.dev_dna_silver.qcomm_orders` c where c.product_id is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.item_master` p where p.product_id = c.product_id)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.item_master`) parent_rows,
  (select count(distinct product_id) from `sahil-devx.dev_dna_silver.item_master`) parent_distinct_keys,
  (select countif(product_id is null) from `sahil-devx.dev_dna_silver.item_master`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.qcomm_orders` c left join `sahil-devx.dev_dna_silver.item_master` p on p.product_id = c.product_id) rows_after_join
union all
select 25 n, 'returns.return_date_key -> dim_date.date_key' join_name,
  (select count(*) from `sahil-devx.dev_dna_silver.returns`) child_rows,
  (select countif(return_date_key is null) from `sahil-devx.dev_dna_silver.returns`) child_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.returns` c where c.return_date_key is not null and exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.return_date_key)) child_rows_matched,
  (select count(distinct c.return_date_key) from `sahil-devx.dev_dna_silver.returns` c where c.return_date_key is not null and not exists (select 1 from `sahil-devx.dev_dna_silver.dim_date` p where p.date_key = c.return_date_key)) orphan_values,
  (select count(*) from `sahil-devx.dev_dna_silver.dim_date`) parent_rows,
  (select count(distinct date_key) from `sahil-devx.dev_dna_silver.dim_date`) parent_distinct_keys,
  (select countif(date_key is null) from `sahil-devx.dev_dna_silver.dim_date`) parent_null_keys,
  (select count(*) from `sahil-devx.dev_dna_silver.returns` c left join `sahil-devx.dev_dna_silver.dim_date` p on p.date_key = c.return_date_key) rows_after_join
order by n
