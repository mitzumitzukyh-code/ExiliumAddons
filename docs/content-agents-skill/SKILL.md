---
name: content-agents-cloudflare
description: >
  Sistema completo de 5 agentes automatizados para generar y publicar contenido viral en TikTok e Instagram,
  usando Cloudflare Workers + KV + AI + Pages. Úsala cuando el usuario quiera construir agentes de contenido,
  automatizar redes sociales, crear un centro de mando web, o construir cualquier sistema multi-agente
  sobre Cloudflare. Incluye pruebas de integración completas al finalizar.
---

# Sistema Multi-Agente de Contenido — Cloudflare

---

## REGLAS DE VERSIONADO — LEER ANTES DE HACER CUALQUIER COSA

**Estas reglas son obligatorias. Aplican en cada sesión, sin excepción.**

### Regla 1 — Leer la Skill SIEMPRE al inicio
Antes de escribir cualquier línea de código, hacer cualquier corrección, o responder
cualquier pregunta técnica sobre este proyecto: leer este SKILL.md completo.
No asumir nada del contexto anterior. La Skill es la fuente de verdad.

### Regla 2 — Versión actual
```
Versión: 1.1.0
Última actualización: 2025-05-05
Historial: Ver sección CHANGELOG al final de este archivo
```

### Regla 3 — Cuándo incrementar la versión

| Tipo de cambio | Ejemplo | Versión |
|---|---|---|
| Bug fix, corrección menor | Arreglar un error en un Worker | 1.0.0 → 1.0.1 |
| Feature nueva o agente mejorado | Agregar nueva fuente al Scout | 1.0.0 → 1.1.0 |
| Cambio de arquitectura o stack | Migrar de KV a D1 | 1.0.0 → 2.0.0 |

### Regla 4 — Qué hacer AL TERMINAR cualquier sesión de trabajo

Al finalizar cada sesión, cuando el usuario diga "terminamos", "listo" o "guarda",
actualizar este SKILL.md haciendo lo siguiente:

1. Incrementar la versión según la tabla anterior
2. Actualizar la fecha en `Última actualización`
3. Agregar una entrada al CHANGELOG al final de este archivo con este formato exacto:

```
### v1.0.1 — YYYY-MM-DD
- Qué se construyó o corrigió
- Qué archivos se crearon o modificaron
- Problemas encontrados y cómo se resolvieron (si aplica)
- Notas para la próxima sesión (si aplica)
```

4. Si se descubrió algo nuevo sobre el stack (límites de Cloudflare AI,
   comportamiento inesperado del KV, errores de Wrangler, etc.)
   agregar una nota en la sección Notas de Implementación para que
   sesiones futuras no repitan el mismo error.

### Regla 5 — Qué hacer AL INICIO de cada sesión de corrección

Cuando el usuario reporta un bug o pide una mejora:
1. Leer el SKILL.md completo
2. Revisar el CHANGELOG para entender qué se hizo antes
3. Revisar las Notas de Implementación para no repetir errores conocidos
4. Hacer el cambio
5. Actualizar la Skill al terminar

---

## Objetivo
Construir 5 Workers independientes que trabajen en pipeline para generar contenido viral
en TikTok e Instagram de forma automática, con un Dashboard web como Centro de Mando.
Todo sobre Cloudflare free tier. Sin servidor propio. Sin costo de API externo.

---

## Stack Técnico
- **Workers**: Cloudflare Workers (lógica de cada agente)
- **Cola/Estado**: Cloudflare KV (comunicación entre agentes)
- **IA de texto**: Cloudflare AI — `@cf/meta/llama-3.3-70b-instruct-fp8-fast`
- **IA de imágenes**: Cloudflare AI — `@cf/bytedance/stable-diffusion-xl-lightning`
- **Scheduler**: Cloudflare Cron Triggers + botones manuales en Dashboard
- **Dashboard**: Cloudflare Pages (HTML/CSS/JS estático, sin framework)
- **Lenguaje**: JavaScript/TypeScript (Workers runtime)

---

## Arquitectura de Comunicación

Todos los agentes leen y escriben en **Cloudflare KV**. Nunca se llaman entre sí directamente.
Esto los hace independientes y tolerantes a fallos.

### Namespaces KV requeridos
Crear estos namespaces en Cloudflare antes de empezar:

| Namespace | Propósito |
|-----------|-----------|
| `CONTENT_QUEUE` | Jobs de tendencias del Agente 1 → Agente 2 |
| `CONTENT_RESULTS` | Resultados del Agente 2 → Agente 3 |
| `APPROVED_CONTENT` | Contenido aprobado por Agente 3 → publicación |
| `AGENT_STATUS` | Estado en tiempo real de cada agente |
| `FINANCE_LOG` | Registro de publicaciones y métricas |
| `SYSTEM_CONFIG` | Configuración global del sistema |

### Estructura de un Job en KV
```json
{
  "job_id": "uuid-v4",
  "created_at": "ISO8601",
  "status": "pending|processing|approved|rejected|published",
  "agent_trail": ["scout", "creator", "supervisor"],
  "topic": "string",
  "score": 0.0,
  "category": "gaming|curiosidades|memes|noticias|motivacional",
  "language": "es|en|both",
  "platform": "tiktok|instagram|both",
  "content": {
    "hook": "string",
    "caption": "string",
    "hashtags": ["string"],
    "cta": "string",
    "image_url": "string",
    "image_prompt": "string"
  },
  "review": {
    "status": "approved|rejected|needs_edit",
    "score": 0.0,
    "issues": ["string"],
    "auto_fixable": true
  },
  "finance": {
    "published_at": "ISO8601",
    "platform": "string",
    "affiliate_link": "string"
  }
}
```

---

## Agente 1 — Scout de Tendencias

**Worker name**: `agent-scout`
**Cron**: Cada 6 horas — `0 */6 * * *`
**También**: Disparable manualmente desde Dashboard

### Fuentes a consultar (en orden de prioridad)
1. **Google Trends** — vía `https://trends.google.com/trends/trendingsearches/daily/rss?geo=US` (RSS público, sin API key)
2. **Reddit** — vía `https://www.reddit.com/r/popular.json` y subreddits por categoría
3. **YouTube Trending** — vía YouTube Data API v3 (key gratuita, 10k requests/día)
4. **HackerNews** — vía `https://hacker-news.firebaseio.com/v0/topstories.json` (público)

> TikTok Creative Center no tiene API pública confiable. Usar Reddit + Google como proxy de tendencias TikTok.

### Lógica de scoring
```javascript
score = (velocidad_crecimiento * 0.4) + (volumen_busquedas * 0.3) + (relevancia_categoria * 0.3)
// Descartar si score < 0.6
// Descartar si el topic ya fue procesado en las últimas 48h (check en KV)
```

### Categorías configurables (leer de SYSTEM_CONFIG en KV)
`gaming`, `curiosidades`, `memes`, `noticias`, `motivacional`, `tecnologia`

### Output — escribe en `CONTENT_QUEUE`
Máximo 10 jobs por ciclo. Key: `job:{uuid}`. TTL: 48 horas.

---

## Agente 2 — Creator de Contenido

**Worker name**: `agent-creator`
**Trigger**: Cron cada 30 min — `*/30 * * * *` — busca jobs `status: pending` en `CONTENT_QUEUE`

### Paso 1 — Generar texto con Cloudflare AI

```javascript
const response = await env.AI.run('@cf/meta/llama-3.3-70b-instruct-fp8-fast', {
  messages: [
    {
      role: 'system',
      content: `Eres un experto en contenido viral para TikTok e Instagram.
      Genera contenido en ${job.language === 'es' ? 'español' : job.language === 'en' ? 'inglés' : 'español e inglés'}.
      Responde SOLO con JSON válido, sin markdown, sin explicaciones.`
    },
    {
      role: 'user',
      content: `Tema: "${job.topic}"
      Categoría: ${job.category}
      Plataforma: ${job.platform}
      
      Genera este JSON exacto:
      {
        "hook": "Primera línea que engancha en 3 segundos (máx 15 palabras)",
        "caption": "Caption completo para la publicación (máx 300 caracteres)",
        "hashtags": ["hashtag1", "hashtag2", ... máx 20],
        "cta": "Call to action al final (máx 10 palabras)",
        "image_prompt": "Prompt en inglés para generar imagen con Stable Diffusion (máx 100 palabras, estilo viral, colorido, llamativo)"
      }`
    }
  ]
});
```

### Paso 2 — Generar imagen con Cloudflare AI

```javascript
const imageResponse = await env.AI.run('@cf/bytedance/stable-diffusion-xl-lightning', {
  prompt: content.image_prompt,
  num_steps: 4  // Lightning model — rápido y gratis
});
// imageResponse es un ArrayBuffer — guardar en KV o R2
```

### Paso 3 — Para memes
Si `category === 'memes'`:
- Generar imagen base con SD Lightning
- Superponer texto del hook usando Canvas API en el Worker
- Formato: texto blanco con borde negro, fuente Impact, posición superior e inferior

### Formatos de exportación
- TikTok/Reels: 1080×1920 (9:16)
- Instagram feed: 1080×1080 (1:1)
- Si `platform === 'both'`: generar ambas versiones

### Output — escribe en `CONTENT_RESULTS`
Actualiza el job con `status: 'review_pending'` y los campos `content` completos.

---

## Agente 3 — Supervisor / QA

**Worker name**: `agent-supervisor`
**Trigger**: Cron cada 15 min — `*/15 * * * *` — busca jobs `status: review_pending`

### Criterios de revisión (todos deben pasar)

**Contenido de texto**
- [ ] Hook presente y longitud ≤ 15 palabras
- [ ] Caption entre 50 y 300 caracteres
- [ ] CTA presente al final del caption
- [ ] Hashtags: mínimo 5, máximo 30
- [ ] Idioma del texto coincide con `job.language`
- [ ] No contiene palabras de la lista negra (leer de `SYSTEM_CONFIG`)
- [ ] No es idéntico a los últimos 5 posts publicados (check en `FINANCE_LOG`)
- [ ] La tendencia tiene menos de 48h de antigüedad (`job.created_at`)

**Imagen**
- [ ] El campo `image_url` existe y no está vacío
- [ ] El ArrayBuffer tiene más de 1KB (imagen no está corrupta/vacía)

**Score mínimo**: 0.75 para aprobación automática

### Lógica de decisión
```javascript
if (score >= 0.75 && issues.length === 0) {
  status = 'approved'
} else if (score >= 0.5 && auto_fixable) {
  // Reenviar al Agente 2 con instrucciones de corrección
  status = 'needs_edit'
  // Escribir de vuelta en CONTENT_QUEUE con issues como contexto
} else {
  status = 'rejected'
  // Loggear razón en FINANCE_LOG
}
```

### Output — escribe en `APPROVED_CONTENT`
Jobs aprobados listos para publicación manual (1 clic desde Dashboard).

> **Nota sobre publicación**: TikTok y Meta no permiten publicación automática via API sin aprobación de business. El Agente 3 deja el contenido listo y notifica. El usuario publica con 1 clic desde el Dashboard.

---

## Agente 4 — Finance Tracker

**Worker name**: `agent-finance`
**Trigger**: Se activa cada vez que el Agente 3 aprueba un post + Cron diario a medianoche

### Qué registra por publicación
```json
{
  "post_id": "uuid",
  "published_at": "ISO8601",
  "platform": "tiktok|instagram",
  "category": "string",
  "language": "es|en",
  "topic": "string",
  "affiliate_link": "string",
  "affiliate_clicks": 0,
  "estimated_reach": 0,
  "status": "published|pending|failed"
}
```

### Métricas que calcula (reporte diario)
- Posts publicados esta semana / mes
- Categoría con mejor rendimiento (basado en frecuencia de aprobación)
- Idioma más publicado
- Estimado de ingresos: `affiliate_clicks * avg_commission` (configurable en SYSTEM_CONFIG)
- Racha actual de días publicando (para no romper el algoritmo)
- Alerta si llevan más de 24h sin publicar

### Output — escribe en `FINANCE_LOG`
Key: `finance:daily:{YYYY-MM-DD}` con el reporte del día.
Key: `finance:post:{post_id}` con detalle de cada post.

---

## Agente 5 — Dashboard (Centro de Mando)

**Tipo**: Cloudflare Pages — sitio estático (HTML + CSS + JS vanilla)
**No usa framework**. Todo en un solo `index.html` + `dashboard.js` + `styles.css`.

### Secciones del Dashboard

#### 1. Panel de Estado de Agentes
Muestra en tiempo real (polling cada 30s a un Worker de status):
```
🟢 Scout        Última ejecución: hace 2h    Próxima: en 4h
🟢 Creator      Jobs procesados hoy: 8
🟡 Supervisor   3 items en revisión
🟢 Finance      Reporte: actualizado
🔴 Sistema      Último error: [mensaje]
```

#### 2. Cola de Contenido (Kanban visual)
Columnas: `Pendiente → En creación → En revisión → Aprobado → Publicado`
Cada card muestra: topic, categoría, idioma, plataforma, score del Supervisor.

#### 3. Bandeja de Aprobados (acción requerida)
Lista de posts listos para publicar. Cada uno tiene:
- Preview de la imagen generada
- Caption + hashtags completos listos para copiar
- Botón "Copiar caption" — copia al clipboard con 1 clic
- Botón "Descargar imagen" — descarga el archivo listo para subir
- Botón "Marcar como publicado" — actualiza FINANCE_LOG y mueve a Publicados
- Indicador de plataforma destino (TikTok / Instagram / ambas)
- Link de afiliado asociado si aplica (configurable en SYSTEM_CONFIG)

> Publicación manual: TikTok e Instagram no permiten publicación automática
> sin aprobación de Business Account. El flujo es: Dashboard genera el contenido
> → usuario copia y sube → menos de 60 segundos por post.

#### 4. Centro de Control Manual
Botones para disparar cualquier agente sin esperar el cron:
- `⚡ Buscar tendencias ahora` → llama al Agent Scout
- `🎨 Generar contenido` → llama al Agent Creator
- `🔍 Revisar cola` → llama al Agent Supervisor
- `📊 Actualizar reporte` → llama al Agent Finance

#### 5. Configuración Global
Formulario que escribe en `SYSTEM_CONFIG` en KV:
- Categorías activas (checkboxes)
- Idiomas (es / en / ambos)
- Plataformas objetivo
- Palabras en lista negra
- Horarios de cron preferidos
- Umbral mínimo de score del Supervisor
- Comisión promedio de afiliados (para cálculo de ingresos)

#### 6. Reporte Financiero
Gráfico de barras simple (Chart.js CDN) con:
- Posts por día (últimos 30 días)
- Clicks de afiliado estimados
- Proyección de ingresos del mes

### Autenticación del Dashboard
Proteger con un password simple via `_headers` de Cloudflare Pages o Basic Auth en un Worker proxy. No necesita login sofisticado.

### Diseño Visual
- Fondo oscuro (`#0d1117`), acentos en verde neón (`#00ff88`) y morado (`#7c3aed`)
- Tipografía: `Inter` (Google Fonts CDN)
- Responsive — debe verse bien en móvil (para gestionar desde el teléfono)
- Sin dependencias de npm — todo via CDN (Chart.js, Lucide icons)

---

## Estructura de Archivos del Proyecto

```
content-agents/
├── workers/
│   ├── agent-scout/
│   │   ├── src/index.js
│   │   └── wrangler.toml
│   ├── agent-creator/
│   │   ├── src/index.js
│   │   └── wrangler.toml
│   ├── agent-supervisor/
│   │   ├── src/index.js
│   │   └── wrangler.toml
│   ├── agent-finance/
│   │   ├── src/index.js
│   │   └── wrangler.toml
│   └── agent-status/          ← Worker auxiliar que el Dashboard consulta
│       ├── src/index.js
│       └── wrangler.toml
└── dashboard/
    ├── index.html
    ├── dashboard.js
    ├── styles.css
    └── _headers                ← CORS + auth headers
```

### wrangler.toml base para cada agente
```toml
name = "agent-scout"           # cambiar por cada agente
main = "src/index.js"
compatibility_date = "2024-01-01"

[[kv_namespaces]]
binding = "CONTENT_QUEUE"
id = "REEMPLAZAR_CON_ID_REAL"

[[kv_namespaces]]
binding = "AGENT_STATUS"
id = "REEMPLAZAR_CON_ID_REAL"

[[kv_namespaces]]
binding = "SYSTEM_CONFIG"
id = "REEMPLAZAR_CON_ID_REAL"

[ai]
binding = "AI"

[triggers]
crons = ["0 */6 * * *"]        # ajustar por agente
```

---

## Variables de Entorno Requeridas

Configurar en Cloudflare Dashboard > Workers > Settings > Variables:

| Variable | Agente | Descripción |
|----------|--------|-------------|
| `YOUTUBE_API_KEY` | Scout | YouTube Data API v3 key (gratuita) |
| `DASHBOARD_PASSWORD` | Status Worker | Password para proteger el Dashboard |

> No se necesitan más API keys. Cloudflare AI no requiere key adicional — es parte del plan Workers.

---

## FASE FINAL: Pruebas de Integración (OBLIGATORIO)

**Esta fase es obligatoria. No dar el proyecto como terminado sin completarla.**

Después de deployar todos los Workers y el Dashboard, ejecutar este ciclo de prueba completo:

### Test 1 — Scout funciona
```bash
curl -X POST https://agent-scout.TU_SUBDOMINIO.workers.dev/run \
  -H "Content-Type: application/json" \
  -d '{"manual": true, "category": "gaming", "language": "es"}'
# Esperado: HTTP 200 + JSON con al menos 1 job guardado en KV
```

### Test 2 — Creator genera contenido real
```bash
curl -X POST https://agent-creator.TU_SUBDOMINIO.workers.dev/run \
  -H "Content-Type: application/json" \
  -d '{"manual": true}'
# Esperado: HTTP 200 + job actualizado con hook, caption, hashtags, image generada
```

### Test 3 — Supervisor aprueba correctamente
```bash
curl -X POST https://agent-supervisor.TU_SUBDOMINIO.workers.dev/run \
  -H "Content-Type: application/json" \
  -d '{"manual": true}'
# Esperado: Al menos 1 job con status "approved" en APPROVED_CONTENT
```

### Test 4 — Finance registra la actividad
```bash
curl -X POST https://agent-finance.TU_SUBDOMINIO.workers.dev/run \
  -H "Content-Type: application/json" \
  -d '{"manual": true}'
# Esperado: Reporte del día actualizado en FINANCE_LOG
```

### Test 5 — Dashboard muestra todo en tiempo real
- Abrir el Dashboard en el browser
- Verificar que los 4 agentes aparecen con estado actual
- Verificar que la cola Kanban muestra los jobs del test
- Verificar que la bandeja de Aprobados tiene al menos 1 item con imagen preview
- Verificar que los botones manuales disparan los Workers correctamente

### Test 6 — Imagen de prueba real
Disparar el pipeline completo con este topic de prueba:
```json
{
  "topic": "Top 5 videojuegos más esperados de 2025",
  "category": "gaming",
  "language": "es",
  "platform": "both"
}
```
**Resultado esperado**: Una imagen 1080×1920 con texto superpuesto lista para subir a TikTok,
y una 1080×1080 para Instagram feed. Ambas visibles en el Dashboard.

### Test 7 — Meme de prueba real
```json
{
  "topic": "Cuando el WiFi se cae justo en el momento crucial del juego",
  "category": "memes",
  "language": "es",
  "platform": "both"
}
```
**Resultado esperado**: Imagen estilo meme con texto en Impact font, visible en Dashboard.

### Checklist final de entrega
- [ ] Los 5 Workers están deployados y responden HTTP 200
- [ ] El Dashboard carga en Cloudflare Pages sin errores de consola
- [ ] El pipeline Scout → Creator → Supervisor → Finance funciona de punta a punta
- [ ] Se generó al menos 1 imagen real (no placeholder) visible en Dashboard
- [ ] Se generó al menos 1 meme real visible en Dashboard
- [ ] Los botones manuales del Dashboard disparan los Workers correctamente
- [ ] La sección de configuración guarda y lee de KV correctamente
- [ ] El reporte financiero muestra datos reales (no zeros)

---


---

## Cuentas Necesarias para Publicar y Monetizar

### Redes Sociales (gratuitas)
- TikTok — cuenta personal normal, sin requisitos
- Instagram — cuenta personal normal, sin requisitos
- Publicación: manual desde el Dashboard (1 clic copiar + pegar en la app)
- Publicación automática futura: requiere Meta Business Account + aprobación de API (upgrade opcional)

### Plataformas de Afiliados compatibles con Venezuela + Zinli

| Plataforma | Registro | Cobro | Ideal para |
|---|---|---|---|
| Hotmart | Gratis en hotmart.com | Zinli / PayPal | Cursos digitales |
| Digistore24 | Gratis en digistore24.com | Zinli / transferencia | Productos digitales |
| Amazon Afiliados | Gratis en affiliate-program.amazon.com | Zinli | Productos físicos y tech |
| TikTok Creator Fund | 10k seguidores mínimo | Directo | Monetización de TikTok |

### Cómo integrar los links de afiliado en el sistema
El Agente 4 (Finance) trackea los links de afiliado por post. Configurar en SYSTEM_CONFIG:
```json
{
  "affiliate_links": {
    "gaming": "https://tu-link-hotmart.com/producto-gaming",
    "tecnologia": "https://amzn.to/tu-link-tech",
    "default": "https://tu-link-principal.com"
  },
  "affiliate_commission_avg": 0.15
}
```
El Agente 2 (Creator) inserta el link de afiliado correspondiente a la categoría
al final del caption automáticamente (solo en Instagram — TikTok no permite links en caption).

### Sección en el Dashboard para gestionar cuentas
El Dashboard debe incluir una sección "Mis Cuentas" con:
- Estado de cada cuenta de red social (activa / inactiva)
- Links de afiliado configurados por categoría
- Total de clicks estimados por plataforma de afiliado
- Botón para regenerar links con UTM parameters para tracking

## Notas de Implementación

- Usar `crypto.randomUUID()` nativo de Workers para generar job IDs (no instalar uuid)
- KV tiene latencia eventual — agregar 500ms de delay entre escritura y lectura en tests
- Cloudflare AI tiene rate limits en free tier: ~50 req/min para texto, ~10 req/min para imágenes
- Las imágenes generadas por SD Lightning son ArrayBuffers — guardar en KV como base64 string
- El Dashboard usa `fetch()` con polling cada 30s al Worker de status — no usar WebSockets
- CORS: el Worker de status debe incluir `Access-Control-Allow-Origin: *` para que el Dashboard pueda leerlo

## Orden de construcción recomendado

### Paso 0 — Setup automatizado (NO tocar Cloudflare Dashboard manualmente)

Crear el archivo `setup.sh` en la raíz del proyecto y ejecutarlo UNA sola vez.
Este script crea los 6 namespaces KV, captura sus IDs automáticamente y genera
un archivo `kv-ids.json` que todos los `wrangler.toml` van a leer:

```bash
#!/bin/bash
# setup.sh — Ejecutar una sola vez: bash setup.sh

echo "🚀 Creando namespaces KV en Cloudflare..."

declare -A KV_IDS

for NS in CONTENT_QUEUE CONTENT_RESULTS APPROVED_CONTENT AGENT_STATUS FINANCE_LOG SYSTEM_CONFIG; do
  echo "Creando $NS..."
  OUTPUT=$(wrangler kv namespace create "$NS" 2>&1)
  ID=$(echo "$OUTPUT" | grep -o '"id": "[^"]*"' | grep -o '[a-f0-9]\{32\}')
  KV_IDS[$NS]=$ID
  echo "  ✅ $NS → $ID"
done

# Guardar IDs en archivo JSON para que los wrangler.toml los usen
cat > kv-ids.json << EOF
{
  "CONTENT_QUEUE": "${KV_IDS[CONTENT_QUEUE]}",
  "CONTENT_RESULTS": "${KV_IDS[CONTENT_RESULTS]}",
  "APPROVED_CONTENT": "${KV_IDS[APPROVED_CONTENT]}",
  "AGENT_STATUS": "${KV_IDS[AGENT_STATUS]}",
  "FINANCE_LOG": "${KV_IDS[FINANCE_LOG]}",
  "SYSTEM_CONFIG": "${KV_IDS[SYSTEM_CONFIG]}"
}
EOF

echo ""
echo "✅ Setup completo. IDs guardados en kv-ids.json"
echo "👉 Ahora continúa con la construcción de los Workers."
```

Después de ejecutar `setup.sh`, cada `wrangler.toml` debe leer los IDs del `kv-ids.json`.
Usar un script `inject-kv-ids.js` (Node.js) para reemplazar los placeholders automáticamente:

```javascript
// inject-kv-ids.js — ejecutar después de setup.sh
const fs = require('fs');
const path = require('path');

const ids = JSON.parse(fs.readFileSync('kv-ids.json', 'utf8'));

const workers = ['agent-scout', 'agent-creator', 'agent-supervisor', 'agent-finance', 'agent-status'];

workers.forEach(worker => {
  const tomlPath = path.join('workers', worker, 'wrangler.toml');
  if (!fs.existsSync(tomlPath)) return;
  
  let content = fs.readFileSync(tomlPath, 'utf8');
  
  Object.entries(ids).forEach(([name, id]) => {
    content = content.replaceAll(`REEMPLAZAR_CON_ID_${name}`, id);
  });
  
  fs.writeFileSync(tomlPath, content);
  console.log(`✅ ${worker}/wrangler.toml actualizado`);
});

console.log('\n👉 Todos los wrangler.toml tienen sus IDs. Listo para deployar.');
```

Secuencia completa de setup desde cero:
```bash
bash setup.sh
node inject-kv-ids.js
```

### Pasos de construcción
1. Ejecutar `setup.sh` + `inject-kv-ids.js` (crea los 6 KV namespaces automáticamente)
2. Construir y deployar `agent-status` Worker (el Dashboard lo necesita)
3. Construir el Dashboard (Pages) — así puedes ver el estado mientras construyes
4. Construir `agent-scout` → probar → continuar
5. Construir `agent-creator` → probar con un topic manual → continuar
6. Construir `agent-supervisor` → probar → continuar
7. Construir `agent-finance` → probar → continuar
8. Ejecutar la Fase Final de Pruebas completa

---

## CHANGELOG

### v1.1.0 — 2025-05-05
- Sección "Cuentas Necesarias" agregada: TikTok, Instagram, Hotmart, Digistore24, Amazon Afiliados
- Bandeja de Aprobados mejorada: botones Copiar caption, Descargar imagen, link de afiliado por post
- Sección "Mis Cuentas" agregada al Dashboard para gestionar redes y links de afiliado
- Agente 2 actualizado: inserta link de afiliado por categoría automáticamente en el caption
- SYSTEM_CONFIG ampliado con campo affiliate_links por categoría y comisión promedio
- Todo compatible con Venezuela + Zinli para cobros

### v1.0.0 — 2025-05-05
- Skill inicial creada
- Arquitectura de 5 agentes definida (Scout, Creator, Supervisor, Finance, Dashboard)
- Stack definido: Cloudflare Workers + KV + AI + Pages
- Setup automatizado con setup.sh + inject-kv-ids.js (sin pasos manuales en Dashboard)
- 7 tests de integración obligatorios definidos incluyendo imagen real y meme real
- Dashboard Centro de Mando con 6 secciones especificado
- Reglas de versionado agregadas en v1.0.0
- Proyecto aún no construido — pendiente primera sesión en Windsurf
