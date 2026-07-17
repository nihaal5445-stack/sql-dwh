/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

create view gold.customer_report as (
with base_query as (
	select 
		f.order_number,
		f.product_key,
		f.order_date,
		f.sales,
		f.quantity,
		c.customer_key,
		c.customer_number,
		concat(c.first_name,' ',c.last_name) as name,
		extract(year from age(c.birth_date)) as age
	from gold.fact_sales as f
	left join gold.dim_customers as c
	on f.customer_key = c.customer_key
	where order_date is not null
) , customer_aggregation as (
	select 
		customer_key,
		name,
		age,
		count(distinct order_number) as total_orders,
		sum(sales) as total_sales,
		sum(quantity) as total_quantity,
		count(distinct product_key) as total_products,
		max(order_date) as recent_order,
		EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12 
	        + EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS lifeSpan
	from base_query
	group by customer_key, name,age
)

select 
	customer_key,
	name,
	age,
	case when age < 20 then 'Under 20'
		 when age < 30 then '20-30'
		 when age < 40 then '30-40'
		 else '40 above' 
		 end as age_group,
	case when lifeSpan >= 12 and total_sales > 5000 then 'VIP'
		when lifeSpan >= 12 and total_sales <= 5000 then 'Regular'
		else 'new'
		end as customer_segment,
	EXTRACT(YEAR FROM AGE(recent_order)) * 12 
	        + EXTRACT(MONTH FROM AGE(recent_order)) AS recency,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	recent_order
from customer_aggregation
);
