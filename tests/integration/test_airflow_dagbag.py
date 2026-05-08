from airflow.dag_processing.dagbag import DagBag

def test_dagbag_loads_without_errors():
    dagbag = DagBag(dag_folder="airflow/dags")
    assert dagbag.import_errors == {}