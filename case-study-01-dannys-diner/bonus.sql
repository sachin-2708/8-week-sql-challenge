
# Bonus question 1 to create a new table which could be used on the go

select s.customer_id, s.order_date, mu.product_name, mu.price, 
case when s.order_date >= m.join_date then 'Y' else 'N' end as member
from sales s
join menu mu on mu.product_id = s.product_id
left join members m on s.customer_id = m.customer_id
order by customer_id, order_date, product_name 


# Bonus question 2 ranking products only after membership
with membership as
(select s.customer_id, s.order_date, mu.product_name, mu.price, 
case when s.order_date >= m.join_date then 'Y' else 'N' end as member
from sales s
join menu mu on mu.product_id = s.product_id
left join members m on s.customer_id = m.customer_id
order by customer_id, order_date, product_name)

select *,
case when member = 'Y' then rank()over(partition by customer_id, member order by order_date) else null end as ranking
from membership
