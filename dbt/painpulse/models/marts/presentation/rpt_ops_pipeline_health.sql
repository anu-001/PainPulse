with source_freshness as (

    select
        'reddit_raw_posts' as asset_name,
        max(ingested_at) as last_loaded_at,
        count(*) filter (
            where ingested_at >= now() - interval '1 day'
        ) as rows_last_24h
    from {{ source('analytics', 'reddit_raw_posts') }}

),

pain_posts as (

    select
        'fct_pain_posts' as asset_name,
        max(created_at_utc) as last_loaded_at,
        count(*) filter (
            where created_at_utc >= now() - interval '30 day'
        ) as rows_last_30d
    from {{ ref('fct_pain_posts') }}

)

select
    asset_name,
    last_loaded_at,
    rows_last_24h as recent_row_count,
    null::text as notes
from source_freshness

union all

select
    asset_name,
    last_loaded_at,
    rows_last_30d as recent_row_count,
    null::text as notes
from pain_posts