/*************************************************************************************************
-- Apple iTunes Music Analysis - Create Tables Script
--
-- Author: Shyam
-- Date: 2025-07-10
--
-- Purpose: Create all database tables with improved data types and constraints
-- Instructions: Run this after 01_drop_tables.sql
*************************************************************************************************/

CREATE TABLE artist (
    artist_id INTEGER PRIMARY KEY,
    name VARCHAR(120) NOT NULL
);

CREATE TABLE media_type (
    media_type_id INTEGER PRIMARY KEY,
    name VARCHAR(120) NOT NULL
);

CREATE TABLE genre (
    genre_id INTEGER PRIMARY KEY,
    name VARCHAR(120) NOT NULL
);

CREATE TABLE playlist (
    playlist_id INTEGER PRIMARY KEY,
    name VARCHAR(120) NOT NULL
);

CREATE TABLE employee (
    employee_id INTEGER PRIMARY KEY,
    last_name VARCHAR(20) NOT NULL,
    first_name VARCHAR(20) NOT NULL,
    title VARCHAR(30),
    reports_to INTEGER,
    levels VARCHAR(20),
    birthdate VARCHAR(30),
    hire_date VARCHAR(30),
    address VARCHAR(70),
    city VARCHAR(40),
    state VARCHAR(40),
    country VARCHAR(40),
    postal_code VARCHAR(10),
    phone VARCHAR(24),
    fax VARCHAR(24),
    email VARCHAR(60)
);

CREATE TABLE album (
    album_id INTEGER PRIMARY KEY,
    title VARCHAR(160) NOT NULL,
    artist_id INTEGER NOT NULL
);

CREATE TABLE customer (
    customer_id INTEGER PRIMARY KEY,
    first_name VARCHAR(40) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    company VARCHAR(80),
    address VARCHAR(70),
    city VARCHAR(40),
    state VARCHAR(40),
    country VARCHAR(40),
    postal_code VARCHAR(10),
    phone VARCHAR(24),
    fax VARCHAR(24),
    email VARCHAR(60),
    support_rep_id INTEGER
);

CREATE TABLE track (
    track_id INTEGER PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    album_id INTEGER,
    media_type_id INTEGER NOT NULL,
    genre_id INTEGER,
    composer VARCHAR(220),
    milliseconds INTEGER,
    bytes INTEGER,
    unit_price NUMERIC(10,2) NOT NULL DEFAULT 0.00
);

CREATE TABLE invoice (
    invoice_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    invoice_date TIMESTAMP NOT NULL,
    billing_address VARCHAR(70),
    billing_city VARCHAR(40),
    billing_state VARCHAR(40),
    billing_country VARCHAR(40),
    billing_postal_code VARCHAR(10),
    total NUMERIC(10,2) NOT NULL DEFAULT 0.00
);

CREATE TABLE invoice_line (
    invoice_line_id INTEGER PRIMARY KEY,
    invoice_id INTEGER NOT NULL,
    track_id INTEGER NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    quantity INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE playlist_track (
    playlist_id INTEGER NOT NULL,
    track_id INTEGER NOT NULL,
    PRIMARY KEY (playlist_id, track_id)
);