{{ config(
  materialized='incremental',
  incremental_strategy='merge',
  incremental_predicates = [
      "DBT_INTERNAL_DEST.session_start > dateadd(day, -7, current_date)"
    ],
  unique_key=['account_id', 'sku_name', 'cloud', 'usage_unit'],
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
    {% if is_incremental() %}
    where
    date_format(price_start_time, 'yyyy-MM-dd') > (
        select
        coalesce(max(price_start_date), '1900-01-01')
        from
        {{ this }}
    )
    {% endif %}