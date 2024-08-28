--Task 1

-- Common Table Expression (CTE) to rank customers by total sales within each channel
WITH RankedCustomers AS (
    SELECT 
        s.channel_id,
        c.cust_first_name,
        c.cust_last_name,
        SUM(s.amount_sold) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY s.channel_id ORDER BY SUM(s.amount_sold) DESC) AS customer_rank
    FROM 
        sh.sales s
    JOIN 
        sh.customers c ON s.cust_id = c.cust_id
    GROUP BY 
        s.channel_id, c.cust_first_name, c.cust_last_name
)
-- Selecting top 5 customers from each channel, along with their sales details
SELECT 
    ch.channel_desc, -- Description of the channel
    rc.cust_last_name, -- Last name of the customer
    rc.cust_first_name, -- First name of the customer
    ROUND(rc.total_sales::numeric, 2) AS amount_sold, -- Total sales amount rounded to 2 decimal places
    TO_CHAR((rc.total_sales / cts.total_channel_sales) * 100, 'FM999999999999999.9999') || '%' AS sales_percentage -- Sales percentage of the customer compared to total channel sales
FROM 
    RankedCustomers rc -- Using the ranked customers CTE
JOIN 
    (SELECT 
        channel_id,
        SUM(amount_sold) AS total_channel_sales
    FROM 
        sh.sales
    GROUP BY 
        channel_id) cts ON rc.channel_id = cts.channel_id -- Joining with total channel sales to calculate sales percentage
JOIN 
    sh.channels ch ON rc.channel_id = ch.channel_id -- Joining with channels to get channel descriptions
WHERE 
    rc.customer_rank <= 5 -- Filtering only the top 5 customers from each channel
ORDER BY 
    ch.channel_desc, rc.total_sales DESC; -- Ordering the result by channel description and total sales amount of customers in descending order


--Task 2
-- Create the tablefunc extension if it doesn't already exist
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- Crosstab query to pivot data and calculate sales amount for each product in each quarter of the year 2000
SELECT *
FROM crosstab(
    -- Subquery to retrieve the data to be pivoted
    'SELECT 
        p.prod_name AS product_name, -- Product name
        EXTRACT(QUARTER FROM t.time_id) AS quarter, -- Extracting the quarter from the time_id
        ROUND(SUM(s.amount_sold)::numeric, 2) AS sales_amount -- Calculating the total sales amount and rounding it to 2 decimal places
    FROM 
        sh.sales s
    JOIN 
        sh.products p ON s.prod_id = p.prod_id
    JOIN 
        sh.customers c ON s.cust_id = c.cust_id
    JOIN 
        sh.countries cn ON c.country_id = cn.country_id
    JOIN 
        sh.times t ON s.time_id = t.time_id
    WHERE 
        p.prod_category = ''Photo'' -- Filtering by product category (Photo)
        AND UPPER(cn.country_region) = UPPER(''Asian'') -- Filtering by country region (Asian), using UPPER for case-insensitive comparison
        AND EXTRACT(YEAR FROM t.time_id) = 2000 -- Filtering by year 2000
    GROUP BY 
        p.prod_name, quarter -- Grouping by product name and quarter
    ORDER BY 
        p.prod_name, quarter', -- Ordering the result by product name and quarter
    'SELECT generate_series(1,4)' -- Generating series for quarters 1 to 4
) AS ct(product_name TEXT, q1 NUMERIC, q2 NUMERIC, q3 NUMERIC, q4 NUMERIC); -- Alias for columns in the result


--Task 3
-- Common Table Expression (CTE) to rank customers by total sales within each channel
WITH RankedCustomers AS (
    SELECT 
        s.cust_id, -- Selecting customer ID
        s.channel_id, -- Selecting channel ID
        SUM(s.amount_sold) AS total_sales, -- Calculating total sales amount for each customer within each channel
        ROW_NUMBER() OVER (PARTITION BY s.channel_id ORDER BY SUM(s.amount_sold) DESC) AS channel_rank -- Ranking customers within each channel based on total sales amount
    FROM 
        sh.sales s -- Joining sales table
    JOIN 
        sh.times t ON s.time_id = t.time_id -- Joining times table to get time information
    WHERE 
        EXTRACT(YEAR FROM t.time_id) IN (1998, 1999, 2001) -- Filtering by years 1998, 1999, and 2001
    GROUP BY 
        s.cust_id, s.channel_id -- Grouping by customer ID and channel ID
),
-- Subquery to select top 300 customers based on channel rank
Top300Customers AS (
    SELECT 
        cust_id,
        channel_id
    FROM 
        RankedCustomers
    WHERE 
        channel_rank <= 300 -- Selecting customers with channel rank less than or equal to 300
)
-- Main query to select top 300 customers along with their sales details
SELECT 
    ch.channel_desc, -- Selecting channel description
    tc.cust_id, -- Selecting customer ID
    c.cust_last_name, -- Selecting customer last name
    c.cust_first_name, -- Selecting customer first name
    ROUND(SUM(s.amount_sold)::numeric, 2) AS amount_sold -- Calculating total sales amount for each customer and rounding to 2 decimal places
FROM 
    Top300Customers tc -- Joining with top 300 customers subquery
JOIN 
    sh.sales s ON tc.cust_id = s.cust_id AND tc.channel_id = s.channel_id -- Joining sales table using customer ID and channel ID
JOIN 
    sh.channels ch ON tc.channel_id = ch.channel_id -- Joining channels table to get channel description
JOIN 
    sh.customers c ON tc.cust_id = c.cust_id -- Joining customers table to get customer details
GROUP BY 
    ch.channel_desc, tc.cust_id, c.cust_last_name, c.cust_first_name -- Grouping by channel description, customer ID, last name, and first name
ORDER BY 
    amount_sold DESC; -- Ordering the result by total sales amount in descending order

   
   --Task 4
-- Selecting calendar month description, product category, and sales amounts for the Americas and Europe regions
SELECT 
    t.calendar_month_desc, -- Selecting calendar month description
    p.prod_category AS product_category, -- Selecting product category
    SUM(CASE WHEN UPPER(cn.country_region) = 'AMERICAS' THEN s.amount_sold ELSE 0 END) AS "Americas SALES", -- Calculating total sales amount for the Americas region
    SUM(CASE WHEN UPPER(cn.country_region) = 'EUROPE' THEN s.amount_sold ELSE 0 END) AS "Europe SALES" -- Calculating total sales amount for the Europe region
FROM 
    sh.sales s -- Joining sales table
JOIN 
    sh.products p ON s.prod_id = p.prod_id -- Joining products table to get product information
JOIN 
    sh.customers c ON s.cust_id = c.cust_id -- Joining customers table to get customer information
JOIN 
    sh.countries cn ON c.country_id = cn.country_id -- Joining countries table to get country information
JOIN 
    sh.times t ON s.time_id = t.time_id -- Joining times table to get time information
WHERE 
    EXTRACT(YEAR FROM t.time_id) = 2000 -- Filtering by year 2000
    AND EXTRACT(MONTH FROM t.time_id) IN (1, 2, 3) -- Filtering by months January, February, and March
    AND UPPER(cn.country_region) IN ('AMERICAS', 'EUROPE') -- Filtering by Americas and Europe regions, using UPPER for case-insensitive comparison
GROUP BY 
    t.calendar_month_desc, p.prod_category -- Grouping by calendar month description and product category
ORDER BY 
    t.calendar_month_desc, p.prod_category; -- Ordering the result by calendar month description and product category













