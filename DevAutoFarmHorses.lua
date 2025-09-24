-----------------------
-- CONFIG
-----------------------
local VERSION = "0.0.6"
local HORSE_FOLDER_NAME = "MobFolder"            -- Folder where live horse NPCs spawn
local MOB_SPAWN_FOLDER  = "MobSpawns"            -- Folder containing spawn area parts
local ITEM_TO_PURCHASE  = {"WesternLasso", 1}    -- Args for PurchaseItemRemote
local EMPTY_FOLDER_WAIT = 5
local LOOP_INTERVAL     = 0.5
local TELEPORT_DELAY    = 0.15
local FEED_DELAY        = 0.6
local PURCHASE_DELAY    = 0.6
local GUI_TIMEOUT       = 3       -- seconds to wait before we kill the GUI
local HORSE_TIMEOUT     = 30
local SEARCH_DELAY      = 5
local TELEPORT_HEIGHT_RANGE = {5, 10}  -- min, max random Y offset

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

function HorseFarmer:waitForAnimalGui()
    local gui = self.player:FindFirstChild("PlayerGui")
    if not gui then return end
    local display = gui:FindFirstChild("DisplayAnimalGui")
    if not display then return end

    if self.forceCloseGui then
        -- ⭐ MODE B: Always disable instantly
        if display.Enabled then
            print("[HorseFarmer] Force closing DisplayAnimalGui immediately.")
            ShowToast("[HorseFarmer] Force closing DisplayAnimalGui immediately.")
            pcall(function() display.Enabled = false end)
        end
        return
    end

    -- ⭐ MODE A: Wait for GUI to close or timeout
    local start = tick()
    while display and display.Enabled and tick() - start < GUI_TIMEOUT do
        task.wait(0.1)
        display = gui:FindFirstChild("DisplayAnimalGui")
    end
    if display and display.Enabled then
        warn("[HorseFarmer] GUI timeout, forcing disable.")
        ShowToast("[HorseFarmer] GUI timeout, forcing disable.")
        pcall(function() display.Enabled = false end)
    end
end

function HorseFarmer:teleportTo(position)
    local character = self.player.Character
    if not (character and character.PrimaryPart) then return false end

    local minY, maxY = TELEPORT_HEIGHT_RANGE[1], TELEPORT_HEIGHT_RANGE[2]
    local randomOffset = math.random(minY, maxY)

    pcall(function()
        character:SetPrimaryPartCFrame(CFrame.new(
            position.X,
            position.Y + randomOffset,
            position.Z
        ))
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
    if typeof(isrbxactive) == "function" and not isrbxactive() then
        warn("Roblox window not active, skipping interaction.")
        ShowToast("Roblox window not active, skipping interaction.")
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
        ShowToast("PurchaseItemRemote not found!")
        return
    end
    pcall(function() remote:InvokeServer(unpack(ITEM_TO_PURCHASE)) end)
    task.wait(PURCHASE_DELAY)
end

function HorseFarmer:sellAllAnimals()
    if not self.autoSell then return end

    local player = self.player
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return end

    local stablesGui = gui:FindFirstChild("StablesGui")
    if not stablesGui then return end

    local horsesContent = stablesGui
        and stablesGui:FindFirstChild("ContainerFrame")
        and stablesGui.ContainerFrame:FindFirstChild("Menu")
        and stablesGui.ContainerFrame.Menu:FindFirstChild("Content")
        and stablesGui.ContainerFrame.Menu.Content:FindFirstChild("Horses")
        and stablesGui.ContainerFrame.Menu.Content.Horses:FindFirstChild("Content")

    if not horsesContent then return end

    -- ✅ Stable capacity check
    local capLabel = stablesGui.ContainerFrame.Menu.Content:FindFirstChild("StorageCapacity")
    if capLabel then
        local txtLabel = capLabel:FindFirstChild("Content") and capLabel.Content:FindFirstChild("TextLabel")
        if txtLabel and txtLabel.Text then
            local current, max = string.match(txtLabel.Text, "(%d+)%s*/%s*(%d+)")
            current, max = tonumber(current), tonumber(max)
            if current and max then
                if current < max - 1 then
                    print(string.format("[HorseFarmer] Storage not full (%d/%d), skipping auto-sell.", current, max))
                    ShowToast(string.format("[HorseFarmer] Storage not full (%d/%d), skipping auto-sell.", current, max))
                    return
                end
            end
        end
    end

    -- ✅ Collect slots that are not favorited or equipped
    local slotNumbers = {}
    local animalData = gui:FindFirstChild("Data") and gui.Data:FindFirstChild("Animals")

    for _, child in ipairs(horsesContent:GetChildren()) do
        local slotNum = tonumber(child.Name)
        if slotNum and animalData then
            local animal = animalData:FindFirstChild(tostring(slotNum))
            local skip = false
            if animal then
                local fav = animal:FindFirstChild("Favorite")
                if fav and fav.Value then
                    print("[HorseFarmer] Skipping favorite animal in slot "..slotNum)
                    ShowToast("[HorseFarmer] Skipping favorite animal in slot "..slotNum)
                    skip = true
                end

                local equipped = animal:FindFirstChild("Equipped")
                if equipped and equipped.Value then
                    print("[HorseFarmer] Skipping equipped animal in slot "..slotNum)
                    ShowToast("[HorseFarmer] Skipping equipped animal in slot "..slotNum)
                    skip = true
                end
            end

            if not skip then
                table.insert(slotNumbers, slotNum)
            end
        end
    end

    -- ✅ Perform sell if we have slots left
    if #slotNumbers > 0 then
        local remote = self.remotes:FindFirstChild("SellSlotsRemote")
        if remote then
            print("[HorseFarmer] Auto-selling slots:", table.concat(slotNumbers, ", "))
            ShowToast("[HorseFarmer] Auto-selling slots: " .. table.concat(slotNumbers, ", "))
            pcall(function()
                remote:InvokeServer(slotNumbers)
            end)
        end
    else
        print("[HorseFarmer] Nothing to sell (all are favorited/equipped/kept).")
        ShowToast("[HorseFarmer] Nothing to sell (all are favorited/equipped/kept).")
    end
end

function HorseFarmer:getStableCount()
    local gui = self.player:FindFirstChild("PlayerGui")
    if not gui then return nil, nil end

    local stablesGui = gui:FindFirstChild("StablesGui")
    if not stablesGui then return nil, nil end

    local capLabel = stablesGui.ContainerFrame
        and stablesGui.ContainerFrame:FindFirstChild("Menu")
        and stablesGui.ContainerFrame.Menu:FindFirstChild("Content")
        and stablesGui.ContainerFrame.Menu.Content:FindFirstChild("StorageCapacity")

    if capLabel then
        local txtLabel = capLabel:FindFirstChild("Content") and capLabel.Content:FindFirstChild("TextLabel")
        if txtLabel and txtLabel.Text then
            local current, max = string.match(txtLabel.Text, "(%d+)%s*/%s*(%d+)")
            return tonumber(current), tonumber(max)
        end
    end

    return nil, nil
end

function HorseFarmer:processHorse(horse)
    local start = tick()
    local success = false

    -- Capture stable count before taming
    local beforeCount = select(1, self:getStableCount())

    -- Try to tame for HORSE_TIMEOUT seconds
    while self.running and horse.Parent == self.horseFolder and tick() - start < HORSE_TIMEOUT do
        if not self:teleportToHorse(horse) then break end
        self:interactWithHorse(horse)
        task.wait(0.25)
    end

    -- Wait for GUI to close, force disable if timed out
    task.wait(0.2)
    self:waitForAnimalGui()
    task.wait(0.5)

    -- Capture stable count after taming
    local afterCount = select(1, self:getStableCount())

    if beforeCount and afterCount and afterCount > beforeCount then
        success = true
        print(string.format("[HorseFarmer] ✅ Stable count increased (%d → %d).", beforeCount, afterCount))
        ShowToast(string.format("[HorseFarmer] ✅ Stable count increased (%d → %d).", beforeCount, afterCount))
    else
        warn("[HorseFarmer] ❌ Failed to process: " .. horse.Name)
        ShowToast("[HorseFarmer] ❌ Failed to process: " .. horse.Name)
    end

    if success then
        task.wait(0.2)
        self:purchaseItem()
        task.wait(3)
        self:sellAllAnimals()
    end

    task.wait(0.5)
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
        ShowToast("HorseFarmer already running.")
        return
    end
    self.running = true
    print("[HorseFarmer] Starting loop for:", table.concat(self.targetHorseTypes, ", "))
    ShowToast("[HorseFarmer] Starting loop for: " .. table.concat(self.targetHorseTypes, ", "))

    task.spawn(function()
        while self.running do
            task.wait(LOOP_INTERVAL)

            self.horseFolder = workspace:FindFirstChild(HORSE_FOLDER_NAME)
            if not self.horseFolder then
                warn("MobFolder missing, retrying in 5s...")
                ShowToast("MobFolder missing, retrying in 5s...")
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
                ShowToast("[HorseFarmer] No target horses found. Searching spawn areas...")
                self:searchSpawnAreas()
                task.wait(EMPTY_FOLDER_WAIT)
            else
                for _, horse in ipairs(horses) do
                    if not self.running then break end
                    print("[HorseFarmer] Farming horse:", horse.Name)
                    ShowToast("[HorseFarmer] Farming horse: " .. horse.Name)
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


-- Optional stop after 12 hours
task.delay(43200, function()
    farmer:stop()
end)
