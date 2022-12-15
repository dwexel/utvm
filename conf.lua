function love.conf(t)
    io.stdout:setvbuf('no')
    t.window.title = "utvm"
    t.identity = "utvm"
    t.modules.physics = false
    t.window.depth = 16
end
