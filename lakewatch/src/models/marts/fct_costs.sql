{{ config(
  materialized='incremental',
  incremental_strategy='merge',
  unique_key=['workspace_id','account_id','usage_date','sku_name','job_id','cloud','usage_unit'],
  schema='marts',
  file_format='delta',
  tags=['fct_costs']
) }}

select
    u.workspace_id,
    u.account_id,
    u.usage_date,
    u.sku_name,
    u.job_id,
    u.cloud,
    u.usage_unit,
    round((sum(u.usage_quantity) * p.price), 2) as cost
from
    {{ ref('int_usage') }} u
    inner join {{ ref('stg_prices') }} p
      on  u.account_id = p.account_id
      and u.sku_name   = p.sku_name
      and u.cloud      = p.cloud
      and u.usage_unit = p.usage_unit
where
    u.usage_date between p.price_start_date and p.price_end_date
    {% if is_incremental() %}
      and u.usage_date >= date_add(
        (select coalesce(max(usage_date), '1900-01-01') from {{ this }}),
        -7
      )
    {% endif %}
group by
    u.workspace_id,
    u.account_id,
    u.usage_date,
    p.price,
    u.sku_name,
    u.job_id,
    u.cloud,
    u.usage_unit
