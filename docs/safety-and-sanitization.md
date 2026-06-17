# Seguridad y sanitización

> OpenCode Kit incluye varias capas de seguridad para proteger tu configuración
> y tus datos. Esta guía explica cada una y cómo usarlas.

---

## Filosofía de seguridad

OpenCode Kit sigue estos principios:

1. **No tocar nada sin permiso.** Todos los comandos son dry-run por defecto.
2. **Verificar antes de copiar.** Los scripts de sanitización corren antes que
   cualquier instalación.
3. **Ser transparente.** Cada script muestra exactamente qué va a hacer.
4. **Poder volver atrás.** Siempre hay un comando de rollback disponible.

---

## Capas de seguridad

```
┌─────────────────────────────────────────────┐
│  Capa 1: Sanitize (busca secretos/paths)     │
│  Capa 2: Validate (verifica estructura)      │
│  Capa 3: Doctor (diagnostica el entorno)      │
│  Capa 4: Dry-run (simula antes de actuar)     │
│  Capa 5: Backup (guarda el estado anterior)   │
│  Capa 6: Rollback (restaura si algo falla)    │
└─────────────────────────────────────────────┘
```

---

## Capa 1: Sanitize check

> Busca secretos, caminos absolutos, tokens, y credenciales en los archivos.

```bash
pnpm sanitize:check
```

### Qué detecta

- 🔴 **Caminos absolutos del sistema** — como `{KIT_ROOT}\...` o `/home/usuario/`.
- 🔴 **Tokens y API keys** — patrones como tokens de OpenAI (prefijo `sk` + guión), tokens de GitHub (prefijo `ghp` + guión bajo), claves de AWS (prefijo `AK` + `IA`).
- 🔴 **Archivos `.env`** — que contienen variables de entorno con valores reales.
- 🔴 **URLs con credenciales** — como `https://usuario:password@example.com`.
- 🟡 **IPs internas** — direcciones privadas que no deberían estar en configuraciones públicas.
- 🟡 **Emails personales** — direcciones de correo que no sean de contacto público.

### Cómo interpretar los resultados

```
Sanitize Check — Results
────────────────────────
🔴 CRITICAL: path absoluto encontrado en README.md:42
→ Reemplazar ${KIT_ROOT} por el valor real

🟡 WARNING: Possible email in templates/opencode.example.jsonc:15
→ Verificar si es un email de ejemplo válido

✅ PASS: No secrets, no tokens, no .env files found
```

### Cómo resolver

Si `sanitize:check` encuentra algo:

1. Reemplazá el camino absoluto con un placeholder (`${KIT_ROOT}`, `${HOME}`).
2. Reemplazá tokens reales con `your-token-here` o similar.
3. Si es un falso positivo, agregá el patrón a la lista de exclusión del script.

### Reglas de exclusión

El script ignora por defecto:

- `node_modules/`
- `.git/`
- Archivos binarios (`.png`, `.jpg`, `.ico`)

Si necesitás excluir más patrones, editalos en `scripts/sanitize-check.mjs`.

---

## Capa 2: Validation

> Verifica que la estructura del kit esté completa y sea consistente.

```bash
pnpm validate
```

### Qué verifica

- ✅ Todos los directorios requeridos existen.
- ✅ Todos los templates están en su lugar.
- ✅ Todos los scripts requeridos existen.
- ✅ El manifest (`opencode-kit.manifest.json`) tiene los perfiles correctos.
- ✅ Cada perfil referencia componentes que existen.

### Cómo interpretar los resultados

```
Validate — Results
──────────────────
✅ 12/12 directories present
✅ 15/15 templates present
✅ 8/8 scripts present
✅ 7 profiles valid
✅ PASS
```

---

## Capa 3: Doctor

> Diagnóstico del entorno antes de cualquier operación.

```bash
pnpm doctor
```

### Qué verifica

- ✅ Node.js versión 20+.
- ✅ pnpm versión 9+.
- ✅ Git versión 2+.
- ✅ Disco disponible (mínimo 100MB).
- ✅ El repositorio está en estado limpio (sin cambios sin commit).
- ✅ Los permisos de archivos son correctos.

### Cuándo usarlo

- **Antes de la primera instalación** — para asegurarte de que todo está listo.
- **Cuando algo falla** — antes de buscar errores complejos, diagnosticá el entorno.
- **Periódicamente** — los cambios en el sistema pueden afectar el kit.

---

## Capa 4: Dry-run

> Simula una instalación sin modificar nada.

```bash
pnpm install:dry-run --profile minimal
```

### Qué muestra

- 📋 Lista de archivos que se copiarían.
- 📋 Ruta de destino.
- 📋 Perfiles que se activarían.
- 📋 Componentes incluidos.

### Por qué es importante

- **No hay sorpresas.** Sabés exactamente qué va a pasar antes de que pase.
- **Podés comparar** entre perfiles sin comprometer nada.
- **Es seguro.** Siempre.

---

## Capa 5: Backup

> Guarda una copia del estado actual antes de hacer cambios.

```bash
pnpm backup
```

### Qué guarda

- Copia de `opencode-kit.manifest.json`.
- Copia de la configuración actual de OpenCode (si existe en la ruta configurada).
- Fecha y hora del backup para identificación.

### Dónde se guarda

```
backups/
├── 2026-06-17_1430/
│   ├── opencode-kit.manifest.json
│   └── opencode-config-backup/
└── 2026-06-17_1500/
    └── ...
```

---

## Capa 6: Rollback

> Restaura el estado anterior si algo sale mal.

```bash
pnpm rollback
```

### Cómo funciona

1. Busca el último backup disponible.
2. Te muestra qué se va a restaurar.
3. Pide confirmación.
4. Restaura los archivos.
5. Verifica que la restauración sea correcta.

### Limitaciones

- Solo restaura archivos que fueron respaldados con `pnpm backup`.
- No puede restaurar cambios que no fueron respaldados.
- Si no hay backups, el comando avisa y no hace nada.

---

## Buenas prácticas de seguridad

### Hacé siempre

1. **Corré `pnpm doctor` al empezar** — conocé el estado del entorno.
2. **Corré `pnpm sanitize:check` antes de distribuir** — no compartas secretos.
3. **Usá `install:dry-run` siempre primero** — nunca copies archivos sin simulacro.
4. **Hacé backup antes de cambios grandes** — `pnpm backup` es rápido.
5. **Verificá los archivos después de copiarlos** — abrí OpenCode y confirmá que
   la configuración cargue.

### No hagas nunca

1. ❌ No comitees archivos `.env` con valores reales.
2. ❌ No compartas caminos absolutos de tu máquina.
3. ❌ No uses el kit en una máquina que no te pertenece sin sanitizar antes.
4. ❌ No ignores advertencias de `sanitize:check` sin verificarlas.

### Checklist pre-instalación

- [ ] `pnpm doctor` — entorno saludable.
- [ ] `pnpm validate` — estructura correcta.
- [ ] `pnpm sanitize:check` — sin secretos ni caminos absolutos.
- [ ] `pnpm install:dry-run --profile <perfil>` — simulación exitosa.
- [ ] Backup de configuración actual (opcional pero recomendado).

---

## Manejo de secretos

### Qué es un secreto

En el contexto del kit, un secreto es cualquier valor que no debería estar en
un archivo de configuración pública:

- API keys (ej. tokens de OpenAI con prefijo `sk` y guión; tokens de Anthropic).
- Tokens de acceso (ej. tokens de GitHub con prefijo `ghp` o `gho` + guión bajo).
- Contraseñas.
- Certificados privados.
- URLs con credenciales.

### Cómo manejar secretos

1. **Usá variables de entorno.** En lugar de hardcodear un token, usá
   `process.env.MI_TOKEN`.
2. **Usá el archivo `env.example`.** El template incluye un archivo de ejemplo
   con los nombres de las variables pero sin valores.
3. **Agregá `.env` a `.gitignore`.** Nunca comitees archivos con valores reales.
4. **Usá un gestor de secretos** (como 1Password, Bitwarden, o GitHub Secrets)
   para entornos compartidos.

### Ejemplo

```jsonc
// ❌ MAL: Token hardcodeado
{
  "apiKey": "${OPENCODE_API_KEY}"
}

// ✅ BIEN: Token desde variable de entorno
{
  "apiKey": "${OPENCODE_API_KEY}"
}
```

---

## Resumen de comandos

| Comando | Propósito | Cuándo usarlo |
|---|---|---|
| `pnpm doctor` | Diagnosticar entorno | Al empezar |
| `pnpm validate` | Validar estructura | Después de cambios |
| `pnpm sanitize:check` | Buscar secretos/paths | Antes de distribuir |
| `pnpm install:dry-run` | Simular instalación | Antes de copiar archivos |
| `pnpm backup` | Respaldar estado actual | Antes de cambios grandes |
| `pnpm rollback` | Restaurar backup | Si algo sale mal |

---

*¿Encontraste un problema de seguridad? Abrí un issue en GitHub.*
