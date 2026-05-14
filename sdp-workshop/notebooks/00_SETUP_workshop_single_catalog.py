# Databricks notebook source
# MAGIC %md
# MAGIC # Setup SDP — **deprecado** (consolidado en `generate_workshop_data.py`)
# MAGIC
# MAGIC Toda la preparación del taller (**esquemas** `ingest`, `bronze`, `silver`, `gold`, **volumen** `ingest.raw`, carpetas `orders/`, `status/`, `customers/`, `transacciones_core/`, **JSON** marketplace y **CSV** Genie) quedó en el notebook **`generate_workshop_data.py`** de la raíz del repositorio.
# MAGIC
# MAGIC **Qué hacer:** importa `generate_workshop_data.py` al workspace y ejecuta **Run all**. Luego aplica `sdp-workshop/sql/GRANTS_single_catalog.sql` y sigue los pasos del track **Lakeflow SDP** en la app o los notebooks en **`exercises/lakeflow-sdp/`**.
# MAGIC
# MAGIC SQL del pipeline: `sdp-workshop/transformations/orders_pipeline.sql` y `customers_pipeline.sql`.

# COMMAND ----------

print(
    "Este notebook ya no ejecuta setup. Usa generate_workshop_data.py (Run all). "
    "Variable pipeline: source = /Volumes/workshop/ingest/raw"
)
