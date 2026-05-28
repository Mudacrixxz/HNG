/*
Question 3: Seller Fulfilment Efficiency
Calculate the average time in hours between order placement and delivery for
each seller. Return the top 20 sellers with the fastest average fulfilment
times among sellers who completed at least 20 delivered orders. Include total
completed orders and average customer rating.
*/

WITH seller_ratings AS (
    SELECT
        p.seller_id,
        AVG(r.rating) AS avg_customer_rating
    FROM products p
    JOIN reviews r ON r.product_id = p.product_id
    WHERE r.rating BETWEEN 1 AND 5
    GROUP BY p.seller_id
)
SELECT
    s.seller_id,
    s.seller_name,
    COUNT(o.order_id) AS total_completed_orders,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.delivery_date::timestamp - o.order_date::timestamp)) / 3600.0), 2)
        AS avg_fulfilment_hours,
    ROUND(sr.avg_customer_rating, 2) AS avg_customer_rating
FROM sellers s
JOIN orders o ON o.seller_id = s.seller_id
LEFT JOIN seller_ratings sr ON sr.seller_id = s.seller_id
WHERE o.order_status = 'Delivered'
  AND o.order_date IS NOT NULL
  AND o.delivery_date IS NOT NULL
GROUP BY s.seller_id, s.seller_name, sr.avg_customer_rating
HAVING COUNT(o.order_id) >= 20
ORDER BY avg_fulfilment_hours ASC, total_completed_orders DESC
LIMIT 20;
