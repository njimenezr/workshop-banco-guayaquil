# Genie Code Workshop — Banco Guayaquil

Workshop práctico de Databricks Genie Code adaptado para **Banco Guayaquil**. Cubre 4 tracks de ~105 minutos sobre el catálogo **`workshop`**: datos sintéticos en **`gold`** (núcleo bancario + **marketplace digital** complementario al SDP), CSV de transacciones para medallión PySpark (Genie), y el módulo **Lakeflow SDP** en `sdp-workshop/` sobre el mismo catálogo. El pipeline SDP sigue siendo solo archivos; los `customer_id` del JSON coinciden con `dim_clientes` para cruces opcionales en SQL.

---

## Tracks disponibles

| Track | Descripción | Duración |
|---|---|---|
| ⚙️ Data Engineering | Genie Code + datos `gold`; CSV real del core (`default/raw`) para medallión PySpark; enlaza con SDP | ~105 min |
| 📊 BI & Analytics | SQL desde lenguaje natural, Metric Views (NPL/mora), Genie Spaces, dashboards de riesgo | 105 min |
| 🧠 Data Science & ML | Scoring crediticio, MLflow, Model Serving, applyInPandas por región/segmento, alertas SARLAFT | 105 min |
| 🛡️ Data Governance | DQ regulatorio, CLS/RLS para datos financieros, framework de auditoría, Data Academy | 105 min |
| 🔷 Lakeflow SDP (módulo aparte) | Taller Declarative Pipelines: medallión, DQ, CDC — ver sección *Módulo Spark Declarative Pipelines* más abajo | ~100 min |

---

## Módulo Spark Declarative Pipelines (SDP)

- **Código y notebooks:** carpeta [`sdp-workshop/`](sdp-workshop/README.md) en **este** repositorio (catálogo único `workshop`, esquemas `sdp_*`).
- **Guía del participante en la app:** track `sdp-lakeflow-workshop-repositorio` (pestaña SDP).
- **Origen pedagógico:** [dbx-Workshop-Declarative-Pipelines](https://github.com/njimenezr/dbx-Workshop-Declarative-Pipelines) (histórico; el taller operativo está consolidado en `sdp-workshop/`).

---

## Preparación del ambiente (paso a paso)

Estos pasos los ejecuta el facilitador **antes del workshop**. Tiempo estimado: 30-45 minutos.

---

### Paso 1 — Subir el notebook generador de datos al workspace

1. Descarga el archivo `generate_workshop_data.py` de este repositorio.
2. Abre el workspace de Databricks en el navegador.
3. En la barra lateral, haz clic en **Workspace** → navega a una carpeta compartida (por ejemplo `/Shared/workshop/`).
4. Haz clic en el botón **"+ Add"** (o arrastra el archivo) → **Import** → sube `generate_workshop_data.py`.
5. Databricks lo reconocerá automáticamente como notebook.

---

### Paso 2 — Crear un cluster y ejecutar el notebook

1. En la barra lateral, ve a **Compute** → **Create compute**.
2. Configura el cluster:
   - **Runtime**: 15.x ML (o superior) — necesario para el track de Data Science
   - **Node type**: cualquier nodo con al menos 16 GB RAM (e.g., `Standard_DS4_v2`)
   - **Single node** es suficiente para la generación de datos
3. Haz clic en **Create compute** y espera a que inicie (2-3 minutos).
4. Abre el notebook `generate_workshop_data` que subiste en el Paso 1.
5. En la esquina superior derecha, selecciona el cluster recién creado.
6. Haz clic en **Run all** (▶▶) o `Shift + Enter` celda por celda.
7. Al terminar, el output final debe mostrar las tablas en `workshop.gold` (incluidas las de **marketplace digital** complementarias al SDP), **y** las líneas que confirman el CSV en `/Volumes/workshop/default/raw/transacciones_nuevas.csv` y el JSON SDP en `/Volumes/workshop/sdp_landing/raw/` (mismos `order_id` / `customer_id` que `fact_pedidos_marketplace`).

```
✅ workshop.gold.dim_clientes
✅ workshop.gold.dim_sucursales
✅ workshop.gold.fact_transacciones
✅ workshop.gold.fact_cartera_creditos
✅ workshop.gold.fact_kpis_diarios
✅ workshop.gold.dim_categoria_pedido_digital
✅ workshop.gold.fact_pedidos_marketplace
✅ SDP landing JSON alineado con gold: /Volumes/workshop/sdp_landing/raw/
✅ CSV exportado ... /Volumes/workshop/default/raw/transacciones_nuevas.csv
✅ Generación completa. Workshop listo.
Genie Data Engineering: CSV del core en /Volumes/workshop/default/raw/transacciones_nuevas.csv
Lakeflow SDP (sdp-workshop): JSON en /Volumes/workshop/sdp_landing/raw/ (alineado con fact_pedidos_marketplace)
```

> El notebook es idempotente — si algo falla, puedes ejecutarlo de nuevo sin problema.

---

### Paso 3 — Verificar las tablas en Unity Catalog

1. En la barra lateral, haz clic en **Catalog** (ícono de catálogo).
2. Navega a **workshop** → **gold**.
3. Confirma que existen **7 tablas** en `gold` y tienen datos:
   - `dim_clientes` (~2,500 filas)
   - `dim_sucursales` (~136 filas)
   - `fact_transacciones` (~200K filas)
   - `fact_cartera_creditos` (~5,000 filas)
   - `fact_kpis_diarios` (~4,000 filas)
   - `dim_categoria_pedido_digital` (8 filas — categorías marketplace)
   - `fact_pedidos_marketplace` (~174 filas — pedidos digitales enlazados a clientes/sucursales; fuente lógica del JSON SDP)

---

### Paso 4 — Dar permisos a los participantes

1. En la barra lateral, ve a **Catalog** → selecciona el catálogo **workshop**.
2. Haz clic en la pestaña **Permissions** → **Grant**.
3. Otorga los siguientes permisos al grupo o usuarios del workshop:

```sql
-- También puedes ejecutar esto en un notebook SQL
GRANT USE CATALOG ON CATALOG workshop TO `workshop_users`;
GRANT USE SCHEMA ON SCHEMA workshop.gold TO `workshop_users`;
GRANT SELECT ON ALL TABLES IN SCHEMA workshop.gold TO `workshop_users`;
```

> Reemplaza `` `workshop_users` `` por el nombre real del grupo en el workspace de Banco Guayaquil. Si no existe un grupo, agrégalo desde **Settings → Identity & Access → Groups**.

---

### Paso 5 — Habilitar Foundation Model API

Requerido para los steps que usan FMAPI (Knowledge Assistant, AI Functions en SQL, alertas SARLAFT). Si ya está habilitado en el workspace, omite este paso.

1. Ve a **Settings** (esquina inferior izquierda) → **Workspace settings**.
2. Busca **"Foundation Model APIs"** o **"External Models"**.
3. Habilítalo y confirma que el modelo `databricks-claude-sonnet-4` está disponible.
4. Para verificar, abre un notebook y ejecuta:

```python
import httpx
from databricks.sdk.config import Config
cfg = Config()
r = httpx.post(
    f"{cfg.host}/serving-endpoints/databricks-claude-sonnet-4/invocations",
    headers={"Authorization": f"Bearer {cfg.token}"},
    json={"messages": [{"role": "user", "content": "Hola"}]},
)
print(r.status_code, r.json())
```

Si retorna `200`, está listo.

---

### Paso 6 — Verificar que Genie Code está activo

1. Abre cualquier notebook en el workspace.
2. Verifica que aparece el botón ✨ **Genie Code** en la barra superior derecha del notebook.
3. Si no aparece, ve a **Settings → Feature Preview** → busca **"Databricks Assistant"** → habilítalo.
4. Pide a un participante de prueba que lo abra y confirme que puede generar código con un prompt simple.

---

### Paso 7 — Desplegar la app de instrucciones

La app muestra las instrucciones interactivas del workshop a los participantes.

**Opción A — Desde la CLI de Databricks:**

```bash
# Instala la CLI si no la tienes
pip install databricks-cli

# Sube el código al workspace (ajusta <tu-usuario> y la carpeta si lo deseas)
databricks workspace import_dir . /Workspace/Users/<tu-usuario>/genie-bg-workshop --overwrite

# Despliega la app
databricks apps deploy genie-bg-workshop \
  --source-code-path /Workspace/Users/<tu-usuario>/genie-bg-workshop
```

**Opción B — Desde la UI:**

1. En la barra lateral, ve a **Apps** → **Create app**.
2. Selecciona **"Custom app"** o **"FastAPI"**.
3. Apunta al path del workspace donde subiste el código.
4. Haz clic en **Deploy**.
5. Una vez desplegada, copia la URL y compártela con los participantes.

---

### Checklist final antes del workshop

Antes de que lleguen los participantes, confirma cada punto:

- [ ] Las **7 tablas** existen en `workshop.gold` con datos, el CSV `/Volumes/workshop/default/raw/transacciones_nuevas.csv` existe (Genie DE paso 2) y el JSON SDP está en `/Volumes/workshop/sdp_landing/raw/` (tras `generate_workshop_data.py`, alineado con `fact_pedidos_marketplace`)
- [ ] Los participantes tienen permisos `SELECT` en `workshop.gold`
- [ ] Foundation Model API responde con `200`
- [ ] El botón ✨ Genie Code aparece en notebooks
- [ ] La app de instrucciones está desplegada y accesible
- [ ] Al menos un cluster está corriendo (o en modo serverless) para que los participantes no esperen cold start

---

## HTML para compartir (sin servidor)

Para enviar la guía por correo, Teams o subirla a un bucket estático sin usar FastAPI:

1. Regenera el archivo único (embebe `data/tracks.json` e íconos SVG):

   ```bash
   python3 scripts/build_static_share_html.py
   ```

2. Entrega a los participantes el archivo **`frontend/workshop-app-compartir.html`**. Pueden abrirlo directamente en el navegador (doble clic) o puedes publicarlo en cualquier hosting de archivos estáticos.

---

## Estructura del proyecto

```
genie-bg-workshop/
├── app.yaml                    # Configuración Databricks Apps
├── main.py                     # Backend FastAPI
├── requirements.txt            # Dependencias Python
├── generate_workshop_data.py   # Genera gold (núcleo + marketplace), CSV core, esquemas sdp_* y JSON sdp_landing (ejecutar una vez)
├── sdp-workshop/               # Taller Lakeflow SDP (mismo catálogo workshop, esquemas sdp_*)
│   ├── README.md
│   ├── notebooks/00_SETUP_workshop_single_catalog.py
│   ├── transformations/*.sql
│   ├── exercises/
│   └── sql/GRANTS_single_catalog.sql
├── scripts/
│   └── build_static_share_html.py  # Genera workshop-app-compartir.html
├── data/
│   └── tracks.json             # Tracks Genie + módulo SDP (`strip: sdp`)
└── frontend/
    ├── index.html              # App (single-page) con API /api/tracks
    ├── workshop-app-compartir.html  # Guía autocontenida para participantes (regenerar con el script)
    ├── index_static.html       # Legado: datos embebidos (preferir workshop-app-compartir.html)
    └── img/                    # Íconos de tracks
```

---

## Regiones sintéticas (Ecuador) en los datos

| Código | Región (ficticia para el taller) | Clientes | Cartera base |
|---|---|---|---|
| GY | Costa — Guayas | 500 | $180M |
| PI | Sierra — Pichincha | 380 | $220M |
| AZ | Austro — Azuay | 320 | $140M |
| MN | Costa — Manabí | 270 | $260M |
| OR | Costa — El Oro | 250 | $120M |
| ES | Costa — Esmeraldas | 220 | $100M |
| LO | Sur — Loja | 170 | $90M |
| SD | Sierra — Santo Domingo | 290 | $195M |

La columna `country_code` conserva el nombre por compatibilidad con el esquema del workshop; semánticamente representa **código de región** dentro del dataset sintético.

---

## Notas para el facilitador

- Los datos son **100% sintéticos** — no contienen información real de Banco Guayaquil ni de sus clientes.
- Las tablas incluyen ~382 defectos de calidad intencionados para el track de Governance.
- El track de Data Science requiere ML Runtime en el cluster (para XGBoost y MLflow).
- Los steps que usan Foundation Model API tienen una advertencia visible en la app — ten un notebook de respaldo con el output esperado por si el endpoint no responde.
- El módulo **SDP** comparte el catálogo `workshop` pero escribe solo en esquemas `sdp_*` (ver `sdp-workshop/README.md`); el setup SDP no debe borrar `workshop.gold`.
