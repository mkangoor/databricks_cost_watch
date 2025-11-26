{{ config(
  materialized='incremental',
  incremental_strategy='merge',
  incremental_predicates = [
      "DBT_INTERNAL_DEST.session_start > dateadd(day, -7, current_date)"
    ],
  unique_key=['workspace_id','account_id', 'sku_name', 'cloud', 'usage_unit'],
  schema='intermediate',
  file_format='delta',
  tags=['int_usage']
) }}

  select
    workspace_id,
    account_id,
    sku_name,
    cloud,
    usage_unit,
    billing_origin_product,
    usage_date,
    job_id,
    sum(usage_quantity) as usage_quantity
  from
    {{ ref('stg_usage') }}
    {% if is_incremental() %}
    where
    usage_date > (
        select
        coalesce(max(usage_date), '1900-01-01')
        from
        {{ this }}
    )
    {% endif %}
  group by
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8