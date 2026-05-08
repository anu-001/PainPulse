import pytest

try:
    from airflow.dag_processing.dagbag import DagBag  # type: ignore
except ImportError:
    DagBag = None


@pytest.mark.skipif(DagBag is None, reason="Airflow not installed in this environment")
def test_reddit_ingest_dag_loads():
    dagbag = DagBag(dag_folder="airflow/dags", include_examples=False)
    assert dagbag.import_errors == {}
    assert "reddit_ingest_daily" in dagbag.dags
    dag = dagbag.get_dag("reddit_ingest_daily")
    assert dag.schedule_interval == "@daily"