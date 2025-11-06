#!/bin/bash
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

if ! command -v dbt &> /dev/null
then
    log "dbt could not be found, installing dbt-databricks adapter..."
    pip install dbt-databricks
else
    log "✅ dbt is already installed."
fi

CATALOG="lakewatch"
if databricks catalogs get "$CATALOG" -o json >/dev/null 2>&1; then
  log "✅ Catalog '$CATALOG' already exists; skipping create."
else
  log "ℹ️ Creating catalog '$CATALOG'..."
    databricks catalogs create "$CATALOG" --comment "lakewatch project" --storage-root s3://dbstorage-prod-rognp/uc/7f80344c-d62e-45f2-baab-7afe8e50d90a/81bc6de5-d4fc-4183-bf26-8b6ad540041f
    log "✅ Catalog '$CATALOG' created."
fi

export DATABRICKS_TOKEN="$(databricks secrets get-secret dbx_project api_token 2>/dev/null \
  | jq -r .value \
  | base64 -D)" \
DATABRICKS_HOST="$(databricks secrets get-secret dbx_project host 2>/dev/null \
  | jq -r .value \
  | base64 -D)" \
DATABRICKS_HTTP_PATH="$(databricks secrets get-secret dbx_project warehouse_id  2>/dev/null \
  | jq -r .value \
  | base64 -D)" \

log "✅ token exported     : (len=${#DATABRICKS_TOKEN})."
log "✅ host exported      : ${DATABRICKS_HOST}."
log "✅ http path exported : ${DATABRICKS_HTTP_PATH}."

dbt --version && echo "✅ dbt is installed."
log "✅ Prerequisites are set."

log "🚀 Running dbt build..."
dbt debug --profiles-dir .
log "✅ dbt build completed."

log "🚀 Generating dbt docs..."
dbt docs generate