"""
Description:
    This DAG tests the Airflow's ability to communicate with remote servers.
"""

# import modules and functions
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash_operator import BashOperator

# default DAG arguments
default_args = {
    "owner": "OSDU",
    "retries": 1,
    "retry_delay": timedelta(minutes=5)
}

# set DAG
dag = DAG(
    "test_fetch_remote",
    default_args = default_args,
    description = "A simple DAG to test remote data fetching",
    schedule_interval = "@daily",
    start_date = datetime(2024, 1, 1),
    catchup = False
)



# set tasks
fetch_task = BashOperator(
    task_id = "fetch_task",
    bash_command = "curl --location 'https://postman-echo.com/get?foo1=bar1&foo2=bar2' ", # list services, processes and python packages
    dag = dag
)

# run tasks
fetch_task