# Databricks notebook source
# MAGIC %md
# MAGIC # Setup — Lakeflow SDP (catálogo único `workshop`)
# MAGIC
# MAGIC **No crea catálogo nuevo.** Usa el catálogo compartido `workshop` y esquemas dedicados `sdp_*` para no chocar con `workshop.gold` del taller Genie.
# MAGIC
# MAGIC Crea:
# MAGIC - Esquemas `workshop.sdp_landing`, `workshop.sdp_bronze`, `workshop.sdp_silver`, `workshop.sdp_gold`
# MAGIC - Volumen `workshop.sdp_landing.raw` y carpetas `orders/`, `status/`, `customers/`
# MAGIC - JSON de ejemplo (pedidos, estatus, CDC clientes)
# MAGIC
# MAGIC **Quién ejecuta:** un usuario con `CREATE SCHEMA` y `CREATE VOLUME` sobre `workshop` (facilitador o cuenta de servicio). Los participantes no necesitan `CREATE CATALOG`.
# MAGIC
# MAGIC **Pipeline — variable `source`:** `/Volumes/workshop/sdp_landing/raw`

# COMMAND ----------

# MAGIC %md
# MAGIC ## Constantes

# COMMAND ----------

CATALOG = "workshop"
LANDING_SCHEMA = "sdp_landing"
VOLUME_NAME = "raw"
BRONZE = "sdp_bronze"
SILVER = "sdp_silver"
GOLD = "sdp_gold"

WORKING_DIR = f"/Volumes/{CATALOG}/{LANDING_SCHEMA}/{VOLUME_NAME}"

print(f"Catálogo: {CATALOG}")
print(f"Ruta fuente (variable pipeline `source`): {WORKING_DIR}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Crear esquemas y volumen (idempotente)

# COMMAND ----------

for s in (LANDING_SCHEMA, BRONZE, SILVER, GOLD):
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {CATALOG}.{s}")
    print(f"✓ Esquema {CATALOG}.{s}")

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
2. Esquema predeterminado (UI): {BRONZE}   (opcional si todo está cualificado)
3. Variable de configuración del pipeline:
     Clave: source
     Valor: {WORKING_DIR}

Tablas esperadas (tras ejecutar el pipeline):
  - {CATALOG}.{BRONZE}.orders, customers_raw, customers_clean
  - {CATALOG}.{SILVER}.orders_clean, customers
  - {CATALOG}.{GOLD}.order_summary, customer_summary

Siguiente paso: importa `sdp-workshop/transformations/*.sql` al editor multi-archivo del pipeline
y abre los notebooks en `sdp-workshop/exercises/`.
================================================================================
"""
)
