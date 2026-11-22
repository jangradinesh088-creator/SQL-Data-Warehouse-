/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/
DROP PROCEDURE IF EXISTS silver.load_silver;

DELIMITER $$

CREATE PROCEDURE silver.load_silver()
BEGIN

    DECLARE v_start_time DATETIME;
    DECLARE v_end_time DATETIME;
    DECLARE v_batch_start_time DATETIME;
    DECLARE v_batch_end_time DATETIME;
    DECLARE v_error_message TEXT;

    -- Error Handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_message = MESSAGE_TEXT;

        SELECT CONCAT('ERROR OCCURRED: ', v_error_message) AS error_message;
    END;

    SET v_batch_start_time = NOW();

    SELECT '========================================' AS message;
    SELECT 'Loading Silver Layer' AS message;
    SELECT '========================================' AS message;


    -- ==========================================
    -- 1. CRM CUSTOMER INFO
    -- ==========================================

    SET v_start_time = NOW();

    TRUNCATE TABLE silver.crm_cust_info;

    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )

    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),

        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE 'n/a'
        END,

        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE 'n/a'
        END,

        cst_create_date

    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) AS t

    WHERE flag_last = 1;

    SET v_end_time = NOW();

    SELECT CONCAT(
        'CRM Customer Info Load Duration: ',
        TIMESTAMPDIFF(SECOND, v_start_time, v_end_time),
        ' seconds'
    ) AS message;


    -- ==========================================
    -- 2. CRM PRODUCT INFO
    -- ==========================================

    SET v_start_time = NOW();

    TRUNCATE TABLE silver.crm_prd_info;

    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )

    SELECT
        prd_id,

        REPLACE(
            SUBSTRING(prd_key, 1, 5),
            '-',
            '_'
        ) AS cat_id,

        SUBSTRING(prd_key, 7) AS prd_key,

        prd_nm,

        IFNULL(prd_cost, 0) AS prd_cost,

        CASE
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,

        CAST(prd_start_dt AS DATE) AS prd_start_dt,

        DATE_SUB(
            LEAD(CAST(prd_start_dt AS DATE)) OVER (
                PARTITION BY prd_key
                ORDER BY CAST(prd_start_dt AS DATE)
            ),
            INTERVAL 1 DAY
        ) AS prd_end_dt

    FROM bronze.crm_prd_info;

    SET v_end_time = NOW();

    SELECT CONCAT(
        'CRM Product Info Load Duration: ',
        TIMESTAMPDIFF(SECOND, v_start_time, v_end_time),
        ' seconds'
    ) AS message;


    -- ==========================================
    -- 3. CRM SALES DETAILS
    -- ==========================================

    SET v_start_time = NOW();

    TRUNCATE TABLE silver.crm_sales_details;

    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )

    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        CASE
            WHEN sls_order_dt IS NULL
                 OR LENGTH(TRIM(CAST(sls_order_dt AS CHAR))) != 8
                 OR TRIM(CAST(sls_order_dt AS CHAR)) = '0'
            THEN NULL
            ELSE STR_TO_DATE(
                CAST(sls_order_dt AS CHAR),
                '%Y%m%d'
            )
        END AS sls_order_dt,

        CASE
            WHEN sls_ship_dt IS NULL
                 OR LENGTH(TRIM(CAST(sls_ship_dt AS CHAR))) != 8
                 OR TRIM(CAST(sls_ship_dt AS CHAR)) = '0'
            THEN NULL
            ELSE STR_TO_DATE(
                CAST(sls_ship_dt AS CHAR),
                '%Y%m%d'
            )
        END AS sls_ship_dt,

        CASE
            WHEN sls_due_dt IS NULL
                 OR LENGTH(TRIM(CAST(sls_due_dt AS CHAR))) != 8
                 OR TRIM(CAST(sls_due_dt AS CHAR)) = '0'
            THEN NULL
            ELSE STR_TO_DATE(
                CAST(sls_due_dt AS CHAR),
                '%Y%m%d'
            )
        END AS sls_due_dt,

        CASE
            WHEN sls_sales IS NULL
                 OR sls_sales <= 0
                 OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,

        sls_quantity,

        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS sls_price

    FROM bronze.crm_sales_details;

    SET v_end_time = NOW();

    SELECT CONCAT(
        'CRM Sales Details Load Duration: ',
        TIMESTAMPDIFF(SECOND, v_start_time, v_end_time),
        ' seconds'
    ) AS message;


    -- ==========================================
    -- 4. ERP CUSTOMER AZ12
    -- ==========================================

    SET v_start_time = NOW();

    TRUNCATE TABLE silver.erp_cust_az12;

    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )

    SELECT
        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4)
            ELSE cid
        END AS cid,

        CASE
            WHEN CAST(bdate AS DATE) > CURDATE() THEN NULL
            ELSE CAST(bdate AS DATE)
        END AS bdate,

        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
            ELSE 'n/a'
        END AS gen

    FROM bronze.erp_cust_az12;

    SET v_end_time = NOW();

    SELECT CONCAT(
        'ERP Customer AZ12 Load Duration: ',
        TIMESTAMPDIFF(SECOND, v_start_time, v_end_time),
        ' seconds'
    ) AS message;


    -- ==========================================
    -- 5. ERP LOCATION A101
    -- ==========================================

    SET v_start_time = NOW();

    TRUNCATE TABLE silver.erp_loc_a101;

    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )

    SELECT
        REPLACE(cid, '-', '') AS cid,

        CASE
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
            ELSE TRIM(cntry)
        END AS cntry

    FROM bronze.erp_loc_a101;

    SET v_end_time = NOW();

    SELECT CONCAT(
        'ERP Location Load Duration: ',
        TIMESTAMPDIFF(SECOND, v_start_time, v_end_time),
        ' seconds'
    ) AS message;


    -- ==========================================
    -- 6. ERP PRODUCT CATEGORY
    -- ==========================================

    SET v_start_time = NOW();

    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    INSERT INTO silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance
    )

    SELECT
        id,
        cat,
        subcat,
        maintenance

    FROM bronze.erp_px_cat_g1v2;

    SET v_end_time = NOW();

    SELECT CONCAT(
        'ERP Product Category Load Duration: ',
        TIMESTAMPDIFF(SECOND, v_start_time, v_end_time),
        ' seconds'
    ) AS message;


    -- ==========================================
    -- BATCH COMPLETION
    -- ==========================================

    SET v_batch_end_time = NOW();

    SELECT '========================================' AS message;
    SELECT 'Loading Silver Layer Completed!' AS message;

    SELECT CONCAT(
        'Total Load Duration: ',
        TIMESTAMPDIFF(
            SECOND,
            v_batch_start_time,
            v_batch_end_time
        ),
        ' seconds'
    ) AS message;

    SELECT '========================================' AS message;

END$$

DELIMITER ;
