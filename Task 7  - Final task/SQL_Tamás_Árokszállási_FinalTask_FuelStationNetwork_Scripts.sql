-- Create the database
CREATE DATABASE fuel_station_management;


-- Create schema for fuel network
CREATE SCHEMA fsn;

-- Create FuelType table
CREATE TABLE FSN.FuelType (
    fuel_type_id SERIAL PRIMARY KEY,
    fuel_name VARCHAR(100) NOT NULL,
    description TEXT
);

-- Create FuelStation table
CREATE TABLE FSN.FuelStation (
    station_id SERIAL PRIMARY KEY,
    station_name VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    employee_id INT  -- No foreign key constraint yet
);

-- Create Employee table
CREATE TABLE FSN.Employee (
    employee_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(100) NOT NULL,
    station_id INT  -- No foreign key constraint yet
);

-- Add foreign key constraints using ALTER TABLE
ALTER TABLE FSN.Employee
    ADD CONSTRAINT fk_employee_station_id FOREIGN KEY (station_id) REFERENCES FSN.FuelStation(station_id);

ALTER TABLE FSN.FuelStation
    ADD CONSTRAINT fk_employee_id FOREIGN KEY (employee_id) REFERENCES FSN.Employee(employee_id);
   
   -- Create Customer table
CREATE TABLE FSN.Customer (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL
);

-- Create FuelPrice table
CREATE TABLE FSN.FuelPrice (
    price_id SERIAL PRIMARY KEY,
    fuel_type_id INT NOT NULL,
    station_id INT NOT NULL,
    regular_price DECIMAL(10, 2) NOT NULL,
    discounted_price DECIMAL(10, 2),
    CONSTRAINT fk_fuel_price_fuel_type_id FOREIGN KEY (fuel_type_id) REFERENCES FSN.FuelType(fuel_type_id),
    CONSTRAINT fk_fuel_price_station_id FOREIGN KEY (station_id) REFERENCES FSN.FuelStation(station_id),
    CONSTRAINT chk_positive_prices CHECK (regular_price >= 0 AND discounted_price >= 0)
);

-- Create FuelSale table
CREATE TABLE FSN.FuelSale (
    sale_id SERIAL PRIMARY KEY,
    station_id INT NOT NULL,
    fuel_type_id INT NOT NULL,
    sale_datetime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    quantity DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    customer_id INT,
    CONSTRAINT fk_fuel_sale_station_id FOREIGN KEY (station_id) REFERENCES FSN.FuelStation(station_id),
    CONSTRAINT fk_fuel_sale_fuel_type_id FOREIGN KEY (fuel_type_id) REFERENCES FSN.FuelType(fuel_type_id),
    CONSTRAINT fk_fuel_sale_customer_id FOREIGN KEY (customer_id) REFERENCES FSN.Customer(customer_id),
    CONSTRAINT chk_sale_datetime CHECK (sale_datetime >= '2024-01-01')
);


-- Create FuelReplenishment table
CREATE TABLE FSN.FuelReplenishment (
    replenish_id SERIAL PRIMARY KEY,
    station_id INT NOT NULL,
    fuel_type_id INT NOT NULL,
    supplier VARCHAR(100) NOT NULL,
    delivery_date DATE NOT NULL,
    quantity_received DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_fuel_replenish_station_id FOREIGN KEY (station_id) REFERENCES FSN.FuelStation(station_id),
    CONSTRAINT fk_fuel_replenish_fuel_type_id FOREIGN KEY (fuel_type_id) REFERENCES FSN.FuelType(fuel_type_id),
    CONSTRAINT chk_positive_quantity_received CHECK (quantity_received >= 0)
);

-- Create FuelStationType table (for many-to-many relationship)
CREATE TABLE FSN.FuelStationType (
    station_id INT NOT NULL,
    fuel_type_id INT NOT NULL,
    name VARCHAR(100),
    phone VARCHAR(20),
    CONSTRAINT fk_fuel_station_type_station_id FOREIGN KEY (station_id) REFERENCES FSN.FuelStation(station_id),
    CONSTRAINT fk_fuel_station_type_fuel_type_id FOREIGN KEY (fuel_type_id) REFERENCES FSN.FuelType(fuel_type_id),
    CONSTRAINT chk_fuel_station_type_name_not_null CHECK (name IS NOT NULL),
    CONSTRAINT chk_fuel_station_type_phone_format CHECK (phone ~ '^[0-9]{10}$')  -- Example check constraint for phone format
);

INSERT INTO FSN.FuelType (fuel_name, description)
SELECT 'Gasoline', 'High-octane petrol for vehicles'
WHERE NOT EXISTS (SELECT 1 FROM FSN.FuelType WHERE fuel_name = 'Gasoline');

INSERT INTO FSN.FuelType (fuel_name, description)
SELECT 'Diesel', 'Fuel for diesel engines'
WHERE NOT EXISTS (SELECT 1 FROM FSN.FuelType WHERE fuel_name = 'Diesel');

ALTER TABLE FSN.Customer
ADD CONSTRAINT unique_customer_phone UNIQUE (phone);

INSERT INTO FSN.Customer (name, phone, email)
SELECT 'John Doe', '1234567890', 'john.doe@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM FSN.Customer WHERE phone = '1234567890'
);

INSERT INTO FSN.Customer (name, phone, email)
SELECT 'Jane Smith', '9876543210', 'jane.smith@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM FSN.Customer WHERE phone = '9876543210'
);


INSERT INTO FSN.Employee (name, role, station_id)
SELECT 'Manager A', 'Station Manager', fs.station_id
FROM FSN.FuelStation fs
WHERE fs.station_name = 'Station 1'
AND NOT EXISTS (
    SELECT 1
    FROM FSN.Employee e
    WHERE e.name = 'Manager A'
    AND e.role = 'Station Manager'
    AND e.station_id = fs.station_id
);

INSERT INTO FSN.FuelStation (station_name, location, employee_id)
SELECT 'Station 1', '123 Main St, City A', e.employee_id
FROM FSN.Employee e
WHERE e.name = 'Manager A'
AND NOT EXISTS (
    SELECT 1 FROM FSN.FuelStation WHERE station_name = 'Station 1'
);

INSERT INTO FSN.FuelPrice (fuel_type_id, station_id, regular_price, discounted_price)
SELECT ft.fuel_type_id, fs.station_id, 2.50, 2.40
FROM FSN.FuelType ft
CROSS JOIN FSN.FuelStation fs
WHERE ft.fuel_name = 'Gasoline'
AND fs.station_name = 'Station 1'
AND NOT EXISTS (
    SELECT 1
    FROM FSN.FuelPrice fp
    WHERE fp.fuel_type_id = ft.fuel_type_id
    AND fp.station_id = fs.station_id
);

INSERT INTO FSN.FuelSale (station_id, fuel_type_id, quantity, payment_method, customer_id)
SELECT fs.station_id, ft.fuel_type_id, 30.5, 'Credit Card', c.customer_id
FROM FSN.FuelStation fs
JOIN FSN.FuelType ft ON fs.station_name = 'Station 1' AND ft.fuel_name = 'Gasoline'
JOIN FSN.Customer c ON c.name = 'John Doe'
WHERE NOT EXISTS (
    SELECT 1
    FROM FSN.FuelSale f
    WHERE f.station_id = fs.station_id
    AND f.fuel_type_id = ft.fuel_type_id
    AND f.customer_id = c.customer_id
);


INSERT INTO FSN.FuelReplenishment (station_id, fuel_type_id, supplier, delivery_date, quantity_received)
SELECT fs.station_id, ft.fuel_type_id, 'Fuel Supplier A', '2024-04-15', 5000.0
FROM FSN.FuelStation fs
JOIN FSN.FuelType ft ON fs.station_name = 'Station 1' AND ft.fuel_name = 'Gasoline'
WHERE NOT EXISTS (
    SELECT 1
    FROM FSN.FuelReplenishment fr
    WHERE fr.station_id = fs.station_id
    AND fr.fuel_type_id = ft.fuel_type_id
);


INSERT INTO FSN.FuelStationType (station_id, fuel_type_id, name, phone)
SELECT fs.station_id, ft.fuel_type_id, 'Station 1 Gasoline Services', '123-456-7890'
FROM FSN.FuelStation fs
JOIN FSN.FuelType ft ON fs.station_name = 'Station 1' AND ft.fuel_name = 'Gasoline'
WHERE NOT EXISTS (
    SELECT 1
    FROM FSN.FuelStationType fst
    WHERE fst.station_id = fs.station_id
    AND fst.fuel_type_id = ft.fuel_type_id
);

-- 5.1 functions

CREATE OR REPLACE FUNCTION update_table_row(
    p_key_value INT,  -- Primary key value of the row to update
    p_column_name TEXT,  -- Name of the column to update
    p_new_value TEXT  -- New value to set for the specified column
)
RETURNS VOID AS $$
BEGIN
    -- Dynamically build and execute the update statement
    EXECUTE format('UPDATE FSN.YourTableName SET %I = $1 WHERE primary_key_column = $2', p_column_name)
    USING p_new_value, p_key_value;
    
    -- Output a message indicating successful update
    RAISE NOTICE 'Row updated successfully';
END;
$$ LANGUAGE plpgsql;

--5.2
CREATE OR REPLACE FUNCTION add_new_transaction(
    p_station_id INT,
    p_fuel_type_id INT,
    p_sale_datetime TIMESTAMP,
    p_quantity DECIMAL(10, 2),
    p_payment_method VARCHAR(50),
    p_customer_id INT
)
RETURNS VOID AS $$
BEGIN
    -- Insert a new transaction record into the FuelSale table
    INSERT INTO FSN.FuelSale (station_id, fuel_type_id, sale_datetime, quantity, payment_method, customer_id)
    VALUES (p_station_id, p_fuel_type_id, p_sale_datetime, p_quantity, p_payment_method, p_customer_id);

    -- Output a message indicating successful insertion
    RAISE NOTICE 'New transaction added successfully';
END;
$$ LANGUAGE plpgsql;


--6

CREATE OR REPLACE VIEW recent_quarter_analytics AS
SELECT
    fs.station_id,
    ft.fuel_name,
    fstat.station_name,
    fstat.location,
    COUNT(*) AS total_transactions,
    SUM(fs.quantity) AS total_quantity_sold,
    SUM(fs.quantity * fp.regular_price) AS total_revenue
FROM
    FSN.FuelSale fs
JOIN
    FSN.FuelType ft ON fs.fuel_type_id = ft.fuel_type_id
JOIN
    FSN.FuelPrice fp ON fs.station_id = fp.station_id
                      AND fs.fuel_type_id = fp.fuel_type_id
JOIN
    FSN.FuelStation fstat ON fs.station_id = fstat.station_id
WHERE
    fs.sale_datetime >= date_trunc('quarter', CURRENT_DATE)  -- Start of current quarter
    AND fs.sale_datetime < date_trunc('quarter', CURRENT_DATE) + INTERVAL '3 months'  -- End of current quarter
GROUP BY
    fs.station_id,
    ft.fuel_name,
    fstat.station_name,
    fstat.location;

SELECT * FROM recent_quarter_analytics;


-- 7

CREATE ROLE manager_role;
GRANT SELECT ON ALL TABLES IN SCHEMA FSN TO manager_role;
ALTER ROLE manager_role LOGIN;
ALTER DEFAULT PRIVILEGES IN SCHEMA FSN
    GRANT SELECT ON TABLES TO manager_role;
   
   









