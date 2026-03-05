class=setmetatable({
    new=function(self,tbl)
        tbl = tbl or {}
        setmetatable(tbl,{
            __index=self
        })
        return tbl  
    end
}, {__index=_ENV}) 

entity=class:new({
    x=0,
    y=0,
    sprite_id=0,
    vision_range=0,
    update=function() end,
    draw=function() end
})

object=class:new({
    name="undefined",
    sprite_id=0,
    walkable=false,
    block_sight=false,
    interact=function(self) end
})

player=entity:new({
    x=x or 0,
    y=y or 0,
    sprite_id=16,
    vision_range=6,
    flipped=false,
    state="idle",
    
    update=function(_ENV)
        local dx,dy=0,0
        if btnp(⬆️) then dy -= 1 end
        if btnp(⬇️) then dy += 1 end
        if btnp(⬅️) then dx -= 1 flipped=true end
        if btnp(➡️) then dx += 1 flipped=false end
        -- check for interactable objects before moving
        local tile = test_map[x+dx] and test_map[x+dx][y+dy]
        if tile then
            if tile.object then
                if tile.object.name=="door" and tile.object.state=="open" then
                    x = mid(0,map_width-1,x + dx)
                    y = mid(0,map_height-1,y + dy)
                elseif tile.object.name=="door" and tile.object.state=="closed" then
                    tile.object.interact(tile)
                end
            elseif test_map[x+dx] and test_map[x+dx][y+dy] and test_map[x+dx][y+dy].walkable then
                x = mid(0,map_width-1,x + dx)
                y = mid(0,map_height-1,y + dy)
            end
        end
        if btnp(❎) then
            global.show_minimap = not global.show_minimap
        end
    end,

    draw=function(_ENV)
         if state=="idle" then
            local sx = (sprite_id%16)*8
            local sy = (sprite_id\16)*8
            sspr(sx,sy,8,8,x*8,y*8,8,8, flipped, false)            
        else 
            spr(sprite_id,x*8,y*8,1,1, flipped, false)
         end
    end
})

npc = entity:new({
    x=x or 0,
    y=y or 0,
    sprite_id=21,
    vision_range=4,
    flipped=false,
    update=function(_ENV) if global.pc.x < x then flipped = true else flipped =false end end,
    draw=function(_ENV)
        spr(sprite_id,x*8,y*8,1,1, flipped, false)
    end
})

function generate_object(name, sprite_id, walkable, block_sight)
    return object:new({
        name=name,
        sprite_id=sprite_id,
        walkable=walkable,
        block_sight=block_sight
    })
end