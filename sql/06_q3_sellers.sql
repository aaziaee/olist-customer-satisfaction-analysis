-- Q3: Seller performance — negative-review rate by seller, restricted to
-- on-time deliveries only, sellers with at least 30 qualifying orders.
-- Flags sellers whose negative rate exceeds mean + 1 standard deviation
-- across all qualifying sellers (statistically-derived threshold, unlike
-- the fixed 1.5x multiplier used in Q2 and Q4).

WITH order_seller_reviews AS (
    SELECT DISTINCT
        oi.order_id,
        oi.seller_id,
        dr.review_score
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN deduped_reviews dr
        ON o.order_id = dr.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_delivered_customer_date::date <= o.order_estimated_delivery_date::date
),
seller_summary AS (
    SELECT
        seller_id,
        COUNT(*) AS total_orders,
        SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) AS negative_orders,
        ROUND(
            100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*),
            2
        ) AS negative_rate
    FROM order_seller_reviews
    GROUP BY seller_id
    HAVING COUNT(*) >= 30
),
stats AS (
    SELECT
        AVG(negative_rate) AS avg_rate,
        STDDEV(negative_rate) AS stddev_rate
    FROM seller_summary
)
SELECT
    ss.seller_id,
    ss.total_orders,
    ss.negative_orders,
    ss.negative_rate,
    ROUND(st.avg_rate, 2) AS avg_rate,
    ROUND(st.stddev_rate, 2) AS stddev_rate,
    CASE
        WHEN ss.negative_rate > st.avg_rate + st.stddev_rate
        THEN 'Above threshold'
        ELSE 'Normal'
    END AS status
FROM seller_summary ss
CROSS JOIN stats st
ORDER BY ss.negative_rate DESC;