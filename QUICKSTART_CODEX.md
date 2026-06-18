# QuickStart — Codex Runtime

5 pasos para tener el Runtime Kit en Codex.

## 1. Clonar el repositorio

```bash
git clone https://github.com/harrysxavio/proyecto-opencode-mem.git
cd proyecto-opencode-mem
pnpm install
```

## 2. Validar el kit

```bash
pnpm validate
pnpm test:codex
```

## 3. Dry-run del overlay

```bash
pnpm codex:install:dry-run --target ~/.codex
```

## 4. Instalar el overlay

```bash
pnpm codex:install --target ~/.codex
```

## 5. Validar la instalación

```bash
pnpm codex:doctor --target ~/.codex
```

## Rollback si es necesario

```bash
pnpm codex:rollback --target ~/.codex
```

---

**Ver también**: [`docs/codex/getting-started.md`](docs/codex/getting-started.md), [`ARCHITECTURE.md`](ARCHITECTURE.md)
