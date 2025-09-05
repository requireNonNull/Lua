local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local teleportCount = 0
local startTime = tick()
local loopRunning = false

local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local itemsFolder = workspace:WaitForChild("Items")
local items = itemsFolder:GetChildren()
local rebirthEvent = ReplicatedStorage:WaitForChild("ResetFolder"):WaitForChild("RebirthEvent")

local currentIndex = 1

-- 🧱 UI SETUP
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportControlGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- 💠 Main Frame (Draggable Container)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 220)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BackgroundTransparency = 0.1
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner", mainFrame)
frameCorner.CornerRadius = UDim.new(0, 10)

-- 🕹️ Start/Stop Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 280, 0, 40)
toggleButton.Position = UDim2.new(0, 20, 0, 20)
toggleButton.Text = "Start Loop"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 18
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
toggleButton.AutoButtonColor = false
toggleButton.Parent = mainFrame

Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 12)

local toggleGradient = Instance.new("UIGradient", toggleButton)
toggleGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255))
}
toggleGradient.Rotation = 45

local toggleStroke = Instance.new("UIStroke", toggleButton)
toggleStroke.Thickness = 2
toggleStroke.Color = Color3.fromRGB(255, 255, 255)

-- ⛔ Terminate Button
local terminateButton = Instance.new("TextButton")
terminateButton.Size = UDim2.new(0, 280, 0, 40)
terminateButton.Position = UDim2.new(0, 20, 0, 70)
terminateButton.Text = "Terminate Script"
terminateButton.Font = Enum.Font.GothamBold
terminateButton.TextSize = 18
terminateButton.TextColor3 = Color3.new(1, 1, 1)
terminateButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
terminateButton.AutoButtonColor = false
terminateButton.Parent = mainFrame

Instance.new("UICorner", terminateButton).CornerRadius = UDim.new(0, 12)

local terminateGradient = Instance.new("UIGradient", terminateButton)
terminateGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 0, 0))
}
terminateGradient.Rotation = 45

local terminateStroke = Instance.new("UIStroke", terminateButton)
terminateStroke.Thickness = 2
terminateStroke.Color = Color3.fromRGB(255, 255, 255)

-- 📋 Info Label
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0, 280, 0, 80)
infoLabel.Position = UDim2.new(0, 20, 0, 130)
infoLabel.Text = ""
infoLabel.TextWrapped = true
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 16
infoLabel.TextColor3 = Color3.new(1, 1, 1)
infoLabel.BackgroundTransparency = 0.3
infoLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
infoLabel.Parent = mainFrame

Instance.new("UICorner", infoLabel).CornerRadius = UDim.new(0, 8)

-- 🟢 Hover Animation Function
local function createHoverEffect(button)
	local tweenIn = TweenService:Create(button, TweenInfo.new(0.15), {BackgroundTransparency = 0.05})
	local tweenOut = TweenService:Create(button, TweenInfo.new(0.15), {BackgroundTransparency = 0.2})

	button.MouseEnter:Connect(function()
		tweenIn:Play()
	end)
	button.MouseLeave:Connect(function()
		tweenOut:Play()
	end)
end

createHoverEffect(toggleButton)
createHoverEffect(terminateButton)

-- 📊 Info Update Loop
task.spawn(function()
	while screenGui.Parent do
		local timePlayed = math.floor(tick() - startTime)
		local minutes = math.floor(timePlayed / 60)
		local seconds = timePlayed % 60

		local serverId = game.JobId ~= "" and game.JobId or "Local Server"
		local status = loopRunning and "🟢 RUNNING" or "🔴 STOPPED"

		infoLabel.Text = string.format(
			"Loop: %s\nTeleports: %d\nTime Played: %02d:%02d\nServer ID:\n%s",
			status,
			teleportCount,
			minutes,
			seconds,
			serverId
		)

		task.wait(1)
	end
end)

-- 🌀 Teleport Loop
task.spawn(function()
	while screenGui.Parent do
		if loopRunning then
			if currentIndex > #items then
				currentIndex = 1
			end

			local model = items[currentIndex]
			if model:IsA("Model") then
				local targetPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
				if targetPart then
					humanoidRootPart.CFrame = targetPart.CFrame
					rebirthEvent:FireServer()
					teleportCount += 1
				end
			end

			currentIndex += 1
		end
		task.wait(0.01)
	end
end)

-- 🔁 Start/Stop Toggle Logic
toggleButton.MouseButton1Click:Connect(function()
	loopRunning = not loopRunning

	if loopRunning then
		toggleButton.Text = "Stop Loop"
		toggleStroke.Color = Color3.fromRGB(255, 80, 80)
		toggleGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 0, 0))
		}
	else
		toggleButton.Text = "Start Loop"
		toggleStroke.Color = Color3.fromRGB(0, 255, 0)
		toggleGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255))
		}
	end
end)

-- ⛔ Terminate Button Logic
terminateButton.MouseButton1Click:Connect(function()
	loopRunning = false
	screenGui:Destroy()
	print("✅ Teleport script terminated and UI cleaned.")
end)
