-- ------------------------------------------------------------
-- 1. Общая воронка: total_orders, cancel_orders, cancel_rate
-- ------------------------------------------------------------
select 
    count(distinct order_id) filter (where action = 'create_order') as total_orders,
    count(distinct order_id) filter (where action = 'cancel_order') as cancel_orders,
    count(distinct order_id) filter (where action = 'cancel_order')::numeric / count(distinct order_id) filter (where action = 'create_order')::numeric * 100 as cancel_rate
from user_actions


-- ------------------------------------------------------------
-- 2. Отмены по дням (день = день СОЗДАНИЯ заказа)
-- ------------------------------------------------------------
with creates as (
    select 
        order_id,
        min(time) as created_at
    from user_actions 
    where action = 'create_order' 
    group by order_id
),
cancels as (
    select 
        order_id
    from user_actions 
    where action = 'cancel_order' 
    group by order_id
)
select
    count(creates.order_id) as create_orders,
    count(cancels.order_id) as cancel_orders,
    round(count(cancels.order_id)::numeric / count(creates.order_id) * 100, 2) as cancel_rate,
    created_at::date as date
from creates left join cancels using(order_id)
group by created_at::date

    
-- ------------------------------------------------------------
-- 3. Отмены по часам
-- ------------------------------------------------------------
with creates as (
    select 
        order_id,
        min(time) as created_at
    from user_actions 
    where action = 'create_order' 
    group by order_id
),
cancels as (
    select 
        order_id
    from user_actions 
    where action = 'cancel_order' 
    group by order_id
)
select
    count(creates.order_id) as create_orders,
    count(cancels.order_id) as cancel_orders,
    round(count(cancels.order_id)::numeric / count(creates.order_id) * 100, 2) as cancel_rate,
    extract(hour from created_at) as hours
from creates left join cancels using(order_id)
group by extract(hour from created_at)
order by hours


-- ------------------------------------------------------------
-- 4. Время до отмены
-- ------------------------------------------------------------
with creates as (
    select 
        order_id,
        min(time) as create_time
    from user_actions
    where action = 'create_order'
    group by order_id
),
cancels as (
    select
        order_id,
        max(time) as cancel_time
    from user_actions
    where action = 'cancel_order'
    group by order_id
),

t1 as (
    select 
        extract(epoch from cancel_time - create_time) as created_at
    from cancels left join creates using(order_id)
)
select
    min(created_at) as min_sec,
    percentile_cont(0.5) within group (order by created_at) as median_sec,
    avg(created_at) as avg_sec,
    max(created_at) as max_sec
from t1;


-- ------------------------------------------------------------
-- 5. Сегментация: пол и возраст
-- ------------------------------------------------------------
with creates as (
    select 
        user_id,
        order_id,
        min(time) as create_time
    from user_actions
    where action = 'create_order'
    group by order_id, user_id
),
cancels as (
    select
        order_id,
        max(time) as cancel_time
    from user_actions
    where action = 'cancel_order'
    group by order_id
),


t1 as (
    select 
        user_id,
        order_id,
        cancel_time,
        create_time
    from creates 
    left join cancels using(order_id)
)
select 
    case 
        when birth_date is null then 'unknown'
        when (2022 - extract(year from birth_date)) < 25 then '<25'
        when (2022 - extract(year from birth_date)) < 35 then '25-34'
        when (2022 - extract(year from birth_date)) < 45 then '35-44'
        else '45+'
    end as age_group,
    sex,
    count(*)                                              AS create_orders,
    count(t1.cancel_time)                                 AS cancel_orders,
    round(count(t1.cancel_time)::numeric / count(*) * 100, 2) AS cancel_rate
from t1 
left join users on users.user_id = t1.user_id
group by 
    case 
        when birth_date is null then 'unknown'
        when (2022 - extract(year from birth_date)) < 25 then '<25'
        when (2022 - extract(year from birth_date)) < 35 then '25-34'
        when (2022 - extract(year from birth_date)) < 45 then '35-44'
        else '45+'
    end,
    users.sex


