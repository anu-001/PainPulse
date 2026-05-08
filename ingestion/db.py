# ingestion/db.py

import os
from typing import Iterable, Dict, Any, List

import psycopg2
from psycopg2.extras import execute_values


def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("PP_DB_HOST", "localhost"),
        port=int(os.getenv("PP_DB_PORT", "5432")),
        dbname=os.getenv("PP_DB_NAME", "analytics"),
        user=os.getenv("PP_DB_USER", "analytics_user"),
        password=os.getenv("PP_DB_PASSWORD", "analytics_pass"),
    )


def upsert_posts(conn, posts: Iterable[Dict[str, Any]]):
    """
    Uses ON CONFLICT(id) DO UPDATE to allow safe re-runs.
    """
    rows: List[tuple] = []
    for p in posts:
        rows.append(
            (
                p["id"],
                p["subreddit"],
                p["title"],
                p.get("body") or "",
                int(p.get("score") or 0),
                int(p.get("num_comments") or 0),
                int(p.get("created_utc") or 0),
            )
        )

    if not rows:
        return

    with conn.cursor() as cur:
        execute_values(
            cur,
            """
            INSERT INTO reddit_raw_posts (
                id, subreddit, title, body, score, num_comments, created_utc
            ) VALUES %s
            ON CONFLICT (id) DO UPDATE SET
                subreddit = EXCLUDED.subreddit,
                title = EXCLUDED.title,
                body = EXCLUDED.body,
                score = EXCLUDED.score,
                num_comments = EXCLUDED.num_comments,
                created_utc = EXCLUDED.created_utc
            """,
            rows,
        )
    conn.commit()



def load_active_sources(conn):
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT subreddit, query
            FROM source_config
            WHERE enabled = TRUE
            """
        )
        rows = cur.fetchall()

    from ingestion.reddit_client import RedditSourceConfig
    # a simple time window placeholder
    import time

    now = int(time.time())
    day_ago = now - 24 * 3600

    return [
        RedditSourceConfig(subreddit=r[0], query=r[1], since_utc=day_ago, until_utc=now)
        for r in rows
    ]