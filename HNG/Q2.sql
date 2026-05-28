/*
Question 2: Product Performance
Identify the top 10 products by total revenue in 2024. Revenue is based on
non-cancelled, non-returned orders. Include product name, category, total
revenue and total number of orders.
*/

SELECT
    p.product_id,
    p.product_name,
    p.category,
    ROUND(SUM(oi.line_total), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_date >= DATE '2024-01-01'
  AND o.order_date < DATE '2025-01-01'
  AND o.order_status NOT IN ('Cancelled', 'Returned')
  AND oi.line_total IS NOT NULL
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 10;
