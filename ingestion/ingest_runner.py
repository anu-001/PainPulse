from ingestion.db import get_db_connection, load_active_sources, upsert_posts
from ingestion.reddit_client import RedditClient


def run_ingestion():
    """
    This will be called from Airflow or CLI.

    - Connects to DB
    - Loads active sources
    - Fetches posts per source
    - Upserts into reddit_raw_posts
    """
    conn = get_db_connection()
    try:
        sources = load_active_sources(conn)
        client = RedditClient()

        for cfg in sources:
            posts = client.fetch_posts(cfg)
            upsert_posts(conn, posts)
    finally:
        conn.close()