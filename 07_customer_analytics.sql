/*************************************************************************************************
-- Apple iTunes Music Analysis - Customer Analytics
--
-- Author: Shyam
-- Date: 2025-07-10
--
-- Purpose: Answer customer-related business questions
-- Instructions: Customer behavior and purchasing trend analysis
*************************************************************************************************/

-- Q1: Top spending customers and customer lifetime value
SELECT 'Top 20 Spending Customers' as analysis;

SELECT 
    CONCAT(c.first_name, ' ', c.last_name) as customer_name,
    c.email,
    c.country,
    c.city,
    COUNT(i.invoice_id) as total_purchases,
    ROUND(SUM(i.total), 2) as lifetime_value,
    ROUND(AVG(i.total), 2) as avg_order_value,
    MAX(i.invoice_date) as last_purchase_date
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.country, c.city
ORDER BY lifetime_value DESC
LIMIT 20;

-- Q2: Customer Lifetime Value Statistics
SELECT 'Customer Lifetime Value Statistics' as analysis;

WITH customer_clv AS (
    SELECT 
        c.customer_id,
        COALESCE(SUM(i.total), 0) as clv
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
)
SELECT 
    ROUND(AVG(clv), 2) as avg_customer_lifetime_value,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clv), 2) as median_clv,
    ROUND(STDDEV(clv), 2) as stddev_clv,
    ROUND(MIN(clv), 2) as min_clv,
    ROUND(MAX(clv), 2) as max_clv,
    COUNT(*) as total_customers
FROM customer_clv;

-- Q3: Repeat vs One-time customers
SELECT 'Customer Purchase Frequency Analysis' as analysis;

WITH customer_purchase_frequency AS (
    SELECT 
        c.customer_id,
        COUNT(i.invoice_id) as purchase_count,
        CASE 
            WHEN COUNT(i.invoice_id) = 0 THEN 'No purchases'
            WHEN COUNT(i.invoice_id) = 1 THEN 'One-time customer'
            ELSE 'Repeat customer'
        END as customer_type
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
)
SELECT 
    customer_type,
    COUNT(*) as customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM customer_purchase_frequency
GROUP BY customer_type
ORDER BY customer_count DESC;

-- Q4: Revenue by country and revenue per customer
SELECT 'Revenue Analysis by Country' as analysis;

SELECT 
    c.country,
    COUNT(DISTINCT c.customer_id) as customer_count,
    COALESCE(ROUND(SUM(i.total), 2), 0) as total_revenue,
    ROUND(COALESCE(SUM(i.total), 0) / COUNT(DISTINCT c.customer_id), 2) as revenue_per_customer,
    COUNT(i.invoice_id) as total_invoices,
    ROUND(COALESCE(AVG(i.total), 0), 2) as avg_invoice_value
FROM customer c
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.country
ORDER BY total_revenue DESC;

-- Q5: Customers who haven't purchased in the last 6 months
SELECT 'Inactive Customers (No purchases in last 6 months)' as analysis;

WITH customer_last_purchase AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) as customer_name,
        c.email,
        c.country,
        MAX(i.invoice_date) as last_purchase_date,
        COUNT(i.invoice_id) as total_purchases,
        COALESCE(SUM(i.total), 0) as total_spent
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.country
)
SELECT 
    customer_name,
    email,
    country,
    last_purchase_date,
    total_purchases,
    total_spent,
    CASE 
        WHEN last_purchase_date IS NULL THEN 'Never purchased'
        ELSE CONCAT(
            EXTRACT(days FROM (CURRENT_DATE - last_purchase_date::date)), 
            ' days ago'
        )
    END as days_since_last_purchase
FROM customer_last_purchase
WHERE last_purchase_date < CURRENT_DATE - INTERVAL '6 months' 
   OR last_purchase_date IS NULL
ORDER BY last_purchase_date ASC NULLS FIRST;

-- Q6: Customer Segmentation by Purchase Behavior
SELECT 'Customer Segmentation' as analysis;

WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) as customer_name,
        c.country,
        COUNT(i.invoice_id) as purchase_frequency,
        COALESCE(SUM(i.total), 0) as total_spent,
        COALESCE(AVG(i.total), 0) as avg_order_value,
        MAX(i.invoice_date) as last_purchase_date
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.country
),
customer_segments AS (
    SELECT 
        *,
        CASE 
            WHEN total_spent >= 40 AND purchase_frequency >= 7 THEN 'VIP Customer'
            WHEN total_spent >= 20 AND purchase_frequency >= 4 THEN 'Loyal Customer'
            WHEN total_spent >= 10 OR purchase_frequency >= 2 THEN 'Regular Customer'
            WHEN total_spent > 0 THEN 'New Customer'
            ELSE 'Inactive Customer'
        END as segment
    FROM customer_metrics
)
SELECT 
    segment,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_total_spent,
    ROUND(AVG(purchase_frequency), 1) as avg_purchase_frequency,
    ROUND(AVG(avg_order_value), 2) as avg_order_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM customer_segments
GROUP BY segment
ORDER BY avg_total_spent DESC;