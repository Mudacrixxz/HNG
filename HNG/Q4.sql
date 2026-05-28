/*
Question 4: Quarterly Revenue Trends
Compare quarterly revenue across 2023 and 2024. For each quarter, calculate
total revenue, average order value and total number of orders. The final column
identifies the quarter with the strongest revenue growth from 2023 to 2024.
Revenue uses non-cancelled, non-returned orders with non-null totals.
*/

WITH quarterly AS (
    SELECT
        EXTRACT(YEAR FROM order_date)::int AS order_year,
        EXTRACT(QUARTER FROM order_date)::int AS order_quarter,
        ROUND(SUM(total_amount), 2) AS total_revenue,
        ROUND(AVG(total_amount), 2) AS average_order_value,
        COUNT(*) AS total_orders
    FROM orders
    WHERE order_date >= DATE '2023-01-01'
      AND order_date < DATE '2025-01-01'
      AND order_status NOT IN ('Cancelled', 'Returned')
      AND total_amount IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(QUARTER FROM order_date)
),
growth AS (
    SELECT
        q24.order_quarter,
        q24.total_revenue - q23.total_revenue AS revenue_growth_amount
    FROM quarterly q24
    JOIN quarterly q23
      ON q23.order_quarter = q24.order_quarter
     AND q23.order_year = 2023
    WHERE q24.order_year = 2024
),
strongest AS (
    SELECT order_quarter
    FROM growth
    ORDER BY revenue_growth_amount DESC
    LIMIT 1
)
SELECT
    q.order_year,
    q.order_quarter,
    q.total_revenue,
    q.average_order_value,
    q.total_orders,
    CASE
        WHEN q.order_year = 2024 AND q.order_quarter = s.order_quarter
        THEN 'strongest_growth_from_2023'
        ELSE NULL
    END AS growth_flag
FROM quarterly q
LEFT JOIN strongest s ON s.order_quarter = q.order_quarter
ORDER BY q.order_year, q.order_quarter;
