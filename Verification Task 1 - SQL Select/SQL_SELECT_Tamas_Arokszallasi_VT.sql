-- I'm joining multiple tables to filter out the necessary data and then grouping them
-- by category to calculate the total income.

with
Topcategories as (select c.name as Genre, SUM(p.amount) as total_sales
from category c 
join film_category fc
using(category_id) 
join film f
using(film_id) 
join inventory i
using (film_id)
join rental r using(inventory_id)
join payment p using(rental_id)
JOIN customer cu ON p.customer_id = cu.customer_id
JOIN address ad ON cu.address_id = ad.address_id
JOIN city ci ON ad.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id
WHERE co.country = 'USA'
group by 1
order by 2 desc)
select Topcategories.genre, Topcategories.total_sales 
from Topcategories
limit 3;



-- I'm using GROUP_CONCAT to concatenate all horror movies rented by each customer into one column.
-- The sum function is used to calculate the total amount paid for those rentals.
SELECT 
    cu.customer_id,
    GROUP_CONCAT(f.title ORDER BY f.title ASC) AS RentedHorrorMovies,
    SUM(p.amount) AS TotalPaidForHorrorMovies  
FROM payment p  
JOIN rental r ON p.rental_ID=r.rental_ID  
JOIN inventory i on r.inventory_ID=i.inventory_ID  
JOIN film f on i.film_ID=f.film_ID  
JOIN film_category fc on f.film_ID=fc.film_ID   
JOIN category c on fc.category_ID=c.category_ID   
LEFT JOIN customer cu on p.customer_Id=cu.customer_Id   
WHERE c.name='Horror'    
GROUP BY cu.customer_Id;    
