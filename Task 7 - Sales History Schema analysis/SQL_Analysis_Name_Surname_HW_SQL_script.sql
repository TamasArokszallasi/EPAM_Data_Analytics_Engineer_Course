--Task 3 /1

SELECT 
    p.prod_category AS product_category,
    SUM(s.amount_sold) AS total_sales_amount
FROM 
    sh.sales s
JOIN 
    sh.products p ON s.prod_id = p.prod_id
JOIN 
    sh.times t ON s.time_id = t.time_id
WHERE 
    t.time_id BETWEEN :start_date AND :end_date -- User-specified start and end dates
GROUP BY 
    p.prod_category
ORDER BY 
    total_sales_amount DESC; -- Order the results by total sales amount



  
   --Task 3/2
   
-- Query 1: Calculate average sales quantity by region for a specified product
SELECT 
    cn.country_region AS region,
    AVG(s.quantity_sold) AS average_sales_quantity
FROM 
    sh.sales s
JOIN 
    sh.customers c ON s.cust_id = c.cust_id
JOIN 
    sh.countries cn ON c.country_id = cn.country_id
JOIN 
    sh.products p ON s.prod_id = p.prod_id
WHERE 
    p.prod_name = :product_name -- User-specified product name
GROUP BY 
    cn.country_region;

-- Query 2: Calculate total sales amount for top 5 customers for a specified period
SELECT 
    c.cust_id,
    c.cust_first_name,
    c.cust_last_name,
    SUM(s.amount_sold) AS total_sales_amount
FROM 
    sh.sales s
JOIN 
    sh.customers c ON s.cust_id = c.cust_id
JOIN 
    sh.products p ON s.prod_id = p.prod_id
WHERE 
    s.time_id BETWEEN :start_date AND :end_date -- User-specified start and end dates
GROUP BY 
    c.cust_id, c.cust_first_name, c.cust_last_name
ORDER BY 
    total_sales_amount DESC
LIMIT 5;

   
   --Task 3/3
SELECT 
    c.cust_id,
    c.cust_first_name,
    c.cust_last_name,
    SUM(s.amount_sold) AS total_sales_amount
FROM 
    sh.sales s
JOIN 
    sh.customers c ON s.cust_id = c.cust_id
GROUP BY 
    c.cust_id -- Grouping only by cust_id since it's unique
ORDER BY 
    total_sales_amount DESC
LIMIT 5;



   