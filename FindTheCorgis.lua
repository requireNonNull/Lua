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

-- 💠 Main Frame (Container without Draggable)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 220)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BackgroundTransparency = 0.1
mainFrame.Active = true
-- Removed Draggable property for mobile compatibility
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner", mainFrame)
frameCorner.CornerRadius = UDim.new(0, 10)

-- 🕹️ Start/Stop Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 280, 0, 40)
toggleButton.Position = UDim2.new(0, 20, 0, 20)
toggleButton.Text = "Start Loop"
toggleButton.Font = Enum.Font.GothamSemibold
toggleButton.TextSize = 18
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255) -- Changed for better contrast
toggleButton.AutoButtonColor = false
toggleButton.Parent = mainFrame

toggleButton.TextStrokeTransparency = 0 -- 0 is fully visible
toggleButton.TextStrokeColor3 = Color3.new(0, 0, 0) -- Black outline

Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 12)

local toggleGradient = Instance.new("UIGradient", toggleButton)
toggleGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 90, 170))
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
terminateButton.Font = Enum.Font.GothamSemibold
terminateButton.TextSize = 18
terminateButton.TextColor3 = Color3.new(1, 1, 1)
terminateButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0) -- Darker red for better contrast
terminateButton.AutoButtonColor = false
terminateButton.Parent = mainFrame

terminateButton.TextStrokeTransparency = 0 -- 0 is fully visible
terminateButton.TextStrokeColor3 = Color3.new(0, 0, 0) -- Black outline

Instance.new("UICorner", terminateButton).CornerRadius = UDim.new(0, 12)

local terminateGradient = Instance.new("UIGradient", terminateButton)
terminateGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 0, 0))
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
infoLabel.Font = Enum.Font.GothamSemibold
infoLabel.TextSize = 16
infoLabel.TextColor3 = Color3.new(1, 1, 1)
infoLabel.BackgroundTransparency = 0.3
infoLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
infoLabel.Parent = mainFrame

Instance.new("UICorner", infoLabel).CornerRadius = UDim.new(0, 8)

-- 🟢 Start/Stop Toggle Function
toggleButton.MouseButton1Click:Connect(function()
	loopRunning = not loopRunning
	toggleButton.Text = loopRunning and "Stop Loop" or "Start Loop"
end)

-- ❌ Terminate Button Function
terminateButton.MouseButton1Click:Connect(function()
	screenGui:Destroy()
	loopRunning = false
end)

-- ✨ Rebirth Notification Function
local function showRebirthNotification()
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 200, 0, 40)
	label.Position = UDim2.new(0.5, -100, 0, 10)
	label.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	label.BackgroundTransparency = 0.2
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 18
	label.Text = "🎉 Rebirth Triggered!"
	label.ZIndex = 5
	label.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Parent = label

	-- Tween fade out after delay
	task.delay(1.5, function()
		local tween = TweenService:Create(label, TweenInfo.new(0.5), {
			TextTransparency = 1,
			BackgroundTransparency = 1
		})
		tween:Play()
		tween.Completed:Wait()
		label:Destroy()
	end)
end

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

					teleportCount += 1
					if teleportCount % 120 == 0 then
						rebirthEvent:FireServer()
						showRebirthNotification()
					end
				end
			end

			currentIndex += 1
		end
		task.wait(0.10) 
	end
end)
