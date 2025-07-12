/*************************************************************************************************
-- Apple iTunes Music Analysis - Basic Statistics (FIXED)
--
-- Author: Shyam
-- Date: 2025-07-10
--
-- Purpose: Generate basic statistics and data summaries
-- Instructions: Run this for initial data exploration
*************************************************************************************************/

-- Database Overview
SELECT 'Database Overview' as section;

WITH overview_stats AS (
    SELECT 
        (SELECT COUNT(*) FROM customer) as total_customers,
        (SELECT COUNT(*) FROM employee) as total_employees,
        (SELECT COUNT(*) FROM artist) as total_artists,
        (SELECT COUNT(*) FROM album) as total_albums,
        (SELECT COUNT(*) FROM track) as total_tracks,
        (SELECT COUNT(*) FROM genre) as total_genres,
        (SELECT COUNT(*) FROM invoice) as total_invoices,
        (SELECT COALESCE(SUM(total), 0) FROM invoice) as total_revenue
)
SELECT * FROM overview_stats;

-- Customer Statistics
SELECT 'Customer Statistics' as section;

WITH customer_stats AS (
    SELECT 
        COUNT(DISTINCT c.country) as countries_served,
        COUNT(DISTINCT c.city) as cities_served,
        ROUND(AVG(i.total)::numeric, 2) as avg_invoice_value,
        ROUND(MAX(i.total)::numeric, 2) as max_invoice_value,
        ROUND(MIN(i.total)::numeric, 2) as min_invoice_value
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    WHERE i.total IS NOT NULL
)
SELECT * FROM customer_stats;

-- Track and Music Statistics
SELECT 'Music Catalog Statistics' as section;

WITH music_stats AS (
    SELECT 
        ROUND(AVG(unit_price)::numeric, 2) as avg_track_price,
        ROUND(MAX(unit_price)::numeric, 2) as max_track_price,
        ROUND(MIN(unit_price)::numeric, 2) as min_track_price,
        ROUND(AVG(milliseconds/1000.0/60.0)::numeric, 2) as avg_track_duration_minutes,
        COUNT(CASE WHEN composer IS NOT NULL AND composer != '' THEN 1 END) as tracks_with_composer,
        COUNT(CASE WHEN composer IS NULL OR composer = '' THEN 1 END) as tracks_without_composer
    FROM track
)
SELECT * FROM music_stats;

-- Sales Statistics
SELECT 'Sales Statistics' as section;

WITH sales_stats AS (
    SELECT 
        COUNT(*) as total_line_items,
        SUM(quantity) as total_units_sold,
        ROUND(AVG(unit_price)::numeric, 2) as avg_selling_price,
        ROUND(SUM(unit_price * quantity)::numeric, 2) as total_line_revenue
    FROM invoice_line
)
SELECT * FROM sales_stats;

-- Time Period Analysis
SELECT 'Time Period Coverage' as section;

WITH time_analysis AS (
    SELECT 
        MIN(invoice_date) as earliest_invoice,
        MAX(invoice_date) as latest_invoice,
        COUNT(DISTINCT DATE_TRUNC('month', invoice_date)) as months_of_data,
        COUNT(DISTINCT EXTRACT(YEAR FROM invoice_date)) as years_of_data
    FROM invoice
)
SELECT * FROM time_analysis;

-- Employee Statistics
SELECT 'Employee Statistics' as section;

WITH employee_stats AS (
    SELECT 
        COUNT(*) as total_employees,
        COUNT(DISTINCT title) as unique_titles,
        COUNT(CASE WHEN reports_to IS NULL THEN 1 END) as top_level_employees,
        COUNT(CASE WHEN reports_to IS NOT NULL THEN 1 END) as reporting_employees
    FROM employee
)
SELECT * FROM employee_stats;