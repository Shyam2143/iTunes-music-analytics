/*************************************************************************************************
-- Apple iTunes Music Analysis - Advanced Analytics
--
-- Author: Shyam
-- Date: 2025-07-10
--
-- Purpose: Complex analytics using window functions, CTEs, and subqueries
-- Instructions: Advanced business intelligence queries
*************************************************************************************************/

-- Q1: Customer Ranking and Percentiles
SELECT 'Customer Revenue Rankings and Percentiles' as analysis;

WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) as customer_name,
        c.country,
        COALESCE(SUM(i.total), 0) as total_spent,
        COUNT(i.invoice_id) as purchase_count
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.country
)
SELECT 
    customer_name,
    country,
    total_spent,
    purchase_count,
    ROW_NUMBER() OVER (ORDER BY total_spent DESC) as revenue_rank,
    DENSE_RANK() OVER (ORDER BY total_spent DESC) as revenue_dense_rank,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_spent), 4) as revenue_percentile,
    CASE 
        WHEN PERCENT_RANK() OVER (ORDER BY total_spent) >= 0.9 THEN 'Top 10%'
        WHEN PERCENT_RANK() OVER (ORDER BY total_spent) >= 0.75 THEN 'Top 25%'
        WHEN PERCENT_RANK() OVER (ORDER BY total_spent) >= 0.5 THEN 'Top 50%'
        ELSE 'Bottom 50%'
    END as customer_tier
FROM customer_revenue
WHERE total_spent > 0
ORDER BY total_spent DESC
LIMIT 30;

-- Q2: Running totals and moving averages for monthly revenue
SELECT 'Monthly Revenue with Running Totals and Moving Averages' as analysis;

WITH monthly_revenue AS (
    SELECT 
        TO_CHAR(invoice_date, 'YYYY-MM') as month,
        SUM(total) as monthly_revenue,
        COUNT(*) as monthly_invoices
    FROM invoice
    GROUP BY TO_CHAR(invoice_date, 'YYYY-MM')
)
SELECT 
    month,
    ROUND(monthly_revenue, 2) as monthly_revenue,
    monthly_invoices,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY month), 2) as running_total,
    ROUND(
        AVG(monthly_revenue) OVER (
            ORDER BY month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) as three_month_avg,
    ROUND(
        AVG(monthly_revenue) OVER (
            ORDER BY month 
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ), 2
    ) as six_month_avg,
    LAG(monthly_revenue, 1) OVER (ORDER BY month) as prev_month,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY month)) 
        / NULLIF(LAG(monthly_revenue, 1) OVER (ORDER BY month), 0) * 100, 
        2
    ) as month_over_month_growth
FROM monthly_revenue
ORDER BY month;

-- Q3: Artist performance with ranking within genres
SELECT 'Artist Performance Rankings within Genres' as analysis;

WITH artist_genre_performance AS (
    SELECT 
        ar.name as artist_name,
        g.name as genre,
        COUNT(DISTINCT t.track_id) as track_count,
        COUNT(il.track_id) as sales_count,
        ROUND(SUM(il.unit_price * il.quantity), 2) as revenue
    FROM artist ar
    JOIN album al ON ar.artist_id = al.artist_id
    JOIN track t ON al.album_id = t.album_id
    JOIN genre g ON t.genre_id = g.genre_id
    LEFT JOIN invoice_line il ON t.track_id = il.track_id
    GROUP BY ar.artist_id, ar.name, g.genre_id, g.name
    HAVING COUNT(DISTINCT t.track_id) >= 3  -- Artists with at least 3 tracks in genre
)
SELECT 
    genre,
    artist_name,
    track_count,
    sales_count,
    COALESCE(revenue, 0) as revenue,
    ROW_NUMBER() OVER (PARTITION BY genre ORDER BY revenue DESC NULLS LAST) as genre_rank,
    ROUND(
        revenue / SUM(revenue) OVER (PARTITION BY genre) * 100, 2
    ) as genre_revenue_share
FROM artist_genre_performance
WHERE ROW_NUMBER() OVER (PARTITION BY genre ORDER BY revenue DESC NULLS LAST) <= 5
ORDER BY genre, genre_rank;

-- Q4: Customer cohort analysis by first purchase month
SELECT 'Customer Cohort Analysis' as analysis;

WITH customer_first_purchase AS (
    SELECT 
        customer_id,
        MIN(invoice_date) as first_purchase_date,
        TO_CHAR(MIN(invoice_date), 'YYYY-MM') as cohort_month
    FROM invoice
    GROUP BY customer_id
),
customer_monthly_activity AS (
    SELECT 
        cfp.customer_id,
        cfp.cohort_month,
        TO_CHAR(i.invoice_date, 'YYYY-MM') as activity_month,
        EXTRACT(
            EPOCH FROM (
                DATE_TRUNC('month', i.invoice_date) - 
                DATE_TRUNC('month', cfp.first_purchase_date)
            )
        ) / (30 * 24 * 3600) as months_since_first_purchase
    FROM customer_first_purchase cfp
    JOIN invoice i ON cfp.customer_id = i.customer_id
)
SELECT 
    cohort_month,
    months_since_first_purchase,
    COUNT(DISTINCT customer_id) as active_customers,
    ROUND(
        COUNT(DISTINCT customer_id) * 100.0 / 
        FIRST_VALUE(COUNT(DISTINCT customer_id)) OVER (
            PARTITION BY cohort_month 
            ORDER BY months_since_first_purchase
        ), 2
    ) as retention_rate
FROM customer_monthly_activity
WHERE cohort_month >= '2012-01'  -- Focus on recent cohorts
GROUP BY cohort_month, months_since_first_purchase
ORDER BY cohort_month, months_since_first_purchase;

-- Q5: Top performing tracks with trend analysis
SELECT 'Track Performance Trends' as analysis;

WITH track_monthly_performance AS (
    SELECT 
        t.track_id,
        t.name as track_name,
        ar.name as artist_name,
        TO_CHAR(i.invoice_date, 'YYYY-MM') as month,
        COUNT(il.track_id) as monthly_sales,
        SUM(il.unit_price * il.quantity) as monthly_revenue
    FROM track t
    JOIN album al ON t.album_id = al.album_id
    JOIN artist ar ON al.artist_id = ar.artist_id
    JOIN invoice_line il ON t.track_id = il.track_id
    JOIN invoice i ON il.invoice_id = i.invoice_id
    GROUP BY t.track_id, t.name, ar.name, TO_CHAR(i.invoice_date, 'YYYY-MM')
),
track_trends AS (
    SELECT 
        track_id,
        track_name,
        artist_name,
        month,
        monthly_sales,
        monthly_revenue,
        LAG(monthly_sales) OVER (
            PARTITION BY track_id 
            ORDER BY month
        ) as prev_month_sales,
        ROW_NUMBER() OVER (
            PARTITION BY track_id 
            ORDER BY month
        ) as month_sequence
    FROM track_monthly_performance
)
SELECT 
    track_name,
    artist_name,
    COUNT(*) as months_active,
    SUM(monthly_sales) as total_sales,
    ROUND(SUM(monthly_revenue), 2) as total_revenue,
    ROUND(AVG(monthly_sales), 2) as avg_monthly_sales,
    MAX(monthly_sales) as peak_monthly_sales,
    ROUND(STDDEV(monthly_sales), 2) as sales_volatility
FROM track_trends
GROUP BY track_id, track_name, artist_name
HAVING SUM(monthly_sales) >= 5  -- Tracks with at least 5 total sales
ORDER BY total_revenue DESC
LIMIT 20;

-- Q6: Geographic expansion opportunities
SELECT 'Geographic Market Analysis' as analysis;

WITH country_metrics AS (
    SELECT 
        c.country,
        COUNT(DISTINCT c.customer_id) as customer_count,
        COALESCE(SUM(i.total), 0) as total_revenue,
        COALESCE(AVG(i.total), 0) as avg_order_value,
        COUNT(i.invoice_id) as total_orders,
        MAX(i.invoice_date) as last_order_date
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.country
),
country_rankings AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) as revenue_rank,
        ROW_NUMBER() OVER (ORDER BY customer_count DESC) as customer_rank,
        total_revenue / NULLIF(customer_count, 0) as revenue_per_customer
    FROM country_metrics
)
SELECT 
    country,
    customer_count,
    ROUND(total_revenue, 2) as total_revenue,
    ROUND(avg_order_value, 2) as avg_order_value,
    total_orders,
    ROUND(revenue_per_customer, 2) as revenue_per_customer,
    revenue_rank,
    customer_rank,
    last_order_date,
    CASE 
        WHEN customer_count >= 5 AND revenue_per_customer >= 35 THEN 'High Value Market'
        WHEN customer_count >= 5 AND revenue_per_customer < 35 THEN 'Growth Opportunity'
        WHEN customer_count < 5 AND revenue_per_customer >= 35 THEN 'Niche Market'
        ELSE 'Emerging Market'
    END as market_classification
FROM country_rankings
ORDER BY total_revenue DESC;