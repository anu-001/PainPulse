with posts as (

    select
        post_id,
        subreddit,
        title,
        body,
        score,
        num_comments,
        created_utc,
        created_at_utc,
        ingested_at_utc
    from {{ ref('stg_reddit_posts') }}

),

enrichment as (

    select
        post_id,
        sentiment_score,
        engagement_score
    from {{ source('analytics', 'reddit_post_enrichment') }}

),

joined as (

    select
        p.post_id,
        p.subreddit,
        p.title,
        p.body,
        p.score,
        p.num_comments,
        p.created_utc,
        p.created_at_utc,
        p.ingested_at_utc,
        e.sentiment_score,
        e.engagement_score,
        case
            when e.sentiment_score < 0 and e.engagement_score >= 1 then true
            else false
        end as matches_pain_pattern
    from posts p
    left join enrichment e
        on p.post_id = e.post_id

)

select *
from joined