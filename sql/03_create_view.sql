-- =====================================================================
-- v_sales - the view every business question reads from
-- MySQL 8.0
-- =====================================================================
-- Run this after the data is loaded.
--
-- Why a view?
--
-- Every question needs the same things: the customer's city and
-- salesman, the product's pack size, and the financial year of the
-- invoice. Writing those joins and that date logic into ten separate
-- queries means ten chances to get them slightly different.
--
-- A view is a saved SELECT. It stores no data of its own. It gives that
-- logic one home, so fixing it here fixes all ten answers at once.
-- =====================================================================

USE ghee_analytics;

DROP VIEW IF EXISTS v_sales;

CREATE VIEW v_sales AS
SELECT
    s.invoice_date,
    s.invoice_no,

    -- The Indian financial year runs April to March, so January to
    -- March belong to the year that started the previous April.
    -- January 2025 is FY2024-25.
    CASE
        WHEN MONTH(s.invoice_date) >= 4 THEN YEAR(s.invoice_date)
        ELSE YEAR(s.invoice_date) - 1
    END AS fy_start_year,

    CONCAT(
        'FY',
        CASE WHEN MONTH(s.invoice_date) >= 4
             THEN YEAR(s.invoice_date)
             ELSE YEAR(s.invoice_date) - 1 END,
        '-',
        -- CAST to CHAR first: RIGHT() works on text, and relying on
        -- MySQL to convert the number for us is the kind of thing that
        -- quietly changes behaviour between versions.
        RIGHT(CAST(CASE WHEN MONTH(s.invoice_date) >= 4
                        THEN YEAR(s.invoice_date) + 1
                        ELSE YEAR(s.invoice_date) END AS CHAR), 2)
    ) AS fy,                                    -- 'FY2024-25'

    MONTH(s.invoice_date)                       AS month_no,
    DATE_FORMAT(s.invoice_date, '%Y-%m')        AS month_key,   -- 'year_month' is reserved in MySQL

    -- from customers
    s.account_code,
    c.account_name,
    c.city,
    c.salesman_code,
    m.salesman_name,

    -- from products
    s.sku,
    p.product_name,
    p.pack_size,

    -- the measures
    s.cartons,
    s.litres,
    s.rate_per_carton,
    s.sales_amount

FROM sales s
-- INNER JOIN, not LEFT JOIN. The load checks already showed every sale
-- has a matching customer and product, so there is nothing to preserve.
JOIN customers c ON s.account_code  = c.account_code
JOIN products  p ON s.sku           = p.sku
JOIN salesmen  m ON c.salesman_code = m.salesman_code;


-- Check the view before using it. Each financial year should start on
-- 1 April and end on 31 March.
SELECT fy,
       COUNT(*)           AS rows_in_year,
       MIN(invoice_date)  AS first_invoice,
       MAX(invoice_date)  AS last_invoice
FROM v_sales
GROUP BY fy
ORDER BY fy;
