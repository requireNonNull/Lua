-- // Logic
local Logic = {}

local VERSION = "v0.2.9"
local DEBUG_MODE = true

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ==========================
-- Config
-- ==========================
local Farmer = { Running = false, Mode = nil }

local safeModeEnabled = false
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
		if current == "HorseFarming" then
		    task.wait(0.2)
		    continue
		end
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
				local heightOffset = (current == "Coins") and 4 or 12
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

			-- Check if the current mode is related to Coins or XP
			if current == "Coins" or current == "XPAgility" or current == "XPJump" then
			    -- Only wait for deletion if safeModeEnabled is true
			    if safeModeEnabled then
			        local startTime = tick()
			        while obj and obj.Parent and Farmer.Running and Farmer.Mode == current do
			            if tick() - startTime > timeout then break end
			            safeWait(0.1)
			        end
			    end
			else
			    -- Always wait for deletion if it's a resource
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

	-- Dynamic Spawns
    ["BossTotem"] = "workspace.Terrain.TotemModel.BossTotem",

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
        Header = "Dynamics",
        Items = { "BossTotem" }
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
local function findNpcInstance(name)
    local npcFolder = workspace:FindFirstChild("DynamicNPCs")
    if not npcFolder then return nil end

    -- Look through all children with this name
    for _, child in ipairs(npcFolder:GetChildren()) do
        if child.Name == name then
            -- Is this the "real" one? Check for an NPC model or HRP
            if child:FindFirstChild("NPC") then
                return child.NPC -- the model inside
            elseif child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart then
                return child
            end
        end
    end

    return nil
end
	
-- Add a Status field inside Logic
Logic.Status = "Idle"  -- default: Idle, Farming, Waiting, Error, etc.

-- Helper function to resolve a full path string to an instance
local function findPartByPath(path)
    local current = game
    local fullPath = path -- Keep track of the full path being checked
	print("[DEBUG] Attempting to resolve teleport target path:", path)
    
    -- Iterate over each part in the path string
    for part in string.gmatch(path, "[^%.]+") do
        current = current:FindFirstChild(part)
        
        -- If a part doesn't exist at any point, log the failure and return nil
        if not current then
            if DEBUG_MODE then
                print("[DEBUG] Failed to find part at:", fullPath)
            end
            return nil
        end
        fullPath = fullPath .. "." .. part  -- Add the current part to the full path
		print("[DEBUG] Set fullPath:", fullPath)
    end
    
    -- Once the path is resolved, check if it's a BasePart or Model, and return the appropriate part
    if current:IsA("BasePart") or current:IsA("Model") then
        return current
    end
    
    -- If it's a model, return the primary part or any base part inside it
    if current:IsA("Model") then
        if current.PrimaryPart then
            return current.PrimaryPart
        else
            local part = current:FindFirstChildWhichIsA("BasePart")
            return part
        end
    end

    -- If none of the conditions are met, return nil
    return nil
end

-- ==========================
-- Teleport Function with Dynamic Path Resolution
-- ==========================
function Logic.TeleportTo(name)
    local target = Logic.Teleports[name]
    if not target then
        warn("[Logic] Teleport location not found:", name)
        return
    end

    local pos

	-- Debug the target to see what it's set to
    print("[DEBUG] Teleport target:", target)

    -- Check if the target is an NPC and resolve the NPC's position
    if typeof(target) == "string" and string.match(name, "^[%a%s]+$") then
        -- Check if the name corresponds to an NPC in the DynamicNPCs folder
        local npc = findNpcInstance(name)
        if npc then
            if npc:IsA("Model") and npc.PrimaryPart then
                pos = npc.PrimaryPart.Position
            elseif npc:IsA("BasePart") then
                pos = npc.Position
            end
        end
    -- If the target is a string (path), resolve it dynamically
    elseif typeof(target) == "string" then
        local resolved = findPartByPath(target)
        if resolved then
            -- If it's a model or part, get the position
            if resolved:IsA("BasePart") then
                pos = resolved.Position
            elseif resolved:IsA("Model") and resolved.PrimaryPart then
                pos = resolved.PrimaryPart.Position
            end
        end
    -- If the target is already a vector (position)
    elseif typeof(target) == "Vector3" then
        pos = target
    end

    -- Perform teleportation if a valid position is found
    if pos then
        local char = player.Character or player.CharacterAdded:Wait()
        tpTo(char, pos)
        if DEBUG_MODE then
            print("[DEBUG][TP] Teleported to", name, pos)
        end
    else
        warn("[Logic] Failed to resolve teleport target for:", name)
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

Logic.TargetHorse = nil

function Logic.RandomHorseTeleport()
    local char = player.Character or player.CharacterAdded:Wait()
    randomTeleport(char) -- reuses the teleportSpots + tpTo
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
-- Add to the bottom of your Logic Module
-- ==========================
-- ==========================
-- Horse Farming (specific horse support + random teleports)
-- ==========================
do
    local horseFolder = workspace:FindFirstChild("MobFolder")
    local validHorseNames = { "Gargoyle", "Flora" }

    -- Track which horse (if any) the user wants to farm
    Logic.TargetHorse = nil -- nil = farm ANY valid horse

    if horseFolder then
        print("[HorseFarming] horseFolder found:", horseFolder:GetFullName())
    else
        warn("[HorseFarming] horseFolder NOT found!")
    end

    -- === Helpers ===
    local function teleportToHorse(horse)
        if not horse then return end
        local part
        if horse:IsA("BasePart") then
            part = horse
        elseif horse.PrimaryPart then
            part = horse.PrimaryPart
        else
            part = horse:FindFirstChildWhichIsA("BasePart")
        end
        if not part then return end

        local char = player.Character or player.CharacterAdded:Wait()
        if not (char and char:FindFirstChild("HumanoidRootPart")) then return end

        pcall(function()
            tpTo(char, part.Position, 3) -- slight height offset
        end)
        if DEBUG_MODE then print("[HorseFarming] Teleported to horse:", horse.Name) end
        safeWait(0.5)
    end

    local function fireTameEvents(horse)
        if not horse then return end
        local tameEvent = horse:FindFirstChild("TameEvent")
        if not tameEvent then
            if DEBUG_MODE then warn("[HorseFarming] No TameEvent for horse:", horse.Name) end
            return
        end
        pcall(function() tameEvent:FireServer("BeginAggro") end)
        safeWait(1)
        pcall(function() tameEvent:FireServer("SuccessfulFeed") end)
        if DEBUG_MODE then print("[HorseFarming] Fired Tame Events for:", horse.Name) end
    end

	local function waitForAnimalGuiToDisable()
	    -- Always re-fetch PlayerGui each call
	    local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	    if not playerGui then return end
	
	    -- Loop until the GUI is gone or disabled
	    while true do
	        local gui = playerGui:FindFirstChild("DisplayAnimalGui")
	        if not gui or not gui.Parent or not gui:IsA("ScreenGui") or not gui.Enabled then
	            break
	        end
	        task.wait(0.1)
	    end
	end

    local function randomHorseTeleport()
        -- reuse existing teleportSpots
        local char = player.Character or player.CharacterAdded:Wait()
        randomTeleport(char)
    end

    -- === Main Loop ===
    local function horseFarmLoop()
        while true do
            if not Farmer.Running or Farmer.Mode ~= "HorseFarming" then
                task.wait(0.2)
                continue
            end

            if not horseFolder then
                Logic.Status = "[HorseFarming] horseFolder missing!"
                safeWait(2)
                continue
            end

            local horses = horseFolder:GetChildren()
            if #horses == 0 then
                Logic.Status = "Waiting for horses to spawn..."
                randomHorseTeleport()      -- NEW: roam while waiting
                safeWait(5)
                continue
            end

            for _, horse in ipairs(horses) do
                if not Farmer.Running or Farmer.Mode ~= "HorseFarming" then break end

                -- Must be a valid horse, and match target if set
                if table.find(validHorseNames, horse.Name)
                and (not Logic.TargetHorse or Logic.TargetHorse == horse.Name) then

                    Logic.Status = "Taming: " .. horse.Name

                    -- Loop until this horse disappears or farming stops
                    while horse.Parent == horseFolder
                    and Farmer.Running
                    and Farmer.Mode == "HorseFarming" do
                        teleportToHorse(horse)
                        fireTameEvents(horse)
                        safeWait(1)
                    end

                    waitForAnimalGuiToDisable()
                    safeWait(0.2)

                    -- Optional purchase remote after taming
                    local remote = safeFind("ReplicatedStorage.Remotes.PurchaseItemRemote")
                    if remote then
                        pcall(function()
                            remote:InvokeServer("WesternLasso", 1)
                        end)
                        if DEBUG_MODE then print("[HorseFarming] Purchased WesternLasso") end
                    end
                end
            end
        end
    end

    task.spawn(horseFarmLoop)

    -- === Logic API ===
Logic.Resources["HorseFarming"] = {
    start = function(targetHorse)
        if not workspace:FindFirstChild("MobFolder") then
            warn("[HorseFarming] Cannot start: MobFolder missing")
            return
        end
        Logic.TargetHorse = targetHorse or nil
        Logic.start("HorseFarming")
    end,
    stop = function()
        Logic.TargetHorse = nil
        Logic.stop()
    end,
    toggle = function(targetHorse)
        if Farmer.Running and Farmer.Mode == "HorseFarming" then
            Logic.Resources["HorseFarming"].stop()
        else
            Logic.Resources["HorseFarming"].start(targetHorse)
        end
    end
}

end

-- ==========================
-- Export
-- ==========================
return Logic
