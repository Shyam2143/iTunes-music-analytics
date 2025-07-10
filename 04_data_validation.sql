/*************************************************************************************************
-- Apple iTunes Music Analysis - Data Validation
--
-- Author: Shyam
-- Date: 2025-07-10
--
-- Purpose: Validate data integrity and quality after import
-- Instructions: Run this after importing all CSV data
*************************************************************************************************/

-- Basic Row Counts
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
SELECT * FROM table_counts ORDER BY row_count DESC;

-- Check for NULL values in critical fields
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
)
SELECT * FROM validation_checks WHERE count > 0;

-- Check foreign key integrity
WITH integrity_checks AS (
    SELECT 'Orphaned albums' as integrity_check, COUNT(*) as count
    FROM album a WHERE NOT EXISTS (SELECT 1 FROM artist ar WHERE ar.artist_id = a.artist_id)
    UNION ALL
    SELECT 'Orphaned tracks', COUNT(*)
    FROM track t WHERE album_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM album a WHERE a.album_id = t.album_id)
    UNION ALL
    SELECT 'Orphaned invoices', COUNT(*)
    FROM invoice i WHERE NOT EXISTS (SELECT 1 FROM customer c WHERE c.customer_id = i.customer_id)
)
SELECT * FROM integrity_checks WHERE count > 0;

-- Data quality checks
WITH quality_checks AS (
    SELECT 'Invalid email formats' as quality_check, COUNT(*) as count
    FROM customer WHERE email IS NOT NULL AND email NOT LIKE '%@%'
    UNION ALL
    SELECT 'Negative prices', COUNT(*)
    FROM track WHERE unit_price < 0
    UNION ALL
    SELECT 'Future invoice dates', COUNT(*)
    FROM invoice WHERE invoice_date > CURRENT_TIMESTAMP
)
SELECT * FROM quality_checks WHERE count > 0;

-- Summary statistics
SELECT 
    'Data validation completed' as status,
    CURRENT_TIMESTAMP as validation_time;