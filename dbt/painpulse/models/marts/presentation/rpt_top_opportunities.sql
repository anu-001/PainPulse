with base as (

    select
        opportunity_id,
        canonical_title,
        opportunity_score,
        frequency_30d,
        avg_engagement_score,
        avg_pain_intensity,
        first_seen_at,
        last_seen_at,
        tier,
        representative_post_id,
        scoring_version
    from {{ ref('opportunity_rankings') }}

)

select
    opportunity_id,
    canonical_title,
    opportunity_score,
    frequency_30d,
    avg_engagement_score,
    avg_pain_intensity,
    first_seen_at,
    last_seen_at,
    tier,
    representative_post_id,
    scoring_version
from base