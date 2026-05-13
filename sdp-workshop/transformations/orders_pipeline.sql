-------------------------------------------------------
-- PIPELINE DE PEDIDOS (ORDERS) — todo en esquema `workshop.gold`
-- Staging SDP + hecho agregado; no pisa dim_* / fact_* del núcleo bancario.
-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.gold.sdp_stg_pedidos_raw
  COMMENT "Bronze SDP: pedidos JSON desde landing (read_files)"
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
  '${source}/orders',
  format => 'json'
);

-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.gold.sdp_stg_pedidos_clean
  (
    CONSTRAINT valid_order_id EXPECT (order_id IS NOT NULL) ON VIOLATION FAIL UPDATE,
    CONSTRAINT valid_customer_id EXPECT (customer_id IS NOT NULL),
    CONSTRAINT valid_timestamp EXPECT (order_timestamp > '2020-01-01')
  )
  COMMENT "Silver SDP: pedidos validados"
  TBLPROPERTIES ("quality" = "silver")
AS
SELECT
  order_id,
  timestamp(order_timestamp) AS order_timestamp,
  customer_id,
  notifications
FROM STREAM workshop.gold.sdp_stg_pedidos_raw;

-------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW workshop.gold.fact_pedidos_agregado_diario_sdp
  COMMENT "Gold SDP: agregado diario de pedidos marketplace (camino declarativo)"
  TBLPROPERTIES ("quality" = "gold", "domain" = "marketplace", "source" = "sdp")
AS
SELECT
  date(order_timestamp) AS order_date,
  count(*) AS total_daily_orders,
  count(DISTINCT customer_id) AS unique_customers
FROM workshop.gold.sdp_stg_pedidos_clean
GROUP BY date(order_timestamp);
