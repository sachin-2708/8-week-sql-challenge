# 8 Week SQL Challenge – Case Study 2: Pizza Runner 🍕

## Overview
This case study is part of the **8 Week SQL Challenge by Danny Ma** and focuses on analyzing operational and customer order data for a pizza delivery business called **Pizza Runner**.

The objective is to clean messy raw data and answer business-driven questions related to:
- Customer ordering behaviour
- Runner delivery performance
- Pizza customisations (extras & exclusions)
- Time-based order trends

---

## Dataset Description
The original dataset contains multiple data quality issues such as:
- Text-based time values
- Nulls represented as strings
- Inconsistent formats for exclusions and extras
- Cancelled and undelivered orders mixed with completed ones

To address this, **cleaned views** were created and used for all analysis.

### Cleaned Tables / Views
- `vw_customer_orders_clean`
- `vw_runner_orders_clean`

These views standardize:
- Dates & timestamps
- NULL handling
- Extras and exclusions formatting
- Delivery status

---

## Key Business Questions Answered
Some of the core questions answered in this case study include:

- How many pizzas were ordered and delivered?
- How many unique customer orders were placed?
- How many successful deliveries were completed by each runner?
- How many pizzas were delivered with:
  - At least one change (extras or exclusions)
  - No changes
  - Both exclusions and extras
- Pizza preferences by customer
- Hourly and daily order volume trends

---

## Key Learnings
This case study reinforced several important SQL and analytics concepts:

- Difference between **orders vs pizzas**
- Handling **zero values using LEFT JOINs**
- Identifying **delivered vs cancelled** orders
- Row-level classification using **AND / OR logic**
- Time-based analysis using **date and time functions**
- Importance of validating assumptions with data

---

## Folder Structure
