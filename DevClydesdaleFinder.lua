-----------------------
-- CONFIG
-----------------------
local VERSION = "0.7-ClydesdaleFinder"
local HORSE_FOLDER_NAME = "MobFolder"     -- Folder where live horse NPCs spawn
local MOB_SPAWN_FOLDER  = "MobSpawns"     -- Folder containing spawn area parts
local LOOP_INTERVAL     = 0.5             -- How often to scan for horses
local TELEPORT_DELAY    = 0.15            -- Delay after teleport
local SEARCH_DELAY      = 5               -- Time to wait at each spawn area
local EMPTY_FOLDER_WAIT = 3               -- Wait before retry when nothing found
local TELEPORT_HEIGHT_RANGE = {5, 10}     -- Random Y offset

-----------------------
-- TOAST HELPER
-----------------------
local function ShowToast(message)
    pcall(function()
        if arceus and arceus.show_toast then
            arceus.show_toast(message)
        end
    end)
    print(message)
end

-----------------------
-- CLYDESDALE FINDER
-----------------------
local Finder = {}
Finder.__index = Finder

function Finder.new()
    local self = setmetatable({}, Finder)
    self.player      = game.Players.LocalPlayer
    self.horseFolder = workspace:WaitForChild(HORSE_FOLDER_NAME)
    self.spawnFolder = workspace:WaitForChild(MOB_SPAWN_FOLDER)
    self.running     = false
    self.spawnPositions = self:getUniqueSpawnPositions()
    return self
end

-- Collect unique spawn positions
function Finder:getUniqueSpawnPositions()
    local unique, positions = {}, {}
    for _, child in ipairs(self.spawnFolder:GetChildren()) do
        if child:IsA("BasePart") then
            local key = tostring(child.Position)
            if not unique[key] then
                unique[key] = true
                table.insert(positions, child.Position)
            end
        end
    end
    ShowToast("[Finder] Found " .. #positions .. " unique spawn positions.")
    return positions
end

-- Teleport utility
function Finder:teleportTo(pos)
    local char = self.player.Character
    if not (char and char.PrimaryPart) then return end
    local minY, maxY = TELEPORT_HEIGHT_RANGE[1], TELEPORT_HEIGHT_RANGE[2]
    local offset = math.random(minY, maxY)
    pcall(function()
        char:SetPrimaryPartCFrame(CFrame.new(pos.X, pos.Y + offset, pos.Z))
    end)
    task.wait(TELEPORT_DELAY)
end

-- Loop teleporting to a Clydesdale until despawn
function Finder:teleportToHorse(horse)
    while self.running and horse.Parent == self.horseFolder do
        self:teleportTo(horse.Position)
        task.wait(0.2)
    end
    ShowToast("[Finder] Clydesdale despawned, resuming patrol...")
end

-- Patrol spawn areas when no horse exists
function Finder:searchSpawnAreas()
    for _, pos in ipairs(self.spawnPositions) do
        if not self.running then return end
        self:teleportTo(pos)
        task.wait(SEARCH_DELAY)
        -- Check mid-patrol if a Clydesdale spawned
        for _, h in ipairs(self.horseFolder:GetChildren()) do
            if string.find(h.Name:lower(), "clydesdale") then
                return h
            end
        end
    end
end

-- Main loop
function Finder:start()
    if self.running then return end
    self.running = true
    ShowToast("[Finder] Starting Clydesdale search loop...")

    task.spawn(function()
        while self.running do
            task.wait(LOOP_INTERVAL)

            self.horseFolder = workspace:FindFirstChild(HORSE_FOLDER_NAME)
            if not self.horseFolder then
                ShowToast("[Finder] MobFolder missing, retrying...")
                task.wait(5)
                continue
            end

            local target
            for _, h in ipairs(self.horseFolder:GetChildren()) do
                if string.find(h.Name:lower(), "clydesdale") then
                    target = h
                    break
                end
            end

            if target then
                ShowToast("[Finder] Found Clydesdale: " .. target.Name)
                self:teleportToHorse(target)
            else
                ShowToast("[Finder] No Clydesdale, patrolling spawns...")
                target = self:searchSpawnAreas()
                if target then
                    ShowToast("[Finder] Found Clydesdale mid-patrol: " .. target.Name)
                    self:teleportToHorse(target)
                else
                    task.wait(EMPTY_FOLDER_WAIT)
                end
            end
        end
        ShowToast("[Finder] Loop stopped.")
    end)
end

function Finder:stop()
    self.running = false
    ShowToast("[Finder] Stopping loop...")
end

-----------------------
-- Example Usage
-----------------------
print("DevClydesdaleFinder: " .. VERSION)
ShowToast("DevClydesdaleFinder: " .. VERSION)

local finder = Finder.new()
finder:start()

-- Optional: stop after 12 hours
task.delay(43200, function() finder:stop() end)
