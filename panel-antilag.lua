--============================================================
--   SCRIPT HUB — Premium UI (Single-file Luau)
--   Dark • Minimalist • Modern • Mobile-friendly
--============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--============================================================
--   ⚙️  CONFIG — Cukup ubah bagian ini saja
--============================================================
local HUB_TITLE    = "SCRIPT HUB"
local HUB_SUBTITLE = "Universal Script Loader"

-- Nama folder ModuleScript opsional (fallback di Studio / Roblox biasa)
-- Taruh folder ini di ReplicatedStorage atau ServerScriptService
local MODULE_FOLDER_NAME = "ScriptHubModules"

local Scripts = {
    {
        Name = "SCRIPT ONE",
        Description = "Short description of the script",
        URL = "https://example.com/script1.lua"
    },
    {
        Name = "SCRIPT TWO",
        Description = "Short description of the script",
        URL = "https://example.com/script2.lua"
    },
    {
        Name = "SCRIPT THREE",
        Description = "Short description of the script",
        URL = "https://example.com/script3.lua"
    },
}
--============================================================

-- Palet warna
local C = {
    Background = Color3.fromHex("111318"),
    Panel      = Color3.fromHex("181B22"),
    PanelAlt   = Color3.fromHex("20242D"),
    PanelHi    = Color3.fromHex("2A2F3A"),
    Accent     = Color3.fromHex("6C5CE7"),
    AccentSoft = Color3.fromHex("8B7EF0"),
    Text       = Color3.fromHex("FFFFFF"),
    TextMuted  = Color3.fromHex("8A8F98"),
    Border     = Color3.fromHex("262B35"),
    Success    = Color3.fromHex("3DD68C"),
    Warning    = Color3.fromHex("F5B544"),
    Danger     = Color3.fromHex("EF5350"),
}

local cam = workspace.CurrentCamera
local viewport = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
local IS_COMPACT = viewport.X < 760

-- Bersihkan versi lama
for _, g in ipairs(PlayerGui:GetChildren()) do
    if g:IsA("ScreenGui") and g.Name == "PremiumScriptHub" then
        g:Destroy()
    end
end

--============================================================
--   Helpers
--============================================================
local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

local function corner(parent, r)
    return create("UICorner", {CornerRadius = UDim.new(0, r or 8), Parent = parent})
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or C.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.4,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function tween(inst, time, props, style, dir)
    local info = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function makeDraggable(target, onTap)
    local dragging, dragged, startPos, startInput = false, false, nil, nil

    target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragged = false
            startInput = input.Position
            startPos = target.Position
        end
    end)

    target.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - startInput
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
                dragged = true
            end
            if dragged then
                target.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if not dragged and onTap then onTap() end
        end
    end)
end

--============================================================
--   Root GUI
--============================================================
local gui = create("ScreenGui", {
    Name = "PremiumScriptHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 100,
    Parent = PlayerGui,
})

--============================================================
--   Main Panel
--============================================================
local panelW = IS_COMPACT and UDim.new(1, -24) or UDim.new(0, 640)
local panelH = IS_COMPACT and UDim.new(1, -120) or UDim.new(0, 420)

local main = create("Frame", {
    Name = "Main",
    Size = UDim2.new(panelW.Scale, panelW.Offset, panelH.Scale, panelH.Offset),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = gui,
})
corner(main, 14)
stroke(main, C.Border, 1, 0.25)

create("UISizeConstraint", {
    MaxSize = Vector2.new(720, 460),
    MinSize = Vector2.new(300, 320),
    Parent = main,
})

local uiScale = create("UIScale", {Scale = 1, Parent = main})

--============================================================
--   Header
--============================================================
local HEADER_H = 58
local STATUS_H = 28

local header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, HEADER_H),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    Parent = main,
})

create("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = C.Border,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    Parent = header,
})

local accentBar = create("Frame", {
    Size = UDim2.new(0, 3, 0, 22),
    Position = UDim2.new(0, 16, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = C.Accent,
    BorderSizePixel = 0,
    Parent = header,
})
corner(accentBar, 2)

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 30, 0, 12),
    Size = UDim2.new(1, -160, 0, 16),
    Font = Enum.Font.GothamBold,
    Text = HUB_TITLE,
    TextColor3 = C.Text,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = header,
})

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 30, 0, 30),
    Size = UDim2.new(1, -160, 0, 14),
    Font = Enum.Font.Gotham,
    Text = HUB_SUBTITLE,
    TextColor3 = C.TextMuted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = header,
})

-- Tombol header (Minimize / Close)
local function headerButton(symbol, xOffset)
    local btn = create("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, xOffset, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = C.PanelAlt,
        BackgroundTransparency = 0.15,
        Text = symbol,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = C.TextMuted,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = header,
    })
    corner(btn, 7)
    stroke(btn, C.Border, 1, 0.4)

    btn.MouseEnter:Connect(function()
        tween(btn, 0.15, {BackgroundColor3 = C.PanelHi, TextColor3 = C.Text})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.15, {BackgroundColor3 = C.PanelAlt, TextColor3 = C.TextMuted})
    end)
    return btn
end

local closeBtn    = headerButton("×", -12)
local minimizeBtn = headerButton("—", -46)

--============================================================
--   Body
--============================================================
local body = create("Frame", {
    Name = "Body",
    Size = UDim2.new(1, 0, 1, -(HEADER_H + STATUS_H)),
    Position = UDim2.new(0, 0, 0, HEADER_H),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    Parent = main,
})

-- Sidebar
local SIDEBAR_W = IS_COMPACT and 78 or 148
local sidebar = create("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, SIDEBAR_W, 1, 0),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    Parent = body,
})

create("Frame", {
    Size = UDim2.new(0, 1, 1, 0),
    Position = UDim2.new(1, -1, 0, 0),
    BackgroundColor3 = C.Border,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    Parent = sidebar,
})

create("UIPadding", {
    PaddingTop = UDim.new(0, 10),
    PaddingBottom = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    Parent = sidebar,
})

create("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = sidebar,
})

-- Content
local content = create("Frame", {
    Name = "Content",
    Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
    Position = UDim2.new(0, SIDEBAR_W, 0, 0),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    Parent = body,
})

--============================================================
--   Status Bar
--============================================================
local statusBar = create("Frame", {
    Name = "StatusBar",
    Size = UDim2.new(1, 0, 0, STATUS_H),
    Position = UDim2.new(0, 0, 1, -STATUS_H),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    Parent = main,
})

create("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = C.Border,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    Parent = statusBar,
})

local statusDot = create("Frame", {
    Size = UDim2.new(0, 7, 0, 7),
    Position = UDim2.new(0, 16, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = C.Success,
    BorderSizePixel = 0,
    Parent = statusBar,
})
corner(statusDot, 4)

local statusLabel = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 30, 0, 0),
    Size = UDim2.new(1, -40, 1, 0),
    Font = Enum.Font.GothamMedium,
    Text = "Ready",
    TextColor3 = C.TextMuted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = statusBar,
})

local function setStatus(text, color)
    statusLabel.Text = text
    tween(statusDot, 0.2, {BackgroundColor3 = color})
end

--============================================================
--   Tabs + Pages
--============================================================
local tabs, pages = {}, {}
local activeTab = nil

local function createPage(name)
    local p = create("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = content,
    })
    pages[name] = p
    return p
end

local function createTab(name, label, order)
    local tab = create("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = C.PanelAlt,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    corner(tab, 8)

    local acc = create("Frame", {
        Size = UDim2.new(0, 3, 0, 16),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Parent = tab,
    })
    corner(acc, 2)

    local lbl = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, IS_COMPACT and 2 or 14, 0, 0),
        Size = UDim2.new(1, IS_COMPACT and -4 or -14, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = label,
        TextColor3 = C.TextMuted,
        TextSize = IS_COMPACT and 10 or 12,
        TextXAlignment = IS_COMPACT and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
        Parent = tab,
    })

    tabs[name] = {button = tab, accent = acc, label = lbl}

    tab.MouseEnter:Connect(function()
        if activeTab ~= name then
            tween(tab, 0.15, {BackgroundTransparency = 0.7})
        end
    end)
    tab.MouseLeave:Connect(function()
        if activeTab ~= name then
            tween(tab, 0.15, {BackgroundTransparency = 1})
        end
    end)

    return tab
end

local function selectTab(name)
    if activeTab == name then return end
    activeTab = name
    for n, t in pairs(tabs) do
        local on = (n == name)
        tween(t.accent, 0.18, {BackgroundTransparency = on and 0 or 1})
        tween(t.label, 0.18, {TextColor3 = on and C.Text or C.TextMuted})
        tween(t.button, 0.18, {BackgroundTransparency = on and 0.55 or 1})
    end
    for n, p in pairs(pages) do
        p.Visible = (n == name)
    end
end

-- Buat tabs
local homeTab     = createTab("HOME",     "HOME",     1)
local scriptsTab  = createTab("SCRIPTS",  "SCRIPTS",  2)
local settingsTab = createTab("SETTINGS", "SETTINGS", 3)

homeTab.MouseButton1Click:Connect(function() selectTab("HOME") end)
scriptsTab.MouseButton1Click:Connect(function() selectTab("SCRIPTS") end)
settingsTab.MouseButton1Click:Connect(function() selectTab("SETTINGS") end)

--============================================================
--   HOME Page
--============================================================
local homePage = createPage("HOME")

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 22, 0, 22),
    Size = UDim2.new(1, -44, 0, 22),
    Font = Enum.Font.GothamBold,
    Text = "Welcome",
    TextColor3 = C.Text,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = homePage,
})

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 22, 0, 50),
    Size = UDim2.new(1, -44, 0, 60),
    Font = Enum.Font.Gotham,
    Text = "Buka tab SCRIPTS untuk melihat daftar script. Tekan LOAD pada sebuah card untuk menjalankannya. Kamu bisa memindahkan panel ini dengan men-drag header.",
    TextColor3 = C.TextMuted,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    Parent = homePage,
})

local infoBox = create("Frame", {
    Position = UDim2.new(0, 22, 0, 118),
    Size = UDim2.new(1, -44, 0, 70),
    BackgroundColor3 = C.PanelAlt,
    BorderSizePixel = 0,
    Parent = homePage,
})
corner(infoBox, 10)
stroke(infoBox, C.Border, 1, 0.4)

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 14, 0, 12),
    Size = UDim2.new(1, -28, 0, 14),
    Font = Enum.Font.GothamBold,
    Text = "QUICK TIPS",
    TextColor3 = C.AccentSoft,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = infoBox,
})

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 14, 0, 30),
    Size = UDim2.new(1, -28, 0, 30),
    Font = Enum.Font.Gotham,
    Text = "• Drag header untuk memindahkan panel\n• Tekan × untuk close, ◈ untuk reopen",
    TextColor3 = C.TextMuted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    Parent = infoBox,
})

--============================================================
--   SCRIPTS Page
--============================================================
local scriptsPage = createPage("SCRIPTS")

local scroll = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.Border,
    ScrollBarImageTransparency = 0.3,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    Parent = scriptsPage,
})

create("UIPadding", {
    PaddingTop = UDim.new(0, 14),
    PaddingBottom = UDim.new(0, 14),
    PaddingLeft = UDim.new(0, 14),
    PaddingRight = UDim.new(0, 14),
    Parent = scroll,
})

create("UIListLayout", {
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = scroll,
})

--============================================================
--   SETTINGS Page
--============================================================
local settingsPage = createPage("SETTINGS")

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 22, 0, 22),
    Size = UDim2.new(1, -44, 0, 22),
    Font = Enum.Font.GothamBold,
    Text = "Settings",
    TextColor3 = C.Text,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = settingsPage,
})

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 22, 0, 50),
    Size = UDim2.new(1, -44, 0, 40),
    Font = Enum.Font.Gotham,
    Text = "Tidak ada opsi tambahan saat ini. Konfigurasi script dan tampilan diatur langsung dari script utama.",
    TextColor3 = C.TextMuted,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    Parent = settingsPage,
})

--============================================================
--   Notifications
--============================================================
local notifHolder = create("Frame", {
    Name = "Notifications",
    Size = UDim2.new(0, 280, 0, 380),
    Position = UDim2.new(1, -16, 0, 16),
    AnchorPoint = Vector2.new(1, 0),
    BackgroundTransparency = 1,
    Parent = gui,
})

create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    Parent = notifHolder,
})

local notifOrder = 0
local function notify(message, kind)
    kind = kind or "info"
    local accent = (kind == "success" and C.Success)
        or (kind == "error" and C.Danger)
        or C.Accent

    notifOrder = notifOrder + 1

    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 54),
        Position = UDim2.new(0, 300, 0, 0),
        BackgroundColor3 = C.PanelAlt,
        BorderSizePixel = 0,
        LayoutOrder = notifOrder,
        Parent = notifHolder,
    })
    corner(card, 10)
    stroke(card, C.Border, 1, 0.4)

    local bar = create("Frame", {
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Parent = card,
    })
    corner(bar, 2)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 9),
        Size = UDim2.new(1, -24, 0, 12),
        Font = Enum.Font.GothamBold,
        Text = kind == "success" and "SUCCESS" or kind == "error" and "ERROR" or "INFO",
        TextColor3 = accent,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local bodyLbl = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 26),
        Size = UDim2.new(1, -24, 0, 20),
        Font = Enum.Font.Gotham,
        Text = message,
        TextColor3 = C.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = card,
    })

    tween(card, 0.35, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    task.delay(3.5, function()
        if not card.Parent then return end
        local t = tween(card, 0.3, {
            Position = UDim2.new(1, 20, 0, 0),
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(bar, 0.3, {BackgroundTransparency = 1})
        tween(bodyLbl, 0.3, {TextTransparency = 1})
        t.Completed:Connect(function() card:Destroy() end)
    end)
end

--============================================================
--   Loader
--============================================================
local function resolveModule(name)
    local containers = {
        game:GetService("ReplicatedStorage"):FindFirstChild(MODULE_FOLDER_NAME),
        game:GetService("ServerScriptService"):FindFirstChild(MODULE_FOLDER_NAME),
        game:GetService("StarterPlayer"):FindFirstChild(MODULE_FOLDER_NAME),
    }
    for _, c in ipairs(containers) do
        if c then
            local m = c:FindFirstChild(name)
            if m and m:IsA("ModuleScript") then return m end
        end
    end
    return nil
end

local function attemptLoad(entry)
    -- 1) Executor API path
    local loadstringFn = rawget(_G, "loadstring")
    local HttpGetFn = rawget(_G, "HttpGet")
        or (rawget(_G, "game") and nil)
        or (getgenv and getgenv().HttpGet)
        or (syn and syn.request)
        or (http and http.request)

    if loadstringFn and HttpGetFn then
        local ok, res = pcall(function()
            if type(HttpGetFn) == "function" and HttpGetFn ~= (syn and syn.request) then
                return HttpGetFn(entry.URL)
            elseif syn and syn.request then
                local r = syn.request({Url = entry.URL, Method = "GET"})
                return r and r.Body
            elseif http and http.request then
                local r = http.request({Url = entry.URL, Method = "GET"})
                return r and r.Body
            end
        end)
        if ok and type(res) == "string" then
            local fn, err = loadstringFn(res)
            if fn then
                local ok2, err2 = pcall(fn)
                if ok2 then return true end
                return false, tostring(err2)
            end
            return false, tostring(err)
        end
    end

    -- 2) ModuleScript fallback
    local mod = resolveModule(entry.Name)
    if mod then
        local ok, err = pcall(require, mod)
        if ok then return true end
        return false, tostring(err)
    end

    return false, "No executor API and no ModuleScript fallback available"
end

--============================================================
--   Script Cards
--============================================================
local function createScriptCard(entry, order)
    local card = create("Frame", {
        Name = entry.Name,
        Size = UDim2.new(1, 0, 0, 88),
        BackgroundColor3 = C.PanelAlt,
        BorderSizePixel = 0,
        LayoutOrder = order,
        Parent = scroll,
    })
    corner(card, 10)
    stroke(card, C.Border, 1, 0.4)

    create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        Parent = card,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, -92, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = entry.Name,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, -92, 0, 26),
        Font = Enum.Font.Gotham,
        Text = entry.Description,
        TextColor3 = C.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = card,
    })

    local dot = create("Frame", {
        Size = UDim2.new(0, 6, 0, 6),
        Position = UDim2.new(0, 0, 1, -6),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = C.TextMuted,
        BorderSizePixel = 0,
        Parent = card,
    })
    corner(dot, 3)

    local statLbl = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 1, -6),
        Size = UDim2.new(0, 100, 0, 14),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.GothamMedium,
        Text = "Ready",
        TextColor3 = C.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local loadBtn = create("TextButton", {
        Size = UDim2.new(0, 76, 0, 32),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = C.Accent,
        Text = "LOAD",
        Font = Enum.Font.GothamBold,
        TextColor3 = C.Text,
        TextSize = 11,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = card,
    })
    corner(loadBtn, 8)

    loadBtn.MouseEnter:Connect(function()
        if not loadBtn:GetAttribute("Loading") then
            tween(loadBtn, 0.15, {BackgroundColor3 = C.AccentSoft})
        end
    end)
    loadBtn.MouseLeave:Connect(function()
        if not loadBtn:GetAttribute("Loading") then
            tween(loadBtn, 0.15, {BackgroundColor3 = C.Accent})
        end
    end)

    card.MouseEnter:Connect(function()
        tween(card, 0.15, {BackgroundColor3 = C.PanelHi})
    end)
    card.MouseLeave:Connect(function()
        tween(card, 0.15, {BackgroundColor3 = C.PanelAlt})
    end)

    local function pressAnim()
        local s = loadBtn.Size
        tween(loadBtn, 0.08, {Size = UDim2.new(s.X.Scale, s.X.Offset - 6, s.Y.Scale, s.Y.Offset - 4)})
        task.wait(0.08)
        tween(loadBtn, 0.08, {Size = s})
    end

    loadBtn.MouseButton1Click:Connect(function()
        if loadBtn:GetAttribute("Loading") then return end
        loadBtn:SetAttribute("Loading", true)

        pressAnim()

        loadBtn.Text = "LOADING..."
        loadBtn.TextSize = 10
        loadBtn.BackgroundColor3 = C.PanelHi
        loadBtn.TextColor3 = C.TextMuted

        dot.BackgroundColor3 = C.Warning
        statLbl.Text = "Loading..."
        setStatus("Loading...", C.Warning)

        task.spawn(function()
            local ok, err = attemptLoad(entry)

            loadBtn:SetAttribute("Loading", false)
            loadBtn.Text = "LOAD"
            loadBtn.TextSize = 11
            loadBtn.BackgroundColor3 = C.Accent
            loadBtn.TextColor3 = C.Text

            if ok then
                dot.BackgroundColor3 = C.Success
                statLbl.Text = "Loaded"
                setStatus("Loaded", C.Success)
                notify(entry.Name .. " loaded successfully", "success")
            else
                dot.BackgroundColor3 = C.Danger
                statLbl.Text = "Failed"
                setStatus("Failed", C.Danger)
                notify("Failed: " .. tostring(err), "error")
            end
        end)
    end)

    return card
end

for i, entry in ipairs(Scripts) do
    createScriptCard(entry, i)
end

--============================================================
--   Reopen Button (floating, draggable)
--============================================================
local reopen = create("Frame", {
    Name = "ReopenButton",
    Size = UDim2.new(0, 46, 0, 46),
    Position = UDim2.new(0, 18, 0.5, 0),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    Visible = false,
    Parent = gui,
})
corner(reopen, 12)
stroke(reopen, C.Border, 1, 0.3)

create("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = "◈",
    TextColor3 = C.AccentSoft,
    TextSize = 22,
    Parent = reopen,
})

local function showMain()
    reopen.Visible = false
    main.Visible = true
    uiScale.Scale = 0.86
    tween(uiScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function hideMain()
    tween(uiScale, 0.2, {Scale = 0.86}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    task.delay(0.2, function()
        main.Visible = false
        reopen.Visible = true
        local s = UDim2.new(0, 0, 0, 0)
        reopen.Size = s
        tween(reopen, 0.28, {Size = UDim2.new(0, 46, 0, 46)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
end

makeDraggable(reopen, showMain)

--============================================================
--   Wire up buttons
--============================================================
local function isOverAnyButton(input, list)
    local p = input.Position
    for _, b in ipairs(list) do
        local ap = b.AbsolutePosition
        local as = b.AbsoluteSize
        if p.X >= ap.X and p.X <= ap.X + as.X
        and p.Y >= ap.Y and p.Y <= ap.Y + as.Y then
            return true
        end
    end
    return false
end

-- Drag header (lewati tombol)
do
    local dragging, startPos, startInput = false, nil, nil

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if isOverAnyButton(input, {closeBtn, minimizeBtn}) then return end
            dragging = true
            startInput = input.Position
            startPos = main.Position
        end
    end)

    header.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - startInput
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

minimizeBtn.MouseButton1Click:Connect(function()
    hideMain()
    notify("Hub minimized", "info")
end)

closeBtn.MouseButton1Click:Connect(function()
    hideMain()
    notify("Hub closed — tap ◈ to reopen", "info")
end)

--============================================================
--   Boot
--============================================================
selectTab("SCRIPTS")

-- Animasi masuk pertama
main.Visible = true
uiScale.Scale = 0.88
tween(uiScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

setStatus("Ready", C.Success)
task.delay(0.6, function()
    notify("Script Hub loaded", "success")
end)