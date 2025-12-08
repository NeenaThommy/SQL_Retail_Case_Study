
-- Find the first and last order date for each customer.

select 
    customer_id,
    first_name,
    min(order_date) as first_orderDate,
    max(order_date) as last_orderDate
from customers c 
left join orders o using(customer_id)
group by customer_id, first_name;

-- Show the cumulative revenue per month (running total).
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(total_amount) AS monthly_total
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    month,
    monthly_total,
    SUM(monthly_total) OVER (
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM monthly_revenue
ORDER BY month;



-- Calculate a 3-order moving average of order amounts per customer.
SELECT
    customer_id,
    order_id,
    total_amount,
    AVG(total_amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3
FROM orders
ORDER BY customer_id, order_date;



-- List products whose sales increased compared to the previous month.
WITH monthly_sales AS (
    SELECT
        product_id,
        DATE_TRUNC('month', order_date) AS month,
        SUM(total_amount) AS monthly_total
    FROM orders
    GROUP BY product_id, DATE_TRUNC('month', order_date)
)
SELECT
    product_id,
    month,
    monthly_total,
    LAG(monthly_total, 1) OVER (
        PARTITION BY product_id
        ORDER BY month
    ) AS previous_month_total
FROM monthly_sales
WHERE monthly_total >
      LAG(monthly_total, 1) OVER (
          PARTITION BY product_id
          ORDER BY month
      )
ORDER BY product_id, month;



Find customers who purchased all products from a specific category.




Identify orders containing the top 3 most expensive products.
SELECT 
    oi.order_id,
    p.product_id,
    p.product_name,
    p.price
FROM (
    SELECT 
        product_id
    FROM products
    ORDER BY price DESC
    LIMIT 3
) AS top3
JOIN order_items oi ON oi.product_id = top3.product_id
JOIN products p ON p.product_id = oi.product_id;




Show the rank of customers based on total spending (dense rank).

SELECT
    customer_id,
    first_name,
    total_spent,
    DENSE_RANK() OVER (ORDER BY total_spent DESC) AS rnk
FROM (
    SELECT
        customer_id,
        first_name,
        SUM(total_amount) AS total_spent
    FROM customers
    JOIN orders USING (customer_id)
    GROUP BY customer_id, first_name
) AS t;




Find gaps between order amounts for each customer (LAG function).
SELECT
    customer_id,
    first_name,
    order_id,
    total_amount,
    lag_amount,
    total_amount - lag_amount AS gap_amount
FROM (
    SELECT
        o.customer_id,
        c.first_name,
        o.order_id,
        o.total_amount,
        LAG(o.total_amount) OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date     -- correct ordering
        ) AS lag_amount
    FROM orders o
    JOIN customers c USING (customer_id)
) AS t;



Show next order date for each customer (LEAD function).

SELECT
        o.customer_id,
        c.first_name,
        o.order_id,
        o.total_amount,
        LEAD(o.order_date) OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date) as next_order_date
FROM orders o JOIN customers c USING (customer_id)

-- List customers whose total spending is above the 75th percentile.

WITH customer_spending AS (
    SELECT
        customer_id,
        first_name,
        SUM(total_amount) AS total_spent
    FROM customers
    JOIN orders USING (customer_id)
    GROUP BY customer_id, first_name
),
ranked AS (
    SELECT
        customer_id,
        first_name,
        total_spent,
        NTILE(4) OVER (ORDER BY total_spent) AS tile
    FROM customer_spending
)
SELECT *
FROM ranked
WHERE tile = 4;     -- 4th tile = top 25% customers
