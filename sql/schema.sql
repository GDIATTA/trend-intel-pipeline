create table if not exists dim_product (
product_id serial primary key,
sku text unique not null,
name text not null,
brand text,
category text,
tags text[],
active_from date default current_date,
active_to date
);


create table if not exists fact_sales (
date date not null,
product_id int references dim_product(product_id),
orders int default 0,
qty int default 0,
gross_revenue numeric(12,2) default 0,
net_revenue numeric(12,2) default 0,
channel text,
primary key (date, product_id, coalesce(channel,'all'))
);


create table if not exists fact_social (
date date not null,
product_id int references dim_product(product_id),
platform text not null,
mentions int default 0,
sentiment_score numeric(6,3),
primary key (date, product_id, platform)
);


create table if not exists fact_search (
date date not null,
topic text not null,
region text default 'global',
score int check (score between 0 and 100),
primary key (date, topic, region)
);


create table if not exists fact_web (
date date not null,
product_id int references dim_product(product_id),
sessions int default 0,
pageviews int default 0,
ctr numeric(6,3),
primary key (date, product_id)
);


create table if not exists agg_trend_daily (
date date not null,
product_id int references dim_product(product_id),
trend_score numeric(8,3) not null,
wow_change numeric(8,3),
source_breakdown_json jsonb,
primary key (date, product_id)
);