-- Q1, Scheme 1: Expectation gap (actual vs. estimated delivery date) bucketed,
-- against negative-review rate. Excludes the 8 delivered orders with a NULL
-- order_delivered_customer_date.

WITH delivery_data AS (
    SELECT 
        dr.review_id,
        dr.order_id,
        dr.review_score,
        o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date AS expectation_gap
    FROM deduped_reviews dr
    JOIN orders o
        ON dr.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
),
bucketed_orders AS (
    SELECT *,
        CASE
            WHEN expectation_gap < 0 THEN 'Early'
            WHEN expectation_gap = 0 THEN 'On time'
            WHEN expectation_gap BETWEEN 1 AND 3 THEN 'Late 1-3 days'
            WHEN expectation_gap BETWEEN 4 AND 7 THEN 'Late 4-7 days'
            WHEN expectation_gap BETWEEN 8 AND 14 THEN 'Late 8-14 days'
            ELSE 'Late 15+ days'
        END AS expectation_bucket
    FROM delivery_data
)
SELECT
    expectation_bucket,
    COUNT(*) AS order_count,
    ROUND(
        100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS negative_rate
FROM bucketed_orders
GROUP BY expectation_bucket
ORDER BY
    CASE expectation_bucket
        WHEN 'Early' THEN 1
        WHEN 'On time' THEN 2
        WHEN 'Late 1-3 days' THEN 3
        WHEN 'Late 4-7 days' THEN 4
        WHEN 'Late 8-14 days' THEN 5
        WHEN 'Late 15+ days' THEN 6
    END;

-- Q1, Scheme 2: Raw delivery duration (purchase to delivery date) bucketed,
-- against negative-review rate. Compared against Scheme 1 to determine which
-- delivery signal more strongly predicts dissatisfaction.

WITH delivery_data AS (
    SELECT 
        dr.review_id,
        dr.order_id,
        dr.review_score,
        o.order_delivered_customer_date::date - o.order_purchase_timestamp::date AS delivery_duration
    FROM deduped_reviews dr
    JOIN orders o
        ON dr.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
),
bucketed_orders AS (
    SELECT *,
        CASE
            WHEN delivery_duration <= 7 THEN '0-7 days'
            WHEN delivery_duration BETWEEN 8 AND 14 THEN '8-14 days'
            WHEN delivery_duration BETWEEN 15 AND 21 THEN '15-21 days'
            WHEN delivery_duration BETWEEN 22 AND 30 THEN '22-30 days'
            ELSE '30+ days'
        END AS duration_bucket
    FROM delivery_data
)
SELECT
    duration_bucket,
    COUNT(*) AS order_count,
    ROUND(
        100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS negative_rate
FROM bucketed_orders
GROUP BY duration_bucket
ORDER BY
    CASE duration_bucket
        WHEN '0-7 days' THEN 1
        WHEN '8-14 days' THEN 2
        WHEN '15-21 days' THEN 3
        WHEN '22-30 days' THEN 4
        WHEN '30+ days' THEN 5
    END;

-- Cross-check: does the Step 0 November 2017 / Feb-Mar 2018 spike in negative
-- reviews line up with a higher share of late deliveries in those months?

WITH delivery_data AS (
    SELECT
        dr.order_id,
        dr.review_score,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
        o.order_delivered_customer_date::date
            - o.order_estimated_delivery_date::date AS expectation_gap
    FROM deduped_reviews dr
    JOIN orders o
        ON dr.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)

SELECT
    month,
    COUNT(*) AS reviewed_orders,
    ROUND(
        100.0 * SUM(
            CASE WHEN expectation_gap > 0 THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS late_share,
    ROUND(
        100.0 * SUM(
            CASE WHEN review_score <= 2 THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS negative_rate
FROM delivery_data
GROUP BY month
ORDER BY month;