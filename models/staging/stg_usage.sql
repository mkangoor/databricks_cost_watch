{{ config(
  materialized='incremental',
  incremental_strategy='merge',
  unique_key=['account_id', 'sku_name', 'cloud', 'usage_unit', 'usage_date'],
  schema='staging',
  file_format='delta',
  tags=['stg_usage']
) }}

select
    workspace_id,
    account_id,
    sku_name,
    cloud,
    usage_unit,
    billing_origin_product,
    usage_date,
    ingestion_date,
    usage_metadata.job_id as job_id,
    usage_quantity
from 
    {{ source('billing_data', 'usage') }}
    {% if is_incremental() %}
    where
    usage_date > (
        select
        coalesce(max(usage_date), '1900-01-01')
        from
        {{ this }}
    )
    {% endif %}