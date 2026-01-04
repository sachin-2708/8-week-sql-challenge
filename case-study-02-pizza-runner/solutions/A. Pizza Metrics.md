## A. Pizza Metrics
------------
# Data Cleaning
- Create a view for customer_orders table which could be used for ready reference.
      - Converting 'null' and '' in exclusions and extras to null.

```sql
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
```
View:

<img width="561" height="327" alt="image" src="https://github.com/user-attachments/assets/e2095508-0f1a-4251-ab32-968fea5622b1" />


- Create a view for runner_orders table
    - Convert 'null' and '' in pickup time to null.
    - Cast pickup_time to datetime, distance to float and duration to signed

```sql
create view vw_runner_orders_clean as
select 
	order_id,
    runner_id,
    cast(case when pickup_time like 'null' then null else pickup_time end as datetime) pickup_time,
    cast(case when distance like 'null' then null else replace(distance, 'km', '') end as float) as distance,
    cast(nullif(regexp_replace(duration, '[^0-9]',''),'')as signed) as duration,
    case when cancellation in ('null','') then null else cancellation end as cancellation
from runner_orders
```
View:

<img width="642" height="245" alt="image" src="https://github.com/user-attachments/assets/c8306cdb-6e57-4e6b-9f91-a600ab76cc2e" />

-----------------------
Q1. How many pizzas were ordered?
Solution:
```sql
select count(*) as pizza_ordered
from vw_customer_orders_clean
```
Output:

<img width="143" height="56" alt="image" src="https://github.com/user-attachments/assets/3c315a7f-ada8-47d3-9e52-ae7250f8cab9" />

-----------------------
Q2. How many unique customer orders were made?
Solution:
```sql
select count(distinct order_id) as unique_customer_orders
from vw_customer_orders_clean
```
Output:

<img width="206" height="52" alt="image" src="https://github.com/user-attachments/assets/86e673ab-b59d-4d36-b1f8-5a7c59076cd1" />

--------------------------
Q3. How many successful orders were delivered by each runner?
Solution:
```sql
select runner_id, count(*) as orders_delivered
from vw_runner_orders_clean
where cancellation is null
group by runner_id
```
Output:

<img width="237" height="97" alt="image" src="https://github.com/user-attachments/assets/13883db3-74fe-4c15-80cd-5195b6d6f217" />

Additionally, if we want to include the runners which have not made any delivery but are registered in the system, we do LEFT JOIN of runners table.
```sql
select r.runner_id, count(o.runner_id) as orders_delivered
from runners r
left join vw_runner_orders_clean o on r.runner_id = o.runner_id
where cancellation is null
group by r.runner_id
```
Output:

<img width="237" height="115" alt="image" src="https://github.com/user-attachments/assets/5be69c6e-6f91-454b-a6bf-f86e7dde2301" />

------------------------------
Q4. How many of each type of pizza was delivered?
Solution:
Using JOIN
```sql
select pizza_name, count(*) as delivered
from vw_customer_orders_clean c
inner join vw_runner_orders_clean r on r.order_id = c.order_id
inner join pizza_names p on p.pizza_id = c.pizza_id
where cancellation is null
group by pizza_name
```
Output:

<img width="202" height="72" alt="image" src="https://github.com/user-attachments/assets/28121a80-1c1d-4ebf-8a3a-90a3ec8e14fd" />

Alternatively, using subquery.
```sql
select p.pizza_name, count(*) as delivered
from vw_customer_orders_clean c
inner join pizza_names p on p.pizza_id = c.pizza_id
where c.order_id in
(select order_id
from vw_runner_orders_clean
where cancellation is null)
group by p.pizza_name
```
Output:

<img width="202" height="72" alt="image" src="https://github.com/user-attachments/assets/5dda82e9-2173-4fff-a814-ba66342702b2" />

--------------------------------
Q5. How many Vegetarian and Meatlovers were ordered by each customer?
Solution:
```sql
select customer_id, 
sum(case when pizza_name = 'Vegetarian' then 1 else 0 end) as Vegetarian,
sum(case when pizza_name = 'Meatlovers' then 1 else 0 end) as Meatlovers
from vw_customer_orders_clean c
left join pizza_names p on p.pizza_id = c.pizza_id
group by customer_id
```
Output:

<img width="307" height="138" alt="image" src="https://github.com/user-attachments/assets/379ef752-f16b-402b-8e32-68491f312245" />

-------------------------------------
Q6. What was the maximum number of pizzas delivered in a single order?
Solution:
```sql
select max(delivered) as max_cnt
from
(select c.order_id, count(*) as delivered
from vw_customer_orders_clean c
left join vw_runner_orders_clean r on r.order_id = c.order_id
where r.cancellation is null
group by order_id)a
```
Output:

<img width="112" height="57" alt="image" src="https://github.com/user-attachments/assets/9f505868-b3f5-41dc-8636-633beccd732e" />

With order_id
```sql
with pizza_orders as
(select c.order_id, count(*) as delivered, rank()over(order by count(*) desc) as rnk
from vw_customer_orders_clean c
left join vw_runner_orders_clean r on r.order_id = c.order_id
where r.cancellation is null
group by order_id)

select order_id, delivered 
from pizza_orders
where rnk = 1
```
Output:

<img width="188" height="58" alt="image" src="https://github.com/user-attachments/assets/af7fbeca-1365-4b93-969e-38b7e2f308cb" />

------------------------------------
Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
Solution:
```sql
select customer_id,
sum(case when exclusions is not null or extras is not null then 1 else 0 end) as has_changes,
sum(case when exclusions is null and extras is null then 1 else 0 end) as no_changes
from vw_customer_orders_clean c
left join vw_runner_orders_clean r on r.order_id = c.order_id
where r.cancellation is null
group by customer_id
```
Output:

<img width="325" height="137" alt="image" src="https://github.com/user-attachments/assets/5406f32b-b36c-48d8-9bf9-9fadbdcf61b6" />

---------------------------------------
Q8. How many pizzas were delivered that had both exclusions and extras?
Solution:
```sql
select count(*) as delivered
from vw_customer_orders_clean c
join vw_runner_orders_clean r on r.order_id = c.order_id
where r.cancellation is null and
c.exclusions is not null and c.extras is not null
```
Output:

<img width="117" height="57" alt="image" src="https://github.com/user-attachments/assets/78e15167-9532-4502-a6ad-c007e5ca3e35" />

--------------------------------------
Q9. What was the total volume of pizzas ordered for each hour of the day?
Solution:
```sql
select hour(order_time) as hr_of_day, count(*) as ordered
from vw_customer_orders_clean
group by hour(order_time)
order by hr_of_day
```
Output:

<img width="188" height="160" alt="image" src="https://github.com/user-attachments/assets/129fd355-913e-40b3-99ba-5633336391bb" />

---------------------------------------
Q10. What was the volume of orders for each day of the week?
Solution:
```sql
select dayname(order_time) as wkday, count(*) as ordered
from vw_customer_orders_clean
group by dayname(order_time)
order by wkday
```
Output:

<img width="200" height="122" alt="image" src="https://github.com/user-attachments/assets/62141fdd-38d7-451a-a4d9-be45e28b288e" />

---------------------------------------
