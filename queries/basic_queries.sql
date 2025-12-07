-- List all customers from 'Bangalore'.
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    city,
    join_date
FROM customers
WHERE lower(city) = 'bangalore';
