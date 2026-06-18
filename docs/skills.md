# Skills

`skills/` contiene 18 skills sanitizados y portables. Cada uno tiene un `SKILL.md` con nombre, trigger y procedimiento.

Los instaladores los copian a `<target>/skills/opencode-runtime-kit/` y generan `.atl/skill-registry.md` desde su frontmatter. Agregar una skill nueva requiere actualizar la lista de instalación y pruebas; el doctor exige que todas las entradas del registro existan.

Una skill es una instrucción: no instala plugins, servicios ni credenciales externas.