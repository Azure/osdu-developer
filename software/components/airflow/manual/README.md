helm repo add airflow https://airflow.apache.org
helm repo update
helm install airflow airflow/airflow -f values.yaml --namespace osdu-system