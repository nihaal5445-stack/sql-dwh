/*
===============================================================================
Date Range Exploration 
===============================================================================
Purpose:
    - To determine the temporal boundaries of key data points.
    - To understand the range of historical data.

SQL Functions Used:
    - MIN(), MAX(), DATEDIFF()
===============================================================================
*/

--first and last order
		SELECT 
		    EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) AS years_span
		FROM gold.fact_sales;

		--youngest and eldest customer
		select
			age(max(birth_date)) as youngest,
			age(min(birth_date)) as oldest
		from gold.dim_customers
