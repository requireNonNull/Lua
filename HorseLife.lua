-- HorseLife CoinFarm (All-in-One)
-- Drop into StarterPlayerScripts or loadstring() it.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- FARMER LOGIC ------------------------
local CoinFarmer = {}
CoinFarmer.Running = false
CoinFarmer.CoinsFarmed = 0
CoinFarmer.CurrentTween = nil

local function getAllCoins()
	local coins = {}
	local root = workspace:WaitForChild("Interactions"):WaitForChild("CurrencyNodes")
	
	for _, folder in ipairs(root:GetChildren()) do
		if folder:IsA("Folder") then
			for _, coin in ipairs(folder:GetChildren()) do
				if coin:IsA("BasePart") or coin:IsA("MeshPart") then
					table.insert(coins, coin)
				end
			end
		end
	end
	return coins
end

local function pivotTo(character, targetPos)
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

	local targetCF = CFrame.new(Vector3.new(targetPos.X, yPos, targetPos.Z))

	-- Tween
	if CoinFarmer.CurrentTween then
		CoinFarmer.CurrentTween:Cancel()
	end
	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear)
	CoinFarmer.CurrentTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCF})
	CoinFarmer.CurrentTween:Play()
	CoinFarmer.CurrentTween.Completed:Wait()
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
					statusLabel.Text = "Status: Moving to coin..."
					pivotTo(character, coin.Position)
					task.wait(0.3)
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
	if CoinFarmer.CurrentTween then
		CoinFarmer.CurrentTween:Cancel()
	end
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

-- Style
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

-- Overlay Window
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(0.4,0,0.25,0)
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

-- Info Labels
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,0,0,30)
statusLabel.Position = UDim2.new(0,0,0,40)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextScaled = true
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = overlay

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(1,0,0,30)
coinsLabel.Position = UDim2.new(0,0,0,75)
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

-- Live stats update
RunService.RenderStepped:Connect(function()
	coinsLabel.Text = "Coins Farmed: " .. CoinFarmer.CoinsFarmed
end)
