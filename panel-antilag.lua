-- =========================================================
-- Y-NEXUS • ANTI LAG PANEL
-- Professional UI + Close/Open button with stable IDs
-- =========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =========================================================
-- CONFIG
-- =========================================================

local GitHubLinks = {
    HapusBayangan = "https://raw.githubusercontent.com/bgamesid01-stack/saputrax/refs/heads/main/hapusbayangan.lua",
    UbahTexture   = "https://raw.githubusercontent.com/bgamesid01-stack/saputrax/refs/heads/main/textureplastic.lua",
    HapusPartikel = "https://raw.githubusercontent.com/bgamesid01-stack/saputrax/refs/heads/main/hapuspartikel.lua",
    HapusDecal = "https://raw.githubusercontent.com/bgamesid01-stack/saputrax/refs/heads/main/hapusdecal.lua"
}

local COLORS = {
    Background = Color3.fromRGB(15, 17, 23),
    Surface = Color3.fromRGB(23, 26, 34),
    Surface2 = Color3.fromRGB(30, 34, 44),
    Stroke = Color3.fromRGB(57, 64, 80),
    Text = Color3.fromRGB(242, 244, 248),
    Muted = Color3.fromRGB(155, 163, 178),
    Accent = Color3.fromRGB(91, 139, 255),
    AccentDark = Color3.fromRGB(63, 101, 205),
    Success = Color3.fromRGB(76, 210, 125),
    Warning = Color3.fromRGB(255, 193, 76),
    Error = Color3.fromRGB(255, 91, 91)
}

local TWEEN_FAST = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_NORMAL = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- =========================================================
-- SCREEN GUI
-- =========================================================

local oldGui = PlayerGui:FindFirstChild("YNexusAntiLag")
if oldGui then
    oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YNexusAntiLag"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = PlayerGui

-- =========================================================
-- OPEN BUTTON
-- ID / NAME: OpenAntiLagButton
-- Tombol ini tetap terlihat ketika panel ditutup.
-- =========================================================

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenAntiLagButton"
OpenButton:SetAttribute("ButtonID", "OPEN_ANTI_LAG")
OpenButton.Size = UDim2.fromOffset(52, 52)
OpenButton.Position = UDim2.new(0, 18, 0.5, -26)
OpenButton.BackgroundColor3 = COLORS.Surface
OpenButton.BorderSizePixel = 0
OpenButton.Text = "Y"
OpenButton.TextColor3 = COLORS.Text
OpenButton.TextSize = 21
OpenButton.Font = Enum.Font.GothamBold
OpenButton.AutoButtonColor = false
OpenButton.Visible = false
OpenButton.ZIndex = 999
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 14)
OpenCorner.Parent = OpenButton

local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = COLORS.Accent
OpenStroke.Thickness = 1.5
OpenStroke.Transparency = 0.15
OpenStroke.Parent = OpenButton

-- =========================================================
-- MAIN PANEL
-- =========================================================

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainAntiLagPanel"
MainFrame:SetAttribute("PanelID", "MAIN_ANTI_LAG_PANEL")
MainFrame.Size = UDim2.fromOffset(350, 330)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -165)
MainFrame.BackgroundColor3 = COLORS.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 5
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = COLORS.Stroke
MainStroke.Thickness = 1.2
MainStroke.Transparency = 0.15
MainStroke.Parent = MainFrame

-- =========================================================
-- HEADER
-- =========================================================

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 62)
Header.BackgroundColor3 = COLORS.Surface
Header.BorderSizePixel = 0
Header.ZIndex = 6
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 16)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Name = "HeaderBottomFix"
HeaderFix.Size = UDim2.new(1, 0, 0, 18)
HeaderFix.Position = UDim2.new(0, 0, 1, -18)
HeaderFix.BackgroundColor3 = COLORS.Surface
HeaderFix.BorderSizePixel = 0
HeaderFix.ZIndex = 6
HeaderFix.Parent = Header

local AccentLine = Instance.new("Frame")
AccentLine.Name = "AccentLine"
AccentLine.Size = UDim2.new(1, 0, 0, 2)
AccentLine.Position = UDim2.new(0, 0, 1, -2)
AccentLine.BackgroundColor3 = COLORS.Accent
AccentLine.BorderSizePixel = 0
AccentLine.ZIndex = 7
AccentLine.Parent = Header

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -80, 0, 25)
Title.Position = UDim2.fromOffset(16, 9)
Title.BackgroundTransparency = 1
Title.Text = "Y-NEXUS"
Title.TextColor3 = COLORS.Text
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 7
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Name = "Subtitle"
Subtitle.Size = UDim2.new(1, -80, 0, 18)
Subtitle.Position = UDim2.fromOffset(16, 32)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "ANTI-LAG  •  MULTI FEATURE"
Subtitle.TextColor3 = COLORS.Muted
Subtitle.TextSize = 9
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 7
Subtitle.Parent = Header

-- =========================================================
-- CLOSE BUTTON
-- ID / NAME: CloseAntiLagButton
-- =========================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseAntiLagButton"
CloseButton:SetAttribute("ButtonID", "CLOSE_ANTI_LAG")
CloseButton.Size = UDim2.fromOffset(34, 34)
CloseButton.Position = UDim2.new(1, -46, 0, 14)
CloseButton.BackgroundColor3 = COLORS.Surface2
CloseButton.BorderSizePixel = 0
CloseButton.Text = "×"
CloseButton.TextColor3 = COLORS.Muted
CloseButton.TextSize = 22
CloseButton.Font = Enum.Font.GothamMedium
CloseButton.AutoButtonColor = false
CloseButton.ZIndex = 8
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 10)
CloseCorner.Parent = CloseButton

local CloseStroke = Instance.new("UIStroke")
CloseStroke.Color = COLORS.Stroke
CloseStroke.Thickness = 1
CloseStroke.Parent = CloseButton

-- =========================================================
-- CONTENT
-- =========================================================

local Content = Instance.new("Frame")
Content.Name = "FeatureContainer"
Content.Size = UDim2.new(1, -28, 0, 190)
Content.Position = UDim2.fromOffset(14, 76)
Content.BackgroundTransparency = 1
Content.ZIndex = 6
Content.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 9)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

-- =========================================================
-- STATUS
-- =========================================================

local StatusBox = Instance.new("Frame")
StatusBox.Name = "StatusBox"
StatusBox.Size = UDim2.new(1, -28, 0, 45)
StatusBox.Position = UDim2.new(0, 14, 1, -59)
StatusBox.BackgroundColor3 = COLORS.Surface
StatusBox.BorderSizePixel = 0
StatusBox.ZIndex = 6
StatusBox.Parent = MainFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 10)
StatusCorner.Parent = StatusBox

local StatusIndicator = Instance.new("Frame")
StatusIndicator.Name = "StatusIndicator"
StatusIndicator.Size = UDim2.fromOffset(5, 25)
StatusIndicator.Position = UDim2.fromOffset(10, 10)
StatusIndicator.BackgroundColor3 = COLORS.Accent
StatusIndicator.BorderSizePixel = 0
StatusIndicator.ZIndex = 7
StatusIndicator.Parent = StatusBox

local IndicatorCorner = Instance.new("UICorner")
IndicatorCorner.CornerRadius = UDim.new(1, 0)
IndicatorCorner.Parent = StatusIndicator

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, -30, 1, 0)
StatusLabel.Position = UDim2.fromOffset(23, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Pilih fitur untuk mengoptimalkan tampilan."
StatusLabel.TextColor3 = COLORS.Muted
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.ZIndex = 7
StatusLabel.Parent = StatusBox

-- =========================================================
-- RUN GITHUB SCRIPT
-- =========================================================

local function setStatus(text, color)
    StatusLabel.Text = text
    StatusLabel.TextColor3 = color
    StatusIndicator.BackgroundColor3 = color
end

local function runGithubScript(url, featureName)
    setStatus("Memuat • " .. featureName, COLORS.Warning)

    local success, content = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        setStatus("Gagal mengunduh • " .. featureName, COLORS.Error)
        return
    end

    local loadedScript, err = loadstring(content)

    if not loadedScript then
        setStatus("Error script • " .. tostring(err), COLORS.Error)
        return
    end

    local executed, executeError = pcall(loadedScript)

    if executed then
        setStatus("Berhasil • " .. featureName, COLORS.Success)
    else
        setStatus("Error saat menjalankan • " .. tostring(executeError), COLORS.Error)
    end
end

-- =========================================================
-- CREATE FEATURE BUTTON
-- =========================================================

local function createButton(buttonId, text, githubUrl, featureName, icon)
    local Button = Instance.new("TextButton")
    Button.Name = buttonId
    Button:SetAttribute("ButtonID", buttonId)
    Button.Size = UDim2.new(1, 0, 0, 54)
    Button.BackgroundColor3 = COLORS.Surface
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.LayoutOrder = #Content:GetChildren() + 1
    Button.ZIndex = 7
    Button.Parent = Content

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 11)
    Corner.Parent = Button

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = COLORS.Stroke
    Stroke.Thickness = 1
    Stroke.Transparency = 0.25
    Stroke.Parent = Button

    local Icon = Instance.new("TextLabel")
    Icon.Name = "Icon"
    Icon.Size = UDim2.fromOffset(34, 34)
    Icon.Position = UDim2.fromOffset(10, 10)
    Icon.BackgroundColor3 = COLORS.Surface2
    Icon.BorderSizePixel = 0
    Icon.Text = icon
    Icon.TextColor3 = COLORS.Text
    Icon.TextSize = 15
    Icon.Font = Enum.Font.GothamBold
    Icon.ZIndex = 8
    Icon.Parent = Button

    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 9)
    IconCorner.Parent = Icon

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Name = "FeatureName"
    NameLabel.Size = UDim2.new(1, -65, 0, 22)
    NameLabel.Position = UDim2.fromOffset(55, 7)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = text
    NameLabel.TextColor3 = COLORS.Text
    NameLabel.TextSize = 11
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.ZIndex = 8
    NameLabel.Parent = Button

    local DescLabel = Instance.new("TextLabel")
    DescLabel.Name = "Description"
    DescLabel.Size = UDim2.new(1, -65, 0, 17)
    DescLabel.Position = UDim2.fromOffset(55, 29)
    DescLabel.BackgroundTransparency = 1
    DescLabel.Text = "Aktifkan fitur ini"
    DescLabel.TextColor3 = COLORS.Muted
    DescLabel.TextSize = 9
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.ZIndex = 8
    DescLabel.Parent = Button

    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TWEEN_FAST, {
            BackgroundColor3 = COLORS.Surface2
        }):Play()
        TweenService:Create(Stroke, TWEEN_FAST, {
            Color = COLORS.Accent,
            Transparency = 0
        }):Play()
    end)

    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TWEEN_FAST, {
            BackgroundColor3 = COLORS.Surface
        }):Play()
        TweenService:Create(Stroke, TWEEN_FAST, {
            Color = COLORS.Stroke,
            Transparency = 0.25
        }):Play()
    end)

    Button.MouseButton1Click:Connect(function()
        runGithubScript(githubUrl, featureName)
    end)

    return Button
end

createButton(
    "RemoveShadowButton",
    "Hapus Bayangan",
    GitHubLinks.HapusBayangan,
    "Hapus Bayangan",
    "◈"
)

createButton(
    "SmoothPlasticButton",
    "Smooth Plastic",
    GitHubLinks.UbahTexture,
    "Smooth Plastic",
    "◆"
)

createButton(
    "RemoveParticlesButton",
    "Hapus Partikel & Efek",
    GitHubLinks.HapusPartikel,
    "Hapus Partikel & Efek",
    "✦"
)

createButton(
    "RemoveDecalButton",
    "Hapus Decal",
    GitHubLinks.HapusDecal,
    "Hapus Decal",
    "✦"
)
-- =========================================================
-- OPEN / CLOSE SYSTEM
-- =========================================================

local panelOpen = true

local function openPanel()
    if panelOpen then return end
    panelOpen = true

    MainFrame.Visible = true
    MainFrame.Size = UDim2.fromOffset(330, 310)
    MainFrame.Position = UDim2.new(0.5, -165, 0.5, -155)

    TweenService:Create(MainFrame, TWEEN_NORMAL, {
        Size = UDim2.fromOffset(350, 330),
        Position = UDim2.new(0.5, -175, 0.5, -165)
    }):Play()

    OpenButton.Visible = false
end

local function closePanel()
    if not panelOpen then return end
    panelOpen = false

    local tween = TweenService:Create(MainFrame, TWEEN_NORMAL, {
        Size = UDim2.fromOffset(0, 0)
    })

    tween:Play()
    tween.Completed:Connect(function()
        if not panelOpen then
            MainFrame.Visible = false
            OpenButton.Visible = true
        end
    end)
end

CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TWEEN_FAST, {
        BackgroundColor3 = COLORS.Error,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    }):Play()
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TWEEN_FAST, {
        BackgroundColor3 = COLORS.Surface2,
        TextColor3 = COLORS.Muted
    }):Play()
end)

OpenButton.MouseEnter:Connect(function()
    TweenService:Create(OpenButton, TWEEN_FAST, {
        BackgroundColor3 = COLORS.Surface2,
        Size = UDim2.fromOffset(56, 56)
    }):Play()
end)

OpenButton.MouseLeave:Connect(function()
    TweenService:Create(OpenButton, TWEEN_FAST, {
        BackgroundColor3 = COLORS.Surface,
        Size = UDim2.fromOffset(52, 52)
    }):Play()
end)

CloseButton.MouseButton1Click:Connect(closePanel)
OpenButton.MouseButton1Click:Connect(openPanel)

-- =========================================================
-- FINAL
-- =========================================================

setStatus("Ready • Pilih fitur yang ingin digunakan.", COLORS.Accent)
