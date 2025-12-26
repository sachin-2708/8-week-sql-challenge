# What is the total amount each customer spent at the restaurant?

select s.customer_id, sum(m.price) as total_spent
from sales s
join menu m on m.product_id = s.product_id
group by s.customer_id

# How many days has each customer visited the restaurant?

select customer_id, count(distinct order_date) as visted_days
from sales
group by customer_id

# What was the first item from the menu purchased by each customer?
with first_order as
(select customer_id, min(order_date) f_order 
from sales
group by customer_id)

select distinct s.customer_id, m.product_name
from sales s
join first_order f on f.customer_id = s.customer_id and s.order_date = f.f_order
join menu m on m.product_id = s.product_id

# OR (correlations subquery approach)

select distinct s1.customer_id, m.product_name
from sales s1
join menu m on s1.product_id = m.product_id
where order_date = 
(select min(s2.order_date)
from sales s2
where s1.customer_id = s2.customer_id)

# What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name, count(*) as total_orders
from sales s
join menu m on m.product_id = s.product_id
group by m.product_name
order by total_orders desc
limit 1
# OR (more dependable)
with ranked as
(select m.product_name, count(*) as total_orders,
rank()over(order by count(*) desc) as rnk
from sales s
join menu m on m.product_id = s.product_id
group by m.product_name)
select product_name, total_orders
from ranked
where rnk = 1
order by product_name

# Which item was the most popular for each customer?
with ranked as
(select s.customer_id, m.product_name, count(*) as total_orders,
rank()over(partition by s.customer_id order by count(*) desc) as rnk
from sales s
join menu m on m.product_id = s.product_id
group by s.customer_id, m.product_name)

select customer_id, product_name, total_orders
from ranked
where rnk = 1

# Which item was purchased first by the customer after they became a member

select customer_id, product_name
from
(select s.customer_id, mu.product_name, rank()over(partition by customer_id order by order_date) as rnk
from sales s
join members m on m.customer_id = s.customer_id and order_date >= m.join_date
join menu mu on mu.product_id = s.product_id)r
where rnk = 1

# OR (Lenghty, but using MIN function)

with first_order as
(select s.customer_id, min(order_date) as f_order
from sales s
join members m on m.customer_id = s.customer_id and order_date >= m.join_date
group by s.customer_id)

select fo.customer_id, mu.product_name
from first_order fo 
join sales s on s.customer_id = fo.customer_id 
join menu mu on mu.product_id = s.product_id
where s.order_date = fo.f_order
order by customer_id

# Which item was purchased just before the customer became a member?

select customer_id, product_name
from
(select s.customer_id, mu.product_name,
rank()over(partition by customer_id order by order_date desc) as rnk
from sales s
join members m on m.customer_id = s.customer_id and s.order_date < m.join_date
join menu mu on mu.product_id = s.product_id)t
where rnk = 1

OR

with before_member as
(select s.customer_id, max(order_date) as before_join
from sales s
join members m on s.customer_id = m.customer_id and s.order_date < m.join_date
group by s.customer_id)

select bm.customer_id, mu.product_name
from before_member bm
join sales s2 on s2.customer_id = bm.customer_id and s2.order_date = bm.before_join
join menu mu on mu.product_id = s2.product_id
order by customer_id


# What is the total items and amount spent for each member before they became a member?

select s.customer_id, count(*) as total_items, sum(mu.price) as amount_spent
from sales s
join members m on m.customer_id = s.customer_id and s.order_date < m.join_date
join menu mu on mu.product_id = s.product_id
group by customer_id
order by customer_id

/* If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
how many points would each customer have? */

select s.customer_id, 
sum(case when m.product_name = "sushi" then 2*price*10 else price*10 end) as points
from sales s
join menu m on s.product_id = m.product_id
group by s.customer_id

/*
In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?
*/
with cte as
(select s.customer_id, mu.product_name, s.order_date, mu.price, m.join_date, date_add(m.join_date, interval 6 day) as first_week_end
from sales s
join members m on m.customer_id = s.customer_id
join menu mu on mu.product_id = s.product_id)

select customer_id,
sum(case when order_date between join_date and first_week_end then 2*price*10
when product_name = 'sushi' then 2*price*10
else price*10 end) as points
 from cte
 where year(order_date) = 2021 and month(order_date) =1
 group by customer_id
 order by customer_id

## if sushi get 4x during first week after joining then the query changes slightly

with base as
(select s.customer_id, mu.product_name, s.order_date, mu.price, m.join_date, date_add(m.join_date, interval 6 day) as first_week_end, 
case when mu.product_name = 'sushi' then 2*price*10 else price*10 end as points
from sales s
join members m on m.customer_id = s.customer_id
join menu mu on mu.product_id = s.product_id)

select customer_id, 
sum(case when order_date between join_date and first_week_end then points*2 else points end) as new_points
from base
where order_date < '2025-02-01'
group by customer_id
order by customer_id
