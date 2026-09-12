-- =========================================================
-- UI ANTI-LAG MULTI-FITUR (LINK GITHUB BERBEDA TIAP TOMBOL)
-- =========================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 1. DAFTAR LINK GITHUB UNTUK MASING-MASING FITUR
-- Ganti link di bawah ini dengan link Raw GitHub milikmu
local GitHubLinks = {
    HapusBayangan = "https://raw.githubusercontent.com/bgamesid01-stack/saputrax/refs/heads/main/hapusbayangan.lua",
    UbahTexture    = "https://raw.githubusercontent.com/bgamesid01-stack/saputrax/refs/heads/main/textureplastic.lua",
    HapusPartikel  = "https://raw.githubusercontent.com/bgamesid01-stack/saputrax/refs/heads/main/hapuspartikel.lua"
}

-- 2. TAMPILAN GUI
-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiLagMultiFeature"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 280)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Corner
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Soft Border / Stroke
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 80)
UIStroke.Thickness = 1.5
UIStroke.Transparency = 0.3
UIStroke.Parent = MainFrame

-- Shadow effect (optional, menggunakan frame di belakang)
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.Position = UDim2.new(0.5, 0, 0.5, 6)
Shadow.Size = UDim2.new(1, 30, 1, 30)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://1316045217" -- soft shadow
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.6
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
Shadow.ZIndex = 0
Shadow.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

-- Biar sudut bawah TitleBar tetap runcing
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 15)
TitleFix.Position = UDim2.new(0, 0, 1, -15)
TitleFix.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

-- Title Text
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Y-Nexus  •  Anti Lag"
Title.TextColor3 = Color3.fromRGB(240, 240, 255)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Accent Line di bawah title
local Accent = Instance.new("Frame")
Accent.Name = "Accent"
Accent.Size = UDim2.new(1, 0, 0, 2)
Accent.Position = UDim2.new(0, 0, 1, -2)
Accent.BackgroundColor3 = Color3.fromRGB(100, 140, 255) -- biru soft
Accent.BorderSizePixel = 0
Accent.Parent = TitleBar

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 25)
StatusLabel.Position = UDim2.new(0, 10, 1, -30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Pilih fitur yang ingin diaktifkan..."
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = MainFrame

-- 3. FUNGSI UNTUK MENJALANKAN SCRIPT DARI GITHUB
local function runGithubScript(url, featureName)
    StatusLabel.Text = "⏳ Memuat: " .. featureName .. "..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 220, 85)

    local success, content = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local loadedScript, err = loadstring(content)
        if loadedScript then
            pcall(loadedScript)
            StatusLabel.Text = "✅ " .. featureName .. " Berhasil!"
            StatusLabel.TextColor3 = Color3.fromRGB(85, 255, 120)
        else
            StatusLabel.Text = "❌ Error Script: " .. tostring(err)
            StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
        end
    else
        StatusLabel.Text = "❌ Gagal mengunduh dari GitHub!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
    end
end

-- 4. PEMBUATAN TOMBOL FITUR
local function createButton(text, posY, githubUrl, featureName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -30, 0, 38)
    btn.Position = UDim2.new(0, 15, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        runGithubScript(githubUrl, featureName)
    end)
end

-- Menambahkan tombol-tombol dengan link GitHub yang berbeda
createButton("🚫 Hapus Bayangan", 50, GitHubLinks.HapusBayangan, "Fitur Hapus Bayangan")
createButton("🧱 Ubah Ke Smooth Plastic", 100, GitHubLinks.UbahTexture, "Fitur Texture Plastic")
createButton("💥 Hapus Partikel & Efek", 150, GitHubLinks.HapusPartikel, "Fitur Hapus Partikel")
