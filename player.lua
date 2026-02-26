function generate_character(x,y)
    player={
    x=x or 0,
    y=y or 0,
    sprite_id=16,
    vision_range=6,
    update=function()
        local dx,dy=0,0
        if btnp(⬆️) then dy -= 1 end
        if btnp(⬇️) then dy += 1 end
        if btnp(⬅️) then dx -= 1 end
        if btnp(➡️) then dx += 1 end
        -- check for interactable objects before moving
        local tile = test_map[player.x+dx] and test_map[player.x+dx][player.y+dy]
        if tile then
            if tile.object then
                if tile.object.name=="door" and tile.object.state=="open" then
                    player.x = mid(0,map_width-1,player.x + dx)
                    player.y = mid(0,map_height-1,player.y + dy)
                elseif tile.object.name=="door" and tile.object.state=="closed" then
                    tile.object.interact(tile)
                end
            elseif test_map[player.x+dx] and test_map[player.x+dx][player.y+dy] and test_map[player.x+dx][player.y+dy].walkable then
                player.x = mid(0,map_width-1,player.x + dx)
                player.y = mid(0,map_height-1,player.y + dy)
            end
        end
    end,
    draw=function()
        spr(player.sprite_id,player.x*8,player.y*8)
    end
    }
    return player
end

function generate_object(name,sprite_id,walkable,block_sight)
    return {
        name=name or "undefined",
        sprite_id=sprite_id or 0,
        walkable=walkable or false,
        block_sight=block_sight or false,
        interact=function()
           -- placeholder for object interaction logic (e.g. opening a door, picking up an item)
        end
    }
end