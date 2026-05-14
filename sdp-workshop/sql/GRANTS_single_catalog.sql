-- =============================================================================
-- Permisos sugeridos — taller SDP + Genie en catálogo único `workshop`
-- Sustituye `workshop_lakeflow_participants` por el grupo real del taller.
-- Valida la sintaxis contra la versión de Unity Catalog de tu workspace.
-- =============================================================================

GRANT USE CATALOG ON CATALOG workshop TO `workshop_lakeflow_participants`;

GRANT USAGE ON SCHEMA workshop.ingest TO `workshop_lakeflow_participants`;
-- SDP escribe en bronze / silver / gold (mismo medallón que Genie; tablas marketplace_*, fact_marketplace_*, dim_marketplace_*).

GRANT USAGE ON SCHEMA workshop.bronze TO `workshop_lakeflow_participants`;
GRANT USAGE ON SCHEMA workshop.silver TO `workshop_lakeflow_participants`;
GRANT USAGE ON SCHEMA workshop.gold TO `workshop_lakeflow_participants`;
GRANT SELECT ON ALL TABLES IN SCHEMA workshop.bronze TO `workshop_lakeflow_participants`;
GRANT SELECT ON ALL TABLES IN SCHEMA workshop.silver TO `workshop_lakeflow_participants`;
GRANT SELECT ON ALL TABLES IN SCHEMA workshop.gold TO `workshop_lakeflow_participants`;

-- Volumen UC (ajusta según doc regional: READ FILES / EXECUTE / USAGE ON VOLUME)
GRANT READ FILES ON VOLUME workshop.ingest.raw TO `workshop_lakeflow_participants`;
GRANT WRITE FILES ON VOLUME workshop.ingest.raw TO `workshop_lakeflow_participants`;

-- Si el pipeline corre con identidad del participante y crea tablas en gold:
-- GRANT CREATE TABLE, MODIFY ON SCHEMA workshop.gold ... (según política)
