-- Calculate the average order value per customer.

SELECT
    customer_id,
    first_name,
    AVG(total_amount) AS avg_order_value
FROM customers
JOIN orders USING (customer_id)
GROUP BY customer_id, first_name;


-- Find customers who joined in the last 6 months but never placed an order.

SELECT 
    c.customer_id,
    c.first_name,
    c.join_date
FROM customers c
LEFT JOIN orders o USING (customer_id)
WHERE c.join_date >= CURRENT_DATE - INTERVAL '6 months'
  AND o.order_id IS NULL;


-- Show the number of orders per month.

SELECT
    DATE_TRUNC('month', order_date) AS month,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;



-- Calculate total quantity sold per product.

SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity
FROM products p
LEFT JOIN order_items oi USING (product_id)
GROUP BY p.product_id, p.product_name
ORDER BY total_quantity DESC;


-- List customers whose last order was over 1 year ago.

WITH last_orders AS (
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.first_name,
    lo.last_order_date
FROM customers c
JOIN last_orders lo USING (customer_id)
WHERE lo.last_order_date <= CURRENT_DATE - INTERVAL '12 months';

-- Find the top 3 selling products by quantity.

SELECT
    product_id,
    product_name,
    SUM(quantity) AS total_quantity
FROM products
JOIN order_items USING(product_id)
GROUP BY product_id, product_name
ORDER BY total_quantity DESC
LIMIT 3;

-- Show total revenue per city.

SELECT
    city,
    SUM(total_amount) AS total_revenue
FROM customers
JOIN orders USING(customer_id)
GROUP BY city;


-- Calculate the percentage contribution of each product to total revenue.

WITH revenue_per_product AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.price) AS product_revenue
    FROM products p
    JOIN order_items oi USING (product_id)
    GROUP BY p.product_id, p.product_name
),
total_revenue AS (
    SELECT SUM(product_revenue) AS total_rev
    FROM revenue_per_product
)
SELECT
    r.product_id,
    r.product_name,
    r.product_revenue,
    ROUND((r.product_revenue / t.total_rev) * 100, 2) AS percentage_contribution
FROM revenue_per_product r CROSS JOIN total_revenue t
ORDER BY percentage_contribution DESC;


-- Identify customers who bought more than 5 distinct products.

SELECT
    c.customer_id,
    c.first_name,
    COUNT(DISTINCT oi.product_id) AS product_count
FROM customers c
JOIN orders o USING (customer_id)
JOIN order_items oi USING (order_id)
GROUP BY c.customer_id, c.first_name
HAVING COUNT(DISTINCT oi.product_id) > 5;


-- List orders with total_amount higher than the average order value.

SELECT
    order_id,
    total_amount,
    (SELECT AVG(total_amount) FROM orders) AS average_amount
FROM orders
WHERE total_amount >
      (SELECT AVG(total_amount) FROM orders);
