/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE 
        @start_time DATETIME, 
        @end_time DATETIME, 
        @batch_start DATETIME = GETDATE();

    BEGIN TRY
        
        PRINT '==============================================';
        PRINT '           LOADING SILVER LAYER';
        PRINT '==============================================';

        --------------------------------------------
        -- Dimension: Stores
        --------------------------------------------
        PRINT '>> Loading silver.stores';
        TRUNCATE TABLE silver.stores;

        INSERT INTO silver.stores (store_id, store_name, region, address, manager)
        SELECT 
            store_id,
            LTRIM(RTRIM(store_name)),
            LTRIM(RTRIM(region)),
            LTRIM(RTRIM(address)),
            LTRIM(RTRIM(manager))
        FROM bronze.csv_stores;

        --------------------------------------------
        -- Dimension: Books
        --------------------------------------------
        PRINT '>> Loading silver.books';
        TRUNCATE TABLE silver.books;

        INSERT INTO silver.books (book_id, title, author, genre, price, publisher)
        SELECT 
            book_id,
            LTRIM(RTRIM(title)),
            LTRIM(RTRIM(author)),
            LTRIM(RTRIM(genre)),
            price,
            LTRIM(RTRIM(publisher))
        FROM bronze.csv_books;

        --------------------------------------------
        -- Dimension: Customers
        --------------------------------------------
        PRINT '>> Loading silver.customers';
        TRUNCATE TABLE silver.customers;

        INSERT INTO silver.customers
        (customer_id, full_name, first_name, last_name, email, phone, region)
        SELECT
            customer_id,
          
           
            LTRIM(RTRIM(first_name + ' ' + last_name)),
            LTRIM(RTRIM(first_name)),
            LTRIM(RTRIM(last_name)),
            LTRIM(RTRIM(email)),
            LTRIM(RTRIM(phone)),
            LTRIM(RTRIM(region))
        FROM bronze.csv_customers;

        --------------------------------------------
        -- Fact: Sales
        --------------------------------------------
        PRINT '>> Loading silver.sales';
        TRUNCATE TABLE silver.sales;

        INSERT INTO silver.sales
        (sale_id, book_id, customer_id, store_id, quantity, sale_date)
        SELECT 
            sale_id,
            book_id,
            customer_id,
            store_id,
            quantity,
            sale_date
        FROM bronze.csv_sales;

        --------------------------------------------
        -- END
        --------------------------------------------

        PRINT '==============================================';
        PRINT 'Silver Layer Load Completed Successfully';
        PRINT ' Total Duration: ' 
              + CAST(DATEDIFF(SECOND, @batch_start, GETDATE()) AS NVARCHAR)
              + ' seconds';
        PRINT '==============================================';

    END TRY
    BEGIN CATCH

        PRINT '==============================================';
        PRINT 'ERROR DURING SILVER LAYER LOAD:';
        PRINT ERROR_MESSAGE();
        PRINT '==============================================';

    END CATCH
END;
EXEC silver.load_silver;
select * from silver.customers;
