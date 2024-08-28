--Task 1 
--COMMENT: For some reason i got no datas in the columns. I have tried to write a simple select statement and even in that case i got no output, however i run it in the database, and there is 
-- data inside the database for sure. This problem i have in both the first and second task, but in the following all working properly. I can't figure out the issue for more than 3 hours

CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT 
    c.category_id, 
    c.name AS category_name, 
    SUM(p.amount) AS total_sales_revenue
FROM 
    category c
    JOIN film_category fc ON c.category_id = fc.category_id
    JOIN inventory i ON fc.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
WHERE 
    EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM CURRENT_DATE) 
    AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 
    c.category_id, c.name
HAVING 
    SUM(p.amount) > 0;


--Task 2

CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(
    quarter_val INT,
    year_val INT
) 
RETURNS TABLE (
    category_id INT,
    category_name TEXT,
    total_sales_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.category_id, 
        c.name AS category_name, 
        SUM(p.amount) AS total_sales_revenue
    FROM 
        category c
        JOIN film_category fc ON c.category_id = fc.category_id
        JOIN inventory i ON fc.film_id = i.film_id
        JOIN rental r ON i.inventory_id = r.inventory_id
        JOIN payment p ON r.rental_id = p.rental_id
    WHERE 
        EXTRACT(QUARTER FROM p.payment_date) = quarter_val
        AND EXTRACT(YEAR FROM p.payment_date) = year_val
    GROUP BY 
        c.category_id, c.name
    HAVING 
        SUM(p.amount) > 0;
END;
$$ LANGUAGE plpgsql;
SELECT * FROM get_sales_revenue_by_category_qtr(1, 2024);



--Task 3


CREATE OR REPLACE FUNCTION most_popular_films_by_countries(countries TEXT[])
RETURNS TABLE (
    country TEXT,
    most_popular_film TEXT,
    rating MPAA_RATING,
    language_name CHARACTER(20),
    length SMALLINT,
    release_year YEAR
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        films.country, 
        films.most_popular_film, 
        films.rating, 
        films.language_name, 
        films.length, 
        films.release_year
    FROM (
        SELECT 
            c.country, 
            f.title AS most_popular_film, 
            f.rating, 
            l.name AS language_name, 
            f.length, 
            f.release_year,
            ROW_NUMBER() OVER (PARTITION BY c.country ORDER BY counts.rental_count DESC, f.film_id) AS row_number
        FROM (
            SELECT 
                c.country, 
                i.film_id, 
                COUNT(*) AS rental_count
            FROM 
                country c
                JOIN city ci ON c.country_id = ci.country_id
                JOIN address a ON ci.city_id = a.city_id
                JOIN customer cu ON a.address_id = cu.address_id
                JOIN rental r ON cu.customer_id = r.customer_id
                JOIN inventory i ON r.inventory_id = i.inventory_id
            WHERE 
                UPPER(c.country) = ANY(SELECT UPPER(unnest(countries))) -- Case-insensitive country name comparison
            GROUP BY 
                c.country, i.film_id
        ) AS counts
        JOIN film f ON counts.film_id = f.film_id
        JOIN language l ON f.language_id = l.language_id
        JOIN country c ON counts.country = c.country -- Join to retrieve country name
    ) AS films
    WHERE 
        films.row_number = 1; -- Selects the first film in case of ties (based on rental_count and film_id)
END;
$$;

SELECT * FROM most_popular_films_by_countries(ARRAY['INDIA']);
SELECT * FROM most_popular_films_by_countries(ARRAY['Afghanistan', 'Brazil', 'United States']);

--Task 4
DROP FUNCTION IF EXISTS core.films_in_stock_by_title(partial_title TEXT);

CREATE OR REPLACE FUNCTION core.films_in_stock_by_title(partial_title TEXT)
RETURNS TABLE (
    row_num INTEGER,
    film_title TEXT,
    language_name CHARACTER(20),
    customer_name TEXT,
    rental_date TIMESTAMP WITH TIME ZONE
) 
AS $$
BEGIN
    RETURN QUERY 
        SELECT 
            CAST(ROW_NUMBER() OVER () AS INTEGER) AS row_num,
            f.title AS film_title,
            l.name AS language_name,
            CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
            r.rental_date
        FROM 
            film f
            JOIN language l ON f.language_id = l.language_id
            JOIN inventory i ON f.film_id = i.film_id
            JOIN rental r ON i.inventory_id = r.inventory_id
            JOIN customer c ON r.customer_id = c.customer_id
        WHERE 
            f.title ILIKE partial_title
            AND r.return_date IS NULL -- Only films currently in stock (not returned yet)
            AND r.rental_date = (
                SELECT MAX(r2.rental_date)
                FROM rental r2
                WHERE r2.inventory_id = i.inventory_id
            )
        ORDER BY 
            f.title, r.rental_date DESC;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM core.films_in_stock_by_title('%love%');



--Task 5
DROP FUNCTION IF EXISTS new_movie;

CREATE OR REPLACE FUNCTION new_movie(p_movie_title TEXT, p_release_year INT = EXTRACT(YEAR FROM CURRENT_DATE)::INT, p_language_name TEXT = 'Klingon')
RETURNS VOID AS $$
DECLARE 
    v_language_id INT;
BEGIN
    -- Normalize the language name for case-insensitive comparison
    p_language_name := LOWER(p_language_name);

    -- Check if the language exists
    SELECT language_id INTO v_language_id 
    FROM language 
    WHERE LOWER(name) = p_language_name;

    -- If language does not exist, insert a new language
    IF v_language_id IS NULL THEN
        INSERT INTO language (name)
        VALUES (p_language_name)
        RETURNING language_id INTO v_language_id;
    END IF;

    -- Insert a new movie
    INSERT INTO film (title, release_year, language_id, rental_rate, rental_duration, replacement_cost)
    VALUES (p_movie_title, p_release_year, v_language_id, 4.99, 3, 19.99);
END; 
$$ LANGUAGE plpgsql;






--rewards_report task 6 playground
DROP FUNCTION IF EXISTS rewards_report;

CREATE OR REPLACE FUNCTION public.rewards_report(min_monthly_purchases integer, min_dollar_amount_purchased numeric)
 RETURNS TABLE (
    customer_id INTEGER,
    first_name TEXT,
    last_name TEXT
)
 LANGUAGE plpgsql
AS $function$
DECLARE
    last_month_start DATE;
    last_month_end DATE;
BEGIN
    IF min_monthly_purchases = 0 THEN
        RAISE EXCEPTION 'Minimum monthly purchases parameter must be > 0';
    END IF;
    IF min_dollar_amount_purchased = 0.00 THEN
        RAISE EXCEPTION 'Minimum monthly dollar amount purchased parameter must be > $0.00';
    END IF;

    last_month_start := CURRENT_DATE - '1 month'::interval;
    last_month_start := to_date((extract(YEAR FROM last_month_start) || '-' || extract(MONTH FROM last_month_start) || '-01'),'YYYY-MM-DD');
    last_month_end := LAST_DAY(last_month_start);

    RETURN QUERY
    SELECT c.customer_id, c.first_name, c.last_name
    FROM payment AS p
    INNER JOIN customer AS c ON p.customer_id = c.customer_id
    WHERE DATE(p.payment_date) BETWEEN last_month_start AND last_month_end
    GROUP BY c.customer_id, c.first_name, c.last_name
    HAVING SUM(p.amount) > min_dollar_amount_purchased
    AND COUNT(p.customer_id) > min_monthly_purchases;
END
$function$



SELECT * FROM rewards_report(5, 10.00);

SELECT pg_get_functiondef('_group_concat'::regproc);



