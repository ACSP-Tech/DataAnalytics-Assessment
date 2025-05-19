-- Switch to the staging database
USE adashi_staging;
-- 
-- Compute, categorize, and summarize customer transaction frequencies per month
--
WITH tx_per_customer_month AS (
	-- Step 1: Count valid savings transactions per customer each month
    SELECT 
        s.owner_id,
        DATE_FORMAT(s.transaction_date, '%Y-%m') AS month, -- YYYY‑MM format
        COUNT(*) AS tx_count
    FROM 
		customer_savings_account s
    WHERE 
		-- Exclude failed, abandoned, reversed, pending, or limited transactions
		s.transaction_status NOT REGEXP 'failed|abandoned|reversal|cannot|limit|pending'
    GROUP BY 
		s.owner_id, 
        month
),

avg_per_user AS (
    -- Step 2: Compute each customer’s average transactions per month
    SELECT
        owner_id,
        AVG(tx_count) AS avg_tx_per_month
    FROM
		tx_per_customer_month
    GROUP BY
		owner_id
),

categorized_users AS (
    -- Step 3: Bucket customers into frequency categories
    SELECT
        CASE
            WHEN avg_tx_per_month >= 10 THEN 'High Frequency'
            WHEN avg_tx_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category,
        COUNT(*) AS customer_count,
        ROUND(AVG(avg_tx_per_month), 1) AS avg_transactions_per_month
    FROM 
		avg_per_user
    GROUP BY
		frequency_category
)

-- Final output: display counts and average tx for each frequency bucket,
-- ordered High → Medium → Low
SELECT *
FROM 
	categorized_users
ORDER BY 
	FIELD(frequency_category, 'High Frequency','Medium Frequency','Low Frequency');