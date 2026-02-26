-- Print a centered string at (x,y) with color col
function printc(string,x,y,col)
    local w = print(string,0,-6,col)
    print(string,x-w/2,y,col)
end

-- determines distance between two points (used for LOS and vision range)
function distance(x0,y0,x1,y1)
    return sqrt((x1-x0)^2 + (y1-y0)^2)
end

-- updates line-of-sight for all tiles based on player position and vision range
function update_los(map)
    local max_range = player.vision_range
    local max_x = player.x + max_range
    local min_x = player.x - max_range
    local max_y = player.y + max_range
    local min_y = player.y - max_range
    max_x = mid(0,map_width-1,max_x)
    min_x = mid(0,map_width-1,min_x)
    max_y = mid(0,map_height-1,max_y)
    min_y = mid(0,map_height-1,min_y)
    for cell in all(map) do
        for tile in all(cell) do
            tile.visible = false
        end
    end
    for i=min_x,max_x do
        for j=min_y,max_y do
            local tile = map[i][j]            
            local los = has_line_of_sight(player.x,player.y,i,j)
            local dist = distance(player.x,player.y,i,j)
            if los and dist <= max_range then
                tile.visible = true
                tile.explored = true
            else
                tile.visible = false
            end
        end
    end
end

-- find a random walkable tile on the map (used for player start position)
function find_empty_tile(map)
    local empty_tiles = {}
    for i=0,#map-1 do
        for j=0,#map[0]-1 do
            --log("checking tile ("..i..","..j..")")
            if map[i][j].walkable then add(empty_tiles, {x=i,y=j}) end
        end
    end
    return empty_tiles[flr(rnd(#empty_tiles))+1]
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
        if p.x == x1 and p.y == y1 then return true end
        local tile = test_map[p.x][p.y]
        if tile.object then
            if tile.object.block_sight then return false end
        end
        if tile and tile.block_sight then
            return false
        end
    end
    return true
end

function map_from_tiles(width, height)
    local small_rooms = {{x=0,y=32},{x=8,y=32},{x=16,y=32},{x=0,y=40},
                         {x=8,y=40},{x=16,y=40},{x=24,y=32},{x=24,y=40}}
    local large_rooms = {{x=0,y=48},{x=16,y=48},{x=32,y=48},{x=48,y=48}}
    local room_w = width/8
    local room_h = height/8
    local map = {}

    -- initialize entire map to solid walls
    for i=0,width-1 do
        map[i] = {}
        for j=0,height-1 do
            map[i][j] = {sprite_id=2, walkable=false, visible=false,
                           explored=false, block_sight=true}
        end
    end

    -- track which 8x8 slots are filled
    local occupied = {}
    for i=0,room_w-1 do
        occupied[i] = {}
        for j=0,room_h-1 do occupied[i][j] = false end
    end

    -- shared helper: write one tile from a spritesheet pixel color
    local function write_tile(mx, my, col)
        if col == 0 then
            map[mx][my] = {sprite_id=2, walkable=false, visible=false,
                           explored=false, block_sight=true}
        elseif col == 2 then
            map[mx][my] = {sprite_id=1, walkable=true, visible=false,
                           explored=false, block_sight=false,
                           object=generate_object("door",3,false,true)}
            map[mx][my].object.state = "closed"
            map[mx][my].object.interact = function(tile)
                tile.object.state = "open"
                tile.object.block_sight = false
                tile.object.sprite_id = 5
                tile.walkable = true
                tile.block_sight = false
            end
        elseif col == 5 then
            map[mx][my] = {sprite_id=1, walkable=true, visible=false,
                           explored=false, block_sight=false}
        end
    end

    for i=0,room_w-1 do
        for j=0,room_h-1 do
            if not occupied[i][j] then
                -- large room requires a free 2x2 block of slots
                local can_large = i+1 < room_w and j+1 < room_h
                    and not occupied[i+1][j]
                    and not occupied[i][j+1]
                    and not occupied[i+1][j+1]

                if can_large and rnd() > 0.75 then
                    local room = large_rooms[flr(rnd(#large_rooms))+1]
                    for x=0,15 do
                        for y=0,15 do
                            write_tile(i*8+x, j*8+y, sget(room.x+x, room.y+y))
                        end
                    end
                    -- mark all four 8x8 slots consumed
                    occupied[i][j]     = true
                    occupied[i+1][j]   = true
                    occupied[i][j+1]   = true
                    occupied[i+1][j+1] = true
                else
                    local room = small_rooms[flr(rnd(#small_rooms))+1]
                    for x=0,7 do
                        for y=0,7 do
                            write_tile(i*8+x, j*8+y, sget(room.x+x, room.y+y))
                        end
                    end
                    occupied[i][j] = true
                end
            end
        end
    end

    -- seal map border
    for i=0,width-1 do
        for j=0,height-1 do
            if i==0 or j==0 or i==width-1 or j==height-1 then
                map[i][j] = {sprite_id=2, walkable=false, visible=false,
                             explored=false, block_sight=true}
            end
        end
    end

    for i=1,width-2 do
        for j=1,height-2 do
            local tile = map[i][j]
            if tile.object and tile.object.state == "closed" then
                -- check right and down neighbors only (avoid double-processing)
                for _,n in ipairs({{i+1,j},{i,j+1}}) do
                    local nx,ny = n[1],n[2]
                    local ntile = map[nx][ny]
                    if ntile.object and ntile.object.state == "closed" then
                        -- replace the neighbor door with a plain floor tile
                        map[nx][ny] = {sprite_id=1, walkable=true, visible=false,
                                    explored=false, block_sight=false}
                    end
                end
            end
        end
    end

    return map
end

function init_log()
    if debug_mode then
        printh(get_local_time()..": -= Log Start =-", "log.txt", true) -- clear log file
    end
end

function log(string)
    if debug_mode then
        printh(get_local_time()..": "..string, "log.txt", false)
    end
end

function get_local_time()
    local year = stat(90)
    local month = stat(91)
    local day = stat(92)    
    local hour = stat(93)
    local minute = stat(94)
    local second = stat(95)
    return year.."-"..month.."-"..day.." "..hour..":"..minute..":"..second
end

function generate_minimap(map)
    local minimap = {}
    for i=0,map_width-1 do
        minimap[i] = {}
        for j=0,map_height-1 do
            local tile = map[i][j]
            if tile.explored and tile.walkable then
                if tile.visible then
                    minimap[i][j] = 11-- white for visible tiles
                else
                    minimap[i][j] = 3 -- dark gray for explored but not visible tiles
                end
            else
                minimap[i][j] = 0 -- black for unexplored tiles
            end
        end
    end
    return minimap
end