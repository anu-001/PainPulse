from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.python import PythonOperator

from ingestion.ingest_runner import run_ingestion


with DAG(
    dag_id="reddit_ingest_daily",
    start_date=datetime(2026, 1, 1),
    schedule_interval="@daily",
    catchup=False,
    default_args={
        "retries": 1,
        "retry_delay": timedelta(minutes=10),
    },
    tags=["reddit", "ingestion"],
) as dag:
    ingest = PythonOperator(
        task_id="run_reddit_ingestion",
        python_callable=run_ingestion,
    )