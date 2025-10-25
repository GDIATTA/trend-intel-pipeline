-- Clamp to mitigate outliers
create or replace function clamp(val numeric, lo numeric, hi numeric)
returns numeric language sql immutable as $$
select greatest(lo, least(hi, val));
$$;


-- 7d z-score helper
create or replace view v_sales_7d as
select
fs.date,
fs.product_id,
avg(fs.net_revenue) over (partition by fs.product_id order by fs.date rows between 6 preceding and current row) as avg7,
stddev_pop(fs.net_revenue) over (partition by fs.product_id order by fs.date rows between 6 preceding and current row) as sd7,
fs.net_revenue
from fact_sales fs;