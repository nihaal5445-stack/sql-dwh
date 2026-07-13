create or replace procedure load_bronze()
language plpgsql
as $$
	begin 
	RAISE NOTICE '==========================================='
	RAISE NOTICE 'Loading Bronze Layer'
	RAISE NOTICE '==========================================='
	
	truncate table bronze.crm_cust_info;
	COPY bronze.crm_cust_info(cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gender, cst_create_date)
	FROM '/Users/nihal/Downloads/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
	WITH (FORMAT csv, DELIMITER ',', QUOTE '"', HEADER true);
	RAISE NOTICE 'Loaded crm_cust_info successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Failed to load crm_cust_info: %', SQLERRM;
    END;
	
	truncate table bronze.crm_sales_details;
	COPY bronze.crm_sales_details(sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
	FROM '/Users/nihal/Downloads/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
	WITH (FORMAT csv, DELIMITER ',', QUOTE '"', HEADER true);
	RAISE NOTICE 'Loaded crm_sales_details successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Failed to load crm_sales_details: %', SQLERRM;
    END;
	
	truncate table bronze.crm_prd_info;
	COPY bronze.crm_prd_info(prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
	FROM '/Users/nihal/Downloads/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
	WITH (FORMAT csv, DELIMITER ',', QUOTE '"', HEADER true);
	RAISE NOTICE 'Loaded crm_prd_info successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Failed to load crm_prd_info: %', SQLERRM;
    END;
	
	truncate table bronze.erp_loc_a101;
	COPY bronze.erp_loc_a101(cid, cntry)
	FROM '/Users/nihal/Downloads/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv'
	WITH (FORMAT csv, DELIMITER ',', QUOTE '"', HEADER true);
	RAISE NOTICE 'Loaded erp_loc_a101 successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Failed to load erp_loc_a101: %', SQLERRM;
    END;
	
	truncate table bronze.erp_cust_az12;
	COPY bronze.erp_cust_az12(cid, bdate, gen)
	FROM '/Users/nihal/Downloads/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
	WITH (FORMAT csv, DELIMITER ',', QUOTE '"', HEADER true);
	RAISE NOTICE 'Loaded erp_cust_az12 successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Failed to load erp_cust_az12: %', SQLERRM;
    END;
	
	truncate table bronze.erp_px_cat_g1v2;
	COPY bronze.erp_px_cat_g1v2(id, cat, subcat, maintenance)
	FROM '/Users/nihal/Downloads/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
	WITH (FORMAT csv, DELIMITER ',', QUOTE '"', HEADER true);
	RAISE NOTICE 'Loaded erp_px_cat_g1v2 successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Failed to load erp_px_cat_g1v2: %', SQLERRM;
    END;
	
end;
$$;

call load_bronze();
