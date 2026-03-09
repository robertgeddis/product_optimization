# Product Optimization 

## 📌 Overview
A collection of queries used to analyze the performance of key feaures of a matching platform, critical site metrics and administrative functions. 

## 📊 Sample Metrics 
* **Retention & Churn:** Calculating cohort-based retention rates and identifying downgrade patterns (`retention`, `renewals_downgrades_view`).
* **Subscription Health:** Tracking `renewal_rate` and analyzing same-month subscription ends to identify friction in the user journey.
* **Onboarding Efficiency:** Measuring the `onboarding_job_completion` rate to optimize the initial user experience.
* **Operational Excellence:** Managing `refund_dashboard` logic and `performance_scorecard` metrics to ensure a high-quality user/provider ecosystem.

## 💼 Business Impact
In my previous role, these queries were instrumental in:
* **Budgeting:** Segmenting spend by country, marketing channel, user role and vertical.  
* **CPA Analysis:** Consolidating data from APIs with manual csv files along with internal conversion data to calculate Cost Per Acquisition.
* **Optimization:** Identifying underperforming channels where spend did not correlate with high-quality user acquisition.

## 🛠 Technical Features (SQL)
To ensure data accuracy and performance, these scripts utilize:
* **Common Table Expressions (CTEs):** For modular, readable code that separates data cleaning from final aggregation.
* **Window Functions:** (e.g., `SUM() OVER(...)`) to calculate cumulative spend and running totals across time periods.
* **Complex Joins:** Bridging disparate data sources such as manual spend files with transactional databases.
* **Data Normalization:** Handling currency conversions and aligning spend to user and vertical matrix for reporting.
