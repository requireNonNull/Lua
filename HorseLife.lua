-- HorseLife MultiFarm (All-in-One, Instant TP + Resources)
local VERSION = "v0.1.0"
local CHANGELOG = "added XP + Resource farm toggle system"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- FARMER CORE ------------------------
local CoinFarmer = {}
CoinFarmer.Running = false
CoinFarmer.Mode = nil -- "Coins", "XP", or resource name
CoinFarmer.CoinsFarmed = 0

-- ============ TARGET GETTERS ============
local function getCoins()
    local coins = {}
    local root = workspace:WaitForChild("Interactions"):WaitForChild("CurrencyNodes")

    for _, folder in ipairs(root:GetChildren()) do
        if folder:IsA("Folder") and folder.Name ~= "Spawned" then
            for _, coin in ipairs(folder:GetChildren()) do
                if (coin:IsA("BasePart") or coin:IsA("MeshPart")) and coin.Name == "Coins" then
                    table.insert(coins, coin)
                end
            end
        end
    end

    return coins
end

local function getXPParts()
    local xpParts = {}
    local spawned = workspace:WaitForChild("Interactions"):WaitForChild("CurrencyNodes"):WaitForChild("Spawned")
    for _, name in ipairs({"XPAgility", "XPJump"}) do
        local part = spawned:FindFirstChild(name)
        if part then
            table.insert(xpParts, part)
        end
    end
    return xpParts
end

local function getResources(name)
    local resFolder = workspace:WaitForChild("Interactions"):WaitForChild("Resource")
    local objects = {}
    local model = resFolder:FindFirstChild(name)
    if model then
        for _, obj in ipairs(model:GetChildren()) do
            local cd = obj:FindFirstChildOfClass("ClickDetector")
            if cd then
                table.insert(objects, cd)
            end
        end
    end
    return objects
end

-- ============ HELPERS ============
local function tpTo(character, targetPos)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	local yPos = targetPos.Y
	yPos += 10
	hrp.CFrame = CFrame.new(Vector3.new(targetPos.X, yPos, targetPos.Z))
end

-- ============ FARM LOGIC ============
function CoinFarmer.Start(statusLabel)
    if CoinFarmer.Running then return end
    CoinFarmer.Running = true
    local character = player.Character or player.CharacterAdded:Wait()

    while CoinFarmer.Running do
        if not CoinFarmer.Mode then
            statusLabel.Text = "Select a farming mode..."
            task.wait(1)
            continue
        end

        -- Coins
        if CoinFarmer.Mode == "Coins" then
            local coins = getCoins()
            if #coins > 0 then
                for _, coin in ipairs(coins) do
                    if not CoinFarmer.Running or CoinFarmer.Mode ~= "Coins" then break end
                    if coin and coin.Parent then
                        statusLabel.Text = "Farming Coins..."
                        tpTo(character, coin.Position)
                        task.wait(1)
                        CoinFarmer.CoinsFarmed += 1
                    end
                end
            else
                statusLabel.Text = "Waiting for Coins..."
                task.wait(2)
            end

        -- XP
        elseif CoinFarmer.Mode == "XP" then
            local xpParts = getXPParts()
            if #xpParts > 0 then
                for _, xp in ipairs(xpParts) do
                    if not CoinFarmer.Running or CoinFarmer.Mode ~= "XP" then break end
                    if xp and xp.Parent then
                        statusLabel.Text = "Farming " .. xp.Name .. "..."
                        tpTo(character, xp.Position)
                        task.wait(1)
                    end
                end
            else
                statusLabel.Text = "Waiting for XP parts..."
                task.wait(2)
            end

        -- RESOURCES
        else
            local targets = getResources(CoinFarmer.Mode)
            if #targets > 0 then
                for _, cd in ipairs(targets) do
                    if not CoinFarmer.Running or CoinFarmer.Mode ~= CoinFarmer.Mode then break end
                    if cd and cd.Parent then
                        statusLabel.Text = "Farming " .. CoinFarmer.Mode .. "..."
                        fireclickdetector(cd)
                        task.wait(1)
                    end
                end
            else
                statusLabel.Text = "Waiting for " .. CoinFarmer.Mode .. "..."
                task.wait(2)
            end
        end
    end
end

function CoinFarmer.Stop()
	CoinFarmer.Running = false
	CoinFarmer.Mode = nil
end

-- UI ------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinFarmUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = game:GetService("CoreGui")

-- Button creator
local function createButton(text, pos, bgColor, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,160,0,45)
	btn.Position = pos
	btn.BackgroundTransparency = 0.3
	btn.BackgroundColor3 = bgColor
	btn.Text = text
	btn.TextScaled = true
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.GothamBold
	btn.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,12)
	corner.Parent = btn

	btn.Parent = screenGui
	btn.MouseButton1Click:Connect(onClick)
	return btn
end

-- Overlay + Labels
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(0.4,0,0.4,0)
overlay.AnchorPoint = Vector2.new(0.5,0.5)
overlay.Position = UDim2.new(0.5,0,0.2,0)
overlay.BackgroundColor3 = Color3.fromRGB(30,30,40)
overlay.BackgroundTransparency = 0.1
overlay.BorderSizePixel = 0
overlay.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,0,0,30)
statusLabel.Position = UDim2.new(0,0,0,0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextScaled = true
statusLabel.Parent = overlay

-- Farming Buttons
local y = 40
local function addFarmButton(name, mode)
	createButton(name, UDim2.new(0,10,0,y), Color3.fromRGB(60,60,100), function()
		if CoinFarmer.Mode == mode then
			CoinFarmer.Mode = nil
			statusLabel.Text = "Stopped: " .. name
		else
			CoinFarmer.Mode = mode
			if not CoinFarmer.Running then
				task.spawn(function() CoinFarmer.Start(statusLabel) end)
			end
		end
	end)
	y += 50
end

-- Add toggles
addFarmButton("Farm Coins", "Coins")
addFarmButton("Farm XP", "XP")
for _, res in ipairs({"AppleBarrel","BerryBush","FallenTree","FoodPallet","LargeBerryBush","Stump","Treasure"}) do
	addFarmButton("Farm " .. res, res)
end

-- Terminate Button
createButton("Terminate", UDim2.new(0,10,0,y+20), Color3.fromRGB(200,50,50), function()
	CoinFarmer.Stop()
	screenGui:Destroy()
end)

-- Live stats
RunService.RenderStepped:Connect(function()
	statusLabel.Text = "Mode: " .. (CoinFarmer.Mode or "None")
end)
