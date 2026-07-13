/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' schema. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ===============================================================================
-- Checking 'silver.crm_cust_info'
-- ===============================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

select cst_id , count(*) from silver.crm_cust_info
group by cst_id having count(*)>1

-- window func to filter data

truncate table silver.crm_cust_info;
insert into silver.crm_cust_info(
cst_id, cst_key, cst_firstname, cst_lastname,
cst_marital_status, cst_gender, cst_create_date
)
select 
cst_id,
cst_key,
trim(cst_firstname) as cst_firstname,
trim(cst_lastname) as cst_lastname,
case upper(trim(cst_marital_status))
	when 'S' then 'Single'
	when 'M' then 'Married'
	else 'n/a'
end cst_marital_status,
case upper(trim(cst_gender))
	when 'F' then 'Female'
	when 'M' then 'Male'
	else 'n/a'
end cst_gender,
cst_create_date
from (
select 
* ,
row_number() over(partition by cst_id order by cst_create_date desc) as flag
from crm_cust_info
) t
where flag = 1;

--===========================
-- 					crm_product_info
--===========================

--check for duplicates
select * from silver.crm_prd_info;

insert into silver.crm_prd_info(
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)
select 
	prd_id, 
	replace(substring(prd_key, 1, 5), '-', '_') as cat_id,
	substring(prd_key, 7) as prd_key,
	prd_nm,
	coalesce(prd_cost, 0) as prd_cost,
	case upper(trim(prd_line))
		when 'R' then 'Road'
		when 'M' then 'Mountain'
		when 'S' then 'Other Sales'
		when 'T' then 'Touring'
		else 'n/a'
	end as prd_line,
	prd_start_dt,
	lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) - 1 as prd_end_dt
from crm_prd_info

-- duplicate primary key check
select prd_id, count(*)
from crm_prd_info
group by prd_id
having count(*) > 1

-- data standardization and consistency
select distinct prd_cost
from crm_prd_info

--invalid dates
select *
from crm_prd_info
where prd_start_dt > prd_end dt


--==========================
--					crm_sales_details
--==========================

select * from bronze.crm_sales_details

insert into silver.crm_sales_details(
	select 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		case when sls_order_dt <= 0 or length(sls_order_dt::TEXT) != 8 then null
			else cast(cast(sls_order_dt as varchar) as date) 
		end as sls_order_dt,
		
		case when sls_ship_dt <= 0 or length(sls_ship_dt::TEXT) != 8 then null
			else cast(cast(sls_ship_dt as varchar) as date) 
		end as sls_ship_dt,
		
		case when sls_due_dt <= 0 or length(sls_due_dt::TEXT) != 8 then null
			else cast(cast(sls_due_dt as varchar) as date) 
		end as sls_due_dt,
		
		case when sls_sales != sls_quantity*abs(sls_price) or sls_sales <= 0 or sls_sales is null
			then sls_quantity* abs(sls_price)
			else sls_sales
		end as sls_sales,
		sls_quantity,
		case when sls_price <= 0 or sls_price is null
			then sls_sales/nullif(sls_quantity, 0)
			else sls_price
		end as sls_price
	from crm_sales_details
)

-- check duplicate primary key

select sls_ord_num, sls_prd_key, count(*)
from crm_sales_details
group by sls_ord_num, sls_prd_key
having count(*) > 1 ;

-- invalid dates
select * from crm_sales_details
where sls_order_dt <= 0
where sls_ord_num = 'SO67487'

-- invalid date orders
select * from crm_sales_details
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt

-- Data Consistency
------------------
-- >> : sum(sales) = quantity * price
-- >> negative/null/zero values NOT ALLOWED
------------------

select 
case when sls_sales != sls_quantity*abs(sls_price) or sls_sales <= 0 or sls_sales is null
		then sls_quantity* abs(sls_price)
		else sls_sales
end as sls_sales,
sls_quantity,
case when sls_price <= 0 or sls_price is null
		then sls_sales/nullif(sls_quantity, 0)
		else sls_price
end as sls_price
from crm_sales_details
where sls_sales != sls_quantity*sls_price or 
		sls_price <= 0 or sls_quantity <= 0 or sls_sales <= 0


--=======================
-- 						ERP
--=======================

-- erp_cust_az12

select * from erp_cust_az12

insert into silver.erp_cust_az12(
	cid,
	bdate,
	gen
)
select 
	case when cid like 'NAS%' then substring(cid, 4)
	else cid
	end as cid,

	case when bdate > now() then null
	else bdate
	end as bdate,
	
	case when upper(trim(gen)) in ('F', 'FEMALE') then 'Female'
	when upper(trim(gen)) in ('M', 'MALE') then 'Male'
	else 'n/a'
	end as gen
	
from erp_cust_az12

-- invalid dobs
select * 
from silver.erp_cust_az12
where bdate > now() 

--data consistency
select distinct
gen 
from silver.erp_cust_az12


-- erp_loc_a101

select * from erp_loc_a101

insert into silver.erp_loc_a101(
	cid,
	cntry
)
select 
	replace(cid, '-', '') as cid,
	case
		WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'United States', 'USA') THEN 'United States'
        WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'n/a'
        ELSE TRIM(cntry)
	end as cntry

from erp_loc_a101


-- erp_px_cat_g1v2

select * from erp_px_cat_g1v2

insert into silver.erp_px_cat_g1v2(
	id,
	cat,
	subcat,
	maintenance
)

select 
	id,
	cat,
	subcat,
	maintenance
from erp_px_cat_g1v2



