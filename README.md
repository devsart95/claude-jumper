<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/hero-dark.png">
  <img alt="Claude Jumper: a pixel mascot jumping over obstacles on a transparent track that floats over a code editor and a terminal" src="docs/hero-light.png" width="100%">
</picture>

# Claude Jumper

An endless runner that floats over your macOS desktop. Press <kbd>Space</kbd> in any app and the mascot jumps.

Best played while Claude is down or the API returns `529 overloaded_error`. You were going to wait anyway.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111?logo=apple&logoColor=white)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)

</div>

## Run it

```bash
git clone https://github.com/devsart95/claude-jumper.git
cd claude-jumper && ./scripts/build-app.sh && open "dist/Claude Jumper.app"
```

Needs macOS 14+ and Xcode 16+. The first time, macOS asks for Accessibility so the game can see the space bar in other
apps. It ignores every other key.

## The nerdy part

The jump is `v = √(2gh)` with g = 1,550 pt/s² and h = 125 pt, which gives 0.80 s of airtime at any frame rate. Obstacles top
out at 64 pt, so each one leaves at least 0.33 s to time the jump. They are placed by distance, accounting for the speed-up,
so even a last-moment jump lands at least 0.2 s before you have to jump the next one. `swift test` checks all of it.

## Credits

Sprite and icon by [Icons8](https://icons8.com), under the [Icons8 license](https://icons8.com/license). Code under
[MIT](LICENSE). Unofficial fan project, not affiliated with Anthropic. Claude is a trademark of Anthropic, PBC.
