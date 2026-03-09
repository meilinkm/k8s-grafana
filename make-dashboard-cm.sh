#!/bin/bash

# This script takes a dashboard ID and creates the configMap for it in the templates folder.

# usage: $0 <dashboard-id> <datasource-name> <configmap-name>
# eg: ./make-dashboard-cm.sh 15761 Prometheus dashboard-kube-state-metrics-v2
# Note that the datasources are automatically created when deploying Grafana, and are called either 'Prometheus' and 'Loki'.

set -e

ID="$1"
DS_NAME="$2"
NAME="$3"

if [ -z "$ID" ] || [ -z "$DS_NAME" ] || [ -z "$NAME" ]; then
  echo "Usage: $0 <dashboard-id> <datasource-name> <name>"
  exit 1
fi

# Output directories (two levels down)
JSON_DIR="helm/templates/dashboards"
CM_DIR="helm/templates"

mkdir -p "$JSON_DIR"

TMP_JSON="dashboard-$ID.json"
FINAL_JSON="$JSON_DIR/$NAME.json"
CM_FILE="$CM_DIR/cm-$NAME.yaml"

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
' "$TMP_JSON" > "$FINAL_JSON"

echo "Generating ConfigMap $CM_FILE..."
cat > "$CM_FILE" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-$NAME
  labels:
    grafana_dashboard: "1"
data:
  dashboard.json: |
{{ tpl ( .Files.Get "templates/dashboards/$NAME.json" ) . | indent 4 }}
EOF

echo "Cleaning up temporary files..."
rm -f "$TMP_JSON"

echo "Done. Created:"
echo " - $FINAL_JSON"
echo " - $CM_FILE"
