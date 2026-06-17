# Destinos de instalación

> OpenCode Kit puede aplicarse a diferentes entornos. Cada uno tiene su propia
> forma de cargar la configuración. Esta guía explica cada destino.

---

## ¿Qué significa "destino de instalación"?

OpenCode se puede usar de varias formas:

- Como **CLI** (interfaz de línea de comandos).
- Como **extensión de VS Code**.
- Como **configuración local** en un proyecto.
- A través de **Cursor** u otros editores.

Cada destino espera los archivos de configuración en una carpeta distinta.
El kit funciona igual para todos — solo cambiá dónde copiás los archivos.

---

## OpenCode CLI

> El destino principal. OpenCode CLI lee la configuración desde `~/.config/opencode/`.

### Cómo se carga

OpenCode CLI busca estos archivos automáticamente al arrancar:

| Archivo | Propósito |
|---|---|
| `~/.config/opencode/opencode.json` | Configuración principal |
| `~/.config/opencode/AGENTS.md` | Directivas de agentes y personalidad |
| `~/.config/opencode/.opencode/` | Configuración avanzada (skills, plugins) |

### Cómo aplicar el kit

```bash
# 1. Simulá primero
pnpm install:dry-run --profile minimal

# 2. Copiá los archivos relevantes a ~/.config/opencode/
#    (manual — el kit no copia archivos automáticamente)
```

### Verificación

```bash
# Después de copiar, abrí OpenCode CLI y verificá que cargue la configuración
opencode --version

# Si hay errores de configuración, OpenCode los muestra al arrancar
```

---

## VS Code Extension

> OpenCode también funciona como extensión de VS Code. La configuración
> está en la misma carpeta que CLI: `~/.config/opencode/`.

### Cómo se carga

La extensión de VS Code lee los mismos archivos que la CLI:

| Archivo | Ruta |
|---|---|
| Configuración | `~/.config/opencode/opencode.json` |
| Agentes | `~/.config/opencode/AGENTS.md` |

### Diferencia con CLI

No hay diferencia en la configuración. La extensión de VS Code y la CLI
comparten la misma carpeta de configuración. Lo que configures para uno
funciona para el otro.

### Cómo aplicar el kit

```bash
# Es el mismo proceso que para CLI
# 1. Simulá
pnpm install:dry-run --profile full

# 2. Copiá los archivos a ~/.config/opencode/
```

---

## Cursor

> Cursor tiene su propia carpeta de configuración: `~/.cursor/`.

### Cómo se carga

| Archivo | Ruta |
|---|---|
| Configuración | `~/.cursor/opencode.json` (puede requerir adaptación) |
| Agentes | `~/.cursor/AGENTS.md` |

### Diferencias con OpenCode CLI

Cursor puede tener limitaciones en:

- **Plugins** — Algunos plugins de OpenCode (como Engram) pueden no funcionar
  en Cursor.
- **Skills** — La carga de skills puede diferir.
- **Agentes SDD** — Los templates de agentes deberían funcionar, pero probalos.

### Cómo aplicar el kit

```bash
# 1. Simulá
pnpm install:dry-run --profile minimal

# 2. Copiá los archivos adaptados a ~/.cursor/

# 3. Verificá la compatibilidad de plugins
#    Si usás Engram, necesitás la configuración específica de Cursor
```

---

## Proyecto local

> OpenCode soporta configuración por proyecto usando una carpeta `.opencode/`
> en la raíz del proyecto.

### Cómo se carga

| Archivo | Ruta |
|---|---|
| Configuración | `.opencode/opencode.json` |
| Agentes | `.opencode/AGENTS.md` |
| Skills | `.opencode/skills/` |

### Ventajas

- **Aislado** — La configuración no afecta otros proyectos.
- **Versionable** — Podés commitear la configuración en el repo del proyecto.
- **Portable** — Otros desarrolladores del proyecto tienen la misma configuración.

### Cómo aplicar el kit

```bash
# 1. En la raíz de tu proyecto, creá la carpeta
mkdir -p .opencode

# 2. Simulá primero
pnpm install:dry-run --profile sdd

# 3. Copiá los archivos relevantes a .opencode/
```

### Ejemplo

```
mi-proyecto/
├── .opencode/
│   ├── opencode.json
│   ├── AGENTS.md
│   ├── skills/
│   └── plugins/
├── src/
├── package.json
└── README.md
```

---

## Direct agent

> OpenCode también se puede configurar apuntando a cualquier carpeta con una
> variable de entorno.

### Cómo funciona

```bash
# Configurá la variable de entorno para apuntar a tu carpeta
export OPENCODE_CONFIG_DIR=/ruta/a/mi-config

# Arrancá OpenCode — va a leer la configuración de esa carpeta
opencode
```

### Cuándo usarlo

- Tenés múltiples configuraciones y querés cambiar entre ellas.
- Querés aislar la configuración de prueba de la de producción.
- Estás desarrollando el kit y querés probar cambios sin tocar la
  configuración principal.

### Cómo aplicar el kit

```bash
# 1. Copiá los archivos a una carpeta, por ejemplo:
cp -r opencode-kit/templates /ruta/mi-config/

# 2. Configurá la variable
export OPENCODE_CONFIG_DIR=/ruta/mi-config

# 3. Arrancá OpenCode
opencode
```

---

## Comparativa rápida

| Destino | Carpeta | Configuración compartida con | Plugins compatibles |
|---|---|---|---|
| CLI | `~/.config/opencode/` | VS Code Extension | Todos |
| VS Code | `~/.config/opencode/` | CLI | Todos |
| Cursor | `~/.cursor/` | — | Parcial |
| Proyecto local | `.opencode/` | — | Todos (relativos) |
| Direct agent | `$OPENCODE_CONFIG_DIR` | — | Todos |

---

## Buenas prácticas

1. **Siempre simulá primero** con `install:dry-run` antes de copiar archivos.
2. **Usá la configuración local (`.opencode/`)** para proyectos compartidos.
3. **Usá `~/.config/opencode/`** para tu configuración personal global.
4. **Probá un perfil chico primero** (minimal) antes de escalar a full.
5. **Si usás Cursor**, verificá que los plugins que necesitás sean compatibles.

---

*¿Usás OpenCode en otro entorno que no está acá? Contanos en GitHub Issues.*
