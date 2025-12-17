-- ============================================================================
-- E-COMMERCE SALES INTELLIGENCE DATABASE SCHEMA
-- ============================================================================
-- Author: Sajal Vijayvargiya
-- Database: PostgreSQL
-- Description: Normalized schema for Brazilian e-commerce marketplace analysis
-- ============================================================================

DROP TABLE IF EXISTS order_reviews CASCADE;
DROP TABLE IF EXISTS order_payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS product_categories CASCADE;


-- Customer Dimensions 
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product categories dimension
CREATE TABLE product_categories (
    category_name VARCHAR(100) PRIMARY KEY,
    category_name_english VARCHAR(100)
);

-- Products dimension
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    category_name VARCHAR(100) REFERENCES product_categories(category_name),
    name_length INTEGER,
    description_length INTEGER,
    photos_qty INTEGER,
    weight_g INTEGER,
    length_cm INTEGER,
    height_cm INTEGER,
    width_cm INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sellers dimension
CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- ============================================================================
-- FACT TABLES
-- ============================================================================

-- Orders fact table
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) REFERENCES customers(customer_id),
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    CHECK (order_status IN ('delivered', 'shipped', 'canceled', 'unavailable', 'invoiced', 'processing', 'created', 'approved'))
);

-- Order items fact table
CREATE TABLE order_items (
    order_id VARCHAR(50) REFERENCES orders(order_id),
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(50) REFERENCES products(product_id),
    seller_id VARCHAR(50) REFERENCES sellers(seller_id),
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10,2) NOT NULL,
    freight_value DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

-- Order payments fact table
CREATE TABLE order_payments (
    order_id VARCHAR(50) REFERENCES orders(order_id),
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(20) NOT NULL,
    payment_installments INTEGER NOT NULL,
    payment_value DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    CHECK (payment_type IN ('credit_card', 'boleto', 'voucher', 'debit_card', 'not_defined'))
);

-- Order reviews fact table
CREATE TABLE order_reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) REFERENCES orders(order_id),
    review_score INTEGER NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title VARCHAR(200),
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);


-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Customers indexes
CREATE INDEX idx_customers_state ON customers(customer_state);
CREATE INDEX idx_customers_city ON customers(customer_city);

-- Products indexes
CREATE INDEX idx_products_category ON products(category_name);

-- Sellers indexes
CREATE INDEX idx_sellers_state ON sellers(seller_state);

-- Orders indexes
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_purchase_date ON orders(order_purchase_timestamp);
CREATE INDEX idx_orders_delivered_date ON orders(order_delivered_customer_date);

-- Order items indexes
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_order_items_seller ON order_items(seller_id);

-- Order payments indexes
CREATE INDEX idx_payments_type ON order_payments(payment_type);

-- Order reviews indexes
CREATE INDEX idx_reviews_order ON order_reviews(order_id);
CREATE INDEX idx_reviews_score ON order_reviews(review_score);

-- ============================================================================
-- VIEWS FOR ANALYSIS
-- ============================================================================

-- Order summary view
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    COUNT(oi.order_item_id) as total_items,
    SUM(oi.price) as total_price,
    SUM(oi.freight_value) as total_freight,
    SUM(oi.price + oi.freight_value) as total_amount,
    COALESCE(AVG(r.review_score), 0) as avg_review_score
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
GROUP BY o.order_id, o.customer_id, o.order_status, 
         o.order_purchase_timestamp, o.order_delivered_customer_date;

-- Product performance view
CREATE OR REPLACE VIEW vw_product_performance AS
SELECT 
    p.product_id,
    p.category_name,
    pc.category_name_english,
    COUNT(DISTINCT oi.order_id) as total_orders,
    SUM(oi.price) as total_revenue,
    AVG(oi.price) as avg_price,
    COUNT(oi.order_item_id) as units_sold,
    COALESCE(AVG(r.review_score), 0) as avg_rating
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN product_categories pc ON p.category_name = pc.category_name
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
GROUP BY p.product_id, p.category_name, pc.category_name_english;

-- Customer lifetime value view
CREATE OR REPLACE VIEW vw_customer_ltv AS
SELECT 
    c.customer_id,
    c.customer_state,
    c.customer_city,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(oi.price + oi.freight_value) as lifetime_value,
    AVG(oi.price + oi.freight_value) as avg_order_value,
    MIN(o.order_purchase_timestamp) as first_purchase,
    MAX(o.order_purchase_timestamp) as last_purchase,
    EXTRACT(DAY FROM MAX(o.order_purchase_timestamp) - MIN(o.order_purchase_timestamp)) as customer_age_days
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.customer_state, c.customer_city;

-- ============================================================================
-- END OF SCHEMA CREATION
-- ============================================================================