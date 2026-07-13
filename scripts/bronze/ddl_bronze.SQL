create schema bronze;
create schema silver;
create schema gold;

set search_path to bronze;


	DROP TABLE IF EXISTS crm_cust_info CASCADE;
	create table crm_cust_info (
		cst_id int,
		cst_key varchar(50),
		cst_firstname varchar(50),
		cst_lastname varchar(50),
		cst_marital_status varchar(50),
		cst_gender varchar(50),
		cst_create_date date
	);
	
	DROP TABLE IF EXISTS crm_prd_info CASCADE;
	create table crm_prd_info(
		prd_id int,
		prd_key varchar(50),
		prd_nm varchar(50),
		prd_cost int,
		prd_line varchar(50),
		prd_start_dt date,
		prd_end_dt date
	);
	
	DROP TABLE IF EXISTS crm_sales_details CASCADE;
	create table crm_sales_details(
		sls_ord_num varchar(50),
		sls_prd_key varchar(50),
		sls_cust_id int,
		sls_order_dt int,
		sls_ship_dt int,
		sls_due_dt int,
		sls_sales int,
		sls_quantity int,
		sls_price int
	);
	
	
	create table erp_loc_a101(
		cid varchar(50),
		cntry varchar(50)
	);
	
	create table erp_cust_az12(
		CID varchar(50),
		BDATE date,
		GEN varchar(50)
	);
	
	create table erp_px_cat_g1v2(
		id  varchar(50),
		cat  varchar(50),
		subcat  varchar(50),
		maintenance  varchar(50)
	);



