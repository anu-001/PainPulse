CREATE TABLE IF NOT EXISTS source_config (
    id SERIAL PRIMARY KEY,
    subreddit TEXT NOT NULL,
    query TEXT NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    last_run_at TIMESTAMPTZ,
    poll_interval_minutes INTEGER NOT NULL DEFAULT 1440
);

CREATE TABLE IF NOT EXISTS reddit_raw_posts (
    id TEXT PRIMARY KEY,
    subreddit TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    score INTEGER NOT NULL,
    num_comments INTEGER NOT NULL,
    created_utc BIGINT NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pattern_config (
    id SERIAL PRIMARY KEY,
    pattern TEXT NOT NULL,
    description TEXT,
    enabled BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS reddit_post_enrichment (
    post_id TEXT PRIMARY KEY,
    sentiment_score DOUBLE PRECISION,
    engagement_score DOUBLE PRECISION,
    enriched_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);