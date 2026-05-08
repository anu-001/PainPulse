with
    enriched
    as
    (

        select *
        from {{ ref
    ('stg_reddit_posts_enriched') }}

),

filtered as
(

    select
    post_id,
    subreddit,
    title,
    body,
    score,
    num_comments,
    created_utc,
    created_at_utc,
    sentiment_score,
    engagement_score
from enriched
where matches_pain_pattern = true
    and engagement_score is not null
    and sentiment_score is not null

)

select *
from filtered