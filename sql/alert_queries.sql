-- Products with >= +60% WoW mentions or trend_score jump >= +1.0
with wow_mentions as (
select a.date, a.product_id,
a.mentions,
b.mentions as mentions_prev_week,
case when b.mentions is null or b.mentions=0 then null
else (a.mentions - b.mentions)/b.mentions::numeric end as wow
from (
select date, product_id, sum(mentions) as mentions from v_social_daily group by 1,2
) a
left join (
select date + interval '7 days' as date, product_id, sum(mentions) as mentions from v_social_daily group by 1,2
) b using (date, product_id)
)
select p.sku, p.name, w.date, w.wow, a.trend_score,
(a.source_breakdown_json->>'z_social')::numeric as z_social
from wow_mentions w
join agg_trend_daily a on a.date=w.date and a.product_id=w.product_id
join dim_product p on p.product_id = a.product_id
where (w.wow >= 0.60) or (a.trend_score - lag(a.trend_score) over (partition by a.product_id order by a.date) >= 1.0)
order by w.date desc, a.trend_score desc;