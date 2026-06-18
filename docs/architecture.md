# Architecture

La fuente de verdad es [`../arquitectura.md`](../arquitectura.md).

El proyecto separa contratos portables (`contracts/`), skills lazy-loaded (`skills/`) y adaptadores reales (`opencode/`, `codex/`). Los instaladores copian sólo overlays de usuario; no copian datos privados ni modifican binarios.