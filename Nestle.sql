-- =============================================
-- FMCG DATA WAREHOUSE IMPLEMENTATION
-- =============================================

-- Use the FMCGG database
USE FMCGG;


-- =============================================
-- 1. INITIAL DATA EXPLORATION
-- =============================================

-- Explore the FEEDBACK table structure and sample data
SELECT * FROM FEEDBACK LIMIT 5;

-- Check the data types and structure of the FEEDBACK table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'PUBLIC' AND table_name = 'FEEDBACK';

-- Explore the INVENTORY table structure and sample data
SELECT * FROM INVENTORY LIMIT 5;

-- Check the data types and structure of the INVENTORY table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'PUBLIC' AND table_name = 'INVENTORY';

-- Explore the PROMOTION table structure and sample data
SELECT * FROM PROMOTION LIMIT 5;

-- Check the data types and structure of the PROMOTION table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'PUBLIC' AND table_name = 'PROMOTION';

-- Explore the SALES table structure and sample data
SELECT * FROM SALES LIMIT 5;

-- Check the data types and structure of the SALES table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'PUBLIC' AND table_name = 'SALES';

-- Explore the SHIPMENTS table structure and sample data
SELECT * FROM SHIPMENTS LIMIT 5;

-- Check the data types and structure of the SHIPMENTS table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'PUBLIC' AND table_name = 'SHIPMENTS';

-- =============================================
-- 2. DIMENSION TABLES CREATION
-- =============================================

-- Create dimension tables for our star schema data warehouse

-- Product dimension table
CREATE TABLE Dim_Product (
    product_key INT AUTOINCREMENT PRIMARY KEY,  -- Surrogate key for product
    product_id TEXT                             -- Natural key from source system
);

-- Customer dimension table
CREATE TABLE Dim_Customer (
    customer_key INT AUTOINCREMENT PRIMARY KEY, -- Surrogate key for customer
    customer_id TEXT                            -- Natural key from source system
);

-- Time dimension table
CREATE TABLE Dim_Time (
    time_key INT PRIMARY KEY,                   -- Surrogate key in YYYYMMDD format
    date DATE,                                  -- Full date
    day INT,                                    -- Day of month
    month INT,                                  -- Month number
    year INT,                                   -- Year
    quarter INT,                                -- Quarter number
    day_of_week INT,                            -- Day of week (1=Monday, 7=Sunday)
    is_weekend BOOLEAN,                         -- Flag for weekend days
    is_holiday BOOLEAN                          -- Flag for holidays (to be populated if needed)
);

-- Warehouse dimension table
CREATE TABLE Dim_Warehouse (
    warehouse_key INT AUTOINCREMENT PRIMARY KEY, -- Surrogate key for warehouse
    warehouse_id TEXT                            -- Natural key from source system
);

-- Promotion dimension table
CREATE TABLE Dim_Promotion (
    promotion_key INT AUTOINCREMENT PRIMARY KEY, -- Surrogate key for promotion
    promotion_id TEXT,                           -- Natural key from source system
    discount_type TEXT                           -- Type of discount (percentage, fixed, etc.)
);

-- Order dimension table
CREATE TABLE Dim_Order (
    order_key INT AUTOINCREMENT PRIMARY KEY,     -- Surrogate key for order
    order_id TEXT,                               -- Natural key from source system
    order_status TEXT,                           -- Status of the order
    payment_method TEXT                          -- Payment method used
);

-- Location dimension table
CREATE TABLE Dim_Location (
    location_key INT AUTOINCREMENT PRIMARY KEY,  -- Surrogate key for location
    city TEXT,                                   -- City name
    state TEXT,                                  -- State name
    country TEXT                                 -- Country name
);

-- =============================================
-- 3. FACT TABLES CREATION
-- =============================================

-- Create fact tables with relationships to dimension tables

-- Sales fact table
CREATE TABLE Fact_Sales (
    sale_id TEXT,                                -- Natural key from source system
    product_key INT,                             -- Foreign key to product dimension
    customer_key INT,                            -- Foreign key to customer dimension
    time_key INT,                                -- Foreign key to time dimension
    order_key INT,                               -- Foreign key to order dimension
    quantity_purchased NUMBER,                   -- Quantity of products purchased
    total_purchase_amount NUMBER,                -- Total amount of the purchase
    shipping_cost NUMBER,                        -- Cost of shipping
    PRIMARY KEY (sale_id),                       -- Primary key constraint
    FOREIGN KEY (product_key) REFERENCES Dim_Product(product_key),
    FOREIGN KEY (customer_key) REFERENCES Dim_Customer(customer_key),
    FOREIGN KEY (time_key) REFERENCES Dim_Time(time_key),
    FOREIGN KEY (order_key) REFERENCES Dim_Order(order_key)
);

-- Feedback fact table
CREATE TABLE Fact_Feedback (
    feedback_id TEXT,                            -- Natural key from source system
    product_key INT,                             -- Foreign key to product dimension
    customer_key INT,                            -- Foreign key to customer dimension
    time_key INT,                                -- Foreign key to time dimension
    rating NUMBER,                               -- Rating given by customer
    sentiment TEXT,                              -- Sentiment analysis result
    verified_purchase BOOLEAN,                   -- Whether purchase was verified
    review_text TEXT,                            -- Full review text
    PRIMARY KEY (feedback_id),                   -- Primary key constraint
    FOREIGN KEY (product_key) REFERENCES Dim_Product(product_key),
    FOREIGN KEY (customer_key) REFERENCES Dim_Customer(customer_key),
    FOREIGN KEY (time_key) REFERENCES Dim_Time(time_key)
);

-- Inventory fact table
CREATE TABLE Fact_Inventory (
    inventory_record_id TEXT,                    -- Natural key from source system
    product_key INT,                             -- Foreign key to product dimension
    warehouse_key INT,                           -- Foreign key to warehouse dimension
    time_key INT,                                -- Foreign key to time dimension
    stock_quantity NUMBER,                       -- Current stock quantity
    inventory_status TEXT,                       -- Status of inventory (In Stock, Out of Stock, etc.)
    min_stock_level NUMBER,                      -- Minimum stock level threshold
    max_stock_level NUMBER,                      -- Maximum stock level threshold
    PRIMARY KEY (inventory_record_id),           -- Primary key constraint
    FOREIGN KEY (product_key) REFERENCES Dim_Product(product_key),
    FOREIGN KEY (warehouse_key) REFERENCES Dim_Warehouse(warehouse_key),
    FOREIGN KEY (time_key) REFERENCES Dim_Time(time_key)
);

-- Promotions fact table
CREATE TABLE Fact_Promotions (
    promotion_key INT,                           -- Foreign key to promotion dimension
    product_key INT,                             -- Foreign key to product dimension
    start_time_key INT,                          -- Foreign key to time dimension (start date)
    end_time_key INT,                            -- Foreign key to time dimension (end date)
    discount_rate NUMBER,                        -- Discount rate percentage
    FOREIGN KEY (promotion_key) REFERENCES Dim_Promotion(promotion_key),
    FOREIGN KEY (product_key) REFERENCES Dim_Product(product_key),
    FOREIGN KEY (start_time_key) REFERENCES Dim_Time(time_key),
    FOREIGN KEY (end_time_key) REFERENCES Dim_Time(time_key)
);

-- Shipments fact table
CREATE TABLE Fact_Shipments (
    shipment_id TEXT,                            -- Natural key from source system
    order_key INT,                               -- Foreign key to order dimension
    origin_warehouse_key INT,                    -- Foreign key to warehouse dimension
    location_key INT,                            -- Foreign key to location dimension
    shipment_time_key INT,                       -- Foreign key to time dimension (shipment date)
    estimated_delivery_time_key INT,             -- Foreign key to time dimension (estimated delivery)
    actual_delivery_time_key INT,                -- Foreign key to time dimension (actual delivery)
    shipping_carrier TEXT,                       -- Shipping carrier company
    shipment_status TEXT,                        -- Status of shipment
    PRIMARY KEY (shipment_id),                   -- Primary key constraint
    FOREIGN KEY (order_key) REFERENCES Dim_Order(order_key),
    FOREIGN KEY (origin_warehouse_key) REFERENCES Dim_Warehouse(warehouse_key),
    FOREIGN KEY (location_key) REFERENCES Dim_Location(location_key),
    FOREIGN KEY (shipment_time_key) REFERENCES Dim_Time(time_key),
    FOREIGN KEY (estimated_delivery_time_key) REFERENCES Dim_Time(time_key),
    FOREIGN KEY (actual_delivery_time_key) REFERENCES Dim_Time(time_key)
);

-- =============================================
-- 4. POPULATE DIMENSION TABLES
-- =============================================

-- Populate Dim_Product with unique product IDs from all relevant source tables
INSERT INTO Dim_Product (product_id)
SELECT DISTINCT product_id FROM (
    SELECT product_id FROM SALES
    UNION
    SELECT product_id FROM FEEDBACK
    UNION
    SELECT product_id FROM INVENTORY
    UNION
    SELECT product_id FROM PROMOTION
);

-- Populate Dim_Customer with unique customer IDs from all relevant source tables
INSERT INTO Dim_Customer (customer_id)
SELECT DISTINCT customer_id FROM (
    SELECT customer_id FROM SALES
    UNION
    SELECT customer_id FROM FEEDBACK
);

-- Populate Dim_Warehouse with unique warehouse IDs from all relevant source tables
INSERT INTO Dim_Warehouse (warehouse_id)
SELECT DISTINCT warehouse_id FROM (
    SELECT warehouse_id FROM INVENTORY
    UNION
    SELECT origin_warehouse_id AS warehouse_id FROM SHIPMENTS
);

-- Populate Dim_Promotion with unique promotion IDs and discount types
INSERT INTO Dim_Promotion (promotion_id, discount_type)
SELECT DISTINCT promotion_id, discount_type FROM PROMOTION;

-- Populate Dim_Order with unique order IDs, statuses, and payment methods
INSERT INTO Dim_Order (order_id, order_status, payment_method)
SELECT DISTINCT order_id, order_status, payment_method FROM SALES;

-- Populate Dim_Location with unique city, state, and country combinations
INSERT INTO Dim_Location (city, state, country)
SELECT DISTINCT 
    destination_city, 
    destination_state, 
    destination_country 
FROM SHIPMENTS;

-- Populate Dim_Time with all unique dates from various source tables
INSERT INTO Dim_Time (time_key, date, day, month, year, quarter, day_of_week, is_weekend)
SELECT
    TO_NUMBER(TO_CHAR(date, 'YYYYMMDD')) AS time_key,
    date,
    EXTRACT(DAY FROM date),
    EXTRACT(MONTH FROM date),
    EXTRACT(YEAR FROM date),
    EXTRACT(QUARTER FROM date),
    EXTRACT(DAYOFWEEKISO FROM date),
    CASE WHEN EXTRACT(DAYOFWEEKISO FROM date) IN (6,7) THEN TRUE ELSE FALSE END
FROM (
    SELECT DISTINCT DATE(purchase_timestamp) AS date FROM SALES
    UNION
    SELECT DISTINCT review_date FROM FEEDBACK
    UNION
    SELECT DISTINCT last_restock_date FROM INVENTORY
    UNION
    SELECT DISTINCT promotion_start_date FROM PROMOTION
    UNION
    SELECT DISTINCT promotion_end_date FROM PROMOTION
    UNION
    SELECT DISTINCT shipment_date FROM SHIPMENTS
    UNION
    SELECT DISTINCT estimated_delivery_date FROM SHIPMENTS
    UNION
    SELECT DISTINCT actual_delivery_date FROM SHIPMENTS
);

-- =============================================
-- 5. POPULATE FACT TABLES
-- =============================================

-- Populate Fact_Sales by joining source data with dimension keys
INSERT INTO Fact_Sales (sale_id, product_key, customer_key, time_key, order_key, quantity_purchased, total_purchase_amount, shipping_cost)
SELECT
    s.sale_id,
    dp.product_key,
    dc.customer_key,
    dt.time_key,
    dord.order_key,
    s.quantity_purchased,
    s.total_purchase_amount,
    s.shipping_cost
FROM PUBLIC.SALES AS s
JOIN Dim_Product AS dp ON s.product_id = dp.product_id
JOIN Dim_Customer AS dc ON s.customer_id = dc.customer_id
JOIN Dim_Time AS dt ON TO_DATE(s.purchase_timestamp) = dt.date
JOIN Dim_Order AS dord ON s.order_id = dord.order_id;

-- Populate Fact_Feedback by joining source data with dimension keys
INSERT INTO Fact_Feedback (feedback_id, product_key, customer_key, time_key, rating, sentiment, verified_purchase, review_text)
SELECT
    f.feedback_id,
    dp.product_key,
    dc.customer_key,
    dt.time_key,
    f.rating,
    f.sentiment,
    f.verified_purchase,
    f.review_text
FROM PUBLIC.FEEDBACK AS f
JOIN Dim_Product AS dp ON f.product_id = dp.product_id
JOIN Dim_Customer AS dc ON f.customer_id = dc.customer_id
JOIN Dim_Time AS dt ON f.review_date = dt.date;

-- Populate Fact_Promotions by joining source data with dimension keys
INSERT INTO Fact_Promotions (promotion_key, product_key, start_time_key, end_time_key, discount_rate)
SELECT
    dprom.promotion_key,
    dp.product_key,
    dt_start.time_key AS start_time_key,
    dt_end.time_key AS end_time_key,
    p.discount_rate
FROM PUBLIC.PROMOTION AS p
JOIN Dim_Promotion AS dprom ON p.promotion_id = dprom.promotion_id AND p.discount_type = dprom.discount_type
JOIN Dim_Product AS dp ON p.product_id = dp.product_id
JOIN Dim_Time AS dt_start ON p.promotion_start_date = dt_start.date
JOIN Dim_Time AS dt_end ON p.promotion_end_date = dt_end.date;

-- Populate Fact_Shipments by joining source data with dimension keys
INSERT INTO Fact_Shipments (shipment_id, order_key, origin_warehouse_key, location_key, shipment_time_key, estimated_delivery_time_key, actual_delivery_time_key, shipping_carrier, shipment_status)
SELECT
    s.shipment_id,
    dord.order_key,
    dw.warehouse_key AS origin_warehouse_key,
    dl.location_key,
    dt_ship.time_key AS shipment_time_key,
    dt_est.time_key AS estimated_delivery_time_key,
    dt_actual.time_key AS actual_delivery_time_key,
    s.shipping_carrier,
    s.shipment_status
FROM PUBLIC.SHIPMENTS AS s
LEFT JOIN Dim_Order AS dord ON s.order_id = dord.order_id
LEFT JOIN Dim_Warehouse AS dw ON s.origin_warehouse_id = dw.warehouse_id
LEFT JOIN Dim_Location AS dl ON s.destination_city = dl.city AND s.destination_state = dl.state
LEFT JOIN Dim_Time AS dt_ship ON s.shipment_date = dt_ship.date
LEFT JOIN Dim_Time AS dt_est ON s.estimated_delivery_date = dt_est.date
LEFT JOIN Dim_Time AS dt_actual ON s.actual_delivery_date = dt_actual.date;

-- =============================================
-- 6. DATA CLEANING AND VALIDATION
-- =============================================

-- Validate and clean Dim_Customer table
-- Check for duplicates in customer dimension
SELECT 
  CUSTOMER_ID,
  RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY CUSTOMER_KEY) AS ranks
FROM DIM_CUSTOMER
QUALIFY ranks > 1;

-- Create backup before cleaning
CREATE OR REPLACE TABLE DIM_CUSTOMER_BACKUP CLONE DIM_CUSTOMER;

-- Remove duplicate customers
DELETE FROM DIM_CUSTOMER
WHERE CUSTOMER_KEY IN (
  SELECT CUSTOMER_KEY
  FROM (
    SELECT CUSTOMER_KEY,
           ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY CUSTOMER_KEY) AS row_num
    FROM DIM_CUSTOMER
  )
  WHERE row_num > 1
);

-- Validate and clean Dim_Location table
SELECT * FROM DIM_LOCATION LIMIT 5;

-- Check for duplicates in location dimension
SELECT COUNT(*) AS CNT
FROM DIM_LOCATION
HAVING CNT > 1;

-- Create backup before cleaning
CREATE OR REPLACE TABLE DIM_LOCATION_BACKUP CLONE DIM_LOCATION;

-- Remove duplicate locations
DELETE FROM DIM_LOCATION
WHERE LOCATION_KEY IN (
  SELECT LOCATION_KEY
  FROM (
    SELECT LOCATION_KEY,
           ROW_NUMBER() OVER (PARTITION BY CITY, STATE, COUNTRY ORDER BY LOCATION_KEY) AS rn
    FROM DIM_LOCATION
  )
  WHERE rn > 1
);

-- Check distinct values in location dimension
SELECT DISTINCT CITY FROM DIM_LOCATION;
SELECT DISTINCT STATE FROM DIM_LOCATION;
SELECT DISTINCT COUNTRY FROM DIM_LOCATION;

-- Drop country column as all locations are in the same country
ALTER TABLE DIM_LOCATION DROP COLUMN COUNTRY;

-- Validate and clean Dim_Order table
SELECT * FROM DIM_ORDER LIMIT 5;

-- Check for duplicates in order dimension
SELECT 
  ORDER_KEY,
  RANK() OVER (PARTITION BY ORDER_ID, ORDER_STATUS, PAYMENT_METHOD ORDER BY ORDER_KEY) AS ranks
FROM DIM_ORDER
QUALIFY ranks > 1;

-- Create backup before cleaning
CREATE OR REPLACE TABLE DIM_ORDER_BACKUP CLONE DIM_ORDER;

-- Remove duplicate orders
DELETE FROM DIM_ORDER
WHERE ORDER_KEY IN (
  SELECT ORDER_KEY
  FROM (
    SELECT ORDER_KEY,
           ROW_NUMBER() OVER (PARTITION BY ORDER_ID, ORDER_STATUS, PAYMENT_METHOD ORDER BY ORDER_KEY) AS rn
    FROM DIM_ORDER
  )
  WHERE rn > 1
);

-- Check distinct values in order dimension
SELECT DISTINCT ORDER_ID FROM DIM_ORDER;
SELECT DISTINCT ORDER_STATUS FROM DIM_ORDER;
SELECT DISTINCT PAYMENT_METHOD FROM DIM_ORDER;

-- Validate and clean Dim_Product table
SELECT * FROM DIM_PRODUCT LIMIT 5;

-- Check for duplicates in product dimension
SELECT 
  PRODUCT_ID,
  RANK() OVER (PARTITION BY PRODUCT_ID ORDER BY PRODUCT_KEY) AS ranks
FROM DIM_PRODUCT
QUALIFY ranks > 1;

-- Create backup before cleaning
CREATE OR REPLACE TABLE DIM_PRODUCT_BACKUP CLONE DIM_PRODUCT;

-- Remove duplicate products
DELETE FROM DIM_PRODUCT
WHERE PRODUCT_KEY IN (
  SELECT PRODUCT_KEY
  FROM (
    SELECT PRODUCT_KEY,
           ROW_NUMBER() OVER (PARTITION BY PRODUCT_ID ORDER BY PRODUCT_KEY) AS rn
    FROM DIM_PRODUCT
  )
  WHERE rn > 1
);

-- Validate and clean Dim_Promotion table
SELECT * FROM DIM_PROMOTION LIMIT 5;

-- Check for duplicates in promotion dimension
SELECT 
  PROMOTION_ID,
  RANK() OVER (PARTITION BY PROMOTION_ID, DISCOUNT_TYPE ORDER BY PROMOTION_KEY) AS ranks
FROM DIM_PROMOTION
QUALIFY ranks > 1;

-- Create backup before cleaning
CREATE OR REPLACE TABLE DIM_PROMOTION_BACKUP CLONE DIM_PROMOTION;

-- Remove duplicate promotions
DELETE FROM DIM_PROMOTION
WHERE PROMOTION_KEY IN (
  SELECT PROMOTION_KEY
  FROM (
    SELECT PROMOTION_KEY,
           ROW_NUMBER() OVER (PARTITION BY PROMOTION_ID ORDER BY PROMOTION_KEY) AS rn
    FROM DIM_PROMOTION
  )
  WHERE rn > 1
);

-- Check distinct discount types
SELECT DISTINCT DISCOUNT_TYPE FROM DIM_PROMOTION;

-- Validate Dim_Time table
SELECT * FROM DIM_TIME;

-- Check for duplicates in time dimension
SELECT 
  TIME_KEY,
  RANK() OVER (PARTITION BY TIME_KEY, DATE, DAY, MONTH, YEAR, QUARTER, DAY_OF_WEEK, IS_WEEKEND, IS_HOLIDAY ORDER BY TIME_KEY) AS ranks
FROM DIM_TIME
QUALIFY ranks > 1;

-- Validate and clean Dim_Warehouse table
SELECT * FROM DIM_WAREHOUSE;

-- Check for duplicates in warehouse dimension
SELECT 
  WAREHOUSE_ID,
  RANK() OVER (PARTITION BY WAREHOUSE_ID ORDER BY WAREHOUSE_KEY) AS ranks
FROM DIM_WAREHOUSE
QUALIFY ranks > 1;

-- Create backup before cleaning
CREATE OR REPLACE TABLE DIM_WAREHOUSE_BACKUP CLONE DIM_WAREHOUSE;

-- Remove duplicate warehouses
DELETE FROM DIM_WAREHOUSE
WHERE WAREHOUSE_ID IN (
  SELECT WAREHOUSE_ID
  FROM (
    SELECT WAREHOUSE_ID,
           ROW_NUMBER() OVER (PARTITION BY WAREHOUSE_ID ORDER BY WAREHOUSE_KEY) AS rn
    FROM DIM_WAREHOUSE
  )
  WHERE rn > 1
);

-- Validate and clean Fact_Feedback table
SELECT * FROM FACT_FEEDBACK LIMIT 5;

-- Check for duplicates in feedback fact table
SELECT 
  FEEDBACK_ID,
  RANK() OVER (PARTITION BY FEEDBACK_ID, PRODUCT_KEY, CUSTOMER_KEY, TIME_KEY, RATING, SENTIMENT, VERIFIED_PURCHASE, REVIEW_TEXT ORDER BY TIME_KEY) AS ranks
FROM FACT_FEEDBACK
QUALIFY ranks > 1;

-- Validate and clean Fact_Promotions table
SELECT * FROM FACT_PROMOTIONS LIMIT 5;

-- Check for duplicates in promotions fact table
SELECT *,
       ROW_NUMBER() OVER (
         PARTITION BY PROMOTION_KEY, PRODUCT_KEY, START_TIME_KEY, END_TIME_KEY, DISCOUNT_RATE
         ORDER BY START_TIME_KEY
       ) AS row_num
FROM FACT_PROMOTIONS
QUALIFY row_num > 1;

-- Create backup before cleaning
CREATE OR REPLACE TABLE FACT_PROMOTIONS_BACKUP CLONE FACT_PROMOTIONS;

-- Remove duplicate promotions
DELETE FROM FACT_PROMOTIONS
WHERE PROMOTION_KEY IN (
  SELECT PROMOTION_KEY
  FROM (
    SELECT PROMOTION_KEY,
           ROW_NUMBER() OVER (
             PARTITION BY PROMOTION_KEY, PRODUCT_KEY, START_TIME_KEY, END_TIME_KEY, DISCOUNT_RATE
             ORDER BY START_TIME_KEY
           ) AS row_num
    FROM FACT_PROMOTIONS
  )
  WHERE row_num > 1
);

-- Validate and clean Fact_Sales table
-- Create a distinct version of sales fact table
CREATE OR REPLACE TEMPORARY TABLE FACT_SALES_DISTINCT AS
SELECT DISTINCT *
FROM FACT_SALES;

-- Validate and clean Fact_Shipments table
SELECT * FROM FACT_SHIPMENTS LIMIT 5;

-- Check for duplicates in shipments fact table
SELECT *,
       ROW_NUMBER() OVER (
         PARTITION BY SHIPMENT_ID, ORDER_KEY, ORIGIN_WAREHOUSE_KEY, LOCATION_KEY, 
                      SHIPMENT_TIME_KEY, ESTIMATED_DELIVERY_TIME_KEY, ACTUAL_DELIVERY_TIME_KEY,
                      SHIPPING_CARRIER, SHIPMENT_STATUS
         ORDER BY SHIPMENT_TIME_KEY
       ) AS row_num
FROM FACT_SHIPMENTS
QUALIFY row_num > 1;

-- Remove duplicates using a temporary table
CREATE OR REPLACE TEMPORARY TABLE FACT_SHIPMENTS_TEMP AS
SELECT 
    SHIPMENT_ID,
    ORDER_KEY,
    ORIGIN_WAREHOUSE_KEY,
    LOCATION_KEY,
    SHIPMENT_TIME_KEY,
    ESTIMATED_DELIVERY_TIME_KEY,
    ACTUAL_DELIVERY_TIME_KEY,
    SHIPPING_CARRIER,
    SHIPMENT_STATUS,
    ROW_NUMBER() OVER (
        PARTITION BY SHIPMENT_ID, ORDER_KEY, ORIGIN_WAREHOUSE_KEY, LOCATION_KEY, 
                     SHIPMENT_TIME_KEY, ESTIMATED_DELIVERY_TIME_KEY, ACTUAL_DELIVERY_TIME_KEY,
                     SHIPPING_CARRIER, SHIPMENT_STATUS
        ORDER BY SHIPMENT_TIME_KEY
    ) AS row_num
FROM FACT_SHIPMENTS;

-- Delete all rows from the original table
TRUNCATE TABLE FACT_SHIPMENTS;

-- Insert only the distinct rows
INSERT INTO FACT_SHIPMENTS (
    SHIPMENT_ID,
    ORDER_KEY,
    ORIGIN_WAREHOUSE_KEY,
    LOCATION_KEY,
    SHIPMENT_TIME_KEY,
    ESTIMATED_DELIVERY_TIME_KEY,
    ACTUAL_DELIVERY_TIME_KEY,
    SHIPPING_CARRIER,
    SHIPMENT_STATUS
)
SELECT 
    SHIPMENT_ID,
    ORDER_KEY,
    ORIGIN_WAREHOUSE_KEY,
    LOCATION_KEY,
    SHIPMENT_TIME_KEY,
    ESTIMATED_DELIVERY_TIME_KEY,
    ACTUAL_DELIVERY_TIME_KEY,
    SHIPPING_CARRIER,
    SHIPMENT_STATUS
FROM FACT_SHIPMENTS_TEMP
WHERE row_num = 1;

-- Drop the temporary table
DROP TABLE FACT_SHIPMENTS_TEMP;

-- =============================================
-- 7. DATA VALIDATION QUERIES
-- =============================================

-- Validate customer dimension data
SELECT COUNT(DISTINCT customer_id) AS distinct_customers, 
       COUNT(*) AS total_records
FROM Dim_Customer;

-- Validate sales data by year and month
SELECT YEAR(purchase_timestamp) AS year,
       MONTH(purchase_timestamp) AS month,
       COUNT(*) AS sales_count,
       SUM(total_purchase_amount) AS total_sales
FROM SALES
GROUP BY YEAR(purchase_timestamp), MONTH(purchase_timestamp)
ORDER BY year, month;

-- Validate inventory status distribution
SELECT inventory_status,
       COUNT(*) AS record_count
FROM INVENTORY
GROUP BY inventory_status;

-- =============================================
-- 8. INVENTORY OPTIMIZATION ANALYSIS
-- =============================================

-- a) Identify Stockouts and Calculate Lost Revenue

-- Step 1: Identify Stockout Periods
WITH inventory_status AS (
    SELECT 
        product_id,
        last_restock_date,
        inventory_status,
        LEAD(last_restock_date) OVER (PARTITION BY product_id ORDER BY last_restock_date) AS next_restock_date,
        LEAD(inventory_status) OVER (PARTITION BY product_id ORDER BY last_restock_date) AS next_status
    FROM inventory
),
stockout_periods AS (
    SELECT 
        product_id,
        last_restock_date AS stockout_start,
        COALESCE(next_restock_date, CURRENT_DATE()) AS stockout_end,
        DATEDIFF(day, last_restock_date, COALESCE(next_restock_date, CURRENT_DATE())) AS stockout_days
    FROM inventory_status
    WHERE inventory_status = 'Out-of-Stock'
)
SELECT * FROM stockout_periods;


-- 
--| Product ID                             | Stockout Start | Stockout End | Duration (Days) | Key Observations                                                                 |
--|----------------------------------------|----------------|--------------|------------------|----------------------------------------------------------------------------------|
--| **1c4d367d-5bd1-40ab-878d-8617f07bfc42** | 2025-07-13     | 2025-08-30   | 48               | Longest stockout period. Indicates potential supply chain disruption or demand underestimation. |
--| **eb6c8bda-7a5e-498a-8340-d43fd574e168** | 2025-01-27     | 2025-03-09   | 41               | Significant duration. May have caused notable revenue loss and customer dissatisfaction. |
--| **17c746a3-e581-41a0-812b-340657ea1033** | 2025-03-14     | 2025-03-30   | 16               | Moderate impact. Could be mitigated with improved safety stock or faster replenishment. |
--| **3d9957e3-38be-4eee-8dec-24a5c119fdd2** | 2024-11-30     | 2024-12-13   | 13               | Shorter duration, but still worth reviewing for seasonal or promotional timing effects. |
--| **835a1568-4bda-4eb9-98cb-e19c1fd6ca3e** | 2025-07-04     | 2025-07-06   | 2                | Minimal disruption. Could be a one-off or resolved quickly through agile inventory response. |




-- Step 2: Calculate Average Daily Sales per Product
WITH daily_sales AS (
    SELECT
        product_id,
        DATE(purchase_timestamp) AS sale_date,
        SUM(quantity_purchased) AS daily_quantity
    FROM sales
    GROUP BY product_id, sale_date
),
product_avg_daily_sales AS (
    SELECT
        product_id,
        AVG(daily_quantity) AS avg_daily_sales,
        AVG(daily_quantity) * (SELECT AVG(total_purchase_amount/quantity_purchased) 
                              FROM sales WHERE quantity_purchased > 0) AS avg_daily_revenue
    FROM daily_sales
    GROUP BY product_id
)
SELECT * FROM product_avg_daily_sales;

-- top 5 product_id
-- product_id                           avg_daily_sales  avg daily revenye
-- 8a74d58c-d457-4340-9f99-93ff9cf19bb7	35.460274   	 9269.181438122516
--251409e8-a47e-4d85-b503-932eacbd25f2	18.349650	     4796.529072957666
--23bb4711-b35e-43cb-840d-38a9a26f7dbc	12.532751	     3276.013686126943
--97f2c731-31d5-4bae-923a-2335da2c9235	10.000000	     2613.962158928190
--8d5e5905-9996-46b2-885b-05974f9d5779	9.750755	     2548.810459097984

-- lowest 5 product_id 
-- 74c33c82-be40-4a3b-b5f7-1baea9afcf9e	1.000000	261.396215892819
--9892e837-3e0d-4045-9122-d28ea0e0b9c3	1.000000	261.396215892819
--468f460c-b9c7-4c5e-86ff-1a51036255b6	1.000000	261.396215892819
--83191f77-6403-4eb8-9860-9db4db121c5f	1.000000	261.396215892819
--e78e7238-75c4-40b5-ba5c-c5fd9f2e017b	1.000000	261.396215892819

-- Complete analysis: Identify Stockouts and Calculate Lost Revenue
WITH inventory_status AS (
    SELECT 
        product_id,
        last_restock_date,
        inventory_status,
        LEAD(last_restock_date) OVER (PARTITION BY product_id ORDER BY last_restock_date) AS next_restock_date,
        LEAD(inventory_status) OVER (PARTITION BY product_id ORDER BY last_restock_date) AS next_status
    FROM inventory
),
stockout_periods AS (
    SELECT 
        product_id,
        last_restock_date AS stockout_start,
        COALESCE(next_restock_date, CURRENT_DATE()) AS stockout_end,
        DATEDIFF(day, last_restock_date, COALESCE(next_restock_date, CURRENT_DATE())) AS stockout_days
    FROM inventory_status
    WHERE inventory_status = 'Out-of-Stock'
),
daily_sales AS (
    SELECT
        s.product_id,
        DATE(s.purchase_timestamp) AS sale_date,
        SUM(s.quantity_purchased) AS daily_quantity,
        SUM(s.total_purchase_amount) AS daily_revenue
    FROM sales s
    GROUP BY s.product_id, DATE(s.purchase_timestamp)
),
product_avg_daily_sales AS (
    SELECT
        product_id,
        AVG(daily_quantity) AS avg_daily_sales,
        AVG(daily_revenue) AS avg_daily_revenue
    FROM daily_sales
    GROUP BY product_id
),
lost_revenue_calc AS (
    SELECT
        sp.product_id,
        sp.stockout_start,
        sp.stockout_end,
        sp.stockout_days,
        pas.avg_daily_sales,
        pas.avg_daily_revenue,
        sp.stockout_days * pas.avg_daily_sales AS estimated_lost_units,
        sp.stockout_days * pas.avg_daily_revenue AS estimated_lost_revenue
    FROM stockout_periods sp
    JOIN product_avg_daily_sales pas ON sp.product_id = pas.product_id
)
SELECT 
    product_id,
    SUM(estimated_lost_units) AS total_lost_units,
    ROUND(SUM(estimated_lost_revenue), 2) AS total_lost_revenue,
    COUNT(*) AS stockout_events,
    SUM(stockout_days) AS total_stockout_days
FROM lost_revenue_calc
GROUP BY product_id
ORDER BY total_lost_revenue DESC;



-- 

--| Product ID                             | Lost Units | Lost Revenue (SAR) | Stockout Events | Total Stockout Days | Key Observations                                                                 |
--|----------------------------------------|------------|---------------------|------------------|----------------------|----------------------------------------------------------------------------------|
--| **eb6c8bda-7a5e-498a-8340-d43fd574e168** | 150.33     | 60,259.61           | 1                | 41                   | Highest revenue loss. Long stockout duration suggests forecasting or replenishment gaps. |
--| **1c4d367d-5bd1-40ab-878d-8617f07bfc42** | 96.00      | 26,317.44           | 1                | 48                   | Longest stockout period. May indicate systemic supply chain delays or demand underestimation. |
--| **17c746a3-e581-41a0-812b-340657ea1033** | 48.00      | 19,118.40           | 1                | 16                   | Moderate impact. Shorter duration but still significant revenue leakage.         |
--| **3d9957e3-38be-4eee-8dec-24a5c119fdd2** | 44.71      | 18,734.15           | 1                | 13                   | Lowest impact among listed items, but still worth addressing for margin protection. |




-- b) Identify Overstock and Calculate Carrying Cost
WITH current_inventory AS (
    -- Get the latest inventory record for each product
    SELECT 
        product_id,
        stock_quantity,
        max_stock_level,
        min_stock_level,
        last_restock_date
    FROM inventory
    QUALIFY ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY last_restock_date DESC) = 1
),
product_avg_value AS (
    -- Calculate average product value from sales data
    SELECT
        product_id,
        AVG(total_purchase_amount / NULLIF(quantity_purchased, 0)) AS avg_product_value
    FROM sales
    WHERE quantity_purchased > 0
    GROUP BY product_id
),
overstock_products AS (
    -- Identify products with overstock (stock above max level)
    SELECT
        ci.product_id,
        ci.stock_quantity,
        ci.max_stock_level,
        ci.min_stock_level,
        ci.last_restock_date,
        ci.stock_quantity - ci.max_stock_level AS excess_quantity,
        pav.avg_product_value,
        (ci.stock_quantity - ci.max_stock_level) * pav.avg_product_value AS excess_inventory_value,
        DATEDIFF(day, ci.last_restock_date, CURRENT_DATE()) AS days_since_restock
    FROM current_inventory ci
    JOIN product_avg_value pav ON ci.product_id = pav.product_id
    WHERE ci.stock_quantity > ci.max_stock_level
)
-- Calculate carrying cost (assuming 20% annual carrying cost rate)
SELECT
    product_id,
    stock_quantity,
    max_stock_level,
    excess_quantity,
    ROUND(avg_product_value, 2) AS avg_product_value,
    ROUND(excess_inventory_value, 2) AS excess_inventory_value,
    last_restock_date,
    days_since_restock,
    ROUND(excess_inventory_value * 0.20 * days_since_restock / 365, 2) AS carrying_cost
FROM overstock_products
ORDER BY carrying_cost DESC;



-- =============================================
-- OVERSTOCK ANALYSIS RESULTS
-- =============================================
-- Top 5 products with highest carrying costs:
-- 
-- PRODUCT_ID                          | CARRYING_COST
-- ----------------------------------- | -------------
-- ac5c1864-4ce9-4378-838d-5df816e5ac84 | 76734.03
-- 8edfc458-caa8-4c2d-a6f3-9a5c1c400d3a | 76680.30
-- 7984b97f-fb45-497d-a742-476294191913 | 72225.00
-- 741b1f8c-c266-4ac0-9763-385886042092 | 71226.65
-- ea033c25-49f9-4f46-ae61-32122a4dc91e | 64198.87
-- 
-- Bottom 5 products with lowest carrying costs:
-- 
-- PRODUCT_ID                          | CARRYING_COST
-- ----------------------------------- | -------------
-- d6419b8f-7d94-416a-a877-a988a49a19af | 2.16
-- cc632a8a-e434-40ed-a783-fcfec7e775da | 3.08
-- aa8947b7-f673-4727-b57a-3b3dfae58308 | 4.28
-- b333d5dc-a465-4af8-81e9-2001e2d784bc | 4.33
-- 6662b019-9b31-49f3-91f2-010227c84e37 | 8.61
-- 
-- These results highlight the products with the most significant inventory carrying costs
-- and those with minimal impact, aiding in prioritizing inventory optimization efforts.
 



-- 3. Logistics Efficiency Analysis
WITH shipment_delays AS (
    -- Calculate delivery delays
    SELECT
        shipment_id,
        order_id,
        shipping_carrier,
        shipment_status,
        estimated_delivery_date,
        actual_delivery_date,
        DATEDIFF(day, estimated_delivery_date, actual_delivery_date) AS delay_days,
        CASE 
            WHEN actual_delivery_date <= estimated_delivery_date THEN 'On Time'
            ELSE 'Delayed'
        END AS delivery_status
    FROM shipments
    WHERE actual_delivery_date IS NOT NULL
),
carrier_performance AS (
    -- Aggregate performance by shipping carrier
    SELECT
        shipping_carrier,
        COUNT(*) AS total_shipments,
        SUM(CASE WHEN delivery_status = 'On Time' THEN 1 ELSE 0 END) AS on_time_shipments,
        SUM(CASE WHEN delivery_status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_shipments,
        AVG(delay_days) AS avg_delay_days,
        MAX(delay_days) AS max_delay_days
    FROM shipment_delays
    GROUP BY shipping_carrier
),
order_shipping_costs AS (
    -- Calculate shipping costs per order
    SELECT
        s.order_id,
        s.shipping_cost,
        sd.shipping_carrier,
        sd.delay_days
    FROM sales s
    JOIN shipment_delays sd ON s.order_id = sd.order_id
)
-- Final logistics efficiency analysis
SELECT
    cp.shipping_carrier,
    cp.total_shipments,
    cp.on_time_shipments,
    cp.delayed_shipments,
    ROUND(cp.on_time_shipments * 100.0 / cp.total_shipments, 2) AS on_time_percentage,
    cp.avg_delay_days,
    cp.max_delay_days,
    ROUND(AVG(osc.shipping_cost), 2) AS avg_shipping_cost,
    ROUND(SUM(osc.shipping_cost), 2) AS total_shipping_cost
FROM carrier_performance cp
JOIN order_shipping_costs osc ON cp.shipping_carrier = osc.shipping_carrier
GROUP BY cp.shipping_carrier, cp.total_shipments, cp.on_time_shipments, cp.delayed_shipments, cp.avg_delay_days, cp.max_delay_days
ORDER BY on_time_percentage DESC;

--| Carrier         | Total Shipments | On-Time % | Avg Delay (Days) | Max Delay | Avg Cost | Total Cost   | Key Observations                                                                 |
--|----------------|------------------|-----------|-------------------|------------|----------|--------------|----------------------------------------------------------------------------------|
--| **UPS**         | 16,892           | 75.31%    | 0.198             | 3          | $11.50   | $311,453.91  | Highest on-time rate among all carriers. Efficient and cost-consistent.         |
--| **Internal Fleet** | 16,409           | 74.76%    | 0.207             | 3          | $11.50   | $302,733.26  | Slightly lower performance than UPS. Delay average is marginally higher.        |
--| **FedEx**       | 16,699           | 74.58%    | 0.205             | 3          | $11.56   | $308,477.89  | Lowest on-time rate and highest average cost. Delay metrics comparable overall. |



-- Create a view or table that aggregates products by order
CREATE OR REPLACE VIEW order_baskets AS
SELECT 
    do.order_id,
    LISTAGG(dp.product_id, ', ') WITHIN GROUP (ORDER BY dp.product_id) AS basket_items,
    COUNT(fs.product_key) AS item_count
FROM Fact_Sales fs
JOIN Dim_Order do ON fs.order_key = do.order_key
JOIN Dim_Product dp ON fs.product_key = dp.product_key
GROUP BY do.order_id
HAVING item_count > 1;

SELECT * FROM order_baskets;

