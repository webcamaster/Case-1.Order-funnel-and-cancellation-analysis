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
