with source as (

    select
        post_id,
        subreddit,
        title,
        body,
        score,
        num_comments,
        created_utc,
        created_at_utc,
        ingested_at_utc,
        sentiment_score,
        engagement_score,
        matches_pain_pattern
    from {{ ref('stg_reddit_posts_enriched') }}

),

filtered as (

    select
        post_id,
        subreddit,
        title,
        body,
        score,
        num_comments,
        created_utc,
        created_at_utc,
        ingested_at_utc,
        sentiment_score,
        engagement_score,
        matches_pain_pattern
    from source
    where matches_pain_pattern = true

)

select *
from filtered