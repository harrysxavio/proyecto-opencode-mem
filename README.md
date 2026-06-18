# Runtime Kit para OpenCode y Codex

Overlay portable de instrucciones y skills para que OpenCode y Codex trabajen con un Manager, memoria gobernada, contexto pequeño y flujos verificables.

> **Idea para principiantes:** este repositorio no reemplaza OpenCode ni Codex. Instala archivos de configuración dentro del directorio de usuario del runtime que ya tienes instalado.

## Inicio rápido

### Requisitos

- Git.
- Node.js 20 o superior.
- `pnpm` (puedes habilitarlo con `corepack enable`).
- OpenCode y/o Codex ya instalados y autenticados.

```bash
git clone https://github.com/harrysxavio/proyecto-opencode-mem.git
cd proyecto-opencode-mem
corepack enable
pnpm install
pnpm test:all
```

Después elige **un** runtime:

```bash
# Codex
pnpm codex:install:dry-run --target ~/.codex
pnpm codex:install --target ~/.codex
pnpm codex:doctor --target ~/.codex

# OpenCode
pnpm opencode:install:dry-run --target ~/.config/opencode
pnpm opencode:install --target ~/.config/opencode
pnpm opencode:doctor --target ~/.config/opencode
```

En Windows puedes reemplazar `~` por `$HOME` en PowerShell.

## 1. Para personas no técnicas

El kit agrega tres capas de comportamiento:

1. **Manager:** decide si una solicitud es pequeña, de código, documentación, seguridad o QA.
2. **Skills:** procedimientos Markdown que se cargan sólo cuando son útiles.
3. **Gobernanza:** reglas para memoria, seguridad, presupuesto de contexto, backup y rollback.

No instala un modelo de IA. Tampoco ejecuta un servidor propio. Copia archivos que los runtimes leen como instrucciones.

## 2. Qué instala exactamente

Ambos instaladores escriben únicamente dentro del `--target` explícito:

| Destino | Contenido |
|---|---|
| `AGENTS.md` | Overlay del Manager específico del runtime |
| `skills/opencode-runtime-kit/<skill>/SKILL.md` | 18 skills portables |
| `.atl/skill-registry.md` | Índice generado con rutas instaladas válidas |
| `.opencode-kit/last-install.json` | Recibo de instalación para doctor y rollback |
| `.opencode-kit-backups/<id>/` | Copia de cada destino que existía antes de sobrescribirlo |

El instalador no escribe en la carpeta donde está instalada la aplicación. Rechaza explícitamente una ruta administrada por el actualizador de OpenCode.

## Contratos portables

Los archivos de [`contracts/`](contracts/) definen reglas compartidas; [`ARCHITECTURE.md`](ARCHITECTURE.md) resume la arquitectura y enlaza a la fuente maestra. Un contrato describe comportamiento, no instala software.

## 3. Arquitectura para OpenCode

```text
solicitud
  -> OpenCode carga AGENTS.md
  -> Manager clasifica y elige la ruta mínima
  -> carga skills bajo demanda
  -> puede aplicar SDD/gates si la tarea y las herramientas disponibles lo permiten
  -> verifica y responde
```

OpenCode recibe el Manager detallado de `opencode/manager.template.md`. Éste describe clasificación, SDD y gates opcionales. Los contratos viven en `contracts/`; los procedimientos reutilizables, en `skills/`.

**Importante:** instalar instrucciones para Engram, Graphify, modelos de revisión o subagentes no instala esos proveedores. Si no están disponibles, el Manager debe degradar a ejecución inline o declarar la capacidad faltante.

## 4. Arquitectura para Codex

```text
solicitud
  -> Codex carga AGENTS.md
  -> Manager clasifica y crea un Context Pack pequeño cuando corresponde
  -> carga el SKILL.md pertinente
  -> usa memoria/herramientas sólo si el runtime las expone
  -> verifica y responde
```

Codex recibe el Manager compacto de `codex/manager.template.md`. El overlay añade procedimientos y reglas; no modifica el binario, el modelo, los permisos ni los conectores instalados.

## 5. Noise Gate: el filtro antes de la memoria

El Noise Gate no es un programa ni un plugin. Es una **regla que el Manager sigue** antes de guardar algo en memoria. Su trabajo es responder una sola pregunta: *"Esto que pasó, ¿merece recordarse en la próxima sesión?"*

### Las 5 clases de interacción

Cada vez que el usuario escribe algo, el Manager lo clasifica en una de estas cinco categorías:

| Clase | ¿Qué es? | Ejemplo |
|-------|----------|---------|
| **instruction** | Una orden, decisión, corrección o descubrimiento | "Cambiá la fuente de datos a PostgreSQL" |
| **question** | Una pregunta o pedido de explicación | "¿Cómo se configura el rate limiting?" |
| **confirmation** | Un "sí", "ok", "dale", "aprobado" | "Sí, está bien" |
| **navigation** | Un pedido de mostrar, listar o inspeccionar | "Mostrame el archivo .env" |
| **noise** | Chatter, errores sin contexto, pegado accidental | "jaja", "no funcionó" (sin más datos) |

### El árbol de decisión

Solo las **instruction** pueden llegar a memoria, y ni siquiera todas. El Manager aplica este filtro:

```
Llega: "Cambiá la base de datos a PostgreSQL"
  → 1. Es instruction? → Sí
  → 2. Tiene valor futuro? → Sí (afecta toda la arquitectura)
  → 3. Es decisión durable? → Sí → GUARDAR como decision
  
Llega: "Probá con el puerto 3000"
  → 1. Es instruction? → Sí
  → 2. Tiene valor futuro? → No (es un intento, no una decisión)
  →    NO GUARDAR

Llega: "El bug era que faltaba el header X-Signature en el webhook"
  → 1. Es instruction? → Sí
  → 2. Tiene valor futuro? → Sí (causa raíz documentada)
  → 3. Es decisión durable? → No, pero es un bugfix con causa raíz
  →    GUARDAR como bugfix

Llega: "Sí, dale"
  → 1. Es instruction? → No, es confirmation → NO GUARDAR

Llega: "Mostrame los archivos del proyecto"
  → 1. Es instruction? → No, es navigation → NO GUARDAR
```

### Lo que pasa DESPUÉS del Noise Gate

Cuando el Noise Gate decide que algo **sí merece guardarse**, esto es lo que ocurre:

```
  Noise Gate dice: "Esto es guardable"
       │
       ▼
  El Manager arma una observación con estructura:
    {
      title: "Migración a PostgreSQL",
      type: "decision",
      topic_key: "database/choice-postgresql",
      content: "**What**: Cambiamos de MySQL a PostgreSQL
                **Why**: Necesitábamos funciones de array
                **Where**: prisma/schema.prisma"
    }
       │
       ▼
  Si existe Engram MCP (OpenCode):
    → mem_save() guarda la observación
    → Engram la indexa con ID único
    → Si hay conflicto con memoria anterior, pide revisión

  Si existe memoria nativa (Codex):
    → Se guarda en SQLite con FTS5
    → Disponible para futuras búsquedas

  Si no hay backend de memoria:
    → El Manager lo declara: "no hay memoria persistente disponible"
    → No inventa persistencia
```

El Noise Gate **no guarda nada por sí mismo**. Solo clasifica. La guardada la ejecuta el Manager llamando a `mem_save` (o equivalente) **solo si** el Noise Gate dio el visto bueno.

### ¿Qué se guarda exactamente?

| Situación | ¿Ruido o señal? | ¿Llega a memoria? |
|-----------|----------------|-------------------|
| "Cambiá la DB a PostgreSQL" | ✅ Señal — decisión arquitectónica | Sí, como `decision` |
| "El bug era X por Y en archivo Z" | ✅ Señal — bug con causa raíz | Sí, como `bugfix` |
| "A partir de ahora commits en español" | ✅ Señal — preferencia reusable | Sí, como `preference` |
| "La API rechaza montos con >2 decimales" | ✅ Señal — descubrimiento no obvio | Sí, como `discovery` |
| "¿Cómo se configura X?" | ❌ Ruido — pregunta sin decisión | No |
| "Sí, aprobado" | ❌ Ruido — confirmación | No |
| "Mostrame la carpeta src" | ❌ Ruido — navegación temporal | No |
| "jaja" | ❌ Ruido — chatter | No |

## 6. Memoria persistente: cómo aprende la herramienta

La memoria persistente es lo que separa una herramienta que arranca de cero cada sesión de una que **aprende con el tiempo**. Sin memoria, cada sesión es un "hola, ¿qué proyecto es este?". Con memoria, el tooling sabe qué decidiste, qué bugs ya resolviste, qué patrones preferís y qué descubriste que no es obvio.

### No es "guardar el chat"

La memoria persistente no guarda conversaciones enteras ni logs. Guarda **observaciones estructuradas** con una decisión o descubrimiento cada una. Es más parecido a un cuaderno de bitácora que a una grabación.

### Tipos de memoria

| Tipo | ¿Qué guarda? | Ejemplo |
|------|-------------|---------|
| **architecture** | Decisiones de diseño, tradeoffs aceptados | "Usamos PostgreSQL por las funciones de array" |
| **decision** | Cualquier decisión que afecta al proyecto | "Los commits van en español de ahora en más" |
| **bugfix** | Bug con causa raíz identificada | "El error era X por Y en archivo Z" |
| **discovery** | Algo no obvio que aprendiste | "La API rechaza montos con >2 decimales" |
| **preference** | Preferencia reusable del usuario | "Preferís pnpm sobre npm" |
| **pattern** | Patrón que estableciste y vale repetir | "Cada skill tiene frontmatter con name y description" |
| **config** | Cambio de configuración o entorno | "Node 22 rompe el test runner, usamos Node 20" |

Cada observación incluye: título, tipo, **What** (qué pasó), **Why** (por qué), **Where** (archivos afectados) y **Learned** (gotchas o lecciones). Con esa estructura, el Manager entiende no solo *qué* pasó, sino *por qué* y *dónde* — y puede aplicar ese aprendizaje en el futuro.

### Cómo se guarda (después del Noise Gate)

El flujo completo desde que el usuario escribe algo hasta que queda en memoria permanente:

```
Usuario escribe: "Cambiá la DB a PostgreSQL"
       │
       ▼
 ① Manager recibe el mensaje
       │
       ▼
 ② Noise Gate clasifica: instruction con valor futuro
       │
       ▼
 ③ Manager decide tipo: decision (es durable)
       │
       ▼
 ④ Manager arma la observación con título, tipo, contenido
       │
       ▼
 ⑤ Manager llama a mem_save()
       │
       ▼
 ⑥ El backend de memoria la almacena
    → Engram: asigna ID único + sync_id
    → SQLite: indexa con FTS5
       │
       ▼
 ⑦ (Opcional) Si hay conflicto con memoria anterior,
    el Manager revisa y decide si reemplazar
       │
       ▼
 ⑧ Listo. Esa memoria existe para futuras sesiones.
```

### Cómo se recupera (en cualquier momento, no solo entre sesiones)

La memoria se consulta **todo el tiempo**, no solo al arrancar una sesión. Cada vez que el Manager necesita contexto que no está en el prompt actual, busca:

```
En medio de una sesión: "¿Qué base de datos estamos usando?"
       │
       ▼
 ① Manager busca: mem_context() → sesiones recientes
       │
       ▼
 ② Si encuentra sesiones, las revisa
       │
       ▼
 ③ Si no encuentra, busca: mem_search("base de datos")
       │
       ▼
 ④ De los resultados, aplica F4C Selector:
    Rankea por relevancia (50%) + recencia (30%) + tipo (20%)
    Deduplica por topic_key
    Toma los top resultados
       │
       ▼
 ⑤ Responde con el contexto recuperado:
    "La última decisión fue migrar a PostgreSQL por las
     funciones de array. Está en prisma/schema.prisma."
```

También se busca **proactivamente**:
- Al empezar una tarea que puede haberse hecho antes, el Manager busca antes de actuar.
- Si el usuario menciona un tema del que no hay contexto, el Manager busca memoria.
- Si hay conflicto entre lo que dice el usuario y lo que dice la memoria, el Manager lo reporta.

### Cómo aprende la herramienta con el tiempo

Cada sesión que pasa, la memoria acumula decisiones, fixes y descubrimientos. Esto produce una curva de aprendizaje:

```
Sesión 1:   "¿Qué base de datos usamos?"  → "No hay memoria todavía"
Sesión 2:   "¿Qué base de datos usamos?"  → "Decidiste PostgreSQL, está en prisma/schema.prisma"
Sesión 10:  "Agregá una columna"           → el Manager ya sabe la DB, el ORM, la convención de nombres
Sesión 20:  El Manager responde antes de   → porque la memoria ya cubre la mayoría de las decisiones
            que preguntes
```

Cada vez que preguntaste "¿qué hicimos?" en este repositorio, el Manager buscó memoria de sesiones anteriores y respondió con el contexto exacto. Esa es la diferencia entre una herramienta que repite preguntas y una que **aprende**:

- **Sin memoria**: cada sesión empieza en cero. Preguntás lo mismo cada vez.
- **Con memoria**: las decisiones se acumulan. Con el tiempo, el Manager necesita menos preguntas porque ya sabe cómo trabajás.

### Ejemplo real de este repositorio

Este mismo README, los bugs fixeados, y las decisiones arquitectónicas de todo el desarrollo se guardaron usando este flujo. Hoy hay **379 observaciones** en **14 sesiones** a lo largo de **10 días**. Cada vez que preguntaste "¿qué hicimos?" el Manager buscó `mem_context()` y respondió con sesiones anteriores. Eso es el Noise Gate + memoria funcionando.

**Ver**: [`contrato completo de memoria`](contracts/memory-governance.md) y [`contrato del Noise Gate`](contracts/noise-gate.md) para las reglas exactas.

## 7. Tokens y contexto: hacer más con menos

Los runtimes tienen un límite de contexto (ventana de tokens). Si el Manager carga todo el proyecto, skills, memoria y documentación cada vez, ese límite se alcanza rápido y el modelo empieza a "olvidar" el principio de la conversación. Esta arquitectura ataca ese problema de dos maneras: **no cargar lo que no hace falta** y **estructurar lo que se carga para que ocupe menos**.

### Principio: carga diferida (lazy loading)

Nada se carga automáticamente. Skills, contratos, documentos largos — todo se carga **solo cuando el Manager decide que es relevante**:

```
¿Qué pasa si pregunto "cómo configuro la DB"?
  → Manager carga solo: contract/database.md, skill/sql-learning (1.2 KB)
  → No carga: README, contratos de seguridad, skills de frontend, PLAN.md

¿Qué pasa si pido "auditar accesibilidad"?
  → Manager carga solo: skill/web-design-guidelines, contract/accessibility
  → No carga: nada de DB, skills de BigQuery, scripts de instalación
```

El ahorro es enorme: skills individuales pesan ~2-5 KB. Cargar los 18 skills juntos serían ~70 KB innecesarios cada vez.

### Skills individuales (cada skill pesa ~2-5 KB)

Hay 18 skills, pero **nunca** se cargan todos juntos. Cada skill tiene un `description` con triggers. El Manager lee el description, y solo si coincide con la tarea carga el SKILL.md completo. Esto es equivalente a tener 18 manuales en un estante y agarrar solo el que necesitás.

### Context Packs (para trabajo amplio)

Cuando la tarea es grande (arquitectura, refactor multi-archivo, integración), el Manager arma un **Context Pack**: un JSON con los elementos necesarios, un presupuesto de tokens y exclusiones justificadas:

```json
{
  "intent": "Agregar una columna a la tabla users",
  "maxTokens": 4000,
  "items": [
    { "kind": "file", "ref": "prisma/schema.prisma", "reason": "schema actual" },
    { "kind": "file", "ref": "contracts/memory-governance.md", "reason": "no guardar secretos" }
  ],
  "excluded": [
    { "kind": "dir", "ref": "skills/", "reason": "no necesito skills para esto" }
  ]
}
```

Esto evita que el Manager lea archivos innecesarios y garantiza que el presupuesto de tokens se use donde importa.

### token-budgeter

Un skill específico (`token-budgeter`) ayuda al Manager a:
1. Identificar archivos grandes que convendría mover a lazy loading
2. Estimar cuántos tokens consume cada archivo o skill
3. Sugerir qué documentación estable mover a docs/ (cargar solo cuando se pregunta por ella)

### El Noise Gate también ayuda a los tokens

Menos ruido en memoria = menos resultados que procesar en cada búsqueda = menos tokens gastados en filtrar basura. El Noise Gate no es solo para calidad de memoria — también es una optimización de tokens.

### F4C Selector: busca precisa

Cuando el Manager recupera memoria, usa el F4C Selector que rankea resultados por relevancia (50%), recencia (30%) y tipo (20%). Esto evita traer 20 resultados cuando 3 alcanzan. Top-k por defecto: 5 para preguntas simples, 10 para preguntas normales, 20 para arquitectura.

### Resumen del aporte

| Técnica | Aporte |
|---------|--------|
| Skills lazy-loaded | No se cargan ~70 KB de skills que no hacen falta |
| Context Packs | Lectura acotada a lo necesario, con presupuesto explícito |
| token-budgeter | Identifica qué mover a carga diferida |
| Noise Gate | Menos ruido en memoria = menos tokens en búsquedas |
| F4C Selector | Top-k acotado, no trae toda la base de memoria |
| Session Summary | Resumen compacto en vez de dump de la sesión |

El resultado: sesiones más largas, menos "olvidos" del modelo, respuestas más rápidas y menos costo de API. No es magia — es **no quemar tokens en lo que no importa**.

## 8. Qué NO hace ni instala

- No instala OpenCode, Codex, Node.js, Git ni `pnpm`.
- No autentica cuentas ni configura API keys.
- No instala Engram, MCP servers, Graphify, Ponytail, modelos, plugins o subagentes.
- No crea una base de memoria por sí mismo.
- No modifica ejecutables ni directorios administrados por actualizadores.
- No garantiza que una integración externa esté disponible; `doctor` valida el overlay local, no servicios de terceros.
- No activa automáticamente un overlay ya abierto: reinicia el runtime después de instalar.
- No usa los perfiles del manifiesto para la instalación global. Los perfiles son paquetes/staging del repositorio; los comandos `codex:*` y `opencode:*` son los instaladores reales.

## 9. Estado actual

| Área | Estado verificable |
|---|---|
| Codex: install / doctor / rollback | Implementado y probado |
| OpenCode: install / doctor / rollback | Implementado y probado |
| Backup antes de sobrescribir | Implementado |
| Registro con 18 skills y rutas destino | Generado durante la instalación |
| Tests Node y CI | `pnpm test:all` |
| Integraciones externas | Opcionales; no instaladas por este kit |

## 10. Ponytail

Ponytail es una guía contra la sobreingeniería. El kit incluye el contrato y criterios, pero no instala un plugin Ponytail.

## 11. Cómo validar

```bash
pnpm doctor
pnpm test:all
pnpm codex:doctor --target ~/.codex
pnpm opencode:doctor --target ~/.config/opencode
```

`doctor` del repositorio valida prerrequisitos y estructura. Los doctors de runtime validan los archivos instalados y el recibo de instalación. Ninguno prueba autenticación o disponibilidad de servicios externos.

## 12. Rollback

```bash
pnpm codex:rollback:dry-run --target ~/.codex
pnpm codex:rollback --target ~/.codex
pnpm opencode:rollback:dry-run --target ~/.config/opencode
pnpm opencode:rollback --target ~/.config/opencode
```

Rollback restaura sólo los elementos respaldados y elimina sólo los que la última instalación creó. No toca otros archivos del usuario.

## 13. Documentación

- [Arquitectura maestra](arquitectura.md)
- [QuickStart Codex](QUICKSTART_CODEX.md)
- [QuickStart OpenCode](QUICKSTART_OPENCODE.md)
- [Destinos de instalación](docs/installation-targets.md)
- [Seguridad y sanitización](docs/safety-and-sanitization.md)

## Licencia

MIT. Consulta [LICENSE](LICENSE).
