/*************************************************************************************************
-- Apple iTunes Music Analysis - Data Exploration
--
-- Author: Shyam
-- Date: 2025-07-10
--
-- Purpose: Exploratory queries to understand the dataset
-- Instructions: Run this to explore data patterns and distributions
*************************************************************************************************/

-- Top 10 Countries by Customer Count
SELECT 'Top Countries by Customer Count' as analysis;

WITH country_stats AS (
    SELECT 
        country,
        COUNT(*) as customer_count,
        (SELECT COUNT(*) FROM customer) as total_customers
    FROM customer
    GROUP BY country
)
SELECT 
    country,
    customer_count,
    ROUND(customer_count * 100.0 / total_customers, 2) as percentage
FROM country_stats
ORDER BY customer_count DESC
LIMIT 10;

-- Genre Distribution
SELECT 'Genre Distribution' as analysis;

WITH genre_stats AS (
    SELECT 
        g.name as genre,
        COUNT(t.track_id) as track_count,
        ROUND(AVG(t.unit_price), 2) as avg_price,
        (SELECT COUNT(*) FROM track) as total_tracks
    FROM genre g
    LEFT JOIN track t ON g.genre_id = t.genre_id
    GROUP BY g.genre_id, g.name
)
SELECT 
    genre,
    track_count,
    avg_price,
    ROUND(track_count * 100.0 / total_tracks, 2) as percentage
FROM genre_stats
ORDER BY track_count DESC;

-- Media Type Analysis
SELECT 'Media Type Analysis' as analysis;

SELECT 
    mt.name as media_type,
    COUNT(t.track_id) as track_count,
    ROUND(AVG(t.unit_price), 2) as avg_price,
    ROUND(AVG(t.milliseconds/1000.0/60.0), 2) as avg_duration_minutes
FROM media_type mt
LEFT JOIN track t ON mt.media_type_id = t.media_type_id
GROUP BY mt.media_type_id, mt.name
ORDER BY track_count DESC;

-- Top Artists by Album Count
SELECT 'Top Artists by Album Count' as analysis;

SELECT 
    ar.name as artist,
    COUNT(DISTINCT a.album_id) as album_count,
    COUNT(t.track_id) as total_tracks
FROM artist ar
LEFT JOIN album a ON ar.artist_id = a.artist_id
LEFT JOIN track t ON a.album_id = t.album_id
GROUP BY ar.artist_id, ar.name
ORDER BY album_count DESC, total_tracks DESC
LIMIT 15;

-- Customer Purchase Behavior
SELECT 'Customer Purchase Patterns' as analysis;

WITH customer_behavior AS (
    SELECT 
        c.customer_id,
        COUNT(i.invoice_id) as invoice_count,
        COALESCE(SUM(i.total), 0) as total_spent
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
)
SELECT 
    CASE 
        WHEN invoice_count = 0 THEN 'No purchases'
        WHEN invoice_count = 1 THEN '1 purchase'
        WHEN invoice_count BETWEEN 2 AND 5 THEN '2-5 purchases'
        WHEN invoice_count BETWEEN 6 AND 10 THEN '6-10 purchases'
        WHEN invoice_count > 10 THEN '10+ purchases'
    END as purchase_frequency,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_total_spent
FROM customer_behavior
GROUP BY 
    CASE 
        WHEN invoice_count = 0 THEN 'No purchases'
        WHEN invoice_count = 1 THEN '1 purchase'
        WHEN invoice_count BETWEEN 2 AND 5 THEN '2-5 purchases'
        WHEN invoice_count BETWEEN 6 AND 10 THEN '6-10 purchases'
        WHEN invoice_count > 10 THEN '10+ purchases'
    END
ORDER BY MIN(invoice_count);

-- Monthly Sales Trends
SELECT 'Monthly Sales Trends' as analysis;

SELECT 
    TO_CHAR(invoice_date, 'YYYY-MM') as month,
    COUNT(*) as invoice_count,
    ROUND(SUM(total), 2) as total_revenue,
    ROUND(AVG(total), 2) as avg_invoice_value
FROM invoice
GROUP BY TO_CHAR(invoice_date, 'YYYY-MM')
ORDER BY month;

-- Employee Customer Management
SELECT 'Employee Customer Management' as analysis;

SELECT 
    CONCAT(e.first_name, ' ', e.last_name) as employee_name,
    e.title,
    COUNT(DISTINCT c.customer_id) as customers_managed,
    ROUND(COALESCE(SUM(i.total), 0), 2) as total_revenue_generated
FROM employee e
LEFT JOIN customer c ON e.employee_id = c.support_rep_id
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.title
ORDER BY total_revenue_generated DESC;