-- 1) List all customers from 'Bangalore'.
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    city,
    join_date
FROM customers
WHERE lower(city) = 'bangalore';

--2) Find all orders placed in the last 30 days.
select 
    order_id,
	customer_id,
    order_date,
    total_amount
from orders
where order_date >= current_date - interval '30 days'
