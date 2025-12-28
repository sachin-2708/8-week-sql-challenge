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


How many unique customer orders were made?
How many successful orders were delivered by each runner?
How many of each type of pizza was delivered?
How many Vegetarian and Meatlovers were ordered by each customer?
What was the maximum number of pizzas delivered in a single order?
For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
How many pizzas were delivered that had both exclusions and extras?
What was the total volume of pizzas ordered for each hour of the day?
What was the volume of orders for each day of the week?
