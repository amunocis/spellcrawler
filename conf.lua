function love.conf(t)
    t.title = "Spell-Crawler"
    t.version = "11.4"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.vsync = true

    t.modules.joystick = true
    t.modules.physics = false
end
