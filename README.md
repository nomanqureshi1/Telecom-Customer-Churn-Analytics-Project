# Telecom-Customer-Churn-Analytics-Project


Telecom Customer Churn Analytics Project
Tools: Spark · PostgreSQL
1. Raw Data Ingestion
•	Dataset: IBM Telco Customer Churn
•	Source File: WA_Fn-UseC_-Telco-Customer-Churn.csv
•	Initial Load: Data ingested into PostgreSQL as telco_customer_churn (raw layer).
 
2. Silver Layer (Cleaned & Standardized Data)
Source table: silver_telco_customer_churn
Goal: Prepare clean, consistent, and analytics-ready data for modeling.
Steps Performed:
•	Removed invalid or malformed rows (e.g., blank TotalCharges).
•	Dropped duplicate records based on customerid.
•	Converted numeric fields (TotalCharges, MonthlyCharges) to FLOAT.
•	Cast SeniorCitizen to BOOLEAN.
•	Standardized Churn to boolean (Yes → TRUE, No → FALSE).
•	Trimmed whitespace from string fields.
•	Handled missing values via null replacement or filtering.
•	Slowly Changing Dimensions (SCD) Handling:
o	Identified SCD attributes (e.g., Contract, PaymentMethod).
o	Introduced surrogate keys using snapshots.
o	Added is_current, effective_from, effective_to metadata.
o	Preserved full change history.
Output: Clean, enriched table feeding into dimensions and fact tables.
 
3. Dimensional Modeling (Star Schema with Date Dimension)
Fact Table
fact_churn_events
Columns:
•	customerid
•	contract
•	internetservice
•	monthlycharges
•	totalcharges
•	tenure
•	churn
•	date_id
Dimensions
•	dim_customer
o	customerid (PK), gender, seniorcitizen, partner, dependents
•	dim_service
o	customerid (FK), phoneservice, multiplelines, internetservice, onlinesecurity, onlinebackup, deviceprotection, techsupport, streamingtv, streamingmovies
•	dim_billing
o	customerid (FK), contract, paperlessbilling, paymentmethod, monthlycharges, totalcharges
•	dim_date
o	date_id (PK), date, year, month, quarter
 
4. Business Questions Answered
From this star schema, we can answer key business questions:
1.	Which contract type has the highest churn rate?
2.	Does churn rate differ between customers with and without tech support?
3.	What is the churn rate trend over the past months or quarters?
4.	Do customers with paperless billing churn more than those without?
5.	Which internet service type generates the highest average monthly revenue from churned customers?
6.	What is the average tenure of churned customers by contract type?

<img width="451" height="685" alt="image" src="https://github.com/user-attachments/assets/5407153b-c2b6-4793-9b1c-e2c5eefd3f9e" />
