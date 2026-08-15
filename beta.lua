-- ============================================================================
-- Always Fast Vault - Standalone Script
-- Ekstrak dari 6locc untuk Violence District
-- Mobile Friendly, Draggable UI
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================================
-- 1. BUAT GUI
-- ============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FastVaultUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 160, 0, 60)
mainFrame.Position = UDim2.new(0.5, -80, 0.5, -30)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 27)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Sudut melengkung
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Garis tepi
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(45, 48, 58)
stroke.Thickness = 1.2
stroke.Transparency = 0.5
stroke.Parent = mainFrame

-- Judul
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 20)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Text = "Fast Vault"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 50, 0, 16)
statusLabel.Position = UDim2.new(0, 10, 0, 30)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "OFF"
statusLabel.TextColor3 = Color3.fromRGB(140, 140, 155)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Toggle button (switch)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 50, 0, 24)
toggleBtn.Position = UDim2.new(1, -60, 0, 28)
toggleBtn.AnchorPoint = Vector2.new(1, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = ""
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = mainFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(1, 0)
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(45, 48, 58)
toggleStroke.Thickness = 1
toggleStroke.Parent = toggleBtn

local toggleThumb = Instance.new("Frame")
toggleThumb.Size = UDim2.new(0, 18, 0, 18)
toggleThumb.Position = UDim2.new(0, 3, 0.5, -9)
toggleThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
toggleThumb.BorderSizePixel = 0
toggleThumb.Parent = toggleBtn

local thumbCorner = Instance.new("UICorner")
thumbCorner.CornerRadius = UDim.new(1, 0)
thumbCorner.Parent = toggleThumb

-- ============================================================================
-- 2. DRAGGABLE FRAME (Support Touch & Mouse)
-- ============================================================================
local dragToggle = false
local dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ============================================================================
-- 3. STATE & TOGGLE LOGIC
-- ============================================================================
local enabled = false

local function updateToggleUI()
    if enabled then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(78, 127, 252)  -- accent color
        toggleStroke.Color = Color3.fromRGB(78, 127, 252)
        toggleThumb.Position = UDim2.new(1, -21, 0.5, -9)
        statusLabel.Text = "ON"
        statusLabel.TextColor3 = Color3.fromRGB(78, 127, 252)
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
        toggleStroke.Color = Color3.fromRGB(45, 48, 58)
        toggleThumb.Position = UDim2.new(0, 3, 0.5, -9)
        statusLabel.Text = "OFF"
        statusLabel.TextColor3 = Color3.fromRGB(140, 140, 155)
    end
end

-- Klik / Tap untuk toggle
toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    updateToggleUI()
end)

toggleBtn.TouchTap:Connect(function()
    enabled = not enabled
    updateToggleUI()
end)

updateToggleUI()

-- ============================================================================
-- 4. CORE FAST VAULT LOGIC (diambil dari 6locc)
-- ============================================================================

local function setupFastVault(character)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid
    if not animator then return end

    -- Load fast vault animation (ID dari 6locc)
    local fastVaultAnim = Instance.new("Animation")
    fastVaultAnim.AnimationId = "rbxassetid://83873880822918"
    local fastVaultTrack
    pcall(function()
        fastVaultTrack = animator:LoadAnimation(fastVaultAnim)
        if fastVaultTrack then
            fastVaultTrack.Priority = Enum.AnimationPriority.Action
        end
    end)

    -- Listen animation played
    local connection
    connection = animator.AnimationPlayed:Connect(function(animationTrack)
        if not enabled then return end
        if not character or not character.Parent then
            if connection then connection:Disconnect() end
            return
        end

        local animId = animationTrack.Animation and animationTrack.Animation.AnimationId or ""
        local animName = animationTrack.Name or ""
        animId = string.lower(tostring(animId))
        animName = string.lower(tostring(animName))

        -- Deteksi animasi vault biasa (walking vault)
        if animId:find("126081405469607") or animName:find("walkingvault") then
            -- Hentikan animasi vault biasa
            pcall(function()
                animationTrack:Stop(0)
            end)

            -- Mainkan fast vault
            if fastVaultTrack then
                pcall(function()
                    fastVaultTrack:Play(0.02)
                end)
            end

            -- Set atribut sprint agar vault menjadi fast
            pcall(function()
                character:SetAttribute("Sprinting", true)
                character:SetAttribute("IsRunning", true)
                humanoid:SetAttribute("Sprinting", true)
                humanoid:SetAttribute("IsRunning", true)
            end)
        end
    end)

    -- Simpan connection untuk cleanup
    if not character:GetAttribute("FastVaultConnection") then
        character:SetAttribute("FastVaultConnection", connection)
    end
end

-- ============================================================================
-- 5. HOOK KE CHARACTER
-- ============================================================================

local function onCharacterAdded(character)
    task.wait(0.5) -- Tunggu humanoid & animator siap
    setupFastVault(character)
end

local function cleanupCharacter(character)
    local conn = character:GetAttribute("FastVaultConnection")
    if conn then
        pcall(function() conn:Disconnect() end)
        character:SetAttribute("FastVaultConnection", nil)
    end
end

-- Jika character sudah ada
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

-- Ketika character baru spawn
LocalPlayer.CharacterAdded:Connect(function(character)
    if LocalPlayer.Character and LocalPlayer.Character ~= character then
        cleanupCharacter(LocalPlayer.Character)
    end
    onCharacterAdded(character)
end)

print("[Fast Vault] Script loaded. Toggle UI to enable/disable.")
