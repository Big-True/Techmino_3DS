-- port/compat.lua
-- LovePotion 3DS compatibility shim
-- Load this BEFORE conf.lua / main.lua to patch missing APIs

local IS_3DS = (love._os == "Horizon") or (love._console == "3DS")

if not IS_3DS then return end

-------------------------------------------------------
-- 1. love.graphics patches
-------------------------------------------------------
local gc = love.graphics

-- getDPIScale: stub returns 1 (not registered in LovePotion)
if not gc.getDPIScale then
    function gc.getDPIScale() return 1 end
end

-- captureScreenshot: ABSENT
if not gc.captureScreenshot then
    function gc.captureScreenshot() end
end

-- discard: ABSENT
if not gc.discard then
    function gc.discard() end
end

-- stencil / setStencilTest: ABSENT
if not gc.stencil then
    function gc.stencil() end
end
if not gc.setStencilTest then
    function gc.setStencilTest() end
end

-- ellipse: ABSENT, approximate with circle
if not gc.ellipse then
    function gc.ellipse(mode, x, y, rx, ry, segments)
        -- approximate ellipse as circle using average radius
        gc.circle(mode, x, y, (rx + ry) / 2, segments)
    end
end

-- newShader / setShader: ABSENT
if not gc.newShader then
    local dummyShader = setmetatable({}, {
        __index = function(self, k)
            if k == 'send' then return function() end end
            if k == 'getWarnings' then return function() return '' end end
            return function() end
        end
    })
    function gc.newShader()
        return dummyShader
    end
end

if not gc.setShader then
    function gc.setShader() end
end

-- newText: ABSENT, redirect to newTextBatch
if not gc.newText then
    gc.newText = gc.newTextBatch
end

-- getSystemLimits: may not exist
if not gc.getSystemLimits then
    function gc.getSystemLimits()
        return { texturesize = 1024 }
    end
end

-------------------------------------------------------
-- 2. love.window patches
-------------------------------------------------------
local win = love.window

-- isMinimized: ABSENT
if not win.isMinimized then
    function win.isMinimized() return false end
end

-- getSafeArea: ABSENT
if not win.getSafeArea then
    function win.getSafeArea()
        return 0, 0, gc.getWidth(), gc.getHeight()
    end
end

-- setFullscreen: ABSENT
if not win.setFullscreen then
    function win.setFullscreen() return false end
end

-- getFullscreen: ABSENT
if not win.getFullscreen then
    function win.getFullscreen() return true end
end

-- getMode: ABSENT
if not win.getMode then
    function win.getMode()
        return gc.getWidth(), gc.getHeight(), {fullscreen=true, vsync=1}
    end
end

-------------------------------------------------------
-- 3. love.mouse shim (module completely ABSENT)
-------------------------------------------------------
if not love.mouse then
    local mx, my = 0, 0
    love.mouse = {
        isDown = function() return false end,
        getPosition = function() return mx, my end,
        getX = function() return mx end,
        getY = function() return my end,
        setPosition = function(x, y) mx, my = x, y end,
        setVisible = function() end,
        isVisible = function() return false end,
        setGrabbed = function() end,
        isGrabbed = function() return false end,
        setRelativeMode = function() end,
        isRelativeMode = function() return false end,
        isCursorSupported = function() return false end,
        setCursor = function() end,
        newCursor = function() return {} end,
        getSystemCursor = function() return {} end,
    }
end

-------------------------------------------------------
-- 4. love.keyboard patches
-------------------------------------------------------
local kb = love.keyboard

-- isDown: ABSENT at module level (only Joystick:isDown exists)
if not kb.isDown then
    kb.isDown = function() return false end
end

-- setKeyRepeat: ABSENT
if not kb.setKeyRepeat then
    kb.setKeyRepeat = function() end
end

-------------------------------------------------------
-- 5. love.system patches
-------------------------------------------------------
local sys = love.system

-- openURL: ABSENT
if not sys.openURL then
    sys.openURL = function() return false end
end

-- vibrate: ABSENT
if not sys.vibrate then
    sys.vibrate = function() end
end

-- clipboard: ABSENT
if not sys.getClipboardText then
    sys.getClipboardText = function() return '' end
end
if not sys.setClipboardText then
    sys.setClipboardText = function() end
end

-------------------------------------------------------
-- 6. love.filesystem patches
-------------------------------------------------------
local fs = love.filesystem

-- newFile: ABSENT (use openFile instead)
if not fs.newFile then
    function fs.newFile(name)
        return fs.openFile(name)
    end
end

-------------------------------------------------------
-- 7. love.math patches
-------------------------------------------------------
local lm = love.math

-- noise: ABSENT (use perlinNoise instead)
if not lm.noise then
    lm.noise = lm.perlinNoise
end

-------------------------------------------------------
-- 8. love.data patches (should be present but verify)
-------------------------------------------------------
-- love.data.compress/decompress/encode/decode are PRESENT in LovePotion

-------------------------------------------------------
-- 9. love.setDeprecationOutput: may not exist
-------------------------------------------------------
if not love.setDeprecationOutput then
    love.setDeprecationOutput = function() end
end

-------------------------------------------------------
-- 10. love._os / SYSTEM value
-------------------------------------------------------
-- Ensure love._os is set (LovePotion sets it to "Horizon")
if not love._os then
    love._os = love.system.getOS()
end

-------------------------------------------------------
-- 11. Font system patches for 3DS
-- LovePotion 3DS uses BCFNT system fonts, NOT TTF/OTF
-- Techmino loads .otf files which won't work on 3DS
-------------------------------------------------------
local origNewFont = gc.newFont
if origNewFont then
    -- Patch newFont to handle File objects and .otf fallback
    gc.newFont = function(fileOrPath, size, ...)
        if type(fileOrPath) == 'userdata' then
            -- File object: try to get filename
            local ok, path = pcall(function() return fileOrPath:getFilename() end)
            if ok and path then
                -- If it's a .otf/.ttf file, try to load it; on 3DS it will use BCFNT fallback
                local ok2, font = pcall(origNewFont, path, size, ...)
                if ok2 then return font end
                -- Fallback: try loading without the file (use system font)
                local ok3, sysFont = pcall(origNewFont, size or 12)
                if ok3 then return sysFont end
            end
        end
        local ok, font = pcall(origNewFont, fileOrPath, size, ...)
        if ok then return font end
        -- Final fallback: system font with given size
        return origNewFont(size or 12)
    end
end

-- setNewFont: ABSENT in LovePotion, shim it
if not gc.setNewFont then
    gc.setNewFont = function(fileOrSize, sizeOrHinting, ...)
        if type(fileOrSize) == 'number' then
            return gc.newFont(fileOrSize)
        else
            -- file + size or file + hinting + dpiScale
            local size = sizeOrHinting
            if type(size) ~= 'number' then
                size = 12 -- default if hinting was passed instead of size
            end
            return gc.newFont(fileOrSize, size)
        end
    end
end

-------------------------------------------------------
-- 12. LuaJIT stubs (3DS uses Lua 5.1 without JIT)
-------------------------------------------------------
if not jit then
    jit = {
        arch = 'ARM',
        version = 'none (3DS)',
        version_num = 0,
        off = function() end,
        flush = function() end,
        on = function() end,
        status = function() return false end,
    }
end

-------------------------------------------------------
-- 13. Discord RPC stub (requires LuaJIT FFI)
-------------------------------------------------------
package.preload['parts.discordRPC'] = function()
    return {
        update = function() end,
        shutdown = function() end,
    }
end

-------------------------------------------------------
-- 14. Dual-screen helpers
-------------------------------------------------------
love._3ds = love._3ds or {}
local _currentScreen = 'top'

function love._3ds.getCurrentScreen()
    return _currentScreen
end

function love._3ds.setCurrentScreen(s)
    _currentScreen = s
end

function love._3ds.isBottomScreen()
    return _currentScreen == 'bottom'
end

function love._3ds.isTopScreen()
    return _currentScreen ~= 'bottom'
end

print('[3DS Compat] Compatibility shim loaded for LovePotion 3DS')
