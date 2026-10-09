-- Period: August 2026
-- Revenue = line_total (benchmark def). Customer match on email; dim_customer has exactly one row per email.
select coalesce(c.loyalty_tier, '(no match)') loyalty_tier, round(sum(o.line_total), 2) revenue_inr
from `sahil-devx.dev_dna_silver.d2c_orders` o
left join `sahil-devx.dev_dna_silver.dim_customer` c on lower(o.customer_email) = lower(c.email) and not c.is_deleted
where not o.is_deleted and o.order_date_key between '2026-08-01' and '2026-08-31'
group by 1 order by 2 desc
