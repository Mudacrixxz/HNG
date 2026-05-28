/*
Question 8: Top Seller Bonus Qualification
Identify the top 10 sellers in 2024 by total revenue who completed at least
10 delivered orders and have an average customer rating of 4.0 or above.
Include total orders, average rating and total revenue.
*/

WITH seller_revenue AS (
    SELECT
        s.seller_id,
        s.seller_name,
        COUNT(DISTINCT o.order_id) FILTER (WHERE o.order_status = 'Delivered') AS total_completed_orders,
        SUM(o.total_amount) FILTER (WHERE o.order_status NOT IN ('Cancelled', 'Returned')) AS total_revenue
    FROM sellers s
    JOIN orders o ON o.seller_id = s.seller_id
    WHERE o.order_date >= DATE '2024-01-01'
      AND o.order_date < DATE '2025-01-01'
      AND o.total_amount IS NOT NULL
    GROUP BY s.seller_id, s.seller_name
),
seller_ratings AS (
    SELECT
        p.seller_id,
        AVG(r.rating) AS avg_customer_rating
    FROM products p
    JOIN reviews r ON r.product_id = p.product_id
    WHERE r.rating BETWEEN 1 AND 5
    GROUP BY p.seller_id
)
SELECT
    sr.seller_id,
    sr.seller_name,
    sr.total_completed_orders,
    ROUND(rt.avg_customer_rating, 2) AS average_rating,
    ROUND(sr.total_revenue, 2) AS total_revenue
FROM seller_revenue sr
JOIN seller_ratings rt ON rt.seller_id = sr.seller_id
WHERE sr.total_completed_orders >= 10
  AND rt.avg_customer_rating >= 4.0
ORDER BY sr.total_revenue DESC
LIMIT 10;
