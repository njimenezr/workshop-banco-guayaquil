-------------------------------------------------------
-- PIPELINE DE CLIENTES (AUTO CDC) — esquema `workshop.gold`
-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.gold.sdp_stg_clientes_raw
  COMMENT "Bronze SDP: eventos CDC clientes marketplace (read_files)"
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

CREATE OR REFRESH STREAMING TABLE workshop.gold.sdp_stg_clientes_clean
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
  COMMENT "Silver SDP: CDC validado"
  TBLPROPERTIES ("quality" = "silver")
AS
SELECT
  *,
  CAST(from_unixtime(timestamp) AS timestamp) AS timestamp_datetime
FROM STREAM workshop.gold.sdp_stg_clientes_raw;

-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.gold.dim_cliente_digital_sdp
  COMMENT "Dimensión SDP: estado actual cliente marketplace (SCD1)";

CREATE FLOW customers_cdc_flow AS
AUTO CDC INTO workshop.gold.dim_cliente_digital_sdp
FROM STREAM workshop.gold.sdp_stg_clientes_clean
  KEYS (customer_id)
  APPLY AS DELETE WHEN operation = 'DELETE'
  SEQUENCE BY timestamp_datetime
  COLUMNS * EXCEPT (timestamp, _rescued_data, operation, processing_time, source_file)
  STORED AS SCD TYPE 1;

-------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW workshop.gold.dim_resumen_cliente_digital_sdp
  COMMENT "Vista analítica SDP derivada del perfil digital (marketplace)"
  TBLPROPERTIES ("quality" = "gold", "domain" = "marketplace", "source" = "sdp")
AS
SELECT
  customer_id,
  name,
  state,
  city,
  current_timestamp() AS last_refreshed
FROM workshop.gold.dim_cliente_digital_sdp;
