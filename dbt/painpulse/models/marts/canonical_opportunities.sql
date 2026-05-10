with source_posts as (

    select *
    from {{ ref('int_canonical_opportunity_keys') }}

),

grouped as (

    select
        md5(canonical_text_key) as opportunity_id,
        canonical_text_key,
        min(created_at_utc) as first_seen_at,
        max(created_at_utc) as last_seen_at,
        count(*) as post_count
    from source_posts
    group by 1, 2

),

representatives as (

    select
        md5(sp.canonical_text_key) as opportunity_id,
        sp.post_id as representative_post_id,
        sp.title as canonical_title,
        row_number() over (
            partition by md5(sp.canonical_text_key)
            order by sp.score desc, sp.num_comments desc, sp.created_at_utc desc
        ) as rn
    from source_posts sp

),

final as (

    select
        g.opportunity_id,
        r.canonical_title,
        r.representative_post_id,
        g.first_seen_at,
        g.last_seen_at,
        g.post_count,
        split_part(g.canonical_text_key, ' ', 1) as topic_keyword_1,
        split_part(g.canonical_text_key, ' ', 2) as topic_keyword_2,
        split_part(g.canonical_text_key, ' ', 3) as topic_keyword_3
    from grouped g
    join representatives r
      on g.opportunity_id = r.opportunity_id
     and r.rn = 1

)

select *
from final