function printc(string,x,y,col)
    local w = print(string,0,-6,col)
    print(string,x-w/2,y,col)
end

function generate_map(width,height)
    if not width then width = 64 end
    if not height then height = 64 end
    local map = {}
    for i=0,width-1 do
        map[i] = {}
        for j=0,height-1 do
            map[i][j] = {sprite_id=2, walkable=false, visible=false, explored=false, block_sight=true}
        end
    end

    -- BSP parameters
    local MIN_LEAF_SIZE = 8
    local MAX_LEAF_SIZE = 20
    local MIN_ROOM_SIZE = 3

    -- Leaf struct
    local function new_leaf(x,y,w,h)
        return {x=x,y=y,w=w,h=h,left=nil,right=nil,room=nil}
    end

    local leaves = {}
    add(leaves, new_leaf(0,0,width,height))

    -- try to split leaves until no more splits possible
    local function split_leaf(leaf)
        if leaf.left or leaf.right then return false end
        local split_h
        if leaf.w / leaf.h >= 1.25 then split_h = false
        elseif leaf.h / leaf.w >= 1.25 then split_h = true
        else split_h = rnd() > 0.5 end

        local max_split = (split_h and leaf.h or leaf.w) - MIN_LEAF_SIZE
        if max_split <= MIN_LEAF_SIZE then return false end

        local split = flr(rnd(max_split - MIN_LEAF_SIZE)) + MIN_LEAF_SIZE
        if split_h then
            leaf.left = new_leaf(leaf.x, leaf.y, leaf.w, split)
            leaf.right = new_leaf(leaf.x, leaf.y + split, leaf.w, leaf.h - split)
        else
            leaf.left = new_leaf(leaf.x, leaf.y, split, leaf.h)
            leaf.right = new_leaf(leaf.x + split, leaf.y, leaf.w - split, leaf.h)
        end
        return true
    end

    -- repeatedly split
    local did_split = true
    while did_split do
        did_split = false
        for i=1,#leaves do
            local l = leaves[i]
            if not (l.left or l.right) then
                if (l.w > MAX_LEAF_SIZE) or (l.h > MAX_LEAF_SIZE) or (rnd() > 0.8) then
                    if split_leaf(l) then
                        add(leaves, l.left)
                        add(leaves, l.right)
                        did_split = true
                    end
                end
            end
        end
    end

    -- collect final leaves (those without children)
    local final_leaves = {}
    for i=1,#leaves do
        local l = leaves[i]
        if not (l.left or l.right) then add(final_leaves, l) end
    end

    -- create a room inside a leaf
    local function create_room(leaf)
        local room_w = flr(rnd(leaf.w - 2)) + MIN_ROOM_SIZE
        local room_h = flr(rnd(leaf.h - 2)) + MIN_ROOM_SIZE
        if room_w >= leaf.w then room_w = leaf.w - 2 end
        if room_h >= leaf.h then room_h = leaf.h - 2 end
        local room_x = leaf.x + flr(rnd(leaf.w - room_w - 1)) + 1
        local room_y = leaf.y + flr(rnd(leaf.h - room_h - 1)) + 1
        leaf.room = {x=room_x,y=room_y,w=room_w,h=room_h}
        -- carve room
        for i=room_x,room_x+room_w-1 do
            for j=room_y,room_y+room_h-1 do
                if i>=0 and i<width and j>=0 and j<height then
                    map[i][j] = {sprite_id=1, walkable=true, visible=false, explored=false, block_sight=false}
                end
            end
        end
        return leaf.room
    end

    -- get center of a room
    local function center(room)
        return flr(room.x + room.w/2), flr(room.y + room.h/2)
    end

    -- returns true if (x,y) is inside a room's floor area
    local function in_room(x,y,room)
        return x>=room.x and x<room.x+room.w
           and y>=room.y and y<room.y+room.h
    end

    -- place a door tile
    local function place_door(x,y)
        if x>=0 and x<width and y>=0 and y<height then
            map[x][y].object = generate_object("door",3,false,true)
            map[x][y].object.state = "closed"
            map[x][y].object.interact = function(tile)
                tile.object.state = "open"
                tile.object.block_sight = false
                tile.object.sprite_id = 5          
                tile.walkable = true
                tile.block_sight = false
            end
        end
    end

    -- create corridor between two points (L-shaped) and place doors at each room exit
    local function create_corridor(x1,y1,x2,y2,r1,r2)
        if rnd() > 0.5 then
            -- horizontal leg then vertical leg
            for x=min(x1,x2),max(x1,x2) do
                if x>=0 and x<width and y1>=0 and y1<height then
                    map[x][y1] = {sprite_id=1, walkable=true, visible=false, explored=false, block_sight=false}
                end
            end
            for y=min(y1,y2),max(y1,y2) do
                if x2>=0 and x2<width and y>=0 and y<height then
                    map[x2][y] = {sprite_id=1, walkable=true, visible=false, explored=false, block_sight=false}
                end
            end
            -- door1: first tile on horizontal leg that exits room1
            local sx = x2>=x1 and 1 or -1
            for x=x1,x2,sx do
                if not in_room(x,y1,r1) then place_door(x,y1) break end
            end
            -- door2: first tile on vertical leg that exits room2 (walking from room2 center toward bend)
            local sy = y1>=y2 and 1 or -1
            for y=y2,y1,sy do
                if not in_room(x2,y,r2) then place_door(x2,y) break end
            end
        else
            -- vertical leg then horizontal leg
            for y=min(y1,y2),max(y1,y2) do
                if x1>=0 and x1<width and y>=0 and y<height then
                    map[x1][y] = {sprite_id=1, walkable=true, visible=false, explored=false, block_sight=false}
                end
            end
            for x=min(x1,x2),max(x1,x2) do
                if x>=0 and x<width and y2>=0 and y2<height then
                    map[x][y2] = {sprite_id=1, walkable=true, visible=false, explored=false, block_sight=false}
                end
            end
            -- door1: first tile on vertical leg that exits room1
            local sy = y2>=y1 and 1 or -1
            for y=y1,y2,sy do
                if not in_room(x1,y,r1) then place_door(x1,y) break end
            end
            -- door2: first tile on horizontal leg that exits room2 (walking from room2 center toward bend)
            local sx = x1>=x2 and 1 or -1
            for x=x2,x1,sx do
                if not in_room(x,y2,r2) then place_door(x,y2) break end
            end
        end
    end

    -- create rooms for each final leaf
    for i=1,#final_leaves do
        create_room(final_leaves[i])
    end

    -- helper to find a room in a leaf or its children
    local function leaf_room(leaf)
        if not leaf then return nil end
        if leaf.room then return leaf.room end
        local l = leaf_room(leaf.left)
        if l then return l end
        return leaf_room(leaf.right)
    end

    -- connect rooms by walking the BSP tree
    local function connect_children(leaf)
        if not leaf or (not leaf.left and not leaf.right) then return end
        connect_children(leaf.left)
        connect_children(leaf.right)
        local r1 = leaf_room(leaf.left)
        local r2 = leaf_room(leaf.right)
        if r1 and r2 then
            local x1,y1 = center(r1)
            local x2,y2 = center(r2)
            create_corridor(x1,y1,x2,y2,r1,r2)
        end
    end

    connect_children(leaves[1])

    return map
end

function distance(x0,y0,x1,y1)
    return sqrt((x1-x0)^2 + (y1-y0)^2)
end

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

function find_path(start_x,start_y,end_x,end_y)
    -- placeholder for pathfinding algorithm (e.g. A*)
    return {}
end

function find_empty_tile(map)
    local empty_tiles = {}
    for i=0,map_width-1 do
        for j=0,map_height-1 do
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

