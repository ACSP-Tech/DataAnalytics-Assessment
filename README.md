# DataAnalytics-Assessment
Data analysis SQL scripts for assessment project

# Per-Question Explanations

# Question 1 : Write a query to find customers with at least one funded savings plan AND one funded investment plan, sorted by total deposits.
my approach was breaking doen the above query into smaller steps and working with them in a logical way, so i had;
i) how do I uniquely identify a customer where I dentified each customer (owner_id, name)
ii) Then I Counts how many savings accounts (savings_count) and how many investment plans (investment_count) they hold.
iii) Calculates the total amount deposited by summing: The confirmed_amount from all their savings accounts. The amount from all their investment plans.
iv) I choose a inner join to ensure because I want to focus on customers who actively hold both savings and investment products—i.e., true targets for cross‑selling. An INNER JOIN drops any customer lacking at least one matching row in either customer_plans or customer_savings_account.
v) i used a final SELECT to pull from the CTE and orders by name for easy scanning, presentation or export

# Question 2: Calculate the average number of transactions per customer per month and categorize them
in order to achieve the above, I followed the steps below;
i)tx_per_customer_month CTE: Here I Counts all valid transactions per customer each month and use NOT REGEXP to filter out unsuccessful or non‑posting statuses (e.g., “failed”, “pending”).
ii)avg_per_user CTE: this common table expression calculates the average number of valid transactions per month for each customer.
iii)categorized_users CTE: Buckets customers into three frequency groups based on their personal monthly averages: High Frequency: >= 10 tx/month, Medium Frequency: 3–9 tx/month, Low Frequency: < 3 tx/month
Then, Summarizes the number of customers in each bucket and the overall average tx/month within the bucket.
iv )Finally, the outer SELECT retrieves these buckets in a logical order (High → Medium → Low), giving a clear, single‑query view of customer engagement levels for reporting or targeted marketing.

# Question 3: Find all active accounts (savings or investments) with no transactions in the last 1 year (365 days)
I approach the question with the following steps;
i) savings_last CTE: this scans the customer_savings_account table for non‑failed transactions. Groups by plan_id and owner_id to find each account’s most recent valid deposit date.
ii) plans_last CTE: this scans the customer_plans table for active (non‑deleted) investment plans. Groups by id and owner_id to find each plan’s most recent returns date.
iii) all_accounts CTE: here, I merge the two CTE tables using UNION ALL so all account types appear in one list.
iv) Final Selection: I calculates the number of days since each account’s last transaction using DATEDIFF.Filters for records where that difference exceeds 365 days, flagging them as inactive. Orders results by inactivity_days in descending order to prioritize the longest‑dormant accounts
note: from the sample picture, I observed that there was 92 inactive days from 2023-08-10. I mirror this date and used it as a bench-mark.

# Question 4: For each customer, assuming the profit_per_transaction is 0.1% of the transaction value, calculate Account tenure (months since signup), Total transactions, Estimated CLV (Assume: CLV = (total_transactions / tenure) * 12 * avg_profit_per_transaction), Order by estimated CLV from highest to lowest
i)Tenure Calculation: I calculates how many months each customer has been with the company (tenure_months) using TIMESTAMPDIFF.
ii)Transaction Aggregation: here, I counts all valid savings transactions (total_transactions) and computes the average amount per transaction (avg_transaction_value), filtering out any failed or non-posting statuses.
iii)CLV Computation:I use profit per transaction as 0.1% (0.001) of the average transaction value. Calculates the annualized transaction frequency by dividing total transactions by tenure in months and multiplying by 12. Multiplies the annualized frequency by profit per transaction, then rounds the result to two decimal places.
iv)Joining & Ordering: I use a LEFT JOIN to ensure customers with no transactions still appear with a CLV of zero. Orders the final list by estimated_clv in descending order to highlight the highest-value customers.


# Challenges
The challenges faced evolve around the data quality assessment issues, and complex business logic interpretation. Key issues included:

# 1. Data Inconsistencies and Missing Values: 
The following missing values were found in the four tables, and stated are the approach taken to resolve them and the rationale;

# a. savings_savingsaccount table - total rows of 163736
  i) saving_id - 225 missing value | updated and set as unknown where NULL | rationale:  below 1% of the values in the column are unknow.
  ii) Verification_transaction_date - 124076 NULL values| dropped column | above 75% of the column values are missing.
  iii) card_billed_id - 5144 null values | Turn off foreign key enforcement and  Retained the column with a placeholder(unknown) to 
       preserve relational integrity
  iv) gateway_response_message- 2,605 NULL values and 859 empty strings | Action: Replaced all NULLs and empty strings with 'Unknown' | 
      Rationale: Ensured consistency and readability in downstream analysis.
  v) donor_id - 163,655 entries | Action: Turned off foreign key enforcement, altered the table to drop the foreign key constraint and the column itself | Rationale: The column was redundant for the current scope of analysis and removed to reduce clutter.
  vi) payment_gateway - 9,618 NULL values and 1,181 empty strings | Action: Replaced all missing and empty values with 'Unknown' | Rationale: Preserved the column for reporting while handling inconsistencies.
  vii) source_bank_account - 163,035 missing or irrelevant entries | Action: Dropped the column | Rationale: High proportion of missing values rendered the column unusable.
  viii) 15,559 missing values | Action: Updated missing values with 'NA' | Rationale: Maintained data integrity by using a standard placeholder.

  # b. withdrawals_withdrawal - total rows of 1308
  i) bank_id - 87 missing values (range of values: 1–536) | Replaced NULL values with default 0 | Assigned a default to retain the column while indicating unlinked records.
  ii) gateway - 113 NULL values - Action: Replaced missing values with 'Unknown' - Rationale: Ensured consistency for analytical processing.
  iii) gateway_response - 1,084 NULL values - Action: Replaced missing values with 'Unknown' -  Rationale: Standardized the column for easier downstream handling.
  iv) session_id - 1,154 NULL values and 154 empty strings | Action: Dropped the column | Rationale: Excessive missingness rendered the column unusable.
  v) payment_id - 1,308 entries (entire column) |  Action: Dropped the column | Rationale: Fully populated but deemed irrelevant to current analysis.
  vi) withdrawal_intent_id - 925 missing values (range of valid values: 1–325) | Action: Turned off foreign key enforcement and replaced missing values with default 0 | Rationale: Preserved table structure and flagged unmatched records.

# c. plans_plan  - Total Rows: 9,641
i)start_date-  32 missing values | Action: Replaced with default date '1900-01-01' | Rationale: Placeholder used to indicate missing historical dates.
ii)last_charge_date 6,272 missing values | Action: Replaced with default date '1900-01-01' | Rationale: Maintained consistency in date formatting for temporal analysis.
iii)next_charge_date - 8,892 missing values | Action: Replaced with default date '1900-01-01' | Rationale: Ensured structural integrity while indicating absent future change records.
iv)withdrawal_date -  8,825 missing values | Action: Replaced with default date '1900-01-01' | Rationale: Standardized missing values to a known default.
v)debit_card - 4,044 NULL values | Action: Updated with 'Unknown' |  Rationale: Filled missing entries to ensure consistency in card-related analysis.
vi)plan_group_id - 7,641 values (foreign key) | Action: Updated missing values with 'Unknown' | Rationale: Prevented relational conflicts while keeping column functional.
vii) purchase_fund_id -  8,414 values (foreign key) | Action: Dropped the column | Rationale: Column was no longer required and had limited analytical value.
viii)donation_expiry_date - 9,601 missing values | Action: Dropped the column | Rationale: Excessive nullity made the column unusable.
ix)donation_link - 9,601 missing values | Action: Dropped the column | Rationale: Lacked meaningful content for analysis.
x)link_code - 9,601 missing values | Action: Dropped the column | Rationale: Column had limited analytical relevance
xi)usd_index_id - 9,603 missing values | Action: Dropped the column | Rationale: Largely null and not essential to analysis.
xii)recurrence -  7,414 NULL values | Action: Replaced with 'Unknown' | Rationale: Maintained uniformity while indicating missing schedule info
xiii)portfolio_holding_id - 9,419 values (foreign key) | Action: Dropped the column | Rationale: Dropped due to irrelevance in the current analytical scope.
xiv)present_id - 9,075 values (foreign key) | Action: Dropped the column | Rationale: Considered redundant for the current analysis.
xv)donation_description - 9,601 empty rows and generic placeholder text (e.g., “This is the description of the donation”) | Action: Dropped the column | Rationale: Text lacked substantive value and consistency.

# d. user_customuser Table – Total Rows: 1,867
A comprehensive data quality assessment and transformation was carried out on the user_customuser table. The key actions and justifications are summarized below:

# i) Dropped Columns
The following columns were removed due to high null values, limited analytical value, or redundancy:

proposed_deletion_date (1,864 nulls)

proposed_enablement_date (1,867 nulls)

reason_for_deletion (1,858 nulls)

invited_code (1,711 nulls)

disabled_at (1,835 nulls)

enabled_at (1,852 nulls)

last_password_change (1,824 nulls)

tier_id (1,115 nulls)

ambassador_profile_id (393 nulls)

date_of_birth (1,003 nulls)

current_longitude (1,435 nulls)

current_laitude (1,435 nulls)

account_campaign (1,820 nulls)

account_medium (1,505 nulls)

address_city (1,802 nulls)

address_country (1,830 nulls)

address_state (1,814 nulls)

address_street (1,802 nulls)

# ii) Columns Updated with Default or Placeholder Values
To ensure data completeness and avoid integrity issues, the following updates were made:

Nulls replaced with 'Unknown' in:

sign_up_device (554 nulls)

postal_address (1,784 nulls)

pin (353 nulls)

phone_number (152 nulls)

first_name (44 nulls)

last_name (44 nulls)

authy_id (1,813 nulls)

avatar_firebase_reference (1,813 nulls)

avatar_url (1,755 nulls)

avatar_local_uri (1,810 nulls)

# iii) gender_id and tier_id: All NULL values were set to default value 0 to ensure referential and logical consistency.

# iv) last_login: NULL values were replaced with values from the created_on column, assuming account creation time as the first login when login history is missing.


# v) name: A new values was generated by concatenating first_name and last_name to ensure a standardized and unified user identifier.

# 2 standardize column names to customer, customer_plans, customer_savings_account, customer_withdrawals 
