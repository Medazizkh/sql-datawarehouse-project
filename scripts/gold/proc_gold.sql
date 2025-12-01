/******************************************************************************
    Procedure Name : gold.load_gold
    Layer          : GOLD (Star Schema)
    Purpose        : Build all dimensions + fact table for the analytical model.
                     The Gold layer represents clean, conformed, historical,
                     business-ready data optimized for reporting and BI tools.

    Architecture   : Bronze → Silver → Gold (BSG Model)
    Author         : Aziz Khlifi
    Description    :
        - Drops existing Gold layer tables safely
        - Recreates dimensions (Customers, Books, Stores, Date)
        - Loads fact table with surrogate keys
        - Enforces referential integrity (FKs)
        - Ensures idempotency → Procedure can be executed any time

******************************************************************************/
CREATE OR ALTER PROCEDURE gold.load_gold
AS
BEGIN
    SET NOCOUNT ON;

    /**************************************************************************
        IMPORTANT :
        We MUST drop the Fact table FIRST because it contains foreign keys
        referencing all dimensions. SQL Server will NOT allow dimension drop
        until the fact table is removed.
    **************************************************************************/
    IF OBJECT_ID('gold.fact_sales', 'U') IS NOT NULL
        DROP TABLE gold.fact_sales;

    PRINT '==============================================';
    PRINT '           LOADING GOLD LAYER';
    PRINT '==============================================';


    /**************************************************************************
     * 1. DIMENSION : Customers
     *    - Stores customer descriptive data
     *    - Contains surrogate key (CustomerSK)
     *    - Supports reporting by region, demographics, etc.
    **************************************************************************/
    PRINT '>> Loading gold.dim_customers';

    IF OBJECT_ID('gold.dim_customers', 'U') IS NOT NULL
        DROP TABLE gold.dim_customers;

    CREATE TABLE gold.dim_customers (
        CustomerSK INT PRIMARY KEY,
        CustomerID INT,
        FullName VARCHAR(200),
        FirstName VARCHAR(100),
        LastName VARCHAR(100),
        Email VARCHAR(200),
        Phone VARCHAR(20),
        Region VARCHAR(50),
        LoadDate DATETIME
    );

    INSERT INTO gold.dim_customers
    SELECT 
        customer_sk,
        customer_id,
        full_name,
        first_name,
        last_name,
        email,
        phone,
        region,
        load_date
    FROM silver.customers;


    /**************************************************************************
     * 2. DIMENSION : Books
     *    - Metadata for each book sold
     *    - BookSK is the surrogate key linked to fact_sales
     *    - Useful for all analytics by genre, price, author, etc.
    **************************************************************************/
    PRINT '>> Loading gold.dim_books';

    IF OBJECT_ID('gold.dim_books', 'U') IS NOT NULL
        DROP TABLE gold.dim_books;

    CREATE TABLE gold.dim_books (
        BookSK INT PRIMARY KEY,
        BookID INT,
        Title VARCHAR(200),
        Author VARCHAR(100),
        Genre VARCHAR(50),
        Price DECIMAL(10,2),
        Publisher VARCHAR(100),
        LoadDate DATETIME
    );

    INSERT INTO gold.dim_books
    SELECT 
        book_sk,
        book_id,
        title,
        author,
        genre,
        price,
        publisher,
        load_date
    FROM silver.books;


    /**************************************************************************
     * 3. DIMENSION : Stores
     *    - Represents physical store locations
     *    - Allows geographical analytics (region, city, manager…)
    **************************************************************************/
    PRINT '>> Loading gold.dim_stores';

    IF OBJECT_ID('gold.dim_stores', 'U') IS NOT NULL
        DROP TABLE gold.dim_stores;

    CREATE TABLE gold.dim_stores (
        StoreSK INT PRIMARY KEY,
        StoreID INT,
        StoreName VARCHAR(100),
        Region VARCHAR(50),
        Address VARCHAR(200),
        Manager VARCHAR(100),
        LoadDate DATETIME
    );

    INSERT INTO gold.dim_stores
    SELECT 
        store_sk,
        store_id,
        store_name,
        region,
        address,
        manager,
        load_date
    FROM silver.stores;


    /**************************************************************************
     * 4. DIMENSION : Date
     *    - Fundamental dimension in all Data Warehouses
     *    - Allows analysis by year, month, quarter, weekday…
     *    - Enables time-series analytics and partitioning
     *    - We generate dates from 2020 → 2030
    **************************************************************************/
    PRINT '>> Loading gold.dim_date';

    IF OBJECT_ID('gold.dim_date', 'U') IS NOT NULL
        DROP TABLE gold.dim_date;

    CREATE TABLE gold.dim_date (
        DateSK INT IDENTITY(1,1) PRIMARY KEY,
        DateKey INT,               -- YYYYMMDD format
        Date DATE,
        Year INT,
        Quarter TINYINT,
        Month TINYINT,
        Day TINYINT,
        DayOfWeek TINYINT,
        IsWeekend BIT,
        MonthName NVARCHAR(40),
        QuarterName NVARCHAR(20)
    );

    ;WITH DateRange AS (
        SELECT CAST('2020-01-01' AS DATE) AS d
        UNION ALL
        SELECT DATEADD(DAY, 1, d)
        FROM DateRange
        WHERE d < '2030-12-31'
    )
    INSERT INTO gold.dim_date
    SELECT 
        YEAR(d) * 10000 + MONTH(d) * 100 + DAY(d),
        d,
        YEAR(d),
        DATEPART(QUARTER, d),
        MONTH(d),
        DAY(d),
        DATEPART(WEEKDAY, d),
        CASE WHEN DATEPART(WEEKDAY, d) IN (1,7) THEN 1 ELSE 0 END,
        DATENAME(MONTH, d),
        CONCAT('Q', DATEPART(QUARTER, d))
    FROM DateRange
    OPTION (MAXRECURSION 32767);


    /**************************************************************************
     * 5. FACT TABLE : Fact_Sales
     *    - Central table of the STAR SCHEMA
     *    - Contains the business events (sales transactions)
     *    - All dimensions are linked using surrogate keys (SK)
     *    - Quantity is the measurable KPI
    **************************************************************************/
    PRINT '>> Loading gold.fact_sales';

    IF OBJECT_ID('gold.fact_sales', 'U') IS NOT NULL
        DROP TABLE gold.fact_sales;

    CREATE TABLE gold.fact_sales (
        FactSaleSK INT IDENTITY(1,1) PRIMARY KEY,
        SaleSK INT,
        SaleID INT,
        CustomerSK INT,
        BookSK INT,
        StoreSK INT,
        DateSK INT,
        Quantity INT,

        -- Referential Integrity
        FOREIGN KEY (CustomerSK) REFERENCES gold.dim_customers(CustomerSK),
        FOREIGN KEY (BookSK) REFERENCES gold.dim_books(BookSK),
        FOREIGN KEY (StoreSK) REFERENCES gold.dim_stores(StoreSK),
        FOREIGN KEY (DateSK) REFERENCES gold.dim_date(DateSK)
    );

    -- Populate fact table with surrogate keys
    INSERT INTO gold.fact_sales (SaleSK, SaleID, CustomerSK, BookSK, StoreSK, DateSK, Quantity)
    SELECT
        s.sale_sk,
        s.sale_id,
        c.customer_sk,
        b.book_sk,
        st.store_sk,
        d.DateSK,
        s.quantity
    FROM silver.sales s
    LEFT JOIN silver.customers c ON s.customer_id = c.customer_id
    LEFT JOIN silver.books b ON s.book_id = b.book_id
    LEFT JOIN silver.stores st ON s.store_id = st.store_id
    LEFT JOIN gold.dim_date d ON s.sale_date = d.Date;

    PRINT '==============================================';
    PRINT '         GOLD LAYER LOAD COMPLETE';
    PRINT '==============================================';

END;
GO

-- Execute the procedure
EXEC gold.load_gold;
