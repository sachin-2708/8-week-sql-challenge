## D. Pricing and Ratings

Q1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
how much money has Pizza Runner made so far if there are no delivery fees?
Solution:
```sql
select sum(case when co.pizza_id = 1 then 12
when co.pizza_id = 2 then 10 end) as revenue
from vw_customer_orders_clean co
join vw_runner_orders_clean ro on ro.order_id = co.order_id
where ro.cancellation is null
```
Output:

<img width="118" height="57" alt="image" src="https://github.com/user-attachments/assets/9c74a3ba-7767-4e04-a2e1-8ffa740db298" />

---------------------------------------

Q2. What if there was an additional $1 charge for any pizza extras?
- Add cheese is $1 extra
Solution:
```sql
with recursive base as
(select co.*,
row_number()over(partition by order_id order by order_time, pizza_id) as instance_no
from vw_customer_orders_clean co
join vw_runner_orders_clean ro on ro.order_id = co.order_id
where ro.cancellation is null)
, extras_split as
(select order_id, pizza_id, instance_no,
cast(substring_index(extras,',',1) as unsigned) as topping_id,
trim(substring(extras,length(substring_index(extras,',',1))+2)) as remaining
from base
where extras is not null
union all
select order_id, pizza_id, instance_no,
cast(substring_index(remaining,',',1) as unsigned),
trim(substring(remaining,length(substring_index(remaining,',',1))+2)) 
from extras_split
where remaining <> ''
)

select sum(case when b.pizza_id = 1 then 12 else 10 end) +
count(distinct ex.order_id, ex.pizza_id, ex.instance_no, ex.topping_id) as money_earned -- using distinct to counter the left join of extras_split
from base b
left join extras_split ex on ex.order_id = b.order_id and ex.pizza_id = b.pizza_id and ex.instance_no = b.instance_no
```
Output:

<img width="152" height="55" alt="image" src="https://github.com/user-attachments/assets/b04e317e-c04e-4b0e-a7fb-acfc99177ad5" />

-------------------------------------
Q3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
how would you design an additional table for this new dataset 
- generate a schema for this new table and 
insert your own data for ratings for each successful customer order between 1 to 5.
Solution:
```sql
CREATE TABLE runner_ratings (
  order_id INT,
  runner_id INT,
  rating INT CHECK (rating BETWEEN 1 AND 5)
);
INSERT INTO runner_ratings (order_id, runner_id, rating)
VALUES
(1, 1, 5),
(2, 1, 4),
(3, 1, 3),
(4, 2, 5),
(5, 3, 4),
(7, 2, 2),
(8, 2, 5),
(10, 1, 4);
```
Output:

<img width="247" height="205" alt="image" src="https://github.com/user-attachments/assets/3c9e87a0-9053-4664-8d8f-7409dc5b136f" />

---------------------------------------------
Q4. Using your newly generated table - 
can you join all of the information together to form a table 
which has the following information for successful deliveries?
Solution:
```sql
select co.customer_id, co.order_id, ro.runner_id, rr.rating, co.order_time, ro.pickup_time,
timestampdiff(minute, order_time, pickup_time) as order_to_pickup_mins, duration as delivery_duration,
round(avg(distance/(duration/60)),2) as speed_kmph, count(co.order_id) as pizza_cnt
from vw_customer_orders_clean co
join vw_runner_orders_clean ro on ro.order_id = co.order_id
join runner_ratings rr on rr.order_id = co.order_id
where cancellation is null
group by co.customer_id, co.order_id, ro.runner_id, rr.rating, co.order_time, ro.pickup_time,
timestampdiff(minute, order_time, pickup_time), duration
```
Output:

<img width="1087" height="207" alt="image" src="https://github.com/user-attachments/assets/0df64459-01d6-48f8-9785-4fd85e0cfab3" />

-----------------------------------------
Q5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras 
and each runner is paid $0.30 per kilometre traveled - 
how much money does Pizza Runner have left over after these deliveries?
Solution:
```sql
with pizza_revenue as
(select sum(case when co.pizza_id = 1 then 12
when co.pizza_id = 2 then 10 end) as revenue
from vw_customer_orders_clean co
join vw_runner_orders_clean ro on ro.order_id = co.order_id
where ro.cancellation is null)
, runner_costs as
(select round(sum(distance)*0.3,2) as order_cost
from vw_runner_orders_clean
where cancellation is null)

select revenue, order_cost, round(revenue - order_cost,2) as money_left_over
from pizza_revenue, runner_costs      -- Could have used cross join as well because both CTEs give only 1 row outputs
```
Output:

<img width="332" height="55" alt="image" src="https://github.com/user-attachments/assets/5eeaa5da-f077-4181-a068-78908966bb6e" />

-----------------------------------------
