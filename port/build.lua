-- port/build.lua — Build script for Techmino 3DS .love package
-- Usage: lua port/build.lua
-- Output: build/Techmino_3DS.love

local sep = package.config:sub(1,1) -- '/' on unix, '\' on windows
local is_win = sep == '\\'

local function exists(path)
    local f = io.open(path, 'r')
    if f then f:close() return true end
    return false
end

local function mkdir(path)
    if is_win then
        os.execute('mkdir "'..path..'" 2>nul')
    else
        os.execute('mkdir -p "'..path..'"')
    end
end

local function copy(src, dst)
    if is_win then
        os.execute('copy /Y "'..src..'" "'..dst..'" >nul 2>&1')
    else
        os.execute('cp "'..src..'" "'..dst..'"')
    end
end

local function copytree(src, dst)
    mkdir(dst)
    if is_win then
        os.execute('xcopy /E /I /Y "'..src..'" "'..dst..'" >nul 2>&1')
    else
        os.execute('cp -r "'..src..'/"* "'..dst..'/"')
    end
end

print('=== Techmino 3DS Build ===')

-- Step 1: Create clean build directory
print('[1/4] Cleaning build directory...')
if is_win then
    os.execute('rmdir /S /Q build\\game 2>nul')
else
    os.execute('rm -rf build/game')
end
mkdir('build'..sep..'game')

local out = 'build'..sep..'game'

-- Step 2: Copy upstream Techmino files
print('[2/4] Copying upstream Techmino files...')
local upstream_files = {
    'version.lua', 'legals.md', 'license.txt', 'updateLog.txt',
}
for _, f in ipairs(upstream_files) do
    copy('Techmino'..sep..f, out..sep..f)
end
copytree('Techmino'..sep..'media', out..sep..'media')
copytree('Techmino'..sep..'parts', out..sep..'parts')
copytree('Techmino'..sep..'Zframework', out..sep..'Zframework')

-- Step 3: Overlay port/ modifications
print('[3/4] Applying 3DS port modifications...')

-- Copy port/conf.lua → conf.lua (replaces upstream)
if exists('port'..sep..'conf.lua') then
    copy('port'..sep..'conf.lua', out..sep..'conf.lua')
else
    copy('Techmino'..sep..'conf.lua', out..sep..'conf.lua')
end

-- Copy port/main.lua → main.lua (replaces upstream)
if exists('port'..sep..'main.lua') then
    copy('port'..sep..'main.lua', out..sep..'main.lua')
else
    copy('Techmino'..sep..'main.lua', out..sep..'main.lua')
end

-- Copy port/compat.lua → compat.lua (new file, loaded first)
if exists('port'..sep..'compat.lua') then
    copy('port'..sep..'compat.lua', out..sep..'compat.lua')
end

-- Overlay modified Zframework files
local zf_files = {'init.lua', 'screen.lua', 'font.lua', 'gcExtend.lua', 'vibrate.lua', 'clipboard.lua', 'require.lua', 'file.lua', 'bgm.lua'}
for _, f in ipairs(zf_files) do
    if exists('port'..sep..'Zframework'..sep..f) then
        copy('port'..sep..'Zframework'..sep..f, out..sep..'Zframework'..sep..f)
    end
end

-- Overlay modified parts files
local parts_files = {'discordRPC.lua', 'gameFuncs.lua'}
for _, f in ipairs(parts_files) do
    if exists('port'..sep..'parts'..sep..f) then
        copy('port'..sep..'parts'..sep..f, out..sep..'parts'..sep..f)
    end
end

-- Overlay shader stubs (replace .glsl with no-ops)
if exists('port'..sep..'parts'..sep..'shaders') then
    -- Remove original shaders
    if is_win then
        os.execute('del /Q "'..out..sep..'parts'..sep..'shaders'..sep..'*.glsl" 2>nul')
    else
        os.execute('rm -f "'..out..sep..'parts'..sep..'shaders'..sep..'*.glsl"')
    end
    -- Copy stub files
    local p = io.popen('dir /b "port'..sep..'parts'..sep..'shaders" 2>nul')
    if p then
        for file in p:lines() do
            copy('port'..sep..'parts'..sep..'shaders'..sep..file, out..sep..'parts'..sep..'shaders'..sep..file)
        end
        p:close()
    end
end

-- Overlay modified scene files
if exists('port'..sep..'parts'..sep..'scenes') then
    local p = io.popen('dir /b "port'..sep..'parts'..sep..'scenes" 2>nul')
    if p then
        for file in p:lines() do
            copy('port'..sep..'parts'..sep..'scenes'..sep..file, out..sep..'parts'..sep..'scenes'..sep..file)
        end
        p:close()
    end
end

-- Step 4: Create .love package (zip)
print('[4/4] Creating .love package...')
local love_file = 'build'..sep..'Techmino_3DS.love'
if exists(love_file) then
    os.execute('del /Q "'..love_file..'" 2>nul')
end

-- Use PowerShell to create zip on Windows
if is_win then
    os.execute('powershell -Command "Compress-Archive -Path \''..out..'\\*\' -DestinationPath \''..love_file:gsub('%.love$','.zip')..'\' -Force"')
    os.execute('move /Y "'..love_file:gsub('%.love$','.zip')..'" "'..love_file..'" >nul 2>&1')
else
    os.execute('cd "'..out..'" && zip -r "../../'..love_file..'" .')
end

print('')
print('=== Build complete ===')
print('Output: '..love_file)
print('')
print('To create a 3DS .3dsx:')
print('  1. Build lovepotion.3dsx (cd lovepotion && catnip -T 3DS)')
print('  2. cat lovepotion.3dsx build/Techmino_3DS.love > build/Techmino_3DS.3dsx')
