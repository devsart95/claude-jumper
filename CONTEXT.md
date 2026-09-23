# CONTEXT — claude-jumper

## Acción pendiente (Justino)
- **Jugar una ronda con la Mac desbloqueada** (saltar, chocar, minimizar y volver a mostrar,
  arrastrar) y recién ahí pasar el repo a público. Hoy es privado (2026-09-23):
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
- README en inglés y sólo sobre el juego: sin grabación, configuración ni estructura del repo
  (pedido de Justino, 2026-09-23). La UI del juego sigue en español.
- La física vive en `RunnerPhysics` (sin SpriteKit) y sus reglas son tests (`swift test`): el salto
  llega a 125 pt a cualquier fps (integración exacta; la Euler anterior daba 115–122 pt) y cada
  obstáculo deja ≥ 0,3 s de ventana a la velocidad inicial. Tocar gravedad, alturas, hitboxes o la
  separación = correr los tests.
- **Obstáculos por distancia, no por tiempo.** Cada uno tiene su `mark` (scroll en el que entra) y
  el siguiente se ubica para llegar a la mascota `arrivalGap` después, contando la aceleración: por
  tiempo, los primeros 16 s llegaban a 0,84–0,92 s en vez de 1 s. La regla es el peor caso: aun
  saltando el primero en el último momento válido, se aterriza ≥ `timingMargin` (0,2 s) antes del
  último momento para saltar el siguiente. Separación 0,94–1,47 s, media 1,20 s (igual ritmo que el
  diseño original).
- El pitido de choque lo pone la ventana (`GameScene.onGameOver`); la escena recibe tema y
  `UserDefaults` por init, así los tests no pitan ni escriben el récord real.
- Heros del README (`docs/hero-{dark,light}.png`): la pista es una captura real con alfa
  (`screencapture -l <windowID> -o`, saltando con el botón «Saltar ahora» por AX, no con la barra
  espaciadora sintética) compuesta sobre un fondo HTML de editor y terminal renderizado a 2x.
  Rehacerlos si cambia la UI de la pista.

## Abierto
- **El tema cambió solo** durante ráfagas de capturas con `osascript … key code 49` (el guardado
  pasó de `darkBackground` a `lightBackground` sin tocar el botón). Aislado (un espacio, con la
  app o Terminal al frente) no se reprodujo. Con clicks por AX no pasa.
- Dificultad: la velocidad tope llega a los 16 s y después el juego no cambia; como el salto dura
  siempre 0,80 s, la ventana para saltar se agranda con la velocidad. Es decisión de diseño.
