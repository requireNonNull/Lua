-- // AutoFarm Script (Coins, XP, Resources)
-- Single-select UI checkboxes

-- UI ------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 280)
frame.Position = UDim2.new(0, 50, 0, 150)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "AutoFarm Menu"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame

-- Version label
local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(1, -10, 0, 20)
versionLabel.Position = UDim2.new(0, 5, 1, -55)
versionLabel.BackgroundTransparency = 1
versionLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
versionLabel.Text = "v1.4"
versionLabel.Font = Enum.Font.SourceSansItalic
versionLabel.TextSize = 14
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 25)
statusLabel.Position = UDim2.new(0, 5, 1, -30)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Text = "Status: Idle"
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 16
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- Helpers ------------------------
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local function tpTo(char, pos)
    if char and char:FindFirstChild("HumanoidRootPart") then
        char:PivotTo(CFrame.new(pos + Vector3.new(0, 10, 0)))
    end
end

-- Checkbox creation
local checkboxes = {}
local function createCheckbox(text, order, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 30)
    button.Position = UDim2.new(0, 5, 0, 35 + (order * 35))
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    button.TextColor3 = Color3.fromRGB(200, 200, 200)
    button.Text = "[ ] " .. text
    button.Font = Enum.Font.SourceSans
    button.TextSize = 16
    button.Parent = frame

    local state = false

    local function setState(val)
        state = val
        button.Text = (state and "[X] " or "[ ] ") .. text
        if state then
            -- uncheck all others
            for _, other in pairs(checkboxes) do
                if other ~= setState then
                    other(false)
                end
            end
            callback(true)
        else
            callback(false)
        end
    end

    button.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    checkboxes[text] = setState
end

-- Farming logic ------------------------
local Farmer = {
    Running = false,
    Mode = nil,
}

-- Coins (only collect "Coins" parts)
local function getCoinParts()
    local spawned = workspace:FindFirstChild("Interactions")
        and workspace.Interactions:FindFirstChild("CurrencyNodes")
        and workspace.Interactions.CurrencyNodes:FindFirstChild("Spawned")
    if not spawned then return {} end

    local coins = {}
    for _, obj in ipairs(spawned:GetChildren()) do
        if (obj:IsA("BasePart") or obj:IsA("MeshPart")) and obj.Name == "Coins" then
            table.insert(coins, obj)
        end
    end
    return coins
end



-- XP parts (filter specific XP names)
local function getXPParts()
    local spawned = workspace:FindFirstChild("Interactions")
        and workspace.Interactions:FindFirstChild("CurrencyNodes")
        and workspace.Interactions.CurrencyNodes:FindFirstChild("Spawned")
    if not spawned then return {} end

    local xpParts = {}
    for _, name in ipairs({"XPAgility", "XPJump"}) do
        local part = spawned:FindFirstChild(name)
        if part then
            table.insert(xpParts, part)
        end
    end
    return xpParts
end

local function doXP(xpName)
    local parts = getXPParts()
    for _, part in ipairs(parts) do
        if part.Name == xpName and part.Parent then
            tpTo(player.Character, part.Position)
            -- wait until XP part disappears
            repeat task.wait(0.3) until not part.Parent
        end
    end
end

-- Resources
local resourceArgs = {5, true}
local function getResourceModels(name)
    local resFolder = workspace:WaitForChild("Interactions"):WaitForChild("Resource")
    local targets = {}
    local model = resFolder:FindFirstChild(name)
    if model then
        for _, obj in ipairs(model:GetChildren()) do
            if obj:IsA("Model") then
                local cd = obj:FindFirstChildOfClass("ClickDetector")
                local re = obj:FindFirstChild("RemoteEvent")
                if cd and re then
                    table.insert(targets, {Model = obj, Click = cd, Remote = re})
                end
            end
        end
    end
    return targets
end

-- Farming Loop
task.spawn(function()
    while true do
        if Farmer.Running and Farmer.Mode then
            local char = player.Character or player.CharacterAdded:Wait()

            -- Coins
            if Farmer.Mode == "Coins" then
                local coins = getCoinParts()
                for _, coin in ipairs(coins) do
                    if not Farmer.Running or Farmer.Mode ~= "Coins" then break end
                    if coin and coin:IsA("BasePart") and coin.Parent then
                        statusLabel.Text = "Collecting Coins..."
                        tpTo(char, coin.Position)
                        -- wait until coin disappears
                        repeat task.wait(0.3) until not coin.Parent
                    end
                end

            -- XP
            elseif Farmer.Mode == "XPAgility" or Farmer.Mode == "XPJump" then
                statusLabel.Text = "Training " .. Farmer.Mode .. "..."
                doXP(Farmer.Mode)

            -- Resources
            else
                local currentMode = Farmer.Mode
                local targets = getResourceModels(Farmer.Mode)
                if #targets > 0 then
                    for _, res in ipairs(targets) do
                        if not Farmer.Running or Farmer.Mode ~= currentMode then break end
                        if res.Model and res.Model.Parent then
                            statusLabel.Text = "Farming " .. Farmer.Mode .. "..."
                            tpTo(char, res.Model:GetPivot().Position)

                            -- Click once
                            fireclickdetector(res.Click)
                            task.wait(0.3)

                            -- Then spam RemoteEvent until object disappears
                            repeat
                                res.Remote:FireServer(unpack(resourceArgs))
                                task.wait(math.random(4, 10) / 10)
                            until not res.Model.Parent or Farmer.Mode ~= currentMode
                        end
                    end
                else
                    statusLabel.Text = "Waiting for " .. Farmer.Mode .. "..."
                    task.wait(2)
                end
            end
        else
            statusLabel.Text = "Status: Idle"
            task.wait(1)
        end
    end
end)

-- UI setup ------------------------
createCheckbox("Coins", 0, function(state)
    Farmer.Running = state
    Farmer.Mode = state and "Coins" or nil
end)

if xpFolder then
    createCheckbox("XP Agility", 1, function(state)
        Farmer.Running = state
        Farmer.Mode = state and "XPAgility" or nil
    end)

    createCheckbox("XP Jump", 2, function(state)
        Farmer.Running = state
        Farmer.Mode = state and "XPJump" or nil
    end)
end

-- Auto-add all resources dynamically
local resFolder = workspace:WaitForChild("Interactions"):WaitForChild("Resource")
local order = 3
for _, resource in ipairs(resFolder:GetChildren()) do
    if resource:IsA("Folder") or resource:IsA("Model") then
        local resName = resource.Name
        createCheckbox(resName, order, function(state)
            Farmer.Running = state
            Farmer.Mode = state and resName or nil
        end)
        order = order + 1
    end
end
