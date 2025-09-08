-- HorseLife CoinFarm TEST MODE (Remote Fire Only)
local VERSION = "v0.0.5-TEST"
local CHANGELOG = "<+> Test mode: Only fires remote for each Spawned coin, no teleporting <+>"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- FARMER LOGIC ------------------------
local CoinFarmer = {}
CoinFarmer.Running = false
CoinFarmer.CoinsFarmed = 0

-- Only get coins inside the "Spawned" folder
local function getAllCoins()
    local coins = {}
    local root = workspace:WaitForChild("Interactions"):WaitForChild("CurrencyNodes"):WaitForChild("Spawned")

    for _, coin in ipairs(root:GetChildren()) do
        if coin.Name == "Coins" then
            table.insert(coins, coin)
        end
    end
    return coins
end

function CoinFarmer.Start(statusLabel)
    if CoinFarmer.Running then return end
    CoinFarmer.Running = true

    while CoinFarmer.Running do
        local coins = getAllCoins()
        if #coins > 0 then
            for _, coin in ipairs(coins) do
                if not CoinFarmer.Running then break end
                if coin and coin.Parent then
                    statusLabel.Text = "Status: Firing remote..."
                    local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("GetCurrencyNodeRemote")
                    remote:FireServer(coin)

                    CoinFarmer.CoinsFarmed += 1
                    statusLabel.Text = "Status: Fired remote for coin"
                    task.wait(0.2)
                end
            end
        else
            statusLabel.Text = "Status: Waiting for coins..."
            task.wait(2)
        end
    end
end

function CoinFarmer.Stop()
    CoinFarmer.Running = false
end

-- UI ------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinFarmUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Toggle Button
local farmButton = Instance.new("TextButton")
farmButton.Size = UDim2.new(0, 160, 0, 65)
farmButton.Position = UDim2.new(0, 10, 1, -215)
farmButton.BackgroundTransparency = 0.3
farmButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
farmButton.Text = "Start Farming"
farmButton.TextScaled = true
farmButton.TextColor3 = Color3.new(1,1,1)
farmButton.Font = Enum.Font.GothamBold
farmButton.BorderSizePixel = 0
farmButton.Parent = screenGui

-- Terminate Button
local terminateBtn = Instance.new("TextButton")
terminateBtn.Size = UDim2.new(0, 160, 0, 65)
terminateBtn.Position = UDim2.new(0, 10, 1, -140)
terminateBtn.BackgroundTransparency = 0.3
terminateBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
terminateBtn.Text = "Terminate Farm"
terminateBtn.TextScaled = true
terminateBtn.TextColor3 = Color3.new(1,1,1)
terminateBtn.Font = Enum.Font.GothamBold
terminateBtn.BorderSizePixel = 0
terminateBtn.Parent = screenGui

-- Style
local function styleButton(btn, grad1, grad2, strokeColor)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btn
    local stroke = Instance.new("UIStroke")
    stroke.Color = strokeColor
    stroke.Thickness = 3
    stroke.Transparency = 0.15
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = btn
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new {
        ColorSequenceKeypoint.new(0, grad1),
        ColorSequenceKeypoint.new(1, grad2)
    }
    gradient.Rotation = 45
    gradient.Parent = btn
end
styleButton(farmButton, Color3.fromRGB(60,100,200), Color3.fromRGB(20,40,120), Color3.fromRGB(120,180,255))
styleButton(terminateBtn, Color3.fromRGB(255,120,120), Color3.fromRGB(200,40,40), Color3.fromRGB(255,200,200))

-- Overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(0.45,0,0.32,0)
overlay.AnchorPoint = Vector2.new(0.5,0.5)
overlay.Position = UDim2.new(0.5,0,0.15,0)
overlay.BackgroundColor3 = Color3.fromRGB(30,30,40)
overlay.BackgroundTransparency = 0.1
overlay.BorderSizePixel = 0
overlay.Parent = screenGui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,16)
corner.Parent = overlay

-- Title + Info
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.BackgroundTransparency = 1
title.Text = "HorseLife CoinFarm TEST"
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(200,230,255)
title.Font = Enum.Font.GothamBold
title.Parent = overlay

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(1,0,0,20)
versionLabel.Position = UDim2.new(0,0,0,40)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "Version: " .. VERSION
versionLabel.TextScaled = true
versionLabel.TextColor3 = Color3.fromRGB(180,180,200)
versionLabel.Font = Enum.Font.Gotham
versionLabel.Parent = overlay

local changelogLabel = Instance.new("TextLabel")
changelogLabel.Size = UDim2.new(1,0,0,20)
changelogLabel.Position = UDim2.new(0,0,0,65)
changelogLabel.BackgroundTransparency = 1
changelogLabel.Text = "Update: " .. CHANGELOG
changelogLabel.TextScaled = true
changelogLabel.TextColor3 = Color3.fromRGB(160,200,160)
changelogLabel.Font = Enum.Font.Gotham
changelogLabel.Parent = overlay

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,0,0,25)
statusLabel.Position = UDim2.new(0,0,0,90)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextScaled = true
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = overlay

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(1,0,0,25)
coinsLabel.Position = UDim2.new(0,0,0,115)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text = "Coins Farmed: 0"
coinsLabel.TextScaled = true
coinsLabel.TextColor3 = Color3.new(1,1,1)
coinsLabel.Font = Enum.Font.Gotham
coinsLabel.Parent = overlay

-- Toggle Farming
local running = false
farmButton.MouseButton1Click:Connect(function()
    running = not running
    if running then
        farmButton.Text = "Stop Farming"
        statusLabel.Text = "Status: Starting..."
        task.spawn(function()
            CoinFarmer.Start(statusLabel)
        end)
    else
        farmButton.Text = "Start Farming"
        statusLabel.Text = "Status: Idle"
        CoinFarmer.Stop()
    end
end)

-- Terminate completely
terminateBtn.MouseButton1Click:Connect(function()
    CoinFarmer.Stop()
    if screenGui then
        screenGui:Destroy()
    end
    warn("🐎 HorseLife CoinFarm TEST terminated. Reloadstring for new version.")
end)

-- Live stats
RunService.RenderStepped:Connect(function()
    coinsLabel.Text = "Coins Farmed: " .. CoinFarmer.CoinsFarmed
end)
