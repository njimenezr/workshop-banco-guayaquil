-------------------------------------------------------
-- PIPELINE PEDIDOS MARKETPLACE (Lakeflow) — bronze / silver / gold
-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.bronze.marketplace_pedidos_raw
  COMMENT "Bronze: pedidos JSON desde volumen (read_files)"
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
  '${source}/orders',
  format => 'json'
);

-------------------------------------------------------

CREATE OR REFRESH STREAMING TABLE workshop.silver.marketplace_pedidos_clean
  (
    CONSTRAINT valid_order_id EXPECT (order_id IS NOT NULL) ON VIOLATION FAIL UPDATE,
    CONSTRAINT valid_customer_id EXPECT (customer_id IS NOT NULL),
    CONSTRAINT valid_timestamp EXPECT (order_timestamp > '2020-01-01')
  )
  COMMENT "Silver: pedidos validados (Lakeflow)"
  TBLPROPERTIES ("quality" = "silver", "etl_path" = "lakeflow")
AS
SELECT
  order_id,
  timestamp(order_timestamp) AS order_timestamp,
  customer_id,
  notifications
FROM STREAM workshop.bronze.marketplace_pedidos_raw;

-------------------------------------------------------

CREATE OR REFRESH MATERIALIZED VIEW workshop.gold.fact_marketplace_pedidos_diario
  COMMENT "Gold: agregado diario pedidos marketplace (Lakeflow declarativo)"
  TBLPROPERTIES ("quality" = "gold", "domain" = "marketplace", "etl_path" = "lakeflow")
AS
SELECT
  date(order_timestamp) AS order_date,
  count(*) AS total_daily_orders,
  count(DISTINCT customer_id) AS unique_customers
FROM workshop.silver.marketplace_pedidos_clean
GROUP BY date(order_timestamp);
