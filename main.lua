function _init()
    debug_mode = true
    init_mainmenu()
    init_log()
    _update = update_mainmenu
    _draw = draw_mainmenu
end