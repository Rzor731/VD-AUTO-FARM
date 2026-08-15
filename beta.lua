-- ============================================================
--  Contoh Script Menggunakan ModernV2 Library
--  Loader: https://ziaanclient.vercel.app/zilux
-- ============================================================

-- 1. LOAD LIBRARY
local Library = loadstring(game:HttpGet("https://ziaanclient.vercel.app/zilux"))()

-- 2. BUAT WINDOW UTAMA
local Window = Library:Window({
    Name = "My Awesome Script",          -- Judul window
    Content = "ModernV2 Example",        -- Sub-judul
    Size = Library.Scales.Large,         -- Ukuran window (Large, Default, Mobile, dll)
    Logo = "rbxassetid://120358385035996", -- Logo (bisa URL atau asset ID)
    Keybind = "RightControl",            -- Tombol untuk toggle window
    ConfigFolder = "MyScriptConfigs",    -- Folder untuk menyimpan config
    TextGradient = true,                 -- Efek gradien pada teks
    NotifyOnCallbackError = true,        -- Notifikasi jika callback error
})

-- 3. TAMBAHKAN TAB "HOME" (dengan dashboard otomatis)
local HomeTab = Window:CreateHomeTab({
    Name = "Dashboard",
    Icon = "lucide:layout-dashboard",
    Title = "Dashboard",
    Content = "Welcome to the script!",
    DiscordInvite = "yourdiscordinvite", -- Kosongkan jika tidak ada
    SupportedExecutors = {"Synapse X", "Krnl", "ScriptWare"}, -- Daftar executor yang didukung
    UnsupportedExecutors = {},           -- Daftar executor tidak didukung
    Changelog = {
        { Title = "v1.0", Description = "Initial release" },
        { Title = "v1.1", Description = "Added new features" },
    },
    AutoSetup = true,                    -- Buat dashboard otomatis
})

-- 4. TAMBAHKAN TAB KUSTOM
local SettingsTab = Window:AddTab({
    Name = "Settings",
    Icon = "lucide:settings",
    Type = "Double",                     -- Layout dua kolom
})

-- 4a. Section di kiri
local LeftSection = SettingsTab:AddSection({
    Name = "General Settings",
    Position = "left",                   -- atau "right" / "center"
    Icon = "lucide:sliders-horizontal",
    Collapsible = true,                 -- Bisa dilipat
})

-- Toggle
LeftSection:AddToggle({
    Name = "Enable Feature",
    Default = false,
    Flag = "featureToggle",              -- Untuk config
    Callback = function(val)
        print("Feature toggled:", val)
        Window:Notify({
            Title = "Feature",
            Content = val and "Enabled" or "Disabled",
            Duration = 2,
            Icon = "lucide:check",
        })
    end,
})

-- Slider
LeftSection:AddSlider({
    Name = "Speed",
    Min = 0,
    Max = 100,
    Default = 50,
    Type = "%",
    Flag = "speedSlider",
    Callback = function(val)
        print("Speed set to:", val)
    end,
})

-- Dropdown
LeftSection:AddDropdown({
    Name = "Mode",
    Values = {"Easy", "Normal", "Hard"},
    Default = "Normal",
    Flag = "modeDropdown",
    Callback = function(val)
        print("Mode changed to:", val)
    end,
})

-- Keybind
LeftSection:AddKeybind({
    Name = "Toggle Key",
    Default = "F",
    Mode = "Toggle",                     -- atau "Hold"
    Flag = "toggleKey",
    Callback = function(state)
        print("Key pressed, state:", state)
    end,
})

-- 4b. Section di kanan
local RightSection = SettingsTab:AddSection({
    Name = "Appearance",
    Position = "right",
    Icon = "lucide:paint-brush",
})

-- Color Picker
RightSection:AddColorPicker({
    Name = "Accent Color",
    Default = Color3.fromRGB(78, 127, 252),
    Flag = "accentColor",
    Callback = function(color)
        print("Color changed to:", color)
        -- Update accent color global (opsional)
        Library.AccentColor = color
    end,
})

-- Text Input
RightSection:AddTextInput({
    Name = "Custom Message",
    Default = "Hello!",
    Placeholder = "Type your message",
    Flag = "messageInput",
    Callback = function(text)
        print("Message:", text)
    end,
})

-- Button
RightSection:AddButton({
    Name = "Show Message",
    Icon = "lucide:message-circle",
    Callback = function()
        local msg = Library.Flags["messageInput"] and Library.Flags["messageInput"]:GetValue() or "Hello!"
        Window:Notify({
            Title = "Message",
            Content = msg,
            Duration = 3,
            Icon = "lucide:message-circle",
        })
    end,
})

-- 5. TAMBAHKAN TAB "ABOUT"
local AboutTab = Window:AddTab({
    Name = "About",
    Icon = "lucide:info",
    Type = "Single",                     -- Satu kolom penuh
})

local AboutSection = AboutTab:AddSection({
    Name = "About This Script",
    Position = "center",
    Icon = "lucide:info",
})

AboutSection:AddParagraph({
    Name = "ModernV2 Library",
    Content = "This is an example script using the ModernV2 UI library.\n\n" ..
              "Features demonstrated:\n" ..
              "- Window with tabs and sections\n" ..
              "- Toggle, Slider, Dropdown, Keybind, ColorPicker, TextInput, Button\n" ..
              "- Config system with auto-save\n" ..
              "- Notifications and logging\n" ..
              "- Dependency boxes\n" ..
              "- Home dashboard with stats\n\n" ..
              "Library version: 0.3.3",
})

AboutSection:AddButton({
    Name = "Unload Script",
    Icon = "lucide:power",
    Callback = function()
        Window:Dialog({
            Title = "Unload?",
            Content = "Are you sure you want to unload the script?",
            Buttons = {
                { Text = "Cancel", ReturnValue = false },
                { Text = "Unload", Primary = true, ReturnValue = true },
            },
            Callback = function(result)
                if result then
                    -- Unload library (jika didukung)
                    Library.UnloadEnabled = true
                    Library:Unload()
                    -- Hapus window
                    Window:Destroy()
                end
            end,
        })
    end,
})

-- 6. DEMONSTRASI DEPENDENCY BOX
-- Buat toggle yang mengontrol dependency
local depToggle = LeftSection:AddToggle({
    Name = "Enable Advanced Options",
    Default = false,
    Flag = "advancedMode",
})

-- Section yang tergantung pada depToggle
local depSection = SettingsTab:AddSection({
    Name = "Advanced Options",
    Position = "left",
    Icon = "lucide:code",
})

-- Dependency box: hanya muncul jika advancedMode = true
local depBox = depSection:AddDependencyBox({
    Name = "Dependency Example",
    Dependencies = {
        { Flag = "advancedMode", Value = true },  -- Hanya muncul jika true
    },
    Mode = "Visible",   -- atau "Locked" untuk mengunci bukan menyembunyikan
})

depBox:AddLabel("This appears when Advanced Mode is ON"):AddSlider({
    Name = "Advanced Slider",
    Min = 0,
    Max = 10,
    Default = 5,
})

-- 7. WATERMARK (di pojok kanan atas)
local Watermark = Window:Watermark()
local block1 = Watermark:AddBlock("lucide:user", "Player: " .. game.Players.LocalPlayer.Name)
local block2 = Watermark:AddBlock("lucide:clock", "Runtime: 0s")

-- Update watermark setiap detik
local runtime = 0
game:GetService("RunService").Heartbeat:Connect(function(dt)
    runtime = runtime + dt
    if runtime >= 1 then
        runtime = 0
        local hours = math.floor(runtime / 3600)
        local minutes = math.floor((runtime % 3600) / 60)
        local seconds = math.floor(runtime % 60)
        block2:SetText(string.format("Runtime: %02d:%02d:%02d", hours, minutes, seconds))
    end
end)

-- 8. LOGGING DEMO
Library.Logging.new("lucide:info", "Script loaded successfully!", 3)

-- 9. NOTIFIKASI AWAL
Window:Notify({
    Title = "Welcome!",
    Content = "This is a notification example.",
    Duration = 4,
    Icon = "lucide:smile",
})

-- 10. MENU ICON (di pojok kiri tengah)
local MenuIcon = Library:CreateMenuIcon({
    Image = "lucide:menu",       -- Bisa pakai icon atau gambar
    Size = 48,
    IconColor = Color3.fromRGB(255,255,255),
    BGColor = Color3.fromRGB(20,22,27),
    StrokeColor = Library.AccentColor,
    Draggable = true,
})

-- Kaitkan dengan window agar icon bereaksi saat window toggle
Window:AttachMenuIcon(MenuIcon)

-- Tampilkan icon
MenuIcon:SetVisible(true)

-- 11. INDIKATOR (di samping kiri)
local Indicator = Window:Indicator({
    Name = "Online",
    Icon = "lucide:circle-check",
    Color = "Green",   -- atau "Red", "White"
})
Indicator:SetRender(true)

-- Contoh: ubah warna menjadi merah setelah 5 detik
task.delay(5, function()
    Indicator:SetColor("Red")
    Indicator:SetText("Warning")
end)

-- 12. SISTEM CONFIG OTOMATIS
-- Config akan otomatis tersimpan dan dimuat jika ConfigEnabled true
-- Kita bisa menyimpan config secara manual:
-- Window:SaveConfig("MyConfig")   -- simpan dengan nama
-- Window:LoadConfig("MyConfig")   -- muat config

-- 13. DEMO: Dialog dan Input Dialog
-- Contoh tombol untuk memunculkan dialog
local demoSection = AboutTab:AddSection({
    Name = "Dialogs",
    Position = "center",
})

demoSection:AddButton({
    Name = "Show Dialog",
    Icon = "lucide:message-square",
    Callback = function()
        Window:Dialog({
            Title = "Dialog Example",
            Content = "This is a dialog with buttons.",
            Buttons = {
                { Text = "OK", Primary = true, ReturnValue = true },
                { Text = "Cancel", ReturnValue = false },
            },
            Callback = function(result)
                print("Dialog result:", result)
            end,
        })
    end,
})

demoSection:AddButton({
    Name = "Show Input Dialog",
    Icon = "lucide:pen-line",
    Callback = function()
        Window:InputDialog({
            Title = "Input Dialog",
            Content = "Enter your name:",
            Inputs = {
                {
                    Name = "Name",
                    Placeholder = "Your name",
                    Default = "Player",
                },
            },
            Callback = function(values)
                print("Input result:", values.Name)
                Window:Notify({
                    Title = "Hello",
                    Content = "Hello, " .. values.Name,
                    Duration = 3,
                })
            end,
        })
    end,
})

-- ============================================================
--  SCRIPT SELESAI
-- ============================================================
print("ModernV2 example script loaded successfully!")
