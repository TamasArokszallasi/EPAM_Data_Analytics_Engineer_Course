CREATE OR REPLACE FUNCTION get_client_info(
    p_client_id INT,
    p_left_boundary DATE,
    p_right_boundary DATE
)
RETURNS TABLE (
    metric_name VARCHAR,
    metric_value VARCHAR
) AS $$
BEGIN 
   RETURN QUERY 
   SELECT 'Customer Info' AS metric_name, 
          (SELECT name || ' ' || surname || ', ' || email 
           FROM customers 
           WHERE customer_id = p_client_id) AS metric_value
   UNION ALL
   SELECT 'Number of Films Rented', 
          (SELECT COUNT(*)::VARCHAR 
           FROM rentals 
           WHERE customer_id = p_client_id AND rental_date BETWEEN p_left_boundary AND p_right_boundary)
   UNION ALL
   SELECT 'Rented Films Titles', 
          (SELECT STRING_AGG(title, ', ') 
           FROM films 
           JOIN inventory ON films.film_id = inventory.film_id 
           JOIN rentals ON inventory.inventory_id = rentals.inventory_id 
           WHERE rentals.customer_id = p_client_id AND rental_date BETWEEN p_left_boundary AND p_right_boundary)
   UNION ALL
   SELECT 'Number of Payments', 
          (SELECT COUNT(*)::VARCHAR 
           FROM payments 
           WHERE customer_id = p_client_id AND payment_date BETWEEN p_left_boundary AND p_right_boundary)
   UNION ALL
   SELECT 'Payments Amount', 
          (SELECT COALESCE(SUM(amount), 0)::VARCHAR 
           FROM payments 
           WHERE customer_id = p_client_id AND payment_date BETWEEN p_left_boundary AND p_right_boundary);
END; $$ LANGUAGE plpgsql;
