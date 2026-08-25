-- port/Zframework/init_3ds_patch.lua
-- 3DS patches for Zframework/init.lua
-- These are applied at the TOP of init.lua by the build script

local IS_3DS = (love._os == "Horizon") or (love._console == "3DS")

if IS_3DS then
    -- Pre-patch: ensure compat.lua was loaded
    -- If not, load it now
    if not love._3ds then
        pcall(dofile, 'compat.lua')
    end
end
