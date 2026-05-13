# Databricks notebook source
# MAGIC %md
# MAGIC # Setup — Lakeflow SDP (catálogo único `workshop`)
# MAGIC
# MAGIC **No crea catálogo nuevo.** Usa `workshop.sdp_landing` solo para **archivos** (volumen `raw`). El pipeline SDP materializa el **medallón** en **`workshop.bronze`**, **`workshop.silver`** y **`workshop.gold`** (prefijo `sdp_marketplace_*` / `fact_sdp_*` / `dim_sdp_*` — ver `transformations/*.sql`).
# MAGIC
# MAGIC Crea:
# MAGIC - Esquemas `sdp_landing`, `bronze`, `silver`, `gold` (si no existen) y volumen `raw` con carpetas `orders/`, `status/`, `customers/`
# MAGIC - JSON de ejemplo **solo si** aún no existe `workshop.gold.fact_pedidos_marketplace` (modo demo aislado)
# MAGIC
# MAGIC **Quién ejecuta:** un usuario con `CREATE SCHEMA` y `CREATE VOLUME` sobre `workshop` (facilitador o cuenta de servicio). Los participantes no necesitan `CREATE CATALOG`.
# MAGIC
# MAGIC **Pipeline — variable `source`:** `/Volumes/workshop/sdp_landing/raw`
# MAGIC
# MAGIC **Datos alineados con `gold`:** si en el workspace ya existe `workshop.gold.fact_pedidos_marketplace` (creada por `generate_workshop_data.py`), **no** se sobrescriben los JSON con el demo antiguo (`CUST0001` …). Ejecuta primero el generador del workshop para JSON con `customer_id` BGY-* coherentes con `dim_clientes`.

# COMMAND ----------

# MAGIC %md
# MAGIC ## Constantes

# COMMAND ----------

CATALOG = "workshop"
LANDING_SCHEMA = "sdp_landing"
VOLUME_NAME = "raw"
GOLD_SCHEMA = "gold"
BRONZE_SCHEMA = "bronze"
SILVER_SCHEMA = "silver"

WORKING_DIR = f"/Volumes/{CATALOG}/{LANDING_SCHEMA}/{VOLUME_NAME}"

print(f"Catálogo: {CATALOG}")
print(f"Ruta fuente (variable pipeline `source`): {WORKING_DIR}")
print(
    f"Salidas SDP (Lakeflow): {CATALOG}.bronze / {CATALOG}.silver / {CATALOG}.gold "
    "(p. ej. sdp_marketplace_pedidos_raw → sdp_marketplace_pedidos_clean → fact_sdp_marketplace_pedidos_diario)"
)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Crear esquemas y volumen (idempotente)

# COMMAND ----------

spark.sql(f"CREATE SCHEMA IF NOT EXISTS {CATALOG}.{LANDING_SCHEMA}")
print(f"✓ Esquema {CATALOG}.{LANDING_SCHEMA}")
for _s in (BRONZE_SCHEMA, SILVER_SCHEMA, GOLD_SCHEMA):
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {CATALOG}.{_s}")
    print(f"✓ Esquema {CATALOG}.{_s} (medallón Genie + SDP)")

spark.sql(f"CREATE VOLUME IF NOT EXISTS {CATALOG}.{LANDING_SCHEMA}.{VOLUME_NAME}")
print(f"✓ Volumen {CATALOG}.{LANDING_SCHEMA}.{VOLUME_NAME}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Carpetas y datos de ejemplo

# COMMAND ----------

for sub in ("orders", "status", "customers"):
    dbutils.fs.mkdirs(f"{WORKING_DIR}/{sub}")
    print(f"✓ {WORKING_DIR}/{sub}")

# COMMAND ----------

import json
import random
from datetime import datetime, timedelta

_fact_mkt = f"{CATALOG}.gold.fact_pedidos_marketplace"
if spark.catalog.tableExists(_fact_mkt):
    print(
        f"✓ Tabla {_fact_mkt} detectada — se omiten los JSON de demo aleatorios (CUST*/ORD* ficticios).\n"
        "  Los archivos en orders/status/customers deben haberlos escrito generate_workshop_data.py.\n"
        "  Si la carpeta está vacía, ejecuta **Run all** en ese notebook y vuelve aquí."
    )
else:

    def generate_orders(num_orders=174, file_name="00.json"):
        orders = []
        base_date = datetime(2024, 1, 1)
        for i in range(num_orders):
            orders.append(
                {
                    "order_id": f"ORD{i+1000:05d}",
                    "order_timestamp": (base_date + timedelta(days=random.randint(0, 30))).isoformat(),
                    "customer_id": f"CUST{random.randint(1, 100):04d}",
                    "notifications": {
                        "email": random.choice([True, False]),
                        "sms": random.choice([True, False]),
                    },
                }
            )
        path = f"{WORKING_DIR}/orders/{file_name}"
        dbutils.fs.put(path, "\n".join(json.dumps(o) for o in orders), overwrite=True)
        return len(orders)


    def generate_status_updates(num_updates=536, file_name="00.json"):
        statuses = ["placed", "preparing", "on the way", "delivered", "canceled"]
        updates = []
        base_ts = datetime(2024, 1, 1).timestamp()
        for i in range(num_updates):
            updates.append(
                {
                    "order_id": f"ORD{random.randint(1000, 1173):05d}",
                    "order_status": random.choice(statuses),
                    "status_timestamp": base_ts + (i * 3600),
                }
            )
        path = f"{WORKING_DIR}/status/{file_name}"
        dbutils.fs.put(path, "\n".join(json.dumps(u) for u in updates), overwrite=True)
        return len(updates)


    def generate_customer_cdc(file_name="00.json"):
        customers = []
        base_ts = datetime(2024, 1, 1).timestamp()
        for i in range(1, 21):
            customers.append(
                {
                    "customer_id": f"CUST{i:04d}",
                    "name": f"Customer {i}",
                    "email": f"customer{i}@example.com",
                    "address": f"{i*100} Main St",
                    "city": random.choice(["New York", "Los Angeles", "Chicago", "Houston"]),
                    "state": random.choice(["NY", "CA", "IL", "TX"]),
                    "zip_code": f"{10000 + i:05d}",
                    "operation": "INSERT",
                    "timestamp": base_ts + (i * 1000),
                }
            )
        for i in [1, 5, 10, 15, 20]:
            customers.append(
                {
                    "customer_id": f"CUST{i:04d}",
                    "name": f"Customer {i}",
                    "email": f"newemail{i}@example.com",
                    "address": f"{i*200} Oak Ave",
                    "city": "San Francisco",
                    "state": "CA",
                    "zip_code": f"{94000 + i:05d}",
                    "operation": "UPDATE",
                    "timestamp": base_ts + (30 * 1000) + (i * 100),
                }
            )
        for i in [3, 7]:
            customers.append(
                {
                    "customer_id": f"CUST{i:04d}",
                    "operation": "DELETE",
                    "timestamp": base_ts + (60 * 1000) + (i * 100),
                }
            )
        path = f"{WORKING_DIR}/customers/{file_name}"
        dbutils.fs.put(path, "\n".join(json.dumps(c) for c in customers), overwrite=True)
        return len(customers)

    n_o = generate_orders()
    n_s = generate_status_updates()
    n_c = generate_customer_cdc()
    print(f"✓ Pedidos: {n_o}, estatus: {n_s}, CDC clientes: {n_c}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Valores para Pipeline Settings

# COMMAND ----------

print(
    f"""
================================================================================
Configuración lista (catálogo único compartido)
================================================================================
1. Catálogo predeterminado del pipeline: {CATALOG}
2. Esquema predeterminado del pipeline (UI, opcional): {BRONZE_SCHEMA}
3. Variable de configuración del pipeline:
     Clave: source
     Valor: {WORKING_DIR}

Tablas esperadas (tras ejecutar el pipeline):
  - {CATALOG}.bronze.sdp_marketplace_pedidos_raw, sdp_marketplace_clientes_cdc_raw
  - {CATALOG}.silver.sdp_marketplace_pedidos_clean, sdp_marketplace_clientes_cdc_clean
  - {CATALOG}.gold.fact_sdp_marketplace_pedidos_diario, dim_sdp_marketplace_cliente, dim_sdp_marketplace_cliente_resumen

Siguiente paso: importa `sdp-workshop/transformations/*.sql` al editor multi-archivo del pipeline
y abre los notebooks en `sdp-workshop/exercises/`.
================================================================================
"""
)
