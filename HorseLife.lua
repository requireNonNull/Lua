-- // 🦄 Farmy by Breezingfreeze
local VERSION = "v6.6 tpfix007"
local DEBUG_MODE = true
local stopAntiAFK = false

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ==========================
-- UI Setup
-- ==========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 350)
frame.Position = UDim2.new(0, 50, 0, 150)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

-- Draggable
local dragging, dragStart, startPos
local function update(input)
	if dragging and input then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end
frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		UserInputService.InputChanged:Connect(update)
	end
end)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30)
title.BackgroundColor3 = Color3.fromRGB(50,50,50)
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Text = "🦄 Farmy - " .. VERSION
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame

-- Settings Button (top left)
local settingsButton = Instance.new("TextButton")
settingsButton.Size = UDim2.new(0,30,1,0)
settingsButton.Position = UDim2.new(0,0,0,0)
settingsButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
settingsButton.TextColor3 = Color3.fromRGB(255,255,255)
settingsButton.Text = "⚙️"
settingsButton.Font = Enum.Font.SourceSansBold
settingsButton.TextSize = 18
settingsButton.Parent = title

-- Close/Delete Button (top right)
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0,30,1,0)
closeButton.Position = UDim2.new(1,-30,0,0)
closeButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
closeButton.TextColor3 = Color3.fromRGB(255,255,255)
closeButton.Text = "🔴"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.Parent = title

-- Settings Frame
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(1,-10,1,-60)
settingsFrame.Position = UDim2.new(0,5,0,30)
settingsFrame.BackgroundTransparency = 1
settingsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
settingsFrame.Visible = false
settingsFrame.Parent = frame

-- Safe Mode Button
local safeModeEnabled = true
local safeModeButton = Instance.new("TextButton")
safeModeButton.Size = UDim2.new(1, -10, 0, 30)
safeModeButton.Position = UDim2.new(0,5,0,5)
safeModeButton.BackgroundColor3 = Color3.fromRGB(30,150,30)
safeModeButton.TextColor3 = Color3.fromRGB(255,255,255)
safeModeButton.Font = Enum.Font.SourceSansBold
safeModeButton.TextSize = 18
safeModeButton.Text = "Safe Mode: ON"
safeModeButton.Parent = settingsFrame

safeModeButton.MouseButton1Click:Connect(function()
	safeModeEnabled = not safeModeEnabled
	if safeModeEnabled then
		safeModeButton.Text = "Safe Mode: ON"
		safeModeButton.BackgroundColor3 = Color3.fromRGB(30,150,30)
	else
		safeModeButton.Text = "Safe Mode: OFF"
		safeModeButton.BackgroundColor3 = Color3.fromRGB(150,30,30)
	end
end)

-- Teleport Speed Slider
local settingsLabel = Instance.new("TextLabel")
settingsLabel.Size = UDim2.new(1,0,0,30)
settingsLabel.Position = UDim2.new(0,0,0,40)
settingsLabel.BackgroundTransparency = 1
settingsLabel.TextColor3 = Color3.fromRGB(255,255,255)
settingsLabel.Text = "Teleport Delay"
settingsLabel.Font = Enum.Font.SourceSansBold
settingsLabel.TextSize = 16
settingsLabel.Parent = settingsFrame

local sliderBack = Instance.new("Frame")
sliderBack.Size = UDim2.new(1,-20,0,10)
sliderBack.Position = UDim2.new(0,10,0,70)
sliderBack.BackgroundColor3 = Color3.fromRGB(100,100,100)
sliderBack.BorderSizePixel = 0
sliderBack.Parent = settingsFrame

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5,0,1,0)
sliderFill.BackgroundColor3 = Color3.fromRGB(150,30,30)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBack

local sliderButton = Instance.new("TextButton")
sliderButton.Size = UDim2.new(0,20,0,20)
sliderButton.Position = UDim2.new(0.5,-10,0,-5)
sliderButton.BackgroundColor3 = Color3.fromRGB(255,255,255)
sliderButton.Text = ""
sliderButton.Parent = sliderBack

local sliderValueLabel = Instance.new("TextLabel")
sliderValueLabel.Size = UDim2.new(1,0,0,20)
sliderValueLabel.Position = UDim2.new(0,0,0,90)
sliderValueLabel.BackgroundTransparency = 1
sliderValueLabel.TextColor3 = Color3.fromRGB(200,200,200)
sliderValueLabel.Text = "Delay: 0.8s"
sliderValueLabel.Font = Enum.Font.SourceSans
sliderValueLabel.TextSize = 16
sliderValueLabel.Parent = settingsFrame

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,-10,0,20)
statusLabel.Position = UDim2.new(0,5,1,-25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
statusLabel.Text = "⏸️ Idle"
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 16
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- Scroll Frame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -60)
scrollFrame.Position = UDim2.new(0, 5, 0, 30)
scrollFrame.BackgroundTransparency = 1  -- keep transparent
scrollFrame.ScrollBarThickness = 8
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = frame

-- ==============================
-- Container for buttons
-- ==============================
local container = Instance.new("Frame")
container.Size = UDim2.new(1, 0, 0, 0) -- height grows with UIListLayout
container.BackgroundTransparency = 1
container.ZIndex = 2
container.Parent = scrollFrame

-- UIListLayout for buttons
local uiLayout = Instance.new("UIListLayout")
uiLayout.Padding = UDim.new(0,5)
uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiLayout.Parent = container

-- ==========================
-- Helper Variables
-- ==========================
local Farmer = {Running=false, Mode=nil}
local TeleportDelay = 0.8
local draggingSlider = false
local checkboxes = {}

-- Slider drag logic
sliderButton.MouseButton1Down:Connect(function() draggingSlider = true end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
end)
RunService.RenderStepped:Connect(function()
	if draggingSlider then
		local mouseX = UserInputService:GetMouseLocation().X
		local relative = math.clamp((mouseX - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X,0,1)
		sliderButton.Position = UDim2.new(relative,-10,0,-5)
		sliderFill.Size = UDim2.new(relative,0,1,0)
		TeleportDelay = 0.1 + (1 - relative) * 0.9
		sliderValueLabel.Text = string.format("Delay: %.1fs", TeleportDelay)
	end
end)

-- Toggle settings
settingsButton.MouseButton1Click:Connect(function()
	scrollFrame.Visible = not scrollFrame.Visible
	settingsFrame.Visible = not settingsFrame.Visible
end)

-- ==========================
-- Safe Wait Helper
-- ==========================
local function safeWait(base)
	if safeModeEnabled then
		task.wait(base + math.random() * 0.5)
	else
		task.wait(base)
	end
end

local function randomizePos(pos)
	if safeModeEnabled then
		local offset = Vector3.new((math.random()-0.5)*2,0,(math.random()-0.5)*2)
		return pos + offset
	end
	return pos
end

-- ==========================
-- Teleport Function
-- ==========================
local function tpTo(char,pos)
	if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
	local hrp = char.HumanoidRootPart
	pcall(function()
		hrp.CFrame = CFrame.new(randomizePos(pos) + Vector3.new(0,1,0))
	end)
	if DEBUG_MODE then print("[DEBUG][TP] Teleported to", pos) end
end

-- ==========================
-- Random Teleport
-- ==========================
local teleportSpots = {
    Vector3.new(5, 13, 17),
    Vector3.new(-421, 36, -902),
    Vector3.new(1209, 41, -30),
    Vector3.new(2067, 19, -367),
    Vector3.new(2128, 71, -1241),
    Vector3.new(1097, 107, -2018),
    Vector3.new(421, 73, -2572),
    Vector3.new(-118, 19, -1675),
    Vector3.new(-1078, 138, -1772),
    Vector3.new(-1774, 112, -1120),
    Vector3.new(-1815, 42, -277),
    Vector3.new(-1063, 21, -114),
    Vector3.new(-661, 56, 375)
}

local function randomTeleport(char)
	local spot = teleportSpots[math.random(1,#teleportSpots)]
	if DEBUG_MODE then print("[DEBUG][Random TP] ", spot) end
	tpTo(char, spot)
end

-- ==========================
-- Checkbox creation (updated)
-- ==========================
local function createCheckbox(text, order, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -10, 0, 30)
	button.BackgroundColor3 = Color3.fromRGB(40,40,40)
	button.TextColor3 = Color3.fromRGB(200,200,200)
	button.Text = "[ ] "..text
	button.Font = Enum.Font.SourceSansBold
	button.TextSize = 16
	button.LayoutOrder = order
	button.ZIndex = 1 -- above gradient
	button.Parent = container

	local state = false
	local function setState(val)
		state = val
		button.Text = (state and "[⬜] " or "[ ] ") .. text
		if state then
			for _, other in pairs(checkboxes) do
				if other ~= setState then other(false) end
			end
			callback(true)
		else
			callback(false)
		end
	end
	button.MouseButton1Click:Connect(function() setState(not state) end)
	checkboxes[text] = setState

	-- Update canvas size dynamically
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, uiLayout.AbsoluteContentSize.Y + 10)
end

-- ==========================
-- Farming Settings
-- ==========================
local resourceTimeouts = {
	Coins = 5,
	XPAgility = 5,
	XPJump = 5,
	AppleBarrel = 10,
	BerryBush = 20 / 2,
	FallenTree = 25 / 2,
	FoodPallet = 10,
	LargeBerryBush = 72 / 2,
	SilkBush = 200 / 2,
	StoneDeposit = 50 / 2,
	Stump = 35 / 2,
	CactusFruit = 60 / 2,
	Treasure = 50 / 2,
	DailyChest = 200 / 2,
	DiggingNodes = 20 / 2
}

-- Each resource's path
local resourcePaths = {
	Coins = workspace.Interactions.CurrencyNodes:FindFirstChild("Spawned"),
	XPAgility = workspace.Interactions.CurrencyNodes:FindFirstChild("Spawned"),
	XPJump = workspace.Interactions.CurrencyNodes:FindFirstChild("Spawned"),
	AppleBarrel = workspace.Interactions.Resource,
	BerryBush = workspace.Interactions.Resource,
	FallenTree = workspace.Interactions.Resource,
	FoodPallet = workspace.Interactions.Resource,
	LargeBerryBush = workspace.Interactions.Resource,
	SilkBush = workspace.Interactions.Resource,
	StoneDeposit = workspace.Interactions.Resource,
	Stump = workspace.Interactions.Resource,
	CactusFruit = workspace.Interactions.Resource,
	Treasure = workspace.Interactions.Resource,
	DailyChest = workspace.LocalResources,
	DiggingNodes = workspace.LocalResources
}

local manualResources = {
	"AppleBarrel","BerryBush","FallenTree","FoodPallet","LargeBerryBush",
	"SilkBush","StoneDeposit","Stump","CactusFruit","Treasure","DailyChest","DiggingNodes"
}
-- ==========================
-- Farming Loop
-- ==========================
local function startFarming()
	while true do
		if not Farmer.Running or not Farmer.Mode then 
		statusLabel.Text = "⏸️ Idle"  -- loop is idle
		continue 
		end
		
		local char = player.Character or player.CharacterAdded:Wait()
		local current = Farmer.Mode
		local timeout = resourceTimeouts[current] or 10
		local folder = resourcePaths[current]

		if not folder then
			statusLabel.Text = "⏳ Waiting for "..current.."..."
			safeWait(1)
			continue
		end

		local targets = {}
		for _, obj in ipairs(folder:GetChildren()) do
			if obj.Name == current or obj.Parent.Name == current then
				table.insert(targets,obj)
			end
		end

		if #targets == 0 then
			statusLabel.Text = "⏳ Waiting for "..current.."..."
			randomTeleport(char)
			safeWait(3)
			continue
		end

		for _, obj in ipairs(targets) do
			if not Farmer.Running or Farmer.Mode ~= current then break end
			if not obj or not obj.Parent then continue end

			local pos
			pcall(function()
				local ok, pivot = pcall(function() return obj:GetPivot().Position end)
				if ok then pos = pivot
				elseif obj.PrimaryPart then pos = obj.PrimaryPart.Position
				else
					local part = obj:FindFirstChildWhichIsA("BasePart")
					if part then pos = part.Position end
				end
			end)

			if pos then
				statusLabel.Text = "▶️ Collecting "..current.."..."
				tpTo(char,pos)
				safeWait(TeleportDelay)
			end

			-- ClickDetector firing
			pcall(function()
				local cd = obj:FindFirstChildOfClass("ClickDetector")
				if cd then
					if safeModeEnabled then
						task.wait(math.random()*0.3)
					end
					fireclickdetector(cd)
				end
			end)

			-- Only wait for part removal if Safe Mode is enabled
			if safeModeEnabled then
				local startTime = tick()
				while obj and obj.Parent and Farmer.Running and Farmer.Mode == current do
					if tick() - startTime > timeout then break end
					safeWait(TeleportDelay)
				end
			end
		end
	end
end

-- Anti-AFK loop
task.spawn(function()
	local VirtualUser = game:GetService("VirtualUser")
	local player = game.Players.LocalPlayer
	local char = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")
	local UserInputService = game:GetService("UserInputService")
	local keyboard = UserInputService.InputBegan

	-- Function to simulate walking
	local function simulateWalk()
		local randomDirection = Vector3.new(math.random(), 0, math.random()).unit
		local targetPosition = hrp.Position + randomDirection * 2
		humanoid:MoveTo(targetPosition)
	end

	-- Function to simulate jump using key press (Spacebar)
	local function simulateJump()
		-- Simulate pressing the spacebar key to jump
		local jumpInput = Instance.new("InputObject", game)
		jumpInput.UserInputType = Enum.UserInputType.Keyboard
		jumpInput.KeyCode = Enum.KeyCode.Space

		-- Simulate the key press
		keyboard:Fire(jumpInput)  -- Simulate the key press event
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)  -- Ensure jump state
	end
	
	-- Function to simulate mouse move
	local function simulateMouseMovement()
		local mouse = player:GetMouse()
		local randomOffset = Vector2.new(math.random(-5, 5), math.random(-5, 5))
		mouse.MoveEvent:Fire(randomOffset)
	end

	while true do
		if stopAntiAFK then
			if DEBUG_MODE then print("[DEBUG][Anti-AFK] Stopped due to manual stop request.") end
			break  -- Exit the loop if stopAntiAFK is true
		end

		-- Simulate some random AFK activity every 1 minute (or whatever interval you feel is safe)
		task.wait(60)

		if humanoid and hrp then
			-- Simulate activity: Move and Jump
			simulateWalk()
			task.wait(0.5)
			simulateJump()

			-- Simulate mouse movement
			simulateMouseMovement()

			if DEBUG_MODE then print("[DEBUG][Anti-AFK] Simulated walking, jumping, and mouse movement.") end
		end
	end
end)

-- Function to stop Anti-AFK manually
local function stopAFK()
	stopAntiAFK = true  -- Set the control variable to true to stop the loop
end

-- ==========================
-- Setup Checkboxes
-- ==========================
local order = 0
createCheckbox("Coins",order,function(state) Farmer.Running=state Farmer.Mode=state and "Coins" or nil end) order=order+1
createCheckbox("XP Agility",order,function(state) Farmer.Running=state Farmer.Mode=state and "XPAgility" or nil end) order=order+1
createCheckbox("XP Jump",order,function(state) Farmer.Running=state Farmer.Mode=state and "XPJump" or nil end) order=order+1
for _,res in ipairs(manualResources) do
	createCheckbox(res, order, function(state)
		Farmer.Running = state
		Farmer.Mode = state and res or nil
	end)
	order = order + 1
end

-- Close/Delete button functionality
closeButton.MouseButton1Click:Connect(function()
	Farmer.Running = false
	Farmer.Mode = nil
	stopAFK()
	if DEBUG_MODE then print("[DEBUG] Closing UI and stopping all loops...") end
	if screenGui then
		screenGui:Destroy()
	end
end)

-- Start farming loop in background
task.spawn(startFarming)

if DEBUG_MODE then print("[DEBUG] AutoFarm "..VERSION.." fully loaded!") end

