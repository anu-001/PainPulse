import os
import psycopg2

def test_postgres_is_reachable():
    conn = psycopg2.connect(
        dbname=os.getenv("PP_DB_NAME"),
        user=os.getenv("PP_DB_USER"),
        password=os.getenv("PP_DB_PASSWORD"),
        host=os.getenv("PP_DB_HOST", "localhost"),
        port=int(os.getenv("PP_DB_PORT", "5432")),
    )
    with conn.cursor() as cur:
        cur.execute("SELECT 1")
        assert cur.fetchone()[0] == 1
    conn.close()