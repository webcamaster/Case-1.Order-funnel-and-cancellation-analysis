





### 4.2

with creates as (
    select 
        order_id,
        MIN(time) as created_at
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
