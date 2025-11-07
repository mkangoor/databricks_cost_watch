{{ config(
  materialized='incremental',
  incremental_strategy='merge',
  incremental_predicates = [
      "DBT_INTERNAL_DEST.session_start > dateadd(day, -7, current_date)"
    ],
  unique_key=['workspace_id','account_id','sku_name','cloud','usage_unit'],
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
    inner join {{ ref('stg_prices') }} p on u.account_id = p.account_id
    and u.sku_name = p.sku_name
    and u.cloud = p.cloud
    and u.usage_unit = p.usage_unit
  where
    u.usage_date between p.price_start_date
    and p.price_end_date
  group by
    u.workspace_id,
    u.account_id,
    u.usage_date,
    p.price,
    u.sku_name,
    u.job_id,
    u.cloud,
    u.usage_unit