/*
Question 5: Customer Spend Segmentation
Segment customers by total 2024 spend into High, Medium and Low spenders.
For each group, calculate customer count, average spend per customer and total
revenue contribution. Spend uses non-cancelled, non-returned orders.
*/

WITH customer_spend AS (
    SELECT
        c.customer_id,
        COALESCE(SUM(o.total_amount), 0) AS total_spend_2024
    FROM customers c
    LEFT JOIN orders o
      ON o.customer_id = c.customer_id
     AND o.order_date >= DATE '2024-01-01'
     AND o.order_date < DATE '2025-01-01'
     AND o.order_status NOT IN ('Cancelled', 'Returned')
     AND o.total_amount IS NOT NULL
    GROUP BY c.customer_id
),
segments AS (
    SELECT
        customer_id,
        total_spend_2024,
        CASE
            WHEN total_spend_2024 >= 100000 THEN 'High Spenders'
            WHEN total_spend_2024 >= 50000 THEN 'Medium Spenders'
            ELSE 'Low Spenders'
        END AS spend_segment
    FROM customer_spend
)
SELECT
    spend_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spend_2024), 2) AS average_spend_per_customer,
    ROUND(SUM(total_spend_2024), 2) AS total_revenue_contribution
FROM segments
GROUP BY spend_segment
ORDER BY
    CASE spend_segment
        WHEN 'High Spenders' THEN 1
        WHEN 'Medium Spenders' THEN 2
        ELSE 3
    END;
