--==================================================
-- SAFE FILE & EXECUTION API WRAPPERS
--==================================================

local isfile = (type(isfile) == "function" and isfile) or (type(is_file) == "function" and is_file) or function() return false end
local readfile = (type(readfile) == "function" and readfile) or (type(read_file) == "function" and read_file) or function() return "" end
local writefile = (type(writefile) == "function" and writefile) or (type(write_file) == "function" and write_file) or function() end

local function getQueueOnTeleport()
    if type(queue_on_teleport) == "function" then return queue_on_teleport end
    if syn and type(syn.queue_on_teleport) == "function" then return syn.queue_on_teleport end
    if type(queueonteleport) == "function" then return queueonteleport end
    if fluxus and type(fluxus.queue_on_teleport) == "function" then return fluxus.queue_on_teleport end
    return nil
end

-- Ultra Safe Loadstring to completely prevent "attempt to call a nil value"
local function safeLoadstring(url)
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and type(content) == "string" and #content > 0 then
        local loadFunc = (type(loadstring) == "function" and loadstring) or (type(load_string) == "function" and load_string)
        if loadFunc then
            local compileOk, compiledFunc = pcall(loadFunc, content)
            if compileOk and type(compiledFunc) == "function" then
                local execOk, result = pcall(compiledFunc)
                if execOk then
                    return result
                end
            end
        end
    end
    return nil
end

--==================================================
-- OBSIDIAN UI + BEAT SURVIVOR
--==================================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = safeLoadstring(repo .. "Library.lua")
local ThemeManager = safeLoadstring(repo .. "addons/ThemeManager.lua")
local SaveManager = safeLoadstring(repo .. "addons/SaveManager.lua")

if not Library or type(Library) ~= "table" then
    warn("[Fatal Error] UI Library failed to load!")
    return
end

local Options = Library.Options or {}
local Toggles = Library.Toggles or {}

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

--==================================================
-- WINDOW & TABS
--==================================================

local Window = Library:CreateWindow({
    Title = "",
    Footer = "version: 1.0.3",
    Icon = "bot",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

if Window and Window.SetSidebarWidth then
    pcall(function() Window:SetSidebarWidth(40) end)
end

local Tabs = {
    AutoFarm = Window:AddTab("", "zap"),
    Settings = Window:AddTab("", "settings"),
}

local AutoFarmGroup = Tabs.AutoFarm:AddLeftGroupbox("Auto Farm", "zap")
local WebhookGroup = Tabs.AutoFarm:AddRightGroupbox("Webhook", "webhook")

--==================================================
-- BEAT SURVIVOR STATE
--==================================================

local BeatState = {
    LastFinishPos = nil,
    BeatSurvivorDone = false,
}

--==================================================
-- HELPER FUNCTIONS
--==================================================

local function GetRole()
    local player = game:GetService("Players").LocalPlayer
    if not player or not player.Team then return "Unknown" end

    local name = player.Team.Name
    if name == "Killer" then return "Killer" end
    if name == "Survivors" or name == "Survivor" then return "Survivor" end
    if name == "Spectator" or name == "Spectators" then return "Spectator" end

    return "Lobby"
end

local function GetCharacterRoot()
    local player = game:GetService("Players").LocalPlayer
    local character = player and player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function safeRequest(options)
    local req = nil
    pcall(function()
        req = (syn and syn.request) 
           or (http and http.request) 
           or http_request 
           or request 
           or (fluxus and fluxus.request)
           or (krnl and krnl.request)
    end)

    if type(req) == "function" then
        return req(options)
    end
    return nil
end

local function GetExecutorName()
    local name = "Unknown Executor"
    pcall(function()
        if type(identifyexecutor) == "function" then
            name = identifyexecutor()
        elseif type(getexecutorname) == "function" then
            name = getexecutorname()
        end
    end)
    return name
end

--==================================================
-- WEBHOOK SYSTEM
--==================================================

local function SendDiscordWebhook(customTitle, customDesc, forceSend)
    if not forceSend and (not Toggles.EnableWebhook or not Toggles.EnableWebhook.Value) then
        return false, "Webhook Disabled"
    end

    local webhookUrl = Options.WebhookLink and Options.WebhookLink.Value or ""
    if not webhookUrl or webhookUrl == "" or not string.find(webhookUrl, "discord.com/api/webhooks") then
        return false, "Invalid Webhook URL"
    end

    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local MarketplaceService = game:GetService("MarketplaceService")
    local LocalPlayer = Players.LocalPlayer

    local gameName = "Unknown Game"
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)

    local username = LocalPlayer and LocalPlayer.Name or "Unknown"
    local displayName = LocalPlayer and LocalPlayer.DisplayName or "Unknown"
    local userId = LocalPlayer and LocalPlayer.UserId or 0
    local profileUrl = "https://www.roblox.com/users/" .. userId .. "/profile"
    local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
    local executorName = GetExecutorName()
    local currentRole = GetRole()
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    local payload = {
        ["username"] = "VD Auto Farm Logger",
        ["avatar_url"] = "https://cdn-icons-png.flaticon.com/512/2092/2092663.png",
        ["embeds"] = {{
            ["title"] = customTitle or "🚀 VD Auto Farm Notification",
            ["description"] = customDesc or "Notification trigger from **VD Auto Farm Loader**.",
            ["color"] = 5793266,
            ["timestamp"] = timestamp,
            ["thumbnail"] = { ["url"] = avatarUrl },
            ["fields"] = {
                {
                    ["name"] = "👤 Player Info",
                    ["value"] = string.format("**Display:** %s\n**Username:** [%s](%s)\n**User ID:** `%d`", displayName, username, profileUrl, userId),
                    ["inline"] = true
                },
                {
                    ["name"] = "⚡ Executor",
                    ["value"] = string.format("`%s`", executorName),
                    ["inline"] = true
                },
                {
                    ["name"] = "🎮 Game Details",
                    ["value"] = string.format("**Game:** %s\n**Place ID:** `%d`\n**Role:** `%s`", gameName, game.PlaceId, currentRole),
                    ["inline"] = false
                },
                {
                    ["name"] = "📌 Server Job ID",
                    ["value"] = string.format("```lua\n%s\n```", (game.JobId ~= "" and game.JobId or "Singleplayer / Local")),
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "VD Auto Farm System",
                ["icon_url"] = "https://cdn-icons-png.flaticon.com/512/2092/2092663.png"
            }
        }}
    }

    local response = safeRequest({
        Url = webhookUrl,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload)
    })

    if response and (response.StatusCode == 200 or response.StatusCode == 204) then
        return true, "Webhook successfully sent!"
    else
        local status = response and response.StatusCode or "No Response / Failed Request"
        return false, "Failed Status: " .. tostring(status)
    end
end

--==================================================
-- BEAT GAME SURVIVOR
--==================================================

local function BeatGameSurvivor()
    if not Toggles.EnableAutoFarm or not Toggles.EnableAutoFarm.Value then
        BeatState.BeatSurvivorDone = false
        BeatState.LastFinishPos = nil
        return
    end

    if GetRole() ~= "Survivor" then return end

    local root = GetCharacterRoot()
    if not root then return end

    local Workspace = game:GetService("Workspace")
    local map = Workspace:FindFirstChild("Map")
    if not map then return end

    local exitPos = nil

    pcall(function()
        if map:FindFirstChild("RooftopHitbox") or map:FindFirstChild("Rooftop") then
            exitPos = Vector3.new(3098.16, 454.04, -4918.74)
            return
        end

        if map:FindFirstChild("HooksMeat") then
            exitPos = Vector3.new(1546.12, 152.21, -796.72)
            return
        end

        if map:FindFirstChild("churchbell") then
            exitPos = Vector3.new(760.98, -20.14, -78.48)
            return
        end

        local finish = map:FindFirstChild("Finishline") or map:FindFirstChild("FinishLine") or map:FindFirstChild("Fininshline")
        if finish then
            if finish:IsA("BasePart") then
                exitPos = finish.Position
            elseif finish:IsA("Model") then
                local part = finish:FindFirstChildWhichIsA("BasePart")
                if part then exitPos = part.Position end
            end
            return
        end

        for _, obj in ipairs(map:GetDescendants()) do
            if obj.Name:lower():find("finish") then
                if obj:IsA("BasePart") then
                    exitPos = obj.Position
                    break
                elseif obj:IsA("Model") then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        exitPos = part.Position
                        break
                    end
                end
            end
        end

        if not exitPos then
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("MeshPart") and obj.Material == Enum.Material.Limestone then
                    exitPos = Vector3.new(-947.90, 152.12, -7579.52)
                    break
                end
            end
        end

        if not exitPos then
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("MeshPart") and obj.Material == Enum.Material.Leather then
                    exitPos = Vector3.new(1546.12, 152.21, -796.72)
                    break
                end
            end
        end
    end)

    if not exitPos then return end

    if BeatState.LastFinishPos then
        local dist = (exitPos - BeatState.LastFinishPos).Magnitude
        if dist > 50 then
            BeatState.BeatSurvivorDone = false
        end
    end

    if BeatState.BeatSurvivorDone then return end

    root.CFrame = CFrame.new(exitPos + Vector3.new(0, 3, 0))

    BeatState.BeatSurvivorDone = true
    BeatState.LastFinishPos = exitPos

    SendDiscordWebhook("🏆 Round Finished!", "User successfully teleported to the map finish point!")
end

--==================================================
-- SERVER HOP & TELEPORT SYSTEM
--==================================================

local IGNORE_FILE = "ServerHop.txt"
local HOUR = 3600

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local IgnoredServers = {}
local isHopping = false

local function GetIgnoredServers()
    if not isfile(IGNORE_FILE) then return {} end

    local list = {}
    local now = os.time()

    pcall(function()
        local content = readfile(IGNORE_FILE)
        if type(content) == "string" and #content > 0 then
            for _, line in ipairs(content:split("\n")) do
                local serverId, timestamp = line:match("([^|]+)|?(%d*)")
                timestamp = tonumber(timestamp) or 0
                if serverId and serverId ~= "" and now - timestamp < HOUR then
                    list[serverId] = timestamp
                end
            end
        end
    end)

    return list
end

local function UpdateIgnoredServers(list)
    pcall(function()
        local lines = {}
        for serverId, timestamp in pairs(list) do
            table.insert(lines, serverId .. "|" .. timestamp)
        end
        writefile(IGNORE_FILE, table.concat(lines, "\n"))
    end)
end

IgnoredServers = GetIgnoredServers()

pcall(function()
    TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
        if player == Players.LocalPlayer then
            isHopping = false

            if Library and Library.Notify then
                pcall(function()
                    Library:Notify({
                        Title = "Teleport Failed",
                        Description = "Server full or ended. Retrying in 2s...",
                        Icon = "x",
                        Time = 4,
                    })
                end)
            end

            task.wait(2)

            if Toggles.ServerHop and Toggles.ServerHop.Value and not Library.Unloaded do
                task.spawn(function()
                    ServerHop()
                end)
            end
        end
    end)
end)

-- SAFE SERVER HOP DETECTORS
local IsRound = false

pcall(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")

    if Remotes then
        local StatusUpdateEvent = Remotes:FindFirstChild("StatusUpdateEvent")
        local TimeUpdateEvent = Remotes:FindFirstChild("TimeUpdateEvent")

        if StatusUpdateEvent and StatusUpdateEvent:IsA("RemoteEvent") then
            StatusUpdateEvent.OnClientEvent:Connect(function(Status)
                if Status == "WaitingForPlayers" or Status == "IntermissionStarting" or Status == "Intermission" then
                    IsRound = false
                end
            end)
        end

        if TimeUpdateEvent and TimeUpdateEvent:IsA("RemoteEvent") then
            TimeUpdateEvent.OnClientEvent:Connect(function(Status)
                if Status == "Round" then
                    IsRound = true
                end
            end)
        end
    end
end)

local function CanServerHop()
    if not IsRound then return false end
    local role = GetRole()
    if role ~= "Spectator" and role ~= "Killer" then return false end
    return true
end

local function ServerHop()
    if isHopping then return end
    isHopping = true

    local cursor = ""

    while Toggles.ServerHop and Toggles.ServerHop.Value and not Library.Unloaded do
        if not CanServerHop() then
            isHopping = false
            task.wait(0.5)
            continue
        end

        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/"
                .. game.PlaceId
                .. "/servers/Public?limit=100"
                .. "&sortOrder=Asc"
                .. "&excludeFullGames=true"
                .. "&cursor="
                .. cursor

            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if not success or not result or not result.data then
            task.wait(3)
            continue
        end

        local ServersList = result.data

        table.sort(ServersList, function(a, b)
            return (a.ping or math.huge) < (b.ping or math.huge)
        end)

        for _, Server in ipairs(ServersList) do
            if not CanServerHop() then break end

            local maxPlayers = Server.maxPlayers or 10
            local playing = Server.playing or 0
            local freeSlots = maxPlayers - playing

            if
                Server.id
                and Server.id ~= game.JobId
                and playing >= 1
                and playing <= 2
                and freeSlots >= 1
                and not IgnoredServers[Server.id]
            then
                IgnoredServers[Server.id] = os.time()
                UpdateIgnoredServers(IgnoredServers)

                SendDiscordWebhook("🔄 Server Hopping", "Hopping to server: `" .. Server.id .. "`")

                local tpSuccess = pcall(function()
                    TeleportService:TeleportToPlaceInstance(
                        game.PlaceId,
                        Server.id,
                        Players.LocalPlayer
                    )
                end)

                if tpSuccess then
                    task.wait(8)
                end

                isHopping = false
                return
            end
        end

        cursor = result.nextPageCursor
        if not cursor then
            cursor = ""
            task.wait(1)
        else
            task.wait(0.2)
        end
    end

    isHopping = false
end

--==================================================
-- AUTO FARM TOGGLES
--==================================================

AutoFarmGroup:AddToggle("EnableAutoFarm", {
    Text = "Enable Auto Farm",
    Tooltip = "Teleport Survivor to the detected finish location",
    Default = false,
})

AutoFarmGroup:AddToggle("ServerHop", {
    Text = "Server Hop",
    Tooltip = "Hop to 1-2 player servers as Spectator",
    Default = false,
    Callback = function(Value)
        if Value then
            task.spawn(function()
                ServerHop()
            end)
        end
    end,
})

--==================================================
-- AUTO EXECUTE
--==================================================

local LOADER_URL = "https://raw.githubusercontent.com/Rzor731/VD-AUTO-FARM/refs/heads/main/loader.lua"
local AutoExecuteQueued = false

local function QueueAutoExecute()
    if AutoExecuteQueued then return end
    if not Toggles.AutoExecute or not Toggles.AutoExecute.Value then return end

    local qtp = getQueueOnTeleport()
    if type(qtp) ~= "function" then
        if Library and Library.Notify then
            pcall(function()
                Library:Notify({
                    Title = "Auto Execute",
                    Description = "queue_on_teleport is not available on this executor.",
                    Time = 5,
                })
            end)
        end
        return
    end

    local queued = string.format([[
        pcall(function()
            local str = game:HttpGet(%q)
            local loadFunc = (type(loadstring) == "function" and loadstring) or (type(load_string) == "function" and load_string)
            if loadFunc then
                local func = loadFunc(str)
                if type(func) == "function" then
                    func()
                end
            end
        end)
    ]], LOADER_URL)

    local success, err = pcall(function()
        qtp(queued)
    end)

    if success then
        AutoExecuteQueued = true
        if Library and Library.Notify then
            pcall(function()
                Library:Notify({
                    Title = "Auto Execute",
                    Description = "Script queued for next teleport.",
                    Time = 3,
                })
            end)
        end
    end
end

AutoFarmGroup:AddToggle("AutoExecute", {
    Text = "Auto Execute",
    Tooltip = "Automatically execute the script after server hop",
    Default = false,
    Callback = function(Value)
        if Value then
            QueueAutoExecute()
        else
            AutoExecuteQueued = false
        end
    end,
})

--==================================================
-- WEBHOOK SETUP
--==================================================

WebhookGroup:AddToggle("EnableWebhook", {
    Text = "Enable Webhook",
    Tooltip = "Enable webhook notifications",
    Default = false,
})

WebhookGroup:AddInput("WebhookLink", {
    Text = "Webhook Link",
    Default = "",
    Placeholder = "Enter webhook URL...",
    Numeric = false,
    Finished = false,
    ClearTextOnFocus = false,
})

WebhookGroup:AddButton("Test Webhook", function()
    local ok, msg = SendDiscordWebhook("🔔 Webhook Test", "Webhook configuration test from **VD Auto Farm** UI!", true)
    
    if Library and Library.Notify then
        pcall(function()
            if ok then
                Library:Notify({
                    Title = "Webhook Success",
                    Description = "Test message sent to Discord!",
                    Icon = "check",
                    Time = 4,
                })
            else
                Library:Notify({
                    Title = "Webhook Failed",
                    Description = msg,
                    Icon = "x",
                    Time = 5,
                })
            end
        end)
    end
end)

--==================================================
-- SETTINGS & MANAGER SETUP
--==================================================

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame and Library.KeybindFrame.Visible or false,
    Text = "Open Keybind Menu",
    Callback = function(Value)
        if Library.KeybindFrame then
            Library.KeybindFrame.Visible = Value
        end
    end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = Library.ShowCustomCursor or false,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value)
        if Library.SetNotifySide then
            pcall(function() Library:SetNotifySide(Value) end)
        end
    end,
})

MenuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        local DPI = tonumber(Value:gsub("%%", ""))
        if DPI and Library.SetDPIScale then
            pcall(function() Library:SetDPIScale(DPI) end)
        end
    end,
})

MenuGroup:AddSlider("UICornerSlider", {
    Text = "Corner Radius",
    Default = Library.CornerRadius or 0,
    Min = 0,
    Max = 20,
    Rounding = 0,
    Callback = function(Value)
        if Window and Window.SetCornerRadius then
            pcall(function() Window:SetCornerRadius(Value) end)
        end
    end,
})

MenuGroup:AddDivider()

MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        NoUI = true,
        Text = "Menu keybind",
    })

MenuGroup:AddButton("Unload", function()
    pcall(function() Library:Unload() end)
end)

if Options and Options.MenuKeybind then
    Library.ToggleKeybind = Options.MenuKeybind
end

if ThemeManager and SaveManager then
    pcall(function()
        ThemeManager:SetLibrary(Library)
        SaveManager:SetLibrary(Library)

        ThemeManager:SetFolder("AutoFarm")
        SaveManager:SetFolder("AutoFarm")
        SaveManager:SetSubFolder("Settings")

        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

        SaveManager:BuildConfigSection(Tabs.Settings)
        ThemeManager:ApplyToTab(Tabs.Settings)

        SaveManager:LoadAutoloadConfig()
    end)
end

--==================================================
-- INITIALIZE & MAIN LOOP
--==================================================

QueueAutoExecute()

task.spawn(function()
    task.wait(2)
    SendDiscordWebhook("🎮 Script Executed", "VD Auto Farm Loader successfully initialized.")
end)

task.spawn(function()
    while Library and not Library.Unloaded do
        pcall(function()
            BeatGameSurvivor()
        end)
        task.wait(0.1)
    end
end)
