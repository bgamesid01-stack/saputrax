--============================================================
--  SCRIPT HUB — Premium UI (Single-file Luau)
--  Dark • Minimalist • Modern • Mobile & PC friendly
--============================================================

--============================================================
--  1. CONFIGURATION
--============================================================
local CONFIG = {
    Title       = "SCRIPT HUB",
    Subtitle    = "Universal Script Loader",

    -- Fallback ModuleScript folder (dipakai kalau executor API tidak tersedia)
    ModuleFolder = "ScriptHubModules",

    ReopenIconId = "rbxassetid://94897460093839", -- JANGAN DIUBAH

    Credits = {
        Developer     = "Your Name",
        UIDesign      = "Your Name",
        SpecialThanks = "Your Name",
    },
}

local Scripts = {
    {
        Name        = "SCRIPT ONE",
        Description = "Short description of this script",
        URL         = "https://example.com/script1.lua",
    },
    {
        Name        = "SCRIPT TWO",
        Description = "Short description of this script",
        URL         = "https://example.com/script2.lua",
    },
    {
        Name        = "SCRIPT THREE",
        Description = "Short description of this script",
        URL         = "https://example.com/script3.lua",
    },
}

--============================================================
--  2. SERVICES
--============================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--============================================================
--  3. UTILITY FUNCTIONS
--============================================================
local PALETTE = {
    Background = Color3.fromHex("111318"),
    Panel      = Color3.fromHex("181B22"),
    Secondary  = Color3.fromHex("20242D"),
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

local function create(className, props, children)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

local function corner(parent, radius)
    return create("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = parent})
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or PALETTE.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.4,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function tween(inst, duration, props, style, dir)
    local info = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

--============================================================
--  4. NOTIFICATION SYSTEM
--============================================================
local notifOrder = 0

local function buildNotifHolder(parent)
    local holder = create("Frame", {
        Name = "Notifications",
        Size = UDim2.new(0, 260, 0, 400),
        Position = UDim2.new(1, -16, 0, 16),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = holder,
    })
    return holder
end

local notifHolder
local function notify(message, kind)
    kind = kind or "info"
    local accent = (kind == "success" and PALETTE.Success)
        or (kind == "error" and PALETTE.Danger)
        or PALETTE.Accent

    notifOrder = notifOrder + 1

    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 54),
        Position = UDim2.new(0, 300, 0, 0),
        BackgroundColor3 = PALETTE.Secondary,
        BorderSizePixel = 0,
        LayoutOrder = notifOrder,
        Parent = notifHolder,
    })
    corner(card, 10)
    stroke(card, PALETTE.Border, 1, 0.4)

    local accentBar = create("Frame", {
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Parent = card,
    })
    corner(accentBar, 2)

    local titleText = (kind == "success" and "SUCCESS")
        or (kind == "error" and "ERROR")
        or "INFO"

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 9),
        Size = UDim2.new(1, -24, 0, 12),
        Font = Enum.Font.GothamBold,
        Text = titleText,
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
        TextColor3 = PALETTE.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = card,
    })

    tween(card, 0.32, {
        Position = UDim2.new(0, 0, 0, 0),
    }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    task.delay(3.5, function()
        if not card.Parent then return end
        local t = tween(card, 0.28, {
            Position = UDim2.new(1, 20, 0, 0),
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(accentBar, 0.28, {BackgroundTransparency = 1})
        tween(bodyLbl, 0.28, {TextTransparency = 1})
        t.Completed:Connect(function() card:Destroy() end)
    end)
end

--============================================================
--  5. GUI CREATION
--============================================================
for _, g in ipairs(PlayerGui:GetChildren()) do
    if g:IsA("ScreenGui") and g.Name == "PremiumScriptHub" then
        g:Destroy()
    end
end

local camera = workspace.CurrentCamera
local viewport = (camera and camera.ViewportSize) or Vector2.new(1280, 720)
local IS_COMPACT = viewport.X < 760

local gui = create("ScreenGui", {
    Name = "PremiumScriptHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 100,
    Parent = PlayerGui,
})

notifHolder = buildNotifHolder(gui)

--============================================================
--  Main Panel
--============================================================
local PANEL_W = IS_COMPACT and UDim.new(1, -24) or UDim.new(0, 620)
local PANEL_H = IS_COMPACT and UDim.new(1, -140) or UDim.new(0, 460)

local main = create("Frame", {
    Name = "Main",
    Size = UDim2.new(PANEL_W.Scale, PANEL_W.Offset, PANEL_H.Scale, PANEL_H.Offset),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = PALETTE.Panel,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = gui,
})
corner(main, 14)
stroke(main, PALETTE.Border, 1, 0.25)

create("UISizeConstraint", {
    MaxSize = Vector2.new(720, 500),
    MinSize = Vector2.new(300, 340),
    Parent = main,
})

local uiScale = create("UIScale", {Scale = 1, Parent = main})

--============  HEADER  ============
local HEADER_H = 60
local STATUS_H = 28

local header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, HEADER_H),
    BackgroundColor3 = PALETTE.Panel,
    BorderSizePixel = 0,
    Parent = main,
})

create("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = PALETTE.Border,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    Parent = header,
})

create("Frame", {
    Size = UDim2.new(0, 3, 0, 22),
    Position = UDim2.new(0, 16, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = PALETTE.Accent,
    BorderSizePixel = 0,
    Parent = header,
})
corner(header:FindFirstChildWhichIsA("Frame"), 2)

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 30, 0, 13),
    Size = UDim2.new(1, -160, 0, 16),
    Font = Enum.Font.GothamBold,
    Text = CONFIG.Title,
    TextColor3 = PALETTE.Text,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = header,
})

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 30, 0, 32),
    Size = UDim2.new(1, -160, 0, 14),
    Font = Enum.Font.Gotham,
    Text = CONFIG.Subtitle,
    TextColor3 = PALETTE.TextMuted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = header,
})

local function makeHeaderButton(symbol, xOffset)
    local btn = create("TextButton", {
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, xOffset, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = PALETTE.Secondary,
        BackgroundTransparency = 0.15,
        Text = symbol,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = PALETTE.TextMuted,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = header,
    })
    corner(btn, 8)
    stroke(btn, PALETTE.Border, 1, 0.4)

    btn.MouseEnter:Connect(function()
        tween(btn, 0.15, {BackgroundColor3 = PALETTE.PanelHi, TextColor3 = PALETTE.Text})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.15, {BackgroundColor3 = PALETTE.Secondary, TextColor3 = PALETTE.TextMuted})
    end)
    return btn
end

local closeBtn    = makeHeaderButton("×", -12)
local minimizeBtn = makeHeaderButton("—", -48)

--============  BODY  ============
local body = create("Frame", {
    Name = "Body",
    Size = UDim2.new(1, 0, 1, -(HEADER_H + STATUS_H)),
    Position = UDim2.new(0, 0, 0, HEADER_H),
    BackgroundColor3 = PALETTE.Panel,
    BorderSizePixel = 0,
    Parent = main,
})

--============  STATUS BAR  ============
local statusBar = create("Frame", {
    Name = "StatusBar",
    Size = UDim2.new(1, 0, 0, STATUS_H),
    Position = UDim2.new(0, 0, 1, -STATUS_H),
    BackgroundColor3 = PALETTE.Panel,
    BorderSizePixel = 0,
    Parent = main,
})

create("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = PALETTE.Border,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    Parent = statusBar,
})

local statusDot = create("Frame", {
    Size = UDim2.new(0, 7, 0, 7),
    Position = UDim2.new(0, 16, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = PALETTE.Success,
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
    TextColor3 = PALETTE.TextMuted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = statusBar,
})

local function setStatus(text, color)
    statusLabel.Text = text
    tween(statusDot, 0.2, {BackgroundColor3 = color})
end

--============  SCROLL  ============
local scroll = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = PALETTE.Border,
    ScrollBarImageTransparency = 0.3,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    Parent = body,
})

create("UIPadding", {
    PaddingTop = UDim.new(0, 14),
    PaddingBottom = UDim.new(0, 14),
    PaddingLeft = UDim.new(0, 16),
    PaddingRight = UDim.new(0, 16),
    Parent = scroll,
})

create("UIListLayout", {
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = scroll,
})

--============  SECTION LABEL: SCRIPTS  ============
local sectionScripts = create("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 18),
    Font = Enum.Font.GothamBold,
    Text = "SCRIPTS",
    TextColor3 = PALETTE.TextMuted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 0,
    Parent = scroll,
})

--============================================================
--  6. SCRIPT CARD GENERATOR
--============================================================
local function createDivider(order)
    local wrap = create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        LayoutOrder = order,
        Parent = scroll,
    })
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = PALETTE.Border,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Parent = wrap,
    })
    return wrap
end

local function createScriptCard(entry, order)
    local card = create("Frame", {
        Name = entry.Name,
        Size = UDim2.new(1, 0, 0, 90),
        BackgroundColor3 = PALETTE.Secondary,
        BorderSizePixel = 0,
        LayoutOrder = order,
        Parent = scroll,
    })
    corner(card, 10)
    stroke(card, PALETTE.Border, 1, 0.4)

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
        TextColor3 = PALETTE.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 21),
        Size = UDim2.new(1, -92, 0, 26),
        Font = Enum.Font.Gotham,
        Text = entry.Description,
        TextColor3 = PALETTE.TextMuted,
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
        BackgroundColor3 = PALETTE.TextMuted,
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
        TextColor3 = PALETTE.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local loadBtn = create("TextButton", {
        Size = UDim2.new(0, 78, 0, 32),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = PALETTE.Accent,
        Text = "LOAD",
        Font = Enum.Font.GothamBold,
        TextColor3 = PALETTE.Text,
        TextSize = 11,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = card,
    })
    corner(loadBtn, 8)

    loadBtn.MouseEnter:Connect(function()
        if not loadBtn:GetAttribute("Loading") then
            tween(loadBtn, 0.15, {BackgroundColor3 = PALETTE.AccentSoft})
        end
    end)
    loadBtn.MouseLeave:Connect(function()
        if not loadBtn:GetAttribute("Loading") then
            tween(loadBtn, 0.15, {BackgroundColor3 = PALETTE.Accent})
        end
    end)

    card.MouseEnter:Connect(function()
        tween(card, 0.15, {BackgroundColor3 = PALETTE.PanelHi})
    end)
    card.MouseLeave:Connect(function()
        tween(card, 0.15, {BackgroundColor3 = PALETTE.Secondary})
    end)

    loadBtn.MouseButton1Click:Connect(function()
        if loadBtn:GetAttribute("Loading") then return end
        loadBtn:SetAttribute("Loading", true)

        -- press animation
        local baseSize = loadBtn.Size
        tween(loadBtn, 0.08, {
            Size = UDim2.new(baseSize.X.Scale, baseSize.X.Offset - 6,
                             baseSize.Y.Scale, baseSize.Y.Offset - 4)
        })
        task.delay(0.09, function()
            tween(loadBtn, 0.08, {Size = baseSize})
        end)

        loadBtn.Text = "LOADING..."
        loadBtn.TextSize = 10
        loadBtn.BackgroundColor3 = PALETTE.PanelHi
        loadBtn.TextColor3 = PALETTE.TextMuted

        dot.BackgroundColor3 = PALETTE.Warning
        statLbl.Text = "Loading..."
        statLbl.TextColor3 = PALETTE.TextMuted
        setStatus("Loading...", PALETTE.Warning)

        task.spawn(function()
            local ok, err = LOADER.attemptLoad(entry)

            loadBtn:SetAttribute("Loading", false)
            loadBtn.Text = "LOAD"
            loadBtn.TextSize = 11
            loadBtn.BackgroundColor3 = PALETTE.Accent
            loadBtn.TextColor3 = PALETTE.Text

            if ok then
                dot.BackgroundColor3 = PALETTE.Success
                statLbl.Text = "Loaded"
                statLbl.TextColor3 = PALETTE.Success
                setStatus("Loaded", PALETTE.Success)
                notify(entry.Name .. " loaded successfully", "success")
            else
                dot.BackgroundColor3 = PALETTE.Danger
                statLbl.Text = "Failed"
                statLbl.TextColor3 = PALETTE.Danger
                setStatus("Failed", PALETTE.Danger)
                notify("Failed: " .. tostring(err), "error")
            end
        end)
    end)
end

--============================================================
--  7. LOADER SYSTEM
--============================================================
LOADER = {}

function LOADER.resolveModule(moduleName)
    local containers = {
        ReplicatedStorage:FindFirstChild(CONFIG.ModuleFolder),
        ServerScriptService:FindFirstChild(CONFIG.ModuleFolder),
    }
    for _, c in ipairs(containers) do
        if c then
            local m = c:FindFirstChild(moduleName)
            if m and m:IsA("ModuleScript") then
                return m
            end
        end
    end
    return nil
end

function LOADER.attemptLoad(entry)
    -- 1) Executor path (jika tersedia)
    local loadstringFn = rawget(_G, "loadstring")
    local httpGetFn    = rawget(_G, "HttpGet")

    if loadstringFn and httpGetFn then
        local ok, res = pcall(httpGetFn, entry.URL)
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

    -- 2) ModuleScript fallback (works di Studio / Roblox normal)
    local mod = LOADER.resolveModule(entry.Name)
    if mod then
        local ok, err = pcall(require, mod)
        if ok then return true end
        return false, tostring(err)
    end

    return false, "No executor API and no ModuleScript fallback found"
end

--============================================================
--  8. CREDITS SECTION
--============================================================
local function buildCredits(baseOrder)
    createDivider(baseOrder)
    baseOrder = baseOrder + 1

    local credLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "CREDITS",
        TextColor3 = PALETTE.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = baseOrder,
        Parent = scroll,
    })
    baseOrder = baseOrder + 1

    local credCard = create("Frame", {
        Size = UDim2.new(1, 0, 0, 100),
        BackgroundColor3 = PALETTE.Secondary,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        LayoutOrder = baseOrder,
        Parent = scroll,
    })
    corner(credCard, 10)
    stroke(credCard, PALETTE.Border, 1, 0.5)

    create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        Parent = credCard,
    })

    local credList = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = credCard,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = credList,
    })

    local function creditRow(label, value, order)
        local row = create("Frame", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = credList,
        })
        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.42, 0, 1, 0),
            Font = Enum.Font.Gotham,
            Text = label,
            TextColor3 = PALETTE.TextMuted,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })
        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.42, 0, 0, 0),
            Size = UDim2.new(0.58, 0, 1, 0),
            Font = Enum.Font.GothamMedium,
            Text = value,
            TextColor3 = PALETTE.Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = row,
        })
    end

    creditRow("Developed by", CONFIG.Credits.Developer, 1)
    creditRow("UI & Design",  CONFIG.Credits.UIDesign,  2)
    creditRow("Special Thanks", CONFIG.Credits.SpecialThanks, 3)
end

--============  POPULATE  ============
do
    local order = 1
    for _, entry in ipairs(Scripts) do
        createScriptCard(entry, order)
        order = order + 1
    end
    buildCredits(order)
end

--============================================================
--  9. DRAG SYSTEM
--============================================================
local function isPointOverButton(input, buttons)
    local p = input.Position
    for _, b in ipairs(buttons) do
        local ap = b.AbsolutePosition
        local as = b.AbsoluteSize
        if p.X >= ap.X and p.X <= ap.X + as.X
        and p.Y >= ap.Y and p.Y <= ap.Y + as.Y then
            return true
        end
    end
    return false
end

-- Header drag
do
    local dragging, startInput, startPos = false, nil, nil

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if isPointOverButton(input, {closeBtn, minimizeBtn}) then return end
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

--============================================================
--  10. OPEN/CLOSE + REOPEN SYSTEM
--============================================================
-- Floating Reopen Button (asset ID fixed)
local reopen = create("ImageButton", {
    Name = "ReopenButton",
    Size = UDim2.new(0, 46, 0, 46),
    Position = UDim2.new(0, 18, 0.5, 0),
    BackgroundColor3 = PALETTE.Panel,
    BackgroundTransparency = 0.15,
    Image = CONFIG.ReopenIconId,
    ImageColor3 = PALETTE.Text,
    ImageTransparency = 0.05,
    ScaleType = Enum.ScaleType.Fit,
    AutoButtonColor = false,
    Visible = false,
    BorderSizePixel = 0,
    Parent = gui,
})
corner(reopen, 12)
stroke(reopen, PALETTE.Border, 1, 0.3)

create("UIPadding", {
    PaddingTop = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    Parent = reopen,
})

local function showMain()
    reopen.Visible = false
    main.Visible = true
    uiScale.Scale = 0.88
    tween(uiScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function hideMain()
    tween(uiScale, 0.2, {Scale = 0.88}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    task.delay(0.2, function()
        main.Visible = false
        reopen.Visible = true
        reopen.Size = UDim2.new(0, 0, 0, 0)
        tween(reopen, 0.3, {Size = UDim2.new(0, 46, 0, 46)},
            Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
end

-- Drag reopen button (with tap detection)
do
    local dragging, dragged, startInput, startPos = false, false, nil, nil

    reopen.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragged = false
            startInput = input.Position
            startPos = reopen.Position
        end
    end)

    reopen.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - startInput
            if math.abs(d.X) > 4 or math.abs(d.Y) > 4 then
                dragged = true
            end
            if dragged then
                reopen.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y
                )
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if not dragged then
                showMain()
            end
        end
    end)
end

-- Hook header buttons
minimizeBtn.MouseButton1Click:Connect(function()
    hideMain()
    notify("Hub minimized", "info")
end)

closeBtn.MouseButton1Click:Connect(function()
    hideMain()
    notify("Hub closed — tap icon to reopen", "info")
end)

--============================================================
--  11. INITIALIZE
--============================================================
main.Visible = true
uiScale.Scale = 0.88
tween(uiScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

setStatus("Ready", PALETTE.Success)
task.delay(0.55, function()
    notify("Script Hub ready", "success")
end)