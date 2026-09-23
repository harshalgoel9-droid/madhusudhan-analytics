-- =====================================================================
-- Load the four CSV files into the tables
-- MySQL 8.0
-- =====================================================================
-- Run this after 01_create_tables.sql.
--
-- Before running, do two things:
--
-- 1. Edit the four file paths below to point at the data folder on your
--    machine. On Windows use forward slashes:
--        'C:/Users/you/madhusudhan-analytics/data/sales.csv'
--
-- 2. Turn on local file loading. In MySQL Workbench:
--        Database > Manage Connections > your connection
--        > Advanced > Others, add:   OPT_LOCAL_INFILE=1
--    then reconnect.
--
-- If LOAD DATA still refuses, use the GUI instead: right-click the table
-- in the Navigator > Table Data Import Wizard, and point it at the CSV.
-- It is slower but needs no configuration.
--
-- Load order matters. The dimension tables go first because sales has
-- foreign keys pointing at them.
-- =====================================================================

USE ghee_analytics;

SET GLOBAL local_infile = 1;


-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/path/to/madhusudhan-analytics/data/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS                       -- skip the header row
(sku, product_name, pack_size, units_per_carton, litres_per_carton);


-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/path/to/madhusudhan-analytics/data/salesmen.csv'
INTO TABLE salesmen
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(salesman_code, salesman_name);


-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/path/to/madhusudhan-analytics/data/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(account_code, account_name, city, salesman_code);


-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/path/to/madhusudhan-analytics/data/sales.csv'
INTO TABLE sales
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(invoice_date, invoice_no, account_code, sku, cartons, litres,
 rate_per_carton, sales_amount);


-- ---------------------------------------------------------------------
-- Check the load before going any further. If any of these is wrong,
-- everything built on top of it will be wrong too.
-- ---------------------------------------------------------------------
SELECT 'products'  AS table_name, COUNT(*) AS rows_loaded, 3    AS expected FROM products
UNION ALL
SELECT 'salesmen',  COUNT(*), 5    FROM salesmen
UNION ALL
SELECT 'customers', COUNT(*), 143  FROM customers
UNION ALL
SELECT 'sales',     COUNT(*), 2742 FROM sales;

-- Both of these should return 0.
SELECT COUNT(*) AS rows_with_bad_amount
FROM sales
WHERE sales_amount <> cartons * rate_per_carton;

SELECT COUNT(*) AS rows_with_bad_litres
FROM sales
WHERE litres <> cartons * 15;
