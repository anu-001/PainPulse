-- Grain: 1 row per raw reddit post (same as reddit_raw_posts)
-- Purpose: type-cleaned, lightly normalized staging layer.

with
    source
    as
    (

        select
            id,
            subreddit,
            title,
            body,
            score,
            num_comments,
            created_utc,
            ingested_at
        from {{ source
    ('analytics', 'reddit_raw_posts') }}

),

typed as
(

    select
    id::text as post_id,
    subreddit::text as subreddit,
    title::text as title,
    coalesce(body::text, '') as body,
    score::integer as score,
    num_comments::integer as num_comments,
    created_utc::bigint as created_utc,
    to_timestamp(created_utc) at time zone 'utc' as created_at_utc,
    ingested_at::timestamptz as ingested_at_utc
from source

)

select *
from typed;