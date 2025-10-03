-----------------------
-- CONFIG
-----------------------
local VERSION = "0.2.5"
local HORSE_FOLDER_NAME = "MobFolder"            -- Folder where live horse NPCs spawn
local MOB_SPAWN_FOLDER  = "MobSpawns"            -- Folder containing spawn area parts
local ITEM_TO_PURCHASE  = {"WesternLasso", 1}    -- Args for PurchaseItemRemote
local EMPTY_FOLDER_WAIT = 5
local LOOP_INTERVAL     = 0.5
local TELEPORT_DELAY    = 0.15
local FEED_DELAY        = 0.6
local PURCHASE_DELAY    = 0.2
local GUI_TIMEOUT       = 1       -- seconds to wait before we kill the GUI
local HORSE_TIMEOUT     = 20
local SEARCH_DELAY      = 5
local TELEPORT_HEIGHT_RANGE = {5, 10}  -- min, max random Y offset
local IGNORE_SUBSTRINGS = {"Boss"}  -- add any others you want to skip
local GOAL_POINTS       = 2000     -- stop when this many points reached

-----------------------
-- HORSE POINT TABLE
-----------------------
local HORSE_POINTS = {
    {name="Hippocampus", pts=9},
    {name="Felorse",     pts=9},
    {name="Flora",       pts=8},
    {name="Fae",         pts=7},
    {name="Cactaline",   pts=6},
    {name="Kelpie",      pts=6},
    {name="Peryton",     pts=6},
    {name="Gargoyle",    pts=4},
    {name="Clydesdale",  pts=4},
    {name="Unicorn",     pts=4},
    {name="Caprine",     pts=3},
    {name="Bisorse",     pts=2},
    {name="Horse",       pts=1},
    {name="Pony",        pts=1},
    {name="Equus",       pts=1},
}

-----------------------
-- HORSE FARMER CLASS
-----------------------
local HorseFarmer = {}
HorseFarmer.__index = HorseFarmer

-- Helper: return every species sorted by points high→low
function HorseFarmer.getAllSpeciesHighToLow()
    table.sort(HORSE_POINTS, function(a,b) return a.pts > b.pts end)
    local list = {}
    for _, entry in ipairs(HORSE_POINTS) do
        table.insert(list, entry.name)
    end
    return list
end

function HorseFarmer.new(config)
    local self = setmetatable({}, HorseFarmer)

    self.previousCoins = 0
    self.totalSpentOnLassos = 0
    self.totalPoints = 0  -- ⭐ track total points

    self.player      = game.Players.LocalPlayer
    self.horseFolder = workspace:FindFirstChild(HORSE_FOLDER_NAME)
    self.spawnFolder = workspace:FindFirstChild(MOB_SPAWN_FOLDER)
    self.camera      = workspace.CurrentCamera
    self.remotes     = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")

    assert(self.player,      "LocalPlayer not found!")
    assert(self.horseFolder, "MobFolder not found!")
    assert(self.spawnFolder, "MobSpawns folder not found!")
    assert(self.camera,      "Camera not found!")
    assert(self.remotes,     "Remotes folder not found!")

    -- ✅ config table with defaults
    self.targetHorseTypes = config.targets or {}
    self.autoSell         = config.autoSell or false
    self.forceCloseGui    = config.forceCloseGui or false
    self.running          = false
    self.spawnPositions   = self:getUniqueSpawnPositions()

    return self
end

-----------------------
-- Utility: Collect all spawn positions
-----------------------
function HorseFarmer:getUniqueSpawnPositions()
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
    print("[HorseFarmer] Found " .. #positions .. " unique spawn positions.")
    ShowToast("[HorseFarmer] Found " .. #positions .. " unique spawn positions.")
    return positions
end

-----------------------
-- Internal Helpers
-----------------------
function ShowToast(message)
    pcall(function()
        if arceus and arceus.show_toast then
            arceus.show_toast(message)
        end
    end)
end

-----------------------
-- Fuzzy Horse Name Helper
-----------------------
local function normalizeHorseName(name)
    for _, skip in ipairs(IGNORE_SUBSTRINGS) do
        if string.find(name:lower(), skip:lower()) then
            return nil
        end
    end
    for _, entry in ipairs(HORSE_POINTS) do
        local base = entry.name:lower()
        if string.find(name:lower(), base) then
            return entry.name
        end
    end
    return name
end

-----------------------
-- PROCESS HORSE
-----------------------
function HorseFarmer:processHorse(horse)
    local start = tick()

    self:sellAllAnimals()
    task.wait(0.2)

    local beforeCount = select(1, self:getStableCount())

    while self.running and horse.Parent == self.horseFolder and tick() - start < HORSE_TIMEOUT do
        if not self:teleportToHorse(horse) then break end
        self:checkIfNeedsNewLasso()
        task.wait(0.15)
        self:interactWithHorse(horse)
    end

    task.wait(0.2)
    self:waitForAnimalGui()
    task.wait(0.5)

    local afterCount = select(1, self:getStableCount())

    if beforeCount and afterCount and afterCount > beforeCount then
        -- ⭐ success → add points
        local baseName = normalizeHorseName(horse.Name)
        local pts = 0
        for _, entry in ipairs(HORSE_POINTS) do
            if entry.name == baseName then
                pts = entry.pts
                break
            end
        end

        self.totalPoints = self.totalPoints + pts
        print(string.format("[HorseFarmer] ✅ Stable count increased (%d → %d). +%d pts (Total: %d)", beforeCount, afterCount, pts, self.totalPoints))
        ShowToast(string.format("✅ +%d pts (Total: %d)", pts, self.totalPoints))

        if self.totalPoints >= GOAL_POINTS then
            print("[HorseFarmer] 🎉 Goal reached: " .. GOAL_POINTS .. " points. Stopping farmer.")
            ShowToast("🎉 Goal reached: " .. GOAL_POINTS .. " points. Stopping farmer.")
            self:stop()
        end
    else
        warn("[HorseFarmer] ❌ Failed to process: " .. horse.Name)
        ShowToast("[HorseFarmer] ❌ Failed to process: " .. horse.Name)
    end
end

-----------------------
-- START/STOP
-----------------------
function HorseFarmer:start()
    if self.running then
        warn("HorseFarmer already running.")
        ShowToast("HorseFarmer already running.")
        return
    end
    self.running = true
    print("[HorseFarmer] Starting loop for:", table.concat(self.targetHorseTypes, ", "))
    ShowToast("[HorseFarmer] Starting loop for: " .. table.concat(self.targetHorseTypes, ", "))

    task.spawn(function()
        while self.running do
            task.wait(LOOP_INTERVAL)
            if self.totalPoints >= GOAL_POINTS then break end

            self.horseFolder = workspace:FindFirstChild(HORSE_FOLDER_NAME)
            if not self.horseFolder then
                warn("MobFolder missing, retrying in 5s...")
                ShowToast("MobFolder missing, retrying in 5s...")
                task.wait(5)
                continue
            end

            local horses = {}
            for _, h in ipairs(self.horseFolder:GetChildren()) do
                local baseName = normalizeHorseName(h.Name)
                if baseName and table.find(self.targetHorseTypes, baseName) then
                    print("[HorseFarmer] Found horse:", h.Name)
                    ShowToast("[HorseFarmer] Found horse: " .. h.Name)
                    table.insert(horses, h)
                end
            end

            if #horses == 0 then
                print("[HorseFarmer] No target horses found. Searching spawn areas...")
                ShowToast("[HorseFarmer] No target horses found. Searching spawn areas...")
                horses = self:searchSpawnAreas() or {}
                task.wait(EMPTY_FOLDER_WAIT)
            else
                for _, horse in ipairs(horses) do
                    if not self.running then break end
                    self:processHorse(horse)
                    task.wait()
                end
            end
        end
        print("[HorseFarmer] Loop stopped.")
        ShowToast("[HorseFarmer] Loop stopped.")
    end)
end

function HorseFarmer:stop()
    if not self.running then return end
    print("[HorseFarmer] Stopping loop...")
    ShowToast("[HorseFarmer] Stopping loop...")
    self.running = false
end

-----------------------
-- Example Usage
-----------------------
print("DevAutoFarmHorses: " .. VERSION)
ShowToast("DevAutoFarmHorses: " .. VERSION)

local farmer = HorseFarmer.new({
    targets = HorseFarmer.getAllSpeciesHighToLow(),
    autoSell = true,
    forceCloseGui = true,
})

farmer:start()
