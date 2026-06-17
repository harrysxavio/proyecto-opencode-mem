# Guía de inicio rápido

> Esta guía te lleva de cero a tener tu primer perfil de OpenCode funcionando
> en **menos de 10 minutos**. No necesitás experiencia previa con OpenCode.

---

## ¿Qué vamos a hacer?

Vamos a:

1. Instalar las herramientas necesarias.
2. Clonar el kit.
3. Elegir un perfil.
4. Validar que todo funcione.
5. Probar una instalación simulada.
6. Copiar los archivos a tu configuración de OpenCode (opcional).

---

## Paso 1: Instalá las herramientas necesarias

OpenCode Kit necesita tres herramientas. Ya las tenés? Pasá al paso 2.

### Node.js (20.x)

```bash
node --version
# Debería mostrar: v20.x.x
```

Si no lo tenés, descargalo de [nodejs.org](https://nodejs.org/).

### pnpm (9.x)

```bash
pnpm --version
# Debería mostrar: 9.x.x
```

Si no lo tenés, instalalo con:

```bash
corepack enable
corepack prepare pnpm@latest --activate
```

### Git (2.x)

```bash
git --version
# Debería mostrar: git 2.x
```

Si no lo tenés, descargalo de [git-scm.com](https://git-scm.com/).

---

## Paso 2: Cloná el repositorio

```bash
git clone https://github.com/harrysxavio/proyecto-opencode-mem.git
cd proyecto-opencode-mem
```

---

## Paso 3: Instalá las dependencias

```bash
pnpm install
```

Esto instala las dependencias necesarias para los scripts de validación y
utilidades del kit.

---

## Paso 4: Conocé los perfiles

OpenCode Kit tiene 7 perfiles. Si es tu primera vez, empezá con **minimal**:

| Perfil | Componentes | Para qué |
|---|---|---|
| **minimal** | Manager básico + Ponytail + sanitize | Arrancar |
| **agents** | minimal + 10 agentes SDD | Usar SDD |
| **sdd** | agents + pipeline SDD completo | Desarrollo estructurado |
| **memory-enabled** | sdd + Engram + memoria | Proyectos grandes |
| **ponytail-code-gate** | Ponytail avanzado + review | Código mínimo |
| **gentle-alignment** | gentle-ai alignment | Control de IA |
| **full** | Todos los componentes | La configuración completa |

> 📘 La guía completa de perfiles está en [`profiles.md`](profiles.md).

---

## Paso 5: Validá el kit

```bash
pnpm validate
```

Este comando verifica:

- ✅ Que todos los directorios existan.
- ✅ Que todos los templates estén en su lugar.
- ✅ Que todos los scripts requeridos existan.
- ✅ Que el manifest tenga los perfiles correctos.

Deberías ver un mensaje de `PASS` o `PASS WITH WARNINGS`.

---

## Paso 6: Revisá la salud del entorno

```bash
pnpm doctor
```

Este comando diagnostica:

- ✅ Versión de Node.js (mínimo 20.x).
- ✅ Versión de pnpm (mínimo 9.x).
- ✅ Versión de Git (mínimo 2.x).
- ✅ Disco disponible.
- ✅ Estado del repositorio.

---

## Paso 7: Verificá que no hay secretos

```bash
pnpm sanitize:check
```

Este comando busca:

- 🔍 Caminos absolutos del sistema (como `{KIT_ROOT}`).
- 🔍 Tokens y API keys hardcodeadas.
- 🔍 Archivos `.env` que deberían estar en `.gitignore`.
- 🔍 Secretos o credenciales.

> ⚠️ Si encuentra algo, **no sigas** hasta resolverlo. La sanitización es
> obligatoria antes de copiar archivos a tu configuración.

---

## Paso 8: Probá una instalación simulada

```bash
pnpm install:dry-run --profile minimal
```

Esto te muestra:

- 📋 Qué archivos se copiarían.
- 📋 Adónde irían.
- 📋 Qué perfiles estarían activos.

Ningún archivo se modifica realmente. Es una simulación.

También podés probar con otros perfiles:

```bash
pnpm install:dry-run --profile agents
pnpm install:dry-run --profile full
```

---

## Paso 9: Explorá los archivos (opcional)

Antes de copiar nada, explorá lo que contiene el kit:

| Archivo | Propósito |
|---|---|
| `README.md` | Documentación principal |
| `opencode-kit.manifest.json` | Catálogo de componentes y perfiles |
| `templates/opencode.example.jsonc` | Configuración de ejemplo para OpenCode |
| `templates/AGENTS.example.md` | Configuración de agentes de ejemplo |
| `templates/env.example` | Variables de entorno de ejemplo |
| `agents/manager/manager.template.md` | Template del Manager |
| `agents/sdd/*.template.md` | Templates de los 10 agentes SDD |
| `plugins/engram.template.ts` | Template del plugin Engram |
| `scripts/` | Scripts de validación y utilidades |

---

## Paso 10: Copiá los archivos a tu configuración (opcional)

Cuando estés listo para usar el kit en tu OpenCode:

```bash
# Conocé primero qué se copiaría
pnpm install:dry-run --profile minimal

# Si te parece bien, copiá los archivos manualmente
# (el kit no tiene un comando "install" automático para no tocar tu sistema)
```

> 💡 Los perfiles `agents`, `sdd`, `memory-enabled`, y `full` agregan más archivos.
> Siempre usá `install:dry-run` primero para ver el alcance.

---

## Próximos pasos

Una vez que tengas el kit funcionando:

1. **Leé [`profiles.md`](profiles.md)** para entender qué más podés agregar.
2. **Leé [`installation-targets.md`](installation-targets.md)** si usás VS Code
   o Cursor en vez de la CLI de OpenCode.
3. **Leé [`safety-and-sanitization.md`](safety-and-sanitization.md)** para entender
   las buenas prácticas de seguridad.
4. **Leé [`phase-roadmap.md`](phase-roadmap.md)** para ver hacia dónde va el proyecto.

---

## Solución de problemas comunes

### `pnpm validate` falla con "missing directory"

```bash
# Revisá que los directorios existen
ls docs/ agents/ scripts/ templates/ tests/

# Si falta alguno, crealo
mkdir -p docs agents/sdd scripts templates tests/unit
```

### `pnpm doctor` dice "Node.js not found"

Node.js no está instalado o no está en tu PATH. Instalalo desde
[nodejs.org](https://nodejs.org/).

### `sanitize:check` encuentra caminos absolutos

Ejecutá el script para reemplazar los placeholders:

```bash
# El script mismo te guía
pnpm sanitize:check
```

### No sé qué perfil elegir

Empezá con `minimal`. Podés cambiarlo después. Los perfiles son acumulativos:
cada perfil más alto incluye todo lo del anterior.

---

## Resumen

```bash
# En 10 comandos
git clone https://github.com/harrysxavio/proyecto-opencode-mem.git
cd proyecto-opencode-mem
pnpm install
pnpm validate
pnpm doctor
pnpm sanitize:check
pnpm install:dry-run --profile minimal
# Explorá los archivos
# Copiálos a tu configuración (opcional)
# Arrancá OpenCode
```

---

*¿Alguna pregunta? Abrí un issue en GitHub o consultá la [FAQ](../README.md#faq).*
