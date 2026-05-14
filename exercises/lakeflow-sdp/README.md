# Lakeflow SDP — ejercicios (mismo formato de pasos que Genie Code)

Importa estos notebooks al workspace **después** de que el facilitador ejecute **`generate_workshop_data.py`** (Run all) y apliquen los permisos en `sdp-workshop/sql/GRANTS_single_catalog.sql`.

En la **app para compartir** (`workshop-app-compartir.html`), los **6 pasos** del track Lakeflow SDP siguen el mismo orden que el laboratorio: crear pipeline → default catalog/schema → variable `source` → cómputo y run → añadir CDC → verificación SQL.

| Laboratorio | Archivo | Contenido |
|-------------|---------|-------------|
| Lección 1 | `sdp-exercise-01-pipeline-calidad-datos.sql` | UI del pipeline, Settings, `source`, ejecución pedidos + DQ |
| Lección 2 | `sdp-exercise-02-cdc-produccion.py` | Incorporar `customers_pipeline.sql`, AUTO CDC, métricas |

Código SQL reutilizable del pipeline: carpeta **`sdp-workshop/transformations/`** en este repo.

Variable de pipeline: **`source`** = `/Volumes/workshop/ingest/raw`
