CREATE DATABASE ecommerce_analytics;
USE ecommerce_analytics;
SELECT DATABASE();

show tables;

SELECT 'orders' AS table_name, COUNT(*) AS total_rows FROM orders
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation;


DESCRIBE orders;
DESCRIBE customers;
DESCRIBE order_items;
DESCRIBE payments;
DESCRIBE products;
DESCRIBE sellers;
DESCRIBE reviews;

SELECT COUNT(*) AS total_orders
FROM orders;

SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM customers;

SELECT ROUND(SUM(price), 2) AS total_revenue
FROM order_items;

SELECT ROUND(SUM(freight_value), 2) AS total_freight
FROM order_items;

# Average order value (AOV)
SELECT ROUND(SUM(order_revenue) / COUNT(*), 2) AS average_order_value
FROM (
    SELECT
        order_id,
        SUM(price) AS order_revenue
    FROM order_items
    GROUP BY order_id
) AS order_summary;

# Orders by status
SELECT order_status,COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

# Monthly revenue trend
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
ROUND(SUM(i.price), 2) AS monthly_revenue
FROM orders o
JOIN order_items i
ON o.order_id = i.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY month;

# Top 10 product categories by revenue
SELECT p.product_category_english AS category,
ROUND(SUM(i.price), 2) AS revenue
FROM order_items i
JOIN products p
ON i.product_id = p.product_id
GROUP BY p.product_category_english
ORDER BY revenue DESC
LIMIT 10;

#Top 10 states by customer count
SELECT customer_state,
COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC
LIMIT 10;

# Average customer review score
SELECT ROUND(AVG(review_score), 2) AS average_review_score,
COUNT(*) AS total_reviews
FROM reviews;


# Find repeat customers
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    ) AS repeat_customer_percentage
FROM customer_orders;


# Find customers who ordered more than once
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY total_orders DESC;


# Top 10 customers by spending
SELECT c.customer_unique_id,COUNT(DISTINCT o.order_id) AS total_orders,
ROUND(SUM(i.price), 2) AS total_spending
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN order_items i
ON o.order_id = i.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY total_spending DESC
LIMIT 10;

# Average delivery time
SELECT ROUND(AVG(delivery_days), 2) AS average_delivery_days
FROM orders
WHERE delivery_days IS NOT NULL
AND order_status = 'delivered';


# On-time vs late deliveries
SELECT
    CASE
        WHEN is_late = 1 THEN 'Late'
        WHEN is_late = 0 THEN 'On Time'
        ELSE 'Unknown'
    END AS delivery_status,
    COUNT(*) AS total_orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY delivery_status;


# Late delivery percentage
SELECT COUNT(*) AS total_delivered_orders,
SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) AS late_orders,
    ROUND(
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    ) AS late_delivery_percentage
FROM orders
WHERE order_status = 'delivered'
AND is_late IS NOT NULL;


# Average delivery delay by state
SELECT c.customer_state,COUNT(o.order_id) AS total_orders,
ROUND(AVG(o.delay_days), 2) AS average_delay_days
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
AND o.delay_days IS NOT NULL
GROUP BY c.customer_state
ORDER BY average_delay_days DESC;

# Average review score by delivery status

WITH review_summary AS (
    SELECT
        order_id,
        AVG(review_score) AS average_review
    FROM reviews
    GROUP BY order_id
)
SELECT
    CASE
        WHEN o.is_late = 1 THEN 'Late'
        WHEN o.is_late = 0 THEN 'On Time'
    END AS delivery_status,
    ROUND(AVG(r.average_review), 2) AS average_review_score,
    COUNT(*) AS total_orders
FROM orders o
JOIN review_summary r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.is_late IS NOT NULL
GROUP BY delivery_status;

USE ecommerce_analytics;

CREATE OR REPLACE VIEW customer_rfm AS

WITH order_level AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        SUM(i.price) AS order_value

    FROM orders o

    JOIN customers c
        ON o.customer_id = c.customer_id

    JOIN order_items i
        ON o.order_id = i.order_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL

    GROUP BY
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp
),

snapshot AS (
    SELECT
        MAX(order_purchase_timestamp) AS snapshot_date
    FROM order_level
),

customer_metrics AS (
    SELECT
        ol.customer_unique_id,

        DATEDIFF(
            s.snapshot_date,
            MAX(ol.order_purchase_timestamp)
        ) AS recency,

        COUNT(DISTINCT ol.order_id) AS frequency,

        ROUND(SUM(ol.order_value), 2) AS monetary

    FROM order_level ol
    CROSS JOIN snapshot s

    GROUP BY
        ol.customer_unique_id,
        s.snapshot_date
),

rfm_scores AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,

        NTILE(5) OVER (
            ORDER BY recency DESC
        ) AS r_score,

        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS f_score,

        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS m_score

    FROM customer_metrics
)

SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,

    CONCAT(r_score, f_score, m_score) AS rfm_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
            THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3
            THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2
            THEN 'Recent Customers'
        WHEN r_score <= 2 AND f_score >= 3
            THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2
            THEN 'Hibernating'
        ELSE 'Needs Attention'
    END AS customer_segment
FROM rfm_scores;

#View customer-level RFM data
SELECT *
FROM customer_rfm
LIMIT 20;

#Count customers in each segment

SELECT
    customer_segment,
    COUNT(*) AS total_customers
FROM customer_rfm
GROUP BY customer_segment
ORDER BY total_customers DESC;

# Calculate revenue by customer segment
SELECT
    customer_segment,
    COUNT(*) AS total_customers,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(AVG(monetary), 2) AS average_customer_spending
FROM customer_rfm
GROUP BY customer_segment
ORDER BY total_revenue DESC;



# Find your top 10 Champions
SELECT customer_unique_id,recency,frequency,monetary,rfm_score,customer_segment
FROM customer_rfm
WHERE customer_segment = 'Champions'
ORDER BY monetary DESC
LIMIT 10;


# cohort retention query

USE ecommerce_analytics;

WITH customer_months AS (

    -- Get each customer's purchase month
    SELECT DISTINCT
        c.customer_unique_id,

        DATE_SUB(
            DATE(o.order_purchase_timestamp),
            INTERVAL DAYOFMONTH(o.order_purchase_timestamp) - 1 DAY
        ) AS order_month

    FROM orders o

    JOIN customers c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
),

first_purchase AS (

    -- Find each customer's first purchase month
    SELECT
        customer_unique_id,
        MIN(order_month) AS cohort_month

    FROM customer_months
    GROUP BY customer_unique_id
),

cohort_data AS (

    -- Calculate the month number after first purchase
    SELECT
        cm.customer_unique_id,
        fp.cohort_month,
        cm.order_month,

        TIMESTAMPDIFF(
            MONTH,
            fp.cohort_month,
            cm.order_month
        ) AS month_number

    FROM customer_months cm

    JOIN first_purchase fp
        ON cm.customer_unique_id = fp.customer_unique_id
),

cohort_size AS (

    -- Count customers in each original cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_unique_id) AS total_customers

    FROM cohort_data
    WHERE month_number = 0
    GROUP BY cohort_month
),

retention AS (

    -- Count active customers in each cohort month
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers

    FROM cohort_data
    GROUP BY cohort_month, month_number
)

SELECT
    DATE_FORMAT(r.cohort_month, '%Y-%m') AS cohort,
    r.month_number,
    cs.total_customers,
    r.active_customers,

    ROUND(
        r.active_customers * 100.0 / cs.total_customers,
        2
    ) AS retention_percentage

FROM retention r

JOIN cohort_size cs
    ON r.cohort_month = cs.cohort_month

ORDER BY
    r.cohort_month,
    r.month_number;
    
    
#Top 10 sellers by revenue
USE ecommerce_analytics;

SELECT
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT i.order_id) AS total_orders,
    COUNT(*) AS total_items,
    ROUND(SUM(i.price), 2) AS total_revenue,
    ROUND(AVG(i.price), 2) AS average_item_price
FROM sellers s
JOIN order_items i
    ON s.seller_id = i.seller_id
JOIN orders o
    ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    s.seller_id,
    s.seller_state
ORDER BY total_revenue DESC
LIMIT 10;



#Seller delivery performance

WITH seller_orders AS (

    SELECT DISTINCT
        i.seller_id,
        o.order_id,
        o.delivery_days,
        o.delay_days,
        o.is_late

    FROM order_items i

    JOIN orders o
        ON i.order_id = o.order_id

    WHERE o.order_status = 'delivered'
)

SELECT seller_id,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    SUM(CASE
        WHEN is_late = 1 THEN 1
        ELSE 0
    END) AS late_orders,
    ROUND(
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)
        * 100.0 /
        NULLIF(SUM(CASE WHEN is_late IS NOT NULL THEN 1 ELSE 0 END), 0),
        2
    ) AS late_delivery_percentage
FROM seller_orders
GROUP BY seller_id
ORDER BY late_delivery_percentage DESC;



#Compare seller revenue and delivery performance

WITH seller_revenue AS (

    SELECT
        seller_id,
        ROUND(SUM(price), 2) AS total_revenue
    FROM order_items
    GROUP BY seller_id
),

seller_delivery AS (

    SELECT DISTINCT
        i.seller_id,
        o.order_id,
        o.delivery_days,
        o.is_late
    FROM order_items i
    JOIN orders o
        ON i.order_id = o.order_id
    WHERE o.order_status = 'delivered'
)
SELECT
    s.seller_id,
    s.seller_state,
    sr.total_revenue,
    COUNT(DISTINCT sd.order_id) AS delivered_orders,
    ROUND(AVG(sd.delivery_days), 2) AS avg_delivery_days,
    ROUND(
        AVG(CASE WHEN sd.is_late = 1 THEN 1.0
                 WHEN sd.is_late = 0 THEN 0.0
            END) * 100,
        2
    ) AS late_delivery_percentage
FROM sellers s
JOIN seller_revenue sr
    ON s.seller_id = sr.seller_id
LEFT JOIN seller_delivery sd
    ON s.seller_id = sd.seller_id
GROUP BY
    s.seller_id,
    s.seller_state,
    sr.total_revenue
ORDER BY sr.total_revenue DESC
LIMIT 20;




# Calculate monthly revenue
WITH monthly_revenue AS (

    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS sales_month,

        ROUND(SUM(i.price), 2) AS total_revenue

    FROM orders o

    JOIN order_items i
        ON o.order_id = i.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
)
SELECT
    sales_month,
    total_revenue
FROM monthly_revenue
ORDER BY sales_month;




#Calculate Month-over-Month growth
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS sales_month,

        ROUND(SUM(i.price), 2) AS total_revenue
    FROM orders o

    JOIN order_items i
        ON o.order_id = i.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
),
revenue_comparison AS (
    SELECT
        sales_month,
        total_revenue,

        LAG(total_revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue

    FROM monthly_revenue
)
SELECT
    sales_month,
    total_revenue,
    previous_month_revenue,
    ROUND(
        (total_revenue - previous_month_revenue)
        * 100.0 / NULLIF(previous_month_revenue, 0),
        2
    ) AS growth_percentage
FROM revenue_comparison
ORDER BY sales_month;













