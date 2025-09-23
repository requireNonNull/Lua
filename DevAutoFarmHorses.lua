--// Version 1.4.0 - Adds spawn search positions, toggle start/stop, and multi-horse farming
--// Place this in a LocalScript

-----------------------
-- CONFIG
-----------------------
local HORSE_SPAWN_POSITIONS = {
    Gargoyle = {
        Vector3.new(1588, 18, -887),
        Vector3.new(1720, 85, -133)
    },
    Flora = {
        Vector3.new(2122, 238, -1670),
        Vector3.new(2115, 20, -517),
        Vector3.new(-1194, 20, -1113)
    }
}

local HORSE_FOLDER_NAME = "MobFolder"
local ITEM_TO_PURCHASE  = {"WesternLasso", 1}   -- Args for PurchaseItemRemote
local EMPTY_FOLDER_WAIT = 5                     -- Wait when no horses found before next search
local LOOP_INTERVAL     = 0.5                   -- Main loop delay
local TELEPORT_DELAY    = 0.5                   -- Delay after teleport
local FEED_DELAY        = 1                     -- Delay between TameEvent fires
local PURCHASE_DELAY    = 1                     -- Delay before next horse
local GUI_TIMEOUT       = 10                    -- Max seconds to wait for DisplayAnimalGui
local HORSE_TIMEOUT     = 30                    -- Max seconds to stay with a single horse
local SEARCH_DELAY      = 2                     -- Delay between teleporting to spawn positions

-----------------------
-- HORSE FARMER CLASS
-----------------------
local HorseFarmer = {}
HorseFarmer.__index = HorseFarmer

function HorseFarmer.new(horseTypes)
    local self = setmetatable({}, HorseFarmer)

    self.player      = game.Players.LocalPlayer
    self.horseFolder = workspace:FindFirstChild(HORSE_FOLDER_NAME)
    self.camera      = workspace.CurrentCamera
    self.remotes     = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")

    assert(self.player,      "LocalPlayer not found!")
    assert(self.horseFolder, "MobFolder not found!")
    assert(self.camera,      "Camera not found!")
    assert(self.remotes,     "Remotes folder not found!")

    -- farming settings
    self.targetHorseTypes = horseTypes or {}  -- e.g. {"Flora"} or {"Gargoyle","Flora"}
    self.running = false

    return self
end

-----------------------
-- Internal Helpers
-----------------------
function HorseFarmer:waitForAnimalGui()
    local gui = self.player:FindFirstChild("PlayerGui")
    if not gui then return end
    local start = tick()
    while tick() - start < GUI_TIMEOUT do
        local display = gui:FindFirstChild("DisplayAnimalGui")
        if not (display and display.Enabled) then break end
        task.wait(0.1)
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

function HorseFarmer:processHorse(horse)
    local start = tick()
    while self.running and horse.Parent == self.horseFolder and tick() - start < HORSE_TIMEOUT do
        if not self:teleportToHorse(horse) then break end
        self:interactWithHorse(horse)
        task.wait(1)
    end
    self:waitForAnimalGui()
    self:purchaseItem()
end

-- Search spawn positions when no horses are found
function HorseFarmer:searchSpawnAreas()
    for _, horseType in ipairs(self.targetHorseTypes) do
        local positions = HORSE_SPAWN_POSITIONS[horseType]
        if positions then
            for _, pos in ipairs(positions) do
                if not self.running then return end
                print("[HorseFarmer] Searching spawn area:", horseType, pos)
                self:teleportTo(pos)
                task.wait(SEARCH_DELAY)
            end
        end
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

            -- Refresh folder reference
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
                print("[HorseFarmer] No horses found, searching spawn areas...")
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
-- You can expose these to a UI button:
-- Example: Start farming only Flora
--   local farmer = HorseFarmer.new({"Flora"})
--   farmer:start()
--
-- Example: Start farming Gargoyle
--   local farmer = HorseFarmer.new({"Gargoyle"})
--   farmer:start()
--
-- To stop farming from a UI toggle:
--   farmer:stop()

--[[  ❗ SAMPLE DEMO ❗
]]
-- Remove or comment out this demo when connecting to a UI
local farmer = HorseFarmer.new({"Flora"})  -- Change to {"Gargoyle"} or both
farmer:start()

-- Stop after 60 seconds (demo only)
task.delay(60, function()
    farmer:stop()
end)
