with base as (

    select
        post_id,
        subreddit,
        title,
        body,
        score,
        num_comments,
        created_at_utc,
        coalesce(title, '') || ' ' || coalesce(body, '') as raw_text
    from {{ ref('fct_pain_posts') }}

),

normalized as (

    select
        post_id,
        subreddit,
        title,
        body,
        score,
        num_comments,
        created_at_utc,
        lower(raw_text) as raw_text_lc
    from base

),

cleaned as (

    select
        post_id,
        subreddit,
        title,
        body,
        score,
        num_comments,
        created_at_utc,
        regexp_replace(raw_text_lc, '[^a-z0-9\\s]+', ' ', 'g') as alnum_text
    from normalized

),

collapsed as (

    select
        post_id,
        subreddit,
        title,
        body,
        score,
        num_comments,
        created_at_utc,
        trim(regexp_replace(alnum_text, '\\s+', ' ', 'g')) as normalized_text
    from cleaned

),

keyed as (

    select
        post_id,
        subreddit,
        title,
        body,
        score,
        num_comments,
        created_at_utc,
        left(normalized_text, 180) as canonical_text_key
    from collapsed

)

select *
from keyed