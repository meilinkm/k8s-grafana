#!/bin/bash

# This script takes a dashboard ID and creates the configMap for it in the templates folder.

# usage: $0 <dashboard-id> <datasource-name> <configmap-name>
# eg: ./make-dashboard-cm.sh 15761 Prometheus dashboard-kube-state-metrics-v2
# Note that the datasources are automatically created when deploying Grafana, and are called either 'Prometheus' and 'Loki'.

set -e

ID="$1"
DS_NAME="$2"
CM_NAME="$3"

if [ -z "$ID" ] || [ -z "$DS_NAME" ] || [ -z "$CM_NAME" ]; then
  echo "Usage: $0 <dashboard-id> <datasource-name> <configmap-name>"
  exit 1
fi

TMP_JSON="dashboard-$ID.json"
FIXED_JSON="dashboard-$ID-fixed.json"
CM_FILE="helm/templates/$CM_NAME.yaml"

echo "Downloading dashboard $ID..."
curl -s -L "https://grafana.com/api/dashboards/$ID/revisions/latest/download" -o "$TMP_JSON"

echo "Rewriting datasources to \"$DS_NAME\"..."
jq '
  walk(
    if type == "object" and .datasource?
       and (.datasource|type=="object")
    then .datasource = "'$DS_NAME'"
    else .
    end
  )
' "$TMP_JSON" > "$FIXED_JSON"

echo "Generating ConfigMap $CM_FILE..."
cat > "$CM_FILE" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: $CM_NAME
  labels:
    grafana_dashboard: "1"
data:
  dashboard.json: |
$(sed 's/^/    /' "$FIXED_JSON")
EOF

echo "Cleaning up temporary files..."
rm -f "$TMP_JSON" "$FIXED_JSON"

echo "Done. ConfigMap written to $CM_FILE"
