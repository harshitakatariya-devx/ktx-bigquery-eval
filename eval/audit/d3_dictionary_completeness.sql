-- Step 4: actual distinct values (full table) for columns where ktx's value dictionary looked incomplete.
select 'returns.channel_code' col, string_agg(distinct channel_code order by channel_code) actual from `sahil-devx.dev_dna_silver.returns`
union all select 'employees.channel_code', string_agg(distinct channel_code order by channel_code) from `sahil-devx.dev_dna_silver.employees`
union all select 'marketing_spend.channel_code', string_agg(distinct channel_code order by channel_code) from `sahil-devx.dev_dna_silver.marketing_spend`
union all select 'promotions.channel_code', string_agg(distinct channel_code order by channel_code) from `sahil-devx.dev_dna_silver.promotions`
union all select 'product_codes.channel_code', string_agg(distinct channel_code order by channel_code) from `sahil-devx.dev_dna_silver.product_codes`
union all select 'suppliers.category', string_agg(distinct category order by category) from `sahil-devx.dev_dna_silver.suppliers`
order by 1
