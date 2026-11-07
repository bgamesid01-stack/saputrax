-- by 7yd7 (fixed build)

getgenv().Settings = {
    CopyButton = false,
    -------------------
    AutoButton = false,
    AutoInterval = 0.1,
    -------------------
    InstantPurchase = false,
    -------------------
    AutoMassPurchase = false,
    Debug = false
}
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local CoreGui = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait() ; LocalPlayer = Players.LocalPlayer end

-- =========================================================
--  FIX #4: WARNING kalau SignalPrompt tidak tersedia
-- =========================================================
local SIGNAL_OK = true
for _, name in ipairs({
    "SignalPromptGamePassPurchaseFinished",
    "SignalPromptProductPurchaseFinished",
    "SignalPromptPurchaseFinished",
    "SignalPromptBundlePurchaseFinished",
}) do
    if type(MarketplaceService[name]) ~= "function" then
        SIGNAL_OK = false
        warn("[FreeGP] ⚠️ Executor tidak support " .. name .. " — fitur FREE/AUTO/MASS tidak akan work")
    end
end

local COLORS      = { IDLE = Color3.fromRGB(34, 214, 78),  HOVER = Color3.fromRGB(42, 232, 90) }
local COPY_COLORS = { IDLE = Color3.fromRGB(255, 154, 46), HOVER = Color3.fromRGB(255, 176, 84) }
local AUTO_COLORS = { IDLE = Color3.fromRGB(210, 72, 72),  HOVER = Color3.fromRGB(232, 98, 98) }

local TWEEN_SPEED = TweenInfo.new(0.045, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SECONDARY_BUTTON_DELAY = 0.03
local NEW_OVERLAY_BUTTON_INJECT_DELAY = 0
local INSTANT_STATE_WATCH_INTERVAL = 0.03
local OVERLAY_RESCAN_INTERVAL = 0.03
local FINISH_PURCHASE_DEDUP_WINDOW = 0.15

local LastPrompt  = { Id = nil, Type = nil, Nonce = 0 }
local LastInstant = { PromptNonce = -1 }

local SETTINGS_DEFAULTS = {
    CopyButton = false, AutoButton = false, AutoInterval = 0.3,
    InstantPurchase = false, AutoMassPurchase = false, Debug = false,
}

-- =========================================================
--  SETTINGS
-- =========================================================
local function getSettings()
    local resolved = table.clone(SETTINGS_DEFAULTS)
    local ok, envSettings = pcall(function()
        if type(getgenv) ~= "function" then return false end
        local env = getgenv()
        if type(env) ~= "table" then return false end
        local s = env.Settings
        return type(s) == "table" and s or false
    end)
    if not ok or envSettings == false then return resolved end
    for k, def in pairs(SETTINGS_DEFAULTS) do
        if type(envSettings[k]) == type(def) then resolved[k] = envSettings[k] end
    end
    return resolved
end

local function isSettingEnabled(name) return getSettings()[name] == true end

local function log(msg)
    if isSettingEnabled("Debug") then
        print("[FreeGP] " .. tostring(msg))
    end
end

-- =========================================================
--  RUNTIME STATE
-- =========================================================
local RuntimeState = nil
pcall(function()
    local env = type(getgenv) == "function" and getgenv() or nil
    if type(env) == "table" then
        env.__FreeGamepassRuntime = env.__FreeGamepassRuntime or { runId = 0 }
        if type(env.__FreeGamepassRuntime.connections) == "table" then
            for _, conn in ipairs(env.__FreeGamepassRuntime.connections) do
                pcall(function() if conn and conn.Disconnect then conn:Disconnect() end end)
            end
        end
        env.__FreeGamepassRuntime.connections = {}
        env.__FreeGamepassRuntime.runId = env.__FreeGamepassRuntime.runId + 1
        RuntimeState = env.__FreeGamepassRuntime
    end
end)

local CURRENT_RUN_ID = RuntimeState and RuntimeState.runId or os.clock()
local AutoLoopState  = { Running = false, ThreadId = 0, StopGui = nil }
local AutoMassState  = { Running = false, StopRequested = false }
local ParentButtonState = setmetatable({}, { __mode = "k" })
local ScriptConnections = RuntimeState and RuntimeState.connections or {}
local HiddenOverlays    = setmetatable({}, { __mode = "k" })
local ProcessedOverlays = setmetatable({}, { __mode = "k" })
local RecentSignals     = {}

local function isCurrentRun() return not RuntimeState or RuntimeState.runId == CURRENT_RUN_ID end
local function trackConnection(conn)
    if conn then table.insert(ScriptConnections, conn) end
    return conn
end

-- =========================================================
--  UI HELPERS
-- =========================================================
local function toggleRobloxMenu()
    pcall(function()
        local foundOverlay = false
        for _, child in ipairs(CoreGui:GetChildren()) do
            if child:IsA("ScreenGui") and child.Name == "FoundationOverlay" and child.Enabled then
                local saf = child:FindFirstChild("SafeAreaFrame")
                local portal = saf and saf:FindFirstChild("OverlayPortal")
                local backdrop = portal and portal:FindFirstChild("Backdrop")
                local sheet = portal and portal:FindFirstChild("SheetContainer")
                if backdrop and sheet then
                    foundOverlay = true
                    local info = TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
                    TweenService:Create(backdrop, info, {BackgroundTransparency = 1}):Play()
                    local t = TweenService:Create(sheet, info, {Position = UDim2.new(0.5, 0, 0.5, 32)})
                    t:Play()
                    t.Completed:Connect(function()
                        GuiService:SetMenuIsOpen(true); GuiService:SetMenuIsOpen(false)
                    end)
                    break
                end
            end
        end
        if not foundOverlay then
            GuiService:SetMenuIsOpen(true); GuiService:SetMenuIsOpen(false)
        end
    end)
end

pcall(function()
    local old = CoreGui:FindFirstChild("AutoStopButton")
    if old then old:Destroy() end
end)

local function trySet(obj, prop, value) pcall(function() obj[prop] = value end) end

local function tweenColor(target, color)
    if not target or not target.Parent then return end
    local props = {}
    if target:IsA("GuiObject") then props.BackgroundColor3 = color end
    if target:IsA("ImageButton") or target:IsA("ImageLabel") then props.ImageColor3 = color end
    if next(props) then TweenService:Create(target, TWEEN_SPEED, props):Play() end
end

local function applyVisualState(root, color)
    tweenColor(root, color)
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("ImageLabel") or d:IsA("ImageButton") or d:IsA("Frame") then tweenColor(d, color) end
    end
end

local function fireEventFallback(event, ...)
    if type(firesignal) == "function" then pcall(firesignal, event, ...) end
end

-- =========================================================
--  PURCHASE
-- =========================================================
local function finishPurchase(id)
    if LastPrompt.Type == "GamePass" then
        if not pcall(function() MarketplaceService:SignalPromptGamePassPurchaseFinished(LocalPlayer.UserId, id, true) end) then
            fireEventFallback(MarketplaceService.PromptGamePassPurchaseFinished, LocalPlayer, id, true)
        end
    elseif LastPrompt.Type == "Product" then
        if not pcall(function() MarketplaceService:SignalPromptProductPurchaseFinished(LocalPlayer.UserId, id, true) end) then
            fireEventFallback(MarketplaceService.PromptProductPurchaseFinished, LocalPlayer.UserId, id, true)
        end
    elseif LastPrompt.Type == "Asset" then
        if not pcall(function() MarketplaceService:SignalPromptPurchaseFinished(LocalPlayer.UserId, id, true) end) then
            fireEventFallback(MarketplaceService.PromptPurchaseFinished, LocalPlayer, id, true)
        end
    elseif LastPrompt.Type == "Bundle" then
        if not pcall(function() MarketplaceService:SignalPromptBundlePurchaseFinished(LocalPlayer.UserId, id, true) end) then
            fireEventFallback(MarketplaceService.PromptBundlePurchaseFinished, LocalPlayer, id, true)
        end
    elseif LastPrompt.Type == "Premium" then
        if not pcall(function() MarketplaceService:SignalPromptPremiumPurchaseFinished(true) end) then
            fireEventFallback(MarketplaceService.PromptPremiumPurchaseFinished, true)
        end
    end
end

local function finishPurchaseDeduped(id)
    if not id then return false end
    local key = tostring(id) .. "|" .. tostring(LastPrompt.Type or "?")
    local now = os.clock()
    if RecentSignals[key] and (now - RecentSignals[key]) < FINISH_PURCHASE_DEDUP_WINDOW then
        return false
    end
    RecentSignals[key] = now
    finishPurchase(id)
    return true
end

-- =========================================================
--  PROMPT CAPTURE
-- =========================================================
local function restoreHiddenOverlays()
    for o in pairs(HiddenOverlays) do
        pcall(function() if o and o.Parent and o:IsA("ScreenGui") then o.Enabled = true end end)
        HiddenOverlays[o] = nil
    end
end

local function restoreFoundationOverlayVisibility()
    for _, c in ipairs(CoreGui:GetDescendants()) do
        if c:IsA("ScreenGui") and c.Name == "FoundationOverlay" then
            pcall(function() c.Enabled = true end)
        end
    end
end

local function runInstantPurchase(id, options)
    if not isCurrentRun() or not isSettingEnabled("InstantPurchase") then return end
    local opts = options or {}
    if opts.hideOverlay and opts.overlay then
        pcall(function()
            if opts.overlay:IsA("ScreenGui") then
                opts.overlay.Enabled = false
                HiddenOverlays[opts.overlay] = true
            end
        end)
    end
    if opts.forceMenuToggle then toggleRobloxMenu() end
    if not id or id ~= LastPrompt.Id then return end
    local nonce = LastPrompt.Nonce or 0
    if LastInstant.PromptNonce == nonce then return end
    LastInstant.PromptNonce = nonce
    finishPurchaseDeduped(id)
end

local function capturePrompt(player, id, promptType)
    if not isCurrentRun() or player ~= LocalPlayer then return end
    LastPrompt.Nonce = (LastPrompt.Nonce or 0) + 1
    LastPrompt.Id = id
    LastPrompt.Type = promptType
    log(string.format("Captured prompt: type=%s id=%s", tostring(promptType), tostring(id)))

    if isSettingEnabled("Debug") then
        task.spawn(function()
            local infoType
            if promptType == "GamePass" then infoType = Enum.InfoType.GamePass
            elseif promptType == "Product" then infoType = Enum.InfoType.Product
            elseif promptType == "Asset" then infoType = Enum.InfoType.Asset
            elseif promptType == "Bundle" then infoType = Enum.InfoType.Bundle end
            if infoType then
                local ok, info = pcall(function() return MarketplaceService:GetProductInfo(id, infoType) end)
                if ok and info then
                    print(string.format("%s | %s | %s", tostring(info.Name), tostring(id), tostring(info.PriceInRobux or 0)))
                end
            end
        end)
    end

    if isSettingEnabled("InstantPurchase") then
        task.spawn(function() runInstantPurchase(id, { forceMenuToggle = false }) end)
    end
end

trackConnection(MarketplaceService.PromptGamePassPurchaseRequested:Connect(function(p, id) capturePrompt(p, id, "GamePass") end))
trackConnection(MarketplaceService.PromptProductPurchaseRequested:Connect(function(p, id) capturePrompt(p, id, "Product") end))
trackConnection(MarketplaceService.PromptPurchaseRequested:Connect(function(p, id) capturePrompt(p, id, "Asset") end))
trackConnection(MarketplaceService.PromptBundlePurchaseRequested:Connect(function(p, id) capturePrompt(p, id, "Bundle") end))
trackConnection(MarketplaceService.PromptPremiumPurchaseRequested:Connect(function(p) capturePrompt(p, 0, "Premium") end))

-- =========================================================
--  FIX #3: Clear LastPrompt saat semua overlay prompt hilang
-- =========================================================
trackConnection(CoreGui.DescendantRemoving:Connect(function(child)
    if child and child.Name == "FoundationOverlay" then
        task.delay(0.15, function()
            local stillThere = false
            for _, c in ipairs(CoreGui:GetChildren()) do
                if c:IsA("ScreenGui") and c.Name == "FoundationOverlay" and c.Enabled then
                    stillThere = true; break
                end
            end
            if not stillThere then
                LastPrompt.Id = nil
                LastPrompt.Type = nil
                log("LastPrompt cleared (overlay removed)")
            end
        end)
    end
end))

-- =========================================================
--  BUILD OPERATION (COPY)
-- =========================================================
local function buildPurchaseOperation(id)
    local code = "local MarketplaceService = game:GetService(\"MarketplaceService\")\n\n"
    if LastPrompt.Type == "GamePass" then
        return code .. string.format("MarketplaceService:SignalPromptGamePassPurchaseFinished(%d, %d, true)", LocalPlayer.UserId, id)
    elseif LastPrompt.Type == "Product" then
        return code .. string.format("MarketplaceService:SignalPromptProductPurchaseFinished(%d, %d, true)", LocalPlayer.UserId, id)
    elseif LastPrompt.Type == "Asset" then
        return code .. string.format("MarketplaceService:SignalPromptPurchaseFinished(%d, %d, true)", LocalPlayer.UserId, id)
    elseif LastPrompt.Type == "Bundle" then
        return code .. string.format("MarketplaceService:SignalPromptBundlePurchaseFinished(%d, %d, true)", LocalPlayer.UserId, id)
    elseif LastPrompt.Type == "Premium" then
        return code .. "MarketplaceService:SignalPromptPremiumPurchaseFinished(true)"
    end
    return ""
end

-- =========================================================
--  LAYOUT
-- =========================================================
local function settleButtonPosition(anchor, btn, parent, offsetY)
    if not anchor or not btn or not parent then return end
    if parent:FindFirstChildOfClass("UIListLayout") then
        btn.LayoutOrder = (anchor.LayoutOrder or 0) + 1; return
    end
    btn.Position = anchor.Position + UDim2.fromOffset(0, offsetY or 0)
    task.defer(function()
        if btn.Parent ~= parent or anchor.Parent ~= parent then return end
        btn.Position = anchor.Position + UDim2.fromOffset(0, offsetY or 0)
    end)
end

local function settleFreeButtonPosition(orig, free, parent)
    if not orig or not free or not parent then return end
    if parent:FindFirstChildOfClass("UIListLayout") then
        free.LayoutOrder = (orig.LayoutOrder or 0) + 1; return
    end
    free.Position = orig.Position
    task.defer(function()
        if free.Parent ~= parent or orig.Parent ~= parent then return end
        free.Position = orig.Position
    end)
end

local function getInjectedButtonsBaseOrder(parent)
    local maxOrder = 0
    for _, c in ipairs(parent:GetChildren()) do
        if c:IsA("GuiObject") and c.Name ~= "FreeButton" and c.Name ~= "CopyButton" and c.Name ~= "AutoButton" then
            if (c.LayoutOrder or 0) > maxOrder then maxOrder = c.LayoutOrder end
        end
    end
    return maxOrder
end

local function getParentState(parent)
    local s = ParentButtonState[parent]
    if not s then s = {}; ParentButtonState[parent] = s end
    return s
end

local function layoutInjectedButtons(parent)
    if not parent then return end
    local state = getParentState(parent)
    local template = state.TemplateButton
    if not (template and template.Parent == parent) then
        template = nil
        for _, c in ipairs(parent:GetChildren()) do
            if c:IsA("ImageButton") and c.Name ~= "FreeButton" and c.Name ~= "CopyButton" and c.Name ~= "AutoButton" then
                template = c; break
            end
        end
        state.TemplateButton = template
    end
    local free = parent:FindFirstChild("FreeButton")
    local copy = parent:FindFirstChild("CopyButton")
    local auto = parent:FindFirstChild("AutoButton")
    if parent:FindFirstChildOfClass("UIListLayout") then
        local base = getInjectedButtonsBaseOrder(parent)
        if free then free.LayoutOrder = base + 1 end
        if copy then copy.LayoutOrder = base + 2 end
        if auto then auto.LayoutOrder = base + 3 end
        return
    end
    if free and template then settleFreeButtonPosition(template, free, parent) end
    if copy and free then settleButtonPosition(free, copy, parent, 42) end
    if auto then
        local anchor = copy or free
        if anchor then settleButtonPosition(anchor, auto, parent, 42) end
    end
end

-- =========================================================
--  AUTO LOOP
-- =========================================================
local function stopAutoLoop()
    AutoLoopState.Running = false
    AutoLoopState.ThreadId = AutoLoopState.ThreadId + 1
end

local function destroyAutoStopButton()
    if AutoLoopState.StopGui and AutoLoopState.StopGui.Parent then
        AutoLoopState.StopGui:Destroy()
    end
    AutoLoopState.StopGui = nil
end

local function startAutoLoop()
    if AutoLoopState.Running then return end
    AutoLoopState.Running = true
    AutoLoopState.ThreadId = AutoLoopState.ThreadId + 1
    local myId = AutoLoopState.ThreadId
    task.spawn(function()
        while AutoLoopState.Running and AutoLoopState.ThreadId == myId do
            local id = LastPrompt.Id
            if id then
                if finishPurchaseDeduped(id) then toggleRobloxMenu() end
            end
            local interval = getSettings().AutoInterval
            if type(interval) ~= "number" or interval <= 0 then interval = 0.3 end
            task.wait(interval)
        end
    end)
end

-- =========================================================
--  CLIPBOARD
-- =========================================================
local function copyToClipboard(text)
    if type(text) ~= "string" or text == "" then return false end
    if pcall(function() setclipboard(text) end) then return true end
    if type(rbxclipboard) == "function" and pcall(function() rbxclipboard(text) end) then return true end
    if type(toclipboard) == "function" and pcall(function() toclipboard(text) end) then return true end
    print("[FreeGP] CLIPBOARD FALLBACK →\n" .. text)
    return false
end

-- =========================================================
--  DRAGGABLE (fixed leak)
-- =========================================================
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos, didDrag = false, nil, nil, nil, false
    local DRAG_THRESHOLD = 6
    local function update(input)
        local delta = input.Position - dragStart
        if math.abs(delta.X) > DRAG_THRESHOLD or math.abs(delta.Y) > DRAG_THRESHOLD then didDrag = true end
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    trackConnection(frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; didDrag = false
            dragStart = input.Position; startPos = frame.Position
            trackConnection(input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end))
        end
    end))
    trackConnection(frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))
    trackConnection(UIS.InputChanged:Connect(function(input)
        if dragging and input == dragInput then update(input) end
    end))
    return function() local w = didDrag; didDrag = false; return w end
end

-- =========================================================
--  STOP BUTTON
-- =========================================================
local function createAutoStopButton()
    destroyAutoStopButton()
    local gui = Instance.new("ScreenGui")
    local button = Instance.new("TextButton")
    local corner = Instance.new("UICorner")
    local icon = Instance.new("ImageLabel")
    local aspect = Instance.new("UIAspectRatioConstraint")

    gui.Name = "AutoStopButton"
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui

    button.Name = "Button"
    button.Parent = gui
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Position = UDim2.new(0.5, 0, 0, 34)
    button.Size = UDim2.new(0.039, 0, 0.069, 0)
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    button.BackgroundTransparency = 0.4
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.ZIndex = 99999999
    button.Text = ""

    corner.CornerRadius = UDim.new(0, 99999)
    corner.Parent = button

    icon.Parent = button
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.new(0.1, 0, 0.1, 0)
    icon.Size = UDim2.new(0.8, 0, 0.8, 0)
    icon.Image = "rbxassetid://98003862321782"
    icon.ImageColor3 = Color3.fromRGB(255, 90, 90)

    aspect.Parent = button
    aspect.AspectRatio = 1

    local wasDragged = makeDraggable(button)
    button.Activated:Connect(function()
        if wasDragged() then return end
        stopAutoLoop()
        destroyAutoStopButton()
        for _, inst in ipairs(CoreGui:GetDescendants()) do
            if inst:IsA("ImageButton") and inst.Name == "AutoButton" then
                applyVisualState(inst, AUTO_COLORS.IDLE)
            end
        end
    end)
    AutoLoopState.StopGui = gui
end

-- =========================================================
--  BUTTON DECORATION
-- =========================================================
local function decorateButton(btn, text, zIndex, palette)
    local colors = palette or COLORS
    btn.Visible = true
    btn.Active = true
    btn.Selectable = true
    btn.AutoButtonColor = false
    btn.ZIndex = zIndex
    btn.BackgroundColor3 = colors.IDLE
    btn.BackgroundTransparency = 0.1
    trySet(btn, "Interactable", true)
    if btn:IsA("ImageButton") then btn.ImageColor3 = colors.IDLE end
    for _, d in ipairs(btn:GetDescendants()) do
        if d:IsA("LocalScript") or d:IsA("Script") or d:IsA("ModuleScript") then
            d:Destroy()
        elseif d:IsA("GuiObject") then
            d.ZIndex = math.max(d.ZIndex, btn.ZIndex)
            d.Active = true
            trySet(d, "Interactable", true)
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                d.Text = text
                d.TextTransparency = 0
            end
        end
    end
end

local function wireHover(btn, palette)
    local colors = palette or COLORS
    trackConnection(btn.MouseEnter:Connect(function() applyVisualState(btn, colors.HOVER) end))
    trackConnection(btn.MouseLeave:Connect(function() applyVisualState(btn, colors.IDLE) end))
end

-- =========================================================
--  PROCESS PARENT
-- =========================================================
local function processParentButtons(parent)
    if not parent then return end
    local state = getParentState(parent)
    if state.Injecting then state.Dirty = true; return end
    state.Injecting = true

    task.spawn(function()
        repeat
            state.Dirty = false
            local template = state.TemplateButton
            if not (template and template.Parent == parent) then
                state.Injecting = false; return
            end

            -- FREE
            if not parent:FindFirstChild("FreeButton") then
                local free = template:Clone()
                free.Name = "FreeButton"
                free.Parent = parent
                decorateButton(free, "Free", (template.ZIndex or 1) + 10)
                settleFreeButtonPosition(template, free, parent)
                wireHover(free, COLORS)
                trackConnection(free.Activated:Connect(function()
                    local id = LastPrompt.Id
                    if not id then
                        log("Free clicked but LastPrompt.Id is nil — prompt belum ter-capture")
                        return
                    end
                    applyVisualState(free, COLORS.HOVER)
                    if finishPurchaseDeduped(id) then toggleRobloxMenu() end
                    applyVisualState(free, COLORS.IDLE)
                end))
            end

            -- COPY
            task.defer(function()
                task.wait(SECONDARY_BUTTON_DELAY)
                if not isSettingEnabled("CopyButton") then
                    local ex = parent:FindFirstChild("CopyButton")
                    if ex then ex:Destroy() end
                    return
                end
                if parent:FindFirstChild("CopyButton") then return end
                local t = state.TemplateButton
                if not (t and t.Parent == parent) then return end
                local copy = t:Clone()
                copy.Name = "CopyButton"
                copy.Parent = parent
                local free = parent:FindFirstChild("FreeButton")
                decorateButton(copy, "Copy", free and free.ZIndex or ((t.ZIndex or 1) + 10), COPY_COLORS)
                wireHover(copy, COPY_COLORS)
                settleButtonPosition(free, copy, parent, 42)
                trackConnection(copy.Activated:Connect(function()
                    local id = LastPrompt.Id
                    if not id then return end
                    local ok = copyToClipboard(buildPurchaseOperation(id))
                    if ok then
                        applyVisualState(copy, COPY_COLORS.HOVER)
                        task.wait(0.05)
                    end
                    applyVisualState(copy, COPY_COLORS.IDLE)
                end))
            end)

            -- AUTO
            task.defer(function()
                task.wait(SECONDARY_BUTTON_DELAY)
                if not isSettingEnabled("AutoButton") then
                    local ex = parent:FindFirstChild("AutoButton")
                    if ex then ex:Destroy() end
                    stopAutoLoop(); destroyAutoStopButton()
                    return
                end
                if parent:FindFirstChild("AutoButton") then return end
                local t = state.TemplateButton
                if not (t and t.Parent == parent) then return end
                local auto = t:Clone()
                auto.Name = "AutoButton"
                auto.Parent = parent
                local anchor = parent:FindFirstChild("CopyButton") or parent:FindFirstChild("FreeButton")
                decorateButton(auto, "Auto", (anchor and anchor.ZIndex) or ((t.ZIndex or 1) + 10), AUTO_COLORS)
                wireHover(auto, AUTO_COLORS)
                settleButtonPosition(anchor, auto, parent, 42)
                trackConnection(auto.Activated:Connect(function()
                    toggleRobloxMenu()
                    if AutoLoopState.Running then
                        stopAutoLoop(); destroyAutoStopButton()
                        applyVisualState(auto, AUTO_COLORS.IDLE)
                        return
                    end
                    startAutoLoop(); createAutoStopButton()
                    applyVisualState(auto, AUTO_COLORS.HOVER)
                end))
            end)

            task.wait()
            layoutInjectedButtons(parent)
        until not state.Dirty
        state.Injecting = false
    end)
end

local function injectButtons(originalBtn)
    if not originalBtn then return end
    if originalBtn.Name == "FreeButton" or originalBtn.Name == "CopyButton" or originalBtn.Name == "AutoButton" then return end
    local parent = originalBtn.Parent
    if not parent then return end
    local state = getParentState(parent)
    if not (state.TemplateButton and state.TemplateButton.Parent == parent) then
        state.TemplateButton = originalBtn
    end
    processParentButtons(parent)
end

-- =========================================================
--  FIX #1: getActions lebih ketat, tanpa false positive
-- =========================================================
local function getActions(foundation)
    local safe = foundation:FindFirstChild("SafeAreaFrame")
    local portal = safe and safe:FindFirstChild("OverlayPortal")
    local sheet = portal and portal:FindFirstChild("SheetContainer")
    local frame = sheet and sheet:FindFirstChild("Frame")
    local sh = frame and frame:FindFirstChild("Sheet")
    local content = sh and sh:FindFirstChild("Content")
    local actions = content and content:FindFirstChild("Actions")
    if actions then return actions end
    -- Fallback: cari "Actions" yang PASTI berisi ImageButton di descendant-nya
    for _, desc in ipairs(foundation:GetDescendants()) do
        if desc.Name == "Actions" and desc:FindFirstChildWhichIsA("ImageButton", true) then
            return desc
        end
    end
    return nil
end

-- =========================================================
--  FIX #1: scanActions — hapus filter tonumber, return count
-- =========================================================
local function scanActions(actionsFolder)
    if not actionsFolder then return 0 end
    local count = 0
    for _, child in ipairs(actionsFolder:GetChildren()) do
        for _, inner in ipairs(child:GetDescendants()) do
            if inner:IsA("ImageButton")
                and inner.Name ~= "FreeButton"
                and inner.Name ~= "CopyButton"
                and inner.Name ~= "AutoButton" then
                injectButtons(inner)
                count = count + 1
            end
        end
        -- Kalau child sendiri ImageButton
        if child:IsA("ImageButton")
            and child.Name ~= "FreeButton"
            and child.Name ~= "CopyButton"
            and child.Name ~= "AutoButton" then
            injectButtons(child)
            count = count + 1
        end
    end
    return count
end

local function scanAllFoundationOverlays()
    for _, child in ipairs(CoreGui:GetDescendants()) do
        if child:IsA("ScreenGui") and child.Name == "FoundationOverlay" then
            local actions = getActions(child)
            if actions then scanActions(actions) end
        end
    end
end

-- =========================================================
--  FIX #2: ProcessedOverlays di-set HANYA setelah scan sukses
-- =========================================================
local handleOverlay

local function startInstantStateWatcher()
    task.spawn(function()
        local was = isSettingEnabled("InstantPurchase")
        if not was then
            restoreHiddenOverlays()
            restoreFoundationOverlayVisibility()
            scanAllFoundationOverlays()
        end
        while isCurrentRun() do
            local now = isSettingEnabled("InstantPurchase")
            if now ~= was then
                if not now then
                    LastInstant.PromptNonce = -1
                    restoreHiddenOverlays()
                    restoreFoundationOverlayVisibility()
                    scanAllFoundationOverlays()
                end
                for _, c in ipairs(CoreGui:GetDescendants()) do
                    if c:IsA("ScreenGui") and c.Name == "FoundationOverlay" then
                        task.spawn(handleOverlay, c, true)
                    end
                end
                was = now
            end
            task.wait(INSTANT_STATE_WATCH_INTERVAL)
        end
    end)
end

local function startOverlayRescanLoop()
    task.spawn(function()
        while isCurrentRun() do
            if not isSettingEnabled("InstantPurchase") then
                for _, c in ipairs(CoreGui:GetDescendants()) do
                    if c:IsA("ScreenGui") and c.Name == "FoundationOverlay" then
                        local actions = getActions(c)
                        if actions then scanActions(actions) end
                    end
                end
            end
            task.wait(OVERLAY_RESCAN_INTERVAL)
        end
    end)
end

function handleOverlay(child, force)
    if not child or child.Name ~= "FoundationOverlay" then return end

    local modeKey = isSettingEnabled("InstantPurchase") and "instant" or "buttons"
    if not force and ProcessedOverlays[child] == modeKey then return end

    if isSettingEnabled("InstantPurchase") then
        ProcessedOverlays[child] = modeKey   -- instant: boleh langsung
        local function exec()
            runInstantPurchase(LastPrompt.Id, { hideOverlay = true, overlay = child, forceMenuToggle = true })
        end
        task.spawn(function()
            local function check()
                if not (child and child.Parent and isSettingEnabled("InstantPurchase")) then return true end
                local saf = child:FindFirstChild("SafeAreaFrame")
                local portal = saf and saf:FindFirstChild("OverlayPortal")
                if portal then exec(); return true end
                return false
            end
            if not check() then
                local conn
                conn = trackConnection(child.DescendantAdded:Connect(function()
                    if check() and conn then conn:Disconnect() end
                end))
            end
        end)
        return
    end

    -- BUTTONS MODE
    local function tryScan()
        if not (child and child.Parent and isCurrentRun() and not isSettingEnabled("InstantPurchase")) then
            return false
        end
        if not force then task.wait(NEW_OVERLAY_BUTTON_INJECT_DELAY) end
        if not (child and child.Parent and isCurrentRun() and not isSettingEnabled("InstantPurchase")) then
            return false
        end
        local actions = getActions(child)
        if not actions then return false end
        local count = scanActions(actions)
        return count > 0   -- ← harus > 0 supaya tidak set ProcessedOverlays saat kosong
    end

    if tryScan() then
        ProcessedOverlays[child] = modeKey   -- ← set HANYA saat sukses
        log("Injected buttons for overlay")
        return
    end

    -- Retry via DescendantAdded
    local conn
    conn = trackConnection(child.DescendantAdded:Connect(function()
        if tryScan() then
            ProcessedOverlays[child] = modeKey
            if conn then conn:Disconnect() end
        end
    end))
    -- Safety: putus setelah 10s supaya tidak bocor
    task.delay(10, function()
        if conn then conn:Disconnect() end
        -- Kalau belum ter-inject sampai 10s, hapus dari ProcessedOverlays supaya rescan loop bisa retry
        if ProcessedOverlays[child] ~= modeKey then
            ProcessedOverlays[child] = nil
        end
    end)
end

trackConnection(CoreGui.DescendantAdded:Connect(handleOverlay))

-- Filter dulu sebelum spawn
for _, child in ipairs(CoreGui:GetDescendants()) do
    if child:IsA("ScreenGui") and child.Name == "FoundationOverlay" then
        task.spawn(handleOverlay, child)
    end
end

startInstantStateWatcher()
startOverlayRescanLoop()

-- =========================================================
--  FIX #5: AutoMassPurchase — handle deprecated API
-- =========================================================
local function performAutoMassPurchase()
    if AutoMassState.Running then return end
    if not isSettingEnabled("AutoMassPurchase") then return end
    AutoMassState.Running = true
    AutoMassState.StopRequested = false

    task.spawn(function()
        local HttpService = game:GetService("HttpService")
        local function shouldStop()
            return AutoMassState.StopRequested or not isSettingEnabled("AutoMassPurchase") or not isCurrentRun()
        end

        local function fireProduct(id, name)
            if shouldStop() then return end
            log("Product: " .. tostring(name) .. " | " .. tostring(id))
            local ok = pcall(function()
                MarketplaceService:SignalPromptProductPurchaseFinished(LocalPlayer.UserId, id, true)
            end)
            if not ok then
                fireEventFallback(MarketplaceService.PromptProductPurchaseFinished, LocalPlayer.UserId, id, true)
            end
            task.wait(0.1)
        end

        local function fireGamepass(id, name)
            if shouldStop() then return end
            log("GamePass: " .. tostring(name) .. " | " .. tostring(id))
            local ok = pcall(function()
                MarketplaceService:SignalPromptGamePassPurchaseFinished(LocalPlayer.UserId, id, true)
            end)
            if not ok then
                fireEventFallback(MarketplaceService.PromptGamePassPurchaseFinished, LocalPlayer, id, true)
            end
            task.wait(0.1)
        end

        -- Developer Products — coba, kalau error skip
        local okDP, productsPage = pcall(function()
            return MarketplaceService:GetDeveloperProductsAsync()
        end)
        if okDP and productsPage then
            while not shouldStop() do
                for _, info in ipairs(productsPage:GetCurrentPage()) do
                    if shouldStop() then break end
                    fireProduct(info.ProductId, info.Name or "Unknown")
                end
                if productsPage.IsFinished or shouldStop() then break end
                pcall(function() productsPage:AdvanceToNextPageAsync() end)
            end
        else
            log("GetDeveloperProductsAsync gagal — skip developer products (mungkin deprecated)")
        end

        if shouldStop() then
            AutoMassState.Running = false
            return
        end

        -- Gamepasses via HTTP
        local universeId = game.GameId
        if universeId == 0 then
            pcall(function()
                local res = game:HttpGet("https://apis.roblox.com/universes/v1/places/" .. tostring(game.PlaceId) .. "/universe")
                local data = HttpService:JSONDecode(res)
                if data and data.universeId then universeId = data.universeId end
            end)
        end
        if universeId and universeId > 0 then
            pcall(function()
                local cursor = ""
                while cursor and not shouldStop() do
                    local url = "https://games.roblox.com/v1/games/" .. tostring(universeId) .. "/game-passes?limit=100"
                    if cursor ~= "" then url = url .. "&cursor=" .. cursor end
                    local res = game:HttpGet(url)
                    local data = HttpService:JSONDecode(res)
                    if data and data.data then
                        for _, gp in ipairs(data.data) do
                            if shouldStop() then break end
                            fireGamepass(gp.id, gp.name or "Unknown")
                        end
                        cursor = data.nextPageCursor
                    else
                        cursor = nil
                    end
                end
            end)
        end

        AutoMassState.Running = false
        log("AutoMassPurchase complete")
    end)
end

local function startMassPurchaseWatcher()
    task.spawn(function()
        while isCurrentRun() do
            local enabled = isSettingEnabled("AutoMassPurchase")
            if enabled and not AutoMassState.Running then
                performAutoMassPurchase()
            elseif not enabled and AutoMassState.Running then
                AutoMassState.StopRequested = true
            end
            task.wait(1)
        end
    end)
end

startMassPurchaseWatcher()

log("Runtime initialized. RunID: " .. tostring(CURRENT_RUN_ID) .. " SIGNAL_OK=" .. tostring(SIGNAL_OK))