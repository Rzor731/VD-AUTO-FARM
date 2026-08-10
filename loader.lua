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

    FinishPending = false,
    FinishPendingSince = 0,
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

    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local MarketplaceService = game:GetService("MarketplaceService")
    local LocalPlayer = Players.LocalPlayer

    -- Fetch Game Name
    local gameName = "Unknown Game"
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)

    -- Player Details
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
        BeatState.FinishPending = false
        BeatState.FinishPendingSince = 0
        return
    end

    -- Only Survivor
    if GetRole() ~= "Survivor" then
        BeatState.FinishPending = false
        BeatState.FinishPendingSince = 0
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
        BeatState.FinishPending = false
        BeatState.FinishPendingSince = 0
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
        BeatState.FinishPending = false
        BeatState.FinishPendingSince = 0
        return
    end

    --==================================================
    -- START 5 SECOND COUNTDOWN
    --==================================================

    if not BeatState.FinishPending then

        BeatState.FinishPending = true
        BeatState.FinishPendingSince = os.clock()

        return
    end

    -- Still waiting
    if os.clock() - BeatState.FinishPendingSince < 5 then
        return
    end

    --==================================================
    -- RE-CHECK BEFORE TELEPORT
    --==================================================

    if not Toggles.EnableAutoFarm.Value then

        BeatState.FinishPending = false
        BeatState.FinishPendingSince = 0

        return
    end

    if GetRole() ~= "Survivor" then

        BeatState.FinishPending = false
        BeatState.FinishPendingSince = 0

        return
    end

    local currentRoot = GetCharacterRoot()

    if not currentRoot then

        BeatState.FinishPending = false
        BeatState.FinishPendingSince = 0

        return
    end

    --==================================================
    -- TELEPORT TO FINISH
    --==================================================

    currentRoot.CFrame = CFrame.new(
        exitPos + Vector3.new(0, 3, 0)
    )

    --==================================================
    -- SAVE STATE
    --==================================================

    BeatState.BeatSurvivorDone = true
    BeatState.LastFinishPos = exitPos

    BeatState.FinishPending = false
    BeatState.FinishPendingSince = 0

	SendDiscordWebhook("🏆 Round Finished!", "User successfully teleported to the map finish point!")
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
-- SERVER HOP DELAY STATE
--==================================================

local ServerHopPending = false
local ServerHopPendingSince = 0

local SERVER_HOP_DELAY = 2
local MAX_SERVER_PLAYERS = 2

--==================================================
-- STATUS DETECTOR
--==================================================

StatusUpdateEvent.OnClientEvent:Connect(function(Status)

    if Status == "WaitingForPlayers" then

        IsRound = false

        ServerHopPending = false
        ServerHopPendingSince = 0

    elseif Status == "IntermissionStarting" then

        IsRound = false

        ServerHopPending = false
        ServerHopPendingSince = 0

    elseif Status == "Intermission" then

        IsRound = false

        ServerHopPending = false
        ServerHopPendingSince = 0
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

    -- Survivor is handled by AutoFarm
    local role = GetRole()

    if role == "Survivor" then
        return false
    end

    -- Killer can hop during round
    if role == "Killer" then

        if IsRound then
            return true
        end

        return false
    end

    -- Spectator can only hop if round is active
    if role == "Spectator" then

        if IsRound then
            return true
        end

        return false
    end

    return false
end

--==================================================
-- SERVER HOP DELAY
--==================================================

local function WaitForServerHopDelay()

    -- Start countdown
    if not ServerHopPending then

        ServerHopPending = true
        ServerHopPendingSince = os.clock()

        return false
    end

    -- Still waiting for 2 seconds
    if os.clock() - ServerHopPendingSince < SERVER_HOP_DELAY then
        return false
    end

    -- Re-check condition after 2 seconds
    if not Toggles.ServerHop.Value then

        ServerHopPending = false
        ServerHopPendingSince = 0

        return false
    end

    if not CanServerHop() then

        ServerHopPending = false
        ServerHopPendingSince = 0

        return false
    end

    -- Delay completed and condition is still valid
    ServerHopPending = false
    ServerHopPendingSince = 0

    return true
end

--==================================================
-- SERVER HOP DENGAN RETRY MECHANISM
--==================================================

local RetryConfig = {
    MaxRetries = 3,
    RetryDelay = 2,
    BackoffMultiplier = 1.5,
    MaxConsecutiveFailures = 5,
    CooldownPeriod = 30,
}

local RetryState = {
    CurrentRetries = 0,
    ConsecutiveFailures = 0,
    FailedServers = {},
    LastAttemptTime = 0,
    IsInCooldown = false,
}

--==================================================
-- CLEAN FAILED SERVERS
--==================================================

local function CleanFailedServers()

    local now = os.time()
    local expiredTime = 300

    for serverId, timestamp
        in pairs(RetryState.FailedServers) do

        if now - timestamp > expiredTime then
            RetryState.FailedServers[serverId] = nil
        end
    end
end

--==================================================
-- CHECK SERVER AVAILABILITY
--==================================================

local function IsServerAvailable(serverId)

    if IgnoredServers[serverId] then
        return false, "Server already ignored"
    end

    if RetryState.FailedServers[serverId] then

        local timeSinceFailure =
            os.time()
            - RetryState.FailedServers[serverId]

        if timeSinceFailure < 60 then
            return false, "Server in cooldown period"
        end
    end

    return true, nil
end

--==================================================
-- TELEPORT WITH RETRY
--==================================================

local function TeleportWithRetry(serverId, maxRetries)

    local retryCount = 0
    local currentDelay = RetryConfig.RetryDelay

    while retryCount <= maxRetries do

        if retryCount > 0 then

            Library:Notify({
                Title = "Retry Attempt",

                Description = string.format(
                    "Retry %d/%d for server %s (Delay: %.1fs)",
                    retryCount,
                    maxRetries,
                    serverId,
                    currentDelay
                ),

                Time = 3,
            })

            task.wait(currentDelay)

            currentDelay =
                currentDelay
                * RetryConfig.BackoffMultiplier
        end

        local success, errorResult =
            pcall(function()

                TeleportService:TeleportToPlaceInstance(
                    game.PlaceId,
                    serverId,
                    Players.LocalPlayer
                )
            end)

        if success then
            return true, "Teleport successful"

        else

            retryCount =
                retryCount + 1

            RetryState.CurrentRetries =
                retryCount

            local errorMsg =
                tostring(errorResult)

            if errorMsg:find("TeleportThrottled")
                or errorMsg:find("TooManyRequests") then

                currentDelay =
                    math.max(currentDelay, 5)

                Library:Notify({
                    Title = "Rate Limited",
                    Description =
                        "Teleport throttled, increasing delay...",
                    Time = 3,
                })

            elseif errorMsg:find("ServerFull")
                or errorMsg:find("ServerClosed") then

                return false, "Server full or closed"

            elseif errorMsg:find("NetworkError")
                or errorMsg:find("Timeout") then

                Library:Notify({
                    Title = "Network Error",
                    Description =
                        "Connection issue, retrying...",
                    Time = 3,
                })
            end
        end
    end

    return false, "Max retries exceeded"
end

--==================================================
-- SERVER HOP RETRY STATE
--==================================================

local function ServerHopWithRetry()

    if RetryState.IsInCooldown then

        local timeSinceLastAttempt =
            os.time()
            - RetryState.LastAttemptTime

        if timeSinceLastAttempt
            < RetryConfig.CooldownPeriod then

            local remainingCooldown =
                RetryConfig.CooldownPeriod
                - timeSinceLastAttempt

            Library:Notify({
                Title = "Cooldown Active",

                Description = string.format(
                    "Too many failures. Cooling down... (%ds remaining)",
                    remainingCooldown
                ),

                Time = 3,
            })

            return false
        else

            RetryState.IsInCooldown = false
            RetryState.ConsecutiveFailures = 0
        end
    end

    CleanFailedServers()

    return true
end

--==================================================
-- MAIN SERVER HOP
--==================================================

local function ServerHop()

    local cursor = ""
    local attemptCount = 0

    while Toggles.ServerHop.Value
        and not Library.Unloaded do

        --==================================================
        -- CHECK RETRY COOLDOWN
        --==================================================

        if not ServerHopWithRetry() then

            task.wait(1)

        --==================================================
        -- CHECK ROLE / ROUND
        --==================================================

        elseif not CanServerHop() then

            -- Condition not valid.
            -- Cancel any existing 2-second countdown.

            ServerHopPending = false
            ServerHopPendingSince = 0

            task.wait(0.1)

        --==================================================
        -- WAIT 2 SECONDS BEFORE HOP
        --==================================================

        elseif not WaitForServerHopDelay() then

            task.wait(0.1)

        --==================================================
        -- READY TO SEARCH SERVER
        --==================================================

        else

            attemptCount =
                attemptCount + 1

            local success, result =
                pcall(function()

                    local url =
                        "https://games.roblox.com/v1/games/"
                        .. game.PlaceId
                        .. "/servers/Public?limit=100"
                        .. "&sortOrder=Asc"
                        .. "&excludeFullGames=true"
                        .. "&cursor=" .. cursor

                    return HttpService:JSONDecode(
                        game:HttpGet(url)
                    )
                end)

            if not success
                or not result
                or not result.data then

                Library:Notify({
                    Title = "API Error",
                    Description =
                        "Failed to fetch servers. Retrying...",
                    Time = 3,
                })

                task.wait(3)

            else

                local ServersList =
                    result.data

                local serverFound = false

                --==================================================
                -- SEARCH VALID SERVER
                --==================================================

                for _, Server
                    in ipairs(ServersList) do

                    -- Condition can change while scanning
                    if not CanServerHop() then
                        break
                    end

                    --==================================================
                    -- SERVER FILTER
                    --
                    -- ONLY 1-2 PLAYERS
                    --==================================================

                    local isValid =
                        Server.id
                        and Server.id ~= game.JobId

                        and Server.playing
                        and Server.playing >= 1
                        and Server.playing <= MAX_SERVER_PLAYERS

                        and Server.maxPlayers
                        and Server.playing
                            < Server.maxPlayers

                    if isValid then

                        local available, reason =
                            IsServerAvailable(
                                Server.id
                            )

                        if available then

                            serverFound = true

                            -- Mark server as attempted
                            IgnoredServers[
                                Server.id
                            ] = os.time()

                            UpdateIgnoredServers(
                                IgnoredServers
                            )

                            --==================================================
                            -- WEBHOOK
                            --==================================================

                            SendDiscordWebhook(
                                "🔄 Server Hopping (Attempt "
                                .. attemptCount
                                .. ")",

                                "Attempting to join server: `"
                                .. Server.id
                                .. "`\nPlayers: "
                                .. Server.playing
                                .. "/"
                                .. Server.maxPlayers
                            )

                            --==================================================
                            -- TELEPORT
                            --==================================================

                            local teleportSuccess,
                                teleportMsg =
                                TeleportWithRetry(
                                    Server.id,
                                    RetryConfig.MaxRetries
                                )

                            if teleportSuccess then

                                RetryState.ConsecutiveFailures =
                                    0

                                RetryState.LastAttemptTime =
                                    os.time()

                                return

                            else

                                RetryState.FailedServers[
                                    Server.id
                                ] = os.time()

                                RetryState.ConsecutiveFailures =
                                    RetryState.ConsecutiveFailures
                                    + 1

                                RetryState.LastAttemptTime =
                                    os.time()

                                --==================================================
                                -- MAX CONSECUTIVE FAILURES
                                --==================================================

                                if RetryState.ConsecutiveFailures
                                    >= RetryConfig.MaxConsecutiveFailures then

                                    RetryState.IsInCooldown =
                                        true

                                    Library:Notify({
                                        Title =
                                            "Max Failures Reached",

                                        Description =
                                            string.format(
                                                "%d consecutive failures. Entering cooldown for %d seconds.",
                                                RetryState.ConsecutiveFailures,
                                                RetryConfig.CooldownPeriod
                                            ),

                                        Time = 5,
                                    })

                                    SendDiscordWebhook(
                                        "⚠️ Cooldown Activated",

                                        string.format(
                                            "Too many failed attempts (%d). Cooldown for %ds.\nLast server: %s",
                                            RetryState.ConsecutiveFailures,
                                            RetryConfig.CooldownPeriod,
                                            Server.id
                                        )
                                    )

                                    task.wait(
                                        RetryConfig.CooldownPeriod
                                    )

                                    RetryState.IsInCooldown =
                                        false

                                    RetryState.ConsecutiveFailures =
                                        0
                                end

                                Library:Notify({
                                    Title =
                                        "Teleport Failed",

                                    Description =
                                        string.format(
                                            "Server %s: %s (Failures: %d/%d)",
                                            string.sub(
                                                Server.id,
                                                1,
                                                8
                                            ) .. "...",

                                            teleportMsg,

                                            RetryState.ConsecutiveFailures,

                                            RetryConfig.MaxConsecutiveFailures
                                        ),

                                    Time = 3,
                                })
                            end
                        end
                    end
                end

                --==================================================
                -- NO SERVER FOUND
                --==================================================

                if not serverFound then

                    cursor =
                        result.nextPageCursor

                    if not cursor then

                        cursor = ""

                        Library:Notify({
                            Title =
                                "No Servers Found",

                            Description =
                                "No valid 1-2 player servers found. Restarting search...",

                            Time = 3,
                        })

                        task.wait(2)

                    else

                        task.wait(0.5)
                    end
                end
            end
        end
    end

    -- Clean pending state when loop ends
    ServerHopPending = false
    ServerHopPendingSince = 0
end

--==================================================
-- AUTO EXECUTE TOGGLE
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
            Title = "Webhook Success   \n",
            Description = "Test message sent to Discord!",
            Icon = "check",
            Time = 4,
        })
    else
        Library:Notify({
            Title = "Webhook Failed   \n",
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

return {
    ServerHop = ServerHop,
    TeleportWithRetry = TeleportWithRetry,
    RetryState = RetryState,
    RetryConfig = RetryConfig,
    CleanFailedServers = CleanFailedServers,
}
