function init_map()
    map_width = 32
    map_height = 32
    test_map = map_from_tiles(map_width,map_height)
    local empty_tile = find_empty_tile(test_map)
    player=generate_character(empty_tile.x, empty_tile.y)
    minimap = generate_minimap(test_map)

    camera_x = 0
    camera_y = 0
    camera_dest_x = 0
    camera_dest_y = 0
end

function update_map()
    player.update()
    update_los(test_map)
    minimap = generate_minimap(test_map)
    dest_camera_x = player.x * 8 - 64
    dest_camera_y = player.y * 8 - 64
    camera_x += (dest_camera_x - camera_x) * 0.2
    camera_y += (dest_camera_y - camera_y) * 0.2
end

function draw_map()
    cls(0)
    fillp(0x5f5f)
    rectfill(0,0,128,128,1)
    fillp()
    camera(camera_x, camera_y)
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
    player.draw()
    palt()  
    draw_ui()
end

function draw_ui()
    camera()
    --print("x:"..player.x.." y:"..player.y,2,2,7)
    draw_minimap(1,1)
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