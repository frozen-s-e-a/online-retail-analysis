#订单数，客户数，GMV
SELECT COUNT(DISTINCT Invoice) AS ORDER_NUM,
       SUM(GMV) AS GMV,
       COUNT(DISTINCT StockCode) AS STOCK_NUM
FROM sales;

SELECT COUNT(DISTINCT customer.`Customer ID`) AS CUS_NUM FROM customer;

#top20商品GMV
SELECT StockCode, SUM(GMV) FROM sales
GROUP BY StockCode
ORDER BY SUM(GMV) DESC
LIMIT 20;

#top20国家GMV
SELECT Country, SUM(GMV) FROM sales
GROUP BY Country
ORDER BY SUM(GMV) DESC
LIMIT 20;

#月度GMV趋势
select
    date_format(InvoiceDate, '%Y-%m') date,
    sum(GMV) gmv_month
from sales
group by date;

# 月度指标: GMV、订单数、件数、客户数、客单价、件均价
select
    date_format(InvoiceDate, '%Y-%m') date,
    sum(GMV) gmv_month,
    count(distinct Invoice) order_num,
    sum(Quantity) quantity_month,
    count(distinct `Customer ID`) cus_num,
    round(sum(if(`Customer ID` is not null, GMV, null))/count(distinct `Customer ID`), 2) price_customer,
    round(sum(GMV)/sum(Quantity), 2) price_quantity
from sales
group by date;

#累计GMV占比
with
    all_gmv as (
        select `Customer ID` cus, round(sum(GMV), 2) per_gmv
        from customer
        group by cus
    ),
    gmv_rate as (
        select
            cus, per_gmv,
            round(sum(per_gmv) over (order by per_gmv desc), 2) cum_gmv,
            round(sum(per_gmv) over (), 2) total_gmv,
            row_number() over (order by per_gmv desc) rn,
            count(cus) over () total_cus
        from all_gmv
    )
select
    cus, per_gmv,
    round(cum_gmv/total_gmv * 100, 2) per_rate,
    round(rn/total_cus * 100, 2) cus_rate
from gmv_rate
where cum_gmv/total_gmv >= 0.80
limit 1;

#复购率
with oder as (
    select
        `Customer ID` customer_id,
        count(distinct Invoice) order_num
    from customer
    group by customer_id
    )
select sum(if(order_num > 1, 1, 0)) / count(*) as repurchase_rate
from oder;

#rfm三维计算
select
    `Customer ID` customer_id,
    count(distinct Invoice) frequency,
    datediff('2011-12-09', max(InvoiceDate)) recency,
    round(sum(GMV), 2) m
from customer
group by customer_id;

#8层客户分类
with
    rfm as (
        select
            `Customer ID` customer_id,
            count(distinct Invoice) frequency,
            datediff('2011-12-09', max(InvoiceDate)) recency,
            round(sum(GMV), 2) m
        from customer
        group by customer_id
    ),
    scored as (
        select
            customer_id, recency, frequency, m,
            case when recency <= 95 then 1 else 0 end as r_score,
            case when frequency >= 3 then 1 else 0 end as f_score,
            case when m >= 880.38 then 1 else 0 end as m_score
        from rfm
    ),
    label as (
        select
            customer_id, m,
            case
                when r_score = 1 and f_score = 1 and m_score = 1 then '重要价值客户'
                when r_score = 1 and f_score = 0 and m_score = 1 then '重要发展客户'
                when r_score = 0 and f_score = 1 and m_score = 1 then '重要保持客户'
                when r_score = 0 and f_score = 0 and m_score = 1 then '重要挽留客户'
                when r_score = 1 and f_score = 1 and m_score = 0 then '一般价值客户'
                when r_score = 1 and f_score = 0 and m_score = 0 then '一般发展客户'
                when r_score = 0 and f_score = 1 and m_score = 0 then '一般保持客户'
                else '一般挽留客户'
            end as customer_label
        from scored
    )
select
    customer_label,
    count(*) as cus_num,
    round(sum(m), 2) total_gmv,
    round(avg(m), 2) avg_gmv,
    round(count(*) * 100.0 / sum(count(*)) over (), 1) cus_pct,
    round(sum(m) * 100.0 / sum(sum(m)) over (), 1) gmv_pct
from label
group by customer_label;






