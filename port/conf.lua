-- port/conf.lua — Techmino 3DS port
-- Based on upstream Techmino/conf.lua with LovePotion 3DS adaptations
-- THIS FILE IS LOADED FIRST BY LOVEPOTION'S BOOT.LUA (before main.lua)

-- Load 3DS compatibility shim BEFORE anything else
-- This patches all missing LovePotion APIs (mouse, shaders, window, etc.)
pcall(dofile, 'compat.lua')

local system=love._os
if system=='OS X' then system='macOS' end

-- 3DS platform detection
HANDHELD=system=='Horizon' -- LovePotion 3DS returns "Horizon"
MOBILE=system=='Android' or system=='iOS'
FNNS=system:find'\79\83' -- "OS" in Windows/macOS (not present on 3DS/Horizon)

if system=='Web' then
    local oldRead=love.filesystem.read
    function love.filesystem.read(name,size)
        if love.filesystem.getInfo(name) then
            return oldRead(name,size)
        end
    end
end

function love.conf(t)
    local identity='Techmino'
    local msaa=0
    local portrait=false

    local fs=love.filesystem
    fs.setIdentity(identity)
    do -- Load graphic settings from conf/settings
        local fileData=fs.read('conf/settings')
        if fileData then
            msaa=tonumber(fileData:match('"msaa":(%d+)')) or 0;
            msaa=msaa==0 and 0 or 2*msaa
            portrait=MOBILE and fileData:find('"portrait":true') and true
        end
    end

    t.identity=identity -- Saving folder
    t.version="11.5"
    t.gammacorrect=false
    if not HANDHELD then
        t.appendidentity=true -- Search files in source then in save directory
    end
    t.accelerometerjoystick=false -- Accelerometer=joystick on ios/android
    if t.audio then
        t.audio.mic=false
        t.audio.mixwithsystem=true
    end

    local M=t.modules
    M.window,M.system,M.event,M.thread=true,true,true,true
    M.timer,M.math,M.data=true,true,true
    M.video,M.audio,M.sound=true,true,true
    M.graphics,M.font,M.image=true,true,true
    M.touch,M.keyboard,M.joystick=true,true,true
    M.mouse=not HANDHELD -- 3DS has no mouse module
    M.physics=false

    local W=t.window
    if HANDHELD then
        -- 3DS: fixed resolution, vsync, no HiDPI
        W.width,W.height=400,240 -- Top screen
        W.minwidth,W.minheight=400,240
        W.vsync=1
        W.msaa=0
        W.depth=0
        W.stencil=1
        W.highdpi=false
        W.borderless=true
        W.resizable=false
        W.fullscreentype="exclusive"
    else
        W.vsync=0              -- Unlimited FPS
        W.msaa=msaa            -- Multi-sampled antialiasing
        W.depth=0              -- Bits/samp of depth buffer
        W.stencil=1            -- Bits/samp of stencil buffer
        W.display=1            -- Monitor ID
        W.highdpi=true         -- High-dpi mode for the window on a Retina display
        W.x,W.y=nil,nil        -- Position of the window
        W.borderless=MOBILE    -- Display window frame
        W.resizable=not MOBILE -- Whether window is resizable
        W.fullscreentype=MOBILE and "exclusive" or "desktop"
        if portrait then
            W.width,W.height=720,1280
            W.minwidth,W.minheight=360,640
        else
            W.width,W.height=1280,720
            W.minwidth,W.minheight=640,360
        end
    end
    W.title="Techmino "..require"version".string
    if system=='Linux' and fs.getInfo('media/image/icon.png') then
        W.icon='media/image/icon.png'
    end
end
