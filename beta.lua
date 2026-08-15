-- Always Fast Vault - Standalone Script
-- Mobile Friendly GUI
-- Credit: 6locc (Violence District)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- GUI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FastVaultGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 100)
mainFrame.Position = UDim2.new(0.5, -100, 0.85, 0) -- di bawah layar
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 60, 80)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ Fast Vault"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = mainFrame

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.8, 0, 0, 40)
toggleButton.Position = UDim2.new(0.1, 0, 0.45, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
toggleButton.BackgroundTransparency = 0.3
toggleButton.Text = "OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 18
toggleButton.AutoButtonColor = false
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleButton

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(100, 100, 120)
btnStroke.Thickness = 1
btnStroke.Parent = toggleButton

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0.85, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Tap vault (E/Space) to fast vault"
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = mainFrame

-- State
local enabled = false
local isVaulting = false

-- ==== ALGORITMA ALWAYS FAST VAULT (dari 6locc) ====

-- 1. Hook VaultEvent remote agar selalu mengirim parameter true untuk fast vault
-- 2. Mainkan animasi fast vault (83873880822918)
-- 3. Deteksi input E atau Space saat di dekat vault, lalu force sprint dan teleport ke arah vault

-- Kumpulkan semua VaultTrigger / VaultPoint di map
local vaultPoints = {}
local function refreshVaults()
    table.clear(vaultPoints)
    local map = workspace:FindFirstChild("Map") or workspace
    for _, obj in ipairs(map:GetDescendants()) do
        if (obj.Name == "VaultTrigger" or obj.Name == "VaultPoint") and obj:IsA("BasePart") then
            table.insert(vaultPoints, obj)
        end
    end
end
refreshVaults()
-- Update saat map berubah
workspace.DescendantAdded:Connect(function(inst)
    if (inst.Name == "VaultTrigger" or inst.Name == "VaultPoint") and inst:IsA("BasePart") then
        table.insert(vaultPoints, inst)
    end
end)
workspace.DescendantRemoving:Connect(function(inst)
    if (inst.Name == "VaultTrigger" or inst.Name == "VaultPoint") and inst:IsA("BasePart") then
        for i, v in ipairs(vaultPoints) do
            if v == inst then
                table.remove(vaultPoints, i)
                break
            end
        end
    end
end)

-- Cari VaultTrigger terdekat dari posisi player
local function getNearestVaultTrigger(rootPos)
    local nearest, minDist = nil, 12 -- radius 12 studs
    for _, v in ipairs(vaultPoints) do
        if v and v.Parent then
            local dist = (v.Position - rootPos).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = v
            end
        end
    end
    return nearest
end

-- Fast vault animation ID
local FAST_VAULT_ANIM_ID = "83873880822918"

-- Variable untuk animator
local fastAnimTrack = nil
local animator = nil

-- Fungsi untuk memuat dan memainkan animasi fast vault
local function playFastVaultAnim(character)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local anim = humanoid:FindFirstChildOfClass("Animator")
    if not anim then
        anim = Instance.new("Animator")
        anim.Parent = humanoid
    end
    animator = anim

    -- Hentikan animasi sebelumnya
    if fastAnimTrack then
        pcall(fastAnimTrack.Stop, fastAnimTrack)
        fastAnimTrack = nil
    end

    -- Buat animasi baru
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. FAST_VAULT_ANIM_ID
    local track = anim:LoadAnimation(animation)
    if track then
        track.Priority = Enum.AnimationPriority.Action
        track:Play(0.02)
        fastAnimTrack = track
    end
end

-- Fungsi untuk melakukan fast vault
local function doFastVault(character)
    if not enabled then return end
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Cari vault terdekat
    local trigger = getNearestVaultTrigger(root.Position)
    if not trigger then return end

    -- Set attribute sprinting dan running (agar vault dianggap fast)
    pcall(function()
        character:SetAttribute("Sprinting", true)
        character:SetAttribute("IsRunning", true)
    end)

    -- Arahkan karakter ke trigger
    local dir = (trigger.Position - root.Position)
    local flatDir = Vector3.new(dir.X, 0, dir.Z)
    if flatDir.Magnitude > 0.5 then
        flatDir = flatDir.Unit
        root.CFrame = CFrame.new(root.Position, root.Position + flatDir)
    end

    -- Force sprint velocity
    root.AssemblyLinearVelocity = flatDir * 22

    -- Mainkan animasi fast vault
    playFastVaultAnim(character)

    -- Kirim remote event VaultEvent dengan parameter true
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local vaultEvent = remotes:FindFirstChild("Window") and remotes.Window:FindFirstChild("VaultEvent")
        if vaultEvent then
            pcall(function()
                vaultEvent:FireServer(trigger, true)
            end)
        end
        -- Coba juga VaultCompleteEvent jika ada
        local vaultComplete = remotes:FindFirstChild("Window") and remotes.Window:FindFirstChild("VaultCompleteEvent")
        if vaultComplete then
            pcall(function()
                vaultComplete:FireServer(trigger, false) -- false = selesai vault?
            end)
        end
    end
end

-- Hook VaultEvent agar selalu mengirim true saat enabled
local originalFireServer = nil
local hookActive = false

local function setupHook()
    if hookActive then return end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return end
    local window = remotes:FindFirstChild("Window")
    if not window then return end
    local vaultEvent = window:FindFirstChild("VaultEvent")
    if not vaultEvent then return end

    if not hookmetamethod or not getnamecallmethod then
        -- Fallback: tangani dengan InputBegan langsung (tanpa hook remote)
        return
    end

    originalFireServer = hookmetamethod(vaultEvent, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and enabled then
            local args = {...}
            if #args >= 2 then
                -- Ubah parameter kedua menjadi true (fast vault)
                args[2] = true
                return originalFireServer(self, unpack(args))
            end
        end
        return originalFireServer(self, ...)
    end)
    hookActive = true
end

-- Jika hook gagal, gunakan input detection alternatif
local function setupInputHandler()
    -- Detect E or Space
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not enabled then return end

        local key = input.KeyCode
        if key == Enum.KeyCode.E or key == Enum.KeyCode.Space then
            local char = LocalPlayer.Character
            if char then
                doFastVault(char)
            end
        end
    end)
end

-- Juga tangani ketika player menekan tombol vault di UI (mobile) - kita tidak bisa tahu, tapi kita bisa trigger dari input.

-- Inisialisasi
setupInputHandler()
setupHook()

-- Toggle GUI
toggleButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggleButton.Text = enabled and "ON" or "OFF"
    toggleButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 80)
    statusLabel.Text = enabled and "✅ Fast Vault Active" or "Tap vault (E/Space) to fast vault"
end)

-- Untuk mobile, tambahkan touch support
toggleButton.TouchTap:Connect(function()
    enabled = not enabled
    toggleButton.Text = enabled and "ON" or "OFF"
    toggleButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 80)
    statusLabel.Text = enabled and "✅ Fast Vault Active" or "Tap vault (E/Space) to fast vault"
end)

-- Cleanup saat di-unload
local function cleanup()
    if originalFireServer and hookActive then
        pcall(function()
            -- Tidak ada cara mudah untuk unhook, tapi kita bisa set enabled = false
        end)
    end
    screenGui:Destroy()
end

-- Deteksi jika script di-unload (optional)
-- Tambahkan tombol unload? Bisa ditambahkan nanti.

print("Always Fast Vault loaded! Toggle from GUI.")
