with config as (

    select *
    from {{ ref('scoring_config') }}
    where config_version = 'v1'

),

posts as (

    select
        mp.post_id,
        mp.subreddit,
        mp.created_at_utc,
        mp.engagement_score,
        mp.sentiment_score,
        co.opportunity_id,
        co.canonical_title,
        co.representative_post_id,
        co.first_seen_at,
        co.last_seen_at
    from {{ ref('matched_pain_posts') }} mp
    join {{ ref('int_canonical_opportunity_keys') }} ck
      on mp.post_id = ck.post_id
    join {{ ref('canonical_opportunities') }} co
      on md5(ck.canonical_text_key) = co.opportunity_id

),

aggregated as (

    select
        opportunity_id,
        canonical_title,
        representative_post_id,
        min(first_seen_at) as first_seen_at,
        max(last_seen_at) as last_seen_at,
        count(*) filter (
            where created_at_utc >= now() - interval '30 day'
        ) as frequency_30d,
        avg(engagement_score) as avg_engagement_score,
        avg(sentiment_score) as avg_pain_intensity
    from posts
    group by 1, 2, 3

),

scored as (

    select
        a.*,
        c.config_version as scoring_version,
        (
            (a.frequency_30d * c.frequency_weight) +
            (coalesce(a.avg_engagement_score, 0) * c.engagement_weight) +
            (abs(coalesce(a.avg_pain_intensity, 0)) * c.pain_weight)
        ) as opportunity_score_raw
    from aggregated a
    cross join config c

),

normalized as (

    select
        *,
        case
            when max(opportunity_score_raw) over () = 0 then 0
            else opportunity_score_raw / max(opportunity_score_raw) over ()
        end as opportunity_score
    from scored

),

tiered as (

    select
        n.*,
        case
            when n.opportunity_score >= c.tier1_threshold then 'Tier 1'
            when n.opportunity_score >= c.tier2_threshold then 'Tier 2'
            else 'Tier 3'
        end as tier
    from normalized n
    cross join config c

)

select
    opportunity_id,
    canonical_title,
    representative_post_id,
    first_seen_at,
    last_seen_at,
    frequency_30d,
    avg_engagement_score,
    avg_pain_intensity,
    scoring_version,
    opportunity_score,
    tier
from tiered