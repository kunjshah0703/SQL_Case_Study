-- CASE STUDY 1

/*
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture 
and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured 
some very basic data from their few months of operation but have no idea how to use their data to help them run 
the business.

*/

/*

Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting
patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper 
connection with his customers will help him deliver a better and more personalised experience for his 
loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty 
program - additionally he needs help to generate some basic datasets so his team can easily inspect the data 
without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that 
these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:

sales
menu
members

*/


CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


/* 1. What is the total amount each customer spent at the restaurant? */

SELECT * FROM members
SELECT * FROM menu
SELECT * FROM sales

SELECT s.customer_id, SUM(m.price) AS total_spent
FROM menu AS m
LEFT JOIN sales AS s -- For optimization use smaller table first for LEFT JOIN
ON s.product_id = m.product_id
GROUP BY s.customer_id

/* 2. How many days has each customer visited the restaurant? */

SELECT * FROM members
SELECT * FROM menu
SELECT * FROM sales

SELECT customer_id, COUNT(DISTINCT order_date) AS no_days_visited
FROM sales
GROUP By customer_id

SELECT customer_id, MAX(dnk) AS no_of_days_visited FROM(
SELECT customer_id
, DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS dnk
FROM sales) A
GROUP BY customer_id

/* 3. What was the first item from the menu purchased by each customer? */

SELECT * FROM members
SELECT * FROM menu
SELECT * FROM sales

WITH cte
AS
(
SELECT s.customer_id, m.product_name, s.order_date
, RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
FROM menu AS m
LEFT JOIN sales AS s
ON m.product_id = s.product_id)
SELECT * FROM cte WHERE rnk = 1
-- ORDER BY s.customer_id

/* 4. What is the most purchased item on the menu and how many times was it purchased by all customers? */

SELECT * FROM members
SELECT * FROM menu
SELECT * FROM sales;

WITH cte1
AS
(
SELECT  TOP (1) m.product_id,m.product_name, COUNT(1) AS purchase_count
FROM menu AS m
LEFT JOIN sales AS s
ON m.product_id = s.product_id
GROUP BY m.product_id,m.product_name
ORDER BY purchase_count DESC)
SELECT c.product_id, c.product_name,s1.customer_id, COUNT(1) AS total_times_purchased 
FROM cte1 AS c
LEFT JOIN sales AS s1
ON c.product_id = s1.product_id
GROUP BY c.product_id, c.product_name, s1.customer_id

/* 5. Which item was the most popular for each customer? */

SELECT * FROM members;
SELECT * FROM menu;
SELECT * FROM sales;

WITH fav_item
AS
(
SELECT s.customer_id, COUNT(s.product_id) AS ordered, m.product_name
, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS drnk
FROM sales AS s
LEFT JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name)
SELECT customer_id, product_name, ordered
FROM fav_item
WHERE drnk = 1

--WITH cte3
--AS
--(
--SELECT s.customer_id, s.product_id, COUNT(s.product_id) AS ordered--, m.product_name
----, DENSE_RANK() OVER(PARTITION BY s.customer_id, COUNT(s.product_id) ORDER BY s.customer_id) AS drnk
--FROM sales AS s
----LEFT JOIN menu AS m
----ON s.product_id = m.product_id
--GROUP BY s.customer_id, s.product_id--, m.product_name--, s.product_id
--), cte4
--AS
--(
--SELECT *
--, DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY ordered) AS drnk, m.product_name
--FROM cte3
--LEFT JOIN menu AS m
--ON cte3.product_id = m.product_id)
--SELECT * FROM cte4 WHERE drnk = 1

/* 6. Which item was purchased first by the customer after they became a member? */

SELECT * FROM members;
SELECT * FROM menu;
SELECT * FROM sales;

WITH mem_order
AS
(
SELECT s.customer_id, s.order_date, m.join_date, s.product_id
, ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
FROM sales AS s
LEFT JOIN members AS m
ON s.customer_id = m.customer_id
WHERE s.order_date >= m.join_date)
SELECT m1.customer_id, m1.join_date, m1.order_date, m2.product_name
FROM mem_order AS m1
LEFT JOIN menu AS m2
ON m1.product_id = m2.product_id
WHERE m1.rn = 1

/* 7. Which item was purchased just before the customer became a member? */

WITH mem_order
AS
(
SELECT s.customer_id, s.order_date, m.join_date, s.product_id
--, ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
FROM sales AS s
LEFT JOIN members AS m
ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date)
SELECT m1.customer_id, m1.join_date, m1.order_date, m2.product_name
FROM mem_order AS m1
LEFT JOIN menu AS m2
ON m1.product_id = m2.product_id

/* 8. What is the total items and amount spent for each member before they became a member? */


SELECT s.customer_id, COUNT(s.product_id) AS no_of_items, SUM(m1.price) AS total_Spent
FROM sales AS s
LEFT JOIN members AS m
ON s.customer_id = m.customer_id
LEFT JOIN menu AS m1
ON s.product_id = m1.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id

/* 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each 
customer have? */

SELECT * FROM members
SELECT * FROM menu
SELECT * FROM sales

SELECT s.customer_id
, SUM(CASE WHEN m.product_id = 1 THEN m.price * 20 ELSE m.price * 10 END) AS total_points
FROM menu AS m
LEFT JOIN sales AS s
ON m.product_id = s.product_id
GROUP BY s.customer_id

/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points 
on all items, not just sushi - how many points do customer A and B have at the end of January? */

SELECT * FROM members
SELECT * FROM menu
SELECT * FROM sales;

WITH date_cte
AS
(
SELECT *
, DATEADD(DAY, 6, join_date) AS first_week_date_after_joining
, EOMONTH('2021-01-01') AS last_date
FROM members
)
SELECT s.customer_id
, SUM(CASE WHEN m.product_id = 1 THEN  price * 20
	   WHEN s.order_date BETWEEN d.join_date AND d.first_week_date_after_joining THEN price * 20
	   ELSE price * 10
	   END) AS total_points
FROM date_cte AS d
LEFT JOIN menu AS m
LEFT JOIN sales AS s
ON m.product_id = s.product_id
ON d.customer_id = s.customer_id
WHERE s.order_date <= d.last_date
GROUP BY s.customer_id

/* 11. customer_id	order_date	product_name	price	member
A	2021-01-01	curry	15	N
A	2021-01-01	sushi	10	N
A	2021-01-07	curry	15	Y
A	2021-01-10	ramen	12	Y
A	2021-01-11	ramen	12	Y
A	2021-01-11	ramen	12	Y
B	2021-01-01	curry	15	N
B	2021-01-02	curry	15	N
B	2021-01-04	sushi	10	N
B	2021-01-11	sushi	10	Y
B	2021-01-16	ramen	12	Y
B	2021-02-01	ramen	12	Y
C	2021-01-01	ramen	12	N
C	2021-01-01	ramen	12	N
C	2021-01-07	ramen	12	N */

SELECT * FROM members
SELECT * FROM menu
SELECT * FROM sales;

SELECT s.customer_id, s.order_date, m.product_name, m.price
, CASE WHEN s.order_date >= m1.join_date THEN 'Y'
		ELSE 'N' END AS is_member
FROM sales AS s
LEFT JOIN menu AS m
ON s.product_id = m.product_id
LEFT JOIN members AS m1
ON s.customer_id = m1.customer_id
 

/* 12. customer_id	order_date	product_name	price	member	ranking
A	2021-01-01	curry	15	N	null
A	2021-01-01	sushi	10	N	null
A	2021-01-07	curry	15	Y	1
A	2021-01-10	ramen	12	Y	2
A	2021-01-11	ramen	12	Y	3
A	2021-01-11	ramen	12	Y	3
B	2021-01-01	curry	15	N	null
B	2021-01-02	curry	15	N	null
B	2021-01-04	sushi	10	N	null
B	2021-01-11	sushi	10	Y	1
B	2021-01-16	ramen	12	Y	2
B	2021-02-01	ramen	12	Y	3
C	2021-01-01	ramen	12	N	null
C	2021-01-01	ramen	12	N	null
C	2021-01-07	ramen	12	N	null */


WITH cte9
AS
(
SELECT s.customer_id, s.order_date, m.product_name, m.price
, CASE WHEN s.order_date >= m1.join_date THEN 'Y'
		ELSE 'N' END AS is_member
FROM sales AS s
LEFT JOIN menu AS m
ON s.product_id = m.product_id
LEFT JOIN members AS m1
ON s.customer_id = m1.customer_id)
SELECT *
, CASE WHEN is_member = 'N' THEN NULL
	ELSE DENSE_RANK() OVER(PARTITION BY customer_id, is_member ORDER BY order_date) END AS rank
FROM cte9