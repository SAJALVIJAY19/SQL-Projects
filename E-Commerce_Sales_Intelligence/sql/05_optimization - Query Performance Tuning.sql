
-- ============================================================================
-- QUERY OPTIMIZATION & PERFORMANCE TUNING
-- ============================================================================
-- Purpose: Demonstrate SQL optimization techniques
-- ============================================================================

-- ============================================================================
-- 1. ANALYZE QUERY PERFORMANCE
-- ============================================================================

-- Example: Slow query (without optimization)
EXPLAIN ANALYZE
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) as order_count,
    SUM(oi.price) as total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state;


-- ============================================================================
-- 2. INDEX CREATION FOR PERFORMANCE
-- ============================================================================

-- Check existing indexes
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Create additional performance indexes
CREATE INDEX IF NOT EXISTS idx_orders_status_date 
ON orders(order_status, order_purchase_timestamp);

CREATE INDEX IF NOT EXISTS idx_order_items_composite 
ON order_items(order_id, product_id, seller_id);

CREATE INDEX IF NOT EXISTS idx_reviews_score_date 
ON order_reviews(review_score, review_creation_date);

-- Analyze tables to update statistics
ANALYZE customers;
ANALYZE orders;
ANALYZE order_items;
ANALYZE products;
ANALYZE order_reviews;


-- ============================================================================
-- 3. OPTIMIZATION TECHNIQUE: MATERIALIZED VIEWS
-- ============================================================================

-- Create materialized view for frequently accessed aggregations
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_daily_sales_summary AS
SELECT 
    DATE(o.order_purchase_timestamp) as order_date,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    SUM(oi.price) as total_revenue,
    SUM(oi.freight_value) as total_freight,
    AVG(oi.price) as avg_product_price,
    COUNT(oi.order_item_id) as total_items_sold
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE(o.order_purchase_timestamp);

-- Create index on materialized view
CREATE INDEX idx_mv_daily_sales_date ON mv_daily_sales_summary(order_date);

-- Refresh materialized view (run daily)
REFRESH MATERIALIZED VIEW mv_daily_sales_summary;

-- Query the materialized view (much faster!)
SELECT * 
FROM mv_daily_sales_summary
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY order_date DESC;




-- ============================================================================
-- 4. OPTIMIZATION TECHNIQUE: QUERY REWRITING
-- ============================================================================

-- BEFORE: Inefficient subquery in SELECT
-- Bad practice: Correlated subquery
/*
SELECT 
    c.customer_id,
    (SELECT COUNT(*) FROM orders WHERE customer_id = c.customer_id) as order_count
FROM customers c;
*/

-- AFTER: Using JOIN (much faster)
SELECT 
    c.customer_id,
    COUNT(o.order_id) as order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id;


-- ============================================================================
-- 5. OPTIMIZATION TECHNIQUE: PARTITION STRATEGY (Example)
-- ============================================================================

-- For very large tables, consider partitioning by date
-- This is an example for future scaling

-- Create partitioned table
CREATE TABLE orders_partitioned (
    LIKE orders INCLUDING ALL
) PARTITION BY RANGE (order_purchase_timestamp);

-- Create partitions by year
CREATE TABLE orders_2016 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');

CREATE TABLE orders_2017 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');

CREATE TABLE orders_2018 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');



-- ============================================================================
-- 6. QUERY PERFORMANCE COMPARISON
-- ============================================================================

-- Test 1: Revenue by category (with and without index)
-- Drop index temporarily
DROP INDEX IF EXISTS idx_products_category;

-- Time the query without index
EXPLAIN ANALYZE
SELECT 
    pc.category_name_english,
    SUM(oi.price) as revenue
FROM products p
JOIN product_categories pc ON p.category_name = pc.category_name
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY pc.category_name_english;

-- Recreate index
CREATE INDEX idx_products_category ON products(category_name);

-- Time the query with index (should be faster)
EXPLAIN ANALYZE
SELECT 
    pc.category_name_english,
    SUM(oi.price) as revenue
FROM products p
JOIN product_categories pc ON p.category_name = pc.category_name
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY pc.category_name_english;




