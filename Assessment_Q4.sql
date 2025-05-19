-- Switch to the staging database
USE adashi_staging;

WITH
  -- 1) Calculate each active customer's tenure in months
  tenure AS (
    SELECT
      c.id AS customer_id,				 -- Customer identifier
      c.name AS name,					 -- Customer’s full name
      TIMESTAMPDIFF(
		MONTH,
        c.date_joined,
        '2023-11-10'
        ) AS tenure_months 		-- Months since account creation
    FROM
		customer c
    WHERE
		c.is_active = 1 		-- Only active customers
		AND c.is_account_deleted = 0  -- Exclude deleted accounts
  ),

  -- 2) Aggregate each customer’s valid savings transactions
  transactions AS (
    SELECT
      s.owner_id AS customer_id,			-- Matches to tenure.customer_id
      COUNT(*) AS total_transactions,		-- Total number of valid transactions		
      AVG(s.confirmed_amount) AS avg_transaction_value		-- Average transaction amount
    FROM
		customer_savings_account s
    WHERE
		-- Exclude failed, abandoned, reversed, pending, or limited transactions
		s.transaction_status NOT REGEXP 'failed|abandoned|reversal|cannot|limit|pending'
    GROUP BY
		s.owner_id
  ),

  -- 3) Combine tenure and transaction data, then compute estimated CLV
  clv_calc AS (
    SELECT
      t.customer_id,
      t.name,
      t.tenure_months,
      COALESCE(tx.total_transactions, 0) AS total_transactions,		-- Zero if no transactions
      -- Profit per transaction: 0.1% of the average transaction amount
      COALESCE(tx.avg_transaction_value, 0) / 100 * 0.001 AS profit_per_tx,
      -- Estimated CLV formula:
      -- (Avg transactions per month × 12 months) × profit per transaction
      ROUND(
        (COALESCE(tx.total_transactions, 0) / NULLIF(t.tenure_months, 0))
        * 12
        * (COALESCE(tx.avg_transaction_value, 0) / 100 * 0.001),
      2)                                       							-- Rounded to 2 decimal places
      AS estimated_clv
    FROM 
		tenure t
    LEFT JOIN transactions tx
      ON t.customer_id = tx.customer_id 		-- Include customers with zero tx
  )

-- 4) Final output: list customers ordered by highest estimated CLV
SELECT
  customer_id,
  name,
  tenure_months,
  total_transactions,
  estimated_clv
FROM clv_calc
ORDER BY estimated_clv DESC;