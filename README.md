# Apple iTunes Music Analysis Project

## Project Overview

This project provides a comprehensive SQL-based analytical pipeline for analyzing Apple iTunes music store data. The analysis covers customer behavior, sales performance, product popularity, and business intelligence insights.

## Project Structure

```
apple-itunes-music-analysis/
├── 01_drop_tables.sql              # Drop existing tables
├── 02_create_tables.sql             # Create database schema
├── 03_add_constraints.sql           # Add constraints and indexes
├── 04_data_validation.sql           # Data quality validation
├── 05_basic_statistics.sql          # Basic data statistics
├── 06_data_exploration.sql          # Initial data exploration
├── 07_customer_analytics.sql        # Customer behavior analysis
├── 08_sales_revenue_analysis.sql    # Sales and revenue trends
├── 09_product_content_analysis.sql  # Product performance analysis
├── 10_advanced_analytics.sql        # Advanced analytics with window functions
├── 11_executive_summary.sql         # Executive dashboard and KPIs
├── data_import_guide.md             # Data import instructions
└── README.md                        # This file
```

## Database Schema

The database consists of 11 interconnected tables:

- **artist**: Music artists information
- **album**: Album details linked to artists
- **track**: Individual tracks with pricing and metadata
- **genre**: Music genres classification
- **media_type**: Audio format types
- **playlist**: Curated music playlists
- **playlist_track**: Many-to-many relationship between playlists and tracks
- **customer**: Customer information and demographics
- **employee**: Staff information and hierarchy
- **invoice**: Purchase transactions
- **invoice_line**: Individual items within transactions

## Setup Instructions

### Prerequisites
- PostgreSQL 12+ (recommended)
- Access to iTunes sample database CSV files
- SQL client (pgAdmin, DBeaver, or command line)

### Installation Steps

1. **Database Setup**
   ```sql
   -- Run scripts in order:
   \i 01_drop_tables.sql
   \i 02_create_tables.sql
   ```

2. **Data Import**
   - Import CSV files for each table
   - Ensure data integrity

3. **Add Constraints**
   ```sql
   \i 03_add_constraints.sql
   ```

4. **Validate Data**
   ```sql
   \i 04_data_validation.sql
   ```

## Analysis Modules

### 1. Basic Statistics (`05_basic_statistics.sql`)
- Database overview and summary statistics
- Customer, product, and sales metrics
- Data quality indicators

### 2. Data Exploration (`06_data_exploration.sql`)
- Geographic distribution analysis
- Genre and media type breakdown
- Customer purchase patterns
- Employee performance overview

### 3. Customer Analytics (`07_customer_analytics.sql`)
- Top spending customers identification
- Customer lifetime value analysis
- Repeat vs one-time customer segmentation
- Geographic revenue analysis
- Inactive customer identification
- Customer behavior segmentation

### 4. Sales & Revenue Analysis (`08_sales_revenue_analysis.sql`)
- Monthly and quarterly revenue trends
- Sales representative performance
- Peak sales period identification
- Invoice value distribution
- Year-over-year growth analysis

### 5. Product & Content Analysis (`09_product_content_analysis.sql`)
- Top performing tracks and albums
- Revenue by artist and genre
- Unpurchased content identification
- Playlist popularity analysis
- Media type performance trends

### 6. Advanced Analytics (`10_advanced_analytics.sql`)
- Customer ranking and percentiles
- Running totals and moving averages
- Cohort analysis
- Geographic market opportunities
- Track performance trends

### 7. Executive Summary (`11_executive_summary.sql`)
- Key performance indicators (KPIs)
- Business health metrics
- Customer segmentation summary
- Strategic recommendations

## Key Business Questions Answered

### Customer Analytics
- Which customers generate the most revenue?
- What is the average customer lifetime value?
- How many customers are repeat purchasers?
- Which countries have the highest revenue per customer?
- Which customers are at risk of churn?

### Sales Performance
- What are the monthly revenue trends?
- Which sales representatives are most effective?
- What are the peak sales periods?
- How does average order value vary over time?

### Product Performance
- Which tracks and artists generate the most revenue?
- Which content has never been purchased?
- How do genres perform relative to catalog size?
- What are the most popular playlists?

### Operational Insights
- Which markets present expansion opportunities?
- How can we optimize our product mix?
- What customer segments should we prioritize?
- Where should we focus marketing efforts?
