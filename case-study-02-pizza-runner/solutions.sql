# Q1 How many pizzas were ordered?

select count(*) as pizza_ordered
from vw_customer_orders_clean

# Q2 How many unique customer orders were made?

select count(distinct order_id) as unique_customer_orders
from vw_customer_orders_clean

# Q3 How many successful orders were delivered by each runner?

select runner_id, count(*) as orders_delivered
from vw_runner_orders_clean
where cancellation is null
group by runner_id

-- if we want to include ALL runner, even one's who have not delivered any orders then

select r.runner_id, count(o.runner_id) as orders_delivered
from runners r
left join vw_runner_orders_clean o on r.runner_id = o.runner_id
where cancellation is null
group by r.runner_id

# Q4 How many of each type of pizza was delivered?

select pizza_name, count(*) as delivered
from vw_customer_orders_clean c
inner join vw_runner_orders_clean r on r.order_id = c.order_id
inner join pizza_names p on p.pizza_id = c.pizza_id
where cancellation is null
group by pizza_name

-- Using Subquery

select p.pizza_name, count(*) as delivered
from vw_customer_orders_clean c
inner join pizza_names p on p.pizza_id = c.pizza_id
where c.order_id in
(select order_id
from vw_runner_orders_clean
where cancellation is null)
group by p.pizza_name

# Q5 How many Vegetarian and Meatlovers were ordered by each customer?

select customer_id, 
sum(case when pizza_name = 'Vegetarian' then 1 else 0 end) as Vegetarian,
sum(case when pizza_name = 'Meatlovers' then 1 else 0 end) as Meatlovers
from vw_customer_orders_clean c
left join pizza_names p on p.pizza_id = c.pizza_id
group by customer_id

# Q6 What was the maximum number of pizzas delivered in a single order?

select max(delivered) as max_cnt
from
(select c.order_id, count(*) as delivered
from vw_customer_orders_clean c
left join vw_runner_orders_clean r on r.order_id = c.order_id
where r.cancellation is null
group by order_id)a

-- if you also need order_id

with pizza_orders as
(select c.order_id, count(*) as delivered, rank()over(order by count(*) desc) as rnk
from vw_customer_orders_clean c
left join vw_runner_orders_clean r on r.order_id = c.order_id
where r.cancellation is null
group by order_id)

select order_id, delivered 
from pizza_orders
where rnk = 1

# Q7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

select customer_id,
sum(case when exclusions is not null or extras is not null then 1 else 0 end) as has_changes,
sum(case when exclusions is null and extras is null then 1 else 0 end) as no_changes
from vw_customer_orders_clean c
left join vw_runner_orders_clean r on r.order_id = c.order_id
where r.cancellation is null
group by customer_id

# Q8 How many pizzas were delivered that had both exclusions and extras?

select count(*) as delivered
from vw_customer_orders_clean c
join vw_runner_orders_clean r on r.order_id = c.order_id
where r.cancellation is null and
c.exclusions is not null and c.extras is not null

# Q9 What was the total volume of pizzas ordered for each hour of the day?

select hour(order_time) as hr_of_day, count(*) as ordered
from vw_customer_orders_clean
group by hour(order_time)
order by hr_of_day

# Q10 What was the volume of orders for each day of the week?

select dayname(order_time) as wkday, count(*) as ordered
from vw_customer_orders_clean
group by dayname(order_time)
order by wkday
