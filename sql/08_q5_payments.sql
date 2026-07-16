-- Step 1: Validate the payment_sequential assumption

-- Check whether payment_sequential = 1 reliably identifies each order's primary payment
SELECT COUNT(DISTINCT o.order_id) AS orders_missing_seq_1
FROM orders o
WHERE o.order_status = 'delivered'
  AND NOT EXISTS (
      SELECT 1
      FROM order_payments op
      WHERE op.order_id = o.order_id
        AND op.payment_sequential = 1
  );

-- Check whether any delivered orders have no payment record at all
SELECT COUNT(*) AS orders_no_payment
FROM orders o
WHERE o.order_status = 'delivered'
  AND NOT EXISTS (
      SELECT 1
      FROM order_payments op
      WHERE op.order_id = o.order_id
  );


-- Step 2: Exploratory Data Analysis (EDA)
-- The primary_payment / payment_data CTEs are repeated for each sub-query
-- below (2a, 2b, 2c) because a CTE only stays in scope for the single
-- statement it's attached to -- each needs its own WITH clause to run
-- independently.

-- 2a. Payment method distribution
WITH primary_payment AS (
    SELECT
        order_id,
        payment_type,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY payment_sequential
        ) AS rn
    FROM order_payments
),
payment_data AS (
    SELECT
        dr.order_id,
        dr.review_score,
        pp.payment_type,
        o.order_delivered_customer_date::date
            - o.order_estimated_delivery_date::date AS expectation_gap
    FROM deduped_reviews dr
    JOIN orders o
        ON dr.order_id = o.order_id
    JOIN primary_payment pp
        ON dr.order_id = pp.order_id
       AND pp.rn = 1
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    payment_type,
    COUNT(*) AS reviewed_orders,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_orders
FROM payment_data
GROUP BY payment_type
ORDER BY reviewed_orders DESC;

-- 2b. Raw negative review rate (before controlling for delivery)
WITH primary_payment AS (
    SELECT
        order_id,
        payment_type,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY payment_sequential
        ) AS rn
    FROM order_payments
),
payment_data AS (
    SELECT
        dr.order_id,
        dr.review_score,
        pp.payment_type,
        o.order_delivered_customer_date::date
            - o.order_estimated_delivery_date::date AS expectation_gap
    FROM deduped_reviews dr
    JOIN orders o
        ON dr.order_id = o.order_id
    JOIN primary_payment pp
        ON dr.order_id = pp.order_id
       AND pp.rn = 1
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    payment_type,
    COUNT(*) AS reviewed_orders,
    ROUND(
        100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS negative_rate
FROM payment_data
GROUP BY payment_type
ORDER BY negative_rate DESC;

-- 2c. Initial screen: average delivery expectation gap
WITH primary_payment AS (
    SELECT
        order_id,
        payment_type,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY payment_sequential
        ) AS rn
    FROM order_payments
),
payment_data AS (
    SELECT
        dr.order_id,
        dr.review_score,
        pp.payment_type,
        o.order_delivered_customer_date::date
            - o.order_estimated_delivery_date::date AS expectation_gap
    FROM deduped_reviews dr
    JOIN orders o
        ON dr.order_id = o.order_id
    JOIN primary_payment pp
        ON dr.order_id = pp.order_id
       AND pp.rn = 1
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    payment_type,
    ROUND(AVG(expectation_gap), 2) AS avg_expectation_gap
FROM payment_data
GROUP BY payment_type
ORDER BY avg_expectation_gap;


-- Step 3: Controlled comparison (on-time deliveries only)

WITH primary_payment AS (
    SELECT
        order_id,
        payment_type,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY payment_sequential
        ) AS rn
FROM order_payments
),
on_time_payment_data AS (
    SELECT
        dr.order_id,
        dr.review_score,
        pp.payment_type
    FROM deduped_reviews dr
    JOIN orders o
        ON dr.order_id = o.order_id
    JOIN primary_payment pp
        ON dr.order_id = pp.order_id
       AND pp.rn = 1
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_delivered_customer_date::date
            <= o.order_estimated_delivery_date::date
),
baseline AS (
    SELECT
        ROUND(
            100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END)
            / COUNT(*),
            2
        ) AS baseline_rate
    FROM on_time_payment_data
)
SELECT
    payment_type,
    COUNT(*) AS reviewed_orders,
    ROUND(
        100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS negative_rate,
    b.baseline_rate,
    CASE
        WHEN ROUND(
                100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END)
                / COUNT(*),
                2
             ) > b.baseline_rate * 1.5
        THEN 'Above threshold'
        ELSE 'Normal'
    END AS status
FROM on_time_payment_data
CROSS JOIN baseline b
GROUP BY payment_type, b.baseline_rate
ORDER BY negative_rate DESC;


-- Cross-check: does payment type associate with late delivery on its own,
-- independent of review outcome? (Tests the mechanism behind Q5's voucher
-- finding above.)

WITH primary_payment AS (
    SELECT
        order_id,
        payment_type,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY payment_sequential
        ) AS rn
    FROM order_payments
),
payment_delivery AS (
    SELECT
        pp.payment_type,
        o.order_delivered_customer_date::date
            - o.order_estimated_delivery_date::date AS expectation_gap
    FROM orders o
    JOIN primary_payment pp
        ON o.order_id = pp.order_id
       AND pp.rn = 1
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    payment_type,
    COUNT(*) AS total_orders,
    ROUND(
        100.0 * SUM(CASE WHEN expectation_gap > 0 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS late_share
FROM payment_delivery
GROUP BY payment_type
ORDER BY late_share DESC;