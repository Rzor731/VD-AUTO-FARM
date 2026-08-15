-- ================================================================
-- NETWORK DESYNC + GHOST VISUAL (UI Custom, Tanpa Library)
-- Berdasarkan script 6locc
-- ================================================================

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
    EnableGhost = true,
    GhostAlwaysOnTop = true,
    GhostTransparency = 0.5,
    GhostColor = "Accent",  -- Accent, Cyan, Purple, Green, Red, Yellow, White
    Keybind = "None",
}

local COLORS = {
    Accent = Color3.fromRGB(255, 42, 109),
    Cyan = Color3.fromRGB(0, 255, 255),
    Purple = Color3.fromRGB(180, 50, 255),
    Green = Color3.fromRGB(0, 255, 120),
    Red = Color3.fromRGB(255, 60, 60),
    Yellow = Color3.fromRGB(255, 220, 0),
    White = Color3.fromRGB(255, 255, 255),
}

-- ================================================================
-- 2. VARIABEL INTERNAL
-- ================================================================
local ghostModel = nil
local isDesyncActive = false
local desyncConnection = nil
local isBindingKey = false

-- ================================================================
-- 3. FUNGSI GHOST
-- ================================================================
local function destroyGhost()
    if ghostModel then
        pcall(function() ghostModel:Destroy() end)
        ghostModel = nil
    end
end

local function getColor(name)
    return COLORS[name] or COLORS.Accent
end

local function createGhost(character)
    destroyGhost()
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local ghost = Instance.new("Model")
    ghost.Name = "DesyncGhost"
    ghost.Parent = workspace

    -- Duplikat semua part selain HumanoidRootPart
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local clone = part:Clone()
            clone.Anchored = true
            clone.CanCollide = false
            clone.CastShadow = false
            clone.Transparency = 0.99
            clone.Color = getColor(Config.GhostColor)
            clone.Material = Enum.Material.SmoothPlastic
            clone:SetAttribute("OriginalPartName", part.Name)
            clone.Parent = ghost
        end
    end

    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "GhostHighlight"
    highlight.FillColor = getColor(Config.GhostColor)
    highlight.FillTransparency = Config.GhostTransparency
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Config.GhostAlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
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
            if Config.EnableGhost then
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

-- ================================================================
-- 5. BUAT UI
-- ================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DesyncUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 380)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -190)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainFrame.BackgroundTransparency = 0.08
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Corner
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Stroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(45, 48, 58)
stroke.Transparency = 0.65
stroke.Parent = mainFrame

-- Title bar (drag)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ Desync"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0.5, -12)
closeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    destroyGhost()
    if desyncConnection then desyncConnection:Disconnect() end
end)

-- Drag functionality
local dragToggle = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragToggle = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragToggle = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- === Scrolling Frame untuk konten ===
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -30)
scroll.Position = UDim2.new(0, 0, 0, 30)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.Parent = scroll

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
end)

-- === Helper untuk membuat toggle ===
local function createToggle(parent, labelText, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 40, 0, 20)
    switch.Position = UDim2.new(1, -40, 0.5, -10)
    switch.BackgroundColor3 = default and Color3.fromRGB(255, 42, 109) or Color3.fromRGB(40, 40, 50)
    switch.BackgroundTransparency = 0.2
    switch.BorderSizePixel = 0
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.Parent = frame

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = default and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.Parent = switch

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent = thumb

    local state = default

    local function setState(val)
        state = val
        local targetBg = val and Color3.fromRGB(255, 42, 109) or Color3.fromRGB(40, 40, 50)
        local targetPos = val and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7)
        TweenService:Create(switch, TweenInfo.new(0.12), {BackgroundColor3 = targetBg}):Play()
        TweenService:Create(thumb, TweenInfo.new(0.12), {Position = targetPos}):Play()
        if callback then callback(val) end
    end

    switch.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    return { setValue = setState, getValue = function() return state end }
end

-- === Helper dropdown sederhana ===
local function createDropdown(parent, labelText, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.55, 0, 1, 0)
    btn.Position = UDim2.new(0.45, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.BackgroundTransparency = 0.5
    btn.BorderSizePixel = 0
    btn.Text = default
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    local dropdownList = Instance.new("Frame")
    dropdownList.Size = UDim2.new(0.55, 0, 0, 0)
    dropdownList.Position = UDim2.new(0.45, 0, 1, 2)
    dropdownList.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    dropdownList.BorderSizePixel = 0
    dropdownList.ClipsDescendants = true
    dropdownList.Visible = false
    dropdownList.ZIndex = 10
    dropdownList.Parent = frame

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 4)
    listCorner.Parent = dropdownList

    local listStroke = Instance.new("UIStroke")
    listStroke.Color = Color3.fromRGB(45, 48, 58)
    listStroke.Transparency = 0.65
    listStroke.Parent = dropdownList

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = dropdownList

    local selected = default
    local btnList = {}

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 24)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = opt
        optBtn.TextColor3 = (opt == default) and Color3.fromRGB(255, 42, 109) or Color3.fromRGB(180, 180, 190)
        optBtn.Font = Enum.Font.GothamMedium
        optBtn.TextSize = 12
        optBtn.AutoButtonColor = false
        optBtn.Parent = dropdownList

        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            btn.Text = opt
            for _, b in ipairs(btnList) do
                b.TextColor3 = (b == optBtn) and Color3.fromRGB(255, 42, 109) or Color3.fromRGB(180, 180, 190)
            end
            dropdownList.Visible = false
            if callback then callback(opt) end
        end)

        table.insert(btnList, optBtn)
    end

    btn.MouseButton1Click:Connect(function()
        dropdownList.Visible = not dropdownList.Visible
        if dropdownList.Visible then
            local h = #options * 26 + 4
            dropdownList.Size = UDim2.new(0.55, 0, 0, math.min(h, 120))
        end
    end)

    -- Tutup dropdown jika klik di luar
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            local absPos = dropdownList.AbsolutePosition
            local absSize = dropdownList.AbsoluteSize
            if dropdownList.Visible then
                if not (mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
                        mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y) then
                    dropdownList.Visible = false
                end
            end
        end
    end)

    return { getValue = function() return selected end, setValue = function(v) selected = v btn.Text = v end }
end

-- === Helper slider ===
local function createSlider(parent, labelText, minVal, maxVal, default, suffix, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 18)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.4, 0, 0, 18)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default) .. (suffix or "")
    valueLabel.TextColor3 = Color3.fromRGB(255, 42, 109)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 4)
    track.Position = UDim2.new(0, 0, 0, 24)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    track.BorderSizePixel = 0
    track.Parent = frame

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    local ratio = (default - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(ratio, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 42, 109)
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local thumb = Instance.new("TextButton")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = UDim2.new(ratio, -7, 0.5, -7)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.Text = ""
    thumb.AutoButtonColor = false
    thumb.Parent = track

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent = thumb

    local currentVal = default
    local isDragging = false

    local function updateSlider(input)
        local trackAbsPos = track.AbsolutePosition.X
        local trackWidth = track.AbsoluteSize.X
        if trackWidth <= 0 then return end
        local relX = math.clamp((input.Position.X - trackAbsPos) / trackWidth, 0, 1)
        currentVal = minVal + relX * (maxVal - minVal)
        currentVal = math.round(currentVal * 100) / 100
        fill.Size = UDim2.new(relX, 0, 1, 0)
        thumb.Position = UDim2.new(relX, -7, 0.5, -7)
        valueLabel.Text = tostring(currentVal) .. (suffix or "")
        if callback then callback(currentVal) end
    end

    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            updateSlider(input)
        end
    end)

    thumb.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement) then
            updateSlider(input)
        end
    end)

    return { getValue = function() return currentVal end, setValue = function(v) currentVal = v; local r = (v - minVal)/(maxVal-minVal); fill.Size = UDim2.new(r,0,1,0); thumb.Position = UDim2.new(r,-7,0.5,-7); valueLabel.Text = tostring(v)..(suffix or "") end }
end

-- === Helper keybind ===
local function createKeybind(parent, labelText, defaultKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.35, 0, 1, 0)
    btn.Position = UDim2.new(0.65, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.BackgroundTransparency = 0.5
    btn.BorderSizePixel = 0
    btn.Text = defaultKey or "None"
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    local currentKey = defaultKey or "None"

    btn.MouseButton1Click:Connect(function()
        if isBindingKey then return end
        isBindingKey = true
        btn.Text = "..."
        btn.TextColor3 = Color3.fromRGB(255, 42, 109)

        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode.Name
                if key ~= "Unknown" then
                    currentKey = key
                    btn.Text = key
                    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
                    if callback then callback(key) end
                    isBindingKey = false
                    conn:Disconnect()
                end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                -- Abaikan mouse untuk keybind
            end
        end)

        -- Jika user klik di luar atau tekan escape, batalkan
        local cancelConn
        cancelConn = UserInputService.InputBegan:Connect(function(inp)
            if inp.KeyCode == Enum.KeyCode.Escape then
                btn.Text = currentKey
                btn.TextColor3 = Color3.fromRGB(220, 220, 230)
                isBindingKey = false
                conn:Disconnect()
                cancelConn:Disconnect()
            end
        end)
    end)

    return { getValue = function() return currentKey end, setValue = function(v) currentKey = v; btn.Text = v end }
end

-- ================================================================
-- 6. BUILD UI
-- ================================================================

-- Toggle Desync
local desyncToggle = createToggle(scroll, "Enable Desync", false, function(val)
    Config.Desync = val
    if not val then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored = false end
        isDesyncActive = false
        destroyGhost()
    end
end)

-- Toggle Ghost
local ghostToggle = createToggle(scroll, "Show Ghost", true, function(val)
    Config.EnableGhost = val
    if not val then
        destroyGhost()
    elseif Config.Desync and isDesyncActive then
        local char = LocalPlayer.Character
        if char then createGhost(char) end
    end
end)

-- Dropdown Color
local colorDropdown = createDropdown(scroll, "Ghost Color", {"Accent", "Cyan", "Purple", "Green", "Red", "Yellow", "White"}, "Accent", function(val)
    Config.GhostColor = val
    if ghostModel then
        local highlight = ghostModel:FindFirstChild("GhostHighlight")
        if highlight then
            highlight.FillColor = getColor(val)
        end
        for _, part in ipairs(ghostModel:GetChildren()) do
            if part:IsA("BasePart") then
                part.Color = getColor(val)
            end
        end
    end
end)

-- Slider Transparency
local transSlider = createSlider(scroll, "Ghost Transparency", 0, 100, 50, "%", function(val)
    Config.GhostTransparency = val / 100
    if ghostModel then
        local highlight = ghostModel:FindFirstChild("GhostHighlight")
        if highlight then
            highlight.FillTransparency = val / 100
        end
    end
end)

-- Toggle Always On Top
local ontopToggle = createToggle(scroll, "Ghost Always On Top", true, function(val)
    Config.GhostAlwaysOnTop = val
    if ghostModel then
        local highlight = ghostModel:FindFirstChild("GhostHighlight")
        if highlight then
            highlight.DepthMode = val and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        end
    end
end)

-- Keybind
local keybind = createKeybind(scroll, "Toggle Keybind", "None", function(key)
    Config.Keybind = key
end)

-- Tambahkan label info
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 20)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Press keybind to toggle Desync"
infoLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 11
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.Parent = scroll

-- ================================================================
-- 7. KEYBIND LISTENER
-- ================================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or isBindingKey then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode.Name
        if Config.Keybind ~= "None" and key == Config.Keybind then
            desyncToggle.setValue(not desyncToggle.getValue())
        end
    end
end)

-- ================================================================
-- 8. JALANKAN DESYNC LOOP
-- ================================================================
startDesyncLoop()

-- Cleanup saat screenGui di-destroy
screenGui.DescendantRemoving:Connect(function(obj)
    if obj == screenGui then
        destroyGhost()
        if desyncConnection then desyncConnection:Disconnect() end
    end
end)

-- ================================================================
-- 9. TAMPILKAN UI
-- ================================================================
print("[Desync] UI siap. Nyalakan 'Enable Desync' untuk mulai.")
