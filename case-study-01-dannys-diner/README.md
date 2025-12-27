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

## Bonus Work
Beyond answering the questions, I designed a reusable SQL view to model:
- Member vs non-member purchases
- Correct ranking reset after membership
- NULL rankings for non-member transactions

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
