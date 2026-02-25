function init_map()
    map_width = 64
    map_height = 64
    test_map = map_from_tiles(map_width,map_height)
    local empty_tile = find_empty_tile(test_map)
    player=generate_character(empty_tile.x, empty_tile.y)

    camera_x = 0
    camera_y = 0
    camera_dest_x = 0
    camera_dest_y = 0
end

function update_map()
    player.update()
    update_los(test_map)
    dest_camera_x = player.x * 8 - 64
    dest_camera_y = player.y * 8 - 64
    camera_x += (dest_camera_x - camera_x) * 0.2
    camera_y += (dest_camera_y - camera_y) * 0.2
end

function draw_map()
    cls(0)
    camera(camera_x, camera_y)
    for i=0,map_width-1 do
        for j=0,map_height-1 do
            local tile = test_map[i][j]
            if tile.visible then
                spr(tile.sprite_id,i*8,j*8)
                if tile.object then
                    palt(0,false)
                    palt(14,true)
                    spr(tile.object.sprite_id,i*8,j*8)
                    palt()
                end
            elseif not tile.visible and tile.explored then   
                pal(5,1)
                pal(6,5)
                spr(tile.sprite_id,i*8,j*8)
                palt(0,false)
                if tile.object then
                    palt(14,true)
                    spr(tile.object.sprite_id,i*8,j*8)
                    palt()
                end
                pal()
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
    print("x:"..player.x.." y:"..player.y,2,2,7)
end