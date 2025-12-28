-- customer_orders clean up
create view vw_customer_orders_clean as
select 
	order_id,
	customer_id,
    pizza_id,
    case
		when exclusions is null or exclusions like 'null' or exclusions like '' then null
	else exclusions end as exclusions,
    case
		when extras is null or extras like 'null' or extras like '' then null
	else extras end as extras,
    order_time
from customer_orders

-- runner_orders clean up

create view vw_runner_orders_clean as
select 
	order_id,
    runner_id,
    cast(case when pickup_time like 'null' then null else pickup_time end as datetime) pickup_time,
    cast(case when distance like 'null' then null else replace(distance, 'km', '') end as float) as distance,
    cast(nullif(regexp_replace(duration, '[^0-9]',''),'')as signed) as duration,
    case when cancellation in ('null','') then null else cancellation end as cancellation
from runner_orders
