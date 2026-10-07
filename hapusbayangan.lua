local Lighting   = game:GetService("Lighting")
local Workspace  = game:GetService("Workspace")
local trigger = script:WaitForChild("ToggleEvent") 
local active        = false
local mainThread    = nil
local addedConn     = nil
local originalGlobalShadows = Lighting.GlobalShadows
local function stripShadow(obj)
	if obj:IsA("BasePart") then
		obj.CastShadow = false
	end
end

local function scanAll()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		stripShadow(obj)
	end
end

local function activate()
	if active then return end
	active = true

	Lighting.GlobalShadows = false
	scanAll()
	addedConn = Workspace.DescendantAdded:Connect(function(obj)
		if active then
			stripShadow(obj)
		end
	end)

	mainThread = task.spawn(function()
		local elapsed = 0
		while active do
			task.wait(0.1)
			elapsed += 0.1

			if elapsed >= 300 then
				elapsed = 0
				scanAll()
			end
		end
	end)
	print("[ShadowRemover] AKTIF")
end

local function deactivate()
	if not active then return end
	active = false

	if addedConn then
		addedConn:Disconnect()
		addedConn = nil
	end

	if mainThread then
		task.cancel(mainThread)
		mainThread = nil
	end

	Lighting.GlobalShadows = originalGlobalShadows

	print("[ShadowRemover] NONAKTIF")
end

trigger.Event:Connect(function()
	if active then
		deactivate()
	else
		activate()
	end
end)