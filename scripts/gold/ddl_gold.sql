
--======================================
--                                 dim_customers
--======================================

create or replace view gold.dim_customers as
	select 
		row_number() over(order by ci.cst_id) customer_key,
		ci.cst_id as customer_id,
		ci.cst_key as customer_number,
		ci.cst_firstname as first_name,
		ci.cst_lastname as last_name,
		la.cntry as country,
		ci.cst_marital_status as marital_status,
		case ci.cst_gender 
		when 'n/a' then coalesce(ca.gen, 'n/a')
		else ci.cst_gender 
		end as gender,
		ca.bdate as birth_date,
		ci.cst_create_date as create_date
		
	from silver.crm_cust_info as ci
	left join silver.erp_cust_az12 ca
	on 		  ci.cst_key = ca.cid
	left join silver.erp_loc_a101 la
	on 		  ci.cst_key = la.cid;

--======================================
--                                   dim_products
--======================================

create or replace view gold.dim_products as
	select 
		row_number() over(order by pn.prd_start_dt ,pn.prd_key) as product_key,
		pn.prd_id as product_id,
		pn.prd_key as product_number,
		pn.prd_nm as product_name,
		pn.cat_id as category_id,
		pc.cat as category,
		pc.subcat as sub_category,
		pc.maintenance as maintenance,
		pn.prd_cost as cost,
		pn.prd_line as product_line,
		pn.prd_start_dt as start_date
	from silver.crm_prd_info as pn
	left join silver.erp_px_cat_g1v2 as pc
	on 		  pn.cat_id = pc.id
	where pn.prd_end_dt is null;

--======================================
--                                   fact_sales
--======================================

create or replace view gold.fact_sales as
select 
	sls_ord_num as order_number,
	pn.product_key,
	cu.customer_key,
	sls_order_dt as order_date,
	sls_ship_dt as ship_date,
	sls_due_dt as due_date,
	sls_sales as sales,
	sls_quantity as quantity,
	sls_price as price
from silver.crm_sales_details sd
left join gold.dim_customers cu
on sd.sls_cust_id = cu.customer_id
left join gold.dim_products pn
on sd.sls_prd_key = pn.product_number
