-- Switch to the staging database
USE adashi_staging;

-- 
-- This CTE aggregates each customer’s savings and investment activity,
-- computes totals, and makes it easy to query the combined results.
--
WITH cross_selling_customer AS (
    SELECT
        c.id AS owner_id,                   -- Unique customer identifier
        c.name AS name,                     -- Customer’s full name
        COUNT(DISTINCT s.id) AS savings_count,     -- Number of distinct savings accounts
        COUNT(DISTINCT p.id) AS investment_count,  -- Number of distinct investment plans
        -- Total amount deposited: sum of confirmed savings + sum of investments
        COALESCE(SUM(s.confirmed_amount), 0)
        + COALESCE(SUM(p.amount), 0) AS total_deposit
    FROM
        customer_plans p
        INNER JOIN customer c
            ON p.owner_id = c.id            -- Link each plan to its customer
        INNER JOIN customer_savings_account s
            ON c.id = s.owner_id            -- Link each savings account to the same customer
    GROUP BY
        c.id,       -- Group by customer to aggregate percustomer metrics
        c.name
)

-- Final select: list each customer with their counts and total deposits,
-- ordered alphabetically by customer name
SELECT
    owner_id,
    name,
    savings_count,
    investment_count,
    total_deposit
FROM
    cross_selling_customer
ORDER BY
    name;
