--// Version 1.7.1 - Farm all species high→low + optional auto-sell + force-close GUI
--// Place in a LocalScript

-----------------------
-- CONFIG
-----------------------
local HORSE_FOLDER_NAME = "MobFolder"            -- Folder where live horse NPCs spawn
local MOB_SPAWN_FOLDER  = "MobSpawns"            -- Folder containing spawn area parts
local ITEM_TO_PURCHASE  = {"WesternLasso", 1}    -- Args for PurchaseItemRemote
local EMPTY_FOLDER_WAIT = 5
local LOOP_INTERVAL     = 0.5
local TELEPORT_DELAY    = 0.5
local FEED_DELAY        = 1
local PURCHASE_DELAY    = 1
local GUI_TIMEOUT       = 3       -- seconds to wait before we kill the GUI
local HORSE_TIMEOUT     = 30
local SEARCH_DELAY      = 2

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

function HorseFarmer.new(horseTypes, autoSell)
    local self = setmetatable({}, HorseFarmer)

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

    self.targetHorseTypes = horseTypes or {}
    self.autoSell         = autoSell or false
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
    return positions
end

-----------------------
-- Internal Helpers
-----------------------
function HorseFarmer:waitForAnimalGui()
    local gui = self.player:FindFirstChild("PlayerGui")
    if not gui then return end
    local start = tick()
    local display = gui:FindFirstChild("DisplayAnimalGui")
    while display and display.Enabled and tick() - start < GUI_TIMEOUT do
        task.wait(0.1)
        display = gui:FindFirstChild("DisplayAnimalGui")
    end
    -- ⭐ FORCE DISABLE if still present
    if display and display.Enabled then
        warn("[HorseFarmer] GUI timeout, forcing disable.")
        pcall(function() display.Enabled = false end)
    end
end

function HorseFarmer:teleportTo(position)
    local character = self.player.Character
    if not (character and character.PrimaryPart) then return false end
    pcall(function()
        character:SetPrimaryPartCFrame(CFrame.new(position))
    end)
    task.wait(TELEPORT_DELAY)
    return true
end

function HorseFarmer:teleportToHorse(horse)
    if not (horse and horse:IsA("BasePart")) then return false end
    return self:teleportTo(horse.Position)
end

function HorseFarmer:interactWithHorse(horse)
    if not (horse and horse:IsA("BasePart")) then return end
    if not isrbxactive() then
        warn("Roblox window not active, skipping interaction.")
        return
    end

    local screenPos, onScreen = self.camera:WorldToScreenPoint(horse.Position)
    if onScreen then
        pcall(function() mousemoveabs(screenPos.X, screenPos.Y) end)
    end

    local tameEvent = horse:FindFirstChild("TameEvent")
    if not tameEvent then return end

    pcall(function() tameEvent:FireServer("BeginAggro") end)
    task.wait(FEED_DELAY)
    pcall(function() tameEvent:FireServer("SuccessfulFeed") end)
end

function HorseFarmer:purchaseItem()
    local remote = self.remotes:FindFirstChild("PurchaseItemRemote")
    if not remote then
        warn("PurchaseItemRemote not found!")
        return
    end
    pcall(function() remote:InvokeServer(unpack(ITEM_TO_PURCHASE)) end)
    task.wait(PURCHASE_DELAY)
end

-- Sell all horses whose names are numbers
function HorseFarmer:sellAllAnimals()
    if not self.autoSell then return end
    local charFolder = workspace:FindFirstChild("Characters")
    if not charFolder then return end
    local playerFolder = charFolder:FindFirstChild(self.player.Name)
    if not playerFolder then return end
    local animals = playerFolder:FindFirstChild("Animals")
    if not animals then return end

    local slotNumbers = {}
    for _, child in ipairs(animals:GetChildren()) do
        if tonumber(child.Name) then
            table.insert(slotNumbers, child.Name)
        end
    end

    if #slotNumbers > 0 then
        local remote = self.remotes:FindFirstChild("SellSlotsRemote")
        if remote then
            print("[HorseFarmer] Auto-selling slots:", table.concat(slotNumbers, ", "))
            pcall(function()
                remote:InvokeServer(slotNumbers)
            end)
        end
    end
end

function HorseFarmer:processHorse(horse)
    local start = tick()
    while self.running and horse.Parent == self.horseFolder and tick() - start < HORSE_TIMEOUT do
        if not self:teleportToHorse(horse) then break end
        self:interactWithHorse(horse)
        task.wait(1)
    end
    self:waitForAnimalGui()
    self:purchaseItem()
    self:sellAllAnimals()
end

function HorseFarmer:searchSpawnAreas()
    for _, pos in ipairs(self.spawnPositions) do
        if not self.running then return end
        self:teleportTo(pos)
        task.wait(SEARCH_DELAY)
    end
end

-----------------------
-- Public API
-----------------------
function HorseFarmer:start()
    if self.running then
        warn("HorseFarmer already running.")
        return
    end
    self.running = true
    print("[HorseFarmer] Starting loop for:", table.concat(self.targetHorseTypes, ", "))

    task.spawn(function()
        while self.running do
            task.wait(LOOP_INTERVAL)

            self.horseFolder = workspace:FindFirstChild(HORSE_FOLDER_NAME)
            if not self.horseFolder then
                warn("MobFolder missing, retrying in 5s...")
                task.wait(5)
                continue
            end

            local horses = {}
            for _, h in ipairs(self.horseFolder:GetChildren()) do
                if table.find(self.targetHorseTypes, h.Name) then
                    table.insert(horses, h)
                end
            end

            if #horses == 0 then
                print("[HorseFarmer] No target horses found. Searching spawn areas...")
                self:searchSpawnAreas()
                task.wait(EMPTY_FOLDER_WAIT)
            else
                for _, horse in ipairs(horses) do
                    if not self.running then break end
                    print("[HorseFarmer] Farming horse:", horse.Name)
                    self:processHorse(horse)
                    task.wait()
                end
            end
        end
        print("[HorseFarmer] Loop stopped.")
    end)
end

function HorseFarmer:stop()
    if not self.running then return end
    print("[HorseFarmer] Stopping loop...")
    self.running = false
end

-----------------------
-- Example Usage
-----------------------
local allTargets = HorseFarmer.getAllSpeciesHighToLow()
local farmer = HorseFarmer.new(allTargets, true) -- true = enable auto-sell
farmer:start()

-- Optional stop after 5 minutes
task.delay(300, function()
    farmer:stop()
end)
