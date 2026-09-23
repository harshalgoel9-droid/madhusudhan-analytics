-- =====================================================================
-- Madhusudan Ghee - the ten business questions
-- MySQL 8.0
-- =====================================================================
-- Run this last. Every query reads from v_sales.
--
-- The owner looks at one number each month: revenue. It has gone up
-- every year. These queries test whether that means what he thinks it
-- means.
--
-- The order is an argument, not a list:
--   Q1-Q2   Is the business growing, and growing on what?
--   Q3-Q5   If not on volume, what are the customers doing?
--   Q6-Q7   What do we sell, and when?
--   Q8-Q10  Who sells it, and how exposed are we?
--
-- Window functions need MySQL 8.0 or later. On 5.7 they will not run.
-- =====================================================================

USE ghee_analytics;


-- ---------------------------------------------------------------------
-- Q1. How big is the business, and is it growing?
-- ---------------------------------------------------------------------
-- Revenue and volume are reported side by side from the first query.
-- That pairing is what the whole analysis turns on.
SELECT
    fy,
    COUNT(DISTINCT invoice_no)  AS invoices,
    SUM(cartons)                AS cartons,
    SUM(litres)                 AS litres,
    ROUND(SUM(sales_amount), 0) AS revenue
FROM v_sales
GROUP BY fy
ORDER BY fy;


-- ---------------------------------------------------------------------
-- Q2. Is revenue rising because we sell more, or because we charge more?
-- ---------------------------------------------------------------------
-- The main question.
--
-- Revenue = volume x price. If revenue is up 8% and volume is up 3%,
-- the rest came from price. Those two lead to opposite decisions.
--
-- Realised price = total revenue / total litres. We divide the totals
-- rather than averaging rate_per_carton, because an average would give
-- a one-carton invoice the same weight as a fifty-carton one.
WITH by_year AS (
    SELECT
        fy,
        SUM(litres)                     AS litres,
        SUM(sales_amount)               AS revenue,
        SUM(sales_amount) / SUM(litres) AS rate_per_litre
    FROM v_sales
    GROUP BY fy
)
SELECT
    fy,
    litres,
    ROUND(revenue, 0)        AS revenue,
    ROUND(rate_per_litre, 2) AS rate_per_litre,
    -- LAG() reads the previous row, which puts last year's figure on
    -- the same line as this year's.
    ROUND(100.0 * (litres / LAG(litres) OVER (ORDER BY fy) - 1), 1)
        AS volume_growth_pct,
    ROUND(100.0 * (revenue / LAG(revenue) OVER (ORDER BY fy) - 1), 1)
        AS revenue_growth_pct,
    ROUND(100.0 * (rate_per_litre / LAG(rate_per_litre) OVER (ORDER BY fy) - 1), 1)
        AS price_growth_pct
FROM by_year
ORDER BY fy;


-- ---------------------------------------------------------------------
-- Q3. Are we gaining or losing customers?
-- ---------------------------------------------------------------------
-- If volume is flat, either we serve fewer customers or the same ones
-- buy less. This answers the first half.
SELECT
    fy,
    COUNT(DISTINCT account_code) AS active_accounts
FROM v_sales
GROUP BY fy
ORDER BY fy;


-- ---------------------------------------------------------------------
-- Q4. What is happening to volume per account?
-- ---------------------------------------------------------------------
-- Q1 said volume is flat. Q3 said the customer count is rising. Both
-- cannot be good news: more accounts for the same total volume means
-- the average account is buying less.
SELECT
    fy,
    COUNT(DISTINCT account_code)                              AS accounts,
    SUM(litres)                                               AS litres,
    ROUND(SUM(litres) / COUNT(DISTINCT account_code), 1)      AS litres_per_account,
    ROUND(SUM(sales_amount) / COUNT(DISTINCT account_code), 0) AS revenue_per_account
FROM v_sales
GROUP BY fy
ORDER BY fy;


-- ---------------------------------------------------------------------
-- Q5. Do the customers who stayed with us buy more, or less?
-- ---------------------------------------------------------------------
-- Q4 could be an illusion. Adding small new accounts would pull the
-- average down even if nobody changed their behaviour.
--
-- The fix is to hold the customer list still: look only at accounts
-- that bought in all three years. Any change there is real behaviour
-- rather than a change in who is being averaged. This is a cohort.
--
-- HAVING, not WHERE, because "appeared in three years" is a property of
-- the group, not of any single row.
WITH loyal_accounts AS (
    SELECT account_code
    FROM v_sales
    GROUP BY account_code
    HAVING COUNT(DISTINCT fy) = 3
)
SELECT
    v.fy,
    COUNT(DISTINCT v.account_code)                         AS accounts,
    SUM(v.litres)                                          AS litres,
    ROUND(SUM(v.litres) / COUNT(DISTINCT v.account_code), 1) AS litres_per_account
FROM v_sales v
JOIN loyal_accounts l ON v.account_code = l.account_code
GROUP BY v.fy
ORDER BY v.fy;


-- ---------------------------------------------------------------------
-- Q6. Which pack size sells most, and is the mix changing?
-- ---------------------------------------------------------------------
-- A shift to smaller packs would explain falling volume per account
-- without any loss of interest, so this checks the story as much as it
-- answers a question.
SELECT
    fy,
    pack_size,
    SUM(litres) AS litres,
    ROUND(100.0 * SUM(litres) / SUM(SUM(litres)) OVER (PARTITION BY fy), 1)
        AS pct_of_year_litres,
    ROUND(SUM(sales_amount) / SUM(litres), 2) AS rate_per_litre
FROM v_sales
GROUP BY fy, pack_size
ORDER BY fy, litres DESC;


-- ---------------------------------------------------------------------
-- Q7. When in the year do we actually sell?
-- ---------------------------------------------------------------------
-- Ghee is a festive and winter product. The owner reviews this month
-- against last month and sees a collapse every December. This checks
-- whether that is a problem or just the calendar.
--
-- Three years are combined so one odd month cannot set the pattern.
SELECT
    month_no,
    MONTHNAME(MIN(invoice_date))                        AS month_name,
    SUM(litres)                                         AS litres,
    ROUND(100.0 * SUM(litres) / SUM(SUM(litres)) OVER (), 1)
        AS pct_of_annual_litres
FROM v_sales
GROUP BY month_no
ORDER BY month_no;


-- ---------------------------------------------------------------------
-- Q8. Which cities carry the business?
-- ---------------------------------------------------------------------
-- Where to send stock, and where another salesman would pay for himself.
SELECT
    city,
    COUNT(DISTINCT account_code) AS accounts,
    SUM(litres)                  AS litres,
    ROUND(SUM(sales_amount), 0)  AS revenue,
    ROUND(100.0 * SUM(sales_amount) / SUM(SUM(sales_amount)) OVER (), 1)
        AS pct_of_revenue
FROM v_sales
GROUP BY city
ORDER BY revenue DESC;


-- ---------------------------------------------------------------------
-- Q9. How do the five salesmen compare?
-- ---------------------------------------------------------------------
-- Total volume is an unfair measure: a salesman with more accounts
-- should sell more. Litres per account survives that objection.
--
-- Realised rate is a fairness check. If one man sold far more at a much
-- lower rate, he would be buying volume with discount.
SELECT
    m.salesman_code,
    m.salesman_name,
    COUNT(DISTINCT v.account_code)                             AS accounts,
    SUM(v.litres)                                              AS litres,
    ROUND(SUM(v.litres) / COUNT(DISTINCT v.account_code), 0)   AS litres_per_account,
    ROUND(SUM(v.sales_amount) / SUM(v.litres), 2)              AS rate_per_litre
FROM v_sales v
JOIN salesmen m ON v.salesman_code = m.salesman_code
GROUP BY m.salesman_code, m.salesman_name
ORDER BY litres_per_account DESC;


-- ---------------------------------------------------------------------
-- Q10. How exposed are we if a large customer leaves?
-- ---------------------------------------------------------------------
-- The running total shows how fast revenue adds up as you walk down the
-- customer list, which is the honest way to answer it.
WITH account_revenue AS (
    SELECT
        account_code,
        account_name,
        city,
        SUM(sales_amount) AS revenue
    FROM v_sales
    GROUP BY account_code, account_name, city
)
SELECT
    account_name,
    city,
    ROUND(revenue, 0)                                AS revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2) AS pct_of_revenue,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC
                                     ROWS UNBOUNDED PRECEDING)
          / SUM(revenue) OVER (), 1)                 AS running_pct
FROM account_revenue
ORDER BY revenue DESC
LIMIT 15;
