game_camera=class:new({
    x=x or 0,
    y=y or 0,
    dx=0,
    dy=0,
    target={x=0,y=0},
    update=function(_ENV) 
        dx = target.x * 8 - 64
        dy = target.y * 8 - 64
        x += (dx - x) * 0.2
        y += (dy - y) * 0.2
    end
})