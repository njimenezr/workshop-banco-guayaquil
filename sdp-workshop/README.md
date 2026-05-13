# Módulo Lakeflow SDP (catálogo único `workshop`)

Todo el material del taller **Spark Declarative Pipelines** vive en esta carpeta del mismo repositorio que el workshop Banco Guayaquil / Genie Code.

**Cómo encaja con Genie Code:** el track *Data Engineering* usa un **CSV** exportado desde `workshop.gold.fact_transacciones` (ruta `/Volumes/workshop/default/raw/transacciones_nuevas.csv`) para prototipar medallión en PySpark con Genie. Este módulo SDP usa **JSON** de pedidos/clientes en `/Volumes/workshop/sdp_landing/raw` — mismo catálogo, **dos historias de ingesta** (archivo plano “core” vs. Lakeflow declarativo).

Diseño basado en el taller original [dbx-Workshop-Declarative-Pipelines](https://github.com/njimenezr/dbx-Workshop-Declarative-Pipelines), adaptado para **un solo catálogo Unity** (`workshop`) y permisos típicos de clientes corporativos.

## Por qué un solo catálogo

- Muchos usuarios **no tienen** `CREATE CATALOG`.
- El catálogo `workshop` puede ser **creado una vez** por el administrador de la cuenta o landing zone.
- Los datos del taller Genie siguen en **`workshop.gold`** (tablas `dim_*`, `fact_*`).
- El taller SDP usa **otros esquemas** en el mismo catálogo para no pisar `gold`:

| Esquema | Uso |
|---------|-----|
| `workshop.sdp_landing` | Volumen `raw` y archivos JSON fuente |
| `workshop.sdp_bronze` | Tablas streaming bronze del pipeline |
| `workshop.sdp_silver` | Silver + tabla `customers` (SCD1) |
| `workshop.sdp_gold` | Vistas materializadas gold |

## Orden de trabajo (participante)

1. El facilitador (o cuenta de servicio) ejecutó **`notebooks/00_SETUP_workshop_single_catalog.py`** y aplicó **`sql/GRANTS_single_catalog.sql`** al grupo de asistentes.
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
| **Tablas compartidas** (este repo) | Demo / taller guiado; todos leen el mismo volumen y el mismo pipeline escribe en `workshop.sdp_*` | Si dos personas ejecutan **Full refresh** a la vez o regeneran datos en el volumen, pueden pisarse resultados. Coordinar turnos o un solo pipeline de demostración. |
| **Un pipeline por equipo** | Equipos con permiso `CREATE PIPELINE` y mismo catálogo | Misma tabla destino: seguirías con conflicto. Mejor **un pipeline compartido** de demo + ejercicios en lectura. |
| **Prefijo por equipo** (avanzado) | Cliente exige aislamiento sin nuevos catálogos | Duplicar esquemas `sdp_bronze_teamA` vía parámetro y plantillas SQL; más mantenimiento. |
| **Ramificación / entorno dev** | Producción real | Usar catálogos `workshop_dev` / `workshop_prod` solo si el negocio los aprueba (sigue siendo “pocos catálogos”, no uno por persona). |

**Recomendación práctica para salas de taller:** un grupo `workshop_sdp_participants` con `SELECT` sobre `workshop.gold` (Genie) y `USAGE` + `SELECT` + `MODIFY` sobre los esquemas `sdp_*` **solo** si todos comparten el mismo laboratorio; el facilitador ejecuta el pipeline de referencia y los alumnos observan / repiten en **workspace de práctica** propio si la cuenta lo permite.

## Permisos mínimos (resumen)

- Participante: `USE CATALOG workshop`, `USAGE` + `SELECT` (y si aplica `READ FILES`) sobre el volumen `sdp_landing.raw`, `SELECT`/`MODIFY` en `sdp_*` según política (ver SQL de grants).
- Facilitador: además `CREATE SCHEMA`, `CREATE VOLUME`, `CREATE TABLE` o ownership del pipeline.

## Troubleshooting rápido

- **`Variable source not found`:** añade `source` = `/Volumes/workshop/sdp_landing/raw` en la configuración del pipeline.
- **`Permission denied` en volumen:** revisa `GRANT READ FILES` / `USAGE` sobre el volumen UC.
- **Confusión con `workshop.gold`:** las tablas del taller Genie no se modifican; SDP solo escribe en `sdp_*`.
