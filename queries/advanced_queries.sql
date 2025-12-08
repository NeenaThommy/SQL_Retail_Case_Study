
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


-- 1️⃣ Find the most loyal customer in each city (based on order count)

WITH customer_order_count AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.city,
        COUNT(o.order_id) AS order_count
    FROM customers c
    JOIN orders o USING(customer_id)
    GROUP BY c.customer_id, c.first_name, c.city
)
SELECT
    customer_id,
    first_name,
    city,
    order_count
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY city ORDER BY order_count DESC) AS rn
    FROM customer_order_count
) t
WHERE rn = 1;
-- 2️⃣ Show products with no sales in the last 6 months

SELECT
    p.product_id,
    p.product_name
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
LEFT JOIN orders o
    ON oi.order_id = o.order_id
       AND o.order_date >= CURRENT_DATE - INTERVAL '6 months'
WHERE o.order_id IS NULL;

-- 3️⃣ Identify customers who placed an order every month for the last 3 months

SELECT
    customer_id,
    COUNT(DISTINCT TO_CHAR(order_date, 'YYYY-MM')) AS months_ordered
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY customer_id
HAVING COUNT(DISTINCT TO_CHAR(order_date, 'YYYY-MM')) = 3;

-- 4️⃣ Calculate category-wise revenue contribution for each month

WITH monthly_category_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        p.category,
        SUM(oi.quantity * oi.price) AS category_revenue
    FROM orders o
    JOIN order_items oi USING(order_id)
    JOIN products p USING(product_id)
    GROUP BY month, p.category
),
total_monthly_revenue AS (
    SELECT
        month,
        SUM(category_revenue) AS total_revenue
    FROM monthly_category_revenue
    GROUP BY month
)
SELECT
    mcr.month,
    mcr.category,
    mcr.category_revenue,
    ROUND((mcr.category_revenue / tmr.total_revenue) * 100, 2) AS percentage_contribution
FROM monthly_category_revenue mcr
JOIN total_monthly_revenue tmr USING(month)
ORDER BY month, percentage_contribution DESC;
-- 5️⃣ Show the top 2 products per category by revenue

WITH product_revenue AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.price) AS revenue
    FROM products p
    JOIN order_items oi USING(product_id)
    GROUP BY p.category, p.product_id, p.product_name
)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn
    FROM product_revenue
) t
WHERE rn <= 2
ORDER BY category, revenue DESC;

-- 6️⃣ Identify orders that include at least one product from every category

WITH order_categories AS (
    SELECT
        oi.order_id,
        COUNT(DISTINCT p.category) AS categories_in_order
    FROM order_items oi
    JOIN products p USING(product_id)
    GROUP BY oi.order_id
),
total_categories AS (
    SELECT COUNT(DISTINCT category) AS total_category_count
    FROM products
)
SELECT o.order_id
FROM order_categories o
CROSS JOIN total_categories t
WHERE o.categories_in_order = t.total_category_count;

-- 7️⃣ Calculate total discount given if each product has a 10% discount

SELECT
    SUM(oi.quantity * oi.price * 0.10) AS total_discount
FROM order_items oi;

-- 8️⃣ Show customers whose spending increased month-over-month for the last 3 months
WITH monthly_spending AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', order_date) AS month,
        SUM(total_amount) AS total_spent
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY customer_id, month
)
SELECT customer_id
FROM (
    SELECT *,
           LAG(total_spent, 1) OVER (PARTITION BY customer_id ORDER BY month) AS prev_month,
           LAG(total_spent, 2) OVER (PARTITION BY customer_id ORDER BY month) AS prev_month2
    FROM monthly_spending
) t
WHERE total_spent > prev_month AND prev_month > prev_month2;

-- 9️⃣ Find customers with multiple orders on the same day
SELECT
    customer_id,
    order_date,
    COUNT(order_id) AS orders_on_same_day
FROM orders
GROUP BY customer_id, order_date
HAVING COUNT(order_id) > 1;

-- 🔟 Identify orders where total_amount doesn’t match SUM(quantity * price) from order_items
SELECT
    o.order_id,
    o.total_amount,
    SUM(oi.quantity * oi.price) AS calculated_total
FROM orders o
JOIN order_items oi USING(order_id)
GROUP BY o.order_id, o.total_amount
HAVING o.total_amount <> SUM(oi.quantity * oi.price);


