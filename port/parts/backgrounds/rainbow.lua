-- Rainbow background 1 (3DS port: shader may not exist)
local back={}
local shader=SHADER.rgb1
local t

function back.init()
    t=math.random()*2600
end
function back.update(dt)
    t=(t+dt)%6200
end
function back.draw()
    GC.clear(.08,.08,.084)
    if shader then
        shader:send('phase',t)
        GC.setShader(shader)
        GC.rectangle('fill',0,0,SCR.w,SCR.h)
        GC.setShader()
    else
        local r=math.sin(t*.01)*.5+.5
        local g=math.sin(t*.01+2.09)*.5+.5
        local b=math.sin(t*.01+4.18)*.5+.5
        GC.setColor(r*.15,g*.15,b*.15)
        GC.rectangle('fill',0,0,SCR.w,SCR.h)
        GC.setColor(1,1,1)
    end
end
return back
