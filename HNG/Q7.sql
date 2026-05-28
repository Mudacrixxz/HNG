/*
Question 7: Review Ratings and Sales Performance
Group products by average review rating into High Rated, Mid Rated and Low
Rated. For each category, calculate product count, total revenue and average
unit price. Revenue uses non-cancelled, non-returned orders.
*/

WITH product_ratings AS (
    SELECT
        p.product_id,
        p.unit_price,
        AVG(r.rating) AS avg_rating
    FROM products p
    JOIN reviews r ON r.product_id = p.product_id
    WHERE r.rating BETWEEN 1 AND 5
    GROUP BY p.product_id, p.unit_price
),
product_revenue AS (
    SELECT
        oi.product_id,
        SUM(oi.line_total) AS total_revenue
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('Cancelled', 'Returned')
      AND oi.line_total IS NOT NULL
    GROUP BY oi.product_id
),
rated_products AS (
    SELECT
        pr.product_id,
        pr.unit_price,
        COALESCE(rv.total_revenue, 0) AS total_revenue,
        CASE
            WHEN pr.avg_rating >= 4.0 THEN 'High Rated'
            WHEN pr.avg_rating >= 3.0 THEN 'Mid Rated'
            ELSE 'Low Rated'
        END AS rating_category
    FROM product_ratings pr
    LEFT JOIN product_revenue rv ON rv.product_id = pr.product_id
)
SELECT
    rating_category,
    COUNT(*) AS product_count,
    ROUND(SUM(total_revenue), 2) AS total_revenue,
    ROUND(AVG(unit_price), 2) AS average_unit_price
FROM rated_products
GROUP BY rating_category
ORDER BY
    CASE rating_category
        WHEN 'High Rated' THEN 1
        WHEN 'Mid Rated' THEN 2
        ELSE 3
    END;
