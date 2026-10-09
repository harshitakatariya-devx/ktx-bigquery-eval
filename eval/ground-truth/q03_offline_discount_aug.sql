-- Period: August 2026
select round(100 * sum(qty*mrp*discount_pct/100) / sum(qty*mrp), 3) weighted_pct,
       round(100 * sum(qty*mrp - net_amount) / sum(qty*mrp), 3) weighted_from_net_pct,
       round(avg(discount_pct), 3) simple_avg_pct
from `sahil-devx.dev_dna_silver.offline_orders` where not is_deleted and order_date_key between '2026-08-01' and '2026-08-31'
