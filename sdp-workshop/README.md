# Módulo Lakeflow SDP (catálogo único `workshop`)

Todo el material del taller **Spark Declarative Pipelines** vive en esta carpeta del mismo repositorio que el workshop Banco Guayaquil / Genie Code.

**Cómo encaja con Genie Code:** el track *Data Engineering* usa un **CSV** desde `fact_transacciones` y escribe el gold del camino Genie en **`workshop.gold.fact_transacciones_mensual_genie`**. El SDP ingiere **solo JSON** desde `/Volumes/workshop/sdp_landing/raw` (mismos `order_id` / `customer_id` que `fact_pedidos_marketplace`) y materializa en el **mismo esquema `workshop.gold`** tablas `sdp_stg_*`, **`fact_pedidos_agregado_diario_sdp`** y **`dim_cliente_digital_sdp`**. Puedes ejecutar **solo Genie** (sin pipeline), **solo SDP** (sin rellenar la fact Genie), o **ambos** y cruzar todo con SQL en `gold`.

Diseño basado en el taller original [dbx-Workshop-Declarative-Pipelines](https://github.com/njimenezr/dbx-Workshop-Declarative-Pipelines), adaptado para **un solo catálogo Unity** (`workshop`) y permisos típicos de clientes corporativos.

## Por qué un solo catálogo y un esquema analítico `gold`

- Muchos usuarios **no tienen** `CREATE CATALOG`.
- El catálogo `workshop` puede ser **creado una vez** por el administrador de la cuenta o landing zone.
- **`workshop.gold`** concentra:
  - **Núcleo** del taller Genie: `dim_*` / `fact_*` bancarios.
  - **Semilla marketplace** (común a ambos caminos): `dim_categoria_pedido_digital`, `fact_pedidos_marketplace`.
  - **Plantilla camino Genie:** `fact_transacciones_mensual_genie` (0 filas hasta el paso 2 del track DE).
  - **Camino SDP** (aparecen al ejecutar el pipeline): `sdp_stg_pedidos_raw`, `sdp_stg_pedidos_clean`, `fact_pedidos_agregado_diario_sdp`, `sdp_stg_clientes_raw`, `sdp_stg_clientes_clean`, `dim_cliente_digital_sdp`, `dim_resumen_cliente_digital_sdp`.
- **`workshop.sdp_landing`** solo aloja el **volumen** `raw` y los JSON (no es la capa medallón declarativa).

| Esquema | Uso |
|---------|-----|
| `workshop.sdp_landing` | Volumen `raw` + archivos JSON fuente del pipeline |
| `workshop.gold` | Todo lo anterior (núcleo + extensiones Genie y SDP) |

## Orden de trabajo (participante)

1. El facilitador ejecutó **`generate_workshop_data.py`** (tablas `gold`, CSV core, esquema `sdp_landing`, volumen y JSON) y, si aplica, **`notebooks/00_SETUP_workshop_single_catalog.py`**. Aplique **`sql/GRANTS_single_catalog.sql`** al grupo de asistentes.
2. Sube esta carpeta `sdp-workshop/` al Workspace manteniendo rutas relativas (`transformations/`, `exercises/`).
3. Crea un **Lakeflow Spark Declarative Pipeline** (editor multi-archivo) apuntando a `transformations/orders_pipeline.sql` (y luego añade `customers_pipeline.sql` en el ejercicio 2).
4. En **Pipeline settings → Configuration** define la clave **`source`** con el valor impreso por el setup, normalmente  
   `/Volumes/workshop/sdp_landing/raw`
5. Sigue los notebooks en **`exercises/`** en orden.

## Archivos

| Ruta | Descripción |
|------|-------------|
| `notebooks/00_SETUP_workshop_single_catalog.py` | Setup idempotente (sin `DROP CATALOG`) |
| `transformations/orders_pipeline.sql` | Pipeline pedidos (medallión + expectativas) |
| `transformations/customers_pipeline.sql` | CDC clientes (mover aquí en ej. 2 si el taller lo pide) |
| `exercises/01_Building_Pipeline_Data_Quality.sql` | Instrucciones ejercicio 1 |
| `exercises/02_CDC_and_Production.py` | Instrucciones ejercicio 2 |
| `utilities/utils.py` | Helpers (igual que upstream) |
| `sql/GRANTS_single_catalog.sql` | Plantilla de permisos para el grupo |

## Varios usuarios en el mismo `workshop`

| Enfoque | Cuándo usarlo | Riesgo |
|---------|----------------|--------|
| **Tablas compartidas** (este repo) | Demo / taller guiado; todos leen el mismo volumen y el mismo pipeline escribe tablas `*_sdp` en `workshop.gold` | Si dos personas ejecutan **Full refresh** a la vez o regeneran datos en el volumen, pueden pisarse resultados. Coordinar turnos o un solo pipeline de demostración. |
| **Un pipeline por equipo** | Equipos con permiso `CREATE PIPELINE` y mismo catálogo | Misma tabla destino en `gold`: conflicto. Mejor **un pipeline compartido** de demo + ejercicios en lectura. |
| **Prefijo por equipo** (avanzado) | Cliente exige aislamiento sin nuevos catálogos | Duplicar nombres de tabla vía parámetro en las SQL del pipeline; más mantenimiento. |
| **Ramificación / entorno dev** | Producción real | Usar catálogos `workshop_dev` / `workshop_prod` solo si el negocio los aprueba (sigue siendo “pocos catálogos”, no uno por persona). |

**Recomendación práctica para salas de taller:** un grupo `workshop_sdp_participants` con `SELECT` (y según política `MODIFY`) sobre **`workshop.gold`** y `READ`/`WRITE` **FILES** sobre el volumen `sdp_landing.raw`. El facilitador suele ser dueño del pipeline de referencia.

## Permisos mínimos (resumen)

- Participante: `USE CATALOG workshop`, `USAGE` + `SELECT` en `workshop.gold`, `USAGE` + `READ FILES` (y si aplica `WRITE FILES`) sobre `sdp_landing.raw`.
- Facilitador: además `CREATE SCHEMA`, `CREATE VOLUME`, permisos para crear/actualizar el pipeline y tablas en `gold`.

## Troubleshooting rápido

- **`Variable source not found`:** añade `source` = `/Volumes/workshop/sdp_landing/raw` en la configuración del pipeline.
- **`Permission denied` en volumen:** revisa `GRANT READ FILES` / `USAGE` sobre el volumen UC.
- **Convivencia en `gold`:** el pipeline solo crea/actualiza tablas con prefijos `sdp_stg_`, sufijos `_sdp` o nombres explícitos en las SQL del repo; no altera `dim_clientes` ni `fact_transacciones` del núcleo.
