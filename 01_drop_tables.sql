/*************************************************************************************************
-- Apple iTunes Music Analysis - Drop Tables Script
--
-- Author: Shyam
-- Date: 2025-07-10
--
-- Purpose: Clean database by dropping all tables in correct dependency order
-- Instructions: Run this script first if you need to recreate the database schema
*************************************************************************************************/

-- Drop tables in reverse order of dependencies to avoid foreign key constraint errors
DROP TABLE IF EXISTS playlist_track CASCADE;
DROP TABLE IF EXISTS invoice_line CASCADE;
DROP TABLE IF EXISTS invoice CASCADE;
DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS employee CASCADE;
DROP TABLE IF EXISTS track CASCADE;
DROP TABLE IF EXISTS album CASCADE;
DROP TABLE IF EXISTS artist CASCADE;
DROP TABLE IF EXISTS media_type CASCADE;
DROP TABLE IF EXISTS genre CASCADE;
DROP TABLE IF EXISTS playlist CASCADE;

-- Drop materialized views if they exist
DROP MATERIALIZED VIEW IF EXISTS mv_customer_summary CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mv_monthly_revenue CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mv_track_performance CASCADE;