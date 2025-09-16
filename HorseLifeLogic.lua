-- // 🦄 Farmy Logic Only - v6.7 stripped
local DEBUG_MODE = true

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- ==========================
-- Config
-- ==========================
local Farmer = {Running = false, Mode = nil}

-- Set manually
local safeModeEnabled = true
local TeleportDelay = 0.8 -- Default delay

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
-- Resource Settings
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
local function startFarming()
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
			randomTeleport(char)
			safeWait(3)
			continue
		end

		for _, obj in ipairs(targets) do
			if not Farmer.Running or Farmer.Mode ~= current then break end
			if not obj or not obj.Parent then continue end

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

-- ==========================
-- Start Script
-- ==========================

-- Example: Start farming coins
Farmer.Running = true
Farmer.Mode = "Coins" -- Change to "XPAgility", "FallenTree", etc

-- Background farming loop
task.spawn(startFarming)

print("[INFO] Stripped farming script is running.")
