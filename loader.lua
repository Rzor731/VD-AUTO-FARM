--==================================================
-- OBSIDIAN UI + FARM FULL AFK 7/24
--==================================================
pcall(function() game:GetService("GuiService"):SetErrorPromptEnabled(false) end)

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
	LastRole = nil,
}
local FinishWatchActive = false
local ServerHop
local ForceServerHop = false
local LastNotifTime = 0
local function NotifyAF(title, desc, icon)
    local now = os.time()
    if now - LastNotifTime < 2.5 then return end
    LastNotifTime = now
    Library:Notify({
        Title = title .. "   \n",
        Description = desc .. "   ",
        Time = 3,
    })
end
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
	local req = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request) or (krnl and krnl.request)
	if req then
		return req(options)
	end
	return nil
end
-- Detect Executor Name
local function GetExecutorName()
	return (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown Executor"
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
	if type(isfile) ~= "function" or type(readfile) ~= "function" then
		return nil
	end
	if not isfile(ATTRIBUTE_FILE) then
		return nil
	end
	local HttpService = game:GetService("HttpService")
	local success, data = pcall(function()
		return HttpService:JSONDecode(
            readfile(ATTRIBUTE_FILE))
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
            ATTRIBUTE_FILE, HttpService:JSONEncode(data))
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
-- Webhook khusus untuk debug (tidak update snapshot)
local function SendDebugWebhook(title, description)
	if not Toggles.EnableWebhook or not Toggles.EnableWebhook.Value then
		return false
	end
	local webhookUrl = Options.WebhookLink and Options.WebhookLink.Value or ""
	if webhookUrl == "" or not string.find(webhookUrl, "discord.com/api/webhooks") then
		return false
	end
	local HttpService = game:GetService("HttpService")
	local payload = {
		["embeds"] = {
			{
				["title"] = title,
				["description"] = description,
				["color"] = 16711680, -- merah untuk debug
				["footer"] = {
					["text"] = "ServerHop Debug"
				},
				["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
			}
		}
	}
	local response = safeRequest({
		Url = webhookUrl,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = HttpService:JSONEncode(payload)
	})
	return response and (response.StatusCode == 200 or response.StatusCode == 204)
end
local function SendDiscordWebhook(customTitle, customDesc, forceSend)
	if not forceSend and (
        not Toggles.EnableWebhook or not Toggles.EnableWebhook.Value) then
		return false, "Webhook Disabled"
	end
	local webhookUrl = Options.WebhookLink and Options.WebhookLink.Value or ""
	if not webhookUrl or webhookUrl == "" or not string.find(
        webhookUrl, "discord.com/api/webhooks") then
		return false, "Invalid Webhook URL"
	end
	local HttpService = game:GetService("HttpService")
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
    --==================================================
    -- PLAYER INFO
    --==================================================
	local displayName = LocalPlayer.DisplayName
	local userId = LocalPlayer.UserId
	local serverId = game.JobId ~= "" and game.JobId or "Singleplayer"
	local profileUrl = "https://www.roblox.com/users/" .. userId .. "/profile"
    --==================================================
    -- READ CURRENT ATTRIBUTES
    --==================================================
	local attrs = LocalPlayer:GetAttributes()
	local KillerChance = tonumber(attrs.KillerChance) or 0
	local EXP = tonumber(attrs.EXP) or 0
	local Screws = tonumber(attrs.Screws) or 0
	local Gears = tonumber(attrs.Gears) or 0
	local Level = tonumber(attrs.Level) or 0
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
	local KillerChanceDelta = GetAttributeDelta(
            KillerChance, PreviousAttributes.KillerChance)
	local EXPDelta = GetAttributeDelta(
            EXP, PreviousAttributes.EXP)
	local ScrewsDelta = GetAttributeDelta(
            Screws, PreviousAttributes.Screws)
	local GearsDelta = GetAttributeDelta(
            Gears, PreviousAttributes.Gears)
    --==================================================
    -- PAYLOAD
    --==================================================
	local payload = {
		["embeds"] = {
			{
				["title"] = string.format("%s · Level %d", displayName, Level),
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
			}
		}
	}
    --==================================================
    -- SEND WEBHOOK
    --==================================================
	local response = safeRequest({
		Url = webhookUrl,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = HttpService:JSONEncode(
                    payload)
	})
    --==================================================
    -- SUCCESS
    --==================================================
	if response and (
        response.StatusCode == 200 or response.StatusCode == 204) then
        --==================================================
        -- ONLY UPDATE AFTER SUCCESS
        --==================================================
		local newSnapshot = {
			KillerChance = KillerChance,
			EXP = EXP,
			Screws = Screws,
			Gears = Gears
		}
		PreviousAttributes = newSnapshot
		SavePreviousAttributes(
            newSnapshot)
		return true, "Webhook successfully sent!"
	end
    --==================================================
    -- FAILED
    --==================================================
	local status = response and response.StatusCode or "No Response / Failed Request"
    -- Jangan update PreviousAttributes
    -- kalau webhook gagal.
	return false, "Failed Status: " .. tostring(status)
end
--==================================================
-- BEAT GAME SURVIVOR
--==================================================
local function BeatGameSurvivor()
    -- 1. Cek toggle
    if not Toggles.EnableAutoFarm.Value then
        BeatState.BeatSurvivorDone = false
        BeatState.LastFinishPos = nil
        return
    end

    -- 2. Role check + notifikasi
    local currentRole = GetRole()
    if BeatState.LastRole ~= currentRole then
        if currentRole == "Survivor" then
            NotifyAF("🟢 Survivor!", "Ready to farm.")
        end
        BeatState.LastRole = currentRole
    end
    if currentRole ~= "Survivor" then
        return
    end

    -- 3. Karakter & Map
    local root = GetCharacterRoot()
    if not root then
        NotifyAF("⏳ Waiting", "Character not loaded")
        return
    end
    local map = game:GetService("Workspace"):FindFirstChild("Map")
    if not map then
        NotifyAF("⚠️ No Map", "Waiting for map")
        return
    end

    -- 4. Deteksi finish (sama seperti sebelumnya)
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
                    if part then exitPos = part.Position break end
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

    -- 5. Jika finish tidak ditemukan
    if not exitPos then
        NotifyAF("⚠️ Finish Not Found", "Map unsupported")
        return
    end

    -- 6. Reset state jika map berubah
    if BeatState.LastFinishPos then
        if (exitPos - BeatState.LastFinishPos).Magnitude > 50 then
            BeatState.BeatSurvivorDone = false
        end
    end

    -- 7. Cegah teleport berulang di ronde yang sama
    if BeatState.BeatSurvivorDone then
        return
    end

    -- 8. Notifikasi finish ditemukan
    NotifyAF("📍 Finish Found", "Waiting 3s...")

    -- 9. Jeda 3 detik (bukan 6) agar lebih responsif
    task.wait(6)

    -- 10. Validasi ulang semua kondisi
    if not Toggles.EnableAutoFarm.Value then
        NotifyAF("⛔ Cancelled", "Toggle turned off")
        return
    end
    if GetRole() ~= "Survivor" then
        NotifyAF("⛔ Cancelled", "Not Survivor anymore")
        return
    end
    local currentRoot = GetCharacterRoot()
    if not currentRoot then
        NotifyAF("⛔ Cancelled", "Character missing")
        return
    end

    -- 11. Teleport!
    NotifyAF("🚀 Teleporting", "Moving to finish...")
    currentRoot.CFrame = CFrame.new(exitPos + Vector3.new(0, 0, 0))
    BeatState.BeatSurvivorDone = true
    BeatState.LastFinishPos = exitPos

    NotifyAF("✅ Teleport Success", "Round completed!")

    --==================================================
    -- FINISH -> SPECTATOR WATCHDOG
    --==================================================
    if not FinishWatchActive then
        FinishWatchActive = true

        task.spawn(function()
            local watchStart = os.clock()
            local WATCH_TIMEOUT = 10

            while os.clock() - watchStart < WATCH_TIMEOUT do
                if not Toggles.EnableAutoFarm.Value then
                    FinishWatchActive = false
                    return
                end

                local role = GetRole()

                if role == "Spectator" then
                    FinishWatchActive = false

                    NotifyAF(
                        "👁️ Match Completed",
                        "Role changed to Spectator."
                    )

                    return
                end

                task.wait(0.5)
            end

            local finalRole = GetRole()

            if finalRole == "Survivor" then
                NotifyAF(
                    "🔴 Match Stuck",
                    "Still Survivor after finish. Server hopping..."
                )

                pcall(function()
                    SendDebugWebhook(
                        "🔴 Match Stuck",
                        string.format(
                            "Player finished but role remained `%s` after %d seconds.\nCurrent Server: `%s`",
                            tostring(finalRole),
                            WATCH_TIMEOUT,
                            tostring(game.JobId)
                        )
                    )
                end)

                if Toggles.ServerHop
                    and Toggles.ServerHop.Value
                then
                    ForceServerHop = true
                end
            end

            FinishWatchActive = false
        end)
    end

    -- 12. Kirim webhook setelah 5 detik
    task.wait(5)
    SendDiscordWebhook()
end
--==================================================
-- SERVER HOP
-- EVENT-DRIVEN + JOBID FALLBACK + PERSISTENT IGNORE
-- + MATCH-STUCK RECOVERY
--==================================================

local IGNORE_FILE = "ServerHop.txt"

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--==================================================
-- SERVER HOP STATE
--==================================================

local IgnoredServers = {}

local TargetServerId = nil
local OriginalJobId = nil

local TeleportInProgress = false
local TeleportFailed = false

local LastTeleportError = ""
local LastTeleportResult = nil

local IsHopping = false

--==================================================
-- SERVER HOP CONFIG
--==================================================

local CANDIDATE_IGNORE_TIME = 180
local FAILED_SERVER_IGNORE_TIME = 600

local API_RETRY_DELAY = 3
local PAGE_DELAY = 0.5
local NO_SERVER_DELAY = 3

-- Event-driven is primary.
-- JobId is only used as a fallback safety check.
local TELEPORT_EVENT_WINDOW = 7

local TELEPORT_FAILURE_DELAY = 2.5

--==================================================
-- BLACKLIST FILE MANAGEMENT
--==================================================

local function GetIgnoredServers()
	if type(isfile) ~= "function"
		or type(readfile) ~= "function"
		or not isfile(IGNORE_FILE)
	then
		return {}
	end

	local success, content = pcall(readfile, IGNORE_FILE)

	if not success or type(content) ~= "string" then
		return {}
	end

	local now = os.time()
	local list = {}

	for _, line in ipairs(content:split("\n")) do
		local serverId, expiredAt =
			line:match("^([^|]+)|(%d+)$")

		expiredAt = tonumber(expiredAt)

		if serverId
			and serverId ~= ""
			and expiredAt
			and now < expiredAt
		then
			list[serverId] = expiredAt
		end
	end

	return list
end

local function UpdateIgnoredServers(list)
	if type(writefile) ~= "function" then
		return false
	end

	local now = os.time()
	local lines = {}

	for serverId, expiredAt in pairs(list) do
		if serverId
			and expiredAt
			and now < expiredAt
		then
			table.insert(
				lines,
				serverId .. "|" .. expiredAt
			)
		end
	end

	local success = pcall(function()
		writefile(
			IGNORE_FILE,
			table.concat(lines, "\n")
		)
	end)

	return success
end

local function AddIgnoredServer(serverId, duration)
	if not serverId then
		return
	end

	IgnoredServers[serverId] =
		os.time() + duration

	UpdateIgnoredServers(IgnoredServers)
end

local function IsServerIgnored(serverId)
	local expiredAt = IgnoredServers[serverId]

	if not expiredAt then
		return false
	end

	if os.time() >= expiredAt then
		IgnoredServers[serverId] = nil
		UpdateIgnoredServers(IgnoredServers)
		return false
	end

	return true
end

--==================================================
-- ROUND / SERVER HOP STATE
--==================================================

local IsRound = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local StatusUpdateEvent = Remotes:WaitForChild("StatusUpdateEvent")
local TimeUpdateEvent = Remotes:WaitForChild("TimeUpdateEvent")

--==================================================
-- STATUS DETECTOR
--==================================================

StatusUpdateEvent.OnClientEvent:Connect(function(Status)
	if Status == "WaitingForPlayers" then
		IsRound = false
		BeatState.BeatSurvivorDone = false

	elseif Status == "IntermissionStarting" then
		IsRound = false
		BeatState.BeatSurvivorDone = false

	elseif Status == "Intermission" then
		IsRound = false
		BeatState.BeatSurvivorDone = false
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
-- TELEPORT STATE MANAGEMENT
--==================================================

local function ResetTeleportState()
	TargetServerId = nil
	OriginalJobId = nil

	TeleportInProgress = false
	TeleportFailed = false

	LastTeleportError = ""
	LastTeleportResult = nil
end

local function BeginTeleport(serverId)
	TargetServerId = serverId
	OriginalJobId = game.JobId

	TeleportInProgress = true
	TeleportFailed = false

	LastTeleportError = ""
	LastTeleportResult = nil
end

local function RegisterTeleportFailure(teleportResult, errorMessage)
	if not TeleportInProgress then
		return false
	end

	TeleportFailed = true
	LastTeleportResult = teleportResult
	LastTeleportError = tostring(errorMessage)

	return true
end

--==================================================
-- NATIVE TELEPORT FAILURE EVENT
--==================================================

TeleportService.TeleportInitFailed:Connect(
	function(player, teleportResult, errorMessage)
		if player ~= LocalPlayer then
			return
		end

		if not TeleportInProgress then
			return
		end

		local targetId = TargetServerId

		if not RegisterTeleportFailure(
			teleportResult,
			errorMessage
		) then
			return
		end

		local resultText = tostring(teleportResult)
		local errorText = tostring(errorMessage)

		warn(
			string.format(
				"[ServerHop] TeleportInitFailed | Server: %s | Code: %s | Error: %s",
				tostring(targetId),
				resultText,
				errorText
			)
		)

		if targetId then
			-- Real teleport failure:
			-- keep the server out for longer.
			AddIgnoredServer(
				targetId,
				FAILED_SERVER_IGNORE_TIME
			)

			pcall(function()
				Library:Notify({
					Title = "❌ Teleport Failed   \n",
					Description = string.format(
						"Server %s gagal. Blacklist 10 menit.   ",
						targetId:sub(1, 8)
					),
					Time = 3
				})
			end)

			pcall(function()
				SendDebugWebhook(
					"🐛 Server Hop Error",
					string.format(
						"Server: `%s`\nCode: `%s`\nError: `%s`",
						targetId,
						resultText,
						errorText
					)
				)
			end)
		end
	end
)

--==================================================
-- TELEPORT REQUEST
--==================================================

local function TryTeleport(serverId)
	BeginTeleport(serverId)

	local success, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(
			game.PlaceId,
			serverId,
			LocalPlayer
		)
	end)

	-- Immediate/synchronous error while invoking teleport.
	if not success then
		TeleportInProgress = false

		LastTeleportError = tostring(err)

		AddIgnoredServer(
			serverId,
			FAILED_SERVER_IGNORE_TIME
		)

		warn(
			string.format(
				"[ServerHop] Teleport call failed | Server: %s | Error: %s",
				serverId,
				tostring(err)
			)
		)

		pcall(function()
			SendDebugWebhook(
				"🐛 Teleport Call Failed",
				string.format(
					"Server: `%s`\nError: `%s`",
					serverId,
					tostring(err)
				)
			)
		end)

		ResetTeleportState()

		return false
	end

	return true
end

--==================================================
-- WAIT FOR TELEPORT RESULT
--==================================================

local function WaitForTeleportResult()
	local startTime = os.clock()

	while TeleportInProgress
		and not TeleportFailed
		and os.clock() - startTime < TELEPORT_EVENT_WINDOW
	do
		-- Native TeleportInitFailed is the primary signal.
		-- JobId change is only a fallback success signal.
		if game.JobId ~= OriginalJobId then
			return "Success"
		end

		task.wait(0.1)
	end

	if TeleportFailed then
		return "Failed"
	end

	if game.JobId ~= OriginalJobId then
		return "Success"
	end

	-- No failure event and JobId did not change.
	-- Treat this candidate as a silent timeout so the loop
	-- does not remain stuck forever.
	return "Timeout"
end

--==================================================
-- MAIN SERVER HOP
--==================================================

ServerHop = function()
	if IsHopping then
		return
	end

	IsHopping = true

	IgnoredServers = GetIgnoredServers()
	ResetTeleportState()

	local cursor = ""
	local consecutiveApiFailures = 0

	while Toggles.ServerHop
		and Toggles.ServerHop.Value
		and not Library.Unloaded
	do
		--==================================================
		-- PERMISSION CHECK
		--==================================================

		local forcedThisCycle = ForceServerHop
		ForceServerHop = false

		if not forcedThisCycle and not CanServerHop() then
			ResetTeleportState()
			task.wait(0.5)
			continue
		end

		--==================================================
		-- REQUEST SERVER LIST
		--==================================================

		local url =
			"https://games.roblox.com/v1/games/"
			.. game.PlaceId
			.. "/servers/Public"
			.. "?limit=100"
			.. "&sortOrder=Asc"
			.. "&excludeFullGames=true"
			.. "&cursor="
			.. HttpService:UrlEncode(cursor)

		local success, result = pcall(function()
			return HttpService:JSONDecode(
				game:HttpGet(url)
			)
		end)

		--==================================================
		-- API FAILURE
		--==================================================

		if not success then
			consecutiveApiFailures += 1

			warn(
				"[ServerHop] API request failed:",
				tostring(result)
			)

			if consecutiveApiFailures >= 5 then
				pcall(function()
					SendDebugWebhook(
						"Server API failed repeatedly",
						string.format(
							"Failures: %d\nError: %s",
							consecutiveApiFailures,
							tostring(result)
						)
					)
				end)

				consecutiveApiFailures = 0
			end

			task.wait(API_RETRY_DELAY)
			continue
		end

		--==================================================
		-- INVALID API RESPONSE
		--==================================================

		if not result
			or type(result.data) ~= "table"
		then
			consecutiveApiFailures += 1

			warn(
				"[ServerHop] API returned invalid data."
			)

			if consecutiveApiFailures >= 5 then
				pcall(function()
					SendDebugWebhook(
						"Server API returned invalid data",
						tostring(result)
					)
				end)

				consecutiveApiFailures = 0
			end

			task.wait(API_RETRY_DELAY)
			continue
		end

		consecutiveApiFailures = 0

		local currentJobId = game.JobId
		local foundServer = false

		--==================================================
		-- SCAN CURRENT PAGE
		--==================================================

		for _, server in ipairs(result.data) do
			if not Toggles.ServerHop.Value
				or Library.Unloaded
			then
				break
			end

			if not forcedThisCycle and not CanServerHop() then
				break
			end

			-- Server target:
			-- 1-3 players, not current server, not ignored.
			local validServer =
				server
				and server.id
				and server.id ~= currentJobId
				and server.playing
				and server.playing >= 1
				and server.playing <= 3
				and not IsServerIgnored(server.id)

			if not validServer then
				continue
			end

			foundServer = true

			local serverId = server.id
			local playerCount = server.playing

			-- Temporarily reserve this candidate so it will
			-- not immediately get selected again.
			AddIgnoredServer(
				serverId,
				CANDIDATE_IGNORE_TIME
			)

			Library:Notify({
				Title = "📡 Teleporting   \n",
				Description = string.format(
					"%d player | Server %s   ",
					playerCount,
					serverId:sub(1, 8)
				),
				Time = 2
			})

			--==================================================
			-- START TELEPORT
			--==================================================

			task.wait(2)

			local teleportStarted =
				TryTeleport(serverId)

			if not teleportStarted then
				task.wait(
					TELEPORT_FAILURE_DELAY
				)

				continue
			end

			--==================================================
			-- WAIT FOR EVENT / JOBID FALLBACK
			--==================================================

			local teleportResult =
				WaitForTeleportResult()

			--==================================================
			-- SUCCESS
			--==================================================

			if teleportResult == "Success" then
				ResetTeleportState()
				IsHopping = false

				return
			end

			--==================================================
			-- NATIVE FAILURE
			--==================================================

			if teleportResult == "Failed" then
				-- TeleportInitFailed already added the server
				-- to the 10-minute blacklist.
				ResetTeleportState()

				task.wait(
					TELEPORT_FAILURE_DELAY
				)

				continue
			end

			--==================================================
			-- SILENT TIMEOUT
			--==================================================

			if teleportResult == "Timeout" then
				local failedServerId = TargetServerId

				warn(
					string.format(
						"[ServerHop] Teleport timeout | Server: %s",
						tostring(failedServerId)
					)
				)

				if failedServerId then
					AddIgnoredServer(
						failedServerId,
						FAILED_SERVER_IGNORE_TIME
					)

					pcall(function()
						SendDebugWebhook(
							"🐛 Teleport Timeout",
							string.format(
								"Server `%s` did not change JobId within %d seconds.",
								failedServerId,
								TELEPORT_EVENT_WINDOW
							)
						)
					end)
				end

				pcall(function()
					Library:Notify({
						Title = "⚠️ Teleport Timeout   \n",
						Description = string.format(
							"Server %s tidak berpindah. Mencoba server lain.   ",
							tostring(failedServerId):sub(1, 8)
						),
						Time = 2.5
					})
				end)

				ResetTeleportState()

				task.wait(
					TELEPORT_FAILURE_DELAY
				)

				continue
			end
		end

		--==================================================
		-- PAGINATION
		--==================================================

		if not foundServer then
			local nextCursor =
				result.nextPageCursor or ""

			if nextCursor ~= "" then
				cursor = nextCursor
				task.wait(PAGE_DELAY)
			else
				cursor = ""

				Library:Notify({
					Title = "⚠️ Server Hop   \n",
					Description = "Tidak ada server 1–3 player yang cocok.   ",
					Time = 2
				})

				task.wait(
					NO_SERVER_DELAY
				)
			end
		end
	end

	ResetTeleportState()
	IsHopping = false
end

--==================================================
-- AUTO SERVER HOP
--==================================================

AutoFarmGroup:AddToggle("ServerHop", {
	Text = "Server Hop",
	Tooltip = "Hop to 1-3 player servers when round is active",
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
-- AUTO FARM TOGGLE
--==================================================
AutoFarmGroup:AddToggle("EnableAutoFarm", {
	Text = "Enable Auto Farm",
	Tooltip = "Teleport Survivor to the detected finish location",
	Default = false,
})
--==================================================
-- AUTO EXECUTE
--==================================================
local LOADER_URL = "https://raw.githubusercontent.com/Rzor731/VD-AUTO-FARM/refs/heads/main/loader.lua"
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
	local queued = string.format([[loadstring(game:HttpGet(%q))()]], LOADER_URL)
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
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")
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
	Values = {
		"50%",
		"75%",
		"100%",
		"125%",
		"150%",
		"175%",
		"200%"
	},
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
