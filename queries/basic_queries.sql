-- Batch 1: Basic SQL Queries

-- 1️⃣ List all customers from Bangalore
SELECT *
FROM customers
WHERE city = 'Bangalore';


-- 2️⃣ Show all orders placed in 2023
SELECT *
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2023;


-- 3️⃣ Get the product name and price of all products in the 'Electronics' category
SELECT product_name, price
FROM products
WHERE category = 'Electronics';


-- 4️⃣ Find the total revenue (sum of total_amount) from all orders
SELECT SUM(total_amount) AS total_revenue
FROM orders;


-- 5️⃣ List customers along with the number of orders they placed
SELECT c.customer_id,
       c.customer_name,
       COUNT(o.order_id) AS number_of_orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY number_of_orders DESC;

--✅ 1. List all orders with status = 'Cancelled'.

SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount,
    status
FROM orders
WHERE status = 'Cancelled';

--2. Find the top 5 customers by total spending
SELECT 
    c.customer_id,
    c.first_name,
    SUM(o.total_amount) AS total_spent
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name
ORDER BY total_spent DESC
LIMIT 5;

--✅ 3. Retrieve customer names along with the number of orders they placed.

select 
customer_id,
first_name ,
count(order_id) as order_count
from customers c left join orders o 
on (c.customer_id = o.customer_id)
group by customer_id,first_name

--4. List products that were never sold
SELECT 
    p.product_id,
    p.product_name
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.order_item_id IS NULL;

SELECT 
    product_id,
    product_name,
    category,
    price
FROM (
    SELECT 
        product_id,
        product_name,
        category,
        price,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) AS rn
    FROM products
) t
WHERE rn = 1;

--6. Show orders where total_amount > 1000.
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount
FROM orders
WHERE total_amount > 1000;

