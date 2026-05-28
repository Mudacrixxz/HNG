/*
Part A: Data Cleaning & Preparation
Database: TradeZone

Notes:
- Date columns are PostgreSQL DATE/TIMESTAMP types, so they are already stored
  consistently. They can be displayed as YYYY-MM-DD with to_char when needed.
- The supplied schema has no discount percentage column, so that validation is
  documented below and cannot be executed.
- Missing product prices are not guessed. Records that depend on unknown prices
  are flagged through data_quality_issues.
*/

BEGIN;

-- Keep original snapshots before making updates. These are only created once.
CREATE TABLE IF NOT EXISTS customers_backup_before_cleaning AS TABLE customers;
CREATE TABLE IF NOT EXISTS sellers_backup_before_cleaning AS TABLE sellers;
CREATE TABLE IF NOT EXISTS products_backup_before_cleaning AS TABLE products;
CREATE TABLE IF NOT EXISTS orders_backup_before_cleaning AS TABLE orders;
CREATE TABLE IF NOT EXISTS order_items_backup_before_cleaning AS TABLE order_items;
CREATE TABLE IF NOT EXISTS payments_backup_before_cleaning AS TABLE payments;
CREATE TABLE IF NOT EXISTS reviews_backup_before_cleaning AS TABLE reviews;

-- Remove exact duplicate rows in the requested core tables. Primary keys should
-- prevent duplicate IDs, so this only removes rows that are identical in every
-- business column.
WITH ranked AS (
    SELECT ctid,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id, first_name, last_name, email, city,
                            state, signup_date, account_status
               ORDER BY ctid
           ) AS rn
    FROM customers
)
DELETE FROM customers c
USING ranked r
WHERE c.ctid = r.ctid
  AND r.rn > 1;

WITH ranked AS (
    SELECT ctid,
           ROW_NUMBER() OVER (
               PARTITION BY seller_id, seller_name, onboarding_date,
                            product_category, city, state, account_status
               ORDER BY ctid
           ) AS rn
    FROM sellers
)
DELETE FROM sellers s
USING ranked r
WHERE s.ctid = r.ctid
  AND r.rn > 1;

WITH ranked AS (
    SELECT ctid,
           ROW_NUMBER() OVER (
               PARTITION BY order_id, customer_id, seller_id, order_date,
                            delivery_date, order_status, total_amount
               ORDER BY ctid
           ) AS rn
    FROM orders
)
DELETE FROM orders o
USING ranked r
WHERE o.ctid = r.ctid
  AND r.rn > 1;

-- Missing and blank values in critical text columns are normalized to NULL.
UPDATE customers
SET
    email = NULLIF(lower(btrim(email)), ''),
    city = CASE
        WHEN regexp_replace(lower(btrim(city)), '[[:space:]-]+', '', 'g') = 'lagos' THEN 'Lagos'
        WHEN regexp_replace(lower(btrim(city)), '[[:space:]-]+', '', 'g') = 'abuja' THEN 'Abuja'
        WHEN regexp_replace(lower(btrim(city)), '[[:space:]-]+', '', 'g') = 'ibadan' THEN 'Ibadan'
        WHEN regexp_replace(lower(btrim(city)), '[[:space:]-]+', '', 'g') = 'kano' THEN 'Kano'
        WHEN regexp_replace(lower(btrim(city)), '[[:space:]-]+', '', 'g') = 'portharcourt' THEN 'Port Harcourt'
        ELSE NULLIF(btrim(city), '')
    END,
    state = CASE
        WHEN upper(btrim(state)) = 'FCT' THEN 'FCT'
        WHEN lower(btrim(state)) = 'lagos' THEN 'Lagos'
        WHEN lower(btrim(state)) = 'oyo' THEN 'Oyo'
        WHEN lower(btrim(state)) = 'kano' THEN 'Kano'
        WHEN lower(btrim(state)) = 'rivers' THEN 'Rivers'
        ELSE NULLIF(btrim(state), '')
    END,
    account_status = CASE
        WHEN lower(btrim(account_status)) = 'active' THEN 'Active'
        WHEN lower(btrim(account_status)) = 'inactive' THEN 'Inactive'
        ELSE NULLIF(btrim(account_status), '')
    END;

UPDATE sellers
SET
    city = CASE
        WHEN regexp_replace(lower(btrim(city)), '[[:space:]-]+', '', 'g') = 'lagos' THEN 'Lagos'
        WHEN regexp_replace(lower(btrim(city)), '[[:space:]-]+', '', 'g') = 'abuja' THEN 'Abuja'
        WHEN regexp_replace(lower(btrim(city)), '[[:space:]-]+', '', 'g') = 'ibadan' THEN 'Ibadan'
        WHEN regexp_replace(lower(btrim(city)), '[[:space:]-]+', '', 'g') = 'kano' THEN 'Kano'
        WHEN regexp_replace(lower(btrim(city)), '[[:space:]-]+', '', 'g') = 'portharcourt' THEN 'Port Harcourt'
        ELSE NULLIF(btrim(city), '')
    END,
    state = CASE
        WHEN upper(btrim(state)) = 'FCT' THEN 'FCT'
        WHEN lower(btrim(state)) = 'lagos' THEN 'Lagos'
        WHEN lower(btrim(state)) = 'oyo' THEN 'Oyo'
        WHEN lower(btrim(state)) = 'kano' THEN 'Kano'
        WHEN lower(btrim(state)) = 'rivers' THEN 'Rivers'
        ELSE NULLIF(btrim(state), '')
    END,
    account_status = CASE
        WHEN lower(btrim(account_status)) = 'active' THEN 'Active'
        WHEN lower(btrim(account_status)) = 'suspended' THEN 'Suspended'
        ELSE NULLIF(btrim(account_status), '')
    END,
    product_category = CASE
        WHEN regexp_replace(lower(btrim(product_category)), '[[:space:]&-]+', '', 'g') IN ('beauty', 'beautypersonalcare', 'beautyandpersonalcare') THEN 'Beauty & Personal Care'
        WHEN regexp_replace(lower(btrim(product_category)), '[[:space:]&-]+', '', 'g') IN ('books', 'booksstationery', 'booksandstationery') THEN 'Books & Stationery'
        WHEN regexp_replace(lower(btrim(product_category)), '[[:space:]&-]+', '', 'g') IN ('electronics', 'electronis') THEN 'Electronics'
        WHEN regexp_replace(lower(btrim(product_category)), '[[:space:]&-]+', '', 'g') IN ('fashion', 'fashon') THEN 'Fashion'
        WHEN regexp_replace(lower(btrim(product_category)), '[[:space:]&-]+', '', 'g') IN ('food', 'foodbeverages', 'foodandbeverages') THEN 'Food & Beverages'
        WHEN regexp_replace(lower(btrim(product_category)), '[[:space:]&-]+', '', 'g') IN ('homegarden', 'homeandgarden') THEN 'Home & Garden'
        WHEN regexp_replace(lower(btrim(product_category)), '[[:space:]&-]+', '', 'g') IN ('sports', 'sportsfitness', 'sportsandfitness') THEN 'Sports & Fitness'
        ELSE NULLIF(btrim(product_category), '')
    END;

UPDATE products
SET
    category = CASE
        WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('beauty', 'beautypersonalcare', 'beautyandpersonalcare') THEN 'Beauty & Personal Care'
        WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('books', 'booksstationery', 'booksandstationery') THEN 'Books & Stationery'
        WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('electronics', 'electronis') THEN 'Electronics'
        WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('fashion', 'fashon') THEN 'Fashion'
        WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('food', 'foodbeverages', 'foodandbeverages') THEN 'Food & Beverages'
        WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('homegarden', 'homeandgarden') THEN 'Home & Garden'
        WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('sports', 'sportsfitness', 'sportsandfitness') THEN 'Sports & Fitness'
        ELSE NULLIF(btrim(category), '')
    END;

-- Use product prices to fill order item prices where the reliable product
-- master value exists.
UPDATE order_items oi
SET unit_price = p.unit_price
FROM products p
WHERE oi.product_id = p.product_id
  AND oi.unit_price IS NULL
  AND p.unit_price IS NOT NULL;

UPDATE order_items
SET line_total = quantity * unit_price
WHERE quantity IS NOT NULL
  AND unit_price IS NOT NULL;

-- Recalculate order totals only where every line item can be priced. Orders
-- with missing product prices remain NULL and are flagged for review.
WITH order_sums AS (
    SELECT
        order_id,
        SUM(line_total) AS calculated_total,
        COUNT(*) FILTER (WHERE line_total IS NULL) AS missing_line_totals
    FROM order_items
    GROUP BY order_id
)
UPDATE orders o
SET total_amount = CASE
    WHEN os.missing_line_totals = 0 THEN os.calculated_total
    ELSE NULL
END
FROM order_sums os
WHERE o.order_id = os.order_id;

-- Review ratings must be between 1 and 5. Do not alter invalid ratings here;
-- flag them so the source record can be investigated.
DROP VIEW IF EXISTS data_quality_issues;
DROP VIEW IF EXISTS duplicate_customer_email_inspection;
DROP VIEW IF EXISTS order_total_validation;

CREATE VIEW order_total_validation AS
SELECT
    o.order_id,
    o.total_amount,
    SUM(oi.line_total) AS line_items_total,
    ABS(COALESCE(o.total_amount, 0) - COALESCE(SUM(oi.line_total), 0)) AS amount_difference,
    CASE
        WHEN o.total_amount IS NULL OR SUM(oi.line_total) IS NULL THEN 'missing_total'
        WHEN ABS(o.total_amount - SUM(oi.line_total)) > 10 THEN 'difference_above_10'
        ELSE 'valid'
    END AS validation_status
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.total_amount;

CREATE VIEW duplicate_customer_email_inspection AS
WITH duplicate_emails AS (
    SELECT email
    FROM customers
    WHERE email IS NOT NULL
    GROUP BY email
    HAVING COUNT(*) > 1
),
customer_order_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS order_count,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date,
        SUM(total_amount) AS total_spend
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.email,
    c.customer_id,
    c.first_name,
    c.last_name,
    c.city,
    c.state,
    c.signup_date,
    c.account_status,
    COALESCE(os.order_count, 0) AS order_count,
    os.first_order_date,
    os.last_order_date,
    os.total_spend
FROM customers c
JOIN duplicate_emails d ON d.email = c.email
LEFT JOIN customer_order_summary os ON os.customer_id = c.customer_id;

CREATE VIEW data_quality_issues AS
SELECT 'customers' AS table_name, customer_id AS record_id,
       'missing_email' AS issue_type,
       'Customer email is missing and remains NULL until the true value is known.' AS issue_detail
FROM customers
WHERE email IS NULL

UNION ALL
SELECT 'customers', email,
       'duplicate_email',
       'More than one customer record uses this email; inspect before merging.'
FROM customers
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1

UNION ALL
SELECT 'products', product_id,
       'missing_unit_price',
       'Product price is missing; dependent revenue fields cannot be calculated reliably.'
FROM products
WHERE unit_price IS NULL

UNION ALL
SELECT 'products', product_id,
       'negative_unit_price',
       'Product price is negative and should be corrected at source.'
FROM products
WHERE unit_price < 0

UNION ALL
SELECT 'order_items', item_id::text,
       'missing_unit_price_or_line_total',
       'Order item has missing price or line total because the product price is unknown.'
FROM order_items
WHERE unit_price IS NULL OR line_total IS NULL

UNION ALL
SELECT 'orders', order_id,
       'missing_total_amount',
       'Order total is missing because at least one order item cannot be priced.'
FROM orders
WHERE total_amount IS NULL

UNION ALL
SELECT 'orders', order_id,
       'order_total_difference_above_10',
       'Order total differs from summed line items by more than 10 naira.'
FROM order_total_validation
WHERE validation_status = 'difference_above_10'

UNION ALL
SELECT 'reviews', review_id,
       'rating_outside_1_to_5',
       'Review rating is outside the valid 1 to 5 range.'
FROM reviews
WHERE rating < 1 OR rating > 5;

COMMIT;

-- Validation checks after cleaning.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'reviews', COUNT(*) FROM reviews
ORDER BY table_name;

SELECT issue_type, COUNT(*) AS issue_count
FROM data_quality_issues
GROUP BY issue_type
ORDER BY issue_type;
