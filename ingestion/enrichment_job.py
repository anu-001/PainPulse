import os
import time

import psycopg2
from psycopg2.extras import execute_values

from ingestion.db import get_db_connection
from ingestion.enrichment import compute_sentiment, compute_engagement


def run_enrichment():
    """
    Enrich recent posts with sentiment and engagement scores into reddit_post_enrichment.

    This job is idempotent on post_id: UPSERTs enrichment rows.
    """
    lookback_hours = int(os.getenv("PP_ENRICH_LOOKBACK_HOURS", "24"))
    now = int(time.time())
    cutoff_unix = now - lookback_hours * 3600

    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT post_id, title, body, score, num_comments
                FROM stg_reddit_posts
                WHERE created_utc >= %s
                """,
                (cutoff_unix,),
            )
            rows = cur.fetchall()

        enrichment_rows = []
        for post_id, title, body, score, num_comments in rows:
            text = f"{title}\n{body}"
            sentiment = compute_sentiment(text)
            engagement = compute_engagement(score, num_comments)
            enrichment_rows.append((post_id, sentiment, engagement))

        if enrichment_rows:
            with conn.cursor() as cur:
                execute_values(
                    cur,
                    """
                    INSERT INTO reddit_post_enrichment (
                        post_id, sentiment_score, engagement_score
                    ) VALUES %s
                    ON CONFLICT (post_id) DO UPDATE SET
                        sentiment_score = EXCLUDED.sentiment_score,
                        engagement_score = EXCLUDED.engagement_score,
                        enriched_at = NOW()
                    """,
                    enrichment_rows,
                )
            conn.commit()
    finally:
        conn.close()