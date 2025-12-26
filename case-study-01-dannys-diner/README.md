# Case Study 1 – Danny’s Diner

## Overview
This case study analyzes customer purchasing behavior and the impact of a
loyalty program using transactional sales data.

## Tables Used
- sales
- menu
- members

## Key Concepts Practiced
- Customer-level aggregation
- Window functions for ranking
- Membership-based logic
- Points calculation with conditional rules

## Bonus Work
Beyond answering the questions, I designed a reusable SQL view to model:
- Member vs non-member purchases
- Correct ranking reset after membership
- NULL rankings for non-member transactions

## Edge Cases Considered
- Multiple purchases on the same date
- Window function evaluation order
- Ranking reset logic
- Membership boundary conditions
- MySQL limitation: CTEs not allowed in views

## Files
- schema.sql – table creation & inserts
- solutions.sql – core questions
- bonus.sql – bonus questions
- views.sql – reusable analytics view
