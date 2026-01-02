s.hotkey.bind({ "cmd" }, "return", function()
    local app = hs.application.get("kitty")

    -- If kitty exists AND has at least one window, do nothing
    if app and #app:allWindows() > 0 then
        return
    end

    hs.task
        .new("/bin/zsh", nil, {
            "-lc",
            "cd ~ && /Applications/kitty.app/Contents/MacOS/kitty --detach nvim",
        })
        :start()

    hs.timer.doAfter(0.5, function()
        local app = hs.application.get("kitty")
        if app then
            local win = app:mainWindow()
            if win then
                win:maximize()
            end
        end
    end)
end)

hs.hotkey.bind({ "cmd", "shift" }, "return", function()
    local app = hs.application.get("kitty")

    -- If kitty exists AND has at least one window, do nothing
    if app and #app:allWindows() > 0 then
        return
    end

    hs.task
        .new("/bin/zsh", nil, {
            "-lc",
            "cd ~ && /Applications/kitty.app/Contents/MacOS/kitty --detach",
        })
        :start()

    hs.timer.doAfter(0.5, function()
        local app = hs.application.get("kitty")
        if app then
            local win = app:mainWindow()
            if win then
                win:maximize()
            end
        end
    end)
end)
