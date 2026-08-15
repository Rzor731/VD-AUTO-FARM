--[=[ 
    GUI for Network Desync Feature
    Extracted from Violence District script
    Mobile-friendly
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or Instance.new("PlayerGui", LocalPlayer)

-- Config defaults
local Config = {
    Desync = false,
    EnableDesyncGhost = false,
    DesyncGhostAlwaysOnTop = true,
    DesyncGhostTransparency = 0.5,
    DesyncGhostColor = "Accent"
}

-- Color map
local colorMap = {
    Accent = Color3.fromRGB(255, 42, 109),
    Cyan = Color3.fromRGB(0, 255, 255),
    Purple = Color3.fromRGB(180, 50, 255),
    Green = Color3.fromRGB(0, 255, 120),
    Red = Color3.fromRGB(255, 60, 60),
    Yellow = Color3.fromRGB(255, 220, 0),
    White = Color3.fromRGB(255, 255, 255)
}

-- Ghost reference
local ghostModel = nil
local ghostHighlight = nil
local isAnchored = false
local lastCFrame = nil

-- Functions to control desync
local function destroyGhost()
    if ghostModel then
        ghostModel:Destroy()
        ghostModel = nil
        ghostHighlight = nil
    end
end

local function createGhost(character)
    if not character then return end
    destroyGhost()
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local ghost = Instance.new("Model")
    ghost.Name = "DesyncGhost"
    
    -- Clone visible parts
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local clone = part:Clone()
            clone.Anchored = true
            clone.CanCollide = false
            clone.CastShadow = false
            clone.Transparency = 0.99
            clone.Material = Enum.Material.SmoothPlastic
            clone.Parent = ghost
            -- Store original part name
            clone:SetAttribute("OriginalPartName", part.Name)
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                local clone = handle:Clone()
                clone.Anchored = true
                clone.CanCollide = false
                clone.CastShadow = false
                clone.Transparency = 0.99
                clone.Material = Enum.Material.SmoothPlastic
                clone:SetAttribute("OriginalPartName", handle.Name)
                clone.Parent = ghost
            end
        end
    end
    
    -- Position ghost at current character position
    local rootCF = rootPart.CFrame
    for _, part in ipairs(ghost:GetChildren()) do
        if part:IsA("BasePart") then
            local origName = part:GetAttribute("OriginalPartName")
            local origPart = character:FindFirstChild(origName, true)
            if origPart and origPart:IsA("BasePart") then
                local offset = rootCF:ToObjectSpace(origPart.CFrame)
                part.CFrame = rootCF * offset
            end
        end
    end
    
    -- Add highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "GhostHighlight"
    highlight.FillColor = colorMap[Config.DesyncGhostColor] or colorMap.Accent
    highlight.FillTransparency = Config.DesyncGhostTransparency or 0.5
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Config.DesyncGhostAlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    highlight.Adornee = ghost
    highlight.Enabled = true
    highlight.Parent = ghost
    
    ghost.Parent = workspace
    ghostModel = ghost
    ghostHighlight = highlight
end

local function updateGhostAppearance()
    if not ghostModel then return end
    if ghostHighlight then
        ghostHighlight.FillColor = colorMap[Config.DesyncGhostColor] or colorMap.Accent
        ghostHighlight.FillTransparency = Config.DesyncGhostTransparency or 0.5
        ghostHighlight.DepthMode = Config.DesyncGhostAlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    end
    -- Update position of ghost parts to match character
    local character = LocalPlayer.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local rootCF = rootPart.CFrame
            for _, part in ipairs(ghostModel:GetChildren()) do
                if part:IsA("BasePart") then
                    local origName = part:GetAttribute("OriginalPartName")
                    local origPart = character:FindFirstChild(origName, true)
                    if origPart and origPart:IsA("BasePart") then
                        local offset = rootCF:ToObjectSpace(origPart.CFrame)
                        part.CFrame = rootCF * offset
                    end
                end
            end
        end
    end
end

local function applyDesync()
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if Config.Desync then
        -- Anchor character and store CFrame
        if not isAnchored then
            rootPart.Anchored = true
            lastCFrame = rootPart.CFrame
            isAnchored = true
        end
        -- Update CFrame based on movement (simulate)
        -- In real script, this is handled in a loop
        if Config.EnableDesyncGhost then
            if not ghostModel then
                createGhost(character)
            else
                updateGhostAppearance()
            end
        else
            destroyGhost()
        end
    else
        -- Unanchor
        if isAnchored then
            rootPart.Anchored = false
            isAnchored = false
        end
        destroyGhost()
    end
end

-- Heartbeat loop for desync (simulate movement while anchored)
local function desyncLoop()
    if not Config.Desync then return end
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    if isAnchored then
        -- Move character based on MoveDirection (simulate)
        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            local speed = humanoid.WalkSpeed
            local delta = RunService.Heartbeat:Wait() or 0.016
            local newPos = rootPart.Position + moveDir * speed * delta
            rootPart.CFrame = CFrame.new(newPos) * rootPart.CFrame.Rotation
            lastCFrame = rootPart.CFrame
        end
    end
end

-- GUI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DesyncControlGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 0)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 42, 109)
stroke.Thickness = 1.5
stroke.Transparency = 0.3
stroke.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0, 0, 0, 6)
title.BackgroundTransparency = 1
title.Text = "Network Desync"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = mainFrame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -36, 0, 8)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Scroll container
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -48)
scrollFrame.Position = UDim2.new(0, 0, 0, 42)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 3
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 42, 109)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.Parent = scrollFrame

-- Helper: create toggle row
local function createToggle(labelText, configKey, defaultValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    row.BackgroundTransparency = 0.3
    row.BorderSizePixel = 0
    row.Parent = scrollFrame
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent = row
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, -8, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, 26)
    toggleBtn.Position = UDim2.new(1, -58, 0.5, -13)
    toggleBtn.BackgroundColor3 = defaultValue and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(60, 60, 80)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = ""
    toggleBtn.AutoButtonColor = false
    toggleBtn.Parent = row
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBtn
    
    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 20, 0, 20)
    thumb.Position = defaultValue and UDim2.new(1, -24, 0.5, -10) or UDim2.new(0, 4, 0.5, -10)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.Parent = toggleBtn
    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent = thumb
    
    local function setValue(val)
        Config[configKey] = val
        toggleBtn.BackgroundColor3 = val and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(60, 60, 80)
        thumb.Position = val and UDim2.new(1, -24, 0.5, -10) or UDim2.new(0, 4, 0.5, -10)
        -- Apply changes
        if configKey == "Desync" then
            applyDesync()
            -- Start/stop loop
            if val then
                if not desyncConnection then
                    desyncConnection = RunService.Heartbeat:Connect(desyncLoop)
                end
            else
                if desyncConnection then
                    desyncConnection:Disconnect()
                    desyncConnection = nil
                end
                -- Unanchor
                local char = LocalPlayer.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then root.Anchored = false end
                end
                isAnchored = false
                destroyGhost()
            end
        elseif configKey == "EnableDesyncGhost" then
            if Config.Desync then
                if val then
                    local char = LocalPlayer.Character
                    if char then createGhost(char) end
                else
                    destroyGhost()
                end
            end
        elseif configKey == "DesyncGhostAlwaysOnTop" then
            if ghostHighlight then
                ghostHighlight.DepthMode = val and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            end
        end
    end
    
    toggleBtn.MouseButton1Click:Connect(function()
        setValue(not Config[configKey])
    end)
    
    -- set initial
    Config[configKey] = defaultValue
    setValue(defaultValue)
    
    return row
end

-- Helper: create slider
local function createSlider(labelText, configKey, minVal, maxVal, defaultValue, suffix)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 60)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    row.BackgroundTransparency = 0.3
    row.BorderSizePixel = 0
    row.Parent = scrollFrame
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent = row
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 0, 20)
    label.Position = UDim2.new(0, 8, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.25, 0, 0, 20)
    valueLabel.Position = UDim2.new(0.72, 0, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue) .. (suffix or "")
    valueLabel.TextColor3 = Color3.fromRGB(255, 42, 109)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = row
    
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size = UDim2.new(1, -16, 0, 4)
    sliderTrack.Position = UDim2.new(0, 8, 0, 34)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Parent = row
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = sliderTrack
    
    local fill = Instance.new("Frame")
    local ratio = (defaultValue - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(ratio, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 42, 109)
    fill.BorderSizePixel = 0
    fill.Parent = sliderTrack
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    local thumb = Instance.new("TextButton")
    thumb.Size = UDim2.new(0, 20, 0, 20)
    thumb.Position = UDim2.new(ratio, -10, 0.5, -10)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.Text = ""
    thumb.AutoButtonColor = false
    thumb.Parent = sliderTrack
    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent = thumb
    
    local function setValue(val)
        val = math.clamp(val, minVal, maxVal)
        Config[configKey] = val
        valueLabel.Text = tostring(val) .. (suffix or "")
        local newRatio = (val - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(newRatio, 0, 1, 0)
        thumb.Position = UDim2.new(newRatio, -10, 0.5, -10)
        -- Apply
        if configKey == "DesyncGhostTransparency" then
            if ghostHighlight then
                ghostHighlight.FillTransparency = val
            end
        end
    end
    
    local dragging = false
    thumb.MouseButton1Down:Connect(function()
        dragging = true
    end)
    thumb.MouseButton1Up:Connect(function()
        dragging = false
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local trackSize = sliderTrack.AbsoluteSize.X
            if trackSize > 0 then
                local mouseX = input.Position.X - sliderTrack.AbsolutePosition.X
                local newVal = minVal + (mouseX / trackSize) * (maxVal - minVal)
                setValue(newVal)
            end
        end
    end)
    
    -- set initial
    setValue(defaultValue)
    
    return row
end

-- Helper: create color picker
local function createColorPicker(labelText, configKey, defaultColor)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    row.BackgroundTransparency = 0.3
    row.BorderSizePixel = 0
    row.Parent = scrollFrame
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent = row
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    local colors = {"Accent", "Cyan", "Purple", "Green", "Red", "Yellow", "White"}
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(0.48, 0, 1, 0)
    btnContainer.Position = UDim2.new(0.5, 0, 0, 0)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = row
    
    local flow = Instance.new("UIListLayout")
    flow.FillDirection = Enum.FillDirection.Horizontal
    flow.HorizontalAlignment = Enum.HorizontalAlignment.Right
    flow.VerticalAlignment = Enum.VerticalAlignment.Center
    flow.Padding = UDim.new(0, 4)
    flow.Parent = btnContainer
    
    local function updateColorButtons(selected)
        for _, child in ipairs(btnContainer:GetChildren()) do
            if child:IsA("TextButton") then
                local isSelected = child.Name == selected
                child.Size = isSelected and UDim2.new(0, 28, 0, 28) or UDim2.new(0, 22, 0, 22)
                child.BackgroundTransparency = isSelected and 0 or 0.3
                child.BorderSizePixel = isSelected and 2 or 0
            end
        end
    end
    
    for _, colorName in ipairs(colors) do
        local btn = Instance.new("TextButton")
        btn.Name = colorName
        btn.Size = UDim2.new(0, 22, 0, 22)
        btn.BackgroundColor3 = colorMap[colorName] or Color3.fromRGB(255,255,255)
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = btnContainer
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(1, 0)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            Config[configKey] = colorName
            updateColorButtons(colorName)
            if ghostHighlight then
                ghostHighlight.FillColor = colorMap[colorName]
            end
        end)
    end
    
    -- set initial
    updateColorButtons(defaultColor)
    Config[configKey] = defaultColor
    
    return row
end

-- Create controls
createToggle("Enable Desync", "Desync", false)
createToggle("Show Ghost", "EnableDesyncGhost", false)
createToggle("Ghost Always On Top", "DesyncGhostAlwaysOnTop", true)
createSlider("Ghost Transparency", "DesyncGhostTransparency", 0, 1, 0.5, "")
createColorPicker("Ghost Color", "DesyncGhostColor", "Accent")

-- Calculate height
local function updateHeight()
    local contentSize = listLayout.AbsoluteContentSize
    mainFrame.Size = UDim2.new(0, 320, 0, math.min(contentSize.Y + 48, 420))
end
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHeight)
task.wait(0.1)
updateHeight()

-- Desync loop connection
local desyncConnection = nil

-- Cleanup on gui destroy
screenGui.AncestryChanged:Connect(function()
    if not screenGui.Parent then
        if desyncConnection then desyncConnection:Disconnect() end
        -- Unanchor if needed
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then root.Anchored = false end
        end
        destroyGhost()
    end
end)

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if Config.Desync then
        applyDesync()
        if Config.EnableDesyncGhost then
            createGhost(char)
        end
    end
end)

print("Desync Control GUI loaded. Use the UI to test network desync features.")
