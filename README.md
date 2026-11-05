# E-Commerce Sales, Customer Retention & Delivery Performance Analysis

An end-to-end data analytics project using the **Brazilian E-Commerce Public Dataset by Olist** to explore sales performance, customer behaviour, retention patterns, and delivery operations. The project combines Python, MySQL, and Power BI to turn raw transactional data into actionable business insights.

## Project at a Glance

| Area | Details |
|---|---|
| Domain | E-commerce / Business Analytics |
| Dataset | Olist Brazilian E-Commerce Public Dataset |
| Period | 2016–2018 |
| Tools | Python, Pandas, NumPy, MySQL, SQL, Power BI, DAX |
| Analysis | Sales trends, customer retention, RFM segmentation, delivery and seller performance |

## Dataset Overview

The analysis uses nine related Olist datasets covering customers, orders, order items, payments, products, sellers, reviews, geolocation, and product category translations.

Key dataset volumes:

- **99,441** orders
- **112,650** order items
- **99,441** customer records
- **103,886** payment records
- **32,951** products
- **3,095** sellers
- **99,224** review records
- **1,000,163** geolocation records
- **71** product category translations

Source: [Olist Brazilian E-Commerce Public Dataset – Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## Business Objectives

- Understand revenue and order trends over time.
- Identify top-performing product categories and sellers.
- Measure average order value and customer purchasing patterns.
- Segment customers by value and engagement using RFM analysis.
- Explore repeat purchasing and retention through cohort analysis.
- Evaluate delivery performance and its relationship with customer reviews.

## Tools & Technologies

- **Python:** Pandas and NumPy for data loading, cleaning, transformation, and exploratory data analysis.
- **Jupyter Notebook:** Analysis, validation, and feature engineering.
- **MySQL:** Relational data storage and SQL-based analysis.
- **SQL:** JOINs, Common Table Expressions (CTEs), aggregations, and window functions.
- **Power BI:** Interactive dashboards, data modelling, and KPI reporting using DAX.

## Project Workflow

1. **Data loading and inspection** – Imported the source datasets and reviewed their structure, data types, missing values, and duplicates.
2. **Data cleaning and preparation** – Standardised and prepared data for reliable analysis.
3. **Exploratory data analysis** – Investigated sales, orders, products, customers, sellers, and delivery patterns using Python.
4. **Database integration** – Loaded prepared datasets into the `ecommerce_analytics` MySQL database.
5. **SQL analysis** – Combined related tables and developed queries using JOINs, CTEs, aggregations, and window functions.
6. **Customer analytics** – Created RFM-based customer segments and performed cohort analysis.
7. **Power BI reporting** – Built interactive dashboards to communicate key performance indicators and trends.

## Power BI Dashboards

The report is organised into three analytical pages:

### 1. Executive Summary
Provides a high-level view of sales and order performance, including delivered sales, delivered orders, average order value, and product revenue.

### 2. Customer Analytics & RFM Segmentation
Explores customer purchasing behaviour, repeat purchases, customer value, and retention patterns through RFM and cohort analysis.

### 3. Delivery & Seller Performance
Examines seller contribution, delivery outcomes, late-delivery patterns, and customer review trends.

## Key Skills Demonstrated

- Data cleaning, preprocessing, and exploratory data analysis
- Relational data modelling and multi-table SQL analysis
- SQL JOINs, CTEs, aggregations, and window functions
- Customer segmentation using RFM analysis
- Cohort and retention analysis
- Power BI dashboard development and DAX-based KPI reporting
- Translating business questions into measurable analysis

## Author

**Saurabh Mohite**  
Data Analytics | Python | SQL | Power BI

---

*Note: KPI values and business findings should be reported from the completed SQL analysis and Power BI report. Dataset row counts above describe the source data and are not dashboard performance results.*
