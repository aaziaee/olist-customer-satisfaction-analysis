-- Olist E-Commerce Database Schema
-- Created in dependency order (parent tables before children)

-- 1. Category name translation (no dependencies)
CREATE TABLE product_category_name_translation (
    product_category_name          VARCHAR(60)     PRIMARY KEY,
    product_category_name_english  VARCHAR(50)
);

-- 2. Sellers (no dependencies)
CREATE TABLE sellers (
    seller_id                CHAR(32)     PRIMARY KEY,
    seller_zip_code_prefix   INT,
    seller_city              VARCHAR(50),
    seller_state             CHAR(2)
);

-- 3. Customers (no dependencies)
CREATE TABLE customers (
    customer_id                CHAR(32)     PRIMARY KEY,
    customer_unique_id         CHAR(32)     NOT NULL,
    customer_zip_code_prefix   INT,
    customer_city              VARCHAR(50),
    customer_state             CHAR(2)
);

-- 4. Geolocation (no dependencies, no primary key — duplicate rows per zip)
CREATE TABLE geolocation (
    geolocation_zip_code_prefix   INT              NOT NULL,
    geolocation_lat                DECIMAL(12,8)    NOT NULL,
    geolocation_lng                DECIMAL(12,8)    NOT NULL,
    geolocation_city               VARCHAR(50),
    geolocation_state              CHAR(2)
);

-- 5. Products (depends on: product_category_name_translation)
CREATE TABLE products (
    product_id                    CHAR(32)      PRIMARY KEY,
    product_category_name         VARCHAR(60)   REFERENCES product_category_name_translation(product_category_name),
    product_name_lenght           SMALLINT,
    product_description_lenght    SMALLINT,
    product_photos_qty            SMALLINT,
    product_weight_g              INT,
    product_length_cm             SMALLINT,
    product_height_cm             SMALLINT,
    product_width_cm              SMALLINT
);

-- 6. Orders (depends on: customers)
CREATE TABLE orders (
    order_id                        CHAR(32)     PRIMARY KEY,
    customer_id                     CHAR(32)     NOT NULL REFERENCES customers(customer_id),
    order_status                    VARCHAR(20),
    order_purchase_timestamp        TIMESTAMP    NOT NULL,
    order_approved_at               TIMESTAMP,
    order_delivered_carrier_date    TIMESTAMP,
    order_delivered_customer_date   TIMESTAMP,
    order_estimated_delivery_date   DATE
);

-- 7. Order items (depends on: orders, products, sellers)
CREATE TABLE order_items (
    order_id               CHAR(32)        REFERENCES orders(order_id),
    order_item_id           SMALLINT,
    product_id               CHAR(32)        NOT NULL REFERENCES products(product_id),
    seller_id                 CHAR(32)        NOT NULL REFERENCES sellers(seller_id),
    shipping_limit_date       TIMESTAMP,
    price                       DECIMAL(7,2),
    freight_value               DECIMAL(6,2),
    PRIMARY KEY (order_id, order_item_id)
);

-- 8. Order payments (depends on: orders)
CREATE TABLE order_payments (
    order_id               CHAR(32)        REFERENCES orders(order_id),
    payment_sequential       SMALLINT,
    payment_type               VARCHAR(20),
    payment_installments         SMALLINT,
    payment_value                   DECIMAL(8,2)   NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

-- 9. Order reviews (depends on: orders)
CREATE TABLE order_reviews (
    review_id                CHAR(32)     NOT NULL,
    order_id                  CHAR(32)     NOT NULL REFERENCES orders(order_id),
    review_score                SMALLINT     NOT NULL,
    review_comment_title           TEXT,
    review_comment_message           TEXT,
    review_creation_date                DATE,
    review_answer_timestamp               TIMESTAMP,
    PRIMARY KEY (review_id, order_id)
);