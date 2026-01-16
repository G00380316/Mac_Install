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
            if not win:isFullScreen() then
                win:setFullScreen(true)
            end
        else
            win:maximize()
        end
    end)
end

--------------------------------------------------
-- Kitty shortcuts
--------------------------------------------------

-- macOS Desktop & Dock settings (REQUIRED)
-- System Settings → Desktop & Dock
-- ❌ Close windows when quitting an application = OFF
--    Prevents macOS window restoration from crashing apps
--    (notably Kitty) when launched via Hammerspoon.
--
-- Recommended:
-- • Prefer tabs when opening documents → Never
-- • Show recent applications in Dock → Off

-- In order to remove errors when opening kitty
local function launchKittyWithNvim()
    -- Always start a clean instance
    hs.task
        .new("/bin/zsh", nil, {
            "-lc",
            "open -n -a Kitty --args nvim",
        })
        :start()
end

hs.hotkey.bind({ "cmd" }, "return", function()
    launchKittyWithNvim()
end)

hs.hotkey.bind({ "cmd", "shift" }, "return", function()
    hs.task
        .new("/bin/zsh", nil, {
            "-lc",
            "open -n -a Kitty",
        })
        :start()
end)

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
