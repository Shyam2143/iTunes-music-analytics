/*************************************************************************************************
-- Apple iTunes Music Analysis - Add Constraints and Indexes
--
-- Author: Shyam
-- Date: 2025-07-10
--
-- Purpose: Add foreign key constraints and performance indexes
-- Instructions: Run this after creating tables and importing data
*************************************************************************************************/

-- Convert employee date fields from VARCHAR to DATE
ALTER TABLE employee 
ALTER COLUMN birthdate TYPE DATE USING TO_DATE(birthdate, 'DD-MM-YYYY HH24:MI'), 
ALTER COLUMN hire_date TYPE DATE USING TO_DATE(hire_date, 'DD-MM-YYYY HH24:MI');

-- Add Foreign Key Constraints
ALTER TABLE album 
ADD CONSTRAINT fk_album_artist 
FOREIGN KEY (artist_id) REFERENCES artist(artist_id);

ALTER TABLE track 
ADD CONSTRAINT fk_track_album 
FOREIGN KEY (album_id) REFERENCES album(album_id);

ALTER TABLE track 
ADD CONSTRAINT fk_track_media_type 
FOREIGN KEY (media_type_id) REFERENCES media_type(media_type_id);

ALTER TABLE track 
ADD CONSTRAINT fk_track_genre 
FOREIGN KEY (genre_id) REFERENCES genre(genre_id);

ALTER TABLE customer 
ADD CONSTRAINT fk_customer_employee 
FOREIGN KEY (support_rep_id) REFERENCES employee(employee_id);

ALTER TABLE employee 
ADD CONSTRAINT fk_employee_reports_to 
FOREIGN KEY (reports_to) REFERENCES employee(employee_id);

ALTER TABLE invoice 
ADD CONSTRAINT fk_invoice_customer 
FOREIGN KEY (customer_id) REFERENCES customer(customer_id);

ALTER TABLE invoice_line 
ADD CONSTRAINT fk_invoice_line_invoice 
FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id);

ALTER TABLE invoice_line 
ADD CONSTRAINT fk_invoice_line_track 
FOREIGN KEY (track_id) REFERENCES track(track_id);

ALTER TABLE playlist_track 
ADD CONSTRAINT fk_playlist_track_playlist 
FOREIGN KEY (playlist_id) REFERENCES playlist(playlist_id);

ALTER TABLE playlist_track 
ADD CONSTRAINT fk_playlist_track_track 
FOREIGN KEY (track_id) REFERENCES track(track_id);

-- Create Performance Indexes
CREATE INDEX idx_customer_country ON customer(country);
CREATE INDEX idx_customer_support_rep ON customer(support_rep_id);
CREATE INDEX idx_invoice_date ON invoice(invoice_date);
CREATE INDEX idx_invoice_customer ON invoice(customer_id);
CREATE INDEX idx_invoice_date_customer ON invoice(invoice_date, customer_id);
CREATE INDEX idx_track_genre ON track(genre_id);
CREATE INDEX idx_track_album ON track(album_id);
CREATE INDEX idx_track_media_type ON track(media_type_id);
CREATE INDEX idx_track_price ON track(unit_price);
CREATE INDEX idx_album_artist ON album(artist_id);
CREATE INDEX idx_invoice_line_track ON invoice_line(track_id);
CREATE INDEX idx_invoice_line_invoice ON invoice_line(invoice_id);
CREATE INDEX idx_employee_reports_to ON employee(reports_to);
CREATE INDEX idx_customer_country_city ON customer(country, city);
CREATE INDEX idx_track_genre_price ON track(genre_id, unit_price);
CREATE INDEX idx_employee_birthdate ON employee(birthdate);
CREATE INDEX idx_employee_hire_date ON employee(hire_date);

-- Add Check Constraints
ALTER TABLE track ADD CONSTRAINT chk_track_price_positive CHECK (unit_price >= 0);
ALTER TABLE invoice ADD CONSTRAINT chk_invoice_total_positive CHECK (total >= 0);
ALTER TABLE invoice_line ADD CONSTRAINT chk_invoice_line_price_positive CHECK (unit_price >= 0);
ALTER TABLE invoice_line ADD CONSTRAINT chk_invoice_line_quantity_positive CHECK (quantity > 0);

-- Create Materialized Views for Performance
CREATE MATERIALIZED VIEW mv_customer_summary AS
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.country,
    c.city,
    COUNT(i.invoice_id) as total_purchases,
    COALESCE(SUM(i.total), 0) as lifetime_value,
    COALESCE(AVG(i.total), 0) as avg_order_value,
    MAX(i.invoice_date) as last_purchase_date
FROM customer c
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.country, c.city;

CREATE UNIQUE INDEX ON mv_customer_summary(customer_id);
CREATE INDEX ON mv_customer_summary(country);
CREATE INDEX ON mv_customer_summary(lifetime_value DESC);