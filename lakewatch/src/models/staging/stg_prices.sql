{{ config(
  materialized='table',
  schema='staging',
  file_format='delta',
  tags=['stg_prices']
) }}

select
    account_id,
    sku_name,
    cloud,
    usage_unit,
    pricing.effective_list.default as price,
    cast(date_format(price_start_time, 'yyyy-MM-dd') as date) as price_start_date,
    cast(coalesce(price_end_time, to_timestamp('9999-12-31', 'yyyy-MM-dd')) as date) as price_end_date
from 
    {{ source('billing_data', 'list_prices') }}
qualify row_number() over (
    partition by account_id, sku_name, cloud, pricing.effective_list.default
    order by price_start_date desc
) = 1