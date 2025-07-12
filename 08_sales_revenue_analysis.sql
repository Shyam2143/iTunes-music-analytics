/*************************************************************************************************
-- Apple iTunes Music Analysis - Sales & Revenue Analysis (FIXED)
--
-- Author: Shyam
-- Date: 2025-07-10
--
-- Purpose: Sales performance and revenue trend analysis
-- Instructions: Business performance metrics and trends
*************************************************************************************************/

-- Q1: Monthly revenue trends (showing all available data)
SELECT 'Monthly Revenue Trends' as analysis;

SELECT 
    TO_CHAR(invoice_date, 'YYYY-MM') as month,
    COUNT(*) as invoice_count,
    ROUND(SUM(total)::numeric, 2) as monthly_revenue,
    ROUND(AVG(total)::numeric, 2) as avg_invoice_value,
    LAG(SUM(total)) OVER (ORDER BY TO_CHAR(invoice_date, 'YYYY-MM')) as prev_month_revenue,
    ROUND(
        ((SUM(total) - LAG(SUM(total)) OVER (ORDER BY TO_CHAR(invoice_date, 'YYYY-MM'))) 
        / NULLIF(LAG(SUM(total)) OVER (ORDER BY TO_CHAR(invoice_date, 'YYYY-MM')), 0)) * 100, 
        2
    ) as revenue_growth_percent
FROM invoice
GROUP BY TO_CHAR(invoice_date, 'YYYY-MM')
ORDER BY month;

-- Q2: Quarterly revenue analysis
SELECT 'Quarterly Revenue Analysis' as analysis;

SELECT 
    EXTRACT(YEAR FROM invoice_date) as year,
    EXTRACT(QUARTER FROM invoice_date) as quarter,
    COUNT(*) as invoice_count,
    ROUND(SUM(total)::numeric, 2) as quarterly_revenue,
    ROUND(AVG(total)::numeric, 2) as avg_invoice_value,
    COUNT(DISTINCT customer_id) as unique_customers
FROM invoice
GROUP BY EXTRACT(YEAR FROM invoice_date), EXTRACT(QUARTER FROM invoice_date)
ORDER BY year, quarter;

-- Q3: Average invoice value analysis
SELECT 'Invoice Value Analysis' as analysis;

WITH invoice_stats AS (
    SELECT 
        AVG(total) as avg_total,
        MIN(total) as min_total,
        MAX(total) as max_total,
        STDDEV(total) as stddev_total,
        COUNT(*) as total_invoices
    FROM invoice
),
median_calc AS (
    SELECT total,
           ROW_NUMBER() OVER (ORDER BY total) as row_num,
           COUNT(*) OVER() as total_count
    FROM invoice
)
SELECT 
    ROUND(s.avg_total::numeric, 2) as avg_invoice_value,
    ROUND(AVG(CASE WHEN m.row_num IN (m.total_count/2, (m.total_count+1)/2) THEN m.total END)::numeric, 2) as median_invoice_value,
    ROUND(s.stddev_total::numeric, 2) as stddev_invoice_value,
    ROUND(s.min_total::numeric, 2) as min_invoice_value,
    ROUND(s.max_total::numeric, 2) as max_invoice_value,
    s.total_invoices
FROM invoice_stats s, median_calc m
GROUP BY s.avg_total, s.stddev_total, s.min_total, s.max_total, s.total_invoices;

-- Q4: Invoice size distribution
SELECT 'Invoice Size Distribution' as analysis;

SELECT 
    CASE 
        WHEN total < 2 THEN 'Under $2'
        WHEN total BETWEEN 2 AND 5 THEN '$2 - $5'
        WHEN total BETWEEN 5 AND 10 THEN '$5 - $10'
        WHEN total BETWEEN 10 AND 20 THEN '$10 - $20'
        WHEN total >= 20 THEN '$20+'
    END as invoice_size_range,
    COUNT(*) as invoice_count,
    ROUND(SUM(total)::numeric, 2) as total_revenue,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage_of_invoices,
    ROUND(SUM(total) * 100.0 / SUM(SUM(total)) OVER(), 2) as percentage_of_revenue
FROM invoice
GROUP BY 
    CASE 
        WHEN total < 2 THEN 'Under $2'
        WHEN total BETWEEN 2 AND 5 THEN '$2 - $5'
        WHEN total BETWEEN 5 AND 10 THEN '$5 - $10'
        WHEN total BETWEEN 10 AND 20 THEN '$10 - $20'
        WHEN total >= 20 THEN '$20+'
    END
ORDER BY MIN(total);

-- Q5: Sales representative performance
SELECT 'Sales Representative Performance' as analysis;

SELECT 
    CONCAT(e.first_name, ' ', e.last_name) as sales_rep,
    e.title,
    COUNT(DISTINCT c.customer_id) as customers_managed,
    COUNT(i.invoice_id) as total_sales,
    ROUND(COALESCE(SUM(i.total), 0)::numeric, 2) as total_revenue,
    ROUND(COALESCE(AVG(i.total), 0)::numeric, 2) as avg_sale_value,
    ROUND(
        COALESCE(SUM(i.total), 0) / NULLIF(COUNT(DISTINCT c.customer_id), 0), 
        2
    ) as revenue_per_customer
FROM employee e
LEFT JOIN customer c ON e.employee_id = c.support_rep_id
LEFT JOIN invoice i ON c.customer_id = i.customer_id
WHERE e.title LIKE '%Sales%' OR e.title LIKE '%Support%'
GROUP BY e.employee_id, e.first_name, e.last_name, e.title
ORDER BY total_revenue DESC;

-- Q6: Peak sales periods analysis
SELECT 'Peak Sales Periods - By Day of Week' as analysis;

SELECT 
    TO_CHAR(invoice_date, 'Day') as day_of_week,
    EXTRACT(DOW FROM invoice_date) as dow_number,
    COUNT(*) as invoice_count,
    ROUND(SUM(total)::numeric, 2) as total_revenue,
    ROUND(AVG(total)::numeric, 2) as avg_invoice_value
FROM invoice
GROUP BY TO_CHAR(invoice_date, 'Day'), EXTRACT(DOW FROM invoice_date)
ORDER BY dow_number;

-- Q7: Peak sales periods - By month
SELECT 'Peak Sales Periods - By Month' as analysis;

SELECT 
    TO_CHAR(invoice_date, 'Month') as month_name,
    EXTRACT(MONTH FROM invoice_date) as month_number,
    COUNT(*) as invoice_count,
    ROUND(SUM(total)::numeric, 2) as total_revenue,
    ROUND(AVG(total)::numeric, 2) as avg_invoice_value
FROM invoice
GROUP BY TO_CHAR(invoice_date, 'Month'), EXTRACT(MONTH FROM invoice_date)
ORDER BY month_number;

-- Q8: Year-over-year growth analysis
SELECT 'Year-over-Year Growth Analysis' as analysis;

WITH yearly_revenue AS (
    SELECT 
        EXTRACT(YEAR FROM invoice_date) as year,
        ROUND(SUM(total)::numeric, 2) as annual_revenue,
        COUNT(*) as annual_invoices,
        COUNT(DISTINCT customer_id) as annual_customers
    FROM invoice
    GROUP BY EXTRACT(YEAR FROM invoice_date)
)
SELECT 
    year,
    annual_revenue,
    annual_invoices,
    annual_customers,
    LAG(annual_revenue) OVER (ORDER BY year) as prev_year_revenue,
    ROUND(
        ((annual_revenue - LAG(annual_revenue) OVER (ORDER BY year)) 
        / NULLIF(LAG(annual_revenue) OVER (ORDER BY year), 0)) * 100, 
        2
    ) as revenue_growth_percent,
    ROUND(annual_revenue / annual_customers, 2) as revenue_per_customer
FROM yearly_revenue
ORDER BY year;

-- Q9: Recent trends (last 24 months of available data)
SELECT 'Recent Monthly Trends (Last 24 Months of Data)' as analysis;

WITH date_range AS (
    SELECT 
        MAX(invoice_date) as max_date,
        MAX(invoice_date) - INTERVAL '24 months' as start_date
    FROM invoice
)
SELECT 
    TO_CHAR(invoice_date, 'YYYY-MM') as month,
    COUNT(*) as invoice_count,
    ROUND(SUM(total)::numeric, 2) as monthly_revenue,
    ROUND(AVG(total)::numeric, 2) as avg_invoice_value,
    LAG(SUM(total)) OVER (ORDER BY TO_CHAR(invoice_date, 'YYYY-MM')) as prev_month_revenue,
    ROUND(
        ((SUM(total) - LAG(SUM(total)) OVER (ORDER BY TO_CHAR(invoice_date, 'YYYY-MM'))) 
        / NULLIF(LAG(SUM(total)) OVER (ORDER BY TO_CHAR(invoice_date, 'YYYY-MM')), 0)) * 100, 
        2
    ) as revenue_growth_percent
FROM invoice, date_range
WHERE invoice_date >= date_range.start_date
GROUP BY TO_CHAR(invoice_date, 'YYYY-MM')
ORDER BY month;