--[[
	FULL AUTOMATIC PERFORMANCE OPTIMIZER / ANTI-LAG SYSTEM
	Place as LocalScript in StarterPlayerScripts.
	Runs automatically. Zero config.
	
	Priority: GAMEPLAY > FPS STABILITY > VISUAL EFFECTS
	All heavy work uses batching + queue + adaptive delay + yield.
--]]

-- =========================================================
-- SERVICES
-- =========================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local Debris            = game:GetService("Debris")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =========================================================
-- CONFIG
-- =========================================================
local PERFORMANCE = {
	BATCH_SIZE       = 30,
	MIN_DELAY        = 0.01,
	NORMAL_DELAY     = 0.03,
	MAX_DELAY        = 0.15,
	SCAN_INTERVAL    = 2.0,
	UPDATE_INTERVAL  = 0.15,
	TARGET_FPS       = 50,

	-- Distance thresholds (studs)
	NEAR_DIST        = 80,
	MID_DIST         = 220,
	FAR_DIST         = 500,

	-- Hysteresis in studs so objects don't flicker ON/OFF
	HYSTERESIS       = 30,

	-- FPS thresholds
	FPS_LOW          = 35,
	FPS_CRITICAL     = 22,
	FPS_HIGH         = 55,

	-- Max queue to hold (drop if over, avoid memory bloat)
	MAX_QUEUE        = 5000,

	-- Ignore these names (common gameplay folders/objects)
	IGNORE_NAMES = {
		["Humanoid"]=true, ["Head"]=true, ["Torso"]=true,
		["UpperTorso"]=true, ["LowerTorso"]=true, ["LeftHand"]=true,
		["RightHand"]=true, ["LeftFoot"]=true, ["RightFoot"]=true,
		["LeftUpperArm"]=true, ["LeftLowerArm"]=true,
		["RightUpperArm"]=true, ["RightLowerArm"]=true,
		["LeftUpperLeg"]=true, ["LeftLowerLeg"]=true,
		["RightUpperLeg"]=true, ["RightLowerLeg"]=true,
		["RootPart"]=true, ["Hitbox"]=true, ["DamagePart"]=true,
		["Camera"]=true, ["Terrain"]=true,
	},
}

-- Mode presets
local MODES = {
	AUTO        = "AUTO",
	PERFORMANCE = "PERFORMANCE",
	BALANCED    = "BALANCED",
	QUALITY     = "QUALITY",
}

local MODE_SETTINGS = {
	[PERFORMANCE] = { batchMul=1.5, delayMul=0.6, effectsOff=true,  materialOptimize=true, partOptimize=true,  lightingOptimize=true  },
	[BALANCED]    = { batchMul=1.0, delayMul=1.0, effectsOff=false, materialOptimize=true, partOptimize=true,  lightingOptimize=true  },
	[QUALITY]     = { batchMul=0.6, delayMul=1.4, effectsOff=false, materialOptimize=false,partOptimize=false, lightingOptimize=false },
}

-- =========================================================
-- STATE
-- =========================================================
local State = {
	running           = true,
	mode              = MODES.AUTO,
	status            = "IDLE",
	fps               = 60,
	fpsAvg            = 60,
	lastFpsSample     = os.clock(),
	fpsFrames         = 0,
	fpsAccum          = 0,

	-- Counters
	counters = {
		objects = 0,
		effects = 0,
		queue   = 0,
	},

	-- Original property storage: [object] = { propName = originalValue }
	originals = setmetatable({}, { __mode = "k" }), -- weak keys

	-- Cache processed objects
	processedParts   = setmetatable({}, { __mode = "k" }),
	processedEffects = setmetatable({}, { __mode = "k" }),
	processedLights  = setmetatable({}, { __mode = "k" }),

	-- Distance state with hysteresis
	distanceState = setmetatable({}, { __mode = "k" }), -- [object] = "NEAR"/"MID"/"FAR"/"VFAR"
}

-- =========================================================
-- LIGHTING ORIGINAL SNAPSHOT
-- =========================================================
local LightingOriginal = {
	GlobalShadows     = Lighting.GlobalShadows,
	Brightness        = Lighting.Brightness,
	Ambient           = Lighting.Ambient,
	OutdoorAmbient    = Lighting.OutdoorAmbient,
	FogEnd            = Lighting.FogEnd,
	Technology        = Lighting.Technology,
}

local function findFirstOfClass(parent, className)
	for _, c in ipairs(parent:GetChildren()) do
		if c:IsA(className) then return c end
	end
	return nil
end

local LightingEffects = {
	Bloom           = findFirstOfClass(Lighting, "BloomEffect"),
	ColorCorrection = findFirstOfClass(Lighting, "ColorCorrectionEffect"),
	SunRays         = findFirstOfClass(Lighting, "SunRaysEffect"),
	DepthOfField    = findFirstOfClass(Lighting, "DepthOfFieldEffect"),
	Atmosphere      = findFirstOfClass(Lighting, "Atmosphere"),
	Blur            = findFirstOfClass(Lighting, "BlurEffect"),
}

local LightingEffectOriginal = {}
for k, v in pairs(LightingEffects) do
	if v then
		local snap = {}
		for _, prop in ipairs({"Enabled","Intensity","Size","Brightness","Threshold","Contrast","Saturation","TintColor","FarIntensity","FocusDistance","InFocusRadius","NearIntensity"}) do
			local ok, val = pcall(function() return v[prop] end)
			if ok then snap[prop] = val end
		end
		LightingEffectOriginal[k] = snap
	end
end

-- =========================================================
-- GUI
-- =========================================================
local function buildGui()
	local screen = Instance.new("ScreenGui")
	screen.Name = "PerfOptimizerGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = PlayerGui

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.AnchorPoint = Vector2.new(1, 0)
	root.Position = UDim2.new(1, -10, 0, 10)
	root.Size = UDim2.new(0, 220, 0, 0)
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	root.BackgroundTransparency = 0.15
	root.BorderSizePixel = 0
	root.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = root

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = root

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 20)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextSize = 13
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = Color3.fromRGB(120, 220, 255)
	header.Text = "PERFORMANCE OPTIMIZER"
	header.LayoutOrder = 1
	header.Parent = root

	local function makeLabel(order, text, color)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, 0, 0, 14)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.Code
		l.TextSize = 12
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextColor3 = color or Color3.fromRGB(200, 200, 200)
		l.Text = text
		l.LayoutOrder = order
		l.Parent = root
		return l
	end

	local fpsLabel     = makeLabel(2, "FPS: --",     Color3.fromRGB(140, 255, 140))
	local modeLabel    = makeLabel(3, "MODE: AUTO",  Color3.fromRGB(200, 220, 255))
	local statusLabel  = makeLabel(4, "STATUS: INIT",Color3.fromRGB(255, 220, 140))
	local objectsLabel = makeLabel(5, "Objects: 0",  Color3.fromRGB(200, 200, 200))
	local effectsLabel = makeLabel(6, "Effects: 0",  Color3.fromRGB(200, 200, 200))
	local queueLabel   = makeLabel(7, "Queue: 0",    Color3.fromRGB(200, 200, 200))

	-- Buttons container
	local btnRow = Instance.new("Frame")
	btnRow.Size = UDim2.new(1, 0, 0, 0)
	btnRow.AutomaticSize = Enum.AutomaticSize.Y
	btnRow.BackgroundTransparency = 1
	btnRow.LayoutOrder = 20
	btnRow.Parent = root

	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.Padding = UDim.new(0, 3)
	btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
	btnLayout.Parent = btnRow

	local function makeButton(text, order, color)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 48, 0, 22)
		b.BackgroundColor3 = color or Color3.fromRGB(45, 55, 80)
		b.BorderSizePixel = 0
		b.Font = Enum.Font.GothamBold
		b.TextSize = 10
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.Text = text
		b.LayoutOrder = order
		b.Parent = btnRow
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = b
		return b
	end

	local autoBtn  = makeButton("AUTO",        1, Color3.fromRGB(55, 100, 60))
	local perfBtn  = makeButton("PERF",        2, Color3.fromRGB(90, 60, 60))
	local balBtn   = makeButton("BAL",         3, Color3.fromRGB(60, 70, 110))
	local qualBtn  = makeButton("QUAL",        4, Color3.fromRGB(60, 90, 100))
	local restBtn  = makeButton("RESTORE",     5, Color3.fromRGB(110, 60, 60))

	-- Minimize
	local minimizeBtn = Instance.new("TextButton")
	minimizeBtn.AnchorPoint = Vector2.new(1, 0)
	minimizeBtn.Position = UDim2.new(1, 0, 0, 0)
	minimizeBtn.Size = UDim2.new(0, 20, 0, 20)
	minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	minimizeBtn.BorderSizePixel = 0
	minimizeBtn.Font = Enum.Font.GothamBold
	minimizeBtn.TextSize = 12
	minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	minimizeBtn.Text = "–"
	minimizeBtn.ZIndex = 3
	minimizeBtn.Parent = root

	local mc = Instance.new("UICorner")
	mc.CornerRadius = UDim.new(0, 6)
	mc.Parent = minimizeBtn

	local minimized = false
	minimizeBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		for _, child in ipairs(root:GetChildren()) do
			if child:IsA("GuiObject") and child ~= minimizeBtn and child ~= layout then
				child.Visible = not minimized
			end
		end
		minimizeBtn.Text = minimized and "+" or "–"
	end)

	-- Draggable
	do
		local dragging, dragStart, startPos
		header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = root.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				root.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
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

	return {
		screen = screen,
		root = root,
		fpsLabel = fpsLabel,
		modeLabel = modeLabel,
		statusLabel = statusLabel,
		objectsLabel = objectsLabel,
		effectsLabel = effectsLabel,
		queueLabel = queueLabel,
		buttons = {
			auto = autoBtn, perf = perfBtn, bal = balBtn, qual = qualBtn, restore = restBtn,
		},
	}
end

local GUI = buildGui()

-- =========================================================
-- OBJECT CLASSIFICATION
-- =========================================================
-- Returns "Character" | "NPC" | "Gameplay" | "Decoration" | "Effect" | "Terrain" | "UI" | "Unknown"
local function classifyObject(obj)
	if not obj or not obj.Parent then return "Unknown" end

	-- Terrain
	if obj:IsA("Terrain") then return "Terrain" end

	-- Character (player)
	local char = LocalPlayer and LocalPlayer.Character
	if char and obj:IsDescendantOf(char) then return "Character" end

	-- Other players / NPCs
	local model = obj:FindFirstAncestorOfClass("Model")
	if model then
		if model:FindFirstChildOfClass("Humanoid") then
			-- Is it a player character?
			local plr = Players:GetPlayerFromCharacter(model)
			if plr then return "Character" end
			return "NPC"
		end
	end

	-- Effects
	if obj:IsA("ParticleEmitter")
		or obj:IsA("Trail")
		or obj:IsA("Beam")
		or obj:IsA("Smoke")
		or obj:IsA("Fire")
		or obj:IsA("Sparkles")
		or obj:IsA("PointLight")
		or obj:IsA("SpotLight")
		or obj:IsA("SurfaceLight") then
		return "Effect"
	end

	if obj:IsA("GuiObject") or obj:IsA("ScreenGui") then return "UI" end

	-- Suspicious name
	if PERFORMANCE.IGNORE_NAMES[obj.Name] then
		if obj:IsA("BasePart") then return "Gameplay" end
	end

	-- BasePart
	if obj:IsA("BasePart") then
		-- Has important tags? Do not touch.
		if obj:HasTag("Gameplay") or obj:HasTag("Important") or obj:HasTag("Hitbox") then
			return "Gameplay"
		end
		-- Anchored decorative? Might be map/decoration. Anchored can also be part of map.
		-- We're conservative: only touch when clearly decorative OR far away later.
		return "Decoration"
	end

	return "Unknown"
end

local function isSafeToOptimize(obj)
	local cls = classifyObject(obj)
	if cls == "Character" or cls == "NPC" or cls == "Gameplay" or cls == "Terrain" or cls == "UI" then
		return false, cls
	end
	return true, cls
end

-- =========================================================
-- ORIGINAL STORAGE
-- =========================================================
local function rememberOriginal(obj, prop, value)
	local t = State.originals[obj]
	if not t then
		t = {}
		State.originals[obj] = t
	end
	if t[prop] == nil then
		t[prop] = value
	end
end

local function setPropertySafe(obj, prop, value)
	pcall(function()
		rememberOriginal(obj, prop, obj[prop])
		obj[prop] = value
	end)
end

-- =========================================================
-- QUEUE
-- =========================================================
local Queue = {
	items = {},
	head = 1,
	tail = 0,
}
State.counters.queue = 0

local function queuePush(task)
	if Queue.tail - Queue.head + 1 >= PERFORMANCE.MAX_QUEUE then
		return false
	end
	Queue.tail += 1
	Queue.items[Queue.tail] = task
	State.counters.queue = Queue.tail - Queue.head + 1
	return true
end

local function queuePop()
	if Queue.head > Queue.tail then
		Queue.items = {}
		Queue.head = 1
		Queue.tail = 0
		State.counters.queue = 0
		return nil
	end
	local item = Queue.items[Queue.head]
	Queue.items[Queue.head] = nil
	Queue.head += 1
	State.counters.queue = Queue.tail - Queue.head + 1
	return item
end

local function queueSize()
	return Queue.tail - Queue.head + 1
end

-- =========================================================
-- ADAPTIVE DELAY / BATCH
-- =========================================================
local function modeSettings()
	local m = State.mode
	if m == MODES.AUTO then
		if State.fpsAvg < PERFORMANCE.FPS_CRITICAL then
			return MODE_SETTINGS[MODES.PERFORMANCE], "PERF"
		elseif State.fpsAvg < PERFORMANCE.FPS_LOW then
			return MODE_SETTINGS[MODES.BALANCED], "BAL"
		elseif State.fpsAvg > PERFORMANCE.FPS_HIGH then
			return MODE_SETTINGS[MODES.QUALITY], "QUAL"
		else
			return MODE_SETTINGS[MODES.BALANCED], "BAL"
		end
	end
	return MODE_SETTINGS[m] or MODE_SETTINGS[MODES.BALANCED], m
end

local function currentBatchSize()
	local ms = modeSettings()
	local base = PERFORMANCE.BATCH_SIZE * (ms.batchMul or 1)
	-- FPS-based adaptive
	local f = State.fpsAvg
	if f >= PERFORMANCE.FPS_HIGH then
		base *= 1.3
	elseif f < PERFORMANCE.FPS_LOW then
		base *= 0.5
	end
	if f < PERFORMANCE.FPS_CRITICAL then
		base *= 0.35
	end
	return math.max(4, math.floor(base))
end

local function currentDelay()
	local ms = modeSettings()
	local base = PERFORMANCE.NORMAL_DELAY * (ms.delayMul or 1)
	local f = State.fpsAvg
	if f >= PERFORMANCE.FPS_HIGH then
		base = PERFORMANCE.MIN_DELAY
	elseif f < PERFORMANCE.FPS_LOW then
		base = PERFORMANCE.NORMAL_DELAY * 1.5
	end
	if f < PERFORMANCE.FPS_CRITICAL then
		base = PERFORMANCE.MAX_DELAY
	end
	return math.clamp(base, PERFORMANCE.MIN_DELAY, PERFORMANCE.MAX_DELAY)
end

-- =========================================================
-- FPS MONITOR
-- =========================================================
local fpsSamples = {}
local FPS_SAMPLE_WINDOW = 1.0

local function updateFps()
	State.fpsFrames += 1
	local now = os.clock()
	local elapsed = now - State.lastFpsSample
	if elapsed >= FPS_SAMPLE_WINDOW then
		local fps = State.fpsFrames / elapsed
		State.fps = fps
		table.insert(fpsSamples, fps)
		if #fpsSamples > 5 then table.remove(fpsSamples, 1) end
		local sum = 0
		for _, v in ipairs(fpsSamples) do sum += v end
		State.fpsAvg = sum / #fpsSamples
		State.fpsFrames = 0
		State.lastFpsSample = now
	end
end

RunService.RenderStepped:Connect(function()
	if not State.running then return end
	updateFps()
end)

-- =========================================================
-- PROCESSORS
-- =========================================================
local function optimizePart(obj)
	local safe, cls = isSafeToOptimize(obj)
	if not safe then return false end
	if State.processedParts[obj] then return false end

	local ms = modeSettings()
	if not ms.partOptimize then return false end

	-- Only optimize if it's Decoration and NOT anchored as part of a big map structure? 
	-- We're conservative: only touch parts that are truly decorative (no collision currently,
	-- or clearly tiny / non-anchored, or far). 
	-- SAFE approach: skip anchored parts to preserve map geometry.
	if obj.Anchored then
		-- Still safe to disable touch/query for anchored decorative parts
		if obj.CanTouch then setPropertySafe(obj, "CanTouch", false) end
		if obj.CanQuery and not obj:IsA("Terrain") then
			-- Only if not a hitbox candidate
			if not obj:FindFirstChildOfClass("ClickDetector") and not obj:FindFirstChildOfClass("ProximityPrompt") then
				setPropertySafe(obj, "CanQuery", false)
			end
		end
	else
		-- Non-anchored, non-gameplay decorative part
		if obj.CanCollide and not obj:FindFirstChildOfClass("ClickDetector")
			and not obj:FindFirstChildOfClass("ProximityPrompt") then
			-- do NOT remove collision from non-anchored parts by default
			-- because that could break gameplay (falling objects etc.)
		end
		if obj.CanTouch then setPropertySafe(obj, "CanTouch", false) end
	end

	-- Material optimization
	if ms.materialOptimize and obj.Material ~= Enum.Material.Plastic
		and obj.Material ~= Enum.Material.SmoothPlastic then
		-- Don't change materials that are commonly used for maps/gameplay visuals
		local m = obj.Material
		if m == Enum.Material.Neon or m == Enum.Material.Glass
			or m == Enum.Material.ForceField or m == Enum.Material.Marble then
			-- skip these (often gameplay/aesthetic critical)
		else
			-- Only optimize on far-range later via distance loop; leave material for now
		end
	end

	State.processedParts[obj] = true
	State.counters.objects += 1
	return true
end

local function optimizeEffect(obj)
	if State.processedEffects[obj] then return false end
	local ms = modeSettings()

	if obj:IsA("ParticleEmitter") then
		if ms.effectsOff or State.fpsAvg < PERFORMANCE.FPS_LOW then
			if obj.Enabled then setPropertySafe(obj, "Enabled", true) end
			-- reduce rate instead of disabling outright
			local origRate = obj.Rate
			rememberOriginal(obj, "Rate", origRate)
			pcall(function()
				obj.Rate = math.max(0, origRate * 0.3)
			end)
		end
	elseif obj:IsA("Trail") or obj:IsA("Beam") then
		if ms.effectsOff then
			pcall(function() setPropertySafe(obj, "Enabled", obj.Enabled) ; obj.Enabled = false end)
		end
	elseif obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
		if ms.effectsOff then
			pcall(function() setPropertySafe(obj, "Enabled", obj.Enabled) ; obj.Enabled = false end)
		end
	end

	State.processedEffects[obj] = true
	State.counters.effects += 1
	return true
end

local function optimizeLight(obj)
	if State.processedLights[obj] then return false end
	local ms = modeSettings()
	if not ms.lightingOptimize then return false end

	if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
		if State.fpsAvg < PERFORMANCE.FPS_LOW then
			pcall(function()
				setPropertySafe(obj, "Shadows", obj.Shadows)
				obj.Shadows = false
			end)
		end
	end
	State.processedLights[obj] = true
	return true
end

-- =========================================================
-- SCHEDULER
-- =========================================================
-- Runs queued work with batching, adaptive delay, FPS-aware pausing.
local schedulerRunning = false

local function schedulerLoop()
	if schedulerRunning then return end
	schedulerRunning = true

	task.spawn(function()
		while State.running do
			-- Critical FPS: pause optimizer work
			if State.fpsAvg < PERFORMANCE.FPS_CRITICAL then
				State.status = "PAUSED (LOW FPS)"
				task.wait(0.5)
				continue
			end

			local batch = currentBatchSize()
			local delay = currentDelay()
			local processed = 0

			local startTime = os.clock()
			while processed < batch do
				local task_ = queuePop()
				if not task_ then break end
				pcall(task_)
				processed += 1
				-- frame budget: don't spend > 6ms in one frame
				if os.clock() - startTime > 0.006 then
					break
				end
			end

			State.status = processed > 0 and "OPTIMIZING" or "IDLE"
			task.wait(delay)
		end

		schedulerRunning = false
	end)
end

-- =========================================================
-- SCANNER
-- =========================================================
-- Incremental scan: walks workspace in batches across frames.
-- Never calls GetDescendants() every frame.

local scanState = {
	queue = {},        -- pending objects to scan
	lastScan = 0,
	initialDone = false,
	visitedCount = 0,
}

local function enqueueScan(obj)
	if obj and obj.Parent then
		table.insert(scanState.queue, obj)
	end
end

-- Build a fresh scan list lazily (chunked)
local function buildScanQueue()
	scanState.queue = {}
	enqueueScan(Workspace)
	-- We'll expand children during scan, using queue
end

local function processScanItem(obj)
	-- classify and enqueue appropriate work
	local cls = classifyObject(obj)
	if cls == "Effect" then
		queuePush(function() optimizeEffect(obj) end)
	elseif cls == "Decoration" then
		queuePush(function() optimizePart(obj) end)
		-- Check children for lights
		for _, child in ipairs(obj:GetChildren()) do
			if child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then
				queuePush(function() optimizeLight(child) end)
			end
		end
	elseif cls == "Unknown" then
		-- safe skip
	end

	-- Enqueue children for scanning (but only if reasonable count)
	local children = obj:GetChildren()
	for i = 1, #children do
		if children[i] ~= PlayerGui then
			enqueueScan(children[i])
		end
	end

	scanState.visitedCount += 1
end

local function scannerLoop()
	task.spawn(function()
		-- initial wait
		task.wait(3)

		while State.running do
			-- If FPS is critical, delay scanning
			if State.fpsAvg < PERFORMANCE.FPS_CRITICAL then
				task.wait(1.5)
				continue
			end

			-- Build new scan queue
			buildScanQueue()
			State.status = "SCANNING"

			-- Process scan queue in batches with yields
			while #scanState.queue > 0 and State.running do
				local batch = currentBatchSize()
				local i = 1
				local startTime = os.clock()
				while i <= batch and #scanState.queue > 0 do
					local obj = table.remove(scanState.queue)
					pcall(processScanItem, obj)
					i += 1
					if os.clock() - startTime > 0.007 then
						break
					end
				end
				task.wait(currentDelay())
				if State.fpsAvg < PERFORMANCE.FPS_CRITICAL then
					task.wait(0.5)
				end
			end

			scanState.initialDone = true
			State.status = "IDLE"

			-- Wait before next scan cycle
			task.wait(PERFORMANCE.SCAN_INTERVAL)
		end
	end)
end

-- =========================================================
-- DISTANCE-BASED OPTIMIZER
-- =========================================================
-- Uses hysteresis to avoid flicker. Runs periodically, not every frame.

local function getPlayerPos()
	local char = LocalPlayer and LocalPlayer.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	return hrp.Position
end

local function setDistanceState(obj, newState)
	local old = State.distanceState[obj]
	if old == newState then return end
	State.distanceState[obj] = newState

	-- Apply optimizations based on state
	if newState == "VFAR" then
		-- hide decorative
		if obj:IsA("BasePart") and not obj.Anchored then
			pcall(function() setPropertySafe(obj, "Transparency", obj.Transparency) ; obj.Transparency = 1 end)
		end
		-- disable effects
		for _, c in ipairs(obj:GetChildren()) do
			if c:IsA("ParticleEmitter") or c:IsA("Trail") or c:IsA("Beam")
				or c:IsA("Smoke") or c:IsA("Fire") or c:IsA("Sparkles") then
				if c.Enabled then
					pcall(function() setPropertySafe(c, "Enabled", c.Enabled) ; c.Enabled = false end)
				end
			end
		end
	elseif newState == "FAR" then
		-- reduce effects
		for _, c in ipairs(obj:GetChildren()) do
			if c:IsA("ParticleEmitter") and c.Enabled then
				pcall(function()
					rememberOriginal(c, "Rate", c.Rate)
					c.Rate = c.Rate * 0.25
				end)
			end
		end
	elseif newState == "MID" then
		-- mild reduction
	elseif newState == "NEAR" then
		-- nothing (or restore visibility)
		if obj:IsA("BasePart") then
			local orig = State.originals[obj]
			if orig and orig.Transparency ~= nil then
				pcall(function() obj.Transparency = orig.Transparency end)
			end
		end
	end
end

local function distanceLoop()
	task.spawn(function()
		-- snapshot of objects to check (only those we've processed & still alive)
		while State.running do
			local pos = getPlayerPos()
			if pos then
				-- Iterate through stored distance entries + processed parts
				local list = {}
				for obj in pairs(State.processedParts) do
					if obj and obj.Parent then table.insert(list, obj) end
				end
				for obj in pairs(State.processedEffects) do
					if obj and obj.Parent then table.insert(list, obj) end
				end

				-- process in batches with yields
				local i = 1
				local batch = currentBatchSize()
				local startTime = os.clock()
				while i <= #list do
					local obj = list[i]
					local ok, objPos = pcall(function()
						if obj:IsA("BasePart") then return obj.Position
						elseif obj:IsA("Model") then return obj:GetPivot().Position
						else
							local parent = obj.Parent
							if parent and parent:IsA("BasePart") then return parent.Position end
						end
						return nil
					end)
					if ok and objPos then
						local dist = (objPos - pos).Magnitude
						local cur = State.distanceState[obj]
						local h = PERFORMANCE.HYSTERESIS

						local newState = cur or "NEAR"
						-- apply hysteresis
						if dist < PERFORMANCE.NEAR_DIST - h then newState = "NEAR"
						elseif dist < PERFORMANCE.MID_DIST - h then newState = "MID"
						elseif dist < PERFORMANCE.FAR_DIST - h then newState = "FAR"
						else newState = "VFAR" end

						if cur == "NEAR" and dist < PERFORMANCE.NEAR_DIST + h then newState = "NEAR" end
						if cur == "MID" and dist > PERFORMANCE.NEAR_DIST + h and dist < PERFORMANCE.MID_DIST + h then newState = "MID" end
						if cur == "FAR" and dist > PERFORMANCE.MID_DIST + h and dist < PERFORMANCE.FAR_DIST + h then newState = "FAR" end
						if cur == "VFAR" and dist > PERFORMANCE.FAR_DIST + h then newState = "VFAR" end

						pcall(setDistanceState, obj, newState)
					end

					i += 1
					if os.clock() - startTime > 0.006 then
						task.wait(currentDelay())
						startTime = os.clock()
					end
					if i % batch == 0 then
						task.wait(currentDelay())
					end
				end
			end

			task.wait(0.5)
		end
	end)
end

-- =========================================================
-- LIGHTING OPTIMIZER
-- =========================================================
local function applyLightingForMode()
	local ms = modeSettings()
	local m = State.mode

	if not ms.lightingOptimize then
		-- restore
		pcall(function()
			Lighting.GlobalShadows = LightingOriginal.GlobalShadows
		end)
		for key, snap in pairs(LightingEffectOriginal) do
			local fx = LightingEffects[key]
			if fx then
				for prop, val in pairs(snap) do
					pcall(function() fx[prop] = val end)
				end
			end
		end
		return
	end

	-- Apply based on FPS
	local lowFps = State.fpsAvg < PERFORMANCE.FPS_LOW
	local critFps = State.fpsAvg < PERFORMANCE.FPS_CRITICAL

	pcall(function()
		if critFps then
			Lighting.GlobalShadows = false
		elseif lowFps then
			Lighting.GlobalShadows = false
		else
			Lighting.GlobalShadows = LightingOriginal.GlobalShadows
		end
	end)

	local function adjust(name, prop, offVal, onVal)
		local fx = LightingEffects[name]
		if not fx then return end
		pcall(function()
			if critFps or lowFps then
				fx[prop] = offVal
			else
				local snap = LightingEffectOriginal[name]
				fx[prop] = (snap and snap[prop]) or onVal
			end
		end)
	end

	adjust("Bloom", "Enabled", false, true)
	adjust("SunRays", "Enabled", false, true)
	adjust("DepthOfField", "Enabled", false, true)
	adjust("Blur", "Enabled", false, true)
	if LightingEffects.Atmosphere then
		pcall(function()
			if critFps then
				LightingEffects.Atmosphere.Density = 0
			elseif lowFps then
				LightingEffects.Atmosphere.Density = 0.1
			else
				local snap = LightingEffectOriginal.Atmosphere
				if snap and snap.Density then
					LightingEffects.Atmosphere.Density = snap.Density
				end
			end
		end)
	end
end

-- =========================================================
-- GUI UPDATER
-- =========================================================
local guiLoopRunning = false
local function guiLoop()
	if guiLoopRunning then return end
	guiLoopRunning = true
	task.spawn(function()
		while State.running do
			pcall(function()
				GUI.fpsLabel.Text = string.format("FPS: %d", math.floor(State.fpsAvg + 0.5))
				local _, modeShort = modeSettings()
				GUI.modeLabel.Text = string.format("MODE: %s (%s)", State.mode, modeShort)
				GUI.statusLabel.Text = "STATUS: " .. State.status
				GUI.objectsLabel.Text = string.format("Objects: %d", State.counters.objects)
				GUI.effectsLabel.Text = string.format("Effects: %d", State.counters.effects)
				GUI.queueLabel.Text = string.format("Queue: %d", queueSize())
			end)
			task.wait(PERFORMANCE.UPDATE_INTERVAL)
		end
	end)
end

-- =========================================================
-- RESTORE
-- =========================================================
local function restoreAll()
	State.status = "RESTORING"

	for obj, props in pairs(State.originals) do
		if obj and obj.Parent then
			for prop, val in pairs(props) do
				pcall(function() obj[prop] = val end)
			end
		end
	end

	-- Restore lighting
	pcall(function()
		Lighting.GlobalShadows = LightingOriginal.GlobalShadows
		Lighting.Brightness = LightingOriginal.Brightness
		Lighting.Ambient = LightingOriginal.Ambient
		Lighting.OutdoorAmbient = LightingOriginal.OutdoorAmbient
		Lighting.FogEnd = LightingOriginal.FogEnd
	end)
	for key, snap in pairs(LightingEffectOriginal) do
		local fx = LightingEffects[key]
		if fx then
			for prop, val in pairs(snap) do
				pcall(function() fx[prop] = val end)
			end
		end
	end

	-- Clear caches
	State.originals = setmetatable({}, { __mode = "k" })
	State.processedParts = setmetatable({}, { __mode = "k" })
	State.processedEffects = setmetatable({}, { __mode = "k" })
	State.processedLights = setmetatable({}, { __mode = "k" })
	State.distanceState = setmetatable({}, { __mode = "k" })
	State.counters.objects = 0
	State.counters.effects = 0

	State.status = "RESTORED"
	task.delay(1.5, function() State.status = "IDLE" end)
end

-- =========================================================
-- BUTTON WIRING
-- =========================================================
local function setMode(mode)
	State.mode = mode
	State.status = "MODE: " .. mode
	applyLightingForMode()
	task.delay(1.0, function()
		if State.status == "MODE: " .. mode then
			State.status = "IDLE"
		end
	end)
end

GUI.buttons.auto.MouseButton1Click:Connect(function() setMode(MODES.AUTO) end)
GUI.buttons.perf.MouseButton1Click:Connect(function() setMode(MODES.PERFORMANCE) end)
GUI.buttons.bal.MouseButton1Click:Connect(function() setMode(MODES.BALANCED) end)
GUI.buttons.qual.MouseButton1Click:Connect(function() setMode(MODES.QUALITY) end)
GUI.buttons.restore.MouseButton1Click:Connect(function() restoreAll() end)

-- =========================================================
-- CHARACTER HANDLING
-- =========================================================
LocalPlayer.CharacterAdded:Connect(function()
	-- Reset scan caches for the new scene as needed but keep originals
	-- Do not clear processed sets (they're weak anyway)
end)

-- =========================================================
-- MEMORY CLEANUP
-- =========================================================
task.spawn(function()
	while State.running do
		task.wait(15)
		-- Force GC of dead references (weak tables do most of it)
		-- Compact queue if oversized
		if queueSize() > PERFORMANCE.MAX_QUEUE * 0.9 then
			-- drop half to avoid buildup
			local keep = {}
			local n = 0
			while n < PERFORMANCE.MAX_QUEUE * 0.5 do
				local t = queuePop()
				if not t then break end
				table.insert(keep, t)
				n += 1
			end
			for _, t in ipairs(keep) do queuePush(t) end
		end
	end
end)

-- =========================================================
-- LIGHTING PERIODIC REFRESH (not per-frame)
-- =========================================================
task.spawn(function()
	while State.running do
		task.wait(5)
		if State.mode ~= MODES.QUALITY then
			pcall(applyLightingForMode)
		end
	end
end)

-- =========================================================
-- BOOT
-- =========================================================
State.status = "BOOTING"
schedulerLoop()
scannerLoop()
distanceLoop()
guiLoop()

-- Initial lighting pass
task.defer(function()
	task.wait(2)
	pcall(applyLightingForMode)
end)

State.status = "READY"

-- =========================================================
-- EXIT
-- =========================================================
-- Nothing to unload; user can click RESTORE before leaving.