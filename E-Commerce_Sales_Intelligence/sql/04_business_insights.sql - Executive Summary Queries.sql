-- ============================================================================
-- EXECUTIVE BUSINESS INSIGHTS & KPIs
-- ============================================================================
-- Purpose: Generate executive-level insights and recommendations
-- ============================================================================

-- ============================================================================
-- KEY PERFORMANCE INDICATORS (KPIs)
-- ============================================================================

-- Overall business health snapshot
WITH kpi_metrics AS (
    SELECT 
        COUNT(DISTINCT o.order_id) as total_orders,
        COUNT(DISTINCT o.customer_id) as total_customers,
        SUM(oi.price + oi.freight_value) as total_revenue,
        AVG(oi.price + oi.freight_value) as avg_order_value,
        COUNT(DISTINCT p.product_id) as products_sold,
        AVG(r.review_score) as avg_customer_satisfaction
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
)
SELECT 
    'Total Revenue' as metric, CONCAT('R$ ', ROUND(total_revenue, 2)) as value
FROM kpi_metrics
UNION ALL
SELECT 'Total Orders', total_orders::TEXT FROM kpi_metrics
UNION ALL
SELECT 'Total Customers', total_customers::TEXT FROM kpi_metrics
UNION ALL
SELECT 'Average Order Value', CONCAT('R$ ', ROUND(avg_order_value, 2)) FROM kpi_metrics
UNION ALL
SELECT 'Products Sold', products_sold::TEXT FROM kpi_metrics
UNION ALL
SELECT 'Avg Customer Satisfaction', CONCAT(ROUND(avg_customer_satisfaction, 2), '/5') FROM kpi_metrics;


-- ============================================================================
-- BUSINESS INSIGHT 1: PARETO ANALYSIS (80/20 RULE)
-- ============================================================================

-- Which 20% of products generate 80% of revenue?
WITH product_revenue AS (
    SELECT 
        p.product_id,
        pc.category_name_english,
        SUM(oi.price) as revenue,
        SUM(SUM(oi.price)) OVER () as total_revenue
    FROM products p
    JOIN product_categories pc ON p.category_name = pc.category_name
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_id, pc.category_name_english
),
cumulative_revenue AS (
    SELECT 
        product_id,
        category_name_english,
        revenue,
        total_revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC) as cumulative_revenue,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) as product_rank,
        COUNT(*) OVER () as total_products
    FROM product_revenue
)
SELECT 
    'Products contributing to 80% revenue' as insight,
    COUNT(*) as product_count,
    ROUND(COUNT(*) * 100.0 / MAX(total_products), 2) as percentage_of_catalog,
    ROUND(SUM(revenue), 2) as revenue_generated,
    ROUND(SUM(revenue) * 100.0 / MAX(total_revenue), 2) as revenue_percentage
FROM cumulative_revenue
WHERE cumulative_revenue <= (total_revenue * 0.80)
GROUP BY insight;


-- ============================================================================
-- BUSINESS INSIGHT 2: CUSTOMER LIFETIME VALUE SEGMENTS
-- ============================================================================

-- What is the potential revenue from different customer segments?
WITH customer_segments AS (
    SELECT 
        c.customer_id,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(oi.price + oi.freight_value) as lifetime_value,
        MAX(o.order_purchase_timestamp) as last_purchase,
        CURRENT_DATE - MAX(o.order_purchase_timestamp::DATE) as days_inactive
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_id
),
segments AS (
    SELECT 
        CASE 
            WHEN order_count >= 5 AND lifetime_value >= 1000 THEN 'VIP'
            WHEN order_count >= 3 AND lifetime_value >= 500 THEN 'High Value'
            WHEN order_count >= 2 THEN 'Repeat'
            ELSE 'One-time'
        END as segment,
        customer_id,
        lifetime_value,
        order_count,
        days_inactive
    FROM customer_segments
)
SELECT 
    segment,
    COUNT(*) as customer_count,
    ROUND(AVG(lifetime_value), 2) as avg_ltv,
    ROUND(SUM(lifetime_value), 2) as total_segment_value,
    ROUND(AVG(order_count), 2) as avg_orders,
    ROUND(AVG(days_inactive), 0) as avg_days_inactive,
    -- Potential revenue if we retain 10% more customers
    ROUND(SUM(lifetime_value) * 0.10, 2) as potential_retention_revenue
FROM segments
GROUP BY segment
ORDER BY total_segment_value DESC;



-- ============================================================================
-- BUSINESS INSIGHT 3: CHURN RISK IDENTIFICATION
-- ============================================================================

-- Identify customers at risk of churning (no purchase in 90+ days)
WITH customer_activity AS (
    SELECT 
        c.customer_id,
        c.customer_state,
        COUNT(DISTINCT o.order_id) as total_orders,
        SUM(oi.price + oi.freight_value) as lifetime_value,
        MAX(o.order_purchase_timestamp) as last_purchase,
        CURRENT_DATE - MAX(o.order_purchase_timestamp::DATE) as days_since_last_purchase,
        AVG(r.review_score) as avg_satisfaction
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_id, c.customer_state
),
churn_risk AS (
    SELECT 
        *,
        CASE 
            WHEN days_since_last_purchase > 180 THEN 'High Risk'
            WHEN days_since_last_purchase > 90 THEN 'Medium Risk'
            WHEN days_since_last_purchase > 60 THEN 'Low Risk'
            ELSE 'Active'
        END as churn_risk_level
    FROM customer_activity
)
SELECT 
    churn_risk_level,
    COUNT(*) as customer_count,
    ROUND(AVG(lifetime_value), 2) as avg_lifetime_value,
    ROUND(SUM(lifetime_value), 2) as total_at_risk_revenue,
    ROUND(AVG(total_orders), 2) as avg_orders,
    ROUND(AVG(days_since_last_purchase), 0) as avg_days_inactive,
    -- Potential revenue loss if these customers churn
    ROUND(SUM(lifetime_value) * 0.30, 2) as estimated_revenue_loss
FROM churn_risk
WHERE churn_risk_level != 'Active'
GROUP BY churn_risk_level
ORDER BY 
    CASE churn_risk_level
        WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        WHEN 'Low Risk' THEN 3
    END;


-- ============================================================================
-- BUSINESS INSIGHT 4: SEASONAL TRENDS & FORECASTING
-- ============================================================================

-- Monthly sales trends with year-over-year comparison
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp) as month,
        EXTRACT(YEAR FROM o.order_purchase_timestamp) as year,
        COUNT(DISTINCT o.order_id) as orders,
        SUM(oi.price + oi.freight_value) as revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp), EXTRACT(YEAR FROM o.order_purchase_timestamp)
)
SELECT 
    TO_CHAR(month, 'Month YYYY') as period,
    orders,
    ROUND(revenue, 2) as revenue,
    LAG(revenue) OVER (ORDER BY month) as prev_month_revenue,
    ROUND(
        ((revenue - LAG(revenue) OVER (ORDER BY month)) / 
        NULLIF(LAG(revenue) OVER (ORDER BY month), 0)) * 100, 
        2
    ) as month_over_month_growth,
    -- Moving average (3 months)
    ROUND(AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) as moving_avg_3m
FROM monthly_sales
ORDER BY month DESC
LIMIT 12;


-- ============================================================================
-- BUSINESS INSIGHT 5: PRICING OPTIMIZATION OPPORTUNITIES
-- ============================================================================

-- Products with high ratings but low prices (upsell potential)
WITH product_metrics AS (
    SELECT 
        p.product_id,
        pc.category_name_english,
        COUNT(DISTINCT oi.order_id) as order_count,
        AVG(oi.price) as avg_price,
        AVG(r.review_score) as avg_rating,
        COUNT(r.review_id) as review_count,
        -- Calculate price percentile within category
        NTILE(4) OVER (PARTITION BY pc.category_name_english ORDER BY AVG(oi.price)) as price_quartile
    FROM products p
    JOIN product_categories pc ON p.category_name = pc.category_name
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    LEFT JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_id, pc.category_name_english
    HAVING COUNT(DISTINCT oi.order_id) >= 10
)
SELECT 
    category_name_english,
    COUNT(*) as products_in_opportunity,
    ROUND(AVG(avg_price), 2) as current_avg_price,
    ROUND(AVG(avg_price) * 1.15, 2) as suggested_price_15pct_increase,
    ROUND(AVG(avg_rating), 2) as avg_rating,
    -- Potential revenue increase
    ROUND(SUM(avg_price * order_count) * 0.15, 2) as potential_additional_revenue
FROM product_metrics
WHERE avg_rating >= 4.5 
    AND price_quartile = 1  -- Bottom 25% in pricing
    AND review_count >= 10
GROUP BY category_name_english
HAVING COUNT(*) >= 3
ORDER BY potential_additional_revenue DESC;


-- ============================================================================
-- BUSINESS INSIGHT 6: MARKET EXPANSION OPPORTUNITIES
-- ============================================================================

-- Underserved states with high potential
WITH state_performance AS (
    SELECT 
        c.customer_state,
        COUNT(DISTINCT c.customer_id) as customer_count,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(oi.price + oi.freight_value) as total_revenue,
        AVG(oi.price + oi.freight_value) as avg_order_value,
        AVG(r.review_score) as avg_satisfaction
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
),
state_potential AS (
    SELECT 
        *,
        NTILE(4) OVER (ORDER BY total_revenue DESC) as revenue_quartile,
        NTILE(4) OVER (ORDER BY customer_count DESC) as customer_quartile
    FROM state_performance
)
SELECT 
    customer_state,
    customer_count,
    order_count,
    ROUND(total_revenue, 2) as current_revenue,
    ROUND(avg_order_value, 2) as avg_order_value,
    ROUND(avg_satisfaction, 2) as satisfaction,
    CASE 
        WHEN revenue_quartile = 4 AND customer_quartile = 4 THEN 'High Growth Potential'
        WHEN revenue_quartile = 3 AND avg_order_value > 150 THEN 'Premium Market'
        WHEN revenue_quartile >= 3 THEN 'Expansion Target'
        ELSE 'Established Market'
    END as market_opportunity,
    -- Estimated additional revenue if we double penetration
    ROUND(total_revenue * 1.0, 2) as expansion_revenue_potential
FROM state_potential
WHERE revenue_quartile >= 3
ORDER BY expansion_revenue_potential DESC;


-- ============================================================================
-- BUSINESS RECOMMENDATIONS SUMMARY
-- ============================================================================


-- Generating actionable recommendations based on all insights
SELECT 
    'EXECUTIVE SUMMARY: KEY RECOMMENDATIONS' as insight_type,
    '' as recommendation
UNION ALL
SELECT 'Revenue Concentration', 
       'Focus on top 20% products generating 80% revenue. Optimize inventory and marketing for these products.'
UNION ALL
SELECT 'Customer Retention',
       'Launch re-engagement campaign for ' || 
       (SELECT COUNT(*) FROM (
           SELECT customer_id FROM orders o
           JOIN order_items oi ON o.order_id = oi.order_id
           GROUP BY customer_id
           HAVING MAX(o.order_purchase_timestamp) < CURRENT_DATE - INTERVAL '90 days'
       ) subq)::TEXT || 
       ' at-risk customers to prevent churn and recover potential revenue.'
UNION ALL
SELECT 'Pricing Strategy',
       'Increase prices by 10-15% for high-rated, low-priced products to maximize profit margins.'
UNION ALL
SELECT 'Market Expansion',
       'Target underserved states with high average order values for geographic expansion.'
UNION ALL
SELECT 'Delivery Excellence',
       'Reduce late deliveries (currently impacting customer satisfaction) by optimizing logistics in bottleneck states.';

-- ============================================================================
-- END OF BUSINESS INSIGHTS
-- ============================================================================