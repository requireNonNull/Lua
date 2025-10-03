-----------------------
-- CONFIG
-----------------------
local VERSION = "0.1-ClydesdaleOnly"
local HORSE_FOLDER_NAME = "MobFolder"       -- Folder where live horse NPCs spawn
local MOB_SPAWN_FOLDER  = "MobSpawns"       -- Folder containing spawn area parts
local LOOP_INTERVAL     = 0.5               -- How often to scan for horses
local TELEPORT_DELAY    = 0.15              -- Delay after teleport
local TELEPORT_HEIGHT_RANGE = {5, 10}       -- Random Y offset when teleporting

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
-- HORSE TELEPORTER
-----------------------
local Teleporter = {}
Teleporter.__index = Teleporter

function Teleporter.new()
    local self = setmetatable({}, Teleporter)
    self.player      = game.Players.LocalPlayer
    self.horseFolder = workspace:WaitForChild(HORSE_FOLDER_NAME)
    self.running     = false
    return self
end

function Teleporter:teleportTo(position)
    local char = self.player.Character
    if not (char and char.PrimaryPart) then return false end

    local minY, maxY = TELEPORT_HEIGHT_RANGE[1], TELEPORT_HEIGHT_RANGE[2]
    local offset = math.random(minY, maxY)

    pcall(function()
        char:SetPrimaryPartCFrame(CFrame.new(
            position.X,
            position.Y + offset,
            position.Z
        ))
    end)

    task.wait(TELEPORT_DELAY)
    return true
end

function Teleporter:teleportToHorse(horse)
    while self.running and horse.Parent == self.horseFolder do
        self:teleportTo(horse.Position)
        task.wait(0.2)
    end
    ShowToast("[Teleporter] Clydesdale despawned, stopping teleport loop.")
end

function Teleporter:start()
    if self.running then
        warn("Teleporter already running")
        return
    end
    self.running = true
    ShowToast("[Teleporter] Starting Clydesdale search loop...")

    task.spawn(function()
        while self.running do
            task.wait(LOOP_INTERVAL)

            -- Refresh folder reference
            self.horseFolder = workspace:FindFirstChild(HORSE_FOLDER_NAME)
            if not self.horseFolder then continue end

            for _, h in ipairs(self.horseFolder:GetChildren()) do
                if string.find(h.Name:lower(), "clydesdale") then
                    ShowToast("[Teleporter] Found Clydesdale: " .. h.Name)
                    self:teleportToHorse(h)
                end
            end
        end
    end)
end

function Teleporter:stop()
    if not self.running then return end
    self.running = false
    ShowToast("[Teleporter] Loop stopped.")
end

-----------------------
-- Example Usage
-----------------------
print("ClydesdaleFinder: " .. VERSION)
ShowToast("ClydesdaleFinder: " .. VERSION)

local tele = Teleporter.new()
tele:start()

-- Optional: auto-stop after 12 hours
task.delay(43200, function() 
    tele:stop() 
end)
