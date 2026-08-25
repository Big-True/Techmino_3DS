# Techmino 3DS Port — Agent Guide

## Project Goal

Port [Techmino](https://github.com/26F-Studio/Techmino) (LÖVE 11.5 Tetris game) to run on Nintendo 3DS via [LovePotion](https://github.com/lovebrew/lovepotion) 3.0.2 (LÖVE 12.0-compatible runtime for Nintendo homebrew).

## Repository Layout

```
Techmino_3DS/
├── AGENTS.md          ← this file
├── README.md          ← project overview
├── build.bat          ← Windows build script
├── Techmino/          ← upstream source (read-only reference)
├── lovepotion/        ← upstream runtime (read-only reference)
├── port/              ← 3DS port modifications (ALL changes go here)
│   ├── compat.lua     ← API compatibility shim (patches missing LovePotion APIs)
│   ├── conf.lua       ← ported conf.lua (3DS platform detection)
│   ├── main.lua       ← ported main.lua (jit/shader/discord guards)
│   ├── build.lua      ← build script (Lua version)
│   ├── Zframework/    ← Zframework overrides (if needed)
│   └── parts/         ← stubbed/modified game modules
│       ├── discordRPC.lua  ← stub (LuaJIT FFI not available)
│       ├── shaders/        ← shader stubs
│       └── scenes/         ← scene overrides (if needed)
└── build/             ← build output (gitignored)
```

**Architecture**: `port/` files overlay `Techmino/` files during build. `compat.lua` is loaded first by `conf.lua` and patches all missing LovePotion APIs at runtime. `Techmino/` and `lovepotion/` are NEVER modified.

`Techmino/AGENTS.md` is the upstream project's own agent guide — read it first for code conventions, architecture, and key files.

## Critical Version Mismatch

LovePotion targets **LÖVE 12.0** APIs. Techmino targets **LÖVE 11.5**. Key differences:

| Area | LÖVE 11.5 | LÖVE 12.0 (LovePotion) |
|------|-----------|------------------------|
| Textures | `love.graphics.newImage()`, `newCanvas()` | `newImage`/`newCanvas` are aliases for `newTexture()` |
| `Graphics.newText` | Creates Text object | **ABSENT** — use `newTextBatch` instead |
| `Graphics.newShader` / `setShader` | GLSL strings | **ABSENT** — not exposed to Lua at all |
| `Graphics.stencil` / `setStencilTest` | Stencil buffer ops | **ABSENT** — not implemented |
| `Graphics.getDPIScale` | Top-level function | Stub exists (returns 0) but **NOT registered** |
| `Graphics.captureScreenshot` | Available | **ABSENT** |
| `Graphics.discard` | Available | **ABSENT** |
| `Graphics.setNewFont` | Available (deprecated) | **ABSENT** — use `newFont` instead |
| `Graphics.newImageFont` / `newBMFont` | Available | **ABSENT** — BMFont errors on 3DS |
| `window.getSafeArea` | Available | **ABSENT** |
| `window.setFullscreen` / `getFullscreen` | Available | **ABSENT** |
| `window.setMode` | Sets window size | **Forced to 400x240** on 3DS (ignores args) |
| `keyboard.isDown` | Module-level function | **ABSENT** — only `Joystick:isDown` exists |
| `keyboard.setKeyRepeat` | Available | **ABSENT** |
| `math.noise` | Perlin noise | **ABSENT** — use `perlinNoise`/`simplexNoise` |
| `filesystem.newFile` | Creates File object | **ABSENT** — use `openFile` instead |
| `mouse` module | Full module | **ABSENT** — no mouse on 3DS |
| `love._os` return | `"Windows"`, `"Linux"`, etc. | `"Horizon"` on 3DS |
| `love._console` | Does not exist | `"3DS"` |
| `love._version` | `"11.5"` | `"12.0"` |

## 3DS Platform Constraints

### Screen
- **Top screen**: 400×240 pixels (800×240 in 3D mode, split into left/right eye views)
- **Bottom screen**: 320×240 pixels (touch screen)
- Techmino's design resolution is **1280×720** — everything must scale down ~5x
- Dual-screen rendering: iterate `love.graphics.getScreens()` → `"left"`, `"right"`, `"bottom"` → call `love.graphics.setActiveScreen(screen)` before drawing
- 3D stereoscopic: `love.graphics.set3D(bool)`, `love.graphics.get3D()`, `love.graphics.getDepth()` (slider position)

### Input (from `platform/ctr/source/objects/joystick_ext.cpp`)
3DS gamepad mapping:
| LÖVE Gamepad Button | 3DS Key |
|---------------------|---------|
| `a` | A |
| `b` | B |
| `x` | X |
| `y` | Y |
| `back` | Select |
| `start` | Start |
| `leftshoulder` | L |
| `rightshoulder` | R |
| `dpup/down/left/right` | D-Pad |
| Axis `triggerleft` | ZL (New3DS only) |
| Axis `triggerright` | ZR (New3DS only) |
| Axis `leftx/lefty` | Circle Pad |
| Axis `rightx/righty` | C-Stick (New3DS only) |

**Mouse events are commented out** in LovePotion callbacks.lua — only `touchpressed/touchreleased/touchmoved` fire on the bottom screen.

### Memory & Performance
- Old 3DS: ~64MB RAM, 2 CPU cores. New 3DS: ~128MB RAM, 4 CPU cores
- `love.lowmemory()` fires with double `collectgarbage()` in LovePotion
- Textures on 3DS may need power-of-two dimensions
- No LuaJIT — plain Lua 5.1. All `jit.*` calls must be guarded or removed

### Shaders
- **User-defined shaders are NOT supported on 3DS** — `love.graphics.newShader()` and `setShader()` are not exposed to Lua at all
- Only built-in PICA200 vertex shaders are available (standard color/texture/video)
- Techmino has 10 GLSL shaders in `parts/shaders/` — all must be replaced with Lua fallbacks (no porting to PICA200 is possible from Lua)

### Fonts
- **TrueType/OpenType fonts are NOT supported on 3DS** — LovePotion uses BCFNT system fonts only
- Techmino loads `parts/fonts/proportional.otf` and `parts/fonts/monospaced.otf` — these will NOT load on 3DS
- Must use 3DS system fonts via LovePotion's font module or bundle BCFNT-compatible fonts
- `font:setFallbacks()` may not be available
- No kerning support (`GetKerning()` always returns 0.0)

### Textures & Canvases
- **Power-of-two texture dimensions required** on 3DS
- **Max texture size 1024×1024** (enforced in T3X handler)
- **Force nearest filtering** — `FILTER_NEAREST` default; no bilinear/trilinear
- **No mipmap generation** — `GenerateMipmaps()` is a no-op
- Limited pixel formats: `RGBA8`, `RGB8`, `RGB565`, `LA8` only
- No line strip primitive — only triangles, triangle strip, triangle fan
- `gc.getSystemLimits().texturesize` — verify availability (used in `gcExtend.lua:146`)
- Canvas format table syntax `gc_setCanvas({stencil=true}, canvas)` — **verify LovePotion support**
- `gc.ellipse()` — **ABSENT** (used in `backgrounds/snow.lua`, `backgrounds/fan.lua`, `gcExtend.lua`)
- `gc.stencil()` / `gc.setStencilTest()` — **ABSENT** (used in 6+ files, 20+ locations)
- `gc.setPointSize()` / `gc.getPointSize()` — implementations exist but **NOT registered**

### Networking
- luasocket is available (included in LovePotion build)
- lua-https with curl backend is available
- `love.thread` is supported (registered in LovePotion's module table)
- HTTP/HTTPS should work but will be slow on 3DS WiFi; WebSocket viability is unverified

### Audio
- Audio requires `dspfirm.cdc` on the 3DS SD card (ndsp-based)
- `love.audio.isEffectsSupported()` may not exist — guard calls to `source:setFilter()`
- `source:getChannelCount()`, `source:setPosition()` (3D audio) — verify availability
- `love.audio.getActiveSourceCount` may not exist
- Queue audio type is incomplete in LovePotion (`Source::Queue()` has a TODO comment)

### love.data
- `love.data.compress/decompress('string','zlib',...)` and `base64` encode/decode — **all PRESENT** in LovePotion

### Missing love.system APIs
- `love.system.openURL()` — **ABSENT** (used in `parts/scenes/stat.lua`, `login.lua`, `dict.lua`, `app_console.lua`)
- `love.system.vibrate()` — **ABSENT**
- `love.system.getClipboardText()/setClipboardText()` — **ABSENT**

### Other missing/different APIs
- `love.keyboard.isDown()` — **ABSENT** at module level; only `Joystick:isDown` exists
- `love.keyboard.setKeyRepeat()` — **ABSENT**
- `love.filesystem.newFile()` — **ABSENT**; use `openFile()` instead (used in `font.lua:21`, `file.lua:9`)
- `love.graphics.newText()` — **ABSENT**; use `newTextBatch()` instead (used in 30+ locations)
- `love.graphics.setNewFont()` — **ABSENT**; use `newFont()` instead (used in `font.lua:11,30`)
- `love.graphics.newImageFont()` / `newBMFont()` — **ABSENT**; BMFont explicitly errors on 3DS
- `love.math.noise()` — **ABSENT**; use `perlinNoise()`/`simplexNoise()` instead

## Files That Will Need Modification

### High-impact (block startup on 3DS)

1. **`conf.lua`** — `love._os` returns `"Horizon"`, not `"Windows"/"Linux"/"Android"/"iOS"`. The `MOBILE` and `FNNS` flags won't set correctly. Window settings (1280×720, vsync, msaa, stencil, highdpi) will fail or be ignored.

2. **`Zframework/init.lua`** — `SYSTEM` will be `"Horizon"`. Code branches for `'Web'`, `'OS X'` will never match. `love.window.isMinimized()` **ABSENT**. `love.mouse.*` calls (cursor, position, buttons) will fail — **mouse module ABSENT**. `love.graphics.getDPIScale()` not registered (stub returns 0). `gc.captureScreenshot()` **ABSENT**. `gc.discard()` **ABSENT**. `gc.stencil()`/`gc.setStencilTest()` **ABSENT**. `gc.ellipse()` **ABSENT**.

3. **`Zframework/screen.lua`** — Calls `love.graphics.getDPIScale()` and `love.window.getSafeArea()`, both missing on 3DS.

4. **`Zframework/font.lua`** — Loads `.otf` files which are NOT supported on 3DS (BCFNT only). Uses `GC.setNewFont()` with DPI scaling. `font:setFallbacks()` may not work. Font sizes need rescaling for 400×240 vs 1280×720.

5. **`main.lua`** — References `jit.arch`, `jit.version`, `jit.version_num` (line 175) which crash without LuaJIT. Discord RPC (`parts/discordRPC.lua`) uses FFI which won't work without LuaJIT. Font loading (lines 41-46) loads `.otf` files that won't work on 3DS.

6. **`parts/shaders/*.glsl`** — All 10 desktop shaders must be replaced or stubbed.

### Medium-impact (degraded functionality)

7. **`Zframework/gcExtend.lua`** — Canvas-heavy `GC.DO()` helper creates temporary canvases for all icons/UI; may hit 3DS memory limits. Canvas stencil table syntax `{stencil=true}` in `widget.lua:1519` may differ in LovePotion.

8. **`parts/scenes/setting_video.lua`** — Fullscreen/portrait toggles irrelevant on 3DS.

9. **`parts/net.lua`** — 767-line online multiplayer via HTTP+WebSocket. Unverified on 3DS WiFi. Uses `love.data.encode/decode('base64')`.

10. **`parts/discordRPC.lua`** — LuaJIT FFI (`require"ffi"`, `ffi.load("discord-rpc")`), Windows-only. Must be stubbed/guarded on 3DS.

11. **`Zframework/profile.lua`** — Uses `jit.off()` and `jit.flush()` (lines 43-44). Guard behind `if jit then`.

12. **`Zframework/sha2.lua`** — Heavy FFI use for crypto acceleration (lines 382-4349), with pure Lua fallback. FFI branch must be guarded.

13. **`Zframework/vibrate.lua`** — Checks `SYSTEM=='iOS'`; needs `'Horizon'` handling.

14. **`Zframework/clipboard.lua`** — Uses `love.thread` channels and `love.system.getClipboardText/setClipboardText`. Clipboard likely unavailable on 3DS.

15. **`Zframework/require.lua`** — Native `.so` library loading paths and `io.popen('uname -m')` (line 23) won't work on 3DS. Guard behind platform check.

16. **`Zframework/bgm.lua`** — Audio filters (`source:setFilter{type='bandpass',...}`) may not work in LovePotion.

17. **`Zframework/file.lua`** — `fs.newFile()` **ABSENT** (line 9) — use `openFile()` instead.

18. **`parts/player/draw.lua`** — Heavy shader usage (`gc_setShader()`) in 16+ locations for block rendering effects. All must fallback gracefully when shaders are absent.

19. **`parts/gameFuncs.lua`** — `SHADER.blockSatur:send()`, `SHADER.fieldSatur:send()` (lines 153-157) and `SHADER.warning` (line 1194). `love.mouse.setVisible()` (line 129). `love.window.setFullscreen()` (line 132).

20. **`conf.lua`** — `love.setDeprecationOutput(false)` (line 32) may not exist. `t.appendidentity=true` (line 34) may not be supported. `W.highdpi=true` (line 55) — 3DS has no HiDPI. `W.vsync=0` (line 50) — 3DS should use vsync.

## Development Commands

```sh
# Techmino on desktop (requires LÖVE 11.5 in PATH)
cd Techmino && love .
cd Techmino && love . --test    # smoke scan

# LovePotion build for 3DS (requires devkitPro/devkitARM Docker)
# CI uses: docker://devkitpro/devkitarm
cd lovepotion && catnip -T 3DS -DLIBRARY_LOADER='linktime' -DUSE_CURL_BACKEND=ON
# Output: build/lovepotion.3dsx + build/lovepotion.elf
# catnip is devkitPro's CMake wrapper

# Packaging a game for LovePotion:
# 1. Build lovepotion.3dsx
# 2. Create game.love (zip of game files: conf.lua, main.lua, etc.)
# 3. Concatenate: cat lovepotion.3dsx game.love > combined.3dsx
# LovePotion's boot.lua detects "fused" executables (3dsx+love appended)

# LovePotion also has a built-in test target:
cd lovepotion && catnip -T 3DS test
# Creates lovepotion_test.3dsx from lovepotion/test/ directory
```

### Key LovePotion build dependencies (from `platform/ctr/pkglist.txt`)
- `3ds-box2d` (physics), `3ds-curl` (HTTP), `3ds-liblua51`, `3ds-physfs`, `3ds-zlib`
- Audio: `3ds-flac`, `3ds-libogg`, `3ds-libvorbisidec`, `3ds-libmodplug`
- Image: `3ds-libpng`, `3ds-libjpeg-turbo`
- Requires `dspfirm.cdc` on SD card for audio playback

## Code Conventions (from Techmino)

- Follow `.editorconfig` (EmmyLuaCodeStyle): spaces, no spaces around operators/assignments/commas
- camelCase for functions/locals, `_camelCase` for private helpers, UPPERCASE for shared state (`GAME`, `MODES`, `SETTING`)
- Modules return plain tables; no class frameworks
- `gc` in identifiers = "graphics" (not garbage collector), except Lua's `gcinfo`
- Double-quoted strings = player-readable text; single-quoted = internal values

## Migration Strategy Notes

### Phase 1: Boot to title screen
- **Start with `conf.lua` and `Zframework/init.lua`** — these gate all startup
- Add `SYSTEM='Horizon'` / `MOBILE=false` / `FNNS=false` branches or add `'Horizon'` to existing platform checks
- Guard all `jit.*` references behind `if jit then ... end` (main.lua:175, profile.lua:43-44, sha2.lua, discordRPC.lua)
- Guard all `ffi` references behind `pcall(require,'ffi')` (sha2.lua, discordRPC.lua)
- Replace `love.graphics.getWidth()/getHeight()` with 400/240 or use canvas queries
- Replace `love.window.getSafeArea()` with `{0, 0, 400, 240}` fallback
- Replace `love.graphics.getDPIScale()` with `1` fallback
- Replace `love.window.isMinimized()` with `false` fallback
- Replace `gc.captureScreenshot()` and `gc.discard()` with no-ops
- Replace `gc.newShader()` with no-op (return dummy shader object)
- Replace `gc.stencil()`/`gc.setStencilTest()` with no-ops (6+ files)
- Replace `gc.ellipse()` with `gc.circle()` or `gc.polygon()` (3 files)
- Replace `love.filesystem.newFile()` with `love.filesystem.openFile()` (font.lua:21, file.lua:9)
- Replace `love.graphics.newText()` with `newTextBatch()` (30+ locations)
- Replace `GC.setNewFont()` with `newFont()` (font.lua:11,30)
- Replace `love.math.noise()` with `love.math.perlinNoise()` (backgrounds/matrix.lua:12)
- Remove or guard `love.setDeprecationOutput()` (conf.lua:32)
- Guard `io.popen()` calls (Zframework/require.lua:23)
- Guard `fs.newFile()` calls (Zframework/font.lua:21, file.lua:9) — use `openFile()` instead
- Guard `love.system.openURL()`, `vibrate()`, `getClipboardText()/setClipboardText()`

### Phase 2: Rendering
- Consider rendering to a 1280×720 canvas then scaling down to fit 400×240 — preserves existing coordinate math
- Bottom screen (320×240 touch) can show score/info/touch controls
- Stub all 10 GLSL shaders — `parts/shaders/*.glsl` use `love_ScreenSize`, `smoothstep`, etc. incompatible with PICA200
- Guard all `gc_setShader()` calls in `parts/player/draw.lua` (16+ locations) with shader-exists checks
- Guard audio filter calls in `Zframework/bgm.lua` (`source:setFilter`)

### Phase 3: Input
- Remap gamepad: 3DS has no `leftstick/rightstick` buttons, no `guide` button; ZL/ZR are axes not buttons
- Touch input on bottom screen already works via `love.touchpressed/touchreleased/touchmoved`
- `love.keyboard.setKeyRepeat(true)` and `love.keyboard.setTextInput(false)` — verify LovePotion support
- Guard `love.mouse.*` calls — 3DS has no mouse

### Phase 4: Networking (lower priority)
- Disable `parts/discordRPC.lua` on 3DS (requires LuaJIT FFI)
- Verify luasocket/HTTPS work on 3DS WiFi
- Online multiplayer (`parts/net.lua`) is a stretch goal

### Key architectural decision
LovePotion's default `love.run()` iterates screens with `love.graphics.getScreens()` and calls `love.draw(screen)` with the screen name. Techmino overrides `love.run()` entirely in `Zframework/init.lua`. The port must either:
- (A) Adapt Zframework's run loop to call `setActiveScreen` per frame, or
- (B) Let LovePotion's default run loop drive and adapt Techmino to accept a `screen` parameter in `love.draw`
