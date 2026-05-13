-- =============================================================================
-- Permisos sugeridos — taller SDP + Genie en catálogo único `workshop`
-- Sustituye `workshop_sdp_participants` por el grupo real del taller.
-- Valida la sintaxis contra la versión de Unity Catalog de tu workspace.
-- =============================================================================

GRANT USE CATALOG ON CATALOG workshop TO `workshop_sdp_participants`;

GRANT USAGE ON SCHEMA workshop.sdp_landing TO `workshop_sdp_participants`;
GRANT USAGE ON SCHEMA workshop.sdp_bronze TO `workshop_sdp_participants`;
GRANT USAGE ON SCHEMA workshop.sdp_silver TO `workshop_sdp_participants`;
GRANT USAGE ON SCHEMA workshop.sdp_gold TO `workshop_sdp_participants`;

-- Taller Genie (mismo grupo)
GRANT USAGE ON SCHEMA workshop.gold TO `workshop_sdp_participants`;
GRANT SELECT ON ALL TABLES IN SCHEMA workshop.gold TO `workshop_sdp_participants`;

-- Volumen UC (ajusta según doc regional: READ FILES / EXECUTE / USAGE ON VOLUME)
GRANT READ FILES ON VOLUME workshop.sdp_landing.raw TO `workshop_sdp_participants`;
GRANT WRITE FILES ON VOLUME workshop.sdp_landing.raw TO `workshop_sdp_participants`;

-- Si el pipeline corre con identidad del participante y crea tablas en sdp_*:
-- GRANT CREATE TABLE ON SCHEMA workshop.sdp_bronze TO `workshop_sdp_participants`;
-- (Muchos equipos prefieren un único service principal dueño del pipeline y solo SELECT para alumnos.)
