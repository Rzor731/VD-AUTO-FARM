--==================================================
-- OBSIDIAN UI + BEAT SURVIVOR
--==================================================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
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
-- WEBHOOK ATTRIBUTE STATE (PERSISTENT)
--==================================================
local ATTRIBUTE_FILE = "VD_AutoFarm_Attributes.json"
local PreviousAttributes = nil
--==================================================
-- LOAD PREVIOUS ATTRIBUTES
--==================================================
local function LoadPreviousAttributes()
    if type(isfile) ~= "function"
    or type(readfile) ~= "function" then
        return nil
    end
    if not isfile(ATTRIBUTE_FILE) then
        return nil
    end
    local HttpService = game:GetService("HttpService")
    local success, data = pcall(function()
        return HttpService:JSONDecode(
            readfile(ATTRIBUTE_FILE)
        )
    end)
    if not success or type(data) ~= "table" then
        return nil
    end
    local LocalPlayer = game:GetService("Players").LocalPlayer
    -- Jangan gunakan snapshot milik player lain
    if tonumber(data.UserId) ~= LocalPlayer.UserId then
        return nil
    end
    return {
        KillerChance = tonumber(data.KillerChance),
        EXP = tonumber(data.EXP),
        Screws = tonumber(data.Screws),
        Gears = tonumber(data.Gears)
    }
end
--==================================================
-- SAVE PREVIOUS ATTRIBUTES
--==================================================
local function SavePreviousAttributes(attributes)
    if type(writefile) ~= "function" then
        return false
    end
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local data = {
        UserId = LocalPlayer.UserId,
        KillerChance = attributes.KillerChance,
        EXP = attributes.EXP,
        Screws = attributes.Screws,
        Gears = attributes.Gears,
        UpdatedAt = os.time()
    }
    local success = pcall(function()
        writefile(
            ATTRIBUTE_FILE,
            HttpService:JSONEncode(data)
        )
    end)
    return success
end
-- Load snapshot dari server/session sebelumnya
PreviousAttributes = LoadPreviousAttributes()
--==================================================
-- ATTRIBUTE DELTA
--==================================================
local function GetAttributeDelta(currentValue, previousValue)
    currentValue = tonumber(currentValue) or 0
    if previousValue == nil then
        return 0
    end
    return currentValue - (tonumber(previousValue) or 0)
end
--==================================================
-- WEBHOOK SYSTEM
--==================================================
local function SendDiscordWebhook(customTitle, customDesc, forceSend)
    if not forceSend
    and (
        not Toggles.EnableWebhook
        or not Toggles.EnableWebhook.Value
    ) then
        return false, "Webhook Disabled"
    end
    local webhookUrl =
        Options.WebhookLink
        and Options.WebhookLink.Value
        or ""
    if not webhookUrl
    or webhookUrl == ""
    or not string.find(
        webhookUrl,
        "discord.com/api/webhooks"
    ) then
        return false, "Invalid Webhook URL"
    end
    local HttpService =
        game:GetService("HttpService")
    local Players =
        game:GetService("Players")
    local LocalPlayer =
        Players.LocalPlayer
    --==================================================
    -- PLAYER INFO
    --==================================================
    local displayName =
        LocalPlayer.DisplayName
    local userId =
        LocalPlayer.UserId
    local serverId =
        game.JobId ~= ""
        and game.JobId
        or "Singleplayer"
    local profileUrl =
        "https://www.roblox.com/users/"
        .. userId
        .. "/profile"
    --==================================================
    -- READ CURRENT ATTRIBUTES
    --==================================================
    local attrs =
        LocalPlayer:GetAttributes()
    local KillerChance =
        tonumber(attrs.KillerChance) or 0
    local EXP =
        tonumber(attrs.EXP) or 0
    local Screws =
        tonumber(attrs.Screws) or 0
    local Gears =
        tonumber(attrs.Gears) or 0
    local Level =
        tonumber(attrs.Level) or 0
    --==================================================
    -- FIRST RUN
    --==================================================
    if not PreviousAttributes then
        PreviousAttributes = {
            KillerChance = KillerChance,
            EXP = EXP,
            Screws = Screws,
            Gears = Gears
        }
    end
    --==================================================
    -- CALCULATE DELTA
    --==================================================
    local KillerChanceDelta =
        GetAttributeDelta(
            KillerChance,
            PreviousAttributes.KillerChance
        )
    local EXPDelta =
        GetAttributeDelta(
            EXP,
            PreviousAttributes.EXP
        )
    local ScrewsDelta =
        GetAttributeDelta(
            Screws,
            PreviousAttributes.Screws
        )
    local GearsDelta =
        GetAttributeDelta(
            Gears,
            PreviousAttributes.Gears
        )
    --==================================================
    -- PAYLOAD
    --==================================================
    local payload = {
        ["embeds"] = {{
            ["title"] = string.format("%s · Level %d", displayName, Level
                ),
            ["url"] = profileUrl,
            ["color"] = 3638942,
            ["fields"] = {
                {
                    ["name"] = "💀 SIN",
                    ["value"] = string.format("%s (**%+d**)", tostring(KillerChance), KillerChanceDelta),
                    ["inline"] = false
                },
                {
                    ["name"] = "🧪 EXP",
                    ["value"] = string.format("%s (**%+d**)", tostring(EXP), EXPDelta),
                    ["inline"] = false
                },
                {
                    ["name"] = "🔩 Screws",
                    ["value"] = string.format("%s (**%+d**)", tostring(Screws), ScrewsDelta),
                    ["inline"] = false
                },
                {
                    ["name"] = "⚙️ Gears",
                    ["value"] = string.format("%s (**%+d**)", tostring(Gears), GearsDelta),
                    ["inline"] = false
                },
                {
	                ["name"] = "🆔 Server ID",
	                ["value"] = string.format("```\n%s\n```", serverId),
	                ["inline"] = false
	            }
            },
            ["footer"] = {
                ["text"] = string.format("VD Auto Farm · %s", GetExecutorName())
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
        }}
    }
    --==================================================
    -- SEND WEBHOOK
    --==================================================
    local response =
        safeRequest({
            Url = webhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] =
                    "application/json"
            },
            Body =
                HttpService:JSONEncode(
                    payload
                )
        })
    --==================================================
    -- SUCCESS
    --==================================================
    if response
    and (
        response.StatusCode == 200
        or response.StatusCode == 204
    ) then
        --==================================================
        -- ONLY UPDATE AFTER SUCCESS
        --==================================================
        local newSnapshot = {
            KillerChance = KillerChance,
            EXP = EXP,
            Screws = Screws,
            Gears = Gears
        }
        PreviousAttributes =
            newSnapshot
        SavePreviousAttributes(
            newSnapshot
        )
        return true,
            "Webhook successfully sent!"
    end
    --==================================================
    -- FAILED
    --==================================================
    local status =
        response
        and response.StatusCode
        or "No Response / Failed Request"
    -- Jangan update PreviousAttributes
    -- kalau webhook gagal.
    return false,
        "Failed Status: "
        .. tostring(status)
end
--==================================================
-- BEAT GAME SURVIVOR
--==================================================
local function BeatGameSurvivor()
    if not Toggles.EnableAutoFarm.Value then
        BeatState.BeatSurvivorDone = false
        BeatState.LastFinishPos = nil
        return
    end
    if GetRole() ~= "Survivor" then
        return
    end
    local root = GetCharacterRoot()
    if not root then
        return
    end
    local Workspace = game:GetService("Workspace")
    local map = Workspace:FindFirstChild("Map")
    if not map then
        return
    end
    local exitPos = nil
    pcall(function()
        if map:FindFirstChild("RooftopHitbox")
            or map:FindFirstChild("Rooftop") then
            exitPos = Vector3.new(
                3098.16,
                454.04,
                -4918.74
            )
            return
        end
        if map:FindFirstChild("HooksMeat") then
            exitPos = Vector3.new(
                1546.12,
                152.21,
                -796.72
            )
            return
        end
        if map:FindFirstChild("churchbell") then
            exitPos = Vector3.new(
                760.98,
                -20.14,
                -78.48
            )
            return
        end
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
    if not exitPos then
        return
    end
    if BeatState.LastFinishPos then
        local dist =
            (exitPos - BeatState.LastFinishPos).Magnitude
        if dist > 50 then
            BeatState.BeatSurvivorDone = false
        end
    end
    if BeatState.BeatSurvivorDone then
        return
    end
    root.CFrame = CFrame.new(
        exitPos + Vector3.new(0, 3, 0)
    )
    BeatState.BeatSurvivorDone = true
    BeatState.LastFinishPos = exitPos

	task.wait(5)
	
    SendDiscordWebhook()
end
--==================================================
-- SERVER HOP
--==================================================
local IGNORE_FILE = "ServerHop.txt"
local HOUR = 3600
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
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
local ReplicatedStorage =
    game:GetService("ReplicatedStorage")
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
    if not IsRound then
        return false
    end
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
        for _, Server in ipairs(ServersList) do
            if not CanServerHop() then
                break
            end
            if
                Server.id
                and Server.id ~= game.JobId
                and Server.playing
                and Server.playing >= 1
                and Server.playing <= 2
                and not IgnoredServers[Server.id]
            then
                IgnoredServers[Server.id] = os.time()
                UpdateIgnoredServers(IgnoredServers)

				task.wait(5)
                -- SendDiscordWebhook("🔄 Server Hopping", "Hopping to a new server: `" .. Server.id .. "`")
                TeleportService:TeleportToPlaceInstance(
                    game.PlaceId,
                    Server.id,
                    Players.LocalPlayer
                )
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
            Title = "Auto Execute   \n",
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
            Title = "Auto Execute   \n",
            Description = "Script queued for the next teleport.",
            Time = 3,
        })
    else
        Library:Notify({
            Title = "Auto Execute   \n",
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
task.spawn(function()
    task.wait(3)
    -- SendDiscordWebhook("🎮 Script Executed", "VD Auto Farm Loader successfully initialized.")
end)
--==================================================
-- MAIN LOOP
--==================================================
task.spawn(function()
    while not Library.Unloaded do
        pcall(function()
            BeatGameSurvivor()
        end)
        task.wait(1)
    end
end)
