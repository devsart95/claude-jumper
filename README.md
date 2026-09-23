<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/hero-dark.png">
  <img alt="Claude Jumper: a pixel mascot jumping over obstacles on a transparent track that floats over a code editor and a terminal" src="docs/hero-light.png" width="100%">
</picture>

# Claude Jumper

An endless runner that lives on top of your macOS desktop.

Press <kbd>Space</kbd> in any app (your editor, your terminal, a fullscreen video) and the little guy jumps.<br>
It's Chrome's offline dino, but native, and it floats above every window without taking focus.

Best played while Claude is down or the API returns `529 overloaded_error`. You were going to wait anyway.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111?logo=apple&logoColor=white)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)
![SpriteKit](https://img.shields.io/badge/engine-SpriteKit-D97757)
![Dependencies: 0](https://img.shields.io/badge/dependencies-0-3fb950)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)

</div>

## Features

- The space bar works from any app. Claude Jumper watches for the key without swallowing it, so the app you're typing in still gets every keystroke.
- Clicks pass through the track to whatever is behind it. Only the small control bar takes the mouse.
- The track sits at the status bar window level, so it stays visible over fullscreen apps and on every Space.
- Two themes, for light and dark wallpapers. The window stays fully transparent in both, and the app remembers your choice.
- Recording mode hides the controls, so an OBS capture shows only the game.
- The high score is stored locally. There are no accounts and nothing goes over the network.
- No dependencies beyond AppKit, SpriteKit and SwiftPM: about 850 lines of Swift, and no `.xcodeproj`.

## Quick start

You need macOS 14 (Sonoma) or later, and Xcode 16 or later for the Swift 6 toolchain.

```bash
git clone https://github.com/devsart95/claude-jumper.git
cd claude-jumper
./scripts/build-app.sh
open "dist/Claude Jumper.app"
```

On first launch macOS asks for Accessibility permission, which the global key monitor needs. You can change it later in
System Settings > Privacy & Security > Accessibility.

> [!TIP]
> `build-app.sh` signs with your first Apple Development identity, or ad-hoc if you don't have one. An ad-hoc build loses
> the Accessibility grant every time you rebuild. To use a specific identity:
> `CODE_SIGN_IDENTITY="Apple Development: you@example.com (TEAMID)" ./scripts/build-app.sh`

## Controls

| Input | Action |
|---|---|
| <kbd>Space</kbd> | Start, jump, resume or retry, from any app |
| Red button | Quit |
| Yellow button | Hide the track (bring it back from the menu bar) |
| Blue arrow | Jump, if you'd rather click |
| Blue sun or moon | Switch between the light and dark themes |
| Striped handle | Drag to move the track |
| Menu bar icon (a running figure) | Show, recording mode, pause, theme, reset high score, quit |

The in-game text is in Spanish. A pocket dictionary:

| On screen | Means |
|---|---|
| `ESPACIO PARA SALTAR` | press space to jump |
| `PAUSA · ESPACIO PARA SEGUIR` | paused, space to continue |
| `OUCH · ESPACIO PARA REINTENTAR` | you crashed, space to retry |
| `RÉCORD` | high score |

## Configuration

Settings live in `UserDefaults` under `py.devsar.claudejumper`:

```bash
# Put your own handle on the track (an empty string hides it)
defaults write py.devsar.claudejumper signature "@you"

# Start in a specific theme: lightBackground | darkBackground
defaults write py.devsar.claudejumper gameTheme lightBackground
```

The high score is stored as `highScore`. Resetting it from the menu is easier than `defaults delete`.

## The physics, for nerds

The jump height comes from projectile motion:

```swift
// v = √(2gh). This guarantees the player's lower edge clears the
// tallest obstacle plus a deliberate forgiveness margin.
static let jumpHeight: CGFloat = 125
static let jumpVelocity = sqrt(2 * gravity * jumpHeight)
static let flightTime = (2 * jumpVelocity) / gravity
```

| Quantity | Value |
|---|---|
| Gravity *g* | 1,550 pt/s² |
| Jump height *h* | 125 pt (the tallest obstacle is 64 pt) |
| Takeoff velocity √(2gh) | ≈ 622.5 pt/s |
| Airtime 2v/g | ≈ 0.803 s |
| Run speed | 255 pt/s at the start, +1.25 pt/s per point, capped at 455 pt/s |
| Jump length | ≈ 205 pt at the start, ≈ 365 pt at top speed |
| Score | 10 points per second, so top speed arrives at 160 points (16 s) |

- Obstacle gaps scale with speed. Each one is at least 88 % of the current jump length, plus 0.30 to 0.72 s of random slack.
- The frame delta is capped at 1/20 s, so a stutter can't carry you through an obstacle.
- Hitboxes are axis-aligned boxes inset by a few points, so you're slightly thinner than you look.
- The sprite uses nearest-neighbor filtering to keep the pixel art sharp.

## Privacy

Is this a keylogger? No. A single global monitor checks `event.keyCode == 49` (space) and ignores every other key. Nothing
is logged or sent anywhere, and the app has no networking code. The only values it saves are `highScore`, `gameTheme` and
`signature`.

You can check with `grep -rn "keyCode" Sources/`, or read all ~850 lines.

## Recording

Use Display Capture in OBS; window and app capture leave the track out. Recording mode (no controls), in the menu bar icon,
hides the buttons and the handle.

To confirm the track stays above fullscreen apps, run this with the game open:

```bash
swift scripts/verificar-overlay.swift   # puts a test window in fullscreen; exits 1 if the track disappears
```

## Project layout

```
claude-jumper/
├── Package.swift                  # SwiftPM, no .xcodeproj
├── Sources/ClaudeJumper/
│   ├── main.swift                 # NSApplication bootstrap
│   ├── AppDelegate.swift          # global key monitor, permission polling, menu bar
│   ├── FloatingGameWindow.swift   # transparent click-through overlay + control bar
│   ├── GameScene.swift            # game loop: physics, spawning, collisions, score
│   ├── MascotNode.swift           # pixel sprite + shadow
│   └── Theme.swift                # light / dark palettes
├── Assets/                        # sprite + app icon (Icons8, see Credits)
├── scripts/
│   ├── build-app.sh               # swift build → .app bundle → codesign
│   └── verificar-overlay.swift    # fullscreen overlay check
└── docs/                          # README images
```

## Credits

Pixel mascot sprite and app icon by [Icons8](https://icons8.com). Built by DevSar in Paraguay 🇵🇾; the handle on the track
is `@rojassartorio`.

> [!NOTE]
> Claude Jumper is an unofficial fan project. It is not affiliated with, endorsed by, or sponsored by Anthropic.
> Claude is a trademark of Anthropic, PBC.

## License

The source code is under the [MIT License](LICENSE). The files in `Assets/` (`clawd-sunglasses.png` and
`ClaudeJumper.icns`) come from Icons8 and are not covered by MIT; the [Icons8 license](https://icons8.com/license) applies to
them.
