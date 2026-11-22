
/*
===============================================================================
                         GOLD LAYER - QUALITY CHECKS
===============================================================================

Script Purpose:
    This script performs quality checks to validate the integrity,
    consistency, and accuracy of the Gold Layer.

    These checks ensure:
    - Uniqueness of surrogate keys in dimension views.
    - Referential integrity between fact and dimension views.
    - Validation of relationships in the data model.

Database: MySQL Workbench

Usage Notes:
    - Investigate and resolve any discrepancies found during the checks.
    - Expected result for duplicate checks: No records.
    - Expected result for referential integrity check: No records.

===============================================================================
*/


-- ============================================================================
-- 1. Checking gold.dim_customers
-- ============================================================================

-- Check uniqueness of Customer Key
-- Expectation: No results

SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;


-- ============================================================================
-- 2. Checking gold.dim_products
-- ============================================================================

-- Check uniqueness of Product Key
-- Expectation: No results

SELECT
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


-- ============================================================================
-- 3. Checking gold.fact_sales
-- ============================================================================

-- Check referential integrity between Fact and Dimension views
-- Expectation: No results

SELECT
    f.order_number,
    f.product_key,
    f.customer_key,
    p.product_key AS matched_product_key,
    c.customer_key AS matched_customer_key

FROM gold.fact_sales f

LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key

LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key

WHERE p.product_key IS NULL
   OR c.customer_key IS NULL;


/*
===============================================================================
                     END OF GOLD LAYER QUALITY CHECKS
===============================================================================
*/
