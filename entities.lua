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
    interact=function(_ENV) end
})

player=entity:new({
    x=x or 0,
    y=y or 0,
    mx=0,
    my=0,
    sprite_id=16,
    vision_range=6,
    dx=0,
    dy=0,
    move_dist=0,
    flipped=false,
    state="idle",

    update=function(_ENV)
        if state == "idle" then
            return move_or_interact(_ENV)
        elseif state == "move" then
            return move_player(_ENV)
        elseif state == "bump" then
            return bump_player(_ENV)
        end
    end,

    bump_player=function(_ENV)
        mx+=dx
        my+=dy
        move_dist-=1
        if move_dist==4 then
            dx *= -1
            dy *= -1
        end
        if move_dist==0 then
            state="idle"
            mx=0
            my=0
            return true
        end
        return false
    end,

    move_player=function(_ENV)
        mx+=dx
        my+=dy
        move_dist-=1
        if move_dist==0 then
            state="idle"
            mx=0
            my=0
            x+=dx
            y+=dy
            return true
        end
        return false
    end,

    move_or_interact=function(_ENV)
        local action_taken = false
        dx,dy=0,0
        if btnp(⬆️) then dy -= 1
        elseif btnp(⬇️) then dy += 1 
        elseif btnp(⬅️) then dx -= 1 flipped=true 
        elseif btnp(➡️) then dx += 1 flipped=false end

        -- check for interactable objects before moving
        if dx != 0 or dy != 0 then
            if walkable(x+dx,y+dy) then
                move_dist=8
                state="move"
            elseif interactable(x+dx,y+dy) then
                local tile = test_map[x+dx] and test_map[x+dx][y+dy]
                if tile and tile.object then
                    tile.object.interact(tile)
                    move_dist=8
                    state="bump"
                end
                for i=1,#global.characters do
                    local c = global.characters[i]
                    if c.x == x+dx and c.y == y+dy and c.interact then
                        c.interact(c)
                        move_dist=8
                        state="bump"
                        break
                    end
                end
            end
        end
        if btnp(❎) then
            global.show_minimap = not global.show_minimap
        end
        return action_taken
    end,

    draw=function(_ENV)
        spr(sprite_id,(x*8)+mx,(y*8)+my,1,1, flipped, false)
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
    end,
    interact=function(_ENV)
        log("mob interaction with player at ("..x..","..y..")")
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