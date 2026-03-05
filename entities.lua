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
    mx=0,
    my=0,
    dx=0,
    dy=0,
    move_dist=0,
    sprite_id=21,
    vision_range=6,
    flipped=false,
    state="idle",
    player_last_known_pos={x=0,y=0},
    path={},
    
    update=function(_ENV)
        if state == "take_turn" then
            return take_turn(_ENV)
        elseif state == "moving" then
            return animate_move(_ENV)
        end
        return true  -- turn complete if in any other state
    end,
    
    take_turn=function(_ENV)
        -- check if player is visible (within range and line of sight)
        local dist = distance(x, y, global.pc.x, global.pc.y)
        local can_see_player = dist <= vision_range and has_line_of_sight(x, y, global.pc.x, global.pc.y, vision_range)
        
        -- face the player if visible
        if can_see_player then
            if global.pc.x < x then 
                flipped = true 
            else 
                flipped = false 
            end
        end
        
        -- update AI state
        if state == "idle" or state == "take_turn" then
            if can_see_player then
                state = "chase"
                player_last_known_pos = {x=global.pc.x, y=global.pc.y}
                path = find_path(x, y, player_last_known_pos.x, player_last_known_pos.y)
            end
        end
        
        if state == "chase" then
            -- update last known position if we can still see player
            if can_see_player then
                player_last_known_pos = {x=global.pc.x, y=global.pc.y}
                -- recalculate path if needed
                if #path == 0 or path[#path].x != player_last_known_pos.x or path[#path].y != player_last_known_pos.y then
                    path = find_path(x, y, player_last_known_pos.x, player_last_known_pos.y)
                end
            end
            
            -- try to move along path
            if #path > 0 then
                local next_step = path[1]
                -- if we're already at next step, remove it
                if next_step.x == x and next_step.y == y then
                    deli(path, 1)
                    if #path == 0 then
                        state = "idle"
                        return true  -- turn complete
                    end
                    next_step = path[1]
                end
                
                -- attempt to move
                if #path > 0 then
                    dx = next_step.x - x
                    dy = next_step.y - y
                    if walkable(next_step.x, next_step.y) then
                        -- start move animation
                        move_dist = 8
                        state = "moving"
                        return false  -- still animating
                    else
                        -- path blocked, recalculate
                        path = find_path(x, y, player_last_known_pos.x, player_last_known_pos.y)
                        if #path == 0 then
                            state = "idle"
                        end
                        return true  -- turn complete (couldn't move)
                    end
                end
            else
                -- no path, return to idle
                state = "idle"
                return true  -- turn complete
            end
        end
        
        return true  -- turn complete
    end,
    
    animate_move=function(_ENV)
        mx += dx
        my += dy
        move_dist -= 1
        if move_dist == 0 then
            mx = 0
            my = 0
            x += dx
            y += dy
            deli(path, 1)
            state = "chase"
            return true  -- animation complete, turn done
        end
        return false  -- still animating
    end,
    draw=function(_ENV)
        spr(sprite_id,(x*8)+mx,(y*8)+my,1,1, flipped, false)
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