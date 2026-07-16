-- Step 0: Baseline negative-review rate by month.
-- Scoped to delivered orders that received a review (646 delivered orders with
-- no review row are excluded — review_score is undefined for them).
-- generate_series ensures months with zero orders still appear in the trend.

WITH calendar AS (
    SELECT
        generate_series(
            MIN(DATE_TRUNC('month', order_purchase_timestamp)),
            MAX(DATE_TRUNC('month', order_purchase_timestamp)),
            INTERVAL '1 month'
        )::date AS month
    FROM orders
),
monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
        COUNT(*) AS reviewed_orders,
        SUM(CASE WHEN dp.review_score <= 2 THEN 1 ELSE 0 END) AS negative_orders,
        ROUND(
            SUM(CASE WHEN dp.review_score <= 2 THEN 1 ELSE 0 END)
            / COUNT(*)::numeric * 100,
            2
        ) AS negative_rate
    FROM deduped_reviews dp
    JOIN orders o
        ON o.order_id = dp.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
)
SELECT
    c.month,
    COALESCE(mm.reviewed_orders, 0) AS reviewed_orders,
    COALESCE(mm.negative_orders, 0) AS negative_orders,
    COALESCE(mm.negative_rate, 0) AS negative_rate
FROM calendar c
LEFT JOIN monthly_metrics mm
    ON c.month = mm.month
ORDER BY c.month;

-- Step 0: Review score distribution, used to validate the review_score <= 2
-- cutoff as the definition of a negative review.

SELECT
    dr.review_score,
    COUNT(*) AS review_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM deduped_reviews dr
JOIN orders o
    ON dr.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY dr.review_score
ORDER BY dr.review_score;