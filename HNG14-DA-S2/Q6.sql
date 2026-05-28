/*
Question 6: Payment Method Preferences by State
Analyse payment method preferences across each state. For each state, show
transaction count and total amount for each payment method, and identify the
most popular method per state by transaction count.
*/

WITH payment_by_state AS (
    SELECT
        c.state,
        p.payment_method,
        COUNT(*) AS transaction_count,
        ROUND(SUM(p.amount), 2) AS total_amount
    FROM payments p
    JOIN orders o ON o.order_id = p.order_id
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE p.payment_method IN ('Cash on Delivery', 'Card', 'Mobile Money', 'Bank Transfer')
    GROUP BY c.state, p.payment_method
),
ranked AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY state
            ORDER BY transaction_count DESC, total_amount DESC, payment_method
        ) AS popularity_rank
    FROM payment_by_state
)
SELECT
    state,
    payment_method,
    transaction_count,
    total_amount,
    CASE WHEN popularity_rank = 1 THEN 'most_popular' ELSE NULL END AS state_preference
FROM ranked
ORDER BY state, popularity_rank, payment_method;
