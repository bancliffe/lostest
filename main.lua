function _init()
    poke( 0x5f2e, 1 )
    debug_mode = true
    global=_ENV
    init_mainmenu()
    init_log()
    _update60 = update_mainmenu
    _draw = draw_mainmenu
end