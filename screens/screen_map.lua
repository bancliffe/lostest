function init_map()
    map_width = 32
    map_height = 32
    global.show_minimap = false
    global.characters={}
    test_map = map_from_tiles(map_width,map_height)
    local empty_tile = find_empty_tile(test_map,0,8,0,8)
    global.pc=player:new({x=empty_tile.x, y=empty_tile.y})
    my_camera = game_camera:new({target=global.pc})
    minimap = generate_minimap(test_map)    
    add(global.characters,global.pc)
    
    for i=1,30 do
        local empty_tile = find_empty_tile(test_map)
        local sprite_id = 17 + flr(rnd(5))
        local c = npc:new({x=empty_tile.x, y=empty_tile.y,sprite_id=sprite_id})
        add(global.characters, c)
    end
    
    -- turn-based system
    player_acted = false
    update_los(test_map)
end

function update_map()
    -- player turn
    player_acted = global.pc:update()
    
    -- if player acted, update all NPCs
    if player_acted then
        for i=2,#global.characters do
            global.characters[i]:update()
        end
        update_los(test_map)
        minimap = generate_minimap(test_map)
    end    
    my_camera:update()    
end

function draw_map()
    cls(0)
    fillp(0x5f5f)
    rectfill(0,0,128,128,1)
    fillp()
    camera(my_camera.x, my_camera.y)
    for i=0,map_width-1 do
        for j=0,map_height-1 do
            local tile = test_map[i][j]
            if tile.visible then
                palt(0,false)
                palt(14,true)
                spr(tile.sprite_id,i*8,j*8)
                if tile.object then   
                    spr(tile.object.sprite_id,i*8,j*8)
                end
                palt()
            end
        end
    end
    palt(0,false)
    palt(14,true)
    for i=1,#global.characters do
        if test_map[global.characters[i].x] and test_map[global.characters[i].x][global.characters[i].y] and test_map[global.characters[i].x][global.characters[i].y].visible then
            global.characters[i]:draw()
        end
    end
    palt()  
    draw_ui()    
end

function draw_ui()
    camera()
    if global.show_minimap then
        draw_minimap(1,1)
    end
end

function draw_minimap(x, y)
    rectfill(x-1,y-1,x+32,y+32,0)
    rect(x-1,y-1,x+32,y+32,7)
    for i=0,#minimap-1 do
        for j=0,#minimap[0]-1 do
            pset(x+i,y+j,minimap[i][j])
        end
    end
end