--==================================================
-- OBSIDIAN UI + BEAT SURVIVOR
--==================================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

--==================================================
-- SHARED SERVICES / REFERENCES
--==================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

--==================================================
-- WINDOW
--==================================================

local Window = Library:CreateWindow({
    Title = "",
    Footer = "version: 1.0.0",
    Icon = "bot",

    NotifySide = "Right",
    ShowCustomCursor = true,
})

--==================================================
-- TABS
--==================================================

Window:SetSidebarWidth(40)

local Tabs = {
    AutoFarm = Window:AddTab("", "zap"),
    Settings = Window:AddTab("", "settings"),
}

--==================================================
-- AUTO FARM TAB
--==================================================

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

    if not player.Team then
        return "Unknown"
    end

    local name = player.Team.Name

    if name == "Killer" then
        return "Killer"
    end

    if name == "Survivors" then
        return "Survivor"
    end

    -- Support both possible spectator team names
    if name == "Spectator" or name == "Spectators" then
        return "Spectator"
    end

    return "Lobby"
end

local function GetCharacterRoot()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character

    return character and character:FindFirstChild("HumanoidRootPart")
end

-- Universal HTTP Request Fallback for All Modern Executors
local function safeRequest(options)
    local req = (syn and syn.request) 
             or (http and http.request) 
             or http_request 
             or request 
             or (fluxus and fluxus.request)
             or (krnl and krnl.request)

    if req then
        return req(options)
    end
    return nil
end

-- Detect Executor Name
local function GetExecutorName()
    return (identifyexecutor and identifyexecutor())
        or (getexecutorname and getexecutorname())
        or "Unknown Executor"
end

--==================================================
-- WEBHOOK SYSTEM
--==================================================

local function SendDiscordWebhook(customTitle, customDesc, forceSend)
    -- Check if Webhook is enabled unless forceSend (Test Button) is true
    if not forceSend and (not Toggles.EnableWebhook or not Toggles.EnableWebhook.Value) then
        return false, "Webhook Disabled"
    end

    local webhookUrl = Options.WebhookLink and Options.WebhookLink.Value or ""

    if not webhookUrl or webhookUrl == "" or not string.find(webhookUrl, "discord.com/api/webhooks") then
        return false, "Invalid Webhook URL"
    end

    -- Fetch Game Name
    local gameName = "Unknown Game"
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)

    -- Player Details
	local stats = GetFarmStats()
    local username = LocalPlayer.Name
    local displayName = LocalPlayer.DisplayName
    local userId = LocalPlayer.UserId
    local profileUrl = "https://www.roblox.com/users/" .. userId .. "/profile"
    local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
    local executorName = GetExecutorName()
    local currentRole = GetRole()
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    -- Payload Data
    local payload = {
        ["username"] = "VD Auto Farm Logger",
        ["avatar_url"] = "https://cdn-icons-png.flaticon.com/512/2092/2092663.png",
        ["embeds"] = {{
            ["title"] = customTitle or "🚀 VD Auto Farm Notification",
            ["description"] = customDesc or "Notification trigger from **VD Auto Farm Loader**.",
            ["color"] = 5793266, -- Discord Blurple (#5865F2)
            ["timestamp"] = timestamp,
            ["thumbnail"] = {
                ["url"] = avatarUrl
            },
            ["fields"] = {
			    {
			        ["name"] = "👤 Player Info",
			        ["value"] = string.format("**Display:** %s\n**Username:** [%s](%s)\n**User ID:** `%d`", displayName, username, profileUrl, userId),
			        ["inline"] = true
			    },
			    {
			        ["name"] = "⚡ Executor & Role",
			        ["value"] = string.format("**Exec:** `%s`\n**Role:** `%s`", executorName, currentRole),
			        ["inline"] = true
			    },
			    -- ⬇️ FIELD HASIL FARM BARU ⬇️
			    {
			        ["name"] = "📊 Farm Statistics",
			        ["value"] = string.format(
			            "⭐ **Level:** `%d` `(+%d)`\n" ..
			            "🔮 **Sins:** `%d` `(+%d)`\n" ..
			            "🔩 **Screws:** `%d` `(+%d)`\n" ..
			            "⚙️ **Gears:** `%d` `(+%d)`",
			            stats.Level.Current, stats.Level.Gained,
			            stats.Sins.Current, stats.Sins.Gained,
			            stats.Screws.Current, stats.Screws.Gained,
			            stats.Gears.Current, stats.Gears.Gained
			        ),
			        ["inline"] = false
			    },
			    {
			        ["name"] = "🎮 Game Details",
			        ["value"] = string.format("**Game:** %s\n**Place ID:** `%d`", gameName, game.PlaceId),
			        ["inline"] = false
			    },
			    {
			        ["name"] = "📌 Server Job ID",
			        ["value"] = string.format("```lua\n%s\n```", (game.JobId ~= "" and game.JobId or "Singleplayer / Local")),
			        ["inline"] = false
			    }
			},
            ["footer"] = {
                ["text"] = "VD Auto Farm",
                ["icon_url"] = "https://cdn-icons-png.flaticon.com/512/2092/2092663.png"
            }
        }}
    }

    local response = safeRequest({
        Url = webhookUrl,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
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

    -- Feature disabled
    if not Toggles.EnableAutoFarm.Value then
        BeatState.BeatSurvivorDone = false
        BeatState.LastFinishPos = nil
        return
    end

    -- Only Survivor
    if GetRole() ~= "Survivor" then
        return
    end

    local root = GetCharacterRoot()

    if not root then
        return
    end

    local map = Workspace:FindFirstChild("Map")

    if not map then
        return
    end

    local exitPos = nil

    pcall(function()

        --==================================================
        -- MAP DETECTOR #1
        -- Rooftop
        --==================================================

        if map:FindFirstChild("RooftopHitbox")
            or map:FindFirstChild("Rooftop") then

            exitPos = Vector3.new(
                3098.16,
                454.04,
                -4918.74
            )

            return
        end

        --==================================================
        -- MAP DETECTOR #2
        -- HooksMeat
        --==================================================

        if map:FindFirstChild("HooksMeat") then

            exitPos = Vector3.new(
                1546.12,
                152.21,
                -796.72
            )

            return
        end

        --==================================================
        -- MAP DETECTOR #3
        -- Churchbell
        --==================================================

        if map:FindFirstChild("churchbell") then

            exitPos = Vector3.new(
                760.98,
                -20.14,
                -78.48
            )

            return
        end

        --==================================================
        -- MAP DETECTOR #4
        -- Finishline
        --==================================================

        local finish =
            map:FindFirstChild("Finishline")
            or map:FindFirstChild("FinishLine")
            or map:FindFirstChild("Fininshline")

        if finish then

            if finish:IsA("BasePart") then

                exitPos = finish.Position

            elseif finish:IsA("Model") then

                local part =
                    finish:FindFirstChildWhichIsA("BasePart")

                if part then
                    exitPos = part.Position
                end
            end

            return
        end

        --==================================================
        -- MAP DETECTOR #5
        -- Any descendant containing "finish"
        --==================================================

        for _, obj in ipairs(map:GetDescendants()) do

            if obj.Name:lower():find("finish") then

                if obj:IsA("BasePart") then

                    exitPos = obj.Position
                    break

                elseif obj:IsA("Model") then

                    local part =
                        obj:FindFirstChildWhichIsA("BasePart")

                    if part then
                        exitPos = part.Position
                        break
                    end
                end
            end
        end

        --==================================================
        -- MAP DETECTOR #6
        -- Limestone fallback
        --==================================================

        if not exitPos then

            for _, obj in ipairs(map:GetDescendants()) do

                if obj:IsA("MeshPart")
                    and obj.Material == Enum.Material.Limestone then

                    exitPos = Vector3.new(
                        -947.90,
                        152.12,
                        -7579.52
                    )

                    break
                end
            end
        end

        --==================================================
        -- MAP DETECTOR #7
        -- Leather fallback
        --==================================================

        if not exitPos then

            for _, obj in ipairs(map:GetDescendants()) do

                if obj:IsA("MeshPart")
                    and obj.Material == Enum.Material.Leather then

                    exitPos = Vector3.new(
                        1546.12,
                        152.21,
                        -796.72
                    )

                    break
                end
            end
        end

    end)

    -- No exit detected
    if not exitPos then
        return
    end

    --==================================================
    -- FINISH POSITION CHANGE CHECK
    --==================================================

    if BeatState.LastFinishPos then

        local dist =
            (exitPos - BeatState.LastFinishPos).Magnitude

        if dist > 50 then
            BeatState.BeatSurvivorDone = false
        end
    end

    -- Already completed this location
    if BeatState.BeatSurvivorDone then
        return
    end

    --==================================================
    -- TELEPORT TO FINISH
    --==================================================

    root.CFrame = CFrame.new(
        exitPos + Vector3.new(0, 3, 0)
    )

    --==================================================
    -- SAVE STATE & WEBHOOK NOTIFY
    --==================================================

    BeatState.BeatSurvivorDone = true
    BeatState.LastFinishPos = exitPos

    -- Send notification to webhook upon finishing
    SendDiscordWebhook("🏆 Round Finished!", "User successfully teleported to the map finish point!")
end

--==================================================
-- SERVER HOP
--==================================================

local IGNORE_FILE = "ServerHop.txt"
local HOUR = 3600

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == Players.LocalPlayer then
        Library:Notify({
            Title = "Teleport Failed",
            Description = "Server penuh/tutup. Mencari server lain...",
            Time = 3,
        })
    end
end)

local InitialStats = {
    Level = LocalPlayer:GetAttribute("Level") or 0,
    Sins = LocalPlayer:GetAttribute("KillerChance") or 0,
    Screws = LocalPlayer:GetAttribute("Screws") or 0,
    Gears = LocalPlayer:GetAttribute("Gears") or 0,
}

local function GetFarmStats()
    local curLvl = LocalPlayer:GetAttribute("Level") or 0
    local curSins = LocalPlayer:GetAttribute("KillerChance") or 0
    local curScrews = LocalPlayer:GetAttribute("Screws") or 0
    local curGears = LocalPlayer:GetAttribute("Gears") or 0

    return {
        Level = { Current = curLvl, Gained = curLvl - InitialStats.Level },
        Sins = { Current = curSins, Gained = curSins - InitialStats.Sins },
        Screws = { Current = curScrews, Gained = curScrews - InitialStats.Screws },
        Gears = { Current = curGears, Gained = curGears - InitialStats.Gears },
    }
end

local IgnoredServers = {}

local function GetIgnoredServers()

    if not isfile(IGNORE_FILE) then
        return {}
    end

    local list = {}
    local now = os.time()

    for _, line in ipairs(readfile(IGNORE_FILE):split("\n")) do

        local serverId, timestamp =
            line:match("([^|]+)|?(%d*)")

        timestamp = tonumber(timestamp) or 0

        if serverId
            and serverId ~= ""
            and now - timestamp < HOUR then

            list[serverId] = timestamp
        end
    end

    return list
end

local function UpdateIgnoredServers(list)

    local lines = {}

    for serverId, timestamp in pairs(list) do
        table.insert(lines, serverId .. "|" .. timestamp)
    end

    writefile(
        IGNORE_FILE,
        table.concat(lines, "\n")
    )
end

IgnoredServers = GetIgnoredServers()

--==================================================
-- SERVER HOP STATE
--==================================================

local IsRound = false


local Remotes =
    ReplicatedStorage:WaitForChild("Remotes")

local StatusUpdateEvent =
    Remotes:WaitForChild("StatusUpdateEvent")

local TimeUpdateEvent =
    Remotes:WaitForChild("TimeUpdateEvent")

--==================================================
-- STATUS DETECTOR
--==================================================

StatusUpdateEvent.OnClientEvent:Connect(function(Status)

    if Status == "WaitingForPlayers" then

        IsRound = false

    elseif Status == "IntermissionStarting" then

        IsRound = false

    elseif Status == "Intermission" then

        IsRound = false
    end
end)

--==================================================
-- ROUND DETECTOR
--==================================================

TimeUpdateEvent.OnClientEvent:Connect(function(Status)

    if Status == "Round" then
        IsRound = true
    end
end)

--==================================================
-- SERVER HOP PERMISSION
--==================================================

local function CanServerHop()

    -- Must be inside a round
    if not IsRound then
        return false
    end

    -- Only Spectator or Killer may serverhop during round
    local role = GetRole()

    if role ~= "Spectator" and role ~= "Killer" then
        return false
    end

    return true
end

--==================================================
-- SERVER HOP
--==================================================

local function ServerHop()

    local cursor = ""

    while Toggles.ServerHop.Value
        and not Library.Unloaded do

        -- Check current round + current role LIVE
        if not CanServerHop() then
            task.wait(0.5)
            continue
        end

        local success, result = pcall(function()

            local url =
                "https://games.roblox.com/v1/games/"
                .. game.PlaceId
                .. "/servers/Public?limit=100"
                .. "&sortOrder=Asc"
                .. "&excludeFullGames=true"
                .. "&cursor="
                .. cursor

            return HttpService:JSONDecode(
                game:HttpGet(url)
            )
        end)

        if not success
            or not result
            or not result.data then

            task.wait(3)
            continue
        end

        local ServersList = result.data

        --==================================================
        -- FIND SERVER
        --==================================================

        for _, Server in ipairs(ServersList) do

            -- Check again before teleporting
            if not CanServerHop() then
                break
            end

            if
			    Server.id
			    and Server.id ~= game.JobId
			    and Server.playing
			    and Server.playing >= 1
			    and Server.maxPlayers
			    and Server.playing < Server.maxPlayers -- Pastikan slot server belum penuh
			    and not IgnoredServers[Server.id]
			then

                -- Mark server before teleport
                IgnoredServers[Server.id] = os.time()

                UpdateIgnoredServers(
                    IgnoredServers
                )

                -- Send Server Hop notification via Webhook
                SendDiscordWebhook("🔄 Server Hopping", "Hopping to a new server: `" .. Server.id .. "`")

                pcall(function()
				    TeleportService:TeleportToPlaceInstance(
				        game.PlaceId,
				        Server.id,
				        Players.LocalPlayer
				    )
				end)

                return
            end
        end

        --==================================================
        -- NEXT PAGE
        --==================================================

        cursor = result.nextPageCursor

        if not cursor then

            -- Start pagination again
            cursor = ""

            task.wait(1)
        else

            task.wait(0.2)
        end
    end
end

--==================================================
-- AUTO FARM TOGGLE
--==================================================

AutoFarmGroup:AddToggle("EnableAutoFarm", {
    Text = "Enable Auto Farm",
    Tooltip = "Teleport Survivor to the detected finish location",

    Default = false,
})

--==================================================
-- AUTO SERVERHOP
--==================================================

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

local LOADER_URL =
    "https://raw.githubusercontent.com/Rzor731/VD-AUTO-FARM/refs/heads/main/loader.lua"

local AutoExecuteQueued = false

local function QueueAutoExecute()
    if AutoExecuteQueued then
        return
    end

    if not Toggles.AutoExecute.Value then
        return
    end

    if type(queue_on_teleport) ~= "function" then
        Library:Notify({
            Title = "Auto Execute   \n",
            Description = "queue_on_teleport is not available.",
            Time = 5,
        })

        return
    end

    local queued = string.format([[
loadstring(game:HttpGet(%q))()
]], LOADER_URL)

    local success, err = pcall(function()
        queue_on_teleport(queued)
    end)

    if success then
        AutoExecuteQueued = true

        Library:Notify({
            Title = "Auto Execute   \n",
            Description = "Script queued for the next teleport.",
            Time = 3,
        })
    else
        Library:Notify({
            Title = "Auto Execute   \n",
            Description = "Failed to queue script: " .. tostring(err),
            Time = 5,
        })
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
-- WEBHOOK GROUPBOX SETUP
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

--==================================================
-- TEST NOTIFICATIONS
--==================================================

local TestNotificationGroup =
    Tabs.AutoFarm:AddRightGroupbox("Test Notifications", "bell")

TestNotificationGroup:AddButton("1. Simple", function()
    Library:Notify({
        Title = "Server Hop",
        Description = "Simple notification",
        Time = 4,
    })
end)

TestNotificationGroup:AddButton("2. Icon", function()
    Library:Notify({
        Title = "Server Hop",
        Description = "Notification with an icon",
        Icon = "info",
        Time = 4,
    })
end)

TestNotificationGroup:AddButton("3. Big Icon", function()
    Library:Notify({
        Title = "Server Hop",
        Description = "Notification with a big icon",
        BigIcon = "rbxassetid://10204738596",
        IconColor = Color3.new(0, 1, 0),
        Time = 4,
    })
end)

TestNotificationGroup:AddButton("4. Persistent", function()
    local Notification = Library:Notify({
        Title = "Server Hop",
        Description = "Persistent notification",
        Persist = true,
    })

    task.delay(5, function()
        if Notification then
            Notification:Destroy()
        end
    end)
end)

TestNotificationGroup:AddButton("5. Update", function()
    local Notification = Library:Notify({
        Title = "Server Hop",
        Description = "Waiting...",
        Persist = true,
    })

    task.delay(2, function()
        Notification:ChangeTitle("Server Hop - Updated")
        Notification:ChangeDescription("Notification has been updated!")
    end)

    task.delay(5, function()
        Notification:Destroy()
    end)
end)

TestNotificationGroup:AddButton("6. Progress", function()
    local Notification = Library:Notify({
        Title = "Server Hop",
        Description = "Testing progress...",
        Steps = 10,
    })

    task.spawn(function()
        for i = 1, 10 do
            Notification:ChangeStep(i)
            task.wait(0.3)
        end

        task.wait(1)
        Notification:Destroy()
    end)
end)

--==================================================
-- SETTINGS
--==================================================

local MenuGroup =
    Tabs.Settings:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",

    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = Library.ShowCustomCursor,

    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = {
        "Left",
        "Right",
    },

    Default = "Right",
    Text = "Notification Side",

    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})

MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",

	Text = "DPI Scale",

	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		Library:SetDPIScale(DPI)
	end,
})

MenuGroup:AddSlider("UICornerSlider", {
    Text = "Corner Radius",

    Default = Library.CornerRadius,
    Min = 0,
    Max = 20,
    Rounding = 0,

    Callback = function(Value)
        Window:SetCornerRadius(Value)
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
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

--==================================================
-- SAVE / THEME MANAGER
--==================================================

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

ThemeManager:SetFolder("AutoFarm")
SaveManager:SetFolder("AutoFarm")
SaveManager:SetSubFolder("Settings")

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({
    "MenuKeybind",
})

SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

SaveManager:LoadAutoloadConfig()

--==================================================
-- INITIALIZE AUTO EXECUTE & EXECUTION NOTIFY
--==================================================

QueueAutoExecute()

-- Send execution log if webhook is enabled on load
task.spawn(function()
    task.wait(2) -- Wait for UI Config to auto load
    SendDiscordWebhook("🎮 Script Executed", "VD Auto Farm Loader successfully initialized.")
end)

--==================================================
-- MAIN LOOP
--==================================================

task.spawn(function()

    while not Library.Unloaded do

        pcall(function()
            BeatGameSurvivor()
        end)

        task.wait(0.1)
    end

end)
