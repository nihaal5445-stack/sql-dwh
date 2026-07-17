/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: DATEPART(), DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(), AVG()
===============================================================================
*/

-- Analyse sales performance over time

--Sales Performance Over Time
select
	Extract(year from order_date) as Year,
	count(distinct customer_key) as Total_customers,
	sum(quantity) as Total_quantity,
	sum(sales)
from gold.fact_sales
where order_date is not null
group by Year
order by Year

