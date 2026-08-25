# Techmino 3DS

Port of [Techmino](https://github.com/26F-Studio/Techmino) (LÖVE 11.5 Tetris game) to Nintendo 3DS via [LovePotion](https://github.com/lovebrew/lovepotion) 3.0.2.

## Quick Start

```sh
# 1. Build simulation test (runs on desktop LÖVE with nest)
build.bat sim

# 2. Run simulation test
run-sim.bat
# Or: "C:\Program Files\LOVE\love.exe" build\sim-test

# 3. Build .3dsx for real 3DS hardware
build.bat 3dsx
# Output: build\Techmino_3DS.3dsx → copy to SD card, launch via Homebrew Launcher
```

## Build Targets

| Command | Output | Description |
|---------|--------|-------------|
| `build.bat sim` | `build\sim-test\` | Simulation test (desktop LÖVE + nest library) |
| `build.bat love` | `build\Techmino_3DS.love` | .love package for LovePotion |
| `build.bat 3dsx` | `build\Techmino_3DS.3dsx` | .3dsx homebrew package (auto-downloads LovePotion if needed) |
| `build.bat` | All of the above | Full build |

## Architecture

```
Techmino_3DS/
├── Techmino/          ← upstream source (submodule, read-only)
├── lovepotion/        ← upstream runtime (submodule, read-only)
├── nest/              ← LovePotion compatibility layer (submodule, read-only)
├── port/              ← 3DS port modifications (ALL changes go here)
│   ├── compat.lua     ← API shim (30+ missing LovePotion APIs)
│   ├── conf.lua       ← 3DS platform detection
│   ├── main.lua       ← jit/shader/discord guards
│   └── parts/         ← stubbed modules (discordRPC, shaders)
├── sim-test/          ← Simulation test wrapper (uses nest)
├── build.bat          ← Build script (sim/love/3dsx)
├── run-sim.bat        ← Launch simulation test
├── AGENTS.md          ← Comprehensive porting guide
└── README.md          ← This file
```

## Simulation Testing

Uses the official [nest](https://github.com/lovebrew/nest) library for LovePotion simulation on desktop LÖVE. The nest library provides:

- Dual-screen window layout (400×240 top + 320×240 bottom)
- Keyboard → 3DS gamepad emulation
- Mouse on bottom screen → touch input simulation
- 3D depth slider (scroll wheel)
- Console-specific API adjustments

When running on actual 3DS hardware, nest's `init()` is a no-op — the same code works on both desktop and 3DS.

### Controls (Simulation)

| Key | 3DS Button |
|-----|-----------|
| Arrow keys | D-Pad |
| Z / X / A / S | A / B / X / Y |
| Q / W | L / R shoulders |
| Enter | Start |
| Backspace | Select |
| Mouse click (bottom screen) | Touch |
| Scroll wheel | 3D depth slider |

## 3DS Package

The `.3dsx` file is created by concatenating `lovepotion.3dsx` (LovePotion runtime) with the game's `.love` archive:

```
lovepotion.3dsx + Techmino_3DS.love → Techmino_3DS.3dsx
```

Copy `Techmino_3DS.3dsx` to the 3DS SD card and launch via the Homebrew Launcher.

## Current Status

### Working
- Platform detection (`HANDHELD` flag, `love._os = "Horizon"`)
- API compatibility shim (30+ missing APIs patched)
- Simulation test via nest library
- Build pipeline (.love + .3dsx packaging)
- Pre-built LovePotion auto-download for .3dsx

### In Progress
- Dual-screen rendering adaptation
- Resolution scaling (1280×720 → 400×240)
- 3DS gamepad input mapping
- Virtual key layout for touch screen
