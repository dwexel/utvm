function love.conf(t)
    io.stdout:setvbuf('no')
    t.window.title = "utvm"
    t.identity = "utvm"
    t.window.depth = 16

    t.window.resizable = true
    t.modules.physics = false

end
