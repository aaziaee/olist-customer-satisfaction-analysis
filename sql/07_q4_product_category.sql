-- Q4: Product category — negative-review rate by category, restricted to
-- on-time deliveries only. COALESCE handles two known data-quality issues:
-- products with no category, and categories missing an English translation.
-- Flags categories whose negative rate exceeds 1.5x the on-time baseline.

WITH order_category_reviews AS (
    SELECT DISTINCT
        oi.order_id,
        COALESCE(t.product_category_name_english, p.product_category_name, 'uncategorized') AS category,
        dr.review_score
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN deduped_reviews dr ON o.order_id = dr.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_delivered_customer_date::date <= o.order_estimated_delivery_date::date
),
order_level_reviews AS (
    SELECT DISTINCT order_id, review_score
    FROM order_category_reviews
),
baseline AS (
    SELECT ROUND(100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*), 2) AS baseline_rate
    FROM order_level_reviews
)
SELECT
    category,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) AS negative_orders,
    ROUND(100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*), 2) AS negative_rate,
    b.baseline_rate,
    CASE WHEN ROUND(100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*), 2) > b.baseline_rate * 1.5
         THEN 'Above threshold' ELSE 'Normal' END AS status
FROM order_category_reviews
CROSS JOIN baseline b
GROUP BY category, b.baseline_rate
HAVING COUNT(*) >= 30   
ORDER BY negative_rate DESC;