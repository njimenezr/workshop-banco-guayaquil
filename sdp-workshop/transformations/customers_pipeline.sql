-------------------------------------------------------
-- PIPELINE CDC CLIENTES MARKETPLACE (Lakeflow) — bronze / silver / gold
-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.bronze.marketplace_clientes_cdc_raw
  COMMENT "Bronze: eventos CDC JSON desde volumen (read_files)"
  TBLPROPERTIES (
    "quality" = "bronze",
    "pipelines.reset.allowed" = false,
    "etl_path" = "lakeflow"
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

CREATE OR REFRESH STREAMING TABLE workshop.silver.marketplace_clientes_cdc_clean
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
  COMMENT "Silver: CDC validado (Lakeflow)"
  TBLPROPERTIES ("quality" = "silver", "etl_path" = "lakeflow")
AS
SELECT
  *,
  CAST(from_unixtime(timestamp) AS timestamp) AS timestamp_datetime
FROM STREAM workshop.bronze.marketplace_clientes_cdc_raw;

-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.gold.dim_marketplace_cliente
  COMMENT "Gold: dimensión cliente digital marketplace SCD1 (Lakeflow)";

CREATE FLOW customers_cdc_flow AS
AUTO CDC INTO workshop.gold.dim_marketplace_cliente
FROM STREAM workshop.silver.marketplace_clientes_cdc_clean
  KEYS (customer_id)
  APPLY AS DELETE WHEN operation = 'DELETE'
  SEQUENCE BY timestamp_datetime
  COLUMNS * EXCEPT (timestamp, _rescued_data, operation, processing_time, source_file)
  STORED AS SCD TYPE 1;

-------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW workshop.gold.dim_marketplace_cliente_resumen
  COMMENT "Gold: vista resumen perfil cliente marketplace (Lakeflow)"
  TBLPROPERTIES ("quality" = "gold", "domain" = "marketplace", "etl_path" = "lakeflow")
AS
SELECT
  customer_id,
  name,
  state,
  city,
  current_timestamp() AS last_refreshed
FROM workshop.gold.dim_marketplace_cliente;
