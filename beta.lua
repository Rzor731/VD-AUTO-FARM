-- ================================================================
-- NETWORK DESYNC + GHOST VISUAL
-- Berdasarkan script 6locc (Violence District)
-- ================================================================

-- Load ModernV2 (pastikan URL benar)
local ModernV2 = loadstring(game:HttpGet("https://raw.githubusercontent.com/nhfudzfsrzggt/brigida/main/zilux.lua"))()

-- Service references
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ================================================================
-- 1. KONFIGURASI DEFAULT
-- ================================================================
local Config = {
    Desync = false,
    EnableDesyncGhost = true,
    DesyncGhostAlwaysOnTop = true,
    DesyncGhostTransparency = 0.5,
    DesyncGhostColor = "Accent",  -- "Accent", "Cyan", "Purple", "Green", "Red", "Yellow", "White"
}

-- ================================================================
-- 2. VARIABEL INTERNAL
-- ================================================================
local ghostModel = nil          -- Model ghost (duplikat karakter)
local isDesyncActive = false    -- Status desync
local lastGhostCFrame = nil     -- Posisi terakhir untuk ghost

-- ================================================================
-- 3. FUNGSI GHOST VISUAL
-- ================================================================
local function destroyGhost()
    if ghostModel then
        pcall(function() ghostModel:Destroy() end)
        ghostModel = nil
    end
end

local function getColorByName(name)
    local colors = {
        Accent = Color3.fromRGB(255, 42, 109),
        Cyan = Color3.fromRGB(0, 255, 255),
        Purple = Color3.fromRGB(180, 50, 255),
        Green = Color3.fromRGB(0, 255, 120),
        Red = Color3.fromRGB(255, 60, 60),
        Yellow = Color3.fromRGB(255, 220, 0),
        White = Color3.fromRGB(255, 255, 255),
    }
    return colors[name] or colors.Accent
end

local function createGhost(character)
    destroyGhost()
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local ghost = Instance.new("Model")
    ghost.Name = "DesyncGhost"
    ghost.Parent = workspace

    -- Duplikat semua BasePart (kecuali HumanoidRootPart)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local clone = part:Clone()
            clone.Anchored = true
            clone.CanCollide = false
            clone.CastShadow = false
            clone.Transparency = 0.99
            clone.Color = getColorByName(Config.DesyncGhostColor)
            clone.Material = Enum.Material.SmoothPlastic
            clone.Parent = ghost
        end
    end

    -- Highlight untuk ghost
    local highlight = Instance.new("Highlight")
    highlight.Name = "GhostHighlight"
    highlight.FillColor = getColorByName(Config.DesyncGhostColor)
    highlight.FillTransparency = Config.DesyncGhostTransparency
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Config.DesyncGhostAlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    highlight.Adornee = ghost
    highlight.Enabled = true
    highlight.Parent = ghost

    -- Posisi ghost = posisi karakter saat desync diaktifkan
    for _, part in ipairs(ghost:GetChildren()) do
        if part:IsA("BasePart") then
            local origName = part:GetAttribute("OriginalPartName")
            if origName then
                local origPart = character:FindFirstChild(origName, true)
                if origPart then
                    part.CFrame = root.CFrame:ToObjectSpace(origPart.CFrame)
                end
            end
        end
    end

    ghostModel = ghost
    lastGhostCFrame = root.CFrame
end

local function updateGhostPosition(character)
    if not ghostModel or not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Update posisi ghost mengikuti root (jika desync aktif, posisi ghost tetap di posisi awal? Di 6locc ghost tetap diam)
    -- Tapi untuk efek yang lebih realistis, kita bisa update ghost sesuai posisi root sebenarnya.
    -- Di script 6locc, ghost tidak di-update posisinya, hanya dibuat sekali saat desync aktif.
    -- Kita akan biarkan ghost diam di posisi awal.
end

-- ================================================================
-- 4. LOOP DESYNC (Heartbeat)
-- ================================================================
local function startDesyncLoop()
    local connection = RunService.Heartbeat:Connect(function(dt)
        if not Config.Desync then
            -- Jika desync dimatikan, lepas anchor dan hapus ghost
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then root.Anchored = false end
            if isDesyncActive then
                isDesyncActive = false
                destroyGhost()
            end
            return
        end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then
            if root then root.Anchored = false end
            isDesyncActive = false
            destroyGhost()
            return
        end

        -- Aktifkan desync
        if not isDesyncActive then
            isDesyncActive = true
            root.Anchored = true
            -- Buat ghost saat pertama kali desync aktif
            if Config.EnableDesyncGhost then
                createGhost(char)
            end
        end

        -- Gerakkan root sesuai arah gerakan (MoveDirection)
        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            local speed = humanoid.WalkSpeed
            root.CFrame = root.CFrame + (moveDir * (speed * dt))
        end

        -- Update ghost position (jika ada)
        if ghostModel then
            -- Di sini kita biarkan ghost diam di posisi awal (tidak diupdate)
            -- Agar terlihat seperti posisi asli karakter sebelum desync
        end
    end)

    return connection
end

-- ================================================================
-- 5. BUAT UI MENGGUNAKAN MODERNV2
-- ================================================================
local Window = ModernV2:CreateWindow({
    Name = "Network Desync",
    Content = "v1.0 – Ghost Visual",
    Icon = "lucide:network",
    Size = ModernV2.Scales.Default,
})

-- Tab utama
local Tab = Window:AddTab({ Name = "Desync", Icon = "lucide:zap" })

-- Section kiri
local LeftGroup = Tab:AddSection({
    Name = "Desync Settings",
    Position = "Left",
    Icon = "lucide:settings",
    Box = true,
})

-- Toggle Desync
LeftGroup:AddToggle({
    Name = "Enable Desync",
    Flag = "DesyncToggle",
    Default = false,
    Callback = function(value)
        Config.Desync = value
        if not value then
            -- Nonaktifkan anchor dan ghost
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then root.Anchored = false end
            isDesyncActive = false
            destroyGhost()
        end
    end,
})

-- Toggle Ghost Visual
LeftGroup:AddToggle({
    Name = "Show Ghost",
    Flag = "GhostToggle",
    Default = true,
    Callback = function(value)
        Config.EnableDesyncGhost = value
        if not value then
            destroyGhost()
        elseif Config.Desync and isDesyncActive then
            -- Buat ulang ghost jika desync aktif
            local char = LocalPlayer.Character
            if char then createGhost(char) end
        end
    end,
})

-- Warna Ghost (Dropdown)
LeftGroup:AddDropdown({
    Name = "Ghost Color",
    Flag = "GhostColor",
    Values = {"Accent", "Cyan", "Purple", "Green", "Red", "Yellow", "White"},
    Default = "Accent",
    Callback = function(value)
        Config.DesyncGhostColor = value
        -- Update warna ghost jika ada
        if ghostModel then
            local highlight = ghostModel:FindFirstChild("GhostHighlight")
            if highlight then
                highlight.FillColor = getColorByName(value)
            end
            for _, part in ipairs(ghostModel:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Color = getColorByName(value)
                end
            end
        end
    end,
})

-- Transparansi Ghost (Slider)
LeftGroup:AddSlider({
    Name = "Ghost Transparency",
    Flag = "GhostTransparency",
    Default = 50,
    Min = 0,
    Max = 100,
    Type = "%",
    Callback = function(value)
        Config.DesyncGhostTransparency = value / 100
        if ghostModel then
            local highlight = ghostModel:FindFirstChild("GhostHighlight")
            if highlight then
                highlight.FillTransparency = value / 100
            end
        end
    end,
})

-- Toggle Always On Top
LeftGroup:AddToggle({
    Name = "Ghost Always On Top",
    Flag = "GhostAlwaysOnTop",
    Default = true,
    Callback = function(value)
        Config.DesyncGhostAlwaysOnTop = value
        if ghostModel then
            local highlight = ghostModel:FindFirstChild("GhostHighlight")
            if highlight then
                highlight.DepthMode = value and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            end
        end
    end,
})

-- Keybind untuk toggle Desync (opsional)
LeftGroup:AddLabel({ Text = "Keybind" })
LeftGroup:AddKeybind({
    Name = "Toggle Desync",
    Flag = "DesyncKeybind",
    Default = "None",
    Mode = "Toggle",
    Callback = function(state)
        if state then
            -- Toggle desync
            local toggle = ModernV2.Flags.DesyncToggle
            if toggle and toggle.Toggle then
                toggle:Toggle()
            end
        end
    end,
})

-- ================================================================
-- 6. JALANKAN DESYNC LOOP
-- ================================================================
local desyncConnection = startDesyncLoop()

-- Cleanup saat window di-destroy
Window.OnDestroy(function()
    if desyncConnection then
        desyncConnection:Disconnect()
    end
    destroyGhost()
end)

-- ================================================================
-- 7. TAMPILKAN WINDOW
-- ================================================================
Window.Signal:SetValue(true)

print("[Desync] Script loaded. Toggle 'Enable Desync' to start.")
