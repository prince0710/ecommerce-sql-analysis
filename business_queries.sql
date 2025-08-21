SELECT 
    YEAR(order_date) as year,
    MONTH(order_date) as month,
    COUNT(*) as total_orders,
    SUM(total_amount) as monthly_revenue,
    AVG(total_amount) as avg_order_value
FROM orders 
WHERE status = 'Completed'
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY year, month;

SELECT 
    p.product_name,
    c.category_name,
    SUM(oi.quantity) as total_sold,
    SUM(oi.quantity * oi.unit_price) as total_revenue,
    (SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.cost)) as profit
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.product_id, p.product_name, c.category_name
ORDER BY total_revenue DESC
LIMIT 10;

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as lifetime_value,
    AVG(o.total_amount) as avg_order_value,
    MIN(o.order_date) as first_order,
    MAX(o.order_date) as last_order
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(o.order_id) > 0
ORDER BY lifetime_value DESC;

SELECT 
    c.category_name,
    COUNT(DISTINCT oi.order_id) as orders_count,
    SUM(oi.quantity) as items_sold,
    SUM(oi.quantity * oi.unit_price) as revenue,
    AVG(oi.unit_price) as avg_price,
    SUM(oi.quantity * oi.unit_price) / SUM(SUM(oi.quantity * oi.unit_price)) OVER() * 100 as revenue_percentage
FROM categories c
JOIN products p ON c.category_id = p.category_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'Completed'
GROUP BY c.category_id, c.category_name
ORDER BY revenue DESC;

WITH customer_rfm AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        DATEDIFF(CURDATE(), MAX(o.order_date)) as recency,
        COUNT(o.order_id) as frequency,
        SUM(o.total_amount) as monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT 
    customer_id,
    first_name,
    last_name,
    recency,
    frequency,
    monetary,
    CASE 
        WHEN frequency >= 3 AND monetary >= 200 THEN 'VIP Customer'
        WHEN frequency >= 2 AND monetary >= 100 THEN 'Regular Customer'
        WHEN recency <= 90 THEN 'Active Customer'
        ELSE 'At-Risk Customer'
    END as customer_segment
FROM customer_rfm
ORDER BY monetary DESC;