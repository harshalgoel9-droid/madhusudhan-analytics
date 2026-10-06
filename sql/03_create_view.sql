-- v_sales: sales joined to customers, salesmen and products, plus financial year columns.
-- All the business questions read from this view, so the joins and FY logic live in one place.

USE ghee_analytics;

DROP VIEW IF EXISTS v_sales;

CREATE VIEW v_sales AS
SELECT
    s.invoice_date,
    s.invoice_no,

    -- Indian FY runs April to March, so Jan 2025 is FY2024-25
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

    -- measures
    s.cartons,
    s.litres,
    s.rate_per_carton,
    s.sales_amount

FROM sales s
-- inner joins are fine: the load checks found no orphan rows
JOIN customers c ON s.account_code  = c.account_code
JOIN products  p ON s.sku           = p.sku
JOIN salesmen  m ON c.salesman_code = m.salesman_code;


-- check: each FY should run 1 April to 31 March
SELECT fy,
       COUNT(*)           AS rows_in_year,
       MIN(invoice_date)  AS first_invoice,
       MAX(invoice_date)  AS last_invoice
FROM v_sales
GROUP BY fy
ORDER BY fy;
