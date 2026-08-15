-- ============================================================
-- DESYNC + GHOST VISUAL (Standalone, tanpa library)
-- Berdasarkan 6locc violence district
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Konfigurasi
local Config = {
    Desync = false,
    ShowGhost = true,
    GhostColor = Color3.fromRGB(255, 42, 109), -- accent
    GhostTransparency = 0.5,
    GhostAlwaysOnTop = true,
}

-- Variabel
local ghostModel = nil
local isDesyncActive = false
local desyncConnection = nil
local ghostCreated = false

-- ============================================================
-- FUNGSI GHOST
-- ============================================================
local function destroyGhost()
    if ghostModel then
        pcall(function() ghostModel:Destroy() end)
        ghostModel = nil
    end
    ghostCreated = false
end

local function createGhost(character)
    destroyGhost()
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local ghost = Instance.new("Model")
    ghost.Name = "DesyncGhost"
    ghost.Parent = workspace

    -- Clone parts
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local clone = part:Clone()
            clone.Anchored = true
            clone.CanCollide = false
            clone.CastShadow = false
            clone.Transparency = 0.99
            clone.Color = Config.GhostColor
            clone.Material = Enum.Material.SmoothPlastic
            clone.Parent = ghost
        end
    end

    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "GhostHighlight"
    highlight.FillColor = Config.GhostColor
    highlight.FillTransparency = Config.GhostTransparency
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Config.GhostAlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    highlight.Adornee = ghost
    highlight.Enabled = true
    highlight.Parent = ghost

    ghostModel = ghost
    ghostCreated = true
end

-- ============================================================
-- DESYNC LOOP
-- ============================================================
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

        if not isDesyncActive then
            isDesyncActive = true
            root.Anchored = true
            if Config.ShowGhost then
                createGhost(char)
            end
        end

        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            local speed = humanoid.WalkSpeed
            root.CFrame = root.CFrame + (moveDir * (speed * dt))
        end
    end)
end

-- ============================================================
-- UI SEDERHANA
-- ============================================================
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DesyncUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 260, 0, 250)
    mainFrame.Position = UDim2.new(0.5, -130, 0.5, -125)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20,22,27)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(45,48,58)

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.Position = UDim2.new(0,0,0,5)
    title.BackgroundTransparency = 1
    title.Text = "Desync / Ghost"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = mainFrame

    -- Toggle Desync
    local desyncBtn = Instance.new("TextButton")
    desyncBtn.Size = UDim2.new(0,120,0,30)
    desyncBtn.Position = UDim2.new(0,10,0,45)
    desyncBtn.BackgroundColor3 = Color3.fromRGB(30,32,40)
    desyncBtn.Text = "Desync OFF"
    desyncBtn.TextColor3 = Color3.fromRGB(200,200,200)
    desyncBtn.Font = Enum.Font.GothamBold
    desyncBtn.TextSize = 13
    desyncBtn.Parent = mainFrame
    Instance.new("UICorner", desyncBtn).CornerRadius = UDim.new(0,5)

    -- Toggle Ghost
    local ghostBtn = Instance.new("TextButton")
    ghostBtn.Size = UDim2.new(0,120,0,30)
    ghostBtn.Position = UDim2.new(0,130,0,45)
    ghostBtn.BackgroundColor3 = Color3.fromRGB(30,32,40)
    ghostBtn.Text = "Ghost ON"
    ghostBtn.TextColor3 = Color3.fromRGB(200,200,200)
    ghostBtn.Font = Enum.Font.GothamBold
    ghostBtn.TextSize = 13
    ghostBtn.Parent = mainFrame
    Instance.new("UICorner", ghostBtn).CornerRadius = UDim.new(0,5)

    -- Slider Transparency
    local transLabel = Instance.new("TextLabel")
    transLabel.Size = UDim2.new(0.5,0,0,20)
    transLabel.Position = UDim2.new(0,10,0,90)
    transLabel.BackgroundTransparency = 1
    transLabel.Text = "Ghost Alpha: 50%"
    transLabel.TextColor3 = Color3.fromRGB(200,200,200)
    transLabel.Font = Enum.Font.Gotham
    transLabel.TextSize = 12
    transLabel.Parent = mainFrame

    local transSlider = Instance.new("TextButton")
    transSlider.Size = UDim2.new(0,100,0,8)
    transSlider.Position = UDim2.new(0.5,-10,0,95)
    transSlider.BackgroundColor3 = Color3.fromRGB(50,55,70)
    transSlider.Text = ""
    transSlider.Parent = mainFrame
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0.5,0,1,0)
    fill.BackgroundColor3 = Config.GhostColor
    fill.BorderSizePixel = 0
    fill.Parent = transSlider
    Instance.new("UICorner", transSlider).CornerRadius = UDim.new(1,0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    -- Always on top toggle
    local topBtn = Instance.new("TextButton")
    topBtn.Size = UDim2.new(0,120,0,25)
    topBtn.Position = UDim2.new(0,10,0,120)
    topBtn.BackgroundColor3 = Color3.fromRGB(30,32,40)
    topBtn.Text = "Always On Top"
    topBtn.TextColor3 = Color3.fromRGB(200,200,200)
    topBtn.Font = Enum.Font.GothamBold
    topBtn.TextSize = 12
    topBtn.Parent = mainFrame
    Instance.new("UICorner", topBtn).CornerRadius = UDim.new(0,5)

    -- Color buttons (simple)
    local colors = {
        {name="Accent", color=Color3.fromRGB(255,42,109)},
        {name="Cyan", color=Color3.fromRGB(0,255,255)},
        {name="Purple", color=Color3.fromRGB(180,50,255)},
        {name="Green", color=Color3.fromRGB(0,255,120)},
        {name="Red", color=Color3.fromRGB(255,60,60)},
        {name="Yellow", color=Color3.fromRGB(255,220,0)},
    }
    for i, c in ipairs(colors) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0,28,0,20)
        btn.Position = UDim2.new(0, 10 + (i-1)*35, 0, 160)
        btn.BackgroundColor3 = c.color
        btn.Text = ""
        btn.Parent = mainFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
        btn.MouseButton1Click:Connect(function()
            Config.GhostColor = c.color
            if ghostModel then
                local hl = ghostModel:FindFirstChild("GhostHighlight")
                if hl then hl.FillColor = c.color end
                for _, p in ipairs(ghostModel:GetChildren()) do
                    if p:IsA("BasePart") then p.Color = c.color end
                end
            end
            fill.BackgroundColor3 = c.color
        end)
    end

    -- Keybind info
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(1,0,0,20)
    keyLabel.Position = UDim2.new(0,0,0,195)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = "Press K to toggle Desync"
    keyLabel.TextColor3 = Color3.fromRGB(150,150,170)
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextSize = 11
    keyLabel.Parent = mainFrame

    -- ============================================================
    -- UI LOGIC
    -- ============================================================
    local function updateDesyncBtn()
        desyncBtn.Text = Config.Desync and "Desync ON" or "Desync OFF"
        desyncBtn.BackgroundColor3 = Config.Desync and Color3.fromRGB(0,180,80) or Color3.fromRGB(60,40,40)
    end
    local function updateGhostBtn()
        ghostBtn.Text = Config.ShowGhost and "Ghost ON" or "Ghost OFF"
        ghostBtn.BackgroundColor3 = Config.ShowGhost and Color3.fromRGB(0,120,200) or Color3.fromRGB(40,40,60)
    end
    local function updateTopBtn()
        topBtn.BackgroundColor3 = Config.GhostAlwaysOnTop and Color3.fromRGB(0,120,200) or Color3.fromRGB(30,32,40)
    end

    desyncBtn.MouseButton1Click:Connect(function()
        Config.Desync = not Config.Desync
        updateDesyncBtn()
        if not Config.Desync then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then root.Anchored = false end
            isDesyncActive = false
            destroyGhost()
        else
            startDesyncLoop()
        end
    end)

    ghostBtn.MouseButton1Click:Connect(function()
        Config.ShowGhost = not Config.ShowGhost
        updateGhostBtn()
        if not Config.ShowGhost then
            destroyGhost()
        elseif Config.Desync and isDesyncActive then
            local char = LocalPlayer.Character
            if char then createGhost(char) end
        end
    end)

    topBtn.MouseButton1Click:Connect(function()
        Config.GhostAlwaysOnTop = not Config.GhostAlwaysOnTop
        updateTopBtn()
        if ghostModel then
            local hl = ghostModel:FindFirstChild("GhostHighlight")
            if hl then
                hl.DepthMode = Config.GhostAlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            end
        end
    end)

    -- Slider logic (drag)
    local dragging = false
    transSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    transSlider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = input.Position.X - transSlider.AbsolutePosition.X
            local w = transSlider.AbsoluteSize.X
            local pct = math.clamp(pos / w, 0, 1)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            transLabel.Text = "Ghost Alpha: " .. math.round(pct * 100) .. "%"
            Config.GhostTransparency = 1 - pct
            if ghostModel then
                local hl = ghostModel:FindFirstChild("GhostHighlight")
                if hl then hl.FillTransparency = Config.GhostTransparency end
            end
        end
    end)

    -- Keybind K
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.K then
            desyncBtn.MouseButton1Click:Fire()
        end
    end)

    updateDesyncBtn()
    updateGhostBtn()
    updateTopBtn()

    return screenGui
end

-- ============================================================
-- INIT
-- ============================================================
local ui = createUI()
startDesyncLoop()

-- Cleanup on exit
game:BindToClose(function()
    if desyncConnection then desyncConnection:Disconnect() end
    destroyGhost()
    if ui then ui:Destroy() end
end)

print("[Desync] Standalone UI ready. Press K to toggle.")
