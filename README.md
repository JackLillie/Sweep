# Sweep

A free, native macOS app for system maintenance. Clean caches, manage storage, audit app permissions, and keep your Mac running smoothly.

Built on top of [Mole](https://github.com/tw93/mole). (I ❤️ Mole)

## Features

- **Overview** — real-time CPU, memory, and disk usage at a glance
- **Smart Clean** — scan and remove caches, logs, browser data, build artifacts, and trash via Mole
- **Applications** — browse and uninstall apps, sorted by size or last opened
- **Storage** — visualize disk usage and find large files
- **Permissions** — audit which apps have access to camera, mic, location, full disk access, etc.
- **Menu bar** — quick stats and one-click actions without opening the full app

## Requirements

- macOS 14.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (to generate the Xcode project)
- [Mole](https://github.com/tw93/mole) (`brew install mole`)

## Building

```sh
xcodegen generate
open Sweep.xcodeproj
```

Or from the command line:

```sh
xcodegen generate
xcodebuild -project Sweep.xcodeproj -scheme Sweep -configuration Debug build
```

## License

MIT — see [LICENSE](LICENSE) for details.
