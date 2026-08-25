-- sim-test/main.lua — Simulation test entry point
-- Uses nest library to simulate LovePotion 3DS on desktop LÖVE 11.5
--
-- Usage:
--   love sim-test/
--
-- The build script (build.bat) merges port/ + Techmino/ into sim-test/
-- and includes the nest library for simulation.

------------------------------------------------------------
-- 1. Initialize nest for 3DS simulation
-- This must happen BEFORE anything else
------------------------------------------------------------
local nest = require("nest").init({
    console = "3ds",
    scale = 2,           -- 2x scale for better visibility
    emulateJoystick = true, -- keyboard → 3DS gamepad
})

------------------------------------------------------------
-- 2. Load 3DS compatibility shim
-- nest handles dual-screen and joystick emulation,
-- but compat.lua handles the remaining API gaps
-- (shaders, filesystem, system, etc.)
------------------------------------------------------------
pcall(dofile, 'compat.lua')

------------------------------------------------------------
-- 3. Load the game's actual main.lua
-- By this point:
--   - love._console = "3DS" (set by nest)
--   - love._os may need to be set (nest may not set this)
------------------------------------------------------------
if not love._os then
    love._os = 'Horizon'
end

-- The game's main.lua is in the same directory (merged build)
dofile('main.lua')
