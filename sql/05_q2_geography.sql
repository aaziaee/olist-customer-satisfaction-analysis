-- Q2: Geography — negative-review rate by customer state, restricted to
-- on-time deliveries only (isolates a state effect from delivery-timing
-- effects already established in Q1). States below 10 orders are excluded.
-- Flags states whose negative rate exceeds 1.5x the on-time baseline.

WITH on_time_orders AS (
    SELECT
        dr.review_id,
        dr.order_id,
        dr.review_score,
        c.customer_state
    FROM deduped_reviews dr
    JOIN orders o
        ON dr.order_id = o.order_id
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_delivered_customer_date::date <= o.order_estimated_delivery_date::date
),
baseline AS (
    SELECT
        ROUND(
            100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*),
            2
        ) AS on_time_baseline_rate
    FROM on_time_orders
)
SELECT
    customer_state,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) AS negative_orders,
    ROUND(
        100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS negative_rate,
    on_time_baseline_rate,
    CASE
        WHEN ROUND(
            100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*),
            2
        ) > on_time_baseline_rate * 1.5
        THEN 'Above threshold'
        ELSE 'Normal'
    END AS status
FROM on_time_orders
CROSS JOIN baseline
GROUP BY customer_state, on_time_baseline_rate
HAVING COUNT(*) >= 10
ORDER BY negative_rate DESC;