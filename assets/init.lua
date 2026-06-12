local spaces = require("hs.spaces")

hs.window.filter.default:subscribe(hs.window.filter.windowFullscreened, function(win)
    if not win then return end

    local screen = hs.screen.mainScreen()
    local s = spaces.spacesForScreen(screen:getUUID())
    if not s then return end

    local target = s[#s]

    if target then
        hs.timer.doAfter(0.1, function()
            spaces.moveWindowToSpace(win:id(), target)
            spaces.gotoSpace(target)
        end)
    end
end)

-- =========================
-- Keymaps
-- =========================

-- Full Screen
hs.hotkey.bind({ "alt", "shift" }, "f", function()
    local win = hs.window.focusedWindow()
    if not win then return end

    win:setFullscreen(not win:isFullscreen())
end)


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

-- Droppy

local activeKey = nil
local oldPos = nil

local function getNotchPos()
    local frame = hs.screen.mainScreen():fullFrame()
    return {
        x = frame.x + frame.w / 2,
        y = frame.y + 25,
    }
end

local function isInNotchZone(pos, notchPos)
    return math.abs(pos.x - notchPos.x) <= 200
        and math.abs(pos.y - notchPos.y) <= 75
end

local function focusDroppy()
    local app = hs.application.get("Droppy")
    if app then
        app:activate(true)
    end
end

local function activateDroppy(key)
    local notchPos = getNotchPos()
    local currentPos = hs.mouse.absolutePosition()

    if not isInNotchZone(currentPos, notchPos) then
        oldPos = currentPos
    end

    hs.mouse.absolutePosition(notchPos)
    focusDroppy()

    activeKey = key
end

local function transitionDroppy(key)
    if oldPos then
        hs.mouse.absolutePosition(oldPos)
    end

    hs.timer.doAfter(0.01, function()
        activateDroppy(key)
    end)
end

local function deactivateDroppy()
    if oldPos then
        hs.mouse.absolutePosition(oldPos)
    end

    activeKey = nil
end

local keys = { "D", "W", "M", "N", "space", "A", "T" }

for _, key in ipairs(keys) do
    hs.hotkey.bind({ "alt", "shift" }, key, function()
        if activeKey == key then
            deactivateDroppy()
        elseif activeKey ~= nil then
            transitionDroppy(key)
        else
            activateDroppy(key)
        end
    end)
end

-- local app = hs.application.get("Droppy")
-- print(hs.inspect(app:allWindows()))
-- for _, app in ipairs(hs.application.runningApplications()) do
--     print(app:name())
-- end
--
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

hs.hotkey.bind({ "cmd", "shift" }, "return", function()
    launchKittyWithNvim()
end)

-- hs.hotkey.bind({ "cmd", "shift" }, "return", function()
--     hs.task
--         .new("/bin/zsh", nil, {
--             "-lc",
--             "open -n -a Kitty",
--         })
--         :start()
-- end)

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
