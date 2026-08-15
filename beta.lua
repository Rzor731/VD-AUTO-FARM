--[[
    Always Fast Vault - Standalone Test Harness
    Extracted/adapted from the provided 6locc.txt source.

    Source-derived behavior:
    1) Replace the walking-vault animation (126081405469607) with the fast-vault
       animation (83873880822918).
    2) Intercept VaultEvent FireServer/InvokeServer calls and change the second
       boolean argument from false -> true.
    3) When E or Space is pressed near a VaultTrigger/VaultPoint (<= 9 studs),
       set sprint/running attributes, face the vault and push the root at 22
       studs/s toward it.
    4) Re-discover vault remotes after respawn and keep the feature toggleable.

    Intended as a standalone test harness for the supplied source.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    return
end

local Config = {
    AlwaysFastVault = false,
}

local Connections = {}
local HookInstalled = false

local FastVaultRemote
local VaultCompleteRemote
local VaultListenerConnection
local CharacterAnimationConnection

local function addConnection(connection)
    if connection then
        table.insert(Connections, connection)
    end
    return connection
end

local function disconnectAll()
    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(Connections)

    if VaultListenerConnection then
        pcall(function()
            VaultListenerConnection:Disconnect()
        end)
        VaultListenerConnection = nil
    end

    if CharacterAnimationConnection then
        pcall(function()
            CharacterAnimationConnection:Disconnect()
        end)
        CharacterAnimationConnection = nil
    end
end

local function findVaultRemotes()
    FastVaultRemote = nil
    VaultCompleteRemote = nil

    local root = ReplicatedStorage:FindFirstChild("Remotes", true) or ReplicatedStorage

    for _, instance in ipairs(root:GetDescendants()) do
        if instance:IsA("RemoteEvent") then
            local name = instance.Name:lower()

            if name == "fastvault" then
                FastVaultRemote = instance
            elseif name == "vaultcompleteeventpart1" then
                VaultCompleteRemote = instance
            end
        end
    end
end

local function getVaultPoints()
    local points = {}
    local map = workspace:FindFirstChild("Map") or workspace

    for _, instance in ipairs(map:GetDescendants()) do
        if (instance.Name == "VaultTrigger" or instance.Name == "VaultPoint")
            and instance:IsA("BasePart") then
            table.insert(points, instance)
        end
    end

    return points
end

local function getNearestVault(position, maxDistance)
    local nearest
    local nearestDistance = maxDistance or 9

    for _, point in ipairs(getVaultPoints()) do
        if point and point.Parent then
            local distance = (position - point.Position).Magnitude
            if distance < nearestDistance then
                nearest = point
                nearestDistance = distance
            end
        end
    end

    return nearest
end

local function setRunningState(character)
    if not character then
        return
    end

    pcall(function()
        character:SetAttribute("Sprinting", true)
        character:SetAttribute("IsRunning", true)
    end)
end

local function playFastVaultAnimation(character)
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        return
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://83873880822918"

    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)

    animation:Destroy()

    if ok and track then
        track.Priority = Enum.AnimationPriority.Action
        track:Play(0.02)
    end
end

local function watchCharacter(character)
    if CharacterAnimationConnection then
        pcall(function()
            CharacterAnimationConnection:Disconnect()
        end)
        CharacterAnimationConnection = nil
    end

    if not character then
        return
    end

    local humanoid = character:WaitForChild("Humanoid", 5)
    local animator = humanoid and humanoid:WaitForChild("Animator", 5)
    if not animator then
        return
    end

    CharacterAnimationConnection = animator.AnimationPlayed:Connect(function(track)
        if not Config.AlwaysFastVault then
            return
        end

        local animationId = ""
        pcall(function()
            animationId = tostring(track.Animation and track.Animation.AnimationId or ""):lower()
        end)

        local trackName = tostring(track.Name or ""):lower()

        if animationId:find("126081405469607", 1, true)
            or trackName:find("walkingvault", 1, true) then

            pcall(function()
                track:Stop(0)
            end)

            playFastVaultAnimation(character)
        end
    end)

    addConnection(CharacterAnimationConnection)
end

local function manualFastVault()
    if not Config.AlwaysFastVault then
        return
    end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local vault = getNearestVault(root.Position, 9)
    if not vault then
        return
    end

    local delta = vault.Position - root.Position
    local direction = Vector3.new(delta.X, 0, delta.Z)

    if direction.Magnitude <= 0.05 then
        local look = root.CFrame.LookVector
        direction = Vector3.new(look.X, 0, look.Z)
    end

    if direction.Magnitude <= 0.05 then
        return
    end

    direction = direction.Unit

    local speed = root.AssemblyLinearVelocity.Magnitude
    local facing = root.CFrame.LookVector:Dot(direction)
    local alreadyFast = speed >= 13 and facing >= 0.7

    if not alreadyFast then
        setRunningState(character)

        root.CFrame = CFrame.new(root.Position, root.Position + direction)
        root.AssemblyLinearVelocity = direction * 22
    end
end

local function installVaultHook()
    if HookInstalled then
        return
    end

    if typeof(hookmetamethod) ~= "function" or typeof(getnamecallmethod) ~= "function" then
        return
    end

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if Config.AlwaysFastVault
            and (method == "FireServer" or method == "InvokeServer")
            and typeof(self) == "Instance"
            and self.Name == "VaultEvent"
            and args[2] == false then

            args[2] = true

            local character = LocalPlayer.Character
            if character then
                setRunningState(character)
            end

            if FastVaultRemote and character then
                pcall(function()
                    FastVaultRemote:FireServer(character)
                end)
            end

            if VaultCompleteRemote then
                pcall(function()
                    VaultCompleteRemote:FireServer()
                end)
            end
        end

        return oldNamecall(self, table.unpack(args))
    end))

    HookInstalled = true
end

local function setEnabled(enabled)
    Config.AlwaysFastVault = enabled

    if enabled then
        findVaultRemotes()
    end
end

-- GUI ------------------------------------------------------------------------

local guiParent = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AlwaysFastVaultTest"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiParent

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(280, 170)
Main.Position = UDim2.new(0.5, -140, 0.5, -85)
Main.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = Main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(55, 60, 75)
stroke.Thickness = 1
stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(14, 10)
Title.Size = UDim2.new(1, -28, 0, 24)
Title.Font = Enum.Font.GothamBold
Title.Text = "Always Fast Vault"
Title.TextColor3 = Color3.fromRGB(240, 242, 248)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local Subtitle = Instance.new("TextLabel")
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.fromOffset(14, 34)
Subtitle.Size = UDim2.new(1, -28, 0, 20)
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "Standalone test harness"
Subtitle.TextColor3 = Color3.fromRGB(150, 156, 170)
Subtitle.TextSize = 11
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Main

local Toggle = Instance.new("TextButton")
Toggle.Name = "Toggle"
Toggle.Position = UDim2.fromOffset(14, 66)
Toggle.Size = UDim2.new(1, -28, 0, 42)
Toggle.BackgroundColor3 = Color3.fromRGB(37, 40, 50)
Toggle.BorderSizePixel = 0
Toggle.AutoButtonColor = false
Toggle.Font = Enum.Font.GothamBold
Toggle.Text = "FAST VAULT: OFF"
Toggle.TextColor3 = Color3.fromRGB(210, 214, 224)
Toggle.TextSize = 13
Toggle.Parent = Main

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 9)
toggleCorner.Parent = Toggle

local Status = Instance.new("TextLabel")
Status.BackgroundTransparency = 1
Status.Position = UDim2.fromOffset(14, 116)
Status.Size = UDim2.new(1, -28, 0, 18)
Status.Font = Enum.Font.Gotham
Status.Text = "Status: disabled"
Status.TextColor3 = Color3.fromRGB(145, 150, 165)
Status.TextSize = 11
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

local Help = Instance.new("TextLabel")
Help.BackgroundTransparency = 1
Help.Position = UDim2.fromOffset(14, 137)
Help.Size = UDim2.new(1, -28, 0, 18)
Help.Font = Enum.Font.Gotham
Help.Text = "PC: E / Space   •   Mobile: use the game vault button"
Help.TextColor3 = Color3.fromRGB(120, 125, 140)
Help.TextSize = 9.5
Help.TextXAlignment = Enum.TextXAlignment.Left
Help.Parent = Main

local function refreshUI()
    local enabled = Config.AlwaysFastVault

    Toggle.Text = enabled and "FAST VAULT: ON" or "FAST VAULT: OFF"
    Toggle.TextColor3 = enabled
        and Color3.fromRGB(95, 255, 170)
        or Color3.fromRGB(210, 214, 224)

    Toggle.BackgroundColor3 = enabled
        and Color3.fromRGB(24, 55, 43)
        or Color3.fromRGB(37, 40, 50)

    Status.Text = enabled
        and "Status: monitoring vaults"
        or "Status: disabled"
end

Toggle.MouseButton1Click:Connect(function()
    setEnabled(not Config.AlwaysFastVault)
    refreshUI()
end)

addConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
        return
    end

    if not Config.AlwaysFastVault then
        return
    end

    if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Space then
        manualFastVault()
    end
end))

-- Simple drag support; works with mouse and touch.
do
    local dragging = false
    local dragStart
    local startPos

    addConnection(Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end))

    addConnection(Main.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    addConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end))
end

addConnection(LocalPlayer.CharacterAdded:Connect(function(character)
    task.defer(function()
        watchCharacter(character)
    end)
end))

findVaultRemotes()
watchCharacter(LocalPlayer.Character)
installVaultHook()
refreshUI()

-- Cleanup helper for repeated execution.
_G.AlwaysFastVaultTestCleanup = function()
    Config.AlwaysFastVault = false
    disconnectAll()

    pcall(function()
        ScreenGui:Destroy()
    end)
end
