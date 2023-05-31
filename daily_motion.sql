CREATE TABLE customers (
    customer_id integer PRIMARY KEY,
    first_name varchar(100),
    last_name varchar(100),
    email varchar(100)
);

CREATE TABLE products (
    product_id integer PRIMARY KEY,
    product_name varchar(100),
    price decimal
);

CREATE TABLE orders (
    order_id integer PRIMARY KEY,
    customer_id integer,
    order_date date
);

CREATE TABLE order_items (
    order_id integer,
    product_id integer,
    quantity integer
);

INSERT INTO customers (customer_id, first_name, last_name, email) VALUES
(1, 'John', 'Doe', 'johndoe@email.com'),
(2, 'Jane', 'Smith', 'janesmith@email.com'),
(3, 'Bob', 'Johnson', 'bobjohnson@email.com'),
(4, 'Alice', 'Brown', 'alicebrown@email.com'),
(5, 'Charlie', 'Davis', 'charliedavis@email.com'),
(6, 'Eva', 'Fisher', 'evafisher@email.com'),
(7, 'George', 'Harris', 'georgeharris@email.com'),
(8, 'Ivy', 'Jones', 'ivyjones@email.com'),
(9, 'Kevin', 'Miller', 'kevinmiller@email.com'),
(10, 'Lily', 'Nelson', 'lilynelson@email.com'),
(11, 'Oliver', 'Patterson', 'oliverpatterson@email.com'),
(12, 'Quinn', 'Roberts', 'quinnroberts@email.com'),
(13, 'Sophia', 'Thomas', 'sophiathomas@email.com');

INSERT INTO products (product_id, product_name, price) VALUES
(1, 'Product A', 10.00),
(2, 'Product B', 15.00),
(3, 'Product C', 20.00),
(4, 'Product D', 25.00),
(5, 'Product E', 30.00),
(6, 'Product F', 35.00),
(7, 'Product G', 40.00),
(8, 'Product H', 45.00),
(9, 'Product I', 50.00),
(10, 'Product J', 55.00),
(11, 'Product K', 60.00),
(12, 'Product L', 65.00),
(13, 'Product M', 70.00);

INSERT INTO orders (order_id, customer_id, order_date) VALUES
(1, 1, '2023-05-01'),
(2, 2, '2023-05-02'),
(3, 3, '2023-05-03'),
(4, 1, '2023-05-04'),
(5, 2, '2023-05-05'),
(6, 3, '2023-05-06'),
(7, 4, '2023-05-07'),
(8, 5, '2023-05-08'),
(9, 6, '2023-05-09'),
(10, 7, '2023-05-10'),
(11, 8, '2023-05-11'),
(12, 9, '2023-05-12'),
(13, 10, '2023-05-13'),
(14, 11, '2023-05-14'),
(15, 12, '2023-05-15'),
(16, 13, '2023-05-16');

INSERT INTO order_items (order_id, product_id, quantity) VALUES
(1, 1, 2),
(1, 2, 1),
(2, 2, 1),
(2, 3, 3),
(3, 1, 1),
(3, 3, 2),
(4, 2, 4),
(4, 3, 1),
(5, 1, 1),
(5, 3, 2),
(6, 2, 3),
(6, 1, 1),
(7, 4, 1),
(7, 5, 2),
(8, 6, 3),
(8, 7, 1),
(9, 8, 2),
(9, 9, 1),
(10, 10, 3),
(10, 11, 2),
(11, 12, 1),
(11, 13, 3),
(12, 4, 2),
(12, 5, 1),
(13, 6, 3),
(13, 7, 2),
(14, 8, 1),
(14, 9, 2),
(15, 10, 3),
(15, 11, 1),
(16, 12, 2),
(16, 13, 3);

--1) Which product has the highest price? Only return a single row.

select * from products order by price desc limit 1;

--2) Which customer has made the most orders?

with get_order_count_per_customerid AS (
	select 
	c.customer_id, 
	c.first_name, 
	c.last_name, 
	count(*) as orders_count 
	from customers c join orders o on c.customer_id = o.customer_id
	group by c.customer_id,c.first_name, c.last_name
)
,get_max_order_count AS (
	select 
	max(orders_count) as max_order_count 
	from get_order_count_per_customerid
)
select a.* 
from get_order_count_per_customerid a 
join get_max_order_count b on a.orders_count = b.max_order_count 
order by a.customer_id;

--3) What’s the total revenue per product?

with quantity_sold_per_product AS (
	select product_id,
	count(quantity) as quantity_sold  
	from order_items group by product_id
)
select p.*, 
q.quantity_sold, 
(q.quantity_sold * p.price) as revenue
from quantity_sold_per_product q 
join products p on q.product_id = p.product_id;

--4) Find the day with the highest revenue.

with get_revenue_per_date AS (
	select *, 
	(oi.quantity * p.price) as revenue from orders o 
	join order_items oi on o.order_id = oi.order_id
	join products p on p.product_id = oi.product_id
)
select order_date, 
sum(revenue) as total_revenue from get_revenue_per_date 
group by order_date
order by total_revenue desc limit 1;

--5) Find the first order (by date) for each customer.

with get_ranking_based_on_order_dates AS (
	select *, 
	dense_rank()over(partition by customer_id order by order_date) rankk 
	from orders
	order by customer_id
)
select 
c.*, 
g.order_date as first_order_date from get_ranking_based_on_order_dates g 
join customers c on g.customer_id = c.customer_id
where g.rankk = 1

--6) Find the top 3 customers who have ordered the most distinct products

select 
c.customer_id, count(DISTINCT oi.product_id) as distinct_orders 
from customers c 
join orders o on c.customer_id = o.customer_id
join order_items oi on oi.order_id = o.order_id 
group by c.customer_id
order by distinct_orders desc limit 3;

--7) Which product has been bought the least in terms of quantity?

with get_quantity_sold_per_product AS (
	select 
	product_id, 
	sum(quantity) as quantity_sold 
	from order_items
	group by product_id
	order by quantity_sold
)
,get_min_sold_quantity AS (
	select min(quantity_sold) as min_qs from get_quantity_sold_per_product
)
select 
p.*, 
b.min_qs as quantity_sold 
from get_quantity_sold_per_product a 
join get_min_sold_quantity b on a.quantity_sold = b.min_qs
join products p on p.product_id = a.product_id

--8) What is the median order total?

with get_revenue_for_orders AS (
	select *, 
	(oi.quantity * p.price) as revenue from order_items oi 
	join products p on oi.product_id = p.product_id
)
select percentile_cont(0.5) within group(order by x.total desc) as median_price from 
( select order_id, sum(revenue) as total from get_revenue_for_orders group by order_id ) x;

--9) For each order, determine if it was ‘Expensive’ (total over 300), ‘Affordable’ (total over 100), or ‘Cheap’.

select 
o.order_id,
sum((oi.quantity * p.price)) as total_revenue,
case 
	when sum((oi.quantity * p.price)) > 300 then 'Expensive'
	when sum((oi.quantity * p.price)) > 100 and sum((oi.quantity * p.price)) < 300 then 'Affordable'
	Else 'Cheap'
End as status
from orders o join order_items oi on o.order_id = oi.order_id 
join products p on p.product_id = oi.product_id
group by o.order_id
order by total_revenue desc;

--10) Find customers who have ordered the product with the highest price.

with get_product_with_highest_price AS (
	select * from products 
	where price = (select max(price) as max_price from products)
)
,get_customer_with_highest_price_orders AS (
	select * from orders o 
	join order_items oi on o.order_id = oi.order_id 
	join get_product_with_highest_price h on h.product_id = oi.product_id
)
select 
customer_id, 
product_name, 
price 
from get_customer_with_highest_price_orders











