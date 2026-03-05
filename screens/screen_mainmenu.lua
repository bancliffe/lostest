function init_mainmenu()
    choices = {"new game","exit"}
    choice = 1
end

function update_mainmenu()
    if btnp(⬆️) then
        choice = max(choice-1,1)
    elseif btnp(⬇️) then
        choice = min(choice+1,#choices)
    end

    if btnp(🅾️) then
        if choice == 1 then
            init_map()
            _update60 = update_map
            _draw = draw_map
        elseif choice == 2 then
            -- exit game
        end
    end
end

function draw_mainmenu()
    cls(0)
    printc("los test", 64, 20, 7)
    for i, c in ipairs(choices) do
        local col = 7
        if i == choice then
            col = 11
        end
        printc(c, 64, 40+i*10, col)
    end
end