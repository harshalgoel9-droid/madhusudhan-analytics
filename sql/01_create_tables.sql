-- Madhusudan Ghee: database and tables (MySQL 8.0)
-- Star schema: sales is the fact table, products / salesmen / customers are dimensions.
-- Run this first.

DROP DATABASE IF EXISTS ghee_analytics;
CREATE DATABASE ghee_analytics
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE ghee_analytics;


-- products: one row per pack size
-- every carton is 15 litres (15 x 1 L, 30 x 500 ml, 75 x 200 ml)
CREATE TABLE products (
    sku               VARCHAR(20)  NOT NULL,
    product_name      VARCHAR(60)  NOT NULL,
    pack_size         VARCHAR(10)  NOT NULL,
    units_per_carton  INT          NOT NULL,
    litres_per_carton DECIMAL(6,2) NOT NULL,
    PRIMARY KEY (sku)
) ENGINE = InnoDB;


-- salesmen: one row per salesman
CREATE TABLE salesmen (
    salesman_code VARCHAR(10) NOT NULL,
    salesman_name VARCHAR(60) NOT NULL,
    PRIMARY KEY (salesman_code)
) ENGINE = InnoDB;


-- customers: one row per account, each account has one salesman
CREATE TABLE customers (
    account_code  VARCHAR(10) NOT NULL,
    account_name  VARCHAR(80) NOT NULL,
    city          VARCHAR(40) NOT NULL,
    salesman_code VARCHAR(10) NOT NULL,
    PRIMARY KEY (account_code),
    CONSTRAINT fk_customers_salesman
        FOREIGN KEY (salesman_code) REFERENCES salesmen (salesman_code)
) ENGINE = InnoDB;


-- sales: one row per invoice line (not per invoice), so count invoices with COUNT(DISTINCT invoice_no)
-- amounts are ex-GST
CREATE TABLE sales (
    invoice_date    DATE          NOT NULL,
    invoice_no      VARCHAR(30)   NOT NULL,
    account_code    VARCHAR(10)   NOT NULL,
    sku             VARCHAR(20)   NOT NULL,
    cartons         INT           NOT NULL,
    litres          DECIMAL(10,2) NOT NULL,
    rate_per_carton DECIMAL(10,2) NOT NULL,
    sales_amount    DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (invoice_no, sku),
    CONSTRAINT fk_sales_customer
        FOREIGN KEY (account_code) REFERENCES customers (account_code),
    CONSTRAINT fk_sales_product
        FOREIGN KEY (sku) REFERENCES products (sku)
) ENGINE = InnoDB;

-- indexes on the columns used for grouping and filtering
CREATE INDEX idx_sales_date    ON sales (invoice_date);
CREATE INDEX idx_sales_account ON sales (account_code);
CREATE INDEX idx_sales_sku     ON sales (sku);
