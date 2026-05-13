-------------------------------------------------------
-- PIPELINE DE CLIENTES (AUTO CDC) — catálogo único `workshop`
-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.sdp_bronze.customers_raw
  COMMENT "Eventos CDC raw para datos de clientes"
  TBLPROPERTIES (
    "quality" = "bronze",
    "pipelines.reset.allowed" = false
  )
AS
SELECT
  *,
  current_timestamp() AS processing_time,
  _metadata.file_name AS source_file
FROM STREAM read_files(
  '${source}/customers',
  format => 'json'
);

-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.sdp_bronze.customers_clean
  (
    CONSTRAINT valid_id EXPECT (customer_id IS NOT NULL) ON VIOLATION FAIL UPDATE,
    CONSTRAINT valid_operation EXPECT (operation IS NOT NULL) ON VIOLATION DROP ROW,
    CONSTRAINT valid_name EXPECT (name IS NOT NULL OR operation = 'DELETE'),
    CONSTRAINT valid_address EXPECT (
      (address IS NOT NULL AND city IS NOT NULL AND state IS NOT NULL AND zip_code IS NOT NULL) OR
      operation = 'DELETE'
    ),
    CONSTRAINT valid_email EXPECT (
      rlike(email, '^([a-zA-Z0-9_\\-\\.]+)@([a-zA-Z0-9_\\-\\.]+)\\.([a-zA-Z]{2,5})$') OR
      operation = 'DELETE'
    ) ON VIOLATION DROP ROW
  )
  COMMENT "Eventos CDC validados listos para procesamiento"
  TBLPROPERTIES ("quality" = "bronze")
AS
SELECT
  *,
  CAST(from_unixtime(timestamp) AS timestamp) AS timestamp_datetime
FROM STREAM workshop.sdp_bronze.customers_raw;

-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.sdp_silver.customers
  COMMENT "Estado actual de clientes (SCD Tipo 1)";

CREATE FLOW customers_cdc_flow AS
AUTO CDC INTO workshop.sdp_silver.customers
FROM STREAM workshop.sdp_bronze.customers_clean
  KEYS (customer_id)
  APPLY AS DELETE WHEN operation = 'DELETE'
  SEQUENCE BY timestamp_datetime
  COLUMNS * EXCEPT (timestamp, _rescued_data, operation, processing_time, source_file)
  STORED AS SCD TYPE 1;

-------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW workshop.sdp_gold.customer_summary
  COMMENT "Resumen de clientes con métricas derivadas"
  TBLPROPERTIES ("quality" = "gold")
AS
SELECT
  customer_id,
  name,
  state,
  city,
  current_timestamp() AS last_refreshed
FROM workshop.sdp_silver.customers;
