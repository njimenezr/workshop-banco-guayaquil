-------------------------------------------------------
-- PIPELINE PEDIDOS MARKETPLACE (SDP) — medallón en bronze / silver / gold
-- Misma convención que el camino Genie: capas por esquema, no staging en gold.
-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.bronze.sdp_marketplace_pedidos_raw
  COMMENT "Bronze: pedidos JSON desde volumen (read_files)"
  TBLPROPERTIES (
    "quality" = "bronze",
    "pipelines.reset.allowed" = false,
    "etl_path" = "sdp"
  )
AS
SELECT
  *,
  current_timestamp() AS processing_time,
  _metadata.file_name AS source_file
FROM STREAM read_files(
  '${source}/orders',
  format => 'json'
);

-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.silver.sdp_marketplace_pedidos_clean
  (
    CONSTRAINT valid_order_id EXPECT (order_id IS NOT NULL) ON VIOLATION FAIL UPDATE,
    CONSTRAINT valid_customer_id EXPECT (customer_id IS NOT NULL),
    CONSTRAINT valid_timestamp EXPECT (order_timestamp > '2020-01-01')
  )
  COMMENT "Silver: pedidos validados (SDP)"
  TBLPROPERTIES ("quality" = "silver", "etl_path" = "sdp")
AS
SELECT
  order_id,
  timestamp(order_timestamp) AS order_timestamp,
  customer_id,
  notifications
FROM STREAM workshop.bronze.sdp_marketplace_pedidos_raw;

-------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW workshop.gold.fact_sdp_marketplace_pedidos_diario
  COMMENT "Gold: agregado diario pedidos marketplace (ETL declarativo SDP)"
  TBLPROPERTIES ("quality" = "gold", "domain" = "marketplace", "etl_path" = "sdp")
AS
SELECT
  date(order_timestamp) AS order_date,
  count(*) AS total_daily_orders,
  count(DISTINCT customer_id) AS unique_customers
FROM workshop.silver.sdp_marketplace_pedidos_clean
GROUP BY date(order_timestamp);
