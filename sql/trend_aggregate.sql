-- Parameters
-- weights: sales=0.4, social=0.3, search=0.15, web=0.15
with
sales as (
select s.date, s.product_id,
clamp( (s.net_revenue - avg(s.net_revenue) over w)
/ nullif(stddev_pop(s.net_revenue) over w,0), -3, 3) as z_sales
from (
select date, product_id, sum(net_revenue) as net_revenue
from fact_sales group by 1,2
) s
window w as (partition by product_id order by date rows between 13 preceding and current row)
),
social as (
select d.date, d.product_id,
clamp( (d.mentions - avg(d.mentions) over w)
/ nullif(stddev_pop(d.mentions) over w,0), -3, 3) as z_social
from v_social_daily d
window w as (partition by product_id order by date rows between 13 preceding and current row)
),
web as (
select w.date, w.product_id,
clamp( (w.sessions - avg(w.sessions) over win)
/ nullif(stddev_pop(w.sessions) over win,0), -3, 3) as z_web
from fact_web w
window win as (partition by product_id order by date rows between 13 preceding and current row)
),
search as (
-- Map topic to product via SKU/name keywords in a real impl.
select f.date, p.product_id,
clamp( (avg(f.score) - avg(avg(f.score)) over (partition by p.product_id order by f.date rows between 13 preceding and current row))
/ nullif(stddev_pop(avg(f.score)) over (partition by p.product_id order by f.date rows between 13 preceding and current row),0), -3, 3) as z_search
from fact_search f
join dim_product p on f.topic ilike concat('%', p.sku, '%') or f.topic ilike concat('%', p.name, '%')
group by f.date, p.product_id
)
insert into agg_trend_daily (date, product_id, trend_score, wow_change, source_breakdown_json)
select d.date, d.product_id,
0.40*coalesce(s.z_sales,0) + 0.30*coalesce(o.z_social,0) + 0.15*coalesce(g.z_search,0) + 0.15*coalesce(w.z_web,0) as trend_score,
null as wow_change,
jsonb_build_object('z_sales', s.z_sales, 'z_social', o.z_social, 'z_search', g.z_search, 'z_web', w.z_web)
from (
select date, product_id from fact_sales
union select date, product_id from v_social_daily
union select date, product_id from fact_web
) d
left join sales s on s.date=d.date and s.product_id=d.product_id
left join social o on o.date=d.date and o.product_id=d.product_id
left join search g on g.date=d.date and g.product_id=d.product_id
left join web w on w.date=d.date and w.product_id=d.product_id
on conflict (date, product_id) do update
set trend_score=excluded.trend_score,
source_breakdown_json=excluded.source_breakdown_json;