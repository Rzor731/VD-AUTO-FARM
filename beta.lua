-- ================================================================
-- VD AUTO FARM - MIGRASI KE MODERNV2 (ZILUX)
-- Menggunakan library dari ziaanclient.vercel.app/zilux
-- ================================================================

-- Load ModernV2 Library
local ModernV2 = loadstring(game:HttpGet("https://ziaanclient.vercel.app/zilux"))()
if not ModernV2 then
    error("Gagal memuat ModernV2 library. Periksa URL atau koneksi.")
end

pcall(function()
    game:GetService("GuiService"):SetErrorPromptEnabled(false)
end)

-- Service references
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ================================================================
-- 1. BUAT WINDOW
-- ================================================================
local Window = ModernV2:CreateWindow({
    Name = "",                              -- Title (kosong)
    Content = "version: 1.0.0",             -- Footer
    Icon = "bot",
    Size = ModernV2.Scales.Default,
    Keybind = "RightShift",                 -- Toggle menu
    ConfigFolder = "VD_AutoFarm_Configs",
    TextGradient = true,
})

-- ================================================================
-- 2. TABS
-- ================================================================
local Tabs = {
    AutoFarm = Window:AddTab({ Name = "Auto Farm", Icon = "zap" }),
    Settings = Window:AddTab({ Name = "Settings", Icon = "settings" }),
}

-- ================================================================
-- 3. SECTIONS (GROUPBOX)
-- ================================================================
local AutoFarmGroup = Tabs.AutoFarm:AddSection({
    Name = "Auto Farm",
    Position = "Left",
    Icon = "zap",
    Box = true,
})

local WebhookGroup = Tabs.AutoFarm:AddSection({
    Name = "Webhook",
    Position = "Right",
    Icon = "webhook",
    Box = true,
})

-- ================================================================
-- 4. PENAMPUNG KOMPONEN
-- ================================================================
local Options = {}
local Toggles = {}

-- ================================================================
-- 5. NOTIFIKASI
-- ================================================================
local LastNotifTime = 0
local function Notify(title, desc, duration)
    local now = os.clock()
    if now - LastNotifTime < 2.5 then return end
    LastNotifTime = now
    Window:Notify({
        Title = title,
        Content = desc,
        Duration = duration or 3,
        Icon = "lucide:bell",
    })
end

-- ================================================================
-- 6. FUNGSI UTAMA (sama persis dengan script asli)
-- ================================================================
local function GetRole()
    local team = LocalPlayer.Team
    if not team then return "Unknown" end
    local n = team.Name
    if n == "Killer" then return "Killer"
    elseif n == "Survivors" then return "Survivor"
    elseif n == "Spectator" or n == "Spectators" then return "Spectator" end
    return "Lobby"
end

local function GetRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function SafeReq(opts)
    local fn = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request) or (krnl and krnl.request)
    return fn and fn(opts)
end

local function ExecutorName()
    return (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown Executor"
end

-- ================================================================
-- 7. WEBHOOK & SNAPSHOT
-- ================================================================
local ATTR_FILE = "VD_AutoFarm_Attributes.json"
local PrevAttrs

local function LoadSnapshot()
    if not isfile or not readfile or not isfile(ATTR_FILE) then return nil end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(ATTR_FILE))
    end)
    if not ok or type(data) ~= "table" or tonumber(data.UserId) ~= LocalPlayer.UserId then return nil end
    return {
        KillerChance = tonumber(data.KillerChance),
        EXP = tonumber(data.EXP),
        Screws = tonumber(data.Screws),
        Gears = tonumber(data.Gears),
    }
end

local function SaveSnapshot(attrs)
    if not writefile then return false end
    local data = {
        UserId = LocalPlayer.UserId,
        KillerChance = attrs.KillerChance,
        EXP = attrs.EXP,
        Screws = attrs.Screws,
        Gears = attrs.Gears,
        UpdatedAt = os.time(),
    }
    return pcall(function()
        writefile(ATTR_FILE, HttpService:JSONEncode(data))
    end)
end

local function Delta(cur, prev)
    cur = tonumber(cur) or 0
    if prev == nil then return 0 end
    return cur - (tonumber(prev) or 0)
end

PrevAttrs = LoadSnapshot()

local function WebhookEnabled()
    return Toggles.EnableWebhook and Toggles.EnableWebhook:GetValue()
end

local function WebhookUrl()
    return Options.WebhookLink and Options.WebhookLink:GetValue() or ""
end

local function ValidWebhook(url)
    return url ~= "" and string.find(url, "discord.com/api/webhooks")
end

local function SendDebug(title, desc)
    if not WebhookEnabled() then return false end
    local url = WebhookUrl()
    if not ValidWebhook(url) then return false end
    local payload = {
        embeds = {
            {
                title = title,
                description = desc,
                color = 16711680,
                footer = { text = "ServerHop Debug" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
            }
        }
    }
    local res = SafeReq({
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload),
    })
    return res and (res.StatusCode == 200 or res.StatusCode == 204)
end

local function SendWebhook(title, desc, force)
    if not force and not WebhookEnabled() then return false, "Disabled" end
    local url = WebhookUrl()
    if not ValidWebhook(url) then return false, "Invalid URL" end
    local attrs = LocalPlayer:GetAttributes()
    local kc = tonumber(attrs.KillerChance) or 0
    local exp = tonumber(attrs.EXP) or 0
    local screws = tonumber(attrs.Screws) or 0
    local gears = tonumber(attrs.Gears) or 0
    local lvl = tonumber(attrs.Level) or 0
    if not PrevAttrs then
        PrevAttrs = { KillerChance = kc, EXP = exp, Screws = screws, Gears = gears }
    end
    local payload = {
        embeds = {
            {
                title = title or string.format("%s · Level %d", LocalPlayer.DisplayName, lvl),
                url = string.format("https://www.roblox.com/users/%d/profile", LocalPlayer.UserId),
                description = desc,
                color = 3638942,
                fields = {
                    { name = "💀 SIN", value = string.format("%s (**%+d**)", kc, Delta(kc, PrevAttrs.KillerChance)), inline = false },
                    { name = "🧪 EXP", value = string.format("%s (**%+d**)", exp, Delta(exp, PrevAttrs.EXP)), inline = false },
                    { name = "🔩 Screws", value = string.format("%s (**%+d**)", screws, Delta(screws, PrevAttrs.Screws)), inline = false },
                    { name = "⚙️ Gears", value = string.format("%s (**%+d**)", gears, Delta(gears, PrevAttrs.Gears)), inline = false },
                    { name = "🆔 Server ID", value = string.format("```\n%s\n```", game.JobId ~= "" and game.JobId or "Singleplayer"), inline = false },
                },
                footer = { text = string.format("VD Auto Farm · %s", ExecutorName()) },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
            }
        }
    }
    local res = SafeReq({
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload),
    })
    if res and (res.StatusCode == 200 or res.StatusCode == 204) then
        PrevAttrs = { KillerChance = kc, EXP = exp, Screws = screws, Gears = gears }
        SaveSnapshot(PrevAttrs)
        return true, "OK"
    end
    return false, "Status: " .. tostring(res and res.StatusCode or "No Response")
end

-- ================================================================
-- 8. BEAT GAME (AUTO FARM)
-- ================================================================
local BeatState = {
    LastFinishPos = nil,
    BeatSurvivorDone = false,
    LastRole = nil,
}
local FinishWatchActive = false
local ForceServerHop = false

local function FindFinish(map)
    local pos
    pcall(function()
        if map:FindFirstChild("RooftopHitbox") or map:FindFirstChild("Rooftop") then
            pos = Vector3.new(3098.16, 454.04, -4918.74)
            return
        end
        if map:FindFirstChild("HooksMeat") then
            pos = Vector3.new(1546.12, 152.21, -796.72)
            return
        end
        if map:FindFirstChild("churchbell") then
            pos = Vector3.new(760.98, -20.14, -78.48)
            return
        end
        local finish = map:FindFirstChild("Finishline") or map:FindFirstChild("FinishLine") or map:FindFirstChild("Fininshline")
        if finish then
            if finish:IsA("BasePart") then
                pos = finish.Position
            elseif finish:IsA("Model") then
                local p = finish:FindFirstChildWhichIsA("BasePart")
                if p then pos = p.Position end
            end
            return
        end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj.Name:lower():find("finish") then
                if obj:IsA("BasePart") then pos = obj.Position break
                elseif obj:IsA("Model") then
                    local p = obj:FindFirstChildWhichIsA("BasePart")
                    if p then pos = p.Position break end
                end
            end
        end
        if pos then return end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("MeshPart") and obj.Material == Enum.Material.Limestone then
                pos = Vector3.new(-947.90, 152.12, -7579.52)
                break
            end
        end
        if pos then return end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("MeshPart") and obj.Material == Enum.Material.Leather then
                pos = Vector3.new(1546.12, 152.21, -796.72)
                break
            end
        end
    end)
    return pos
end

local function BeatGame()
    if not Toggles.EnableAutoFarm:GetValue() then
        BeatState.BeatSurvivorDone = false
        BeatState.LastFinishPos = nil
        return
    end
    local role = GetRole()
    if BeatState.LastRole ~= role then
        if role == "Survivor" then
            Notify("🟢 Survivor!", "Ready to farm.")
        end
        BeatState.LastRole = role
    end
    if role ~= "Survivor" then return end
    local root = GetRoot()
    if not root then
        Notify("⏳ Waiting", "Character not loaded")
        return
    end
    local map = Workspace:FindFirstChild("Map")
    if not map then
        Notify("⚠️ No Map", "Waiting for map")
        return
    end
    local exitPos = FindFinish(map)
    if not exitPos then
        Notify("⚠️ Finish Not Found", "Map unsupported")
        return
    end
    if BeatState.LastFinishPos and (exitPos - BeatState.LastFinishPos).Magnitude > 50 then
        BeatState.BeatSurvivorDone = false
    end
    if BeatState.BeatSurvivorDone then return end
    Notify("📍 Finish Found", "Waiting 6s...")
    task.wait(6)
    if not Toggles.EnableAutoFarm:GetValue() then
        Notify("⛔ Cancelled", "Toggle turned off")
        return
    end
    if GetRole() ~= "Survivor" then
        Notify("⛔ Cancelled", "Not Survivor anymore")
        return
    end
    local currentRoot = GetRoot()
    if not currentRoot then
        Notify("⛔ Cancelled", "Character missing")
        return
    end
    Notify("🚀 Teleporting", "Moving to finish...")
    currentRoot.CFrame = CFrame.new(exitPos)
    BeatState.BeatSurvivorDone = true
    BeatState.LastFinishPos = exitPos
    Notify("✅ Teleport Success", "Round completed!")
    if not FinishWatchActive then
        FinishWatchActive = true
        task.spawn(function()
            local start = os.clock()
            local timeout = 10
            while os.clock() - start < timeout do
                if not Toggles.EnableAutoFarm:GetValue() then
                    FinishWatchActive = false
                    return
                end
                if GetRole() == "Spectator" then
                    FinishWatchActive = false
                    Notify("👁️ Match Completed", "Role changed to Spectator.")
                    return
                end
                task.wait(0.5)
            end
            if GetRole() == "Survivor" then
                Notify("🔴 Match Stuck", "Still Survivor after finish. Server hopping...")
                pcall(function()
                    SendDebug("🔴 Match Stuck", string.format("Role remained `%s` after %ds.\nServer: `%s`", tostring(GetRole()), timeout, tostring(game.JobId)))
                end)
                if Toggles.ServerHop and Toggles.ServerHop:GetValue() then
                    ForceServerHop = true
                end
            end
            FinishWatchActive = false
        end)
    end
    task.wait(5)
    SendWebhook()
end

-- ================================================================
-- 9. SERVER HOP
-- ================================================================
local IGNORE_FILE = "ServerHop.txt"
local IGNORE_CANDIDATE = 180
local IGNORE_FAILED = 600
local API_RETRY = 3
local PAGE_WAIT = 0.5
local NO_SERVER_WAIT = 3
local TELEPORT_TIMEOUT = 7
local TELEPORT_RETRY_WAIT = 2.5

local IgnoredServers = {}
local TargetServer = nil
local OriginalJob = nil
local TeleportInProgress = false
local TeleportFailed = false
local IsHopping = false

local function LoadIgnored()
    if not isfile or not readfile or not isfile(IGNORE_FILE) then return {} end
    local ok, content = pcall(readfile, IGNORE_FILE)
    if not ok then return {} end
    local now = os.time()
    local list = {}
    for _, line in ipairs(content:split("\n")) do
        local id, exp = line:match("^([^|]+)|(%d+)$")
        exp = tonumber(exp)
        if id and id ~= "" and exp and now < exp then
            list[id] = exp
        end
    end
    return list
end

local function SaveIgnored(list)
    if not writefile then return end
    local now = os.time()
    local lines = {}
    for id, exp in pairs(list) do
        if id and exp and now < exp then
            table.insert(lines, id .. "|" .. exp)
        end
    end
    pcall(function()
        writefile(IGNORE_FILE, table.concat(lines, "\n"))
    end)
end

local function AddIgnored(id, duration)
    if not id then return end
    IgnoredServers[id] = os.time() + duration
    SaveIgnored(IgnoredServers)
end

local function IsIgnored(id)
    local exp = IgnoredServers[id]
    if not exp then return false end
    if os.time() >= exp then
        IgnoredServers[id] = nil
        SaveIgnored(IgnoredServers)
        return false
    end
    return true
end

local IsRound = false
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StatusEvent = Remotes:WaitForChild("StatusUpdateEvent")
local TimeEvent = Remotes:WaitForChild("TimeUpdateEvent")

StatusEvent.OnClientEvent:Connect(function(s)
    if s == "WaitingForPlayers" or s == "IntermissionStarting" or s == "Intermission" then
        IsRound = false
        BeatState.BeatSurvivorDone = false
    end
end)
TimeEvent.OnClientEvent:Connect(function(s)
    if s == "Round" then
        IsRound = true
    end
end)

local function CanHop()
    if not IsRound then return false end
    local r = GetRole()
    return r == "Spectator" or r == "Killer"
end

local function ResetTeleportState()
    TargetServer = nil
    OriginalJob = nil
    TeleportInProgress = false
    TeleportFailed = false
end

local function BeginTeleport(id)
    TargetServer = id
    OriginalJob = game.JobId
    TeleportInProgress = true
    TeleportFailed = false
end

TeleportService.TeleportInitFailed:Connect(function(player, result, err)
    if player ~= LocalPlayer or not TeleportInProgress then return end
    local id = TargetServer
    TeleportFailed = true
    if id then
        AddIgnored(id, IGNORE_FAILED)
        Notify("❌ Teleport Failed", string.format("Server %s blacklisted 10m", id:sub(1, 8)))
        pcall(function()
            SendDebug("🐛 Teleport Failed", string.format("Server: `%s`\nCode: `%s`\nError: `%s`", id, tostring(result), tostring(err)))
        end)
    end
end)

local function DoTeleport(id)
    BeginTeleport(id)
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, id, LocalPlayer)
    end)
    if not ok then
        TeleportInProgress = false
        AddIgnored(id, IGNORE_FAILED)
        Notify("❌ Teleport Error", "Call failed, retrying later")
        pcall(function()
            SendDebug("🐛 Teleport Call Failed", string.format("Server: `%s`\nError: `%s`", id, tostring(err)))
        end)
        ResetTeleportState()
        return false
    end
    return true
end

local function WaitTeleport()
    local start = os.clock()
    while TeleportInProgress and not TeleportFailed and os.clock() - start < TELEPORT_TIMEOUT do
        if game.JobId ~= OriginalJob then
            return "Success"
        end
        task.wait(0.1)
    end
    if TeleportFailed then return "Failed" end
    if game.JobId ~= OriginalJob then return "Success" end
    return "Timeout"
end

local function ServerHop()
    if IsHopping then return end
    IsHopping = true
    IgnoredServers = LoadIgnored()
    ResetTeleportState()
    local cursor = ""
    local apiFails = 0
    while Toggles.ServerHop and Toggles.ServerHop:GetValue() and not Window.Destroyed do
        local forced = ForceServerHop
        ForceServerHop = false
        if not forced and not CanHop() then
            ResetTeleportState()
            task.wait(0.5)
            goto continue
        end
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?limit=100&sortOrder=Asc&excludeFullGames=true&cursor=%s", game.PlaceId, HttpService:UrlEncode(cursor))
        local ok, res = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if not ok or not res or type(res.data) ~= "table" then
            apiFails = apiFails + 1
            if apiFails >= 5 then
                cursor = ""
                apiFails = 0
                pcall(function()
                    SendDebug("API Error", "Reset pagination after 5 failures")
                end)
            end
            task.wait(API_RETRY)
            goto continue
        end
        apiFails = 0
        local curJob = game.JobId
        local found = false
        for _, srv in ipairs(res.data) do
            if not Toggles.ServerHop:GetValue() or Window.Destroyed then break end
            if not forced and not CanHop() then break end
            if srv.id and srv.id ~= curJob and srv.playing == 2 and not IsIgnored(srv.id) then
                found = true
                local id = srv.id
                local count = srv.playing
                AddIgnored(id, IGNORE_CANDIDATE)
                Notify("📡 Teleporting", string.format("%d player | %s", count, id:sub(1, 8)))
                task.wait(2)
                if not DoTeleport(id) then
                    task.wait(TELEPORT_RETRY_WAIT)
                    goto continue
                end
                local result = WaitTeleport()
                if result == "Success" then
                    ResetTeleportState()
                    IsHopping = false
                    return
                elseif result == "Failed" then
                    ResetTeleportState()
                    task.wait(TELEPORT_RETRY_WAIT)
                    goto continue
                else
                    local failId = TargetServer
                    if failId then
                        AddIgnored(failId, IGNORE_FAILED)
                        pcall(function()
                            SendDebug("🐛 Teleport Timeout", string.format("Server %s no response in %ds", failId, TELEPORT_TIMEOUT))
                        end)
                    end
                    Notify("⚠️ Timeout", "Server didn't respond, trying next")
                    ResetTeleportState()
                    task.wait(TELEPORT_RETRY_WAIT)
                end
            end
        end
        if not found then
            local nextCursor = res.nextPageCursor or ""
            if nextCursor ~= "" then
                cursor = nextCursor
                task.wait(PAGE_WAIT)
            else
                cursor = ""
                Notify("⚠️ Server Hop", "No 1-3 player server available")
                task.wait(NO_SERVER_WAIT)
            end
        end
        ::continue::
    end
    ResetTeleportState()
    IsHopping = false
end

-- ================================================================
-- 10. KOMPONEN UI
-- ================================================================

-- AutoFarm Group
Toggles.EnableAutoFarm = AutoFarmGroup:AddToggle({
    Name = "Enable Auto Farm",
    Flag = "EnableAutoFarm",
    Default = false,
})

Toggles.ServerHop = AutoFarmGroup:AddToggle({
    Name = "Server Hop",
    Flag = "ServerHop",
    Default = false,
    Callback = function(v)
        if v then
            task.spawn(ServerHop)
        end
    end,
})

local LOADER_URL = "https://raw.githubusercontent.com/Rzor731/VD-AUTO-FARM/refs/heads/main/loader.lua"
local AutoExecuteQueued = false

local function QueueAutoExec()
    if AutoExecuteQueued or not Toggles.AutoExecute:GetValue() then return end
    if type(queue_on_teleport) ~= "function" then
        Notify("Auto Execute", "queue_on_teleport not available", 5)
        return
    end
    local code = string.format([[loadstring(game:HttpGet(%q))()]], LOADER_URL)
    local ok, err = pcall(function()
        queue_on_teleport(code)
    end)
    if ok then
        AutoExecuteQueued = true
        Notify("Auto Execute", "Queued for next teleport")
    else
        Notify("Auto Execute", "Failed: " .. tostring(err), 5)
    end
end

Toggles.AutoExecute = AutoFarmGroup:AddToggle({
    Name = "Auto Execute",
    Flag = "AutoExecute",
    Default = false,
    Callback = function(v)
        if v then
            QueueAutoExec()
        else
            AutoExecuteQueued = false
        end
    end,
})

-- Webhook Group
Toggles.EnableWebhook = WebhookGroup:AddToggle({
    Name = "Enable Webhook",
    Flag = "EnableWebhook",
    Default = false,
})

Options.WebhookLink = WebhookGroup:AddTextInput({
    Name = "Webhook Link",
    Flag = "WebhookLink",
    Default = "",
    Placeholder = "Enter webhook URL...",
})

WebhookGroup:AddButton({
    Name = "Test Webhook",
    Callback = function()
        local ok, msg = SendWebhook("🔔 Webhook Test", "Test from VD Auto Farm!", true)
        if ok then
            Notify("Webhook Success", "Test message sent!")
        else
            Notify("Webhook Failed", msg, 5)
        end
    end,
})

-- ================================================================
-- 11. SETTINGS TAB
-- ================================================================
local MenuGroup = Tabs.Settings:AddSection({
    Name = "Menu",
    Position = "Left",
    Icon = "wrench",
    Box = true,
})

-- Corner Radius (mengakses UICorner langsung)
MenuGroup:AddSlider({
    Name = "Corner Radius",
    Flag = "UICornerSlider",
    Default = 10,
    Min = 0,
    Max = 20,
    Rounding = 0,
    Callback = function(v)
        local corner = Window.Root:FindFirstChildWhichIsA("UICorner")
        if corner then
            corner.CornerRadius = UDim.new(0, v)
        end
    end,
})

MenuGroup:AddDivider()

MenuGroup:AddLabel({ Text = "Menu bind" })

Options.MenuKeybind = MenuGroup:AddKeybind({
    Name = "Menu Keybind",
    Flag = "MenuKeybind",
    Default = "RightShift",
    Mode = "Toggle",
    Callback = function(state)
        if state then
            Window:ToggleInterface()
        end
    end,
})

MenuGroup:AddButton({
    Name = "Unload",
    Callback = function()
        Window:Destroy()
    end,
})

-- ================================================================
-- 12. THEME & CONFIG
-- ================================================================
ModernV2:AddTheme({
    Name = "Default",
    Accent = Color3.fromRGB(78, 127, 252),
    Background = Color3.fromRGB(8, 8, 13),
    Surface = Color3.fromRGB(20, 22, 27),
    Outline = Color3.fromRGB(45, 48, 58),
    Text = Color3.fromRGB(255, 255, 255),
    Placeholder = Color3.fromRGB(140, 140, 155),
    Button = Color3.fromRGB(78, 127, 252),
    Icon = Color3.fromRGB(255, 255, 255),
})

-- Config otomatis via flag system, tidak perlu konfigurasi tambahan.
QueueAutoExec()

-- ================================================================
-- 13. LOOP UTAMA
-- ================================================================
task.spawn(function()
    while not Window.Destroyed do
        pcall(BeatGame)
        task.wait(1)
    end
end)

-- Tampilkan window
Window.Signal:SetValue(true)

-- ================================================================
-- SELESAI
-- ================================================================
