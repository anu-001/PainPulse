from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

from ingestion.enrichment_job import run_enrichment


DBT_PROJECT_DIR = "/opt/airflow/dbt"  # mount your dbt project here in docker-compose
DBT_PROFILE = "painpulse"


with DAG(
    dag_id="reddit_modeling_daily",
    start_date=datetime(2026, 1, 1),
    schedule_interval="@daily",
    catchup=False,
    default_args={
        "retries": 1,
        "retry_delay": timedelta(minutes=10),
    },
    tags=["reddit", "dbt", "modeling"],
) as dag:

    dbt_staging = BashOperator(
        task_id="dbt_run_staging",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt run --profiles-dir . --profile {DBT_PROFILE} "
            f"--models stg_reddit_posts"
        ),
    )

    enrich_posts = PythonOperator(
        task_id="run_enrichment_job",
        python_callable=run_enrichment,
    )

    dbt_enriched_and_matched = BashOperator(
        task_id="dbt_run_enriched_and_matched",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt run --profiles-dir . --profile {DBT_PROFILE} "
            f"--models stg_reddit_posts_enriched matched_pain_posts && "
            f"dbt test --profiles-dir . --profile {DBT_PROFILE} "
            f"--models stg_reddit_posts stg_reddit_posts_enriched matched_pain_posts"
        ),
    )

    dbt_staging >> enrich_posts >> dbt_enriched_and_matched