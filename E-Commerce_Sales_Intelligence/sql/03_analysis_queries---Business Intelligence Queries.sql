-- ============================================================================
-- E-COMMERCE BUSINESS INTELLIGENCE QUERIES
-- ============================================================================
-- Author: Sajal Vijayvargiya
-- Purpose: Answer key business questions using advanced SQL
-- ============================================================================

-- ============================================================================
-- 1. REVENUE ANALYSIS
-- ===========================================================================


-- Q1: Total revenue by month with growth rate
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp) as month,
        SUM(oi.price + oi.freight_value) as total_revenue,
        COUNT(DISTINCT o.order_id) as total_orders,
        COUNT(DISTINCT o.customer_id) as unique_customers
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT 
    month,
    total_revenue,
    total_orders,
    unique_customers,
    ROUND(total_revenue / total_orders, 2) as avg_order_value,
    ROUND(
        ((total_revenue - LAG(total_revenue) OVER (ORDER BY month)) / 
        NULLIF(LAG(total_revenue) OVER (ORDER BY month), 0)) * 100, 
        2
    ) as revenue_growth_pct
FROM monthly_revenue
ORDER BY month;



-- Q2: Top 10 revenue-generating product categories
SELECT 
    pc.category_name_english,
    COUNT(DISTINCT oi.order_id) as total_orders,
    COUNT(oi.order_item_id) as units_sold,
    ROUND(SUM(oi.price), 2) as total_revenue,
    ROUND(AVG(oi.price), 2) as avg_price,
    ROUND(SUM(oi.price) / COUNT(DISTINCT oi.order_id), 2) as revenue_per_order
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN product_categories pc ON p.category_name = pc.category_name
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY pc.category_name_english
ORDER BY total_revenue DESC
LIMIT 10;



-- Q3: Revenue by state (geographic analysis)
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT c.customer_id) as total_customers,
    ROUND(SUM(oi.price + oi.freight_value), 2) as total_revenue,
    ROUND(AVG(oi.price + oi.freight_value), 2) as avg_order_value,
    ROUND(SUM(oi.price + oi.freight_value) * 100.0 / SUM(SUM(oi.price + oi.freight_value)) OVER(), 2) as revenue_percentage
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================================
-- 2. CUSTOMER ANALYSIS
-- ============================================================================

-- Q4: Customer segmentation using RFM (Recency, Frequency, Monetary)
WITH customer_rfm AS (
    SELECT 
        c.customer_id,
        c.customer_state,
        DATE_PART('day', CURRENT_DATE - MAX(o.order_purchase_timestamp)) as recency_days,
        COUNT(DISTINCT o.order_id) as frequency,
        SUM(oi.price + oi.freight_value) as monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_id, c.customer_state
),
rfm_scores AS (
    SELECT 
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) as r_score,
        NTILE(5) OVER (ORDER BY frequency) as f_score,
        NTILE(5) OVER (ORDER BY monetary) as m_score
    FROM customer_rfm
)
SELECT 
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score <= 2 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Others'
    END as customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(monetary), 2) as avg_lifetime_value,
    ROUND(AVG(frequency), 2) as avg_order_frequency,
    ROUND(SUM(monetary), 2) as total_segment_value
FROM rfm_scores
GROUP BY customer_segment
ORDER BY total_segment_value DESC;



-- Q5: Top 20 customers by lifetime value
SELECT 
    c.customer_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(oi.price + oi.freight_value) as lifetime_value,
    AVG(oi.price + oi.freight_value) as avg_order_value,
    MAX(o.order_purchase_timestamp) as last_purchase_date,
    DATE_PART('day', CURRENT_DATE - MAX(o.order_purchase_timestamp)) as days_since_last_order
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_id, c.customer_city, c.customer_state
ORDER BY lifetime_value DESC
LIMIT 20;


-- ============================================================================
-- 3. PRODUCT ANALYSIS
-- ============================================================================

-- Q7: Best-selling products with ratings
SELECT 
    p.product_id,
    pc.category_name_english,
    COUNT(DISTINCT oi.order_id) as times_ordered,
    SUM(oi.price) as total_revenue,
    AVG(oi.price) as avg_price,
    COUNT(oi.order_item_id) as units_sold,
    ROUND(AVG(r.review_score), 2) as avg_rating,
    COUNT(r.review_id) as review_count
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN product_categories pc ON p.category_name = pc.category_name
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_id, pc.category_name_english
HAVING COUNT(DISTINCT oi.order_id) >= 10
ORDER BY total_revenue DESC
LIMIT 20;


-- Q8: Products with best ratings but low sales (hidden gems)
SELECT 
    p.product_id,
    pc.category_name_english,
    AVG(r.review_score) as avg_rating,
    COUNT(r.review_id) as review_count,
    COUNT(DISTINCT oi.order_id) as total_orders,
    ROUND(AVG(oi.price), 2) as avg_price
FROM products p
JOIN product_categories pc ON p.category_name = pc.category_name
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_id, pc.category_name_english
HAVING AVG(r.review_score) >= 4.5 
    AND COUNT(r.review_id) >= 5
    AND COUNT(DISTINCT oi.order_id) < 20
ORDER BY avg_rating DESC, review_count DESC
LIMIT 15;


-- Q9: Category performance by rating
SELECT 
    pc.category_name_english,
    COUNT(DISTINCT p.product_id) as total_products,
    COUNT(DISTINCT oi.order_id) as total_orders,
    ROUND(AVG(r.review_score), 2) as avg_category_rating,
    ROUND(SUM(oi.price), 2) as total_revenue,
    COUNT(CASE WHEN r.review_score >= 4 THEN 1 END) * 100.0 / NULLIF(COUNT(r.review_id), 0) as pct_positive_reviews
FROM product_categories pc
JOIN products p ON pc.category_name = p.category_name
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY pc.category_name_english
HAVING COUNT(r.review_id) >= 10
ORDER BY avg_category_rating DESC, total_revenue DESC;


-- ============================================================================
-- 4. DELIVERY & OPERATIONS ANALYSIS
-- ============================================================================

-- Q10: Average delivery time by state
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) as total_delivered_orders,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400), 2) as avg_delivery_days,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_estimated_delivery_date - o.order_delivered_customer_date))/86400), 2) as avg_early_late_days,
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) as late_deliveries,
    ROUND(COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) * 100.0 / COUNT(*), 2) as late_delivery_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY late_delivery_pct DESC;


-- Q11: Delivery performance impact on ratings
WITH delivery_performance AS (
    SELECT 
        o.order_id,
        CASE 
            WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On-Time'
            WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date + INTERVAL '3 days' THEN 'Slightly Late'
            ELSE 'Very Late'
        END as delivery_status,
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400 as delivery_days,
        r.review_score
    FROM orders o
    LEFT JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
)
SELECT 
    delivery_status,
    COUNT(*) as order_count,
    ROUND(AVG(delivery_days), 2) as avg_delivery_days,
    ROUND(AVG(review_score), 2) as avg_rating,
    COUNT(CASE WHEN review_score >= 4 THEN 1 END) * 100.0 / NULLIF(COUNT(review_score), 0) as pct_positive_reviews
FROM delivery_performance
GROUP BY delivery_status
ORDER BY avg_rating DESC;


-- ============================================================================
-- 5. PAYMENT ANALYSIS
-- ============================================================================

-- Q12: Payment methods analysis
SELECT 
    op.payment_type,
    COUNT(DISTINCT op.order_id) as total_transactions,
    ROUND(SUM(op.payment_value), 2) as total_amount,
    ROUND(AVG(op.payment_value), 2) as avg_transaction_value,
    ROUND(AVG(op.payment_installments), 2) as avg_installments,
    ROUND(SUM(op.payment_value) * 100.0 / SUM(SUM(op.payment_value)) OVER(), 2) as revenue_percentage
FROM order_payments op
JOIN orders o ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY op.payment_type
ORDER BY total_amount DESC;


-- Q13: High-value orders (top 1% by value)
WITH order_values AS (
    SELECT 
        o.order_id,
        c.customer_state,
        SUM(oi.price + oi.freight_value) as order_value,
        NTILE(100) OVER (ORDER BY SUM(oi.price + oi.freight_value)) as percentile
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id, c.customer_state
)
SELECT 
    percentile,
    COUNT(*) as order_count,
    ROUND(MIN(order_value), 2) as min_value,
    ROUND(MAX(order_value), 2) as max_value,
    ROUND(AVG(order_value), 2) as avg_value,
    ROUND(SUM(order_value), 2) as total_value
FROM order_values
WHERE percentile >= 99
GROUP BY percentile
ORDER BY percentile DESC;


-- ============================================================================
-- 6. COHORT ANALYSIS
-- ============================================================================

-- Q14: Monthly cohort retention analysis
WITH customer_cohorts AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_purchase_timestamp)) as cohort_month
    FROM orders
    WHERE order_status = 'delivered'
    GROUP BY customer_id
),
customer_activities AS (
    SELECT 
        cc.customer_id,
        cc.cohort_month,
        DATE_TRUNC('month', o.order_purchase_timestamp) as activity_month,
        DATE_PART('month', AGE(DATE_TRUNC('month', o.order_purchase_timestamp), cc.cohort_month)) as months_since_cohort
    FROM customer_cohorts cc
    JOIN orders o ON cc.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
)
SELECT 
    cohort_month,
    COUNT(DISTINCT CASE WHEN months_since_cohort = 0 THEN customer_id END) as month_0,
    COUNT(DISTINCT CASE WHEN months_since_cohort = 1 THEN customer_id END) as month_1,
    COUNT(DISTINCT CASE WHEN months_since_cohort = 2 THEN customer_id END) as month_2,
    COUNT(DISTINCT CASE WHEN months_since_cohort = 3 THEN customer_id END) as month_3,
    ROUND(COUNT(DISTINCT CASE WHEN months_since_cohort = 1 THEN customer_id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT CASE WHEN months_since_cohort = 0 THEN customer_id END), 0), 2) as retention_month_1_pct
FROM customer_activities
WHERE cohort_month >= '2017-01-01'
GROUP BY cohort_month
ORDER BY cohort_month;


-- ============================================================================
-- 7. SELLER PERFORMANCE
-- ============================================================================

-- Q15: Top performing sellers
SELECT 
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) as total_orders,
    COUNT(oi.order_item_id) as total_items_sold,
    ROUND(SUM(oi.price), 2) as total_revenue,
    ROUND(AVG(oi.price), 2) as avg_item_price,
    ROUND(AVG(r.review_score), 2) as avg_seller_rating,
    COUNT(r.review_id) as review_count
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_city, s.seller_state
HAVING COUNT(DISTINCT oi.order_id) >= 100
ORDER BY total_revenue DESC
LIMIT 20;

-- ============================================================================
-- END OF ANALYSIS QUERIES
-- ============================================================================