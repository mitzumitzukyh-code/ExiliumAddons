# PROMPT — Sistema Multi-Agente de Contenido
# Pegar esto en Windsurf Cascade con Claude Opus al inicio de cada sesión

---

Lee el archivo `content-agents/SKILL.md` completo antes de hacer cualquier cosa.
Ese archivo es la fuente de verdad del proyecto. Contiene la arquitectura,
el stack, la lógica de cada agente, las reglas de versionado y el historial
de lo que se ha hecho. No asumas nada que no esté ahí.

Después de leerlo:

1. Revisa el CHANGELOG al final del SKILL.md para saber en qué versión
   estamos y qué se hizo en sesiones anteriores.

2. Revisa las Notas de Implementación para no repetir errores conocidos.

3. Sigue el Orden de construcción que dice la Skill:
   - Primero ejecuta `bash setup.sh` para crear los 6 namespaces KV
   - Luego ejecuta `node inject-kv-ids.js` para inyectar los IDs
   - Construye los Workers en el orden que indica la Skill
   - Construye el Dashboard al principio para poder ver el estado
   - Al terminar cada Worker, pruébalo antes de continuar con el siguiente

4. Cuando termines TODA la construcción, ejecuta obligatoriamente
   los 7 tests de integración que están en la sección
   "FASE FINAL: Pruebas de Integración" del SKILL.md.
   No des el proyecto como terminado si algún test falla.

5. Al terminar esta sesión de trabajo:
   - Incrementa la versión del SKILL.md según las reglas de versionado
   - Actualiza la fecha
   - Agrega una entrada al CHANGELOG con todo lo que hiciste,
     los archivos que creaste o modificaste, y cualquier problema
     que encontraste y cómo lo resolviste
   - Si descubriste algo nuevo sobre Cloudflare Workers, KV o AI,
     agrégalo en las Notas de Implementación

El proyecto usa exclusivamente Cloudflare Workers + KV + AI + Pages.
Sin APIs externas de pago. Sin servidores propios. Sin npm pesado.
Todo debe funcionar en el free tier de Cloudflare.
