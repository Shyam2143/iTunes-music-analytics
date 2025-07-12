/*************************************************************************************************
-- Apple iTunes Music Analysis - Executive Summary & KPIs (FINAL FIX)
--
-- Author: Shyam
-- Date: 2025-07-10
--
-- Purpose: Executive dashboard with key performance indicators
-- Instructions: High-level business metrics for leadership team
*************************************************************************************************/

-- Executive Summary - Key Business Metrics
WITH business_metrics AS (
    SELECT 
        (SELECT ROUND(SUM(total)::numeric, 2) FROM invoice) as total_revenue,
        (SELECT COUNT(*) FROM customer) as total_customers,
        (SELECT COUNT(*) FROM invoice) as total_transactions,
        (SELECT ROUND(AVG(total)::numeric, 2) FROM invoice) as avg_transaction_value,
        (SELECT COUNT(*) FROM track) as total_tracks,
        (SELECT COUNT(*) FROM artist) as total_artists
)
SELECT 'EXECUTIVE SUMMARY - KEY METRICS' as report_section, 
       'Total Revenue' as metric, 
       CONCAT('$', total_revenue) as value,
       'Primary business outcome' as description
FROM business_metrics
UNION ALL
SELECT 'EXECUTIVE SUMMARY - KEY METRICS',
       'Total Customers', 
       total_customers::text,
       'Active customer base'
FROM business_metrics
UNION ALL
SELECT 'EXECUTIVE SUMMARY - KEY METRICS',
       'Total Transactions', 
       total_transactions::text,
       'Purchase frequency indicator'
FROM business_metrics
UNION ALL
SELECT 'EXECUTIVE SUMMARY - KEY METRICS',
       'Average Transaction Value', 
       CONCAT('$', avg_transaction_value),
       'Customer spending behavior'
FROM business_metrics
UNION ALL
SELECT 'EXECUTIVE SUMMARY - KEY METRICS',
       'Music Catalog Size', 
       total_tracks::text,
       'Available inventory'
FROM business_metrics
UNION ALL
SELECT 'EXECUTIVE SUMMARY - KEY METRICS',
       'Total Artists', 
       total_artists::text,
       'Artist diversity'
FROM business_metrics;

-- Monthly Performance Trends (Last 12 Months of available data)
WITH date_boundary AS (
    SELECT MAX(invoice_date) as max_date FROM invoice
),
monthly_kpis AS (
    SELECT 
        TO_CHAR(i.invoice_date, 'YYYY-MM') as month,
        COUNT(DISTINCT i.customer_id) as active_customers,
        COUNT(*) as transactions,
        ROUND(SUM(i.total)::numeric, 2) as revenue,
        ROUND(AVG(i.total)::numeric, 2) as avg_transaction_value
    FROM invoice i, date_boundary d
    WHERE i.invoice_date >= d.max_date - INTERVAL '12 months'
    GROUP BY TO_CHAR(i.invoice_date, 'YYYY-MM')
)
SELECT 
    'MONTHLY PERFORMANCE TRENDS' as report_section,
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

-- Top 5 Countries by Revenue
SELECT 
    'TOP 5 COUNTRIES BY REVENUE' as report_section,
    c.country,
    COUNT(DISTINCT c.customer_id) as customer_count,
    ROUND(SUM(i.total)::numeric, 2) as total_revenue
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.country
ORDER BY total_revenue DESC
LIMIT 5;

-- Top 5 Artists by Revenue
SELECT 
    'TOP 5 ARTISTS BY REVENUE' as report_section,
    ar.name as artist_name,
    ROUND(SUM(il.unit_price * il.quantity)::numeric, 2) as total_revenue,
    COUNT(DISTINCT il.invoice_id) as total_sales
FROM artist ar
JOIN album al ON ar.artist_id = al.artist_id
JOIN track t ON al.album_id = t.album_id
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY ar.artist_id, ar.name
ORDER BY total_revenue DESC
LIMIT 5;

-- Top 5 Genres by Revenue
SELECT 
    'TOP 5 GENRES BY REVENUE' as report_section,
    g.name as genre_name,
    ROUND(SUM(il.unit_price * il.quantity)::numeric, 2) as total_revenue,
    COUNT(il.track_id) as tracks_sold
FROM genre g
JOIN track t ON g.genre_id = t.genre_id
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY g.genre_id, g.name
ORDER BY total_revenue DESC
LIMIT 5;

-- Customer Segmentation Analysis (Simplified)
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        COUNT(i.invoice_id) as purchase_count,
        COALESCE(SUM(i.total), 0) as total_spent
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
),
customer_segments AS (
    SELECT 
        CASE 
            WHEN total_spent >= 40 AND purchase_count >= 7 THEN 'VIP'
            WHEN total_spent >= 20 AND purchase_count >= 4 THEN 'Loyal'
            WHEN total_spent >= 10 OR purchase_count >= 2 THEN 'Regular'
            WHEN total_spent > 0 THEN 'New'
            ELSE 'Inactive'
        END as segment,
        total_spent,
        purchase_count
    FROM customer_spending
)
SELECT 
    'CUSTOMER SEGMENTATION ANALYSIS' as report_section,
    segment,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent)::numeric, 2) as avg_spent,
    ROUND(SUM(total_spent)::numeric, 2) as segment_revenue,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as customer_percentage,
    ROUND(SUM(total_spent) * 100.0 / SUM(SUM(total_spent)) OVER(), 1) as revenue_percentage
FROM customer_segments
GROUP BY segment
ORDER BY segment_revenue DESC;

-- Sales Performance by Employee
SELECT 
    'SALES PERFORMANCE BY EMPLOYEE' as report_section,
    CONCAT(e.first_name, ' ', e.last_name) as employee_name,
    e.title,
    COUNT(DISTINCT c.customer_id) as customers_managed,
    COUNT(i.invoice_id) as total_sales,
    ROUND(COALESCE(SUM(i.total), 0)::numeric, 2) as total_revenue
FROM employee e
LEFT JOIN customer c ON e.employee_id = c.support_rep_id
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.title
ORDER BY total_revenue DESC;

-- Business Health Indicators
WITH recent_dates AS (
    SELECT 
        MAX(invoice_date) as latest_date
    FROM invoice
),
customer_activity AS (
    SELECT 
        COUNT(DISTINCT CASE 
            WHEN i.invoice_date >= (SELECT latest_date FROM recent_dates) - INTERVAL '1 month' 
            THEN i.customer_id 
        END) as active_1m,
        COUNT(DISTINCT CASE 
            WHEN i.invoice_date >= (SELECT latest_date FROM recent_dates) - INTERVAL '3 months' 
            THEN i.customer_id 
        END) as active_3m
    FROM invoice i
),
totals AS (
    SELECT 
        COUNT(*) as total_customers
    FROM customer
),
catalog_metrics AS (
    SELECT 
        COUNT(DISTINCT il.track_id) as tracks_sold,
        COUNT(DISTINCT t.track_id) as total_tracks
    FROM track t
    LEFT JOIN invoice_line il ON t.track_id = il.track_id
)
SELECT 
    'BUSINESS HEALTH INDICATORS' as report_section,
    'Customer Engagement (1M)' as indicator,
    CONCAT(ROUND(ca.active_1m * 100.0 / NULLIF(t.total_customers, 0), 1), '%') as value,
    'Customers active in last month' as description
FROM customer_activity ca, totals t
UNION ALL
SELECT 
    'BUSINESS HEALTH INDICATORS',
    'Customer Engagement (3M)',
    CONCAT(ROUND(ca.active_3m * 100.0 / NULLIF(t.total_customers, 0), 1), '%'),
    'Customers active in last 3 months'
FROM customer_activity ca, totals t
UNION ALL
SELECT 
    'BUSINESS HEALTH INDICATORS',
    'Catalog Utilization',
    CONCAT(ROUND(cm.tracks_sold * 100.0 / NULLIF(cm.total_tracks, 0), 1), '%'),
    'Percentage of tracks ever sold'
FROM catalog_metrics cm;

-- Key Recommendations
SELECT 
    'KEY RECOMMENDATIONS' as report_section,
    1 as priority,
    'Customer Retention' as focus_area,
    'Implement targeted campaigns for at-risk customers' as recommendation,
    'High impact on revenue sustainability' as rationale
UNION ALL
SELECT 
    'KEY RECOMMENDATIONS',
    2,
    'Geographic Expansion',
    'Expand marketing in high-value, low-penetration countries',
    'Untapped revenue potential in existing markets'
UNION ALL
SELECT 
    'KEY RECOMMENDATIONS',
    3,
    'Catalog Optimization',
    'Promote or discount unpurchased tracks',
    'Improve inventory turnover and ROI'
UNION ALL
SELECT 
    'KEY RECOMMENDATIONS',
    4,
    'Customer Segmentation',
    'Develop VIP customer loyalty programs',
    'Maximize value from top-spending customers'
UNION ALL
SELECT 
    'KEY RECOMMENDATIONS',
    5,
    'Product Mix',
    'Focus on high-performing genres and artists',
    'Optimize content acquisition strategy'
ORDER BY priority;

-- Data Summary
WITH data_summary AS (
    SELECT 
        MIN(invoice_date) as earliest_date,
        MAX(invoice_date) as latest_date,
        COUNT(DISTINCT TO_CHAR(invoice_date, 'YYYY-MM')) as months_of_data
    FROM invoice
)
SELECT 
    'DATA SUMMARY' as report_section,
    'Data Period' as metric,
    CONCAT(
        TO_CHAR(earliest_date, 'YYYY-MM-DD'), 
        ' to ', 
        TO_CHAR(latest_date, 'YYYY-MM-DD')
    ) as value,
    CONCAT(months_of_data, ' months of transaction data') as description
FROM data_summary;