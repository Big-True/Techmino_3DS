-- port/parts/shaders/init.lua — 3DS shader stubs
-- LovePotion 3DS has no user-defined shaders (newShader/setShader ABSENT)
-- This file ensures SHADER table is populated with no-op objects
-- Place this file alongside the original .glsl files; the build script
-- will use this instead of loading .glsl files.

-- The SHADER table is populated in main.lua using pcall(love.graphics.newShader)
-- which returns dummy objects via compat.lua's shim.
-- This file is not loaded directly — it's a reference for the build system.
