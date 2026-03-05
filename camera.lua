game_camera=class:new({
    x=x or 0,
    y=y or 0,
    dx=0,
    dy=0,
    mode="snap",
    target={x=0,y=0},
    update=function(_ENV) 
        if mode=="snap" then
            x = (target.x * 8) + target.mx - 64
            y = (target.y * 8) +target.my - 64
        elseif mode=="smooth" then
            dx = target.x * 8 - 64
            dy = target.y * 8 - 64
            x += (dx - x) * 0.2
            y += (dy - y) * 0.2
        end
    end
})