-- HorseLife CoinFarm (All-in-One, Instant TP)
local VERSION = "v0.0.5"
local CHANGELOG = "<+> Added +20 Y offset for horse sitting <+>"

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

	local yPos = targetPos.Y
		yPos = result.Position.Y + 20

	-- Insta-TP
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

-- Buttons
local function createButton(text, pos, bgColor)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,160,0,65)
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

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120,180,255)
	stroke.Thickness = 3
	stroke.Transparency = 0.15
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = btn

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60,100,200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20,40,120))
	}
	gradient.Rotation = 45
	gradient.Parent = btn

	btn.Parent = screenGui
	return btn
end

local farmButton = createButton("Start Farming", UDim2.new(0,10,1,-215), Color3.fromRGB(40,40,60))
local terminateBtn = createButton("Terminate Farm", UDim2.new(0,10,1,-140), Color3.fromRGB(255,80,80))

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

-- Labels
local function createLabel(text, pos, color, font, size)
	local lbl = Instance.new("TextLabel")
	lbl.Size = size
	lbl.Position = pos
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextScaled = true
	lbl.TextColor3 = color
	lbl.Font = font
	lbl.Parent = overlay
	return lbl
end

createLabel("HorseLife CoinFarm", UDim2.new(0,0,0,0), Color3.fromRGB(200,230,255), Enum.Font.GothamBold, UDim2.new(1,0,0,35))
createLabel("Version: " .. VERSION, UDim2.new(0,0,0,35), Color3.fromRGB(180,180,200), Enum.Font.Gotham, UDim2.new(1,0,0,25))
createLabel("Update: " .. CHANGELOG, UDim2.new(0,0,0,60), Color3.fromRGB(160,200,160), Enum.Font.Gotham, UDim2.new(1,0,0,25))

local statusLabel = createLabel("Status: Idle", UDim2.new(0,0,0,90), Color3.new(1,1,1), Enum.Font.Gotham, UDim2.new(1,0,0,30))
local coinsLabel = createLabel("Coins Farmed: 0", UDim2.new(0,0,0,125), Color3.new(1,1,1), Enum.Font.Gotham, UDim2.new(1,0,0,30))

-- Button logic
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

terminateBtn.MouseButton1Click:Connect(function()
	CoinFarmer.Stop()
	if screenGui then
		screenGui:Destroy()
	end
	warn("🐎 HorseLife CoinFarm terminated. You can reloadstring a new version now.")
end)

-- Live stats
RunService.RenderStepped:Connect(function()
	coinsLabel.Text = "Coins Farmed: " .. CoinFarmer.CoinsFarmed
end)
