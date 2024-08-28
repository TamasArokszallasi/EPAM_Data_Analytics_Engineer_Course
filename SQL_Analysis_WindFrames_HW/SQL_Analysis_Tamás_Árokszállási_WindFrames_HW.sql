--Task 1
-- CTE (Common Table Expression) to calculate total sales data for each channel, region, and year between 1999 and 2001
WITH SalesData AS (
    SELECT 
        c.channel_desc,
        UPPER(cn.country_region) AS country_region,
        EXTRACT(YEAR FROM t.time_id) AS calendar_year,
        SUM(s.amount_sold) AS amount_sold
    FROM 
        sh.sales s
    JOIN 
        sh.channels c ON s.channel_id = c.channel_id
    JOIN 
        sh.customers cust ON s.cust_id = cust.cust_id
    JOIN 
        sh.countries cn ON cust.country_id = cn.country_id
    JOIN 
        sh.times t ON s.time_id = t.time_id
    WHERE 
        EXTRACT(YEAR FROM t.time_id) BETWEEN 1999 AND 2001
        AND UPPER(cn.country_region) IN ('AMERICAS', 'ASIA', 'EUROPE')
    GROUP BY 
        c.channel_desc, UPPER(cn.country_region), EXTRACT(YEAR FROM t.time_id)
),
RegionYearTotals AS (
    SELECT 
        country_region,
        calendar_year,
        SUM(amount_sold) AS total_amount_sold_by_region_year
    FROM 
        SalesData
    GROUP BY 
        country_region, calendar_year
)
SELECT 
    sd.channel_desc,
    sd.country_region,
    sd.calendar_year,
    sd.amount_sold,
    ROUND(sd.amount_sold / ryt.total_amount_sold_by_region_year * 100, 2) AS "BY CHANNELS",
    LAG(ROUND(sd.amount_sold / ryt.total_amount_sold_by_region_year * 100, 2)) OVER (PARTITION BY sd.channel_desc ORDER BY sd.calendar_year) AS "PREVIOUS PERIOD",
    ROUND(
        ROUND(sd.amount_sold / ryt.total_amount_sold_by_region_year * 100, 2) -
        LAG(ROUND(sd.amount_sold / ryt.total_amount_sold_by_region_year * 100, 2)) OVER (PARTITION BY sd.channel_desc ORDER BY sd.calendar_year),
    2) AS "DIFF"
FROM 
    SalesData sd
JOIN 
    RegionYearTotals ryt ON sd.country_region = ryt.country_region AND sd.calendar_year = ryt.calendar_year
ORDER BY 
    sd.country_region, sd.calendar_year, sd.channel_desc;


   
  --Task 2
-- Common Table Expression (CTE) to retrieve sales data for the 49th, 50th, and 51st weeks of 1999
WITH WeekSales AS (
    SELECT 
        t.time_id,
        SUM(s.amount_sold) AS amount_sold
    FROM 
        sh.sales s
    JOIN 
        sh.times t ON s.time_id = t.time_id
    WHERE 
        EXTRACT(YEAR FROM t.time_id) = 1999 
        AND EXTRACT(WEEK FROM t.time_id) IN (49, 50, 51)
    GROUP BY 
        t.time_id
),
WeekSalesWithAvg AS (
    SELECT 
        time_id,
        amount_sold,
        SUM(amount_sold) OVER (ORDER BY time_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CUM_SUM,
        AVG(amount_sold) OVER (ORDER BY time_id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS CENTERED_3_DAY_AVG
    FROM 
        WeekSales
)
SELECT 
    time_id,
    amount_sold,
    CUM_SUM, 
    CENTERED_3_DAY_AVG 
FROM 
    WeekSalesWithAvg
ORDER BY 
    time_id;

    
    
  --Task 3
-- RANGE Mode
SELECT
    time_id,
    amount_sold,
    AVG(amount_sold) OVER (ORDER BY time_id RANGE BETWEEN INTERVAL '7' DAY PRECEDING AND CURRENT ROW) AS moving_avg
FROM
    sh.sales;

-- ROWS Mode
SELECT
    prod_id,
    time_id,
    amount_sold,
    SUM(amount_sold) OVER (PARTITION BY prod_id ORDER BY time_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM
    sh.sales;

-- GROUPS Mode
SELECT
    channel_id,
    EXTRACT(YEAR FROM time_id) AS calendar_year,
    amount_sold,
    amount_sold - LAG(amount_sold) OVER (PARTITION BY channel_id ORDER BY EXTRACT(YEAR FROM time_id) GROUPS BETWEEN 1 PRECEDING AND 1 PRECEDING) AS sales_diff_prev_year
FROM
    sh.sales;



