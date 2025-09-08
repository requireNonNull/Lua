-- HorseLife CoinFarm (All-in-One, Instant TP)
local VERSION = "v0.0.3"
local CHANGELOG = "<+> 1 sec delay each tp <+>"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- FARMER LOGIC ------------------------
local CoinFarmer = {}
CoinFarmer.Running = false
CoinFarmer.CoinsFarmed = 0

local function getAllCoins()
    local coins = {}
    local root = workspace:WaitForChild("Interactions"):WaitForChild("CurrencyNodes")

    for _, folder in ipairs(root:GetChildren()) do
        if folder:IsA("Folder") then
            for _, coin in ipairs(folder:GetChildren()) do
                if (coin:IsA("BasePart") or coin:IsA("MeshPart")) and coin.Name == "Coins" then
                    table.insert(coins, coin)
                end
            end
        end
    end
    return coins
end

local function tpTo(character, targetPos)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	-- Ground adjust
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {character}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	local result = workspace:Raycast(targetPos + Vector3.new(0,5,0), Vector3.new(0,-20,0), rayParams)

	local yPos = targetPos.Y
	if result then
		yPos = result.Position.Y + 3
	end

	-- Insta-TP instead of tween
	hrp.CFrame = CFrame.new(Vector3.new(targetPos.X, yPos, targetPos.Z))
end

function CoinFarmer.Start(statusLabel)
	if CoinFarmer.Running then return end
	CoinFarmer.Running = true
	local character = player.Character or player.CharacterAdded:Wait()

	while CoinFarmer.Running do
		local coins = getAllCoins()
		if #coins > 0 then
			for _, coin in ipairs(coins) do
				if not CoinFarmer.Running then break end
				if coin and coin.Parent then
					statusLabel.Text = "Status: Teleporting to coin..."
					tpTo(character, coin.Position)
					task.wait(1) -- small delay to avoid breaking physics
					CoinFarmer.CoinsFarmed += 1
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

-- Terminate style (gradient + stroke)
local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 12)
corner2.Parent = terminateBtn

local stroke2 = Instance.new("UIStroke")
stroke2.Color = Color3.fromRGB(255, 200, 200)
stroke2.Thickness = 3
stroke2.Transparency = 0.15
stroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke2.Parent = terminateBtn

local gradient2 = Instance.new("UIGradient")
gradient2.Color = ColorSequence.new {
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 120)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 40, 40))
}
gradient2.Rotation = 45
gradient2.Parent = terminateBtn

-- Style function
local function styleButton(btn)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = btn
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 180, 255)
	stroke.Thickness = 3
	stroke.Transparency = 0.15
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = btn
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 100, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 40, 120))
	}
	gradient.Rotation = 45
	gradient.Parent = btn
end
styleButton(farmButton)

-- Overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(0.4,0,0.28,0)
overlay.AnchorPoint = Vector2.new(0.5,0.5)
overlay.Position = UDim2.new(0.5,0,0.15,0)
overlay.BackgroundColor3 = Color3.fromRGB(30,30,40)
overlay.BackgroundTransparency = 0.1
overlay.BorderSizePixel = 0
overlay.Parent = screenGui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,16)
corner.Parent = overlay
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(120,180,255)
stroke.Thickness = 3
stroke.Transparency = 0.3
stroke.Parent = overlay

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.BackgroundTransparency = 1
title.Text = "HorseLife CoinFarm"
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(200,230,255)
title.Font = Enum.Font.GothamBold
title.Parent = overlay

-- Version label
local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(1,0,0,25)
versionLabel.Position = UDim2.new(0,0,0,35)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "Version: " .. VERSION
versionLabel.TextScaled = true
versionLabel.TextColor3 = Color3.fromRGB(180,180,200)
versionLabel.Font = Enum.Font.Gotham
versionLabel.Parent = overlay

-- Changelog label
local changelogLabel = Instance.new("TextLabel")
changelogLabel.Size = UDim2.new(1,0,0,25)
changelogLabel.Position = UDim2.new(0,0,0,60)
changelogLabel.BackgroundTransparency = 1
changelogLabel.Text = "Update: " .. CHANGELOG
changelogLabel.TextScaled = true
changelogLabel.TextColor3 = Color3.fromRGB(160,200,160)
changelogLabel.Font = Enum.Font.Gotham
changelogLabel.Parent = overlay

-- Info Labels
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,0,0,30)
statusLabel.Position = UDim2.new(0,0,0,65)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextScaled = true
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = overlay

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(1,0,0,30)
coinsLabel.Position = UDim2.new(0,0,0,100)
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
	warn("🐎 HorseLife CoinFarm terminated. You can reloadstring a new version now.")
end)

-- Live stats update
RunService.RenderStepped:Connect(function()
	coinsLabel.Text = "Coins Farmed: " .. CoinFarmer.CoinsFarmed
end)
