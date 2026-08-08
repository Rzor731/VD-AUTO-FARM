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

local AutoFarmGroup =
    Tabs.AutoFarm:AddLeftGroupbox("Auto Farm", "zap")

local WebhookGroup =
    Tabs.AutoFarm:AddRightGroupbox("Webhook", "webhook")

--==================================================
-- BEAT SURVIVOR STATE
--==================================================

local BeatState = {
    LastFinishPos = nil,
    BeatSurvivorDone = false,
}

--==================================================
-- NOTIFICATION STATE
--==================================================

local NotificationState = {
    RoundNotificationShown = false,

    CurrentRoundRole = nil,

    LastRole = nil,

    MapDetected = false,
    FinishDetected = false,
    EscapeCompleted = false,

    SearchStarted = false,

    LastServer = nil,

    RequestErrorShown = false,
    NoServerShown = false,
}

--==================================================
-- NOTIFICATION HELPER
--==================================================

local function Notify(Title, Description, Time)
    Library:Notify({
        Title = Title,
        Description = Description,
        Time = Time or 4,
    })
end

--==================================================
-- RESET ROUND NOTIFICATION STATE
--==================================================

local function ResetRoundNotificationState()
    NotificationState.RoundNotificationShown = false
    NotificationState.CurrentRoundRole = nil

    NotificationState.LastRole = nil

    NotificationState.FinishDetected = false
    NotificationState.EscapeCompleted = false

    NotificationState.SearchStarted = false

    NotificationState.LastServer = nil

    NotificationState.RequestErrorShown = false
    NotificationState.NoServerShown = false
end

--==================================================
-- HELPER FUNCTIONS
--==================================================

local function GetRole()

    local player =
        game:GetService("Players").LocalPlayer

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

    if name == "Spectator"
        or name == "Spectators" then

        return "Spectator"
    end

    return "Lobby"
end

local function GetCharacterRoot()

    local player =
        game:GetService("Players").LocalPlayer

    local character =
        player.Character

    return character
        and character:FindFirstChild("HumanoidRootPart")
end

--==================================================
-- BEAT GAME SURVIVOR
--==================================================

local function BeatGameSurvivor()

    --==================================================
    -- FEATURE DISABLED
    --==================================================

    if not Toggles.EnableAutoFarm.Value then

        BeatState.BeatSurvivorDone = false
        BeatState.LastFinishPos = nil

        return
    end

    --==================================================
    -- ONLY SURVIVOR
    --==================================================

    if GetRole() ~= "Survivor" then
        return
    end

    local root = GetCharacterRoot()

    if not root then
        return
    end

    local Workspace =
        game:GetService("Workspace")

    local map =
        Workspace:FindFirstChild("Map")

    if not map then
        return
    end

    local exitPos = nil
    local detectedMap = nil

    --==================================================
    -- MAP DETECTION
    --==================================================

    pcall(function()

        --==================================================
        -- MAP #1
        -- Rooftop
        --==================================================

        if map:FindFirstChild("RooftopHitbox")
            or map:FindFirstChild("Rooftop") then

            exitPos = Vector3.new(
                3098.16,
                454.04,
                -4918.74
            )

            detectedMap = "Rooftop"

            return
        end

        --==================================================
        -- MAP #2
        -- HooksMeat
        --==================================================

        if map:FindFirstChild("HooksMeat") then

            exitPos = Vector3.new(
                1546.12,
                152.21,
                -796.72
            )

            detectedMap = "HooksMeat"

            return
        end

        --==================================================
        -- MAP #3
        -- Churchbell
        --==================================================

        if map:FindFirstChild("churchbell") then

            exitPos = Vector3.new(
                760.98,
                -20.14,
                -78.48
            )

            detectedMap = "Churchbell"

            return
        end

        --==================================================
        -- MAP #4
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

            if exitPos then
                detectedMap = "Finishline"
            end

            return
        end

        --==================================================
        -- MAP #5
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

        if exitPos then
            detectedMap = "Finishline"
        end

        --==================================================
        -- MAP #6
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

                    detectedMap = "Limestone"

                    break
                end
            end
        end

        --==================================================
        -- MAP #7
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

                    detectedMap = "Leather"

                    break
                end
            end
        end

    end)

    --==================================================
    -- NO EXIT DETECTED
    --==================================================

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

            NotificationState.FinishDetected = false
        end
    end

    --==================================================
    -- ALREADY COMPLETED
    --==================================================

    if BeatState.BeatSurvivorDone then
        return
    end

    --==================================================
    -- FINISH DETECTED
    --==================================================

    if not NotificationState.FinishDetected then

        NotificationState.FinishDetected = true

        Notify(
            "Auto Farm     \n",
            "Finish detected • Teleporting...     ",
            4
        )
    end

    --==================================================
    -- TELEPORT TO FINISH
    --==================================================

    root.CFrame =
        CFrame.new(
            exitPos + Vector3.new(0, 3, 0)
        )

    --==================================================
    -- SAVE STATE
    --==================================================

    BeatState.BeatSurvivorDone = true
    BeatState.LastFinishPos = exitPos

end

--==================================================
-- SERVER HOP
--==================================================

local IGNORE_FILE = "ServerHop.txt"
local HOUR = 3600

local HttpService =
    game:GetService("HttpService")

local TeleportService =
    game:GetService("TeleportService")

local Players =
    game:GetService("Players")

local IgnoredServers = {}

--==================================================
-- GET IGNORED SERVERS
--==================================================

local function GetIgnoredServers()

    if not isfile(IGNORE_FILE) then
        return {}
    end

    local list = {}
    local now = os.time()

    for _, line in ipairs(
        readfile(IGNORE_FILE):split("\n")
    ) do

        local serverId, timestamp =
            line:match("([^|]+)|?(%d*)")

        timestamp =
            tonumber(timestamp) or 0

        if serverId
            and serverId ~= ""
            and now - timestamp < HOUR then

            list[serverId] = timestamp
        end
    end

    return list
end

--==================================================
-- UPDATE IGNORED SERVERS
--==================================================

local function UpdateIgnoredServers(list)

    local lines = {}

    for serverId, timestamp in pairs(list) do

        table.insert(
            lines,
            serverId .. "|" .. timestamp
        )
    end

    writefile(
        IGNORE_FILE,
        table.concat(lines, "\n")
    )
end

IgnoredServers =
    GetIgnoredServers()

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

    if Status == "WaitingForPlayers"
        or Status == "IntermissionStarting"
        or Status == "Intermission" then

        IsRound = false

        ResetRoundNotificationState()

    end

end)

--==================================================
-- ROUND DETECTOR
--==================================================

TimeUpdateEvent.OnClientEvent:Connect(function(Status)

    if Status == "Round" then

        IsRound = true

        local role = GetRole()

        if not NotificationState.RoundNotificationShown then

            if role == "Survivor"
                or role == "Killer"
                or role == "Spectator" then

                NotificationState.RoundNotificationShown = true
                NotificationState.CurrentRoundRole = role

                Notify(
                    "Round Started     \n",
                    "Role: " .. role     ,
                    4
                )
            end
        end

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

    -- Only Spectator or Killer
    local role = GetRole()

    if role ~= "Spectator"
        and role ~= "Killer" then

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

        --==================================================
        -- CHECK CURRENT ROUND + ROLE
        --==================================================

        if not CanServerHop() then

            task.wait(0.5)

            continue
        end

        --==================================================
        -- SEARCH STARTED
        --==================================================

        if not NotificationState.SearchStarted then

            NotificationState.SearchStarted = true
            NotificationState.RequestErrorShown = false
            NotificationState.NoServerShown = false

            local role = GetRole()

            Notify(
                "Server Hop     \n",
                role
                    .. " detected • Searching...     ",
                4
            )
        end

        --==================================================
        -- REQUEST SERVER LIST
        --==================================================

        local success, result =
            pcall(function()

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

        --==================================================
        -- REQUEST FAILED
        --==================================================

        if not success
            or not result
            or not result.data then

            if not NotificationState.RequestErrorShown then

                NotificationState.RequestErrorShown = true

                Notify(
                    "Server Hop     \n",
                    "Failed to fetch servers • Retrying...     ",
                    4
                )
            end

            task.wait(3)

            continue
        end

        NotificationState.RequestErrorShown = false

        local ServersList =
            result.data

        --==================================================
        -- FIND SERVER
        --==================================================

        local FoundServer = false

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
                and Server.playing <= 2

                and not IgnoredServers[Server.id]
            then

                FoundServer = true

                local playerCount =
                    Server.playing or 0

                local ping =
                    Server.ping or 0

                --==================================================
                -- SERVER FOUND
                --==================================================

                Notify(
                    "Server Hop     \n",
                    string.format(
                        "%d players • %dms • Teleporting...     ",
                        playerCount,
                        ping
                    ),
                    5
                )

                --==================================================
                -- MARK SERVER BEFORE TELEPORT
                --==================================================

                IgnoredServers[Server.id] =
                    os.time()

                UpdateIgnoredServers(
                    IgnoredServers
                )

                NotificationState.LastServer =
                    Server.id

                --==================================================
                -- TELEPORT
                --==================================================

                TeleportService:TeleportToPlaceInstance(
                    game.PlaceId,
                    Server.id,
                    Players.LocalPlayer
                )

                return
            end
        end

        --==================================================
        -- NO SERVER FOUND ON CURRENT PAGE
        --==================================================

        if not FoundServer
            and not NotificationState.NoServerShown then

            NotificationState.NoServerShown = true

            Notify(
                "Server Hop     \n",
                "No suitable server found • Continuing search...     ",
                4
            )
        end

        --==================================================
        -- NEXT PAGE
        --==================================================

        cursor =
            result.nextPageCursor

        if not cursor then

            -- Start pagination again
            cursor = ""

            NotificationState.NoServerShown = false

            task.wait(1)

        else

            task.wait(0.2)
        end

    end
end

--==================================================
-- AUTO FARM TOGGLE
--==================================================

AutoFarmGroup:AddToggle(
    "EnableAutoFarm",
    {
        Text = "Enable Auto Farm",

        Tooltip =
            "Teleport Survivor to the detected finish location",

        Default = false,

        Callback = function(Value)

            if Value then

                Notify(
                    "Auto Farm     \n",
                    "Enabled.     ",
                    3
                )

            else

                Notify(
                    "Auto Farm     \n",
                    "Disabled.     ",
                    3
                )

                BeatState.BeatSurvivorDone = false
                BeatState.LastFinishPos = nil

                NotificationState.MapDetected = false
                NotificationState.FinishDetected = false
            end
        end,
    }
)

--==================================================
-- AUTO SERVERHOP
--==================================================

AutoFarmGroup:AddToggle(
    "ServerHop",
    {
        Text = "Server Hop",

        Tooltip =
            "Hop to 1-2 player servers as Killer or Spectator",

        Default = false,

        Callback = function(Value)

            if Value then

                local role = GetRole()

                if IsRound
                    and (
                        role == "Killer"
                        or role == "Spectator"
                    ) then

                    Notify(
                        "Server Hop     \n",
                        "Searching...     ",
                        4
                    )

                elseif IsRound
                    and role == "Survivor" then

                    Notify(
                        "Server Hop     \n",
                        "Waiting for Survivor to finish...     ",
                        4
                    )

                else

                    Notify(
                        "Server Hop     \n",
                        "Waiting for valid condition...     ",
                        4
                    )
                end

                task.spawn(function()
                    ServerHop()
                end)

            else

                Notify(
                    "Server Hop     \n",
                    "Disabled.     ",
                    3
                )

                NotificationState.SearchStarted = false
                NotificationState.RequestErrorShown = false
                NotificationState.NoServerShown = false
            end

        end,
    }
)

--==================================================
-- AUTO EXECUTE
--==================================================

AutoFarmGroup:AddToggle(
    "AutoExecute",
    {
        Text = "Auto Execute",

        Tooltip =
            "Automatically execute the script",

        Default = false,
    }
)

--==================================================
-- WEBHOOK
--==================================================

WebhookGroup:AddToggle(
    "EnableWebhook",
    {
        Text = "Enable Webhook",

        Tooltip =
            "Enable webhook notifications",

        Default = false,
    }
)

WebhookGroup:AddInput(
    "WebhookLink",
    {
        Text = "Webhook Link",

        Default = "",

        Placeholder =
            "Enter webhook URL...",

        Numeric = false,

        Finished = false,

        ClearTextOnFocus = false,
    }
)

--==================================================
-- TEST NOTIFICATIONS
--==================================================

local TestNotificationGroup =
    Tabs.AutoFarm:AddRightGroupbox(
        "Test Notifications",
        "bell"
    )

TestNotificationGroup:AddButton(
    "1. Simple",
    function()

        Library:Notify({
            Title = "Server Hop",
            Description = "Simple notification",
            Time = 4,
        })

    end
)

TestNotificationGroup:AddButton(
    "2. Icon",
    function()

        Library:Notify({
            Title = "Server Hop",
            Description = "Notification with an icon",
            Icon = "info",
            Time = 4,
        })

    end
)

TestNotificationGroup:AddButton(
    "3. Big Icon",
    function()

        Library:Notify({
            Title = "Server Hop",
            Description = "Notification with a big icon",
            BigIcon = "rbxassetid://10204738596",
            IconColor = Color3.new(0, 1, 0),
            Time = 4,
        })

    end
)

TestNotificationGroup:AddButton(
    "4. Persistent",
    function()

        local Notification =
            Library:Notify({
                Title = "Server Hop",
                Description = "Persistent notification",
                Persist = true,
            })

        task.delay(
            5,
            function()

                if Notification then
                    Notification:Destroy()
                end

            end
        )

    end
)

TestNotificationGroup:AddButton(
    "5. Update",
    function()

        local Notification =
            Library:Notify({
                Title = "Server Hop",
                Description = "Waiting...",
                Persist = true,
            })

        task.delay(
            2,
            function()

                Notification:ChangeTitle(
                    "Server Hop - Updated"
                )

                Notification:ChangeDescription(
                    "Notification has been updated!"
                )

            end
        )

        task.delay(
            5,
            function()

                Notification:Destroy()

            end
        )

    end
)

TestNotificationGroup:AddButton(
    "6. Progress",
    function()

        local Notification =
            Library:Notify({
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

    end
)

--==================================================
-- SETTINGS
--==================================================

local MenuGroup =
    Tabs.Settings:AddLeftGroupbox(
        "Menu",
        "wrench"
    )

MenuGroup:AddToggle(
    "KeybindMenuOpen",
    {
        Default =
            Library.KeybindFrame.Visible,

        Text = "Open Keybind Menu",

        Callback = function(Value)

            Library.KeybindFrame.Visible =
                Value

        end,
    }
)

MenuGroup:AddToggle(
    "ShowCustomCursor",
    {
        Text = "Custom Cursor",

        Default =
            Library.ShowCustomCursor,

        Callback = function(Value)

            Library.ShowCustomCursor =
                Value

        end,
    }
)

MenuGroup:AddDropdown(
    "NotificationSide",
    {
        Values = {
            "Left",
            "Right",
        },

        Default = "Right",

        Text = "Notification Side",

        Callback = function(Value)

            Library:SetNotifySide(
                Value
            )

        end,
    }
)

MenuGroup:AddDropdown(
    "DPIDropdown",
    {
        Values = {
            "50%",
            "75%",
            "100%",
            "125%",
            "150%",
            "175%",
            "200%",
        },

        Default = "100%",

        Text = "DPI Scale",

        Callback = function(Value)

            local DPI =
                tonumber(
                    Value:gsub("%%", "")
                )

            if DPI then

                Library:SetDPIScale(
                    DPI
                )

            end

        end,
    }
)

MenuGroup:AddSlider(
    "UICornerSlider",
    {
        Text = "Corner Radius",

        Default =
            Library.CornerRadius,

        Min = 0,
        Max = 20,
        Rounding = 0,

        Callback = function(Value)

            Window:SetCornerRadius(
                Value
            )

        end,
    }
)

MenuGroup:AddDivider()

MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker(
        "MenuKeybind",
        {
            Default = "RightShift",
            NoUI = true,
            Text = "Menu keybind",
        }
    )

MenuGroup:AddButton(
    "Unload",
    function()

        Library:Unload()

    end
)

Library.ToggleKeybind =
    Options.MenuKeybind

--==================================================
-- SAVE / THEME MANAGER
--==================================================

ThemeManager:SetLibrary(
    Library
)

SaveManager:SetLibrary(
    Library
)

ThemeManager:SetFolder(
    "AutoFarm"
)

SaveManager:SetFolder(
    "AutoFarm"
)

SaveManager:SetSubFolder(
    "Settings"
)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({
    "MenuKeybind",
})

SaveManager:BuildConfigSection(
    Tabs.Settings
)

ThemeManager:ApplyToTab(
    Tabs.Settings
)

SaveManager:LoadAutoloadConfig()

--==================================================
-- MAIN LOOP
--==================================================

task.spawn(function()

    while not Library.Unloaded do

        pcall(function()

            local CurrentRole =
                GetRole()

            --==================================================
            -- SURVIVOR -> SPECTATOR
            -- ESCAPE COMPLETED
            --==================================================

            if IsRound
                and NotificationState.LastRole == "Survivor"
                and CurrentRole == "Spectator"
                and not NotificationState.EscapeCompleted then

                NotificationState.EscapeCompleted = true

                Notify(
                    "Auto Farm     \n",
                    "Escape completed • Waiting for server hop...     ",
                    5
                )
            end

            NotificationState.LastRole =
                CurrentRole

            --==================================================
            -- AUTO FARM
            --==================================================

            BeatGameSurvivor()

        end)

        task.wait(0.1)

    end

end)

--==================================================
-- SCRIPT READY
--==================================================

Notify(
    "VD Auto Farm     \n",
    "Script loaded successfully.     ",
    4
)
