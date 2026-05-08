from ingestion.ingest_runner import upsert_posts

def test_upsert_posts_is_idempotent(db_conn):
    posts = [
        {"id": "abc", "title": "A", "body": "B", "score": 1, "num_comments": 0, "subreddit": "x", "created_utc": 1},
    ]
    upsert_posts(db_conn, posts)
    upsert_posts(db_conn, posts)

    with db_conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM reddit_raw_posts WHERE id = 'abc'")
        count = cur.fetchone()[0]
    assert count == 1