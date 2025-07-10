/*************************************************************************************************
-- Apple iTunes Music Analysis - Product & Content Analysis
--
-- Author: Shyam
-- Date: 2025-07-10
--
-- Purpose: Track, album, and content performance analysis
-- Instructions: Product popularity and revenue analysis
*************************************************************************************************/

-- Q1: Top revenue-generating tracks
SELECT 'Top 20 Revenue-Generating Tracks' as analysis;

SELECT 
    t.name as track_name,
    al.title as album_title,
    ar.name as artist_name,
    g.name as genre,
    COUNT(il.track_id) as times_purchased,
    ROUND(SUM(il.unit_price * il.quantity), 2) as total_revenue,
    ROUND(AVG(il.unit_price), 2) as avg_selling_price,
    t.unit_price as catalog_price
FROM track t
JOIN album al ON t.album_id = al.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
JOIN genre g ON t.genre_id = g.genre_id
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY t.track_id, t.name, al.title, ar.name, g.name, t.unit_price
ORDER BY total_revenue DESC
LIMIT 20;

-- Q2: Most frequently purchased tracks
SELECT 'Most Frequently Purchased Tracks' as analysis;

SELECT 
    t.name as track_name,
    al.title as album_title,
    ar.name as artist_name,
    COUNT(il.track_id) as purchase_count,
    SUM(il.quantity) as total_quantity_sold,
    ROUND(SUM(il.unit_price * il.quantity), 2) as total_revenue
FROM track t
JOIN album al ON t.album_id = al.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY t.track_id, t.name, al.title, ar.name
ORDER BY purchase_count DESC, total_quantity_sold DESC
LIMIT 20;

-- Q3: Albums with highest revenue
SELECT 'Top Revenue-Generating Albums' as analysis;

SELECT 
    al.title as album_title,
    ar.name as artist_name,
    COUNT(DISTINCT t.track_id) as tracks_in_album,
    COUNT(il.track_id) as total_track_purchases,
    ROUND(SUM(il.unit_price * il.quantity), 2) as album_revenue,
    ROUND(AVG(il.unit_price), 2) as avg_track_price
FROM album al
JOIN artist ar ON al.artist_id = ar.artist_id
JOIN track t ON al.album_id = t.album_id
LEFT JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY al.album_id, al.title, ar.name
ORDER BY album_revenue DESC NULLS LAST
LIMIT 15;

-- Q4: Tracks that have never been purchased
SELECT 'Unpurchased Tracks Analysis' as analysis;

SELECT 
    t.name as track_name,
    al.title as album_title,
    ar.name as artist_name,
    g.name as genre,
    mt.name as media_type,
    t.unit_price,
    ROUND(t.milliseconds/1000/60.0, 2) as duration_minutes
FROM track t
JOIN album al ON t.album_id = al.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
JOIN genre g ON t.genre_id = g.genre_id
JOIN media_type mt ON t.media_type_id = mt.media_type_id
LEFT JOIN invoice_line il ON t.track_id = il.track_id
WHERE il.track_id IS NULL
ORDER BY ar.name, al.title, t.name
LIMIT 50;

-- Q5: Average price per track by genre
SELECT 'Average Track Price by Genre' as analysis;

SELECT 
    g.name as genre,
    COUNT(t.track_id) as total_tracks,
    ROUND(AVG(t.unit_price), 2) as avg_catalog_price,
    ROUND(MIN(t.unit_price), 2) as min_price,
    ROUND(MAX(t.unit_price), 2) as max_price,
    COUNT(CASE WHEN il.track_id IS NOT NULL THEN 1 END) as tracks_sold,
    ROUND(
        COUNT(CASE WHEN il.track_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(t.track_id), 
        2
    ) as sell_through_rate
FROM genre g
JOIN track t ON g.genre_id = t.genre_id
LEFT JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY g.genre_id, g.name
ORDER BY avg_catalog_price DESC;

-- Q6: Track count vs sales correlation by genre
SELECT 'Genre Performance: Track Count vs Sales' as analysis;

SELECT 
    g.name as genre,
    COUNT(DISTINCT t.track_id) as total_tracks,
    COUNT(il.invoice_line_id) as total_sales,
    ROUND(SUM(il.unit_price * il.quantity), 2) as total_revenue,
    ROUND(
        COUNT(il.invoice_line_id) / COUNT(DISTINCT t.track_id)::decimal, 
        2
    ) as sales_per_track,
    ROUND(
        SUM(il.unit_price * il.quantity) / COUNT(DISTINCT t.track_id)::decimal, 
        2
    ) as revenue_per_track
FROM genre g
JOIN track t ON g.genre_id = t.genre_id
LEFT JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY g.genre_id, g.name
ORDER BY revenue_per_track DESC;

-- Q7: Most popular playlists (by track inclusion)
SELECT 'Most Popular Playlists by Track Count' as analysis;

SELECT 
    p.name as playlist_name,
    COUNT(pt.track_id) as track_count,
    COUNT(DISTINCT g.genre_id) as genre_diversity,
    ROUND(AVG(t.unit_price), 2) as avg_track_price,
    ROUND(SUM(t.unit_price), 2) as total_playlist_value
FROM playlist p
JOIN playlist_track pt ON p.playlist_id = pt.playlist_id
JOIN track t ON pt.track_id = t.track_id
LEFT JOIN genre g ON t.genre_id = g.genre_id
GROUP BY p.playlist_id, p.name
ORDER BY track_count DESC;

-- Q8: Content analysis by media type
SELECT 'Content Analysis by Media Type' as analysis;

SELECT 
    mt.name as media_type,
    COUNT(t.track_id) as track_count,
    ROUND(AVG(t.unit_price), 2) as avg_price,
    ROUND(AVG(t.milliseconds/1000/60.0), 2) as avg_duration_minutes,
    COUNT(il.track_id) as tracks_sold,
    ROUND(SUM(il.unit_price * il.quantity), 2) as total_revenue
FROM media_type mt
JOIN track t ON mt.media_type_id = t.media_type_id
LEFT JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY mt.media_type_id, mt.name
ORDER BY total_revenue DESC NULLS LAST;

-- Q9: Artist productivity vs sales performance
SELECT 'Artist Productivity vs Sales Performance' as analysis;

SELECT 
    ar.name as artist,
    COUNT(DISTINCT al.album_id) as album_count,
    COUNT(DISTINCT t.track_id) as track_count,
    COUNT(il.track_id) as total_sales,
    ROUND(SUM(il.unit_price * il.quantity), 2) as total_revenue,
    ROUND(
        SUM(il.unit_price * il.quantity) / NULLIF(COUNT(DISTINCT t.track_id), 0), 
        2
    ) as revenue_per_track,
    ROUND(
        COUNT(il.track_id) / NULLIF(COUNT(DISTINCT t.track_id), 0)::decimal, 
        2
    ) as avg_sales_per_track
FROM artist ar
JOIN album al ON ar.artist_id = al.artist_id
JOIN track t ON al.album_id = t.album_id
LEFT JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY ar.artist_id, ar.name
HAVING COUNT(DISTINCT t.track_id) >= 10  -- Artists with at least 10 tracks
ORDER BY total_revenue DESC NULLS LAST
LIMIT 20;