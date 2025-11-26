#!/bin/bash

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

export DATABRICKS_TOKEN="$(databricks --profile DEFAULT secrets get-secret dbx_project api_token 2>/dev/null \
  | jq -r .value \
  | base64 -D)" \
DATABRICKS_HOST="$(databricks --profile DEFAULT secrets get-secret dbx_project host 2>/dev/null \
  | jq -r .value \
  | base64 -D)" \
WAREHOUSE_HTTP_PATH="$(databricks --profile DEFAULT secrets get-secret dbx_project warehouse_http_path  2>/dev/null \
  | jq -r .value \
  | base64 -D)" \
WAREHOUSE_ID="$(databricks --profile DEFAULT secrets get-secret dbx_project warehouse_id  2>/dev/null \
  | jq -r .value \
  | base64 -D)" \

log "✅ token exported          : (len=${#DATABRICKS_TOKEN})."
log "✅ host exported           : ${DATABRICKS_HOST}."
log "✅ warehouse path exported : ${WAREHOUSE_HTTP_PATH}."
log "✅ warehouse_id exported   : ${WAREHOUSE_ID}."

databricks bundle validate --profile DEFAULT
databricks bundle deploy --target dev --profile DEFAULT