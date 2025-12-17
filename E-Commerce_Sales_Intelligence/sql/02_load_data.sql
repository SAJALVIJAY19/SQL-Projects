COPY orders(order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
FROM 'D:/RAGHAV/PROJECTS/SQL/SQL-Projects/E-Commerce_Sales_Intelligence/datasets/olist_orders_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY sellers(seller_id, seller_zip_code, seller_city, seller_state)
FROM 'D:/RAGHAV/PROJECTS/SQL/SQL-Projects/E-Commerce_Sales_Intelligence/datasets/olist_sellers_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY order_items(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
FROM 'D:/RAGHAV/PROJECTS/SQL/SQL-Projects/E-Commerce_Sales_Intelligence/datasets/olist_order_items_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY order_payments(order_id, payment_sequential, payment_type, payment_installments, payment_value)
FROM 'D:/RAGHAV/PROJECTS/SQL/SQL-Projects/E-Commerce_Sales_Intelligence/datasets/olist_order_payments_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY order_reviews(review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp)
FROM 'D:/RAGHAV/PROJECTS/SQL/SQL-Projects/E-Commerce_Sales_Intelligence/datasets/olist_order_reviews_dataset.csv'
DELIMITER ','
CSV HEADER;


COPY products(product_id, category_name, name_length, description_length, photos_qty, weight_g, length_cm, height_cm, width_cm)
FROM 'D:/RAGHAV/PROJECTS/SQL/SQL-Projects/E-Commerce_Sales_Intelligence/datasets/olist_products_dataset.csv'
DELIMITER ','
CSV HEADER;


SELECT 'customers' as table_name, COUNT(*) as row_count FROM customers
UNION ALL
SELECT 'product_categories', COUNT(*) FROM product_categories
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews;


-- Sample data check
SELECT * FROM customers LIMIT 5;
SELECT * FROM orders LIMIT 5;
SELECT * FROM order_items LIMIT 5;

-- Check for NULL values in critical columns
SELECT 
    'orders' as table_name,
    COUNT(*) as total_rows,
    COUNT(*) - COUNT(customer_id) as null_customers,
    COUNT(*) - COUNT(order_status) as null_status
FROM orders;


-- ============================================================================
-- DATA QUALITY CHECKS
-- ============================================================================

-- Check for orphaned records (orders without customers)
SELECT COUNT(*) as orphaned_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Check for duplicate order_ids
SELECT order_id, COUNT(*) as duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Check date ranges
SELECT 
    MIN(order_purchase_timestamp) as earliest_order,
    MAX(order_purchase_timestamp) as latest_order,
    MAX(order_purchase_timestamp) - MIN(order_purchase_timestamp) as date_range
FROM orders;

