
/*
===============================================================================
                    SILVER LAYER - DATA QUALITY CHECKS
===============================================================================

Project     : SQL Data Warehouse Project
Layer       : Silver
Database    : MySQL
Purpose     : Validate data quality after loading Bronze data into Silver.

Checks Performed:
    1. Duplicate Check
    2. NULL Check
    3. Unwanted Spaces Check
    4. Invalid Values Check
    5. Date Validation
    6. Data Standardization Check

Tables:
    CRM_CUST_INFO
    CRM_PRD_INFO
    CRM_SALES_DETAILS
    ERP_CUST_AZ12
    ERP_LOC_A101
    ERP_PX_CAT_G1V2

===============================================================================
*/


-- ============================================================================
-- 1. CRM CUSTOMER INFO
-- ============================================================================

-- Check for duplicate Customer IDs
SELECT cst_id, COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

-- Check for NULL Customer IDs
SELECT *
FROM silver.crm_cust_info
WHERE cst_id IS NULL;

-- Check for unwanted spaces
SELECT *
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)
   OR cst_lastname <> TRIM(cst_lastname);

-- Check distinct Gender values
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;

-- Check distinct Marital Status values
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;


-- ============================================================================
-- 2. CRM PRODUCT INFO
-- ============================================================================

-- Check for duplicate Product IDs
SELECT prd_id, COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;

-- Check for NULL Product IDs
SELECT *
FROM silver.crm_prd_info
WHERE prd_id IS NULL;

-- Check for unwanted spaces in Product Name
SELECT *
FROM silver.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);

-- Check for NULL or negative Product Cost
SELECT *
FROM silver.crm_prd_info
WHERE prd_cost IS NULL
   OR prd_cost < 0;

-- Check Product Line values
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- Check invalid Product Date Range
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- ============================================================================
-- 3. CRM SALES DETAILS
-- ============================================================================

-- Check for NULL IDs
SELECT *
FROM silver.crm_sales_details
WHERE sls_ord_num IS NULL
   OR sls_prd_key IS NULL
   OR sls_cust_id IS NULL;

-- Check invalid Sales values
SELECT *
FROM silver.crm_sales_details
WHERE sls_sales IS NULL
   OR sls_sales <= 0;

-- Check invalid Quantity
SELECT *
FROM silver.crm_sales_details
WHERE sls_quantity IS NULL
   OR sls_quantity <= 0;

-- Check invalid Price
SELECT *
FROM silver.crm_sales_details
WHERE sls_price IS NULL
   OR sls_price <= 0;

-- Check Order Date after Shipping Date
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt;

-- Check Shipping Date after Due Date
SELECT *
FROM silver.crm_sales_details
WHERE sls_ship_dt > sls_due_dt;


-- ============================================================================
-- 4. ERP CUSTOMER AZ12
-- ============================================================================

-- Check for duplicate Customer IDs
SELECT cid, COUNT(*) AS duplicate_count
FROM silver.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1;

-- Check for NULL Customer IDs
SELECT *
FROM silver.erp_cust_az12
WHERE cid IS NULL;

-- Check future Birth Dates
SELECT *
FROM silver.erp_cust_az12
WHERE bdate > CURDATE();

-- Check Gender values
SELECT DISTINCT gen
FROM silver.erp_cust_az12;


-- ============================================================================
-- 5. ERP LOCATION A101
-- ============================================================================

-- Check for duplicate Customer IDs
SELECT cid, COUNT(*) AS duplicate_count
FROM silver.erp_loc_a101
GROUP BY cid
HAVING COUNT(*) > 1;

-- Check for NULL Customer IDs
SELECT *
FROM silver.erp_loc_a101
WHERE cid IS NULL;

-- Check Country values
SELECT DISTINCT cntry
FROM silver.erp_loc_a101;


-- ============================================================================
-- 6. ERP PRODUCT CATEGORY G1V2
-- ============================================================================

-- Check for duplicate Product IDs
SELECT id, COUNT(*) AS duplicate_count
FROM silver.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1;

-- Check for NULL Product IDs
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE id IS NULL;

-- Check for unwanted spaces
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat <> TRIM(cat)
   OR subcat <> TRIM(subcat);


/*
===============================================================================
                            END OF QUALITY CHECKS
===============================================================================
*/

