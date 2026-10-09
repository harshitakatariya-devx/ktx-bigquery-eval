-- Step 3 follow-up: return_ids that appear on more than one current (rn = 1) row.
with d as (
  select return_id, count(*) n, count(distinct channel_code) channels, count(distinct original_order_ref) orders,
         count(distinct refund_amount) refund_values, count(distinct hash_key) hash_keys, sum(refund_amount) refund_sum, max(refund_amount) refund_max
  from `sahil-devx.dev_dna_silver.returns` where rn = 1 and not coalesce(is_deleted, false)
  group by 1 having count(*) > 1)
select count(*) dup_return_ids, sum(n) dup_rows, countif(channels > 1) ids_in_2_channels, countif(orders > 1) ids_with_2_orders,
       countif(refund_values = 1) ids_same_refund, round(sum(refund_sum - refund_max), 2) refund_counted_extra_inr
from d
