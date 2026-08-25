# Techmino 3DS

Port of [Techmino](https://github.com/26F-Studio/Techmino) (LÖVE 11.5 Tetris game) to Nintendo 3DS via [LovePotion](https://github.com/lovebrew/lovepotion) 3.0.2.

## Architecture

```
Techmino_3DS/
├── Techmino/          ← upstream source (git submodule, read-only)
├── lovepotion/        ← upstream runtime (git submodule, read-only)
├── port/              ← 3DS port modifications
│   ├── compat.lua     ← API compatibility shim (patches missing LovePotion APIs)
│   ├── conf.lua       ← ported conf.lua (3DS platform detection)
│   ├── main.lua       ← ported main.lua (jit/shader/discord guards)
│   ├── build.lua      ← build script (Lua version)
│   └── parts/         ← stubbed/modified game modules
├── build.bat          ← Windows build script
├── build/             ← build output (gitignored)
└── AGENTS.md          ← agent guide for this port
```

## How It Works

1. **`port/compat.lua`** — Loaded first by `conf.lua`. Patches all missing LovePotion APIs:
   - `love.mouse` (module ABSENT on 3DS) — creates stub with `isDown=false`, `getPosition=0,0`
   - `love.graphics.newShader/setShader` — returns dummy objects
   - `love.graphics.stencil/setStencilTest` — no-ops
   - `love.graphics.ellipse` — approximated with circle
   - `love.graphics.newText` → redirects to `newTextBatch`
   - `love.graphics.setNewFont` → shimmed with .otf fallback to system fonts
   - `love.graphics.getDPIScale` → returns 1
   - `love.graphics.captureScreenshot/discard` — no-ops
   - `love.window.isMinimized/getSafeArea/setFullscreen` — stubs
   - `love.keyboard.isDown/setKeyRepeat` — stubs
   - `love.system.openURL/vibrate/clipboard` — stubs
   - `love.filesystem.newFile` → redirects to `openFile`
   - `love.math.noise` → redirects to `perlinNoise`
   - `jit` table — stubbed (Lua 5.1 without JIT on 3DS)
   - `parts.discordRPC` — preloaded as no-op (requires LuaJIT FFI)

2. **`port/conf.lua`** — Replaces upstream. Adds `HANDHELD` flag for 3DS, disables mouse module, sets vsync=1, 400×240.

3. **`port/main.lua`** — Replaces upstream. Guards `jit.*` references, `pcall`-wraps shader loading, enables virtual keys by default.

4. **Build script** (`build.bat`) — Merges `port/` over `Techmino/` into `build/game/`, removes `.glsl` shaders, creates `.love` package.

## Building

```sh
# Build .love package
build.bat

# Build LovePotion for 3DS (requires devkitPro Docker)
cd lovepotion
catnip -T 3DS -DLIBRARY_LOADER='linktime' -DUSE_CURL_BACKEND=ON

# Combine into .3dsx
copy /B lovepotion\build\lovepotion.3dsx + build\Techmino_3DS.love build\Techmino_3DS.3dsx
```

## Current Status

### Working (via compat.lua shim)
- Platform detection (`HANDHELD` flag)
- All missing API stubs (mouse, shaders, window, keyboard, system)
- Font loading fallback (.otf → system fonts)
- Build pipeline (.love packaging)

### Not Yet Implemented
- Dual-screen rendering (top screen game, bottom screen touch controls)
- Resolution scaling (1280×720 → 400×240)
- 3DS gamepad input mapping
- Virtual key layout for touch screen
- Stencil operation alternatives
- Canvas memory optimization
- Audio optimization (reduced sources, no filters)
