WITH rfm_calc AS (
    SELECT 
        u.user_id,
        DATE_DIFF(CURRENT_TIMESTAMP(), MAX(u.last_active_at), DAY) AS recency,
        COUNT(t.transaction_id) AS frequency,
        ROUND(SUM(t.transaction_value)) AS monetary
    FROM `saas_production.users` u
    INNER JOIN `saas_production.transaction_logs` t
        ON u.user_id = t.user_id
    GROUP BY u.user_id 
),
rfm_quant AS (
    SELECT 
        user_id,
        NTILE(4) OVER (ORDER BY recency DESC) AS recency_quantile,
        NTILE(4) OVER (ORDER BY frequency) AS frequency_quantile,
        NTILE(4) OVER (ORDER BY monetary) AS monetary_quantile
    FROM rfm_calc 
)
SELECT 
    user_id,
    recency_quantile, 
    frequency_quantile, 
    monetary_quantile,
    CASE
        WHEN monetary_quantile >= 3 AND frequency_quantile >= 3 THEN 'High Value Customer'
        WHEN frequency_quantile >= 3 THEN 'Loyal Customer'
        WHEN recency_quantile <= 1 THEN 'At Risk Customer'
        WHEN recency_quantile >= 3 THEN 'Persuadable Customer'
        ELSE 'Standard'
    END AS customer_segment
FROM rfm_quant;
