# Q1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

select week(registration_date) as week_num, count(*) as no_of_runnners_signed
from runners
group by week(registration_date);

# if we consider week start from 2021-01-01 and want the week numbers to be counted from 1 instead of 0, below query works for the same

select floor(datediff(registration_date,'2021-01-01')/7)+1 as week_num, count(*) as no_of_runners_signed
from runners
group by floor(datediff(registration_date,'2021-01-01')/7)+1;

# Q2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

select r1.runner_id, 
round(coalesce(avg(timestampdiff(minute, c.order_time, r.pickup_time)),0)) as avg_time_taken_for_pickup
from runners r1
left join vw_runner_orders_clean r on r1.runner_id = r.runner_id
left join vw_customer_orders_clean c on c.order_id = r.order_id
where r.cancellation is null
group by r1.runner_id

# Q3 Is there any relationship between the number of pizzas and how long the order takes to prepare?

with pizza_prep as
(select c.order_id, timestampdiff(minute,c.order_time, r.pickup_time) as prep_time, count(*) as pizza_cnt
from vw_customer_orders_clean c
join vw_runner_orders_clean r on r.order_id = c.order_id 
where r.cancellation is null
group by c.order_id, timestampdiff(minute,c.order_time, r.pickup_time))

select pizza_cnt, avg(prep_time) as time_taken
from pizza_prep
group by pizza_cnt

## OR

with pizza_prep as
(select c.order_id,
	count(*) as pizza_cnt,
    timestampdiff(minute, min(c.order_time), max(r.pickup_time)) as prep_time
from vw_customer_orders_clean c
join vw_runner_orders_clean r on r.order_id = c.order_id 
where r.cancellation is null
group by c.order_id)

select pizza_cnt, avg(prep_time) as avg_prep_time
from pizza_prep
group by pizza_cnt

# Conclusion: Although more pizza's take more time to prep, there is no direct correlation
# as a few single pizzas are taking longer to prep as well. But 2 pizza's take 6 mins more than 1 pizza.

# Q4 What was the average distance travelled for each customer?

with dist as
(select c.order_id, c.customer_id, max(r.distance) as distance
from vw_customer_orders_clean c
join vw_runner_orders_clean r on r.order_id = c.order_id 
where r.cancellation is null
group by c.order_id, c.customer_id)

select customer_id, avg(distance) as avg_distance
from dist
group by customer_id;

## Wrong approach -- because this fails in customer ID 102 as it has 3 distances but 1st two distances are from the same order.
select c.customer_id, round(avg(distance),2) as avg_dist
from vw_customer_orders_clean c
join vw_runner_orders_clean r on r.order_id = c.order_id 
where r.cancellation is null
group by c.customer_id

# Q5 What was the difference between the longest and shortest delivery times for all orders?

select max(duration) as longest_time, 
		min(duration) as shortest_time,
        max(duration) - min(duration) as diff
from vw_customer_orders_clean c
join vw_runner_orders_clean r on r.order_id = c.order_id 
where r.cancellation is null

# Q6 What was the average speed for each runner for each delivery and do you notice any trend for these values?

select order_id, runner_id, distance as distance_km, duration as duration_min, round((distance*60/duration),1) as speed_kmph,
round(avg(distance*60/duration)over(partition by runner_id),2) as avg_runner_speed
from vw_runner_orders_clean
where cancellation is null
order by runner_id, speed_kmph

-- runner 1 has consistent speed for delivery, runner 2 has variable speed and runner 3 has only 1 delivery

# Q7 What is the successful delivery percentage for each runner?

select r1.runner_id, 
ifnull(round(100.0*sum(case when r.cancellation is null then 1 else 0 end)/count(r.runner_id),2),"no delivery") as delivery_perc
from runners r1
left join vw_runner_orders_clean r on r.runner_id = r1.runner_id
group by runner_id
