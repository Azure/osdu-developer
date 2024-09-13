from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from datetime import datetime
import emoji

def print_emoji_message():
    # Print an emoji message
    print(emoji.emojize(":rocket: The emoji package is installed! :rocket:"))

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2023, 1, 1),
    'retries': 1
}

with DAG(
    dag_id='test_emoji_package',
    default_args=default_args,
    schedule_interval=None,
    catchup=False
) as dag:

    test_task = PythonOperator(
        task_id='print_emoji_message',
        python_callable=print_emoji_message
    )

    test_task