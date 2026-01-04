## C. Ingredient Optimisation
Q1. What are the standard ingredients for each pizza?
Solution:
Used recursive cte to split normalise the pizza_recipes table.
```sql
with recursive topping_split as
-- Step 1: Take the FIRST topping 
(select pizza_id, 
	cast(substring_index(toppings,',',1) as unsigned) as topping,   -- first topping
    substring(toppings, length(substring_index(toppings,',',1))+2) as remaining  -- remaining topping, to be used in the recursive part
from pizza_recipes
UNION ALL
-- Step 2: Keep extracting till nothing is left
select pizza_id,
	cast(substring_index(remaining,',',1) as unsigned) as topping,
    substring(remaining, length(substring_index(remaining,',',1))+2)
    from topping_split
    where remaining <> ''
    )

select pn.pizza_name,
  group_concat(p.topping_name order by p.topping_name separator ', ') as standard_ingredients
from topping_split ts
join pizza_names pn on pn.pizza_id = ts.pizza_id
join pizza_toppings p on p.topping_id = ts.topping
group by ts.pizza_id
```
Output:

<img width="622" height="78" alt="image" src="https://github.com/user-attachments/assets/bfe0b638-8c29-4080-83ec-be0d1fd2e449" />

-------------------------------------
Q2. What was the most commonly added extra?
Solution:
Used recursive CTE to split the extras column in the vw_customer_orders_clean view to normalise the column.
```sql
with recursive extras_split as
(select order_id, 
	cast(substring_index(extras,',',1) as unsigned) as topping_id,
    trim(substring(extras,length(substring_index(extras,',',1))+2)) as remaining
from vw_customer_orders_clean
where extras is not null
union all
select order_id,
cast(substring_index(remaining,',',1) as unsigned),
trim(substring(remaining,length(substring_index(remaining,',',1))+2))
from extras_split
where remaining <> ''
)

select pt.topping_name, count(*) as times_added
from extras_split es
join pizza_toppings pt on pt.topping_id = es.topping_id
group by pt.topping_name
```
Output:

<img width="243" height="101" alt="image" src="https://github.com/user-attachments/assets/81a96e7b-d7ba-46aa-8060-a44bcdb75681" />

----------------------------------------
Q3. What was the most common exclusion?
Solution:
```sql
with recursive exclusions_split as
(select order_id,
	cast(substring_index(exclusions,',',1) as unsigned) as topping_id,
    trim(substring(exclusions,length(substring_index(exclusions,',',1))+2)) as remaining
from vw_customer_orders_clean
where exclusions is not null
union all
select order_id,
	cast(substring_index(remaining,',',1) as unsigned),
    trim(substring(remaining,length(substring_index(remaining,',',1))+2))
from exclusions_split
where remaining <>'')

select ps.topping_name, count(*) as times_excluded
from exclusions_split es
join pizza_toppings ps on ps.topping_id = es.topping_id
group by ps.topping_name
order by times_excluded desc
```
Output:

<img width="261" height="98" alt="image" src="https://github.com/user-attachments/assets/5dd4089e-52df-4ae0-a4f8-25d3744bd1d1" />

---------------------------------------------------

Q4. Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
Solution:
```sql
with recursive base as
(select *,
	row_number()over(partition by order_id order by order_time,pizza_id) as instance_no    -- create base cte with row_number to have orders ranked
from vw_customer_orders_clean
)
, exclusions_split as   -- split exclusions from base table for normalising the data
(select order_id, pizza_id, instance_no,
cast(substring_index(exclusions,',',1) as unsigned) as topping_id,
trim(substring(exclusions, length(substring_index(exclusions,',',1))+2)) as remaining
from base
where exclusions is not null
union all
select order_id, pizza_id, instance_no,
cast(substring_index(remaining,',',1) as unsigned),
trim(substring(remaining, length(substring_index(remaining,',',1))+2))
from exclusions_split
where remaining <> ''
)
, extras_split as     -- split extras from base table for normalising the data
(select order_id, pizza_id, instance_no,
cast(substring_index(extras,',',1) as unsigned) as topping_id,
trim(substring(extras, length(substring_index(extras,',',1))+2)) as remaining
from base
where extras is not null
union all
select order_id, pizza_id, instance_no,
cast(substring_index(remaining,',',1) as unsigned),
trim(substring(remaining, length(substring_index(remaining,',',1))+2))
from extras_split
where remaining <> ''
)
, extra_named as     -- name the extras in order the join the table later
(select ex.order_id, ex.pizza_id, ex.instance_no,
group_concat(distinct pt.topping_name order by pt.topping_name) as extra_toppings
from extras_split ex
join pizza_toppings pt on pt.topping_id = ex.topping_id
group by ex.order_id, ex.pizza_id, ex.instance_no)
, exclusions_named as    -- name the exclusions in order the join the table later
(select en.order_id, en.pizza_id, en.instance_no,
group_concat(distinct pt.topping_name order by pt.topping_name) as exclusion_toppings
from exclusions_split en
join pizza_toppings pt on pt.topping_id = en.topping_id
group by en.order_id, en.pizza_id, en.instance_no
)

select c.order_id, c.customer_id,
concat(p.pizza_name,
	if(en.exclusion_toppings is not null, concat(' - Exclude ',en.exclusion_toppings),''),
    if(ex.extra_toppings is not null, concat(' - Extra ',ex.extra_toppings),'')
    ) as order_item
from base c
join pizza_names p on p.pizza_id = c.pizza_id
left join exclusions_named en on en.order_id = c.order_id and en.pizza_id = c.pizza_id and en.instance_no = c.instance_no
left join extra_named ex on ex.order_id = c.order_id and ex.pizza_id = c.pizza_id and ex.instance_no = c.instance_no
order by c.order_id,c.pizza_id, c.instance_no
```
Output:

<img width="717" height="336" alt="image" src="https://github.com/user-attachments/assets/1a143218-6edc-4958-af0f-fe0a6de80270" />

---------------------------------------
Q5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
Solution:
```sql
with recursive base as
(select *,
	row_number()over(partition by order_id order by order_time,pizza_id) as instance_no
from vw_customer_orders_clean)
, recipe_split as
(select c.order_id, c.pizza_id, c.instance_no,
cast(substring_index(pr.toppings,',',1) as unsigned) as topping_id,
trim(substring(pr.toppings, length(substring_index(pr.toppings,',',1))+2)) as remaining
from base c
join pizza_recipes pr on pr.pizza_id = c.pizza_id
union all
select order_id, pizza_id, instance_no,
cast(substring_index(remaining,',',1) as unsigned),
trim(substring(remaining,length(substring_index(remaining,',',1))+2))
from recipe_split
where remaining <> ''
),
 exclusions_split as
(select order_id, pizza_id, instance_no,
cast(substring_index(exclusions,',',1) as unsigned) as topping_id,
trim(substring(exclusions, length(substring_index(exclusions,',',1))+2)) as remaining
from base
where exclusions is not null
union all
select order_id, pizza_id, instance_no,
cast(substring_index(remaining,',',1) as unsigned),
trim(substring(remaining, length(substring_index(remaining,',',1))+2))
from exclusions_split
where remaining <> ''
)
, extras_split as
(select order_id, pizza_id, instance_no,
cast(substring_index(extras,',',1) as unsigned) as topping_id,
trim(substring(extras, length(substring_index(extras,',',1))+2)) as remaining
from base
where extras is not null
union all
select order_id, pizza_id, instance_no,
cast(substring_index(remaining,',',1) as unsigned),
trim(substring(remaining, length(substring_index(remaining,',',1))+2))
from extras_split
where remaining <> ''
)
, ingredients_after_exclusion as
(select rs.order_id, rs.pizza_id, rs.instance_no, rs.topping_id
from recipe_split rs
left join exclusions_split es on
es.order_id = rs.order_id and es.pizza_id = rs.pizza_id and es.instance_no = rs.instance_no and es.topping_id = rs.topping_id
where es.topping_id is null)
, all_ingredients as
(select * from ingredients_after_exclusion
union all
select order_id, pizza_id, instance_no, topping_id
from extras_split)
, ingredient_cnt as
(select ai.order_id, ai.pizza_id, ai.instance_no, pt.topping_name, count(*) as qty
from all_ingredients ai
join pizza_toppings pt on pt.topping_id = ai.topping_id
group by ai.order_id, ai.pizza_id, ai.instance_no, pt.topping_name)

select b.order_id,
concat(pn.pizza_name, ':', 
group_concat(
	case when ic.qty > 1 then concat(ic.qty, 'x', ic.topping_name)
    else ic.topping_name end order by ic.topping_name
    separator ', ')) as ingredient_list
from base b
join ingredient_cnt ic on ic.order_id = b.order_id and ic.pizza_id = b.pizza_id
and ic.instance_no = b.instance_no
join pizza_names pn on pn.pizza_id = b.pizza_id
group by b.order_id, b.pizza_id, b.instance_no, pn.pizza_name
order by b.order_id, b.pizza_id
```
Output:

<img width="727" height="332" alt="image" src="https://github.com/user-attachments/assets/66f70439-9687-412f-a70a-89629ac15be3" />

---------------------------------------------
Q6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
Solution:
```sql
with recursive base as
(select co.*,
	row_number()over(partition by co.order_id order by co.order_time,co.pizza_id) as instance_no
from vw_customer_orders_clean co
join vw_runner_orders_clean ro on ro.order_id = co.order_id
where ro.cancellation is null)
, recipe_split as
(select c.order_id, c.pizza_id, c.instance_no,
cast(substring_index(pr.toppings,',',1) as unsigned) as topping_id,
trim(substring(pr.toppings, length(substring_index(pr.toppings,',',1))+2)) as remaining
from base c
join pizza_recipes pr on pr.pizza_id = c.pizza_id
union all
select order_id, pizza_id, instance_no,
cast(substring_index(remaining,',',1) as unsigned),
trim(substring(remaining,length(substring_index(remaining,',',1))+2))
from recipe_split
where remaining <> ''
),
 exclusions_split as
(select order_id, pizza_id, instance_no,
cast(substring_index(exclusions,',',1) as unsigned) as topping_id,
trim(substring(exclusions, length(substring_index(exclusions,',',1))+2)) as remaining
from base
where exclusions is not null
union all
select order_id, pizza_id, instance_no,
cast(substring_index(remaining,',',1) as unsigned),
trim(substring(remaining, length(substring_index(remaining,',',1))+2))
from exclusions_split
where remaining <> ''
)
, extras_split as
(select order_id, pizza_id, instance_no,
cast(substring_index(extras,',',1) as unsigned) as topping_id,
trim(substring(extras, length(substring_index(extras,',',1))+2)) as remaining
from base
where extras is not null
union all
select order_id, pizza_id, instance_no,
cast(substring_index(remaining,',',1) as unsigned),
trim(substring(remaining, length(substring_index(remaining,',',1))+2))
from extras_split
where remaining <> ''
)
, ingredients_after_exclusion as
(select rs.order_id, rs.pizza_id, rs.instance_no, rs.topping_id
from recipe_split rs
left join exclusions_split es on
es.order_id = rs.order_id and es.pizza_id = rs.pizza_id and es.instance_no = rs.instance_no and es.topping_id = rs.topping_id
where es.topping_id is null)
, all_ingredients as
(select * from ingredients_after_exclusion
union all
select order_id, pizza_id, instance_no, topping_id
from extras_split)
, ingredient_cnt as
(select ai.order_id, ai.pizza_id, ai.instance_no, pt.topping_name, count(*) as qty
from all_ingredients ai
join pizza_toppings pt on pt.topping_id = ai.topping_id
group by ai.order_id, ai.pizza_id, ai.instance_no, pt.topping_name)

select pt.topping_name, count(*) as topping_qty
from all_ingredients ai
join pizza_toppings pt on ai.topping_id = pt.topping_id
group by pt.topping_name
order by topping_qty desc
```
Output:

<img width="236" height="290" alt="image" src="https://github.com/user-attachments/assets/b329f1be-9b59-4d0f-9dd6-418fb682bbc7" />
