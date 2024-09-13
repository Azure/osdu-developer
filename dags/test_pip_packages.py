from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from datetime import datetime
import subprocess

# Define a function to get the list of installed pip packages
def list_installed_packages():
    # Run the pip freeze command to get installed packages
    installed_packages = subprocess.check_output(['pip', 'freeze']).decode('utf-8')
    
    # Log the output to Airflow logs
    print("Installed pip packages:")
    print(installed_packages)

# Define the DAG
default_args = {
    'owner': 'airflow',
    'start_date': datetime(2023, 1, 1),
    'retries': 1
}

with DAG(
    dag_id='list_pip_packages',
    default_args=default_args,
    schedule_interval=None,
    catchup=False
) as dag:

    # Define the task using PythonOperator
    check_pip_packages = PythonOperator(
        task_id='check_pip_packages',
        python_callable=list_installed_packages
    )

    # Set task dependencies (if needed)
    check_pip_packages
