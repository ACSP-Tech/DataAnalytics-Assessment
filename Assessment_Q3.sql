-- Switch to the staging database
USE adashi_staging;

WITH
  -- 1) Identify each savings account’s most recent successful transaction
  savings_last AS (
    SELECT
      s.plan_id AS plan_id,		-- Savings plan identifier
      s.owner_id AS owner_id,	-- Customer identifier	
      'Savings' AS type,		 -- Label the record type
      MAX(s.transaction_date) AS last_transaction_date 		-- Most recent valid deposit
    FROM 
		customer_savings_account s
	WHERE
		s.transaction_status NOT REGEXP 'failed|abandoned|reversal|cannot|limit|pending'
    GROUP BY
		s.plan_id,
        s.owner_id
  ),
  
  -- 2) Identify each investment plan’s most recent returns date
  plans_last AS (
    SELECT
      p.id AS plan_id,			-- Investment plan identifier
      p.owner_id AS owner_id,	-- Customer identifier
      'Investment'  AS type,	-- Label the record type
	MAX(p.last_returns_date) AS last_transaction_date	-- Most recent returns posting
    FROM customer_plans p	
    WHERE p.is_deleted = 0           -- Only include active (not deleted) plans
    GROUP BY p.id, p.owner_id		 
  ),

-- 3) Combine savings and investment records into a unified list
  all_accounts AS (
    SELECT * FROM savings_last
    UNION ALL
    SELECT * FROM plans_last
  )

-- 4) Flag accounts with no activity in the past 365 days as of reference date
SELECT
  plan_id,
  owner_id,
  type,
  last_transaction_date,
  DATEDIFF('2023-11-10', last_transaction_date) AS inactivity_days  -- Days since last activity, according to the sample of 92 days from 2023-08-10
FROM all_accounts
WHERE DATEDIFF('2023-11-10', last_transaction_date) > 365			-- Inactive for more than one year
ORDER BY inactivity_days DESC;										-- Longest inactive first
