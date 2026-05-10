with scored as (

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
        matches_pain_pattern,
        normalized_score,
        normalized_num_comments,
        negative_sentiment_strength,
        normalized_engagement_score,
        pain_relevance_score
    from {{ ref('int_pain_posts_scored') }}

),

ranked as (

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
        matches_pain_pattern,
        normalized_score,
        normalized_num_comments,
        negative_sentiment_strength,
        normalized_engagement_score,
        pain_relevance_score,
        row_number() over (
            order by pain_relevance_score desc, created_at_utc desc, post_id asc
        ) as pain_post_rank
    from scored

)

select *
from ranked