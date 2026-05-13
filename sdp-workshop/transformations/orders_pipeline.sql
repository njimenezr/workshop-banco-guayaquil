-------------------------------------------------------
-- PIPELINE DE PEDIDOS (ORDERS) — catálogo único `workshop`
-- Esquemas: sdp_bronze, sdp_silver, sdp_gold (no chocan con workshop.gold del taller Genie)
-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.sdp_bronze.orders
  COMMENT "Datos de pedidos raw ingeridos desde archivos JSON"
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

CREATE OR REFRESH STREAMING TABLE workshop.sdp_silver.orders_clean
  (
    CONSTRAINT valid_order_id EXPECT (order_id IS NOT NULL) ON VIOLATION FAIL UPDATE,
    CONSTRAINT valid_customer_id EXPECT (customer_id IS NOT NULL),
    CONSTRAINT valid_timestamp EXPECT (order_timestamp > '2020-01-01')
  )
  COMMENT "Datos de pedidos limpios con campos validados"
  TBLPROPERTIES ("quality" = "silver")
AS
SELECT
  order_id,
  timestamp(order_timestamp) AS order_timestamp,
  customer_id,
  notifications
FROM STREAM workshop.sdp_bronze.orders;

-------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW workshop.sdp_gold.order_summary
  COMMENT "Conteos diarios de pedidos agregados desde la capa silver"
  TBLPROPERTIES ("quality" = "gold")
AS
SELECT
  date(order_timestamp) AS order_date,
  count(*) AS total_daily_orders,
  count(DISTINCT customer_id) AS unique_customers
FROM workshop.sdp_silver.orders_clean
GROUP BY date(order_timestamp);
