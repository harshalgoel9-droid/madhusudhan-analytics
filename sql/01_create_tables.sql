-- =====================================================================
-- Madhusudan Ghee - database and tables
-- MySQL 8.0
-- =====================================================================
-- Run this first, in MySQL Workbench.
--
-- Four tables. One fact table (sales) holding the numbers we add up,
-- and three dimension tables holding the labels we group by. This is a
-- star schema.
--
-- Keeping names and cities out of the fact table means each is stored
-- once. A shop that changes its name is corrected in one row instead of
-- in thirty.
-- =====================================================================

DROP DATABASE IF EXISTS ghee_analytics;
CREATE DATABASE ghee_analytics
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE ghee_analytics;


-- ---------------------------------------------------------------------
-- products - one row per pack size (3 rows)
-- ---------------------------------------------------------------------
-- Every carton holds 15 litres whatever the pack size: 15 x 1 L,
-- 30 x 500 ml, or 75 x 200 ml. That is why litres_per_carton is 15 on
-- all three rows.
CREATE TABLE products (
    sku               VARCHAR(20)  NOT NULL,
    product_name      VARCHAR(60)  NOT NULL,
    pack_size         VARCHAR(10)  NOT NULL,
    units_per_carton  INT          NOT NULL,
    litres_per_carton DECIMAL(6,2) NOT NULL,
    PRIMARY KEY (sku)
) ENGINE = InnoDB;


-- ---------------------------------------------------------------------
-- salesmen - one row per field salesman (5 rows)
-- ---------------------------------------------------------------------
CREATE TABLE salesmen (
    salesman_code VARCHAR(10) NOT NULL,
    salesman_name VARCHAR(60) NOT NULL,
    PRIMARY KEY (salesman_code)
) ENGINE = InnoDB;


-- ---------------------------------------------------------------------
-- customers - one row per account (143 rows)
-- ---------------------------------------------------------------------
-- Each account sits in one city and belongs to one salesman, so city
-- performance and salesman performance are two views of the same split.
CREATE TABLE customers (
    account_code  VARCHAR(10) NOT NULL,
    account_name  VARCHAR(80) NOT NULL,
    city          VARCHAR(40) NOT NULL,
    salesman_code VARCHAR(10) NOT NULL,
    PRIMARY KEY (account_code),
    CONSTRAINT fk_customers_salesman
        FOREIGN KEY (salesman_code) REFERENCES salesmen (salesman_code)
) ENGINE = InnoDB;


-- ---------------------------------------------------------------------
-- sales - one row per invoice line (2,742 rows)
-- ---------------------------------------------------------------------
-- The grain is the invoice LINE, not the invoice. An invoice covering
-- two pack sizes is two rows here. That is why invoice counts always
-- use COUNT(DISTINCT invoice_no) and never COUNT(*).
--
-- Amounts are ex-GST. Tax is collected on the government's behalf and
-- is not revenue, so the tax columns are not loaded.
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

-- Indexes on the columns we group and filter by. On 2,742 rows this
-- makes no difference you can feel. It is the habit that matters.
CREATE INDEX idx_sales_date    ON sales (invoice_date);
CREATE INDEX idx_sales_account ON sales (account_code);
CREATE INDEX idx_sales_sku     ON sales (sku);
