--Task1
WITH SalesData AS (
    SELECT
        c.channel_desc,
        r.country_region,
        SUM(s.quantity_sold) AS total_quantity_sold
    FROM
        sh.sales s
        JOIN sh.channels c ON s.channel_id = c.channel_id
        JOIN sh.customers cu ON s.cust_id = cu.cust_id
        JOIN sh.countries r ON cu.country_id = r.country_id
    GROUP BY
        c.channel_desc,
        r.country_region
),
ChannelTotals AS (
    SELECT
        channel_desc,
        SUM(total_quantity_sold) AS channel_total_sales
    FROM
        SalesData
    GROUP BY
        channel_desc
)
SELECT
    sd.channel_desc,
    sd.country_region,
    sd.total_quantity_sold AS sales,
    ROUND((sd.total_quantity_sold / ct.channel_total_sales) * 100, 2) || '%' AS sales_percentage
FROM
    SalesData sd
    JOIN ChannelTotals ct ON sd.channel_desc = ct.channel_desc
ORDER BY
    sd.total_quantity_sold DESC;
   
   --Task 2
   WITH YearlySales AS (
    SELECT
        p.prod_subcategory,
        EXTRACT(YEAR FROM t.time_id) AS sales_year,
        SUM(s.quantity_sold) AS total_sales
    FROM
        sh.sales s
        JOIN sh.products p ON s.prod_id = p.prod_id
        JOIN sh.times t ON s.time_id = t.time_id
    WHERE
        EXTRACT(YEAR FROM t.time_id) BETWEEN 1997 AND 2001
    GROUP BY
        p.prod_subcategory,
        EXTRACT(YEAR FROM t.time_id)
),
YearlyComparisons AS (
    SELECT
        curr.prod_subcategory,
        curr.sales_year,
        curr.total_sales AS current_year_sales,
        prev.total_sales AS previous_year_sales
    FROM
        YearlySales curr
        LEFT JOIN YearlySales prev ON curr.prod_subcategory = prev.prod_subcategory
            AND curr.sales_year = prev.sales_year + 1
    WHERE
        curr.sales_year BETWEEN 1998 AND 2001
),
ConsistentGrowth AS (
    SELECT
        prod_subcategory,
        COUNT(*) AS years_with_growth
    FROM
        YearlyComparisons
    WHERE
        current_year_sales > previous_year_sales
    GROUP BY
        prod_subcategory
    HAVING
        COUNT(*) = 4  -- Must have growth for all four years: 1998 to 2001
)
SELECT
    prod_subcategory
FROM
    ConsistentGrowth;
   
   --Task 3
WITH QuarterlySales AS (
    SELECT
        EXTRACT(YEAR FROM t.time_id) AS calendar_year,
        'Q' || EXTRACT(QUARTER FROM t.time_id) AS calendar_quarter_desc,
        p.prod_category,
        SUM(s.amount_sold) AS sales
    FROM
        sh.sales s
        JOIN sh.products p ON s.prod_id = p.prod_id
        JOIN sh.times t ON s.time_id = t.time_id
        JOIN sh.channels c ON s.channel_id = c.channel_id
    WHERE
        p.prod_category IN ('Electronics', 'Hardware', 'Software/Other')
        AND c.channel_desc IN ('Partners', 'Internet')
        AND EXTRACT(YEAR FROM t.time_id) IN (1999, 2000)
    GROUP BY
        1, 2, 3
),
CalculatedMetrics AS (
    SELECT
        qs.calendar_year,
        qs.calendar_quarter_desc,
        qs.prod_category,
        qs.sales,
        CASE
            WHEN qs.calendar_quarter_desc = 'Q1' THEN 'N/A'
            ELSE ROUND(((qs.sales / FIRST_VALUE(qs.sales) OVER (
                PARTITION BY qs.calendar_year, qs.prod_category ORDER BY qs.calendar_quarter_desc
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) - 1) * 100, 2) || '%'
        END AS diff_percent,
        ROUND(SUM(qs.sales) OVER (
            PARTITION BY qs.calendar_year, qs.prod_category ORDER BY qs.calendar_quarter_desc
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS cum_sum
    FROM
        QuarterlySales qs
)
SELECT
    cm.calendar_year,
    cm.calendar_quarter_desc,
    cm.prod_category,
    ROUND(cm.sales, 2) AS sales$,
    cm.diff_percent,
    cm.cum_sum AS cum_sum$
FROM
    CalculatedMetrics cm
ORDER BY
    cm.calendar_year,
    cm.calendar_quarter_desc,
    cm.sales DESC;


