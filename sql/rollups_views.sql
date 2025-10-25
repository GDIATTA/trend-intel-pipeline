-- Social combined across platforms
create or replace view v_social_daily as
select date, product_id,
sum(mentions) as mentions,
avg(sentiment_score) as sentiment
from fact_social
group by 1,2;


-- WoW helpers
create or replace view v_sales_wow as
select a.date, a.product_id,
a.net_revenue,
b.net_revenue as net_revenue_prev_week,
case when b.net_revenue is null or b.net_revenue = 0 then null
else (a.net_revenue - b.net_revenue) / b.net_revenue::numeric end as wow_sales
from (
select date, product_id, sum(net_revenue) as net_revenue
from fact_sales group by 1,2
) a
left join (
select date + interval '7 days' as date, product_id, sum(net_revenue) as net_revenue
from fact_sales group by 1,2
) b using (date, product_id);