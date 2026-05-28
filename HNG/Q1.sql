/*
Question 1: Customer Acquisition & 30-Day Conversion
Find the top 5 states by new customer sign-ups in 2024. For each state,
calculate the percentage of these new customers who made at least one purchase
within their first 30 days of signing up.
*/

WITH signups_2024 AS (
    SELECT customer_id, state, signup_date
    FROM customers
    WHERE signup_date >= DATE '2024-01-01'
      AND signup_date < DATE '2025-01-01'
),
customer_conversion AS (
    SELECT
        s.customer_id,
        s.state,
        EXISTS (
            SELECT 1
            FROM orders o
            WHERE o.customer_id = s.customer_id
              AND o.order_date >= s.signup_date
              AND o.order_date <= s.signup_date + INTERVAL '30 days'
              AND o.order_status NOT IN ('Cancelled', 'Returned')
        ) AS converted_within_30_days
    FROM signups_2024 s
)
SELECT
    state,
    COUNT(*) AS new_customer_signups,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE converted_within_30_days) / COUNT(*),
        2
    ) AS conversion_rate_30_day_pct
FROM customer_conversion
GROUP BY state
ORDER BY new_customer_signups DESC, state
LIMIT 5;
