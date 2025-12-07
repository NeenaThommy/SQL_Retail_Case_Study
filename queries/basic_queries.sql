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
