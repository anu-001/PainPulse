with ranked as (

    select
        co.opportunity_id,
        co.canonical_title,
        mp.post_id,
        fp.title,
        fp.body,
        fp.subreddit,
        fp.created_at_utc,
        fp.score,
        fp.num_comments,
        concat('https://reddit.com/comments/', fp.post_id) as reddit_url,
        row_number() over (
            partition by co.opportunity_id
            order by fp.score desc, fp.num_comments desc, fp.created_at_utc desc
        ) as post_rank
    from {{ ref('matched_pain_posts') }} mp
    join {{ ref('fct_pain_posts') }} fp
      on mp.post_id = fp.post_id
    left join {{ ref('canonical_opportunities') }} co
      on co.opportunity_id = co.opportunity_id

)

select
    opportunity_id,
    canonical_title,
    post_id,
    title,
    body,
    subreddit,
    created_at_utc,
    score,
    num_comments,
    reddit_url,
    post_rank
from ranked
where post_rank <= 10