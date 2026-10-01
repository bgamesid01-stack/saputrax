--[[
    SCRIPT HUB - Modern Universal Script Loader
    Single LocalScript - Creates entire GUI automatically
    Compatible with Roblox Studio (HttpService ON) & most executors
]]

--============================================================
-- KONFIGURASI SCRIPT (EDIT BAGIAN INI SAJA)
--============================================================
local Scripts = {
	{
		Name = "SCRIPT ONE",
		Description = "Basic utility script",
		URL = "https://raw.githubusercontent.com/example/script1.lua"
	},
	{
		Name = "SCRIPT TWO",
		Description = "Advanced features",
		URL = "https://raw.githubusercontent.com/example/script2.lua"
	},
	{
		Name = "SCRIPT THREE",
		Description = "ESP & visuals",
		URL = "https://raw.githubusercontent.com/example/script3.lua"
	},
	{
		Name = "SCRIPT FOUR",
		Description = "Misc tools",
		URL = "https://raw.githubusercontent.com/example/script4.lua"
	},
}

--============================================================
-- SERVICES & VARIABLES
--============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Cleanup previous instance
local existing = PlayerGui:FindFirstChild("ScriptHub")
if existing then existing:Destroy() end

--============================================================
-- THEME
--============================================================
local Theme = {
	Background = Color3.fromRGB(18, 18, 22),
	Secondary = Color3.fromRGB(28, 28, 34),
	Accent = Color3.fromRGB(0, 170, 255),       -- Neon Blue
	AccentHover = Color3.fromRGB(0, 200, 255),
	Text = Color3.fromRGB(240, 240, 245),
	TextDim = Color3.fromRGB(160, 160, 170),
	Success = Color3.fromRGB(50, 220, 120),
	Error = Color3.fromRGB(255, 70, 70),
	Stroke = Color3.fromRGB(50, 50, 60),
}

--============================================================
-- UTILITY
--============================================================
local function Create(class, props)
	local obj = Instance.new(class)
	for k, v in pairs(props) do
		obj[k] = v
	end
	return obj
end

local function Tween(obj, props, duration, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

--============================================================
-- MAIN GUI
--============================================================
local ScreenGui = Create("ScreenGui", {
	Name = "ScriptHub",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = PlayerGui
})

-- Main Frame
local MainFrame = Create("Frame", {
	Name = "Main",
	Size = UDim2.new(0, 340, 0, 420),
	Position = UDim2.new(0.5, -170, 0.5, -210),
	BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = ScreenGui
})

Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = MainFrame})
Create("UIStroke", {Color = Theme.Stroke, Thickness = 1.5, Transparency = 0.3, Parent = MainFrame})

-- Soft shadow-like effect
local Shadow = Create("ImageLabel", {
	Name = "Shadow",
	Size = UDim2.new(1, 40, 1, 40),
	Position = UDim2.new(0, -20, 0, -20),
	BackgroundTransparency = 1,
	Image = "rbxassetid://6014261993",
	ImageColor3 = Color3.new(0, 0, 0),
	ImageTransparency = 0.6,
	ScaleType = Enum.ScaleType.Slice,
	SliceCenter = Rect.new(49, 49, 450, 450),
	ZIndex = 0,
	Parent = MainFrame
})

--============================================================
-- HEADER
--============================================================
local Header = Create("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 70),
	BackgroundColor3 = Theme.Secondary,
	BorderSizePixel = 0,
	Parent = MainFrame
})
Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = Header})

-- Fix bottom corners of header
local HeaderFix = Create("Frame", {
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 1, -20),
	BackgroundColor3 = Theme.Secondary,
	BorderSizePixel = 0,
	Parent = Header
})

local Title = Create("TextLabel", {
	Name = "Title",
	Size = UDim2.new(1, -80, 0, 28),
	Position = UDim2.new(0, 16, 0, 10),
	BackgroundTransparency = 1,
	Text = "SCRIPT HUB",
	TextColor3 = Theme.Text,
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = Header
})

local Subtitle = Create("TextLabel", {
	Name = "Subtitle",
	Size = UDim2.new(1, -80, 0, 18),
	Position = UDim2.new(0, 16, 0, 36),
	BackgroundTransparency = 1,
	Text = "Universal Script Loader",
	TextColor3 = Theme.TextDim,
	TextSize = 13,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = Header
})

-- Close Button
local CloseBtn = Create("TextButton", {
	Name = "Close",
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -40, 0, 12),
	BackgroundColor3 = Color3.fromRGB(40, 40, 48),
	Text = "×",
	TextColor3 = Theme.Text,
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
	Parent = Header
})
Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = CloseBtn})

-- Minimize Button
local MinBtn = Create("TextButton", {
	Name = "Minimize",
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -74, 0, 12),
	BackgroundColor3 = Color3.fromRGB(40, 40, 48),
	Text = "–",
	TextColor3 = Theme.Text,
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
	Parent = Header
})
Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = MinBtn})

--============================================================
-- STATUS BAR
--============================================================
local StatusBar = Create("Frame", {
	Name = "StatusBar",
	Size = UDim2.new(1, -24, 0, 28),
	Position = UDim2.new(0, 12, 0, 78),
	BackgroundColor3 = Theme.Secondary,
	BorderSizePixel = 0,
	Parent = MainFrame
})
Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = StatusBar})

local StatusLabel = Create("TextLabel", {
	Name = "Status",
	Size = UDim2.new(1, -16, 1, 0),
	Position = UDim2.new(0, 12, 0, 0),
	BackgroundTransparency = 1,
	Text = "Status: Ready",
	TextColor3 = Theme.TextDim,
	TextSize = 13,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = StatusBar
})

local function SetStatus(text, color)
	StatusLabel.Text = "Status: " .. text
	StatusLabel.TextColor3 = color or Theme.TextDim
end

--============================================================
-- SCROLLING LIST
--============================================================
local Scroll = Create("ScrollingFrame", {
	Name = "ScriptList",
	Size = UDim2.new(1, -24, 1, -170),
	Position = UDim2.new(0, 12, 0, 116),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = Theme.Accent,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = MainFrame
})

local ListLayout = Create("UIListLayout", {
	Padding = UDim.new(0, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = Scroll
})

Create("UIPadding", {
	PaddingTop = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 4),
	Parent = Scroll
})

--============================================================
-- NOTIFICATION SYSTEM
--============================================================
local NotifContainer = Create("Frame", {
	Name = "Notifications",
	Size = UDim2.new(0, 280, 1, 0),
	Position = UDim2.new(1, -300, 0, 20),
	BackgroundTransparency = 1,
	Parent = ScreenGui
})

local NotifLayout = Create("UIListLayout", {
	Padding = UDim.new(0, 8),
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Parent = NotifContainer
})

local function Notify(message, isSuccess)
	local notif = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = Theme.Secondary,
		BorderSizePixel = 0,
		Parent = NotifContainer
	})
	Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = notif})
	Create("UIStroke", {
		Color = isSuccess and Theme.Success or Theme.Error,
		Thickness = 1.5,
		Parent = notif
	})

	local icon = Create("TextLabel", {
		Size = UDim2.new(0, 30, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		Text = isSuccess and "✓" or "✕",
		TextColor3 = isSuccess and Theme.Success or Theme.Error,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		Parent = notif
	})

	local msg = Create("TextLabel", {
		Size = UDim2.new(1, -50, 1, 0),
		Position = UDim2.new(0, 40, 0, 0),
		BackgroundTransparency = 1,
		Text = message,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = notif
	})

	notif.Position = UDim2.new(1, 20, 0, 0)
	Tween(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.35, Enum.EasingStyle.Back)

	task.delay(3.2, function()
		local tw = Tween(notif, {Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1}, 0.3)
		tw.Completed:Wait()
		notif:Destroy()
	end)
end

--============================================================
-- LOADER FUNCTION
--============================================================
local loadingFlags = {} -- anti double click

local function LoadScript(scriptData, button)
	if loadingFlags[scriptData.Name] then return end
	loadingFlags[scriptData.Name] = true

	button.Active = false
	SetStatus("Loading " .. scriptData.Name .. "...", Theme.Accent)

	local success, result = pcall(function()
		-- Prefer executor-style if available
		if syn and syn.request then
			local response = syn.request({Url = scriptData.URL, Method = "GET"})
			if response.StatusCode == 200 then
				return loadstring(response.Body)()
			else
				error("HTTP " .. tostring(response.StatusCode))
			end
		elseif http and http.request then
			local response = http.request({Url = scriptData.URL, Method = "GET"})
			return loadstring(response.Body)()
		elseif request then
			local response = request({Url = scriptData.URL, Method = "GET"})
			return loadstring(response.Body)()
		else
			-- Standard Roblox / Studio path
			local code = HttpService:GetAsync(scriptData.URL)
			return loadstring(code)()
		end
	end)

	if success then
		SetStatus("Loaded Successfully", Theme.Success)
		Notify("✓ " .. scriptData.Name .. " berhasil dimuat", true)
	else
		SetStatus("Failed to Load", Theme.Error)
		local errMsg = tostring(result)
		if #errMsg > 60 then errMsg = errMsg:sub(1, 57) .. "..." end
		Notify("✕ Gagal: " .. errMsg, false)
		warn("[ScriptHub] Load error for", scriptData.Name, ":", result)
	end

	button.Active = true
	loadingFlags[scriptData.Name] = false

	task.delay(2.5, function()
		if StatusLabel.Text:find("Loaded") or StatusLabel.Text:find("Failed") then
			SetStatus("Ready", Theme.TextDim)
		end
	end)
end

--============================================================
-- CREATE SCRIPT CARDS
--============================================================
for i, data in ipairs(Scripts) do
	local Card = Create("Frame", {
		Name = "Card_" .. i,
		Size = UDim2.new(1, -4, 0, 72),
		BackgroundColor3 = Theme.Secondary,
		BorderSizePixel = 0,
		LayoutOrder = i,
		Parent = Scroll
	})
	Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = Card})
	Create("UIStroke", {Color = Theme.Stroke, Thickness = 1, Transparency = 0.4, Parent = Card})

	local Number = Create("TextLabel", {
		Size = UDim2.new(0, 36, 0, 20),
		Position = UDim2.new(0, 12, 0, 10),
		BackgroundTransparency = 1,
		Text = string.format("%02d", i),
		TextColor3 = Theme.Accent,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		Parent = Card
	})

	local NameLabel = Create("TextLabel", {
		Size = UDim2.new(1, -120, 0, 20),
		Position = UDim2.new(0, 48, 0, 10),
		BackgroundTransparency = 1,
		Text = data.Name,
		TextColor3 = Theme.Text,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Card
	})

	local DescLabel = Create("TextLabel", {
		Size = UDim2.new(1, -120, 0, 18),
		Position = UDim2.new(0, 12, 0, 34),
		BackgroundTransparency = 1,
		Text = data.Description or "",
		TextColor3 = Theme.TextDim,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Card
	})

	local LoadBtn = Create("TextButton", {
		Name = "Load",
		Size = UDim2.new(0, 90, 0, 32),
		Position = UDim2.new(1, -102, 0.5, -16),
		BackgroundColor3 = Theme.Accent,
		Text = "Load Script",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Parent = Card
	})
	Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = LoadBtn})

	-- Hover & Press effects
	LoadBtn.MouseEnter:Connect(function()
		Tween(LoadBtn, {BackgroundColor3 = Theme.AccentHover}, 0.15)
	end)
	LoadBtn.MouseLeave:Connect(function()
		Tween(LoadBtn, {BackgroundColor3 = Theme.Accent}, 0.15)
	end)
	LoadBtn.MouseButton1Down:Connect(function()
		Tween(LoadBtn, {Size = UDim2.new(0, 86, 0, 30)}, 0.08)
	end)
	LoadBtn.MouseButton1Up:Connect(function()
		Tween(LoadBtn, {Size = UDim2.new(0, 90, 0, 32)}, 0.08)
	end)

	LoadBtn.MouseButton1Click:Connect(function()
		LoadScript(data, LoadBtn)
	end)
end

--============================================================
-- BOTTOM BUTTONS (Refresh + Close)
--============================================================
local BottomBar = Create("Frame", {
	Name = "BottomBar",
	Size = UDim2.new(1, -24, 0, 40),
	Position = UDim2.new(0, 12, 1, -52),
	BackgroundTransparency = 1,
	Parent = MainFrame
})

local RefreshBtn = Create("TextButton", {
	Name = "Refresh",
	Size = UDim2.new(0.48, -4, 1, 0),
	BackgroundColor3 = Theme.Secondary,
	Text = "Refresh",
	TextColor3 = Theme.Text,
	TextSize = 14,
	Font = Enum.Font.GothamMedium,
	BorderSizePixel = 0,
	Parent = BottomBar
})
Create("UICorner", {CornerRadius = UDim.new(0, 9), Parent = RefreshBtn})
Create("UIStroke", {Color = Theme.Stroke, Thickness = 1, Transparency = 0.4, Parent = RefreshBtn})

local CloseBottom = Create("TextButton", {
	Name = "CloseBottom",
	Size = UDim2.new(0.48, -4, 1, 0),
	Position = UDim2.new(0.52, 4, 0, 0),
	BackgroundColor3 = Color3.fromRGB(180, 50, 50),
	Text = "Close",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 14,
	Font = Enum.Font.GothamMedium,
	BorderSizePixel = 0,
	Parent = BottomBar
})
Create("UICorner", {CornerRadius = UDim.new(0, 9), Parent = CloseBottom})

RefreshBtn.MouseButton1Click:Connect(function()
	SetStatus("Ready", Theme.TextDim)
	Notify("List refreshed", true)
end)

--============================================================
-- CLOSE / MINIMIZE LOGIC
--============================================================
local isMinimized = false
local originalSize = MainFrame.Size

local function CloseHub()
	Tween(MainFrame, {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.wait(0.28)
	ScreenGui:Destroy()
end

CloseBtn.MouseButton1Click:Connect(CloseHub)
CloseBottom.MouseButton1Click:Connect(CloseHub)

MinBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		Tween(MainFrame, {Size = UDim2.new(0, 340, 0, 70)}, 0.3)
		Scroll.Visible = false
		StatusBar.Visible = false
		BottomBar.Visible = false
		MinBtn.Text = "+"
	else
		Tween(MainFrame, {Size = originalSize}, 0.3)
		Scroll.Visible = true
		StatusBar.Visible = true
		BottomBar.Visible = true
		MinBtn.Text = "–"
	end
end)

--============================================================
-- DRAGGING (PC) + TOUCH FRIENDLY
--============================================================
local dragging, dragInput, dragStart, startPos

local function Update(input)
	local delta = input.Position - dragStart
	MainFrame.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

Header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Header.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		Update(input)
	end
end)

--============================================================
-- OPEN ANIMATION
--============================================================
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

Tween(MainFrame, {
	Size = UDim2.new(0, 340, 0, 420),
	Position = UDim2.new(0.5, -170, 0.5, -210)
}, 0.4, Enum.EasingStyle.Back)

print("[ScriptHub] Loaded successfully")