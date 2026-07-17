/*
===============================================================================
Performance Analysis (Year-over-Year, Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
===============================================================================
*/


--Analysis the annual variation of products by comparing 
--each product's sales to both its average sales performance and 
-- the previous year sales

WITH yearly_product_sales AS (
    SELECT
        EXTRACT(YEAR FROM f.order_date) AS order_year,
        d.product_name AS product_name,
        SUM(f.sales) AS curr_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS d
        ON f.product_key = d.product_key
    GROUP BY order_year, product_name
),
with_avg AS (
    SELECT
        order_year,
        product_name,
        curr_sales,
        ROUND(AVG(curr_sales) OVER (PARTITION BY product_name), 2) AS average_sales
    FROM yearly_product_sales
)
SELECT 
    order_year,
    product_name,
    curr_sales,
    average_sales,
    CASE 
        WHEN curr_sales - average_sales < 0 THEN 'Below avg'
        ELSE 'Above avg'
    END AS avg_change,
	lag(curr_sales) over(partition by product_name order by order_year) as prev_sales
FROM with_avg
ORDER BY product_name, order_year;
