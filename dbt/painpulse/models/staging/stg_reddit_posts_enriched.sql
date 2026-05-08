with
    posts
    as
    (

        select *
        from {{ ref
    ('stg_reddit_posts') }}

),

patterns as
(

    select
    pattern
from {{ source
('analytics', 'pattern_config') }}
    where enabled = true

),

-- For now, we just expose patterns table; actual pattern matching is done in Python
-- through reddit_post_enrichment and matches_pain_pattern will be a DB boolean
-- or we can do a simple heuristic here.

enrichment as
(

    select
    post_id,
    sentiment_score,
    engagement_score
from {{ source
('analytics', 'reddit_post_enrichment') }}

),

joined as
(

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
    -- simple heuristic for now: treat negative sentiment & non-zero engagement as pain
    case
            when e.sentiment_score < 0 and e.engagement_score >= 1
                then true
            else false
        end as matches_pain_pattern
from posts p
    left join enrichment e
    on p.post_id = e.post_id

)

select *
from joined;