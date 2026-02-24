function generate_character(x,y)
    player={
    x=x or 0,
    y=y or 0,
    sprite_id=16,
    vision_range=5,
    update=function()
        if btnp(⬆️) then player.y -= 1 end
        if btnp(⬇️) then player.y += 1 end
        if btnp(⬅️) then player.x -= 1 end
        if btnp(➡️) then player.x += 1 end
        player.x = mid(0,map_width-1,player.x)
        player.y = mid(0,map_height-1,player.y)
    end,
    draw=function()
        spr(player.sprite_id,player.x*8,player.y*8)
    end
    }
    return player
end
