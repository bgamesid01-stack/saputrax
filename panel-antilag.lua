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
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiLagMultiFeature"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 260)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "⚡ ANTI-LAG PANEL ⚡"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

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
