# CONTEXT — claude-jumper

## Acción pendiente (Justino)
- **Revisar el README renderizado y pasar el repo a público.** Hoy es privado (2026-09-23):
  `gh repo edit devsart95/claude-jumper --visibility public --accept-visibility-change-consequences`

## Estado (2026-09-23)
- GitHub `devsart95/claude-jumper`, rama `main`, **privado**. Sin releases ni binarios publicados:
  quien lo quiera compila con `./scripts/build-app.sh`.
- Sin deploy: es una app local de macOS.

## Config que el git no ve
- `UserDefaults` del dominio `py.devsar.claudejumper`: `signature` (handle en la pista; vacío lo
  oculta; sin setear → `@rojassartorio`), `gameTheme` (`lightBackground` | `darkBackground`),
  `highScore`.
- Firma: `CODE_SIGN_IDENTITY` pisa la identidad. Sin ella, el script toma la primera
  *Apple Development* del llavero y, si no hay, firma ad-hoc. Con la ad-hoc el requisito
  designado es el `cdhash`, así que macOS vuelve a pedir Accesibilidad en cada build.

## Decisiones
- **Sprite e ícono de Icons8 van en el repo con crédito** (decisión de Justino, 2026-09-23). La
  licencia gratuita de Icons8 prohíbe distribuirlos como archivo suelto; quedan fuera de MIT y el
  README lo dice. Si Icons8 reclama: reemplazar por una mascota propia en `MascotNode`.
- Proyecto de fan: disclaimer de no afiliación con Anthropic en el README. El nombre usa la marca
  «Claude».
- README en inglés; la UI del juego sigue en español (el README trae un mini glosario).
- Heros del README (`docs/hero-{dark,light}.png`): la pista es una captura real con alfa
  (`screencapture -l <windowID> -o`, saltando con el botón «Saltar ahora» por AX, no con la barra
  espaciadora sintética) compuesta sobre un fondo HTML de editor y terminal renderizado a 2x.
  Rehacerlos si cambia la UI de la pista.

## Abierto
- **El tema cambió solo** durante ráfagas de capturas con `osascript … key code 49` (el guardado
  pasó de `darkBackground` a `lightBackground` sin tocar el botón). Aislado (un espacio, con la
  app o Terminal al frente) no se reprodujo. Con clicks por AX no pasa.
- Sin tests. La banda `herramienta` pide tests de dominio: la física de `GameScene.Geometry`
  (salto, separación de obstáculos) es lo primero. Hoy no hay test target: `swift test` no corre
  nada.
