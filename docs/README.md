# Mobile Docs Index

Documentacion de referencia para `pokemon-stadium-lite-app`.

Usa este indice como punto de entrada rapido.

## Documentos disponibles

- [mobile-flows.md](./mobile-flows.md)
  Referencia funcional de flujos clave, estados esperados y eventos backend involucrados.

- [mobile-implementation-reference.md](./mobile-implementation-reference.md)
  Mapa de arquitectura mobile, ownership de archivos y reglas operativas de sesion, socket y battle.

- [mobile-qa-checklist.md](./mobile-qa-checklist.md)
  Checklist ejecutable para QA manual en Android con expected results.

- [ui-ux-improvement-proposal.md](./ui-ux-improvement-proposal.md)
  Propuesta de mejora visual y de experiencia de usuario alineada con el lenguaje actual de la app.

## Cuando usar cada documento

- Si vas a probar una historia end to end: `mobile-flows.md`
- Si vas a tocar codigo o refactorizar: `mobile-implementation-reference.md`
- Si vas a correr smoke, regression o validar un release: `mobile-qa-checklist.md`
- Si vas a abrir trabajo de producto, diseno o polish visual: `ui-ux-improvement-proposal.md`

## Referencia externa importante

El contrato de Socket.IO y el comportamiento oficial del backend viven en:

- `pokemon-stadium-lite-backend/docs/socket-contracts.md`
- `pokemon-stadium-lite-backend/README.md`

La documentacion mobile de este repo asume ese contrato como dependencia.
