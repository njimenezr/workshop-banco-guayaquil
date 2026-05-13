# Módulo Lakeflow SDP (catálogo único `workshop`)

Todo el material del taller **Spark Declarative Pipelines** vive en esta carpeta del mismo repositorio que el workshop Banco Guayaquil / Genie Code.

**Cómo encaja con Genie Code:** son **dos estilos de ETL** sobre el mismo catálogo y el **mismo medallón lógico** (`bronze` → `silver` → `gold`):

| Camino | Fuentes (archivos) | Donde materializa |
|--------|--------------------|-------------------|
| **Genie (Data Engineering)** | CSV `/Volumes/workshop/default/raw/transacciones_nuevas.csv` | `workshop.bronze.transacciones_raw`, `workshop.silver.transacciones_clean`, `workshop.gold.fact_transacciones_mensual_genie` (código generado por el participante) |
| **SDP (declarativo)** | JSON `/Volumes/workshop/sdp_landing/raw/` | `workshop.bronze.sdp_marketplace_pedidos_raw`, `workshop.silver.sdp_marketplace_pedidos_clean`, `workshop.gold.fact_sdp_marketplace_pedidos_diario`, y análogo para CDC clientes (`sdp_marketplace_clientes_cdc_*` → `dim_sdp_marketplace_cliente`) |

El generador (`generate_workshop_data.py`) crea el **núcleo** en `gold`, la **semilla** marketplace, el CSV, los JSON del landing y la **plantilla vacía** `fact_transacciones_mensual_genie`. El pipeline SDP **no** lee tablas `gold` del core; solo `read_files` sobre el volumen.

Diseño basado en el taller original [dbx-Workshop-Declarative-Pipelines](https://github.com/njimenezr/dbx-Workshop-Declarative-Pipelines), adaptado para **un solo catálogo Unity** (`workshop`) y permisos típicos de clientes corporativos.

## Esquemas

| Esquema | Uso |
|---------|-----|
| `workshop.sdp_landing` | Volumen `raw` + archivos JSON (única “fuente archivo” del SDP) |
| `workshop.bronze` | Raw Genie + raw SDP (`sdp_marketplace_*`) |
| `workshop.silver` | Limpieza Genie + limpieza SDP |
| `workshop.gold` | Núcleo del taller, semillas marketplace, plantilla Genie, hechos/dims **gold** del SDP |

## Orden de trabajo (participante)

1. El facilitador ejecutó **`generate_workshop_data.py`** y, si aplica, **`notebooks/00_SETUP_workshop_single_catalog.py`**. Aplique **`sql/GRANTS_single_catalog.sql`** al grupo de asistentes.
2. Sube esta carpeta `sdp-workshop/` al Workspace manteniendo rutas relativas (`transformations/`, `exercises/`).
3. Crea un **Lakeflow Spark Declarative Pipeline** apuntando a `transformations/orders_pipeline.sql` (y añade `customers_pipeline.sql` en el ejercicio 2).
4. En **Pipeline settings → Configuration** define **`source`** = `/Volumes/workshop/sdp_landing/raw`
5. Sigue los notebooks en **`exercises/`** en orden.

## Archivos

| Ruta | Descripción |
|------|-------------|
| `notebooks/00_SETUP_workshop_single_catalog.py` | Setup idempotente (sin `DROP CATALOG`) |
| `transformations/orders_pipeline.sql` | Pedidos: bronze → silver → gold |
| `transformations/customers_pipeline.sql` | CDC clientes: bronze → silver → gold |
| `exercises/01_Building_Pipeline_Data_Quality.sql` | Instrucciones ejercicio 1 |
| `exercises/02_CDC_and_Production.py` | Instrucciones ejercicio 2 |
| `utilities/utils.py` | Helpers (igual que upstream) |
| `sql/GRANTS_single_catalog.sql` | Plantilla de permisos para el grupo |

## Varios usuarios en el mismo `workshop`

| Enfoque | Cuándo usarlo | Riesgo |
|---------|----------------|--------|
| **Tablas compartidas** | Demo guiada; un pipeline de referencia | Full refresh simultáneo o escritura en el mismo volumen |
| **Un pipeline por equipo** | Si la cuenta lo permite | Mismos nombres de tabla → conflictos; coordinar o prefijos por equipo |

**Recomendación:** un grupo con `SELECT` sobre `bronze`/`silver`/`gold` y `READ FILES` sobre `sdp_landing.raw`; el facilitador dueño del pipeline.

## Permisos mínimos (resumen)

- Participante: `USE CATALOG workshop`, `USAGE` + `SELECT` en `bronze`, `silver`, `gold`, `READ FILES` (y si aplica `WRITE FILES`) en `sdp_landing.raw`.
- Facilitador: además `CREATE SCHEMA`, `CREATE VOLUME`, permisos de pipeline.

## Troubleshooting rápido

- **`Variable source not found`:** `source` = `/Volumes/workshop/sdp_landing/raw`
- **`Permission denied` en volumen:** `GRANT READ FILES` / `USAGE` sobre el volumen UC
- **Convivencia:** tablas SDP usan prefijos `sdp_marketplace_*`, `fact_sdp_*`, `dim_sdp_*`; no sustituyen `dim_clientes` ni `fact_transacciones`.
