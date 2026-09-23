<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/hero-dark.png">
  <img alt="Claude Jumper: a pixel mascot jumping over obstacles on a transparent track that floats over a code editor and a terminal" src="docs/hero-light.png" width="100%">
</picture>

# Claude Jumper

A small endless runner for macOS that sits on top of your desktop. Press <kbd>Space</kbd> from any app and the mascot jumps.

Best played while Claude is down or the API returns `529 overloaded_error`. You were going to wait anyway.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111?logo=apple&logoColor=white)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)

</div>

## How it plays

The track is a transparent strip along the bottom of the screen. Obstacles come in from the right and you jump them with
the space bar without leaving the app you're working in. The game only listens for the key, so your app still receives it.
You score 10 points a second, the run speeds up as the score climbs, and your best score is kept between launches.

The track stays above other windows, fullscreen apps included, and mouse clicks pass through it. A small control bar in the
corner lets you jump, switch between a light and a dark theme, drag the track somewhere else, hide it or quit. Pause and the
remaining options are in the menu bar icon.

## Build and run

You need macOS 14 or later and Xcode 16 or later.

```bash
git clone https://github.com/devsart95/claude-jumper.git
cd claude-jumper
./scripts/build-app.sh
open "dist/Claude Jumper.app"
```

The first time, macOS asks for Accessibility permission, which is what lets an app see a key pressed in another app. The
game checks for the space bar and nothing else.

`build-app.sh` signs with your Apple Development certificate if you have one. Without it the app is signed ad hoc and macOS
asks for the permission again after every rebuild. Set `CODE_SIGN_IDENTITY` to choose a specific identity.

## How the jump is tuned

Everything in the game is measured against a single jump. It rises 125 pt and stays in the air for 0.80 s under a gravity of
1,550 pt/s².

The tallest obstacle is 64 pt, about half the jump, so the challenge is timing. At the starting speed the
hardest obstacle gives you a 0.33 s window to clear it. The run speeds up from 255 to 455 pt/s over the first 16 seconds,
and the window only gets wider, because obstacles pass under you faster while the jump lasts just as long.

Obstacles arrive one full jump apart plus a random pause of 0.20 to 0.62 s, so you always land before the next one needs a
jump. In the tightest pairing you still have 0.49 s after touching down.

The jump uses the exact equations for constant gravity, so it peaks at 125 pt whether the display runs at 30, 60 or 120 fps.
A plain Euler step, the usual shortcut, peaks anywhere from 115 to 122 pt depending on the frame rate. Hitboxes are a few
points smaller than the sprites, so grazing a corner doesn't end the run.

`swift test` checks each of these rules: the jump height at several frame rates, the timing window of every obstacle, the
time left after landing for every pair of obstacles, and that a run without jumps ends at the first obstacle.

## Credits and license

The mascot sprite and the app icon are from [Icons8](https://icons8.com). They are not covered by the MIT license; the
[Icons8 license](https://icons8.com/license) applies to them. The rest of the project is [MIT](LICENSE).

Claude Jumper is an unofficial fan project, not affiliated with or endorsed by Anthropic. Claude is a trademark of
Anthropic, PBC.
