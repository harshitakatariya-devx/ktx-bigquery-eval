select 'returns.channel_code' k, string_agg(distinct channel_code) v from `sahil-devx.dev_dna_silver.returns`
union all select 'returns.rn values', string_agg(distinct cast(rn as string)) from `sahil-devx.dev_dna_silver.returns`
union all select 'orders date range', concat(cast(min(order_date_key) as string),' .. ',cast(max(order_date_key) as string)) from `sahil-devx.dev_dna_silver.d2c_orders`
union all select 'dim_customer rn/deleted', concat(cast(countif(rn=1) as string),' rn1 / ',cast(countif(is_deleted) as string),' del / ',cast(count(distinct email) as string),' emails') from `sahil-devx.dev_dna_silver.dim_customer`
union all select 'customers_master rn/deleted', concat(cast(countif(rn=1) as string),' rn1 / ',cast(countif(is_deleted) as string),' del / ',cast(count(distinct lower(email)) as string),' emails') from `sahil-devx.dev_dna_silver.customers_master`
union all select 'loyalty tiers (dim_customer)', string_agg(distinct loyalty_tier) from `sahil-devx.dev_dna_silver.dim_customer`
union all select 'employees cols', 'no manager_id column' 
