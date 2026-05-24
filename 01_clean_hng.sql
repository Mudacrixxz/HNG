BEGIN;

CREATE TABLE IF NOT EXISTS customers_backup_before_cleaning AS TABLE customers;
CREATE TABLE IF NOT EXISTS sellers_backup_before_cleaning AS TABLE sellers;
CREATE TABLE IF NOT EXISTS products_backup_before_cleaning AS TABLE products;
CREATE TABLE IF NOT EXISTS orders_backup_before_cleaning AS TABLE orders;
CREATE TABLE IF NOT EXISTS order_items_backup_before_cleaning AS TABLE order_items;

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
SET category = CASE
    WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('beauty', 'beautypersonalcare', 'beautyandpersonalcare') THEN 'Beauty & Personal Care'
    WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('books', 'booksstationery', 'booksandstationery') THEN 'Books & Stationery'
    WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('electronics', 'electronis') THEN 'Electronics'
    WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('fashion', 'fashon') THEN 'Fashion'
    WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('food', 'foodbeverages', 'foodandbeverages') THEN 'Food & Beverages'
    WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('homegarden', 'homeandgarden') THEN 'Home & Garden'
    WHEN regexp_replace(lower(btrim(category)), '[[:space:]&-]+', '', 'g') IN ('sports', 'sportsfitness', 'sportsandfitness') THEN 'Sports & Fitness'
    ELSE NULLIF(btrim(category), '')
END;

UPDATE order_items oi
SET unit_price = p.unit_price
FROM products p
WHERE p.product_id = oi.product_id
  AND oi.unit_price IS NULL
  AND p.unit_price IS NOT NULL;

UPDATE order_items
SET line_total = quantity * unit_price
WHERE line_total IS NULL
  AND quantity IS NOT NULL
  AND unit_price IS NOT NULL;

UPDATE orders o
SET total_amount = totals.item_total
FROM (
    SELECT order_id, SUM(line_total) AS item_total
    FROM order_items
    GROUP BY order_id
) totals
WHERE totals.order_id = o.order_id
  AND o.total_amount IS DISTINCT FROM totals.item_total;

DROP VIEW IF EXISTS data_quality_issues;
DROP VIEW IF EXISTS duplicate_customer_email_inspection;

CREATE VIEW duplicate_customer_email_inspection AS
WITH dup_emails AS (
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
JOIN dup_emails d ON d.email = c.email
LEFT JOIN customer_order_summary os ON os.customer_id = c.customer_id;

CREATE VIEW data_quality_issues AS
SELECT
    'customers' AS table_name,
    customer_id AS record_id,
    'missing_email' AS issue_type,
    'Customer email is missing and should stay NULL until the real email is known.' AS issue_detail
FROM customers
WHERE email IS NULL

UNION ALL

SELECT
    'products' AS table_name,
    product_id AS record_id,
    'missing_unit_price' AS issue_type,
    'Product price is missing; related order item totals cannot be calculated reliably.' AS issue_detail
FROM products
WHERE unit_price IS NULL

UNION ALL

SELECT
    'order_items' AS table_name,
    item_id::text AS record_id,
    'missing_unit_price_or_line_total' AS issue_type,
    'Order item has missing price or line total because the product price is unknown.' AS issue_detail
FROM order_items
WHERE unit_price IS NULL OR line_total IS NULL

UNION ALL

SELECT
    'orders' AS table_name,
    order_id AS record_id,
    'missing_total_amount' AS issue_type,
    'Order total is missing because at least one order item cannot be priced.' AS issue_detail
FROM orders
WHERE total_amount IS NULL

UNION ALL

SELECT
    'customers' AS table_name,
    email AS record_id,
    'duplicate_email' AS issue_type,
    'More than one customer record uses this email; inspect before merging.' AS issue_detail
FROM customers
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1;

COMMIT;
