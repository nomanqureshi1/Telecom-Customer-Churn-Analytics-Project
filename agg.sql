--Which contract type has the highest churn rate?

select b.contract , count(*) as total_cust,
sum(case when f.churn=true then 1 else 0 end) as churned_cust,
100.0 * SUM(CASE WHEN f.churn = TRUE THEN 1 ELSE 0 END) / COUNT(*) AS churn_rate_pct
from dim_billing b
join fact_churn_events f 
on b.billing_sk = f.billing_sk
group by b.contract


--2.	Does churn rate differ between customers with and without tech support?

SELECT 
    d.techsupport, 
    COUNT(*) AS churned_customers
FROM dim_service d
JOIN fact_churn_events f 
    ON d.service_sk = f.service_sk
WHERE f.churn = TRUE
GROUP BY d.techsupport;

--3.	What is the churn rate trend over the past months or quarters?
SELECT 
    dd.year,
    dd.month,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN f.churn = TRUE THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN f.churn = TRUE THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct
FROM fact_churn_events f
JOIN dim_date dd 
    ON f.date_id = dd.date_id
GROUP BY dd.year, dd.month
ORDER BY dd.year, dd.month;

--4.	Do customers with paperless billing churn more than those without?

SELECT 
    b.paperlessbilling,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN f.churn = TRUE THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN f.churn = TRUE THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_pct
FROM fact_churn_events f
JOIN dim_billing b 
    ON f.billing_sk = b.billing_sk
GROUP BY b.paperlessbilling
ORDER BY churn_rate_pct DESC;

--5.	Which internet service type generates the highest average monthly revenue from churned customers?
SELECT 
    s.internetservice,
    ROUND(AVG(f.monthlycharges), 2) AS avg_monthly_revenue_churned
FROM fact_churn_events f
JOIN dim_service s 
    ON f.service_sk = s.service_sk
WHERE f.churn = TRUE
GROUP BY s.internetservice
ORDER BY avg_monthly_revenue_churned DESC;
--6.	What is the average tenure of churned customers by contract type?

SELECT 

    b.contract,
    ROUND(AVG(f.tenure), 2) AS avg_tenure_churned
FROM fact_churn_events f
JOIN dim_billing b 
    ON f.billing_sk = b.billing_sk
WHERE f.churn = TRUE
GROUP BY b.contract
ORDER BY avg_tenure_churned DESC;