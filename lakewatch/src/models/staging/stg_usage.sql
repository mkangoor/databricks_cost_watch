{{ config(
  materialized='incremental',
  incremental_strategy='merge',
  unique_key=['record_id','workspace_id'],
  schema='staging',
  file_format='delta',
  tags=['stg_usage'],
  on_schema_change='sync_all_columns'
) }}

select
    record_id,
    workspace_id,
    account_id,
    sku_name,
    cloud,
    usage_unit,
    usage_type,
    billing_origin_product,
    usage_date,
    ingestion_date,
    identity_metadata.run_as as run_as_user,
    identity_metadata.created_by as created_by,
    identity_metadata.owned_by as owned_by,
    usage_metadata.job_id as job_id,
    usage_metadata.job_name as job_name,
    usage_metadata.job_run_id as job_run_id,
    usage_metadata.cluster_id as cluster_id,
    usage_quantity,
    product_features
from 
    {{ source('billing_data', 'usage') }}
{% if is_incremental() %}
  where usage_date >= dateadd(day, -7,
    (select coalesce(max(usage_date), '1900-01-01') from {{ this }})
  )
{% endif %}
