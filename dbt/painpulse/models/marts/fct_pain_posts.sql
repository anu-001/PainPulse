{{ config(materialized='table') }}

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
        matches_pain_pattern,
        normalized_score,
        normalized_num_comments,
        negative_sentiment_strength,
        normalized_engagement_score,
        pain_relevance_score,
        pain_post_rank
    from {{ ref('matched_pain_posts') }}

),

final as (

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
        pain_post_rank,

        case
            when pain_post_rank <= 10 then 'top_10'
            when pain_post_rank <= 50 then 'top_50'
            when pain_post_rank <= 100 then 'top_100'
            else 'long_tail'
        end as rank_bucket

    from source

)

select *
from final