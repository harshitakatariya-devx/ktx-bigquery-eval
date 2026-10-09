-- Step 3: independent SQL for every measure (all time, soft-deleted rows excluded), written without the semantic layer.
select 'd2c_orders' src, to_json_string(struct(
  sum(line_item_qty) as units_sold, sum(line_item_qty * line_item_price) as gross_revenue_inr, sum(shipping_amount) as shipping_inr,
  sum(line_item_qty * line_item_price + shipping_amount) as net_after_fees_inr, sum(line_total) as revenue_inr,
  countif(line_total != line_item_qty * line_item_price) as lines_where_line_total_ne_qty_x_price,
  countif(abs(line_total - (line_item_qty * line_item_price + shipping_amount)) < 0.01) as lines_where_line_total_eq_gross_plus_shipping)) v
from `sahil-devx.dev_dna_silver.d2c_orders` where not coalesce(is_deleted, false)
union all select 'platform_orders', to_json_string(struct(sum(units) as units_sold, sum(units*unit_price) as gross_revenue_inr, sum(promo_discount) as discount_inr,
  sum(marketplace_fee) as marketplace_fee_inr, sum(units*unit_price - promo_discount - marketplace_fee) as net_after_fees_inr, sum(units*unit_price - promo_discount) as revenue_inr))
from `sahil-devx.dev_dna_silver.platform_orders` where not coalesce(is_deleted, false)
union all select 'qcomm_orders', to_json_string(struct(sum(qty) as units_sold, sum(qty*mrp) as gross_revenue_inr, sum(total_discount) as discount_inr, sum(delivery_fee) as delivery_fee_inr,
  sum(qty*mrp - total_discount - delivery_fee) as net_after_fees_inr, sum(qty*selling_price) as revenue_inr,
  countif(abs(qty*mrp - total_discount - qty*selling_price) > 0.01) as lines_where_mrp_minus_discount_ne_selling_price))
from `sahil-devx.dev_dna_silver.qcomm_orders` where not coalesce(is_deleted, false)
union all select 'offline_orders', to_json_string(struct(sum(qty) as units_sold, sum(qty*mrp) as gross_revenue_inr, sum(qty*mrp - net_amount) as discount_inr,
  sum(net_amount) as net_after_fees_inr, sum(net_amount) as revenue_inr))
from `sahil-devx.dev_dna_silver.offline_orders` where not coalesce(is_deleted, false)
union all select 'international_orders', to_json_string(struct(sum(qty) as units_sold, sum(qty*unit_price_usd*83) as gross_revenue_inr, sum(qty*unit_price_usd) as gross_revenue_usd,
  sum((qty*unit_price_usd - customs_duty_usd)*83) as net_after_fees_inr, sum(qty*unit_price_usd*83) as revenue_inr))
from `sahil-devx.dev_dna_silver.international_orders` where not coalesce(is_deleted, false)
union all select 'cafe_sales', to_json_string(struct(sum(qty) as units_sold, sum(amount) as net_after_fees_inr, sum(amount) as revenue_inr,
  countif(abs(amount - qty*rate) > 0.01) as lines_where_amount_ne_qty_x_rate, count(*) as lines, sum(qty*rate) as qty_x_rate_total))
from `sahil-devx.dev_dna_silver.cafe_sales` where not coalesce(is_deleted, false)
union all select 'returns', to_json_string(struct(count(distinct return_id) as return_count, sum(refund_amount) as refund_amount_inr,
  count(*) as rn1_rows, count(*) - count(distinct return_id) as return_ids_on_multiple_rn1_rows))
from `sahil-devx.dev_dna_silver.returns` where rn = 1 and not coalesce(is_deleted, false)
