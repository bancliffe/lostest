function init_map()
    map_width = 16
    map_height = 16
    test_map = generate_map(map_width,map_height)
    test_character={x=6,y=6,sprite_id=16,vision_range=5}
end

function update_map()
    if btnp(⬆️) then test_character.y = test_character.y - 1 end
    if btnp(⬇️) then test_character.y = test_character.y + 1 end
    if btnp(⬅️) then test_character.x = test_character.x - 1 end
    if btnp(➡️) then test_character.x = test_character.x + 1 end
    test_character.x = mid(0,map_width-1,test_character.x)
    test_character.y = mid(0,map_height-1,test_character.y)
    update_los(test_map)
end

function draw_map()
    cls(0)
    for i=0,map_width-1 do
        for j=0,map_height-1 do
            local tile = test_map[i][j]
            if tile.visible then
                spr(tile.sprite_id,i*8,j*8)
            elseif not tile.visible and tile.explored then   
                pal(5,1)
                pal(6,5)
                spr(tile.sprite_id,i*8,j*8)
                pal()
            end
        end
    end
    palt(0,false)
    palt(14,true)
    spr(test_character.sprite_id,test_character.x*8,test_character.y*8)
    palt()  
end