# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack

Delegado: Swift 6, SwiftUI/AppKit y SpriteKit para una app nativa de macOS.

## Users

Usuario de macOS que quiere un juego ambiental visible mientras trabaja en otras aplicaciones.

## Product Purpose

Convertir un pequeño objeto flotante en un endless runner: la mascota salta obstáculos mientras el usuario sigue trabajando.

## Positioning

El juego vive sobre el escritorio y responde a la barra espaciadora global sin quitar el foco a la aplicación activa.

## Operating Context

Se ejecuta como aplicación normal de macOS: aparece en el Dock y tiene controles en la barra superior. La pista queda siempre visible sobre las demás ventanas, incluidas las apps en pantalla completa.

## Capabilities and Constraints

- Barra espaciadora global mientras la app está ejecutándose.
- La aplicación observada conserva el evento de teclado.
- Ventana transparente, flotante y arrastrable.
- Salto, obstáculos, colisiones, puntaje y récord local.
- El monitoreo global puede requerir autorización de macOS.
- Alcance inicial: macOS Apple Silicon e Intel, macOS 14 o posterior.

## Brand Commitments

Nombre: Claude Jumper. La mascota es el sprite pixel de Icons8 con anteojos (estilo Clawd): no es original ni está bajo MIT, y exige crédito a Icons8. Proyecto de fan, sin afiliación con Anthropic.

## Evidence on Hand

`Assets/clawd-sunglasses.png` y `Assets/ClaudeJumper.icns`, de Icons8 (licencia de Icons8, crédito obligatorio). Heros del README en `docs/`. No inventar afiliación con Anthropic.

## Product Principles

- Nunca interrumpir el trabajo principal del usuario.
- Entender el estado del juego de un vistazo.
- Mantener controles y configuración al mínimo.
- Sentirse nativo de macOS y liviano.

## Accessibility & Inclusion

Ofrecer pausa y salida desde un menú accesible; el juego no debe capturar ni bloquear la escritura en otras apps.
