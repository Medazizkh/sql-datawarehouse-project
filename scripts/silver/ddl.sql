/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/
IF OBJECT_ID('silver.stores', 'U') IS NOT NULL
    DROP TABLE silver.stores;
GO
CREATE TABLE silver.stores (
    store_sk INT IDENTITY(1,1) PRIMARY KEY,
    store_id INT,
    store_name VARCHAR(100),
    region VARCHAR(50),
    address VARCHAR(200),
    manager VARCHAR(100),
    load_date DATETIME DEFAULT GETDATE()
)
IF OBJECT_ID('silver.books', 'U') IS NOT NULL
    DROP TABLE silver.books;
GO
CREATE TABLE silver.books (
    book_sk INT IDENTITY(1,1) PRIMARY KEY,
    book_id INT,
    title VARCHAR(200),
    author VARCHAR(100),
    genre VARCHAR(50),
    price DECIMAL(10,2),
    publisher VARCHAR(100),
    load_date DATETIME DEFAULT GETDATE()
)
IF OBJECT_ID('silver.customers', 'U') IS NOT NULL
    DROP TABLE silver.customers;
GO
CREATE TABLE silver.customers (
    customer_sk INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    full_name VARCHAR(200),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(200),
    phone VARCHAR(20),
    region VARCHAR(50),
    load_date DATETIME DEFAULT GETDATE()
)
IF OBJECT_ID('silver.sales', 'U') IS NOT NULL
    DROP TABLE silver.sales;
GO
CREATE TABLE silver.sales (
    sale_sk INT IDENTITY(1,1) PRIMARY KEY,
    sale_id INT,
    book_id INT,
    customer_id INT,
    store_id INT,
    quantity INT,
    sale_date DATE,
    load_date DATETIME DEFAULT GETDATE()
);


