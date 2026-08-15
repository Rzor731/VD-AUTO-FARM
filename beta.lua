-- ================================================================
-- DESYNC + GHOST VISUAL - UI MOBILE FRIENDLY
-- Tanpa library eksternal, murni ScreenGui
-- ================================================================

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ================================================================
-- 1. KONFIGURASI
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
local ghostModel = nil
local isDesyncActive = false
local desyncConnection = nil
local isDragging = false
local dragStart = nil
local dragStartPos = nil

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
            clone:SetAttribute("OriginalPartName", part.Name)
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
end

local function updateGhostAppearance()
    if not ghostModel then return end
    local highlight = ghostModel:FindFirstChild("GhostHighlight")
    if highlight then
        highlight.FillColor = getColorByName(Config.DesyncGhostColor)
        highlight.FillTransparency = Config.DesyncGhostTransparency
        highlight.DepthMode = Config.DesyncGhostAlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    end
    for _, part in ipairs(ghostModel:GetChildren()) do
        if part:IsA("BasePart") then
            part.Color = getColorByName(Config.DesyncGhostColor)
        end
    end
end

-- ================================================================
-- 4. LOOP DESYNC
-- ================================================================
local function startDesyncLoop()
    if desyncConnection then
        desyncConnection:Disconnect()
        desyncConnection = nil
    end

    desyncConnection = RunService.Heartbeat:Connect(function(dt)
        if not Config.Desync then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then root.Anchored = false end
            if isDesyncActive then
                isDesyncActive = false
                destroyGhost()
                updateUI()
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
            updateUI()
            return
        end

        if not isDesyncActive then
            isDesyncActive = true
            root.Anchored = true
            if Config.EnableDesyncGhost then
                createGhost(char)
            end
            updateUI()
        end

        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            local speed = humanoid.WalkSpeed
            root.CFrame = root.CFrame + (moveDir * (speed * dt))
        end
    end)
end

-- ================================================================
-- 5. UI MOBILE-FRIENDLY
-- ================================================================

-- Buat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DesyncUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Background untuk UI (agar mudah dilihat)
local bg = Instance.new("Frame")
bg.Name = "Background"
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundTransparency = 0.85
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bg.Visible = false  -- Sembunyikan background, hanya tampilkan panel
bg.Parent = screenGui

-- Panel utama (dapat digeser)
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 220, 0, 380)
panel.Position = UDim2.new(0.5, -110, 0.5, -190)
panel.BackgroundColor3 = Color3.fromRGB(20, 22, 27)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.ZIndex = 10
panel.Parent = screenGui

-- Corner panel
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

-- Stroke panel
local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(45, 48, 58)
panelStroke.Transparency = 0.65
panelStroke.Parent = panel

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 8)
title.BackgroundTransparency = 1
title.Text = "⚡ Desync"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextScaled = true
title.ZIndex = 11
title.Parent = panel

-- ==== Toggle Desync (besar) ====
local desyncBtn = Instance.new("TextButton")
desyncBtn.Name = "DesyncBtn"
desyncBtn.Size = UDim2.new(1, -20, 0, 50)
desyncBtn.Position = UDim2.new(0, 10, 0, 44)
desyncBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
desyncBtn.BackgroundTransparency = 0.2
desyncBtn.Text = "🔴 Desync: OFF"
desyncBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
desyncBtn.Font = Enum.Font.GothamBold
desyncBtn.TextSize = 16
desyncBtn.TextScaled = true
desyncBtn.ZIndex = 12
desyncBtn.AutoButtonColor = false
desyncBtn.Parent = panel

local desyncCorner = Instance.new("UICorner")
desyncCorner.CornerRadius = UDim.new(0, 8)
desyncCorner.Parent = desyncBtn

local desyncStroke = Instance.new("UIStroke")
desyncStroke.Color = Color3.fromRGB(255, 60, 60)
desyncStroke.Transparency = 0.5
desyncStroke.Thickness = 1.5
desyncStroke.Parent = desyncBtn

-- ==== Toggle Ghost ====
local ghostBtn = Instance.new("TextButton")
ghostBtn.Name = "GhostBtn"
ghostBtn.Size = UDim2.new(0.48, -12, 0, 36)
ghostBtn.Position = UDim2.new(0, 10, 0, 102)
ghostBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
ghostBtn.BackgroundTransparency = 0.2
ghostBtn.Text = "👻 Ghost"
ghostBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
ghostBtn.Font = Enum.Font.GothamBold
ghostBtn.TextSize = 14
ghostBtn.TextScaled = true
ghostBtn.ZIndex = 12
ghostBtn.AutoButtonColor = false
ghostBtn.Parent = panel

local ghostCorner = Instance.new("UICorner")
ghostCorner.CornerRadius = UDim.new(0, 8)
ghostCorner.Parent = ghostBtn

local ghostStroke = Instance.new("UIStroke")
ghostStroke.Color = Color3.fromRGB(100, 100, 120)
ghostStroke.Transparency = 0.5
ghostStroke.Thickness = 1.2
ghostStroke.Parent = ghostBtn

-- ==== Toggle Always On Top ====
local alwaysOnTopBtn = Instance.new("TextButton")
alwaysOnTopBtn.Name = "AlwaysOnTopBtn"
alwaysOnTopBtn.Size = UDim2.new(0.48, -12, 0, 36)
alwaysOnTopBtn.Position = UDim2.new(0.52, 2, 0, 102)
alwaysOnTopBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
alwaysOnTopBtn.BackgroundTransparency = 0.2
alwaysOnTopBtn.Text = "🔝 Top"
alwaysOnTopBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
alwaysOnTopBtn.Font = Enum.Font.GothamBold
alwaysOnTopBtn.TextSize = 14
alwaysOnTopBtn.TextScaled = true
alwaysOnTopBtn.ZIndex = 12
alwaysOnTopBtn.AutoButtonColor = false
alwaysOnTopBtn.Parent = panel

local alwaysCorner = Instance.new("UICorner")
alwaysCorner.CornerRadius = UDim.new(0, 8)
alwaysCorner.Parent = alwaysOnTopBtn

local alwaysStroke = Instance.new("UIStroke")
alwaysStroke.Color = Color3.fromRGB(100, 100, 120)
alwaysStroke.Transparency = 0.5
alwaysStroke.Thickness = 1.2
alwaysStroke.Parent = alwaysOnTopBtn

-- ==== Slider Transparansi ====
local transLabel = Instance.new("TextLabel")
transLabel.Size = UDim2.new(1, -20, 0, 18)
transLabel.Position = UDim2.new(0, 10, 0, 146)
transLabel.BackgroundTransparency = 1
transLabel.Text = "Transparansi: 50%"
transLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
transLabel.Font = Enum.Font.GothamMedium
transLabel.TextSize = 12
transLabel.ZIndex = 11
transLabel.Parent = panel

local transSlider = Instance.new("Frame")
transSlider.Name = "TransSlider"
transSlider.Size = UDim2.new(1, -20, 0, 6)
transSlider.Position = UDim2.new(0, 10, 0, 168)
transSlider.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
transSlider.BackgroundTransparency = 0.5
transSlider.BorderSizePixel = 0
transSlider.ZIndex = 11
transSlider.Parent = panel

local transSliderCorner = Instance.new("UICorner")
transSliderCorner.CornerRadius = UDim.new(1, 0)
transSliderCorner.Parent = transSlider

local transFill = Instance.new("Frame")
transFill.Size = UDim2.new(0.5, 0, 1, 0)
transFill.BackgroundColor3 = Color3.fromRGB(255, 42, 109)
transFill.BorderSizePixel = 0
transFill.ZIndex = 12
transFill.Parent = transSlider

local transFillCorner = Instance.new("UICorner")
transFillCorner.CornerRadius = UDim.new(1, 0)
transFillCorner.Parent = transFill

local transThumb = Instance.new("Frame")
transThumb.Size = UDim2.new(0, 16, 0, 16)
transThumb.Position = UDim2.new(0.5, -8, 0.5, -8)
transThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
transThumb.BorderSizePixel = 0
transThumb.ZIndex = 13
transThumb.Parent = transSlider

local transThumbCorner = Instance.new("UICorner")
transThumbCorner.CornerRadius = UDim.new(1, 0)
transThumbCorner.Parent = transThumb

-- ==== Pilihan Warna (tombol warna) ====
local colorLabel = Instance.new("TextLabel")
colorLabel.Size = UDim2.new(1, -20, 0, 18)
colorLabel.Position = UDim2.new(0, 10, 0, 186)
colorLabel.BackgroundTransparency = 1
colorLabel.Text = "Warna: Accent"
colorLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
colorLabel.Font = Enum.Font.GothamMedium
colorLabel.TextSize = 12
colorLabel.ZIndex = 11
colorLabel.Parent = panel

local colorContainer = Instance.new("Frame")
colorContainer.Size = UDim2.new(1, -20, 0, 28)
colorContainer.Position = UDim2.new(0, 10, 0, 208)
colorContainer.BackgroundTransparency = 1
colorContainer.ZIndex = 11
colorContainer.Parent = panel

local colorButtons = {}
local colorNames = {"Accent", "Cyan", "Purple", "Green", "Red", "Yellow", "White"}
local colorValues = {
    Accent = Color3.fromRGB(255, 42, 109),
    Cyan = Color3.fromRGB(0, 255, 255),
    Purple = Color3.fromRGB(180, 50, 255),
    Green = Color3.fromRGB(0, 255, 120),
    Red = Color3.fromRGB(255, 60, 60),
    Yellow = Color3.fromRGB(255, 220, 0),
    White = Color3.fromRGB(255, 255, 255),
}

local function createColorButton(name, color, index)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 26, 0, 26)
    btn.Position = UDim2.new(index * 0.14, 0, 0, 0)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.ZIndex = 12
    btn.AutoButtonColor = false
    btn.Parent = colorContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.8
    stroke.Thickness = 1.2
    stroke.Parent = btn

    return btn
end

for i, name in ipairs(colorNames) do
    local color = colorValues[name]
    local btn = createColorButton(name, color, i-1)
    colorButtons[name] = btn
end

-- ==== Status label ====
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 248)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 11
statusLabel.ZIndex = 11
statusLabel.Parent = panel

-- ================================================================
-- 6. UPDATE UI
-- ================================================================
local function updateUI()
    -- Update desync button
    if Config.Desync then
        desyncBtn.Text = "🟢 Desync: ON"
        desyncBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 30)
        desyncStroke.Color = Color3.fromRGB(0, 255, 100)
        desyncStroke.Transparency = 0.3
    else
        desyncBtn.Text = "🔴 Desync: OFF"
        desyncBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
        desyncStroke.Color = Color3.fromRGB(255, 60, 60)
        desyncStroke.Transparency = 0.5
    end

    -- Update ghost button
    if Config.EnableDesyncGhost then
        ghostBtn.Text = "👻 Ghost: ON"
        ghostBtn.TextColor3 = Color3.fromRGB(100, 255, 200)
        ghostStroke.Color = Color3.fromRGB(100, 255, 200)
        ghostStroke.Transparency = 0.3
    else
        ghostBtn.Text = "👻 Ghost: OFF"
        ghostBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        ghostStroke.Color = Color3.fromRGB(100, 100, 120)
        ghostStroke.Transparency = 0.5
    end

    -- Update always on top
    if Config.DesyncGhostAlwaysOnTop then
        alwaysOnTopBtn.Text = "🔝 Top: ON"
        alwaysOnTopBtn.TextColor3 = Color3.fromRGB(100, 255, 200)
        alwaysStroke.Color = Color3.fromRGB(100, 255, 200)
        alwaysStroke.Transparency = 0.3
    else
        alwaysOnTopBtn.Text = "🔝 Top: OFF"
        alwaysOnTopBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        alwaysStroke.Color = Color3.fromRGB(100, 100, 120)
        alwaysStroke.Transparency = 0.5
    end

    -- Update slider
    local transPercent = Config.DesyncGhostTransparency * 100
    transLabel.Text = "Transparansi: " .. math.round(transPercent) .. "%"
    transFill.Size = UDim2.new(Config.DesyncGhostTransparency, 0, 1, 0)
    transThumb.Position = UDim2.new(Config.DesyncGhostTransparency, -8, 0.5, -8)

    -- Update warna yang dipilih
    for name, btn in pairs(colorButtons) do
        local isActive = (name == Config.DesyncGhostColor)
        btn.BackgroundTransparency = isActive and 0.1 or 0.5
        local stroke = btn:FindFirstChildWhichIsA("UIStroke")
        if stroke then
            stroke.Transparency = isActive and 0.2 or 0.8
            stroke.Thickness = isActive and 2.5 or 1.2
        end
    end

    -- Update color label
    colorLabel.Text = "Warna: " .. Config.DesyncGhostColor

    -- Update status
    if Config.Desync and isDesyncActive then
        statusLabel.Text = "Status: ⚡ Desync ACTIVE"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    elseif Config.Desync then
        statusLabel.Text = "Status: ⏳ Waiting for character..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    else
        statusLabel.Text = "Status: Idle"
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    end
end

-- ================================================================
-- 7. EVENT HANDLING UI
-- ================================================================

-- Desync toggle
desyncBtn.MouseButton1Click:Connect(function()
    Config.Desync = not Config.Desync
    if not Config.Desync then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored = false end
        isDesyncActive = false
        destroyGhost()
    end
    updateUI()
end)

-- Ghost toggle
ghostBtn.MouseButton1Click:Connect(function()
    Config.EnableDesyncGhost = not Config.EnableDesyncGhost
    if not Config.EnableDesyncGhost then
        destroyGhost()
    elseif Config.Desync and isDesyncActive then
        local char = LocalPlayer.Character
        if char then createGhost(char) end
    end
    updateUI()
end)

-- Always On Top toggle
alwaysOnTopBtn.MouseButton1Click:Connect(function()
    Config.DesyncGhostAlwaysOnTop = not Config.DesyncGhostAlwaysOnTop
    updateGhostAppearance()
    updateUI()
end)

-- Color buttons
for name, btn in pairs(colorButtons) do
    btn.MouseButton1Click:Connect(function()
        Config.DesyncGhostColor = name
        updateGhostAppearance()
        updateUI()
    end)
end

-- Slider drag (mobile friendly)
local isDraggingSlider = false

transSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingSlider = true
        local pos = input.Position.X - transSlider.AbsolutePosition.X
        local width = transSlider.AbsoluteSize.X
        local value = math.clamp(pos / width, 0, 1)
        Config.DesyncGhostTransparency = value
        updateGhostAppearance()
        updateUI()
    end
end)

transSlider.InputChanged:Connect(function(input)
    if isDraggingSlider and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local pos = input.Position.X - transSlider.AbsolutePosition.X
        local width = transSlider.AbsoluteSize.X
        local value = math.clamp(pos / width, 0, 1)
        Config.DesyncGhostTransparency = value
        updateGhostAppearance()
        updateUI()
    end
end)

transSlider.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingSlider = false
    end
end)

-- ================================================================
-- 8. DRAG PANEL (Mobile Friendly)
-- ================================================================
local function makeDraggable(frame)
    local dragToggle = false
    local dragStartPos = nil
    local startPos = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = true
            dragStartPos = input.Position
            startPos = frame.Position
        end
    end)

    frame.InputChanged:Connect(function(input)
        if dragToggle and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStartPos
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = false
        end
    end)
end

makeDraggable(panel)

-- ================================================================
-- 9. START DESYNC LOOP
-- ================================================================
startDesyncLoop()

-- Update UI saat startup
task.wait(0.1)
updateUI()

-- ================================================================
-- 10. CLEANUP
-- ================================================================
local function cleanup()
    if desyncConnection then
        desyncConnection:Disconnect()
        desyncConnection = nil
    end
    destroyGhost()
    pcall(function() screenGui:Destroy() end)
end

-- Cleanup saat karakter mati / respawn
LocalPlayer.CharacterAdded:Connect(function()
    -- Reset state
    isDesyncActive = false
    destroyGhost()
    if Config.Desync then
        -- Jika desync aktif, tunggu karakter spawn lalu lanjutkan
        task.wait(0.5)
        -- Tidak otomatis re-activate, biar user toggle ulang
        -- Tapi kita update UI status
        updateUI()
    end
end)

-- Cleanup saat player leave / script dihentikan
game:GetService("Players").LocalPlayer:GetPropertyChangedSignal("Parent"):Connect(function()
    if not LocalPlayer.Parent then
        cleanup()
    end
end)

print("[Desync] UI Mobile Friendly loaded! Toggle Desync to start.")
