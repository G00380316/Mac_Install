-- Generic app launcher
local function launchApp(appName, opts)
    opts = opts or {}
    local fullscreen = opts.fullscreen

    local app = hs.application.get(appName)

    -- If app exists and has at least one window, do nothing
    if app and #app:allWindows() > 0 then
        return
    end

    hs.application.launchOrFocus(appName)

    hs.timer.doAfter(0.6, function()
        local app = hs.application.get(appName)
        if not app then
            return
        end

        local win = app:mainWindow()
        if not win then
            return
        end

        if fullscreen then
            -- True macOS fullscreen
            if not win:isFullScreen() then
                win:setFullScreen(true)
            end
        else
            win:maximize()
        end
    end)
end

--------------------------------------------------
-- App shortcuts
--------------------------------------------------

-- Firefox (⌥ + F)
hs.hotkey.bind({ "alt" }, "f", function()
    launchApp("Firefox")
end)

-- VS Code (⌥ + C)
hs.hotkey.bind({ "alt" }, "c", function()
    launchApp("Visual Studio Code")
end)

-- Xcode (⌥ + X)
hs.hotkey.bind({ "alt" }, "x", function()
    launchApp("Xcode")
end)

-- Kodi (⌥ + K) → fullscreen
hs.hotkey.bind({ "alt" }, "k", function()
    launchApp("Kodi", { fullscreen = true })
end)

-- Stremio (⌥ + M) → fullscreen
hs.hotkey.bind({ "alt" }, "m", function()
    launchApp("Stremio", { fullscreen = true })
end)

hs.hotkey.bind({ "cmd" }, "return", function()
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
