/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/


create view gold.product_report as (
with base_query as (
select
	f.product_key,
	p.product_name,
	p.category,
	p.sub_category,
	p.cost,
	f.order_number,
	f.order_date,
	f.sales,
	f.quantity,
	f.customer_key
	
	from gold.fact_sales as f
	left join gold.dim_products as p
	on f.product_key = p.product_key
	where order_date is not null
) , product_aggregation as (
	select 
		product_key,
		product_name,
		category,
		sub_category,
		cost,
		count(distinct order_number) as total_order,
		sum(sales) as total_sales,
		sum(quantity) as total_quantity,
		count(distinct customer_key) as total_customers,
		max(order_date) as recent_order,
		EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12 
	        + EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS lifeSpan
	from base_query
	group by product_key,
			product_name,
			category,
			sub_category,
			cost
)

	select 
		product_key,
		product_name,
		category,
		sub_category,
		cost,
		recent_order,
		case when total_sales > 50000 then 'High-Performer'
		when total_sales >= 10000 then 'Mid'
		else 'Low'
		end as product_segment
	from product_aggregation
);
