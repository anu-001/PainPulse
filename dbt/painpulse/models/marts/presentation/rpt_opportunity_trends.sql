with daily as (

    select
        co.opportunity_id,
        co.canonical_title,
        date_trunc('day', fp.created_at_utc) as activity_date,
        count(*) as post_count,
        avg(fp.score) as avg_post_score,
        avg(fp.num_comments) as avg_num_comments
    from {{ ref('matched_pain_posts') }} mp
    join {{ ref('fct_pain_posts') }} fp
      on mp.post_id = fp.post_id
    left join {{ ref('canonical_opportunities') }} co
      on co.opportunity_id = co.opportunity_id
    group by 1, 2, 3

)

select
    opportunity_id,
    canonical_title,
    activity_date,
    post_count,
    avg_post_score,
    avg_num_comments
from daily