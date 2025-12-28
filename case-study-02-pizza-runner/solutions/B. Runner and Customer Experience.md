## B. Runner and Customer Experience


Q1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
Solution:
```sql
select week(registration_date) as week_num, count(*) as no_of_runnners_signed
from runners
group by week(registration_date);
```
Output:

<img width="286" height="96" alt="image" src="https://github.com/user-attachments/assets/c2de0e1f-c02f-45dc-8f3e-d4077ec28178" />

If we consider week start from 2021-01-01 and want the week numbers to be counted from 1 instead of 0, below query works:
```sql
select floor(datediff(registration_date,'2021-01-01')/7)+1 as week_num, count(*) as no_of_runners_signed
from runners
group by floor(datediff(registration_date,'2021-01-01')/7)+1;
```
Output:

<img width="280" height="97" alt="image" src="https://github.com/user-attachments/assets/f0b6703e-750f-4f75-a49d-28a3ea69292a" />

-------------------------------------
Q2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
Solution:
```sql
select r1.runner_id, 
round(coalesce(avg(timestampdiff(minute, c.order_time, r.pickup_time)),0)) as avg_time_taken_for_pickup
from runners r1
left join vw_runner_orders_clean r on r1.runner_id = r.runner_id
left join vw_customer_orders_clean c on c.order_id = r.order_id
where r.cancellation is null
group by r1.runner_id
```
Output:

<img width="308" height="122" alt="image" src="https://github.com/user-attachments/assets/d0f6b3b9-fc70-4a6a-9fa7-23cf2662674f" />

----------------------------------------
Q3 Is there any relationship between the number of pizzas and how long the order takes to prepare?
Solution:
```sql
with pizza_prep as
(select c.order_id, timestampdiff(minute,c.order_time, r.pickup_time) as prep_time, count(*) as pizza_cnt
from vw_customer_orders_clean c
join vw_runner_orders_clean r on r.order_id = c.order_id 
where r.cancellation is null
group by c.order_id, timestampdiff(minute,c.order_time, r.pickup_time))

select pizza_cnt, avg(prep_time) as time_taken
from pizza_prep
group by pizza_cnt
```
OR, a more better approach is to use Min(order_date) and Max(pickup_date) to avoid the multiple rows in customer_orders table.
```sql
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
```
Output:

<img width="227" height="96" alt="image" src="https://github.com/user-attachments/assets/2a109142-83b6-4afd-9a33-896d1aac2a9d" />

Conclusion: Although more pizzas take more time to prep, there is no direct correlation as a few single pizzas are taking longer to prep as well. But 2 pizza's take 6 mins more than 1 pizza.

-------------------------------------
Q4 What was the average distance travelled for each customer?
What was the difference between the longest and shortest delivery times for all orders?
What was the average speed for each runner for each delivery and do you notice any trend for these values?
What is the successful delivery percentage for each runner?



