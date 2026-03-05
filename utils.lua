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
    local max_range = pc.vision_range
    local max_x = pc.x + max_range
    local min_x = pc.x - max_range
    local max_y = pc.y + max_range
    local min_y = pc.y - max_range
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
            local los = has_line_of_sight(pc.x,pc.y,i,j,max_range)
            local dist = distance(pc.x,pc.y,i,j)
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
function find_empty_tile(map,minx,maxx,miny,maxy)
    minx = minx or 0
    maxx = maxx or #map-1
    miny = miny or 0
    maxy = maxy or #map[0]-1
    local empty_tiles = {}
    for i=minx,maxx do
        for j=miny,maxy do
            --log("checking tile ("..i..","..j..")")
            if map[i][j].sprite_id==1 and map[i][j].object == nil and get_character_at(i,j) == nil then add(empty_tiles, {x=i,y=j}) end
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
function has_line_of_sight(x0,y0,x1,y1,max_range)
    max_range = max_range or 5
    local pts = bresenham(x0,y0,x1,y1)
    if #pts > max_range then return false end
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
                sfx(0)
                tile.object.state = "open"
                tile.object.block_sight = false
                tile.object.sprite_id = 5
                tile.object.walkable = true
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

function walkable(x,y)
    local tile = test_map[x][y]
    if tile.object and not tile.object.walkable then return false end
    return tile and tile.walkable and not get_character_at(x,y)
end

function interactable(x,y)
    local tile = test_map[x][y]
    if tile.object and tile.object.interact then return true end
    for i=1,#global.characters do
        if global.characters[i].x == x and global.characters[i].y == y and global.characters[i].interact then
             return true
        end
    end
    return false
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

function get_character_at(x,y)
    for i=1,#global.characters do
        if global.characters[i].x == x and global.characters[i].y == y then
            return global.characters[i]
        end
    end
    return nil
end

function find_path(start_x,start_y,goal_x,goal_y)
    -- A* pathfinding with orthogonal movement only
    if start_x == goal_x and start_y == goal_y then return {} end
    
    -- check if goal tile itself is walkable (ignore character occupancy for goal)
    if test_map[goal_x] and test_map[goal_x][goal_y] then
        local goal_tile = test_map[goal_x][goal_y]
        if not goal_tile.walkable then return {} end
        if goal_tile.object and not goal_tile.object.walkable then return {} end
    else
        return {}
    end
    
    local function manhattan(x1, y1, x2, y2)
        return abs(x1 - x2) + abs(y1 - y2)
    end
    
    local open_list = {}
    local closed_set = {}
    local came_from = {}
    local g_score = {}
    local f_score = {}
    
    -- initialize start node
    local start_key = start_x..","..start_y
    add(open_list, {x=start_x, y=start_y})
    g_score[start_key] = 0
    f_score[start_key] = manhattan(start_x, start_y, goal_x, goal_y)
    
    while #open_list > 0 do
        -- find node in open_list with lowest f_score
        local current_idx = 1
        local current = open_list[1]
        local current_key = current.x..","..current.y
        for i=2,#open_list do
            local node = open_list[i]
            local node_key = node.x..","..node.y
            if f_score[node_key] < f_score[current_key] then
                current_idx = i
                current = node
                current_key = node_key
            end
        end
        
        -- reached goal?
        if current.x == goal_x and current.y == goal_y then
            -- reconstruct path
            local path = {}
            local key = current_key
            while came_from[key] do
                local coords = came_from[key]
                add(path, {x=coords.x, y=coords.y})
                key = coords.x..","..coords.y
            end
            -- reverse path and add goal
            local final_path = {}
            for i=#path,1,-1 do
                add(final_path, path[i])
            end
            add(final_path, {x=goal_x, y=goal_y})
            return final_path
        end
        
        -- move current from open to closed
        deli(open_list, current_idx)
        closed_set[current_key] = true
        
        -- check 4 neighbors (orthogonal only: up, down, left, right)
        local neighbors = {
            {x=current.x, y=current.y-1},
            {x=current.x, y=current.y+1},
            {x=current.x-1, y=current.y},
            {x=current.x+1, y=current.y}
        }
        
        for i=1,#neighbors do
            local neighbor = neighbors[i]
            local nx, ny = neighbor.x, neighbor.y
            local neighbor_key = nx..","..ny
            
            -- check if valid and walkable
            if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height then
                if (nx == goal_x and ny == goal_y) or walkable(nx, ny) then
                    if not closed_set[neighbor_key] then
                        local tentative_g = g_score[current_key] + 1
                        
                        -- check if neighbor is in open_list
                        local in_open = false
                        for j=1,#open_list do
                            if open_list[j].x == nx and open_list[j].y == ny then
                                in_open = true
                                break
                            end
                        end
                        
                        if not in_open or tentative_g < (g_score[neighbor_key] or 9999) then
                            came_from[neighbor_key] = {x=current.x, y=current.y}
                            g_score[neighbor_key] = tentative_g
                            f_score[neighbor_key] = tentative_g + manhattan(nx, ny, goal_x, goal_y)
                            
                            if not in_open then
                                add(open_list, {x=nx, y=ny})
                            end
                        end
                    end
                end
            end
        end
    end
    
    return {} -- no path found
end