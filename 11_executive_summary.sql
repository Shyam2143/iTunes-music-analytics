/*************************************************************************************************
-- Apple iTunes Music Analysis - Executive Summary & KPIs
--
-- Author: Shyam
-- Date: 2025-07-10
--
-- Purpose: Executive dashboard with key performance indicators
-- Instructions: High-level business metrics for leadership team
*************************************************************************************************/

-- Executive Summary - Key Business Metrics
SELECT 'EXECUTIVE SUMMARY - KEY METRICS' as report_section;

WITH business_metrics AS (
    SELECT 
        COUNT(DISTINCT c.customer_id) as total_customers,
        COUNT(DISTINCT i.invoice_id) as total_transactions,
        ROUND(SUM(i.total), 2) as total_revenue,
        ROUND(AVG(i.total), 2) as avg_transaction_value,
        COUNT(DISTINCT ar.artist_id) as total_artists,
        COUNT(DISTINCT t.track_id) as total_tracks,
        COUNT(DISTINCT il.track_id) as tracks_sold,
        MAX(i.invoice_date) as latest_transaction,
        MIN(i.invoice_date) as earliest_transaction
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    CROSS JOIN artist ar
    CROSS JOIN track t
    LEFT JOIN invoice_line il ON t.track_id = il.track_id
)
SELECT 
    'Total Revenue' as metric, 
    CONCAT('$', total_revenue) as value,
    'Primary business outcome' as description
FROM business_metrics
UNION ALL
SELECT 
    'Total Customers', 
    total_customers::text,
    'Active customer base'
FROM business_metrics
UNION ALL
SELECT 
    'Total Transactions', 
    total_transactions::text,
    'Purchase frequency indicator'
FROM business_metrics
UNION ALL
SELECT 
    'Average Transaction Value', 
    CONCAT('$', avg_transaction_value),
    'Customer spending behavior'
FROM business_metrics
UNION ALL
SELECT 
    'Music Catalog Size', 
    total_tracks::text,
    'Available inventory'
FROM business_metrics
UNION ALL
SELECT 
    'Catalog Utilization', 
    CONCAT(ROUND(tracks_sold * 100.0 / total_tracks, 1), '%'),
    'Percentage of tracks sold'
FROM business_metrics;

-- Monthly Performance Trends (Last 12 Months)
SELECT 'MONTHLY PERFORMANCE TRENDS (Last 12 Months)' as report_section;

WITH monthly_kpis AS (
    SELECT 
        TO_CHAR(invoice_date, 'YYYY-MM') as month,
        COUNT(DISTINCT customer_id) as active_customers,
        COUNT(*) as transactions,
        ROUND(SUM(total), 2) as revenue,
        ROUND(AVG(total), 2) as avg_transaction_value
    FROM invoice
    WHERE invoice_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY TO_CHAR(invoice_date, 'YYYY-MM')
)
SELECT 
    month,
    active_customers,
    transactions,
    revenue,
    avg_transaction_value,
    LAG(revenue) OVER (ORDER BY month) as prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) / 
        NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 1
    ) as revenue_growth_pct
FROM monthly_kpis
ORDER BY month;

-- Top Performance Categories
SELECT 'TOP PERFORMERS BY CATEGORY' as report_section;

-- Top 5 Revenue Countries
SELECT 'Top Revenue Countries' as category, country as name, 
       CONCAT('$', ROUND(SUM(total), 2)) as value
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY country
ORDER BY SUM(total) DESC
LIMIT 5

UNION ALL

-- Top 5 Revenue Artists
SELECT 'Top Revenue Artists', ar.name,
       CONCAT('$', ROUND(SUM(il.unit_price * il.quantity), 2))
FROM artist ar
JOIN album al ON ar.artist_id = al.artist_id
JOIN track t ON al.album_id = t.album_id
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY ar.artist_id, ar.name
ORDER BY SUM(il.unit_price * il.quantity) DESC
LIMIT 5

UNION ALL

-- Top 5 Revenue Genres
SELECT 'Top Revenue Genres', g.name,
       CONCAT('$', ROUND(SUM(il.unit_price * il.quantity), 2))
FROM genre g
JOIN track t ON g.genre_id = t.genre_id
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY g.genre_id, g.name
ORDER BY SUM(il.unit_price * il.quantity) DESC
LIMIT 5;

-- Customer Segment Analysis
SELECT 'CUSTOMER SEGMENTATION ANALYSIS' as report_section;

WITH customer_segments AS (
    SELECT 
        c.customer_id,
        COUNT(i.invoice_id) as purchase_frequency,
        COALESCE(SUM(i.total), 0) as total_spent,
        MAX(i.invoice_date) as last_purchase,
        CASE 
            WHEN COALESCE(SUM(i.total), 0) >= 40 AND COUNT(i.invoice_id) >= 7 THEN 'VIP'
            WHEN COALESCE(SUM(i.total), 0) >= 20 AND COUNT(i.invoice_id) >= 4 THEN 'Loyal'
            WHEN COALESCE(SUM(i.total), 0) >= 10 OR COUNT(i.invoice_id) >= 2 THEN 'Regular'
            WHEN COALESCE(SUM(i.total), 0) > 0 THEN 'New'
            ELSE 'Inactive'
        END as segment,
        CASE 
            WHEN MAX(i.invoice_date) IS NULL THEN 'Never Purchased'
            WHEN MAX(i.invoice_date) < CURRENT_DATE - INTERVAL '6 months' THEN 'At Risk'
            WHEN MAX(i.invoice_date) < CURRENT_DATE - INTERVAL '3 months' THEN 'Declining'
            ELSE 'Active'
        END as activity_status
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
)
SELECT 
    segment,
    activity_status,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_spent,
    ROUND(SUM(total_spent), 2) as segment_revenue,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as customer_percentage,
    ROUND(SUM(total_spent) * 100.0 / SUM(SUM(total_spent)) OVER(), 1) as revenue_percentage
FROM customer_segments
GROUP BY segment, activity_status
ORDER BY segment_revenue DESC;

-- Business Health Indicators
SELECT 'BUSINESS HEALTH INDICATORS' as report_section;

WITH health_metrics AS (
    SELECT 
        -- Customer metrics
        COUNT(DISTINCT CASE WHEN i.invoice_date >= CURRENT_DATE - INTERVAL '1 month' THEN c.customer_id END) as active_customers_1m,
        COUNT(DISTINCT CASE WHEN i.invoice_date >= CURRENT_DATE - INTERVAL '3 months' THEN c.customer_id END) as active_customers_3m,
        COUNT(DISTINCT c.customer_id) as total_customers,
        
        -- Revenue metrics
        SUM(CASE WHEN i.invoice_date >= CURRENT_DATE - INTERVAL '1 month' THEN i.total ELSE 0 END) as revenue_1m,
        SUM(CASE WHEN i.invoice_date >= CURRENT_DATE - INTERVAL '3 months' THEN i.total ELSE 0 END) as revenue_3m,
        SUM(i.total) as total_revenue,
        
        -- Product metrics
        COUNT(DISTINCT il.track_id) as tracks_sold,
        COUNT(DISTINCT t.track_id) as total_tracks
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    CROSS JOIN track t
    LEFT JOIN invoice_line il ON t.track_id = il.track_id
)
SELECT 
    'Customer Engagement Rate (1M)' as indicator,
    CONCAT(ROUND(active_customers_1m * 100.0 / NULLIF(total_customers, 0), 1), '%') as value,
    'Customers active in last month vs total' as definition
FROM health_metrics
UNION ALL
SELECT 
    'Customer Engagement Rate (3M)',
    CONCAT(ROUND(active_customers_3m * 100.0 / NULLIF(total_customers, 0), 1), '%'),
    'Customers active in last 3 months vs total'
FROM health_metrics
UNION ALL
SELECT 
    'Catalog Utilization Rate',
    CONCAT(ROUND(tracks_sold * 100.0 / NULLIF(total_tracks, 0), 1), '%'),
    'Percentage of catalog that has been sold'
FROM health_metrics
UNION ALL
SELECT 
    'Revenue Concentration (1M)',
    CONCAT(ROUND(revenue_1m * 100.0 / NULLIF(total_revenue, 0), 1), '%'),
    'Percentage of total revenue from last month'
FROM health_metrics;

-- Recommendations Summary
SELECT 'KEY RECOMMENDATIONS' as report_section;

SELECT 
    1 as priority,
    'Customer Retention' as focus_area,
    'Implement targeted campaigns for at-risk customers' as recommendation,
    'High impact on revenue sustainability' as rationale
UNION ALL
SELECT 
    2,
    'Geographic Expansion',
    'Expand marketing in high-value, low-penetration countries',
    'Untapped revenue potential in existing markets'
UNION ALL
SELECT 
    3,
    'Catalog Optimization',
    'Promote or discount unpurchased tracks',
    'Improve inventory turnover and ROI'
UNION ALL
SELECT 
    4,
    'Customer Segmentation',
    'Develop VIP customer loyalty programs',
    'Maximize value from top-spending customers'
UNION ALL
SELECT 
    5,
    'Product Mix',
    'Focus on high-performing genres and artists',
    'Optimize content acquisition strategy'
ORDER BY priority;