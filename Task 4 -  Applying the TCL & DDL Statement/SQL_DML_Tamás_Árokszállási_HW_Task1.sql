--TASK 1

INSERT INTO public.film (title, rental_rate, rental_duration, language_id, last_update)
SELECT 'The Hobbit: Unexpected Journey', 4.99, 1, language_id, CURRENT_DATE
FROM language
WHERE LOWER(name) = LOWER('English') AND NOT EXISTS (
    SELECT 1 FROM public.film WHERE LOWER(title) = LOWER('The Hobbit: Unexpected Journey')
)
RETURNING film_id;

INSERT INTO public.film (title, rental_rate, rental_duration, language_id, last_update)
SELECT 'Analyze This', 9.99, 2, language_id, CURRENT_DATE
FROM language
WHERE LOWER(name) = LOWER('English') AND NOT EXISTS (
    SELECT 1 FROM public.film WHERE LOWER(title) = LOWER('Analyze This');

INSERT INTO public.film (title, rental_rate, rental_duration, language_id, last_update)
SELECT 'Lord Of The Rings: Return Of The King', 19.99, 3, language_id, CURRENT_DATE
FROM language
WHERE LOWER(name) = LOWER('English') AND NOT EXISTS (
    SELECT 1 FROM public.film WHERE LOWER(title) = LOWER('Lord Of The Rings: Return Of The King');



-- Realized that it is a bit easier way to add actors into.
-- Insert actors into the 'actor' table whom are belongig to my fav. movies.
INSERT INTO public.actor (first_name, last_name, last_update)
values('Martin', 'Freeman', Current_date),
('Ian', 'McKellen', Current_date),
('Robert', 'DeNiro', Current_date),
('Bill', 'Crystal', Current_date),
('Elijah', 'Wood', Current_date),
('Sean', 'Austin', Current_date);

--task 2
INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT actor.actor_id, film.film_id, CURRENT_DATE
FROM public.actor, public.film
WHERE LOWER(actor.first_name) = LOWER('Martin') AND LOWER(actor.last_name) = LOWER('Freeman')
AND LOWER(film.title) IN (LOWER('The Hobbit: Unexpected Journey'))
ON CONFLICT (actor_id, film_id) DO NOTHING;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT actor.actor_id, film.film_id, CURRENT_DATE
FROM public.actor, public.film
WHERE LOWER(actor.first_name) = LOWER('Ian') AND LOWER(actor.last_name) = LOWER('McKellen')
AND LOWER(film.title) IN (LOWER('The Hobbit: Unexpected Journey'))
ON CONFLICT (actor_id, film_id) DO NOTHING;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT actor.actor_id, film.film_id, CURRENT_DATE
FROM public.actor, public.film
WHERE LOWER(actor.first_name) = LOWER('Robert') AND LOWER(actor.last_name) = LOWER('DeNiro')
AND LOWER(film.title) IN (LOWER('Analyze This'))
ON CONFLICT (actor_id, film_id) DO NOTHING;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT actor.actor_id, film.film_id, CURRENT_DATE
FROM public.actor, public.film
WHERE LOWER(actor.first_name) = LOWER('Bill') AND LOWER(actor.last_name) = LOWER('Crystal')
AND LOWER(film.title) IN (LOWER('Analyze This'))
ON CONFLICT (actor_id, film_id) DO NOTHING;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT actor.actor_id, film.film_id, CURRENT_DATE
FROM public.actor, public.film
WHERE LOWER(actor.first_name) = LOWER('Elijah') AND LOWER(actor.last_name) = LOWER('woods')
AND LOWER(film.title) IN (LOWER('Lord Of The Rings: Return Of The King'))
ON CONFLICT (actor_id, film_id) DO NOTHING;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT actor.actor_id, film.film_id, CURRENT_DATE
FROM public.actor, public.film
WHERE LOWER(actor.first_name) = LOWER('Sean') AND LOWER(actor.last_name) = LOWER('Austin')
AND LOWER(film.title) IN (LOWER('Lord Of The Rings: Return Of The King'))
ON CONFLICT (actor_id, film_id) DO NOTHING;



--task 3 
INSERT INTO public.inventory (film_id, store_id)
SELECT film.film_id, store.store_id
FROM public.film, (SELECT store_id FROM public.store LIMIT 1) AS store
WHERE LOWER(film.title) = LOWER('Analyze This') AND
NOT EXISTS (SELECT 1 FROM public.inventory WHERE film_id = film.film_id AND store_id = store.store_id);

INSERT INTO public.inventory (film_id, store_id)
SELECT film.film_id, store.store_id
FROM public.film, (SELECT store_id FROM public.store LIMIT 1) AS store
WHERE LOWER(film.title) = LOWER('The Hobbit: Unexpected Journey') AND
NOT EXISTS (SELECT 1 FROM public.inventory WHERE film_id = film.film_id AND store_id = store.store_id);

INSERT INTO public.inventory (film_id, store_id)
SELECT film.film_id, store.store_id
FROM public.film, (SELECT store_id FROM public.store LIMIT 1) AS store
WHERE LOWER(film.title) = LOWER('Lord Of The Rings: Return Of The King') AND
NOT EXISTS (SELECT 1 FROM public.inventory WHERE film_id = film.film_id AND store_id = store.store_id);

--Task 4 

WITH eligible_customers AS (
    SELECT customer_id
    FROM customer
    WHERE customer_id IN (
        SELECT customer_id
        FROM rental
        GROUP BY customer_id
        HAVING COUNT(rental_id) >= 43
    ) AND customer_id IN (
        SELECT customer_id
        FROM payment
        GROUP BY customer_id
        HAVING COUNT(payment_id) >= 43
    ) and customer_id = '111'
    LIMIT 1
)
UPDATE customer
SET first_name = 'Tamás',
    last_name = 'Árokszállási',
    email = 'arokthomas@gmail.com',
    address_id = 5
FROM eligible_customers
WHERE customer.customer_id = eligible_customers.customer_id;

select * from customer;
--checking im in :)
select * from customer where first_name in ('Tamás');






 

 --'Customer' and 'Inventory' to delete the records from it.

DELETE FROM public.rental 
WHERE customer_id = (
    SELECT customer_id 
    FROM customer
    WHERE LOWER(email) = LOWER('arokthomas@gmail.com')
);

DELETE FROM public.payment 
WHERE customer_id = (
    SELECT customer_id 
    FROM customer
    WHERE LOWER(email) = LOWER('arokthomas@gmail.com')
);

 
 

-- Insert a new rental record, i choose Mike Hillyer randomly as the staff.

INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
SELECT CURRENT_DATE, inv.inventory_id, cust.customer_id, CURRENT_TIMESTAMP + INTERVAL '7 days', stf.staff_id
FROM (
    SELECT inventory_id FROM public.inventory WHERE film_id = (SELECT film_id from film where LOWER(title) = LOWER('The Hobbit: Unexpected Journey'))
) inv,
(
    SELECT customer_id FROM public.customer WHERE customer_id = (SELECT customer_id FROM customer WHERE LOWER(email) = LOWER('BETTY.WHITE@sakilacustomer.org'))
) cust,
(
    SELECT staff_id FROM public.staff WHERE staff_id = (SELECT staff_id from staff where store_id = (SELECT store_id FROM store LIMIT 1) and LOWER(first_name) = LOWER('Mike'))
) stf
WHERE NOT EXISTS (
    SELECT 1 FROM public.rental 
    WHERE inventory_id = inv.inventory_id 
    AND customer_id = cust.customer_id 
    AND staff_id = stf.staff_id
);


-- just checking the successfully inserted row :)
SELECT * from rental where customer_id = (SELECT customer_id from customer where email = 'BETTY.WHITE@sakilacustomer.org');


-- first of all, i have to create a new partition.
CREATE TABLE public.payment_y2024 PARTITION OF payment
FOR VALUES FROM ('2024-03-17') TO ('2024-07-18');

-- inserting a transaction into the payment table.
INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT cust.customer_id, stf.staff_id, rental.rental_id, 10, CURRENT_DATE
FROM public.customer cust, public.rental rental, public.staff stf
WHERE cust.customer_id = (SELECT customer_id from customer where LOWER(email) = LOWER('BETTY.WHITE@sakilacustomer.org')) 
and rental.rental_id = (SELECT rental_id from public.rental where customer_id = cust.customer_id)
and stf.staff_id = (SELECT staff_id from staff where store_id = (SELECT store_id FROM store LIMIT 1) and LOWER(first_name) = LOWER('Mike'));




