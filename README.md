# grafana

You can pull the chart from its official repo:
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm search repo grafana | grep -E "grafana/grafana |NAME"
NAME                    CHART VERSION   APP VERSION  DESCRIPTION
grafana/grafana         10.5.15         12.3.1       The leading tool for querying and visualizing t...
helm pull grafana/grafana --version 10.5.15 --untar
```
This repo contains a parent helm chart, and is initialized with: 
```bash
mkdir k8s-grafana
cd k8s-grafana
helm create grafana
mv grafana helm
rm -rf helm/templates/*
```
Edit helm/Chart.yaml:
```Bash
apiVersion: v2
name: grafana
description: A Helm chart for grafana on Kubernetes
type: application
version: 0.1.0
appVersion: "12.3.1"

dependencies:
  - name: grafana
    version: 10.5.15
    repository: https://grafana.github.io/helm-charts
```
Run the dependency update which will download the grafana helm chart in tgz format and place it in the charts sub-folder as a child helm chart. It will also create the Chart.lock file.
```Bash
cd helm
helm dependency update
cd charts
tar xvf *tgz
rm -f *tgz
```
In the parent helm chart values.yaml file (k8s-grafana/helm/values.yaml) you can override settings from the child helm chart (k8s-grafana/helm/grafana/charts/grafana/values.yaml). Copy the values.yaml file from the child helm chart to the parent helm chart, and modify/clean up where necessary. 

Test deploy the helm chart - from the helm folder:
```Bash
helm -n monitoring install grafana . -f values.yaml
```
There is a helper script that can generate configMaps for Grafana dashboards. It takes the id of an existing dashboard (on https://grafana.com/grafana/dashboards/), and you specify the datasource to be used as well as the name of configmap. E.g.:
```Bash
./make-dashboard-cm.sh 15761 Prometheus dashboard-kubernetes-api-server
./make-dashboard-cm.sh 21742 Prometheus dashboard-kube-state-metrics-v2
```
Note that (by far) not all dashboards on the Grafana website are suitable for the environment; it greatly depends on the version of several software items (Kubernetes, Grafana, kube-state-metrics, Promtheus, etcetcetera), if a dashboard will work correctly or not. It is therefore advised to try out a dashboard first, before creating a configMap for it.
