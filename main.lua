function _init()
    --poke(0x5f2e,1)
    --pal({[0]=0,-15,1,-4,12,-13,3,-5,11,-6,-14,2,-3,-8,8,7},1)
    init_mainmenu()
    _update = update_mainmenu
    _draw = draw_mainmenu
end