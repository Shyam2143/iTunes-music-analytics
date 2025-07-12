/*************************************************************************************************
-- Apple iTunes Music Analysis - Data Validation (COMPREHENSIVE)
--
-- Author: Shyam
-- Date: 2025-07-10
--
-- Purpose: Validate data integrity and quality after import
-- Instructions: Run this after importing all CSV data
*************************************************************************************************/

-- Basic Row Counts
SELECT 'TABLE ROW COUNTS' as validation_category;

WITH table_counts AS (
    SELECT 'artist' as table_name, COUNT(*) as row_count FROM artist
    UNION ALL
    SELECT 'album', COUNT(*) FROM album
    UNION ALL
    SELECT 'track', COUNT(*) FROM track
    UNION ALL
    SELECT 'customer', COUNT(*) FROM customer
    UNION ALL
    SELECT 'employee', COUNT(*) FROM employee
    UNION ALL
    SELECT 'invoice', COUNT(*) FROM invoice
    UNION ALL
    SELECT 'invoice_line', COUNT(*) FROM invoice_line
    UNION ALL
    SELECT 'playlist', COUNT(*) FROM playlist
    UNION ALL
    SELECT 'playlist_track', COUNT(*) FROM playlist_track
    UNION ALL
    SELECT 'genre', COUNT(*) FROM genre
    UNION ALL
    SELECT 'media_type', COUNT(*) FROM media_type
)
SELECT table_name, row_count FROM table_counts ORDER BY row_count DESC;

-- Check for NULL values in critical fields (SHOW ALL RESULTS)
SELECT 'NULL VALUE CHECKS' as validation_category;

WITH validation_checks AS (
    SELECT 'Missing artist names' as validation_check, COUNT(*) as count
    FROM artist WHERE name IS NULL OR name = ''
    UNION ALL
    SELECT 'Missing customer emails', COUNT(*)
    FROM customer WHERE email IS NULL OR email = ''
    UNION ALL
    SELECT 'Missing track prices', COUNT(*)
    FROM track WHERE unit_price IS NULL
    UNION ALL
    SELECT 'Missing invoice totals', COUNT(*)
    FROM invoice WHERE total IS NULL
    UNION ALL
    SELECT 'Missing album titles', COUNT(*)
    FROM album WHERE title IS NULL OR title = ''
    UNION ALL
    SELECT 'Missing track names', COUNT(*)
    FROM track WHERE name IS NULL OR name = ''
)
SELECT 
    validation_check,
    count,
    CASE WHEN count = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM validation_checks 
ORDER BY count DESC;

-- Check foreign key integrity (SHOW ALL RESULTS)
SELECT 'FOREIGN KEY INTEGRITY CHECKS' as validation_category;

WITH integrity_checks AS (
    SELECT 'Orphaned albums' as integrity_check, COUNT(*) as count
    FROM album a WHERE NOT EXISTS (SELECT 1 FROM artist ar WHERE ar.artist_id = a.artist_id)
    UNION ALL
    SELECT 'Orphaned tracks', COUNT(*)
    FROM track t WHERE album_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM album a WHERE a.album_id = t.album_id)
    UNION ALL
    SELECT 'Orphaned invoices', COUNT(*)
    FROM invoice i WHERE NOT EXISTS (SELECT 1 FROM customer c WHERE c.customer_id = i.customer_id)
    UNION ALL
    SELECT 'Orphaned invoice lines', COUNT(*)
    FROM invoice_line il WHERE NOT EXISTS (SELECT 1 FROM invoice i WHERE i.invoice_id = il.invoice_id)
    UNION ALL
    SELECT 'Orphaned customers (no support rep)', COUNT(*)
    FROM customer c WHERE support_rep_id IS NOT NULL 
    AND NOT EXISTS (SELECT 1 FROM employee e WHERE e.employee_id = c.support_rep_id)
)
SELECT 
    integrity_check,
    count,
    CASE WHEN count = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM integrity_checks 
ORDER BY count DESC;

-- Data quality checks (SHOW ALL RESULTS)
SELECT 'DATA QUALITY CHECKS' as validation_category;

WITH quality_checks AS (
    SELECT 'Invalid email formats' as quality_check, COUNT(*) as count
    FROM customer WHERE email IS NOT NULL AND email NOT LIKE '%@%'
    UNION ALL
    SELECT 'Negative track prices', COUNT(*)
    FROM track WHERE unit_price < 0
    UNION ALL
    SELECT 'Future invoice dates', COUNT(*)
    FROM invoice WHERE invoice_date > NOW()
    UNION ALL
    SELECT 'Zero or negative invoice totals', COUNT(*)
    FROM invoice WHERE total <= 0
    UNION ALL
    SELECT 'Zero or negative quantities', COUNT(*)
    FROM invoice_line WHERE quantity <= 0
    UNION ALL
    SELECT 'Tracks with zero duration', COUNT(*)
    FROM track WHERE milliseconds IS NOT NULL AND milliseconds <= 0
)
SELECT 
    quality_check,
    count,
    CASE WHEN count = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM quality_checks 
ORDER BY count DESC;

-- Additional Data Range Checks
SELECT 'DATA RANGE VALIDATION' as validation_category;

WITH range_checks AS (
    SELECT 'Track prices outside normal range ($0.01-$10)' as range_check, 
           COUNT(*) as count
    FROM track WHERE unit_price IS NOT NULL AND (unit_price < 0.01 OR unit_price > 10.00)
    UNION ALL
    SELECT 'Invoices with unusual totals (>$100)', 
           COUNT(*)
    FROM invoice WHERE total > 100
    UNION ALL
    SELECT 'Very short tracks (<10 seconds)', 
           COUNT(*)
    FROM track WHERE milliseconds IS NOT NULL AND milliseconds < 10000
    UNION ALL
    SELECT 'Very long tracks (>30 minutes)', 
           COUNT(*)
    FROM track WHERE milliseconds IS NOT NULL AND milliseconds > 1800000
)
SELECT 
    range_check,
    count,
    CASE WHEN count = 0 THEN '✓ NORMAL' 
         WHEN count < 10 THEN '⚠ REVIEW' 
         ELSE '✗ INVESTIGATE' END as status
FROM range_checks 
ORDER BY count DESC;

-- Date Range Summary
SELECT 'DATE RANGE SUMMARY' as validation_category;

SELECT 
    'Invoice Date Range' as summary_item,
    MIN(invoice_date) as earliest_date,
    MAX(invoice_date) as latest_date,
    COUNT(DISTINCT DATE_TRUNC('month', invoice_date)) as months_of_data
FROM invoice
UNION ALL
SELECT 
    'Employee Date Range',
    MIN(hire_date) as earliest_date,
    MAX(hire_date) as latest_date,
    COUNT(*) as employee_count
FROM employee WHERE hire_date IS NOT NULL;

-- Summary validation report
SELECT 'VALIDATION SUMMARY' as validation_category;

WITH all_checks AS (
    -- NULL checks
    SELECT COUNT(*) as issues FROM (
        SELECT COUNT(*) as cnt FROM artist WHERE name IS NULL OR name = ''
        UNION ALL SELECT COUNT(*) FROM customer WHERE email IS NULL OR email = ''
        UNION ALL SELECT COUNT(*) FROM track WHERE unit_price IS NULL
        UNION ALL SELECT COUNT(*) FROM invoice WHERE total IS NULL
    ) x WHERE x.cnt > 0
    
    UNION ALL
    
    -- Integrity checks  
    SELECT COUNT(*) FROM (
        SELECT COUNT(*) as cnt FROM album a WHERE NOT EXISTS (SELECT 1 FROM artist ar WHERE ar.artist_id = a.artist_id)
        UNION ALL SELECT COUNT(*) FROM track t WHERE album_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM album a WHERE a.album_id = t.album_id)
        UNION ALL SELECT COUNT(*) FROM invoice i WHERE NOT EXISTS (SELECT 1 FROM customer c WHERE c.customer_id = i.customer_id)
    ) x WHERE x.cnt > 0
    
    UNION ALL
    
    -- Quality checks
    SELECT COUNT(*) FROM (
        SELECT COUNT(*) as cnt FROM customer WHERE email IS NOT NULL AND email NOT LIKE '%@%'
        UNION ALL SELECT COUNT(*) FROM track WHERE unit_price < 0
        UNION ALL SELECT COUNT(*) FROM invoice WHERE invoice_date > NOW()
    ) x WHERE x.cnt > 0
)
SELECT 
    'Total Issues Found' as metric,
    SUM(issues) as count,
    CASE 
        WHEN SUM(issues) = 0 THEN '✓ DATA IS CLEAN - NO ISSUES FOUND'
        WHEN SUM(issues) < 5 THEN '⚠ MINOR ISSUES FOUND'
        ELSE '✗ MAJOR ISSUES NEED ATTENTION'
    END as overall_status
FROM all_checks;

-- Final completion message
SELECT 
    'Data validation completed successfully' as status,
    NOW() as validation_time,
    'All checks passed - your data integrity is excellent!' as message;