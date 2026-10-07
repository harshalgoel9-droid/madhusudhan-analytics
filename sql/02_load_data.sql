-- Load the four CSV files (MySQL 8.0). Run after 01_create_tables.sql.
-- Load order: products, salesmen, customers, then sales (foreign keys).

USE ghee_analytics;

SET GLOBAL local_infile = 1;


LOAD DATA LOCAL INFILE 'C:/path/to/madhusudhan-analytics/data/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS                       -- skip the header row
(sku, product_name, pack_size, units_per_carton, litres_per_carton);


LOAD DATA LOCAL INFILE 'C:/path/to/madhusudhan-analytics/data/salesmen.csv'
INTO TABLE salesmen
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(salesman_code, salesman_name);


LOAD DATA LOCAL INFILE 'C:/path/to/madhusudhan-analytics/data/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(account_code, account_name, city, salesman_code);


LOAD DATA LOCAL INFILE 'C:/path/to/madhusudhan-analytics/data/sales.csv'
INTO TABLE sales
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(invoice_date, invoice_no, account_code, sku, cartons, litres,
 rate_per_carton, sales_amount);


-- check row counts
SELECT 'products'  AS table_name, COUNT(*) AS rows_loaded, 3    AS expected FROM products
UNION ALL
SELECT 'salesmen',  COUNT(*), 5    FROM salesmen
UNION ALL
SELECT 'customers', COUNT(*), 143  FROM customers
UNION ALL
SELECT 'sales',     COUNT(*), 2742 FROM sales;

-- both should return 0
SELECT COUNT(*) AS rows_with_bad_amount
FROM sales
WHERE sales_amount <> cartons * rate_per_carton;

SELECT COUNT(*) AS rows_with_bad_litres
FROM sales
WHERE litres <> cartons * 15;
