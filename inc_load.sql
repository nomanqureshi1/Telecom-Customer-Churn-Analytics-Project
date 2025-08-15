---- Incremental Upserts from silver_telco_customer_churn (no transformations)

INSERT INTO dim_customer (
    customerid, gender, seniorcitizen, partner, dependents, updated_at
)
SELECT DISTINCT
    s.customerid,
    s.gender,
    s.seniorcitizen,
    s.partner,
    s.dependents,
    NOW()
FROM silver_telco_customer_churn s
ON CONFLICT (customerid) DO UPDATE SET
    gender        = EXCLUDED.gender,
    seniorcitizen = EXCLUDED.seniorcitizen,
    partner       = EXCLUDED.partner,
    dependents    = EXCLUDED.dependents,
    updated_at    = NOW();


---- dim_service

insert into dim_service(
    customerid, phoneservice, multiplelines, internetservice, onlinesecurity, onlinebackup, deviceprotection, techsupport, streamingtv, streamingmovies, updated_at
)
select DISTINCT
    s.customerid,
    s.phoneservice,
    s.multiplelines,
    s.internetservice,
    s.onlinesecurity,
    s.onlinebackup,
    s.deviceprotection,
    s.techsupport,
    s.streamingtv,
    s.streamingmovies,
    NOW()
from silver_telco_customer_churn s
on conflict (customerid) do update set
    phoneservice      = EXCLUDED.phoneservice,
    multiplelines     = EXCLUDED.multiplelines,
    internetservice   = EXCLUDED.internetservice,
    onlinesecurity    = EXCLUDED.onlinesecurity,
    onlinebackup      = EXCLUDED.onlinebackup,
    deviceprotection  = EXCLUDED.deviceprotection,
    techsupport       = EXCLUDED.techsupport,
    streamingtv       = EXCLUDED.streamingtv,
    streamingmovies   = EXCLUDED.streamingmovies,
    updated_at        = NOW();


insert into dim_billing(
    customerid, contract, paperlessbilling, paymentmethod, monthlycharges, totalcharges, updated_at 
)
select DISTINCT
    s.customerid,
    s.contract,
    s.paperlessbilling,
    s.paymentmethod,
    s.monthlycharges,
    s.totalcharges,
    NOW()
from silver_telco_customer_churn s
on conflict (customerid) do update set
    contract          = EXCLUDED.contract,
    paperlessbilling  = EXCLUDED.paperlessbilling,
    paymentmethod     = EXCLUDED.paymentmethod,
    monthlycharges    = EXCLUDED.monthlycharges,
    totalcharges      = EXCLUDED.totalcharges,
    updated_at        = EXCLUDED.updated_at;        




    -- Incremental load into fact_churn_events


CREATE UNIQUE INDEX IF NOT EXISTS uq_fact_churn_daily
ON fact_churn_events (customer_sk, date_id);




WITH run_date AS (
  SELECT TO_CHAR(CURRENT_DATE, 'YYYYMMDD')::INT AS date_id
),
lkp AS (
  SELECT
      c.customer_sk,
      sv.service_sk,
      b.billing_sk,
      c.customerid
  FROM dim_customer c
  JOIN dim_service  sv ON sv.customerid = c.customerid
  JOIN dim_billing  b  ON b.customerid  = c.customerid
)
INSERT INTO fact_churn_events (
    customer_sk, service_sk, billing_sk, date_id,
    tenure, churn, monthlycharges, totalcharges
)
SELECT
    l.customer_sk,
    l.service_sk,
    l.billing_sk,
    r.date_id,
    s.tenure,
    s.churn,
    s.monthlycharges,
    s.totalcharges
FROM silver_telco_customer_churn s
JOIN lkp l        ON l.customerid = s.customerid
CROSS JOIN run_date r
ON CONFLICT (customer_sk, date_id) DO NOTHING;  -- prevents duplicate daily inserts



