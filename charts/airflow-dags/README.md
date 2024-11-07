
## Install Process

Either manually modify the values.yaml for the chart or generate a custom_values yaml to use.

_The following commands can help generate a prepopulated custom_values file._
```bash
# Setup Variables
GROUP=<your_group>

# Translate Values File
cat > custom_values.yaml << EOF
################################################################################
# Specify the airflow dags specific values
#
airflow:
  manifestdag:
    enabled: true
    items:
      - name: manifest
        folder: "src/osdu_dags"
        compress: true
        url: "https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-dags/-/archive/master/ingestion-dags-master.tar.gz"
        pvc: "airflow-dags-pvc"
  csvdag:
    enabled: false

EOF

NAMESPACE=airflow
helm template airflow-dags . -f custom_values.yaml

helm template airflow-dags . -f custom_values.yaml

helm upgrade --install airflow-dags -f custom_values.yaml . -n $NAMESPACE
```