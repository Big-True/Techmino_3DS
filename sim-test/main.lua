-- sim-test/main.lua — Simulation test entry point
-- Uses nest library to simulate LovePotion 3DS on desktop LOVE 11.5
--
-- IMPORTANT: The build script saves the game's original main.lua as
-- game_main.lua BEFORE copying this file.

------------------------------------------------------------
-- 1. Initialize nest for 3DS simulation
------------------------------------------------------------
local nest = require("nest").init({
    console = "3ds",
    scale = 2,
    emulateJoystick = true,
})

------------------------------------------------------------
-- 2. Load 3DS compatibility shim
------------------------------------------------------------
pcall(dofile, 'compat.lua')

------------------------------------------------------------
-- 3. Ensure love._os is set
------------------------------------------------------------
if not love._os then
    love._os = 'Horizon'
end

------------------------------------------------------------
-- 4. Override error handler BEFORE loading game code
-- The game's Zframework has an error handler that auto-restarts,
-- creating an infinite crash loop. Override it to just print
-- the error and stop.
------------------------------------------------------------
local sim_errors = {}

function love.errorhandler(msg)
    msg = tostring(msg or 'unknown error')
    table.insert(sim_errors, msg)
    print('[SIM-TEST] ERROR: ' .. msg)

    -- Return a simple error display loop (no restart)
    return function()
        love.event.pump()
        for e, a in love.event.poll() do
            if e == 'quit' then return a or 0 end
        end

        if love.graphics.isActive() then
            love.graphics.clear(0.1, 0.1, 0.12)

            love.graphics.setColor(1, 0.4, 0.4)
            love.graphics.rectangle('fill', 10, 10, love.graphics.getWidth() - 20, 40)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print('  SIM-TEST ERROR (press Escape to quit)', 15, 20)

            love.graphics.setColor(0.9, 0.9, 0.9)
            local y = 60
            for i, e in ipairs(sim_errors) do
                if i > 8 then break end
                love.graphics.print(e:sub(1, 100), 15, y)
                y = y + 18
            end

            love.graphics.present()
        end

        love.timer.sleep(0.1)
    end
end

------------------------------------------------------------
-- 5. Suppress audio errors (no audio device in CI/headless)
------------------------------------------------------------
local realAudioInit = love.audio and love.audio.setVolume
if realAudioInit then
    pcall(love.audio.setVolume, 0)
end

------------------------------------------------------------
-- 6. Load the game's original main.lua (saved as game_main.lua)
------------------------------------------------------------
local ok, err = pcall(dofile, 'game_main.lua')
if not ok then
    print('[SIM-TEST] FATAL loading game_main.lua:')
    print(err)
    table.insert(sim_errors, 'LOAD: ' .. tostring(err))
end
