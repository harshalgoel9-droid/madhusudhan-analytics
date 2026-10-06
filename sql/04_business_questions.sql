-- Madhusudan Ghee: ten business questions (MySQL 8.0, needs window functions)
-- All queries read from v_sales.
--   Q1-Q2   is the business growing, and on what?
--   Q3-Q5   what are the customers doing?
--   Q6-Q7   what sells, and when?
--   Q8-Q10  cities, salesmen, concentration

USE ghee_analytics;


-- Q1. How big is the business, and is it growing?
SELECT
    fy,
    COUNT(DISTINCT invoice_no)  AS invoices,
    SUM(cartons)                AS cartons,
    SUM(litres)                 AS litres,
    ROUND(SUM(sales_amount), 0) AS revenue
FROM v_sales
GROUP BY fy
ORDER BY fy;


-- Q2. Is revenue rising because we sell more, or because we charge more?
-- price per litre = total revenue / total litres (not an average of rates,
-- which would weight a 1-carton invoice the same as a 50-carton one)
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
    -- LAG() brings last year's value onto this year's row
    ROUND(100.0 * (litres / LAG(litres) OVER (ORDER BY fy) - 1), 1)
        AS volume_growth_pct,
    ROUND(100.0 * (revenue / LAG(revenue) OVER (ORDER BY fy) - 1), 1)
        AS revenue_growth_pct,
    ROUND(100.0 * (rate_per_litre / LAG(rate_per_litre) OVER (ORDER BY fy) - 1), 1)
        AS price_growth_pct
FROM by_year
ORDER BY fy;


-- Q3. Are we gaining or losing customers?
SELECT
    fy,
    COUNT(DISTINCT account_code) AS active_accounts
FROM v_sales
GROUP BY fy
ORDER BY fy;


-- Q4. What is happening to volume per account?
SELECT
    fy,
    COUNT(DISTINCT account_code)                              AS accounts,
    SUM(litres)                                               AS litres,
    ROUND(SUM(litres) / COUNT(DISTINCT account_code), 1)      AS litres_per_account,
    ROUND(SUM(sales_amount) / COUNT(DISTINCT account_code), 0) AS revenue_per_account
FROM v_sales
GROUP BY fy
ORDER BY fy;


-- Q5. Do the customers who stayed with us buy more, or less?
-- cohort: only accounts that bought in all three years, so new small
-- accounts can't drag the average down
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


-- Q6. Which pack size sells most, and is the mix changing?
-- (a shift to smaller packs could also explain lower litres per account)
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


-- Q7. When in the year do we actually sell?
-- all three years combined
SELECT
    month_no,
    MONTHNAME(MIN(invoice_date))                        AS month_name,
    SUM(litres)                                         AS litres,
    ROUND(100.0 * SUM(litres) / SUM(SUM(litres)) OVER (), 1)
        AS pct_of_annual_litres
FROM v_sales
GROUP BY month_no
ORDER BY month_no;


-- Q8. Which cities carry the business?
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


-- Q9. How do the five salesmen compare?
-- litres per account, since salesmen have different numbers of accounts;
-- rate per litre to check nobody is selling volume through discounts
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


-- Q10. How dependent are we on the largest customers?
-- running % of revenue down the customer list
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
