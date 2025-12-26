# creating a view for ready reference
create view vw_customer_order_ranking as 
select customer_id, order_date, product_name, price, member,
case when member = 'Y' then rank()over(partition by customer_id, member order by order_date) else null end as ranking
from
(select s.customer_id, s.order_date, mu.product_name, mu.price, 
case when s.order_date >= m.join_date then 'Y' else 'N' end as member
from sales s
join menu mu on mu.product_id = s.product_id
left join members m on s.customer_id = m.customer_id) membership


select * from vw_customer_order_ranking
