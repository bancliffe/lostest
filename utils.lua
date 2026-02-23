function printc(string,x,y,col)
    local w = print(string,0,-6,col)
    print(string,x-w/2,y,col)
end

function generate_map(width,height)
    if not width then width = 128 end
    if not height then height = 128 end
    local map = {}
    for i=0,width-1 do
        map[i] = {}
        for j=0,height-1 do
            map[i][j] = {sprite_id=1, walkable=true, visible=false, explored=false, block_sight=false}
        end
    end

    --random walls
    for i=0,32 do
        local x = flr(rnd(width))
        local y = flr(rnd(height))
        map[x][y] = {sprite_id=2, walkable=false, visible=false, explored=false, block_sight=true}
    end
    return map
end

function distance(x0,y0,x1,y1)
    return sqrt((x1-x0)^2 + (y1-y0)^2)
end

function update_los(map)
    for i=0,map_width-1 do
        for j=0,map_height-1 do
            local tile = map[i][j]            
            local los = has_line_of_sight(test_character.x,test_character.y,i,j)
            if los then
                tile.visible = true
                tile.explored = true
            else
                tile.visible = false
            end
        end
    end
end

-- Bresenham line algorithm: returns an array of tiles from (x0,y0) to (x1,y1)
function bresenham(x0,y0,x1,y1)
    local tiles = {}
    local dx = abs(x1 - x0)
    local dy = abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1

    local err = dx - dy
    local x = x0
    local y = y0

    while true do
        add(tiles, {x = x, y = y})
        if x == x1 and y == y1 then break end
        local e2 = err * 2
        if e2 > -dy then
            err = err - dy
            x = x + sx
        end
        if e2 < dx then
            err = err + dx
            y = y + sy
        end
    end
    return tiles
end

-- Check line-of-sight between two tile coordinates.
function has_line_of_sight(x0,y0,x1,y1)
    local pts = bresenham(x0,y0,x1,y1)
    for i=1,#pts do
        local p = pts[i]
        local tile = test_map[p.x][p.y]
        if tile and tile.block_sight then
            -- make sure the walls get marked as visible 
            if p.x == x1 and p.y == y1 then return true end
            return false
        end
    end
    return true
end

