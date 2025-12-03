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
    date_format(price_start_time, 'yyyy-MM-dd') as price_start_date,
    date_format(
      coalesce(price_end_time, current_timestamp()),
      'yyyy-MM-dd'
    ) as price_end_date
from 
    {{ source('billing_data', 'list_prices') }}