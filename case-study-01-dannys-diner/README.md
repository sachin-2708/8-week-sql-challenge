# Case Study 1 – Danny’s Diner
<img width="1080" height="1080" alt="1" src="https://github.com/user-attachments/assets/aef241d7-1dc2-4162-8a48-e9d5f27c62cd" />


## Overview
This case study analyzes customer purchasing behavior and the impact of a
loyalty program using transactional sales data.

## Tables Used
- sales
- menu
- members

## Entity Relationship Diagram
<img width="900" height="437" alt="image" src="https://github.com/user-attachments/assets/d1701c73-5787-4881-9dce-2f855a234c3a" />


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
