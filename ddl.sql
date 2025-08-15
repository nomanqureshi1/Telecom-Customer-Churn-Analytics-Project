--raw layer
CREATE TABLE telco_customer_churn (
    customerID VARCHAR,
    gender VARCHAR,
    SeniorCitizen INT,
    Partner VARCHAR,
    Dependents VARCHAR,
    tenure INT,
    PhoneService VARCHAR,
    MultipleLines VARCHAR,
    InternetService VARCHAR,
    OnlineSecurity VARCHAR,
    OnlineBackup VARCHAR,
    DeviceProtection VARCHAR,
    TechSupport VARCHAR,
    StreamingTV VARCHAR,
    StreamingMovies VARCHAR,
    Contract VARCHAR,
    PaperlessBilling VARCHAR,
    PaymentMethod VARCHAR,
    MonthlyCharges FLOAT,
    TotalCharges VARCHAR,
    Churn VARCHAR
);

--silver layer

CREATE TABLE silver_telco_customer_churn (
    customerid VARCHAR(10) PRIMARY KEY,
    gender VARCHAR(10),
    seniorcitizen BOOLEAN,
    partner BOOLEAN,
    dependents VARCHAR(3),
    tenure INT,
    phoneservice BOOLEAN,
    multiplelines VARCHAR(20),
    internetservice VARCHAR(20),
    onlinesecurity VARCHAR(20),
    onlinebackup VARCHAR(20),
    deviceprotection VARCHAR(20),
    techsupport VARCHAR(20),
    streamingtv VARCHAR(20),
    streamingmovies VARCHAR(20),
    contract VARCHAR(20),
    paperlessbilling VARCHAR(3),
    paymentmethod VARCHAR(50),
    monthlycharges DOUBLE PRECISION,
    totalcharges DOUBLE PRECISION,
    churn BOOLEAN,
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN
);







--dim_customer
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_sk      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customerid       TEXT   NOT NULL UNIQUE,
    gender           TEXT,
    seniorcitizen    BOOLEAN,
    partner          BOOLEAN,
    dependents       BOOLEAN,
    -- audit
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS ix_dim_customer_customerid ON dim_customer(customerid);


--dim_service

CREATE TABLE IF NOT EXISTS dim_service (
    service_sk        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customerid        TEXT   NOT NULL UNIQUE,
    phoneservice      TEXT,
    multiplelines     TEXT,
    internetservice   TEXT,
    onlinesecurity    TEXT,
    onlinebackup      TEXT,
    deviceprotection  TEXT,
    techsupport       TEXT,
    streamingtv       TEXT,
    streamingmovies   TEXT,
    -- audit
    created_at        TIMESTAMPTZ DEFAULT NOW(),
    updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_dim_service_customerid ON dim_service(customerid);


--dim_billing
CREATE TABLE IF NOT EXISTS dim_billing (
    billing_sk        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customerid        TEXT   NOT NULL UNIQUE,
    contract          TEXT,
    paperlessbilling  TEXT,
    paymentmethod     TEXT,
    monthlycharges    DOUBLE PRECISION,
    totalcharges      DOUBLE PRECISION,
    -- audit
    created_at        TIMESTAMPTZ DEFAULT NOW(),
    updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_dim_billing_customerid ON dim_billing(customerid);


--dim_date

CREATE TABLE IF NOT EXISTS dim_date (
    date_id  INTEGER PRIMARY KEY,         -- yyyymmdd
    "date"   DATE NOT NULL UNIQUE,
    "year"   INTEGER NOT NULL,
    "month"  INTEGER NOT NULL,
    "quarter" INTEGER NOT NULL
);

-- seed a reasonable range once (adjust as you like)
INSERT INTO dim_date (date_id, "date", "year", "month", "quarter")
SELECT
    TO_CHAR(d::date, 'YYYYMMDD')::INT AS date_id,
    d::date                              AS "date",
    EXTRACT(YEAR    FROM d)::INT         AS "year",
    EXTRACT(MONTH   FROM d)::INT         AS "month",
    EXTRACT(QUARTER FROM d)::INT         AS "quarter"
FROM generate_series('2020-01-01'::date, '2030-12-31'::date, '1 day') AS g(d)
ON CONFLICT (date_id) DO NOTHING;



--Fact — DDL
CREATE TABLE IF NOT EXISTS fact_churn_events (
    fact_sk         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_sk     BIGINT NOT NULL,
    service_sk      BIGINT NOT NULL,
    billing_sk      BIGINT NOT NULL,
    date_id         INTEGER NOT NULL,
    -- measures / attributes at event level
    tenure          INTEGER,
    churn           INTEGER,             -- 0/1 from silver
    monthlycharges  DOUBLE PRECISION,
    totalcharges    DOUBLE PRECISION,
    -- audit
    inserted_at     TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_fact_customer FOREIGN KEY (customer_sk) REFERENCES dim_customer(customer_sk),
    CONSTRAINT fk_fact_service  FOREIGN KEY (service_sk)  REFERENCES dim_service(service_sk),
    CONSTRAINT fk_fact_billing  FOREIGN KEY (billing_sk)  REFERENCES dim_billing(billing_sk),
    CONSTRAINT fk_fact_date     FOREIGN KEY (date_id)     REFERENCES dim_date(date_id)
);

CREATE INDEX IF NOT EXISTS ix_fact_churn_events_date_id    ON fact_churn_events(date_id);
CREATE INDEX IF NOT EXISTS ix_fact_churn_events_customer_sk ON fact_churn_events(customer_sk);


--Incremental Upserts from silver_telco_customer_churn



