--Task 2.1
DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rentaluser') THEN
        CREATE ROLE rentaluser LOGIN PASSWORD 'rentalpassword' VALID UNTIL 'infinity';
        GRANT CONNECT ON DATABASE dvdrental TO rentaluser;
    END IF;
END
$$;



--Task 2.2

GRANT SELECT ON TABLE customer TO rentaluser;

SET ROLE rentaluser;
SELECT * FROM customer;
RESET ROLE;


--Task 2.3
CREATE Group rental;
GRANT rental TO rentaluser;

--Task 2.4

GRANT INSERT, UPDATE ON TABLE rental TO rental;
GRANT USAGE, SELECT ON SEQUENCE rental_rental_id_seq TO rental;


SET ROLE rental;
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES ( 1, 123, NULL, 1);
RESET ROLE;


--Task 2.5
-- Switch back to the appropriate role (e.g., 'postgres') before revoking permissions
RESET ROLE;

REVOKE INSERT ON TABLE rental FROM GROUP rental;

SET ROLE rental;

-- Define variables for dynamic values
-- Define variables for dynamic values
DO $$
DECLARE
    p_customer_id INT;
    p_inventory_id INT;
    p_staff_id INT;
BEGIN
    -- Select random customer and inventory for rental
    SELECT customer_id, inventory_id, staff_id
    INTO p_customer_id, p_inventory_id, p_staff_id
    FROM (
        SELECT c.customer_id, i.inventory_id, s.staff_id
        FROM customer c
        CROSS JOIN inventory i
        CROSS JOIN staff s
        WHERE EXISTS (SELECT 1 FROM payment WHERE customer_id = c.customer_id)
          AND NOT EXISTS (SELECT 1 FROM rental r WHERE r.customer_id = c.customer_id AND r.inventory_id = i.inventory_id)
        ORDER BY RANDOM()
        LIMIT 1
    ) AS random_rental;

    -- Insert a new row into the 'rental' table with dynamic values
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
    VALUES (CURRENT_DATE, p_inventory_id, p_customer_id, NULL, p_staff_id);

    RAISE NOTICE 'New rental inserted successfully.';
END $$;




--Task 2.6
-- Define a function to create personalized roles for eligible customers
DO $$
DECLARE
    customer_record RECORD;
    role_name TEXT;
BEGIN
    -- Fetch customers who have both payment and rental history
    FOR customer_record IN
        SELECT c.customer_id, c.first_name, c.last_name
        FROM customer c
        WHERE EXISTS (SELECT 1 FROM payment WHERE customer_id = c.customer_id)
          AND EXISTS (SELECT 1 FROM rental WHERE customer_id = c.customer_id)
    LOOP
        -- Generate role name based on customer's first_name and last_name
        role_name := 'client_' || REPLACE(customer_record.first_name, ' ', '_') || '_' || REPLACE(customer_record.last_name, ' ', '_');

        -- Check if the role already exists
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = role_name) THEN
            -- Create the role if it doesn't exist
            EXECUTE 'CREATE ROLE ' || quote_ident(role_name);

            RAISE NOTICE 'Created role: %', role_name;
        ELSE
            RAISE NOTICE 'Role already exists: %', role_name;
        END IF;
    END LOOP;
END $$;

--TASK 3

DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'customer_role') THEN
        CREATE ROLE customer_role LOGIN PASSWORD 'customerpassword' VALID UNTIL 'infinity';
        GRANT CONNECT ON DATABASE dvdrental TO customer_role;
    END IF;
END
$$;

-- Enable row-level security on the rental table
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;

-- Define a row-level security policy for the rental table
CREATE POLICY rental_access_policy
    ON rental
    FOR SELECT
    USING (customer_id = current_setting('app.user_id')::int);

   
   -- Set the current user's customer_id (replace 123 with the actual customer_id)
SELECT set_config('app.user_id', '123', true);
SET ROLE customer_role;

-- Query rental data for the current user
SELECT * FROM rental;

-- Query payment data for the current user
SELECT * FROM payment;
RESET ROLE;


