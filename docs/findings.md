# Findings

## Contents

- [Step 0 — Baseline](#step-0--baseline)
- [Q1 — Delivery Experience](#q1--delivery-experience)
- [Step 0 / Q1 Cross-Check](#step-0--q1-cross-check-does-the-november-2017-spike-connect-to-delivery-lateness)
- [Q2 — Geography](#q2--geography)
- [Q3 — Seller Performance](#q3--seller-performance)
- [Q4 — Product Category](#q4--product-category)
- [Q5 — Payments](#q5--payments)
- [Q5 Cross-Check](#q5-cross-check-does-payment-type-associate-with-late-delivery)
- [Synthesis: Which Factor Should Olist Prioritize?](#synthesis-which-factor-should-olist-prioritize)
- [Recommendation](#recommendation)

## Step 0 — Baseline

The review score distribution, scoped to delivered orders only to match every other step in this analysis, supports the `review_score` ≤ 2 cutoff used throughout. Scores 1 and 2 combine for 12.81% of reviews (9.76% + 3.05%), and score 1 is roughly 3.2 times more common than score 2 — forming a distinct, concentrated negative cluster rather than a broad "somewhat dissatisfied" group. Score 3 accounts for 8.26% of reviews, while scores 4 and 5 together represent 78.93% of all reviews. This clear separation supports using `review_score` ≤ 2 as the definition of negative customer satisfaction, without folding in neutral opinions.

The monthly trend shows the negative-review rate is not stable over time. Two periods stand out: November 2017 (16.57% negative, on 7,238 reviewed orders — the highest-volume month in the dataset) and February–March 2018 (19.38% and 21.17% negative). Both periods combine unusually high order volume with an elevated negative rate, which lines up with Q1's finding that missed delivery dates are the strongest driver of dissatisfaction. A plausible explanation is that demand surges — November includes Black Friday in Brazil — strained delivery capacity during these months. See the cross-check below.

## Q1 — Delivery Experience

The expectation gap (actual vs. estimated delivery date) showed a stronger relationship with negative reviews than raw delivery duration (purchase vs. delivery date). The negative-review rate increased from 9.22% for early deliveries to 80.15% for orders delivered 8–14 days late — a 70.93 percentage-point increase — compared with 7.55% to 64.50% for deliveries taking 0–7 versus 30+ days, a 56.95 percentage-point increase. By this project's evaluation rule (percentage-point swing rather than multiplier), expectation gap is the stronger driver. The two signals are much closer by multiplier (8.7x vs. 8.5x), so this conclusion rests specifically on the percentage-point comparison, not a signal that dominates by every measure.

Although 92.0% of reviewed delivered orders arrived before the estimated delivery date, the small 6.7% that arrived late saw a sharp increase in negative reviews. This suggests that missing the promised delivery date has a greater impact on customer satisfaction than delivery time itself. The negative-review rate levels off after 8–14 days late (80.15% vs. 78.35% for 15+ days), pointing to a likely ceiling effect where dissatisfaction is already near its maximum.

**Business implication:** prioritizing orders at risk of missing their estimated delivery date is likely to have a greater impact than reducing delivery times across all orders.

## Step 0 / Q1 Cross-Check: Does the November 2017 Spike Connect to Delivery Lateness?

The elevated negative rate in November 2017 (12.26% late share) and February–March 2018 (14.02% and 18.65% late share) coincides with a higher share of late deliveries than the surrounding months (typically 2–6% late share). This supports the hypothesis that seasonal demand surges — November includes Black Friday in Brazil — strained delivery capacity and drove both the volume spike and the dissatisfaction spike observed in Step 0, directly reinforcing Q1's finding that missed delivery dates are the primary driver of negative reviews.

*Note: this cross-check's totals are slightly lower than Step 0's original monthly trend (95,824 vs. 95,832 overall — for example, June 2018 shows 6,072 orders here vs. 6,075 in Step 0). This is expected: this query needs `order_delivered_customer_date` to compute the expectation gap, so it applies the NULL-date guard (8 delivered orders excluded) that Step 0's trend doesn't require.*

## Q2 — Geography

The on-time-only baseline negative-review rate was 9.27% across 89,443 reviewed delivered orders, matching exactly the combined "Early" and "On time" population from Q1 — confirming both analyses use the same scope.

No state exceeded the project's 1.5x baseline flag threshold. The highest negative-review rate was 12.99% in AC (1.40x the baseline), followed by AM (11.43%), but all states remained within the normal range. This indicates geography does not have a meaningful independent effect on customer dissatisfaction once delivery timing is controlled for.

**Business implication:** improving customer satisfaction is unlikely to require state-specific strategies. This reinforces Q1's finding that meeting the promised delivery date is a much stronger driver of satisfaction than customer location.

*Note: states with relatively small order volumes (e.g., RR, AP, and AC) should be interpreted with caution, since their negative-review rates are more sensitive to small changes in review counts.*

## Q3 — Seller Performance

To isolate seller performance from delivery delays, the analysis included only reviewed, delivered, on-time orders. Sellers with at least 30 orders were evaluated to ensure more reliable rates. A seller was flagged when its negative-review rate exceeded one standard deviation above the average seller rate.

*Note on baseline definitions: Q2's baseline (9.27%) is the pooled negative-review rate across all on-time orders, weighting every order equally. Q3's average rate (9.8%) is the unweighted mean of each qualifying seller's individual rate, weighting every seller equally regardless of order volume. The two figures are close but intentionally not the same statistic — Q3 needed seller-level rates as its unit of analysis to compute a standard deviation across sellers, which a single pooled rate can't provide.*

Among 593 qualifying sellers, 74 were flagged as "Needs Attention." These 74 sellers are collectively responsible for 7,428 on-time orders — 8.3% of the 89,443-order on-time population — meaning seller-level issues touch a meaningful share of volume, not a negligible edge case. Several high-volume sellers remained well above the expected range, including sellers with 89, 164, 204, 371, 482, and 880 orders, indicating that the elevated rates cannot be explained by small sample sizes alone. This suggests seller-specific factors — such as product quality, packaging, or service — can independently drive dissatisfaction even when deliveries are on time.

**Business implication:** while delivery timing is the strongest overall driver of negative reviews (Q1), a smaller group of consistently underperforming sellers represents a second, targeted improvement opportunity. Monitoring and supporting these sellers is likely to improve satisfaction without requiring platform-wide operational changes.

*Methodology note: the initial analysis used a minimum threshold of 10 orders per seller. Many flagged sellers had very small sample sizes, making their rates highly sensitive to just one or two additional reviews. The threshold was raised to 30 orders, reducing small-sample noise while retaining 593 sellers for analysis.*

## Q4 — Product Category

To check whether specific product categories drive negative reviews on their own, only reviewed, on-time delivered orders were included, consistent with Q2 and Q3. Categories with fewer than 30 orders were removed, since a few very small categories (as few as 12 orders) showed high negative rates that could easily shift with just one or two reviews — the same issue found in Q3. This left 63 qualifying categories. The baseline negative rate is 9.27%, matching Q2 and Q5.

*Note: an earlier version of this baseline was computed at the order-item grain and overstated at 9.55%, since an order touching two categories contributed to the pooled rate twice. It's now collapsed to one row per order before aggregating, consistent with how Q2 and Q5 compute theirs.*

9 categories were flagged as above the 1.5x baseline threshold (13.91%) — one more than under the earlier miscalculated baseline, since `fixed_telephony` (200 orders, 14.00% negative) clears the corrected, lower threshold but not the previous inflated one. The two clearest cases are `fashion_male_clothing` (101 orders, 20.79% negative) and `office_furniture` (1,145 orders, 18.52% negative) — both large enough to trust, and both far above baseline. Other flagged categories include `home_construction` (452 orders, 14.82%), `home_confort` (353 orders, 14.73%), `party_supplies` (38 orders, 15.79%), `construction_tools_safety` (154 orders, 14.94%), `fashio_female_clothing` (34 orders, 14.71%), `audio` (305 orders, 14.43%), and `fixed_telephony` (200 orders, 14.00%) — so the pattern appears across several categories, not just one outlier.

**Business implication:** some product categories create more dissatisfaction than others, even when delivery is on time. This points to product quality or a mismatch between what's advertised and what's delivered as a second real issue, separate from delivery timing and seller performance, worth a closer look at product descriptions or return reasons for these categories.

*Methodology note: the same small-sample problem found in Q3 also showed up in Q4 — a few categories with only 12–20 orders reached high rates that likely came from chance rather than a real pattern. To stay consistent with Q3, the minimum order count was raised to 30, removing only 3 very small categories out of 66.*

## Q5 — Payments

Before writing the main query, `payment_sequential` was checked, since the plan assumed `payment_sequential = 1` would identify each order's main payment. This didn't hold for 79 delivered orders, where payment records started at sequential 2 (or 2, then 3) instead of 1. Only 1 order had no payment record at all. This looks like a data-entry inconsistency rather than a real data gap, so the primary payment was redefined as the earliest available payment per order, using `ROW_NUMBER()` ordered by `payment_sequential`.

An initial exploratory step checked whether payment method was worth investigating at all:
- Payment method split: Credit Card 77.02%, Boleto 19.89%, Voucher 1.55%, Debit Card 1.54%
- Raw negative-review rate (before controlling for delivery): Voucher 18.60%, Credit Card 14.71%, Boleto 14.42%, Debit Card 13.02%

Voucher stood out as clearly higher than the rest, so it was investigated further. Using the same on-time-only method as Q2–Q4, the controlled negative-review rates were: Voucher 10.95%, Credit Card 9.26%, Boleto 9.23%, Debit Card 8.57%, against a baseline of 9.27%. None of the payment methods exceeded the 1.5x anomaly threshold.

In plain terms: vouchers looked riskier at first — 18.60% negative reviews against a blended baseline in the 12–15% range across payment types. Once only on-time orders are compared, that gap narrows substantially (10.95% vs. a 9.27% baseline) but doesn't fully close — voucher orders remain at 1.18x the baseline even with delivery timing controlled for. The obvious explanation — that voucher orders are simply more often late — was tested directly in the cross-check below and is not supported: voucher had the second-lowest late-delivery share of the four payment types. What explains the remaining gap isn't identified by this analysis. Voucher is also the smallest payment-type group by a wide margin (roughly 1.5% of orders), so some of this may be small-sample volatility rather than a systematic driver. This is reported as an open question, not a resolved one.

**Business implication:** Olist doesn't need a payment-specific strategy to reduce negative reviews — no payment method exceeded the anomaly threshold once delivery timing was controlled for. Voucher's mild, unresolved elevation is worth a lightweight follow-up if voucher volume grows, but doesn't justify action on the evidence currently available.

## Q5 Cross-Check: Does Payment Type Associate With Late Delivery?

This result does not support the mechanism proposed in the Q5 findings above. Voucher has the second-lowest late-delivery share of the four payment types (5.81%) — below boleto (7.32%) and credit card (6.68%), and only slightly above debit card (5.32%). Voucher orders are not disproportionately late. Whatever is driving voucher's elevated raw negative-review rate (18.60%) and its mildly-elevated controlled rate (10.95% vs. a 9.27% baseline), it is not simply "voucher orders arrive late more often."

*Note: this cross-check doesn't require a review to exist (it measures delivery timing only), so its population (96,469 orders) is larger than Q5's review-based totals (roughly 95,823) — the difference matches the 646 delivered orders with no review row.*

What remains open: voucher accounts for only 1,498 orders — the smallest of the four groups by a wide margin, roughly 1.5% of the payment-tagged population — so part of its elevated rate in both the raw and controlled comparisons may reflect small-sample volatility rather than a confirmed, systematic pattern. This is reported as an open question rather than something resolved by this analysis.

## Synthesis: Which Factor Should Olist Prioritize?

### Answering the Main Business Question

Across Step 0 through Q5, one factor clearly dominates: missing the estimated delivery date. It has the strongest observed effect, the clearest operational actionability, and a business impact disproportionate to its size. Two secondary, independently supported drivers remain after controlling for delivery timing — seller performance and a defined set of product categories — while two factors that initially appeared plausible were not supported by the evidence.

### Ranking Framework

Ranked by strength of effect, orders affected, and actionability.

| Factor | Strength | Orders affected | Actionable? | Verdict |
|---|---|---|---|---|
| Delivery timing (Q1) | 9.22% → 80.15% negative rate (70.93 pp increase) | 6.7% of orders, but ~32.5% of all negative reviews | High — Olist controls delivery estimates and carrier capacity | Fix first |
| Seller performance (Q3) | Negative-review rates up to 53.93% (threshold: 16.1%) | 7,428 orders (8.3% of on-time volume) | Moderate — targeted seller management rather than platform-wide changes | Fix second |
| Product category (Q4) | Negative-review rates up to 20.79% (threshold: 13.91%) | 2,782 orders (3.11% of on-time volume) | Moderate — category-specific investigation | Fix third |
| Geography (Q2) | Highest state (AC): 12.99%, below the 13.91% threshold | — | — | Ruled out |
| Payment type (Q5) | Highest (Voucher): 10.95%, below the 13.91% threshold | ~1,498 orders (smallest payment group) | Unclear, low confidence | Ruled out / open question |

### Why Delivery Timing Comes First

Orders delivered late make up just 6.7% of volume, but account for roughly 32.5% of all negative reviews across the dataset — a concentration of harm nearly five times larger than their share of order volume would suggest. This is supported by the Step 0/Q1 cross-check: the November 2017 and February–March 2018 spikes in negative reviews occurred alongside unusually high shares of late deliveries. It is also the most operationally actionable lever identified in this analysis — Olist does not need to diagnose individual sellers or categories to improve this outcome; improving delivery-estimate accuracy and increasing logistics capacity during peak-demand periods directly targets the strongest driver identified.

By this project's evaluation rule (percentage-point increase rather than multiplier), expectation gap is a stronger predictor of dissatisfaction than raw delivery duration. The two measures are much closer by multiplier (8.7x vs. 8.5x), so this conclusion reflects the evaluation framework defined for this project rather than a signal that dominates by every possible measure.

### Why Sellers Come Second, Categories Third

Both seller performance and product category remain independently associated with customer dissatisfaction after controlling for delivery timing, showing that neither pattern is simply a consequence of late deliveries.

Seller performance ranks above product category primarily because it affects a larger share of orders (8.3% vs. 3.11% of the on-time population), while also showing substantially higher negative-review rates among the flagged sellers. The 74 flagged sellers account for 7,428 on-time orders — a meaningful improvement opportunity through targeted monitoring and support. Product category remains an important but narrower opportunity, with nine categories exceeding the predefined threshold. In particular, `fashion_male_clothing` and `office_furniture` combine elevated negative-review rates (20.79% and 18.52%) with sufficient order volume (101 and 1,145 orders) to support further investigation.

### Why Geography and Payment Type Are Ruled Out

Q2 found that no state exceeded the project's flag threshold, even at its highest observed rate (AC: 12.99% vs. a 13.91% threshold). Geography therefore provides little independent explanatory power once delivery performance is controlled for.

Q5 produced a more nuanced result. Voucher payments showed a mild elevation (1.18x the on-time baseline) that remained after controlling for delivery timing. However, the follow-up cross-check showed voucher orders are not disproportionately late, ruling out the most obvious explanation. At the same time, voucher represents the smallest payment group by a wide margin, making the observed difference difficult to interpret confidently. The appropriate conclusion is that voucher remains an open question rather than a confirmed business driver.

## Recommendation

1. **Improve delivery-estimate accuracy and surge-period logistics capacity.** This is the highest-leverage intervention identified in the project and addresses the factor with by far the strongest association with negative reviews.
2. **Monitor and support the 74 flagged sellers.** These sellers account for 8.3% of on-time order volume and continue to generate unusually high negative-review rates even after removing the effect of delivery delays.
3. **Investigate the nine flagged product categories**, beginning with `fashion_male_clothing` and `office_furniture`, where high negative-review rates are supported by sufficient order volume.
4. **Do not prioritize geography- or payment-specific initiatives** based on the current evidence. Voucher payment behavior is worth revisiting if its share of orders increases, but the present analysis does not justify operational changes.

*This ranking reflects observed association, not confirmed causation, and should be read with the caveat that review score is itself known to weight delivery experience heavily — the strength of delivery's rank here may partly reflect what the metric captures well, not the full scope of its business impact.*

Overall, the evidence indicates that customer dissatisfaction on Olist is strongly associated with failures to meet promised delivery dates. Once delivery performance is controlled for, seller performance emerges as the strongest secondary driver, followed by a small number of product categories, while geography and payment method contribute little independent explanatory value.
