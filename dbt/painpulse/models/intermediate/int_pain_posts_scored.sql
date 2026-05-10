with filtered as (

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
    from {{ ref('int_pain_posts_filtered') }}

),

scored as (

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

        greatest(coalesce(score, 0), 0) as normalized_score,
        greatest(coalesce(num_comments, 0), 0) as normalized_num_comments,
        abs(least(coalesce(sentiment_score, 0), 0)) as negative_sentiment_strength,
        greatest(coalesce(engagement_score, 0), 0) as normalized_engagement_score,

        (
            greatest(coalesce(score, 0), 0) * 0.30 +
            greatest(coalesce(num_comments, 0), 0) * 0.20 +
            abs(least(coalesce(sentiment_score, 0), 0)) * 0.30 +
            greatest(coalesce(engagement_score, 0), 0) * 0.20
        ) as pain_relevance_score

    from filtered

)

select *
from scored