-- Deduplicates order_reviews (some orders have >1 review row, e.g. a resubmitted
-- or updated review). Keeps one row per order_id — the review with the latest
-- review_answer_timestamp. Referenced by every query below rather than
-- repeating this logic each time.

CREATE VIEW deduped_reviews AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY review_answer_timestamp DESC NULLS LAST
           ) AS rn
    FROM order_reviews
) t
WHERE rn = 1;