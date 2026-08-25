-- sim-test/conf.lua — Simulation test configuration
-- Uses nest library for 3DS emulation on desktop LÖVE

function love.conf(t)
    -- Basic LÖVE configuration for simulation
    t.identity = 'Techmino'
    t.version = "11.5"
    t.gammacorrect = false
    t.appendidentity = true

    t.window.width = 400
    t.window.height = 240
    t.window.vsync = 1
    t.window.resizable = false

    -- Enable all modules (nest will handle the rest)
    t.modules.joystick = true
    t.modules.mouse = true
    t.modules.touch = true
end
