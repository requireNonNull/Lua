-- // Logic
local Logic = {}

local VERSION = "v0.1.0"
local DEBUG_MODE = true

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ==========================
-- Config
-- ==========================
local Farmer = { Running = false, Mode = nil }

local safeModeEnabled = true
local TeleportDelay = 0.5 -- Default delay

-- ==========================
-- Helpers
-- ==========================
local function safeWait(base)
	if safeModeEnabled then
		task.wait(base + math.random() * 0.5)
	else
		task.wait(base)
	end
end

local function safeFind(path)
	local current = workspace
	for part in string.gmatch(path, "[^%.]+") do
		current = current:FindFirstChild(part)
		if not current then return nil end
	end
	return current
end

local function randomizePos(pos)
	if safeModeEnabled then
		local offset = Vector3.new((math.random() - 0.5) * 2, 0, (math.random() - 0.5) * 2)
		return pos + offset
	end
	return pos
end

local function tpTo(char, pos, heightOffset)
	if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
	pcall(function()
		char.HumanoidRootPart.CFrame = CFrame.new(randomizePos(pos) + Vector3.new(0, heightOffset or 1, 0))
	end)
	if DEBUG_MODE then print("[DEBUG][TP] Teleported to", pos) end
end

-- ==========================
-- Random Teleport
-- ==========================
local teleportSpots = {
	Vector3.new(5, 13, 17),
	Vector3.new(-421, 36, -902),
	Vector3.new(1209, 41, -30),
	Vector3.new(2067, 19, -367),
	Vector3.new(2128, 71, -1241),
	Vector3.new(1097, 107, -2018),
	Vector3.new(421, 73, -2572),
	Vector3.new(-118, 19, -1675),
	Vector3.new(-1078, 138, -1772),
	Vector3.new(-1774, 112, -1120),
	Vector3.new(-1815, 42, -277),
	Vector3.new(-1063, 21, -114),
	Vector3.new(-661, 56, 375)
}

local function randomTeleport(char)
	local spot = teleportSpots[math.random(1, #teleportSpots)]
	tpTo(char, spot)
end

-- ==========================
-- Resource Definitions
-- ==========================
local resourceTimeouts = {
	Coins = 5,
	XPAgility = 5,
	XPJump = 5,
	AppleBarrel = 10,
	BerryBush = 10,
	FallenTree = 12.5,
	FoodPallet = 10,
	LargeBerryBush = 36,
	SilkBush = 100,
	StoneDeposit = 25,
	Stump = 17.5,
	CactusFruit = 30,
	Treasure = 25,
	DailyChest = 100,
	DiggingNodes = 10,
	Infection = 75,
	InfectionEgg = 137.5
}

local resourcePaths = {
	Coins = safeFind("Interactions.CurrencyNodes.Spawned"),
	XPAgility = safeFind("Interactions.CurrencyNodes.Spawned"),
	XPJump = safeFind("Interactions.CurrencyNodes.Spawned"),
	AppleBarrel = safeFind("Interactions.Resource"),
	BerryBush = safeFind("Interactions.Resource"),
	FallenTree = safeFind("Interactions.Resource"),
	FoodPallet = safeFind("Interactions.Resource"),
	LargeBerryBush = safeFind("Interactions.Resource"),
	SilkBush = safeFind("Interactions.Resource"),
	StoneDeposit = safeFind("Interactions.Resource"),
	Stump = safeFind("Interactions.Resource"),
	CactusFruit = safeFind("Interactions.Resource"),
	Treasure = safeFind("Interactions.Resource"),
	DailyChest = safeFind("LocalResources"),
	DiggingNodes = safeFind("LocalResources"),
	Infection = safeFind("Interactions.Resource"),
	InfectionEgg = safeFind("Interactions.Resource")
}

-- ==========================
-- Farming Loop
-- ==========================
local function farmingLoop()
	while true do
		if not Farmer.Running or not Farmer.Mode then
			task.wait(0.1)
			continue
		end

		local char = player.Character or player.CharacterAdded:Wait()
		local current = Farmer.Mode
		local timeout = resourceTimeouts[current] or 10
		local folder = resourcePaths[current]

		if not folder then
			if DEBUG_MODE then warn("[DEBUG] Resource folder not found for:", current) end
			Logic.Status = "Folder not found for: " .. current
			safeWait(1)
			continue
		end

		local targets = {}
		for _, obj in ipairs(folder:GetChildren()) do
			if obj.Name == current or obj.Parent.Name == current then
				table.insert(targets, obj)
			end
		end

		if #targets == 0 then
			Logic.Status = "Waiting for " .. current
			randomTeleport(char)
			safeWait(3)
			continue
		end
		
		Logic.Status = "Found " .. #targets .. " of " .. current
		task.wait(0.5)

		local collected = 0
		local dropped = 0
		for _, obj in ipairs(targets) do
		    if not Farmer.Running or Farmer.Mode ~= current then break end
		
		    if not obj or not obj.Parent then
		        dropped += 1
		        continue
		    end
		
		    collected += 1
		    local remaining = #targets - dropped
		    Logic.Status = "Collecting " .. collected .. " of " .. remaining .. " " .. current
	
			local pos
			pcall(function()
				local ok, pivot = pcall(function() return obj:GetPivot().Position end)
				if ok then
					pos = pivot
				elseif obj.PrimaryPart then
					pos = obj.PrimaryPart.Position
				else
					local part = obj:FindFirstChildWhichIsA("BasePart")
					if part then pos = part.Position end
				end
			end)

			if pos then
				local heightOffset = (current == "Coins") and 1 or 12
				tpTo(char, pos, heightOffset)
				safeWait(TeleportDelay)
			end

			pcall(function()
				local cd = obj:FindFirstChildOfClass("ClickDetector")
				if cd then
					if safeModeEnabled then task.wait(math.random() * 0.3) end
					fireclickdetector(cd)
				end
			end)

			if current ~= "Coins" and current ~= "XPAgility" and current ~= "XPJump" then
				local startTime = tick()
				while obj and obj.Parent and Farmer.Running and Farmer.Mode == current do
					if tick() - startTime > timeout then break end
					safeWait(0.1)
				end
			end

			task.wait(0.1)
		end
	end
end

task.spawn(farmingLoop)

-- ==========================
-- Logic API
-- ==========================

Logic.Teleports = {
    -- Main Locations
    ["Spawn"] = Vector3.new(6, 11, -30),
    ["Shop"] = Vector3.new(-80, 14, 110),
    ["Equipment"] = Vector3.new(-59, 14, 119),
    ["Market Realm"] = Vector3.new(65, 11, -28),
    ["Board Storage"] = Vector3.new(-231, 13, -148),
    ["Horse Shrine"] = Vector3.new(460, 21, 245),
    ["Plush Machine"] = Vector3.new(1885, 14, -310),

    -- Farming / Resource Spots
    ["Dig Site"] = Vector3.new(-172, 13, -1485),
    ["Fishing Spot"] = Vector3.new(221, 13, 172),
    ["Garden Plot"] = Vector3.new(-250, 15, -258),

    -- Contests / Minigames
    ["Training Course"] = Vector3.new(175, 13, -220),
    ["Taming Contest"] = Vector3.new(162, 15, 32),
    ["Cosmetic Contest"] = Vector3.new(82, 15, 129),

    -- Events
    ["Alien Event"] = Vector3.new(-1805, 41, -227),

    -- NPCs
    ["Orion"] = "workspace.DynamicNPCs.Orion",
    ["Alex"] = "workspace.DynamicNPCs.Alex",
    ["Aurelia"] = "workspace.DynamicNPCs.Aurelia",
    ["Lyric"] = "workspace.DynamicNPCs.Lyric"
}

-- ==========================
-- Teleport Categories (ordered for UI)
-- ==========================
Logic.TeleportCategories = {
    {
        Header = "Main Locations",
        Items = { "Spawn", "Shop", "Equipment", "Market Realm", "Board Storage", "Horse Shrine", "Plush Machine"  }
    },
    {
        Header = "Farming Spots",
        Items = { "Dig Site", "Fishing Spot", "Garden Plot"}
    },
    {
        Header = "Contests",
        Items = { "Training Course", "Taming Contest", "Cosmetic Contest" }
    },
    {
        Header = "Events",
        Items = { "Alien Event" }
    },
    {
        Header = "NPCs",
        Items = { "Orion", "Alex", "Aurelia", "Lyric" }
    }
}
-- ==========================
-- Dynamic position resolver
local function getPositionFromPath(path)
    if typeof(path) == "Vector3" then
        return path
    elseif typeof(path) == "string" then
        local current = game
        for segment in string.gmatch(path, "[^%.]+") do
            current = current:FindFirstChild(segment)
            if not current then return nil end
        end
        -- Try to get position from BasePart inside model
        if current:IsA("BasePart") then
            return current.Position
        elseif current:FindFirstChildWhichIsA("BasePart") then
            return current:FindFirstChildWhichIsA("BasePart").Position
        else
            warn("[Logic] Could not find a BasePart in model:", path)
            return nil
        end
    end
    return nil
end

-- Add a Status field inside Logic
Logic.Status = "Idle"  -- default: Idle, Farming, Waiting, Error, etc.

function Logic.TeleportTo(name)
    local target = Logic.Teleports[name]
    if not target then
        warn("[Logic] Teleport location not found:", name)
        return
    end

    local pos = getPositionFromPath(target)
    if pos then
        local char = player.Character or player.CharacterAdded:Wait()
        tpTo(char, pos)
    end
end

function Logic.start(resourceName)
	Farmer.Mode = resourceName
	Farmer.Running = true
	Logic.Status = " " .. resourceName
	print("[INFO] Farming started for:", resourceName)
end

function Logic.stop()
	Farmer.Running = false
	Farmer.Mode = nil
	print("[INFO] Farming stopped.")
end

function Logic.toggle(resourceName)
	if Farmer.Running and Farmer.Mode == resourceName then
		Logic.stop()
	else
		Logic.start(resourceName)
	end
end

-- Table to track UI toggles
local UIToggles = {}

-- Set a resource as toggled on/off in the UI
function Logic.setUIToggled(resourceName, value)
    UIToggles[resourceName] = value and true or false
end

-- Check if a resource is toggled in the UI
function Logic.isUIToggled(resourceName)
    return UIToggles[resourceName] or false
end

-- Extend getState to include UI toggle info
function Logic.getState()
    return {
        running = Farmer.Running,
        mode = Farmer.Mode,
        uiToggled = UIToggles
    }
end

function Logic.GetStatus()
    return Logic.Status
end

function Logic.SetStatus(newStatus)
    if type(newStatus) ~= "string" then return end
    Logic.Status = newStatus
end

function Logic.SetTpDelay(delay)
	if type(delay) ~= "number" or delay <= 0 then
		warn("[Logic] Invalid teleport delay:", delay)
		return
	end
	TeleportDelay = delay
	if DEBUG_MODE then
		print("[DEBUG] Teleport delay set to", TeleportDelay)
	end
end

function Logic.GetVersion()
    return VERSION
end

-- ==========================
-- Resource API (Ordered)
-- ==========================
Logic.ResourceList = {
	"Coins",
	"XPAgility",
	"XPJump",
	"AppleBarrel",
	"BerryBush",
	"FallenTree",
	"FoodPallet",
	"LargeBerryBush",
	"SilkBush",
	"StoneDeposit",
	"Stump",
	"CactusFruit",
	"Treasure",
	"DailyChest",
	"DiggingNodes",
	"Infection",
	"InfectionEgg"
}

Logic.Resources = {}
for _, resourceName in ipairs(Logic.ResourceList) do
	Logic.Resources[resourceName] = {
		start = function() Logic.start(resourceName) end,
		stop = Logic.stop,
		toggle = function() Logic.toggle(resourceName) end
	}
end

-- ==========================
-- Export
-- ==========================
return Logic
