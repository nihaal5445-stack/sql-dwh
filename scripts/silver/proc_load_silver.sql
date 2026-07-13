CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    v_sttime       TIMESTAMP;
    v_endtime      TIMESTAMP;
    v_totsttime    TIMESTAMP;
    v_totendtime   TIMESTAMP;
BEGIN
    v_totsttime := clock_timestamp();

    -- ===========================
    -- crm_cust_info
    -- ===========================
    v_sttime := clock_timestamp();
    RAISE NOTICE '>> Loading crm_cust_info';

    RAISE NOTICE '>> Truncating table: silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;

    RAISE NOTICE '>> Inserting into table: silver.crm_cust_info';
    INSERT INTO silver.crm_cust_info(
        cst_id, cst_key, cst_firstname, cst_lastname,
        cst_marital_status, cst_gender, cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE UPPER(TRIM(cst_marital_status))
            WHEN 'S' THEN 'Single'
            WHEN 'M' THEN 'Married'
            ELSE 'n/a'
        END,
        CASE UPPER(TRIM(cst_gender))
            WHEN 'F' THEN 'Female'
            WHEN 'M' THEN 'Male'
            ELSE 'n/a'
        END,
        cst_create_date
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag
        FROM bronze.crm_cust_info
    ) t
    WHERE flag = 1;

    v_endtime := clock_timestamp();
    RAISE NOTICE '>> Load duration: % seconds', EXTRACT(EPOCH FROM (v_endtime - v_sttime));
    RAISE NOTICE '------------------------';

    -- ===========================
    -- crm_prd_info
    -- ===========================
    v_sttime := clock_timestamp();
    RAISE NOTICE '>> Loading crm_prd_info';

    RAISE NOTICE '>> Truncating table: silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info;

    RAISE NOTICE '>> Inserting into table: silver.crm_prd_info';
    INSERT INTO silver.crm_prd_info(
        prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
        SUBSTRING(prd_key, 7),
        prd_nm,
        COALESCE(prd_cost, 0),
        CASE UPPER(TRIM(prd_line))
            WHEN 'R' THEN 'Road'
            WHEN 'M' THEN 'Mountain'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END,
        prd_start_dt,
        LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1
    FROM bronze.crm_prd_info;

    v_endtime := clock_timestamp();
    RAISE NOTICE '>> Load duration: % seconds', EXTRACT(EPOCH FROM (v_endtime - v_sttime));
    RAISE NOTICE '------------------------';

    -- ===========================
    -- crm_sales_details
    -- ===========================
    v_sttime := clock_timestamp();
    RAISE NOTICE '>> Loading crm_sales_details';

    RAISE NOTICE '>> Truncating table: silver.crm_sales_details';
    TRUNCATE TABLE silver.crm_sales_details;

    RAISE NOTICE '>> Inserting into table: silver.crm_sales_details';
    INSERT INTO silver.crm_sales_details(
        sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt,
        sls_sales, sls_quantity, sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE WHEN sls_order_dt <= 0 OR LENGTH(sls_order_dt::TEXT) != 8 THEN NULL
             ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD') END,
        CASE WHEN sls_ship_dt <= 0 OR LENGTH(sls_ship_dt::TEXT) != 8 THEN NULL
             ELSE TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD') END,
        CASE WHEN sls_due_dt <= 0 OR LENGTH(sls_due_dt::TEXT) != 8 THEN NULL
             ELSE TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD') END,
        CASE WHEN sls_sales != sls_quantity * ABS(sls_price) OR sls_sales <= 0 OR sls_sales IS NULL
             THEN sls_quantity * ABS(sls_price)
             ELSE sls_sales END,
        sls_quantity,
        CASE WHEN sls_price <= 0 OR sls_price IS NULL
             THEN sls_sales / NULLIF(sls_quantity, 0)
             ELSE sls_price END
    FROM bronze.crm_sales_details;

    v_endtime := clock_timestamp();
    RAISE NOTICE '>> Load duration: % seconds', EXTRACT(EPOCH FROM (v_endtime - v_sttime));
    RAISE NOTICE '------------------------';

    -- ===========================
    -- erp_cust_az12
    -- ===========================
    v_sttime := clock_timestamp();
    RAISE NOTICE '>> Loading erp_cust_az12';

    RAISE NOTICE '>> Truncating table: silver.erp_cust_az12';
    TRUNCATE TABLE silver.erp_cust_az12;

    RAISE NOTICE '>> Inserting into table: silver.erp_cust_az12';
    INSERT INTO silver.erp_cust_az12(cid, bdate, gen)
    SELECT
        CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4) ELSE cid END,
        CASE WHEN bdate > NOW() THEN NULL ELSE bdate END,
        CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
             WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
             ELSE 'n/a' END
    FROM bronze.erp_cust_az12;

    v_endtime := clock_timestamp();
    RAISE NOTICE '>> Load duration: % seconds', EXTRACT(EPOCH FROM (v_endtime - v_sttime));
    RAISE NOTICE '------------------------';

    -- ===========================
    -- erp_loc_a101
    -- ===========================
    v_sttime := clock_timestamp();
    RAISE NOTICE '>> Loading erp_loc_a101';

    RAISE NOTICE '>> Truncating table: silver.erp_loc_a101';
    TRUNCATE TABLE silver.erp_loc_a101;

    RAISE NOTICE '>> Inserting into table: silver.erp_loc_a101';
    INSERT INTO silver.erp_loc_a101(cid, cntry)
    SELECT
        REPLACE(cid, '-', ''),
        CASE
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'United States', 'USA') THEN 'United States'
            WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'n/a'
            ELSE TRIM(cntry)
        END
    FROM bronze.erp_loc_a101;

    v_endtime := clock_timestamp();
    RAISE NOTICE '>> Load duration: % seconds', EXTRACT(EPOCH FROM (v_endtime - v_sttime));
    RAISE NOTICE '------------------------';

    -- ===========================
    -- erp_px_cat_g1v2
    -- ===========================
    v_sttime := clock_timestamp();
    RAISE NOTICE '>> Loading erp_px_cat_g1v2';

    RAISE NOTICE '>> Truncating table: silver.erp_px_cat_g1v2';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    RAISE NOTICE '>> Inserting into table: silver.erp_px_cat_g1v2';
    INSERT INTO silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
    SELECT id, cat, subcat, maintenance
    FROM bronze.erp_px_cat_g1v2;

    v_endtime := clock_timestamp();
    RAISE NOTICE '>> Load duration: % seconds', EXTRACT(EPOCH FROM (v_endtime - v_sttime));
    RAISE NOTICE '========================';

    -- ===========================
    -- Total duration
    -- ===========================
    v_totendtime := clock_timestamp();
    RAISE NOTICE '>> TOTAL LOAD DURATION: % seconds', EXTRACT(EPOCH FROM (v_totendtime - v_totsttime));
END;
$$;

call load_silver()
