# Methodology

## Project Framing

Before defining the business questions, the repeat purchase rate was checked to decide what the analysis should focus on:

```sql
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(*) AS total_orders
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT ROUND(
    COUNT(CASE WHEN total_orders >= 2 THEN 1 END)::numeric
    * 100 / COUNT(*),
    2
) AS repeat_purchase_rate
FROM customer_orders;
```

The repeat purchase rate came out to roughly 3% of customers. This was used as an initial framing analysis rather than a core business question. Because so few customers place more than one order, customer lifetime value, retention, and churn were ruled out as a framing for this project. Instead, the analysis focuses on customer satisfaction on what is, for most customers, their only purchase.

## Main Business Question

What causes negative customer experiences (`review_score` ≤ 2) on Olist, and which factor should the business prioritize to reduce them?

## Outcome Metric

Every question in this project uses the same measure: **negative-review rate** — the percentage of orders with a `review_score` of 2 or less.

## Sub-Questions

- **Step 0 — Baseline:** Is the "2 or less" cutoff a good choice, and how does the negative-review rate change over time? This establishes the base number everything else is compared against.
- **Q1 — Delivery Experience:** Does the gap between the promised and actual delivery date predict negative reviews more strongly than raw delivery duration? This identifies which delivery signal actually drives dissatisfaction.
- **Q2 — Geography:** Looking only at orders delivered on time, do some states still show more negative reviews? This would point to a regional problem rather than a delivery problem.
- **Q3 — Sellers:** Looking only at orders delivered on time, and only at sellers with enough on-time orders, do some sellers still show more negative reviews? This would indicate a seller performance problem rather than a delivery problem.
- **Q4 — Product Category:** Looking only at orders delivered on time, do some product categories still show more negative reviews? This could point to a product quality or expectation issue.
- - **Q5 — Payments:** Does payment type relate to negative-review rate on its own, or is any apparent effect actually explained by delivery delay?

Delivery performance is investigated separately in Q1 because it is expected to be one of the strongest influences on customer satisfaction. To isolate other sources of dissatisfaction, Q2 through Q4 intentionally analyze only on-time deliveries, reducing the influence of logistics so that geographic, seller, and product-related patterns can be examined more independently.

**Synthesis** (prose, not a query): after Q1 through Q5 produce their results, the findings are reasoned through in plain writing to determine which factor Olist should address first, based on how strong the effect is, how many orders it affects, and how actionable it is.

## Implementation Notes

- **NULL-date guard:** 8 delivered orders have a NULL `order_delivered_customer_date` and are excluded using `WHERE order_delivered_customer_date IS NOT NULL`. This applies to any step performing delivery-date arithmetic — Q1, the on-time predicate used in Q2 through Q4, and Steps 2 and 3 of Q5. It does not apply to Step 0, which aggregates by `order_purchase_timestamp`, or to Q5's Step 1, which only validates `payment_sequential` and never touches delivery dates.
- **On-time predicate** (defined once and reused by Q2 through Q4 and Q5 Step 2): `order_delivered_customer_date::date <= order_estimated_delivery_date`. The `::date` cast matters, since `order_delivered_customer_date` is a `TIMESTAMP` and `order_estimated_delivery_date` is a `DATE` — casting before comparing avoids inconsistent day-boundary behavior.
- Each Q1 through Q5 query reports two things: how large the difference is (severity) and how many orders it affects (percentage) — both are needed for the synthesis.
- Q4 uses `COALESCE` to handle two known issues: 623 products (1.9%) with no category, and 2 categories that had no English name before the translation table was corrected.
- Step 0's monthly trend uses a full list of months (via `generate_series()`) so that a zero-order month doesn't simply disappear from the results.
- **Evaluation rule for comparing delivery signals (Q1):** the stronger driver is defined as the one with the larger percentage-point increase from its lowest to its highest bucket, not the larger multiplier. Percentage points reflect the actual share of orders shifting from satisfied to dissatisfied, which is a more directly business-relevant measure than a ratio computed from two different starting baselines.

## Known Limitations

- This analysis shows connection, not proof of cause — this applies especially to the comparison between Q5 and Q1.
- Review score depends heavily on delivery experience. Results should be read as "best explains review score," not as "total real business impact."
- Q2, Q3, and Q4 each cover only the on-time-filtered subset of their dimension — states, sellers, or categories that are otherwise fine but still show elevated negative reviews. None of these results claims to describe the full effect of geography, seller performance, or product category — only the part that is independent of delivery lateness.
- The analysis is scoped to delivered orders only. Canceled or undelivered orders — a separate and likely more severe source of dissatisfaction — are out of scope for this project.
- Q3 uses a statistically-derived threshold (mean plus one standard deviation across seller-level rates), while Q2 and Q4 use a simpler fixed 1.5x baseline multiplier. The heavier technique was applied once as the project's showcase method rather than repeated for every question. Both are documented judgment calls, not formal statistical tests.
- Orders containing items from multiple sellers or multiple product categories are counted once for each seller or category they include in Q3 and Q4. As a result, a single review may contribute to more than one seller or category summary.
