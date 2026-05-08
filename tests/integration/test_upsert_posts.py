import os

import psycopg2

from ingestion.db import upsert_posts


def _connect():
    return psycopg2.connect(
        host=os.getenv("PP_DB_HOST", "localhost"),
        port=int(os.getenv("PP_DB_PORT", "5432")),
        dbname=os.getenv("PP_DB_NAME", "analytics"),
        user=os.getenv("PP_DB_USER", "analytics_user"),
        password=os.getenv("PP_DB_PASSWORD", "analytics_pass"),
    )


def test_upsert_posts_is_idempotent():
    conn = _connect()
    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE reddit_raw_posts;")
        conn.commit()

    post = {
        "id": "abc123",
        "subreddit": "smallbusiness",
        "title": "Test post",
        "body": "Body",
        "score": 10,
        "num_comments": 1,
        "created_utc": 1715123456,
    }

    upsert_posts(conn, [post])
    upsert_posts(conn, [post])

    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM reddit_raw_posts WHERE id = 'abc123';")
        count = cur.fetchone()[0]
    conn.close()

    assert count == 1