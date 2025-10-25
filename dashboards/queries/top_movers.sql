select a.date, p.sku, p.name, a.trend_score,
a.source_breakdown_json->>'z_sales' as z_sales,
a.source_breakdown_json->>'z_social' as z_social,
a.source_breakdown_json->>'z_search' as z_search,
a.source_breakdown_json->>'z_web' as z_web
from agg_trend_daily a
join dim_product p using (product_id)
where a.date >= current_date - interval '7 days'
order by a.trend_score desc
limit 100;