-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Player references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Variables
local teleportCount = 0
local startTime = tick()
local loopRunning = false

local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local itemsFolder = workspace:WaitForChild("Items")
local items = itemsFolder:GetChildren()
local rebirthEvent = ReplicatedStorage:WaitForChild("ResetFolder"):WaitForChild("RebirthEvent")

local currentIndex = 1

-- Helper function: Add UICorner to a UI element with radius
local function addUICorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = instance
end

-- Helper function: Create a hover effect for buttons (color change on hover)
local function createHoverEffect(button)
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = button.BackgroundColor3:lerp(Color3.new(0.8, 0.8, 0.8), 0.1)
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = button.BackgroundColor3:lerp(Color3.new(0.3, 0.3, 0.3), 0) -- reset to original
	end)
end

-- === UI SETUP ===

-- Main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportControlGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main Frame (container)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 220)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BackgroundTransparency = 0.1
mainFrame.Active = true
mainFrame.Parent = screenGui
addUICorner(mainFrame, 10)

-- Start/Stop Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 280, 0, 40)
toggleButton.Position = UDim2.new(0, 20, 0, 20)
toggleButton.Text = "Start Loop"
toggleButton.Font = Enum.Font.GothamSemibold
toggleButton.TextSize = 18
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
toggleButton.AutoButtonColor = false
toggleButton.Parent = mainFrame
addUICorner(toggleButton, 12)

-- Gradient for toggle button
local toggleGradient = Instance.new("UIGradient", toggleButton)
toggleGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 90, 170))
}
toggleGradient.Rotation = 45

-- TextStroke for toggle button (using properties)
toggleButton.TextStrokeTransparency = 0
toggleButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

-- Outline stroke for toggle button
local toggleStroke = Instance.new("UIStroke", toggleButton)
toggleStroke.Thickness = 2
toggleStroke.Color = Color3.fromRGB(255, 255, 255)

-- Terminate Button
local terminateButton = Instance.new("TextButton")
terminateButton.Size = UDim2.new(0, 280, 0, 40)
terminateButton.Position = UDim2.new(0, 20, 0, 70)
terminateButton.Text = "Terminate Script"
terminateButton.Font = Enum.Font.GothamSemibold
terminateButton.TextSize = 18
terminateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
terminateButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
terminateButton.AutoButtonColor = false
terminateButton.Parent = mainFrame
addUICorner(terminateButton, 12)

-- Gradient for terminate button
local terminateGradient = Instance.new("UIGradient", terminateButton)
terminateGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 0, 0))
}
terminateGradient.Rotation = 45

-- TextStroke for terminate button
terminateButton.TextStrokeTransparency = 0
terminateButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

-- Outline stroke for terminate button
local terminateStroke = Instance.new("UIStroke", terminateButton)
terminateStroke.Thickness = 2
terminateStroke.Color = Color3.fromRGB(255, 255, 255)

-- Info Label (shows status and stats)
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0, 280, 0, 80)
infoLabel.Position = UDim2.new(0, 20, 0, 130)
infoLabel.Text = ""
infoLabel.TextWrapped = true
infoLabel.Font = Enum.Font.GothamSemibold
infoLabel.TextSize = 16
infoLabel.TextColor3 = Color3.fromRGB(230, 230, 230) -- light text for visibility
infoLabel.BackgroundTransparency = 0.3
infoLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
infoLabel.Parent = mainFrame
addUICorner(infoLabel, 8)

-- === BUTTON FUNCTIONS ===

toggleButton.MouseButton1Click:Connect(function()
	loopRunning = not loopRunning
	toggleButton.Text = loopRunning and "Stop Loop" or "Start Loop"
	print("[DEBUG] Toggle Button clicked. Loop running:", loopRunning)
end)

terminateButton.MouseButton1Click:Connect(function()
	print("[DEBUG] Terminate Button clicked. Destroying UI and stopping loop.")
	loopRunning = false
	screenGui:Destroy()
end)

-- Optional: add hover effect to buttons (simple brightness increase)
createHoverEffect(toggleButton)
createHoverEffect(terminateButton)

-- === REBIRTH NOTIFICATION FUNCTION ===
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
	addUICorner(label, 10)

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Parent = label

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

-- === INFO LABEL UPDATE LOOP ===
task.spawn(function()
	while screenGui.Parent do
		local timePlayed = math.floor(tick() - startTime)
		local minutes = math.floor(timePlayed / 60)
		local seconds = timePlayed % 60

		local serverId = game.JobId ~= "" and game.JobId or "Local Server"
		local status = loopRunning and "🟢 RUNNING" or "🔴 STOPPED"

		infoLabel.Text = string.format(
			"Loop Status: %s\nTeleports Done: %d\nTime Played: %02d:%02d\nServer ID:\n%s",
			status,
			teleportCount,
			minutes,
			seconds,
			serverId
		)

		task.wait(1)
	end
end)

-- === TELEPORT LOOP ===
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
					-- Teleport player
					humanoidRootPart.CFrame = targetPart.CFrame

					teleportCount += 1

					-- Debug info
					print(string.format("[DEBUG] Teleported to item #%d: %s (Teleport count: %d)", currentIndex, model.Name, teleportCount))

					-- Trigger rebirth every 120 teleports
					if teleportCount % 120 == 0 then
						rebirthEvent:FireServer()
						showRebirthNotification()
						print("[DEBUG] Rebirth event fired.")
					end
				else
					print("[WARN] Item #" .. currentIndex .. " has no PrimaryPart or BasePart.")
				end
			else
				print("[WARN] Item #" .. currentIndex .. " is not a Model.")
			end

			currentIndex += 1
		end
		task.wait(0.10) -- small delay between teleports
	end
end)
