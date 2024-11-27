/* Question Set 1 - Easy */
--1. who is the most senior most employee based on job title?

SELECT * from employee
ORDER by levels DESC
limit 1

--2.which country have the most invoices?

SELECT 
	billing_country,
	count(invoice_id) as total_invoices
FROM invoice
group by 1
ORDER by 2 desc

--3.what are top 3 values of invoice?

SELECT total FROM invoice
ORDER by total desc
limit 3

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

SELECT
	billing_city,
	sum(total) as invoice_total
FROM invoice
GROUP by 1
ORDER by 2 DESC
limit 1

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

SELECT
	c.customer_id,
	c.first_name,
	c.last_name,
	sum(i.total) as total_spent
from customer as c
JOIN invoice as i
on c.customer_id = i.customer_id
GROUP by 1
ORDER by 4 desc
limit 1

/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

--method 1

SELECT 
	distinct c.email,
	c.first_name,
	c.last_name,
	g.name
FROM genre as g
JOIN track as t
on g.genre_id = t.genre_id
JOIN invoice_line as il
ON t.track_id = il.track_id
JOIN invoice as i
on il.invoice_id = i.invoice_id
JOIN customer as c
on c.customer_id = i.customer_id
WHERE
	g.name = 'Rock'
ORDER by 1

--method 2

SELECT DISTINCT email,first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoiceline ON invoice.invoice_id = invoiceline.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;


/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT 
	a.artist_id, 
	a.name,
	COUNT(a.artist_id) AS number_of_songs
FROM track as t
JOIN album as al
on al.album_id = t.album_id
JOIN artist as a
ON a.artist_id = al.artist_id
JOIN genre as g
ON g.genre_id = t.genre_id
WHERE g.name LIKE 'Rock'
GROUP BY 1
ORDER BY 3 DESC
LIMIT 10;

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT 
	name,
	milliseconds
from track
WHERE
	milliseconds > (select avg(milliseconds)
					from track)
order by milliseconds desc

/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

with best_selling_artist as 
(
SELECT
	a.artist_id as artist_id,
	a.name as artist_name,
	sum(il.unit_price * il.quantity) as total_sales
FROM invoice_line as il
JOIN track as t
on il.track_id = t.track_id
JOIN album as al
on al.album_id = t.album_id
JOIN artist as a
on al.artist_id = a.artist_id
group by 1
order by 3 desc
LIMIT 1
)
SELECT
	c.customer_id,
	c.first_name,
	c.last_name,
	bs.artist_name,
	sum(il.unit_price*il.quantity) as total_spent
FROM invoice as i
JOIN customer as c
on i.customer_id = c.customer_id
JOIN invoice_line as il
on il.invoice_id = i.invoice_id
JOIN track as t
on il.track_id = t.track_id
JOIN album as al
on al.album_id = t.album_id
JOIN best_selling_artist as bs
on bs.artist_id = al.artist_id
group by 1,2,3,4
ORDER by 5 desc

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method 1: Using CTE */

with popular_genre as
(
SELECT
	count(il.quantity) as purchases,
	c.country,
	g.name,
	g.genre_id,
	row_number() over(partition by c.country order by count(il.quantity) desc) as ranks
FROM invoice_line as il
JOIN invoice as i
on il.invoice_id = i.invoice_id
JOIN customer as c
on c.customer_id = i.customer_id
JOIN track as t
on t.track_id = il.track_id
JOIN genre as g
on g.genre_id = t.genre_id
group by 2,3,4
ORDER by 2, 1 desc
)
SELECT * from popular_genre
WHERE
	ranks = 1

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method 1: using CTE */

with customer_with_country as
(
select
	c.customer_id,
	c.first_name,
	c.last_name,
	i.billing_country,
	sum(i.total) as total_spent,
	row_number() over(partition by i.billing_country order by sum(total) desc) as ranks
from customer as c
join invoice as i
on c.customer_id = i.customer_id
group by 1,2,3,4
order by 4,5 desc
)
select * from customer_with_country
where
	ranks = 1