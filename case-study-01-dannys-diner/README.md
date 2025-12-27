# Case Study 1 – Danny’s Diner
<img width="1080" height="1080" alt="1" src="https://github.com/user-attachments/assets/aef241d7-1dc2-4162-8a48-e9d5f27c62cd" />


## Overview
This case study analyzes customer purchasing behavior and the impact of a
loyalty program using transactional sales data.

## Tables Used
- sales
- menu
- members

## Entity Relationship Diagram
<img width="900" height="437" alt="erd-cs-1" src="https://github.com/user-attachments/assets/bde663d9-18f8-46b8-9333-4733dfd37ede" />

## Key Concepts Practiced
- Customer-level aggregation
- Window functions for ranking
- Membership-based logic
- Points calculation with conditional rules

## Case Study Questions & Solutions
Q1. What is the total amount each customer spent at the restaurant?
Solution:
```sql
select s.customer_id, sum(m.price) as total_spent
from sales s
join menu m on m.product_id = s.product_id
group by s.customer_id
```
Output:

<img width="220" height="112" alt="image" src="https://github.com/user-attachments/assets/8f07d575-6536-4bae-b621-47bf5033dbff" />

------------------------------------------------------------------------------
Q2. How many days has each customer visited the restaurant?
Solution:
```sql
select customer_id, count(distinct order_date) as visted_days
from sales
group by customer_id
```
Output:

<img width="220" height="110" alt="image" src="https://github.com/user-attachments/assets/5a61ad8a-59e2-4ae0-b920-71421370d194" />

------------------------------------------------------------------------------
Q3. What was the first item from the menu purchased by each customer?
Solution:
```sql
with first_order as
(select customer_id, min(order_date) f_order 
from sales
group by customer_id)

select distinct s.customer_id, m.product_name, s.order_date
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
```
Output:

<img width="330" height="115" alt="image" src="https://github.com/user-attachments/assets/b3092fab-9d91-472d-84c8-939857fc6bf8" />

-------------------------------------------------------------------
Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?
Solution:
``` sql
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
```
Output:

<img width="240" height="57" alt="image" src="https://github.com/user-attachments/assets/e727ee32-2ec0-49cf-af13-46eb4b5e0fca" />

-------------------------------------------------------------------
Q5. Which item was the most popular for each customer?
Solution:
```sql
with ranked as
(select s.customer_id, m.product_name, count(*) as total_orders,
rank()over(partition by s.customer_id order by count(*) desc) as rnk
from sales s
join menu m on m.product_id = s.product_id
group by s.customer_id, m.product_name)

select customer_id, product_name, total_orders
from ranked
where rnk = 1
```
Output:

<img width="337" height="146" alt="image" src="https://github.com/user-attachments/assets/de3a194e-dd1d-45e9-ad1b-d167d5e033d3" />

-------------------------------------------------------------------------------------
Q6. Which item was purchased first by the customer after they became a member?
Solution:
```sql
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
```
Output:

<img width="236" height="80" alt="image" src="https://github.com/user-attachments/assets/2abbed3c-63ed-48c8-b6e1-d1e121d5e77f" />

------------------------------------------------------------------------

Q7. Which item was purchased just before the customer became a member?
Solution:
```sql
select customer_id, product_name
from
(select s.customer_id, mu.product_name,
rank()over(partition by customer_id order by order_date desc) as rnk
from sales s
join members m on m.customer_id = s.customer_id and s.order_date < m.join_date
join menu mu on mu.product_id = s.product_id)t
where rnk = 1

# OR

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
```
Output:

<img width="240" height="98" alt="image" src="https://github.com/user-attachments/assets/266e03df-98e2-4206-ad54-96ebd5f11d43" />

-------------------------------------------------------------------------------
Q8. What is the total items and amount spent for each member before they became a member?
Solution:
```sql
select s.customer_id, count(*) as total_items, sum(mu.price) as amount_spent
from sales s
join members m on m.customer_id = s.customer_id and s.order_date < m.join_date
join menu mu on mu.product_id = s.product_id
group by customer_id
order by customer_id
```
Output:

<img width="326" height="77" alt="image" src="https://github.com/user-attachments/assets/df20d78b-f35c-40c9-8c1e-8f562a06fbfb" />

--------------------------------------------------------------------------------
Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
Solution:
```sql
select s.customer_id, 
sum(case when m.product_name = "sushi" then 2*price*10 else price*10 end) as points
from sales s
join menu m on s.product_id = m.product_id
group by s.customer_id
```
Output:

<img width="200" height="102" alt="image" src="https://github.com/user-attachments/assets/c26f32bf-b481-4652-bd6a-bf5543a583e8" />

---------------------------------------------------------------------------------
Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
Solution:
```sql
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
```
Output:

<img width="202" height="77" alt="image" src="https://github.com/user-attachments/assets/2423464e-4b5f-4733-884d-2dd4c1ba3a2e" />

Additionally if sushi get 4x during first week after joining then the query changes slightly
```sql
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
```
Output:

<img width="223" height="82" alt="image" src="https://github.com/user-attachments/assets/6a6df8c6-7a7e-408d-83b1-f300f8c48d64" />

---------------------------------------------------------------------------

## Bonus Work
Beyond answering the questions, I designed a reusable SQL view to model:
- Member vs non-member purchases
- Correct ranking reset after membership
- NULL rankings for non-member transactions

Danny wanted to join all things and recreate the following table:
| customer_id | order_date | product_name | price | member |
|------------|------------|--------------|-------|--------|
| A | 2021-01-01 | curry | 15 | N |
| A | 2021-01-01 | sushi | 10 | N |
| A | 2021-01-07 | curry | 15 | Y |
| A | 2021-01-10 | ramen | 12 | Y |
| A | 2021-01-11 | ramen | 12 | Y |
| A | 2021-01-11 | ramen | 12 | Y |
| B | 2021-01-01 | curry | 15 | N |
| B | 2021-01-02 | curry | 15 | N |
| B | 2021-01-04 | sushi | 10 | N |
| B | 2021-01-11 | sushi | 10 | Y |
| B | 2021-01-16 | ramen | 12 | Y |
| B | 2021-02-01 | ramen | 12 | Y |
| C | 2021-01-01 | ramen | 12 | N |
| C | 2021-01-01 | ramen | 12 | N |
| C | 2021-01-07 | ramen | 12 | N |

## Edge Cases Considered
- Multiple purchases on the same date
- Window function evaluation order
- Ranking reset logic
- Membership boundary conditions
- MySQL limitation: CTEs not allowed in views

## Files
- schema.sql – table creation & inserts
- solutions.sql – core questions
- bonus.sql – bonus questions
- views.sql – reusable analytics view
