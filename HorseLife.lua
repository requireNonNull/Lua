-- // AutoFarm Script (Timeout-based) v4.0
-- Single-select UI checkboxes with scrollable UI and full debug

local VERSION = "v4.7"
local DEBUG_MODE = true -- Always debug every step

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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

-- Close Button (top right)
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0,30,1,0)
closeButton.Position = UDim2.new(1,-30,0,0)
closeButton.BackgroundColor3 = Color3.fromRGB(150,50,50)
closeButton.TextColor3 = Color3.fromRGB(255,255,255)
closeButton.Text = "❌"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.Parent = title

-- Add this under UI Setup (after title)
local settingsButton = Instance.new("TextButton")
settingsButton.Size = UDim2.new(0,30,1,0)
settingsButton.Position = UDim2.new(0,0,0,0)
settingsButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
settingsButton.TextColor3 = Color3.fromRGB(255,255,255)
settingsButton.Text = "⚙️"
settingsButton.Font = Enum.Font.SourceSansBold
settingsButton.TextSize = 18
settingsButton.Parent = title

-- Settings Frame (hidden by default)
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(1,-10,1,-60)
settingsFrame.Position = UDim2.new(0,5,0,30)
settingsFrame.BackgroundTransparency = 1
settingsFrame.Visible = false
settingsFrame.Parent = frame

-- inside your UI creation code, in the Settings area
local safeModeEnabled = false -- default OFF

local safeModeButton = Instance.new("TextButton")
safeModeButton.Size = UDim2.new(1, -10, 0, 30)
safeModeButton.Position = UDim2.new(0, 5, 0, 5) -- top of settings
safeModeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
safeModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
safeModeButton.Font = Enum.Font.SourceSansBold
safeModeButton.TextSize = 18
safeModeButton.Text = "Safe Mode: OFF"
safeModeButton.Parent = settingsFrame

local settingsLabel = Instance.new("TextLabel")
settingsLabel.Size = UDim2.new(1,0,0,30)
settingsLabel.BackgroundTransparency = 1
settingsLabel.TextColor3 = Color3.fromRGB(255,255,255)
settingsLabel.Text = "Teleport Speed"
settingsLabel.Font = Enum.Font.SourceSansBold
settingsLabel.TextSize = 16
settingsLabel.Parent = settingsFrame

-- Fake Slider
local sliderBack = Instance.new("Frame")
sliderBack.Size = UDim2.new(1,-20,0,10)
sliderBack.Position = UDim2.new(0,10,0,40)
sliderBack.BackgroundColor3 = Color3.fromRGB(100,100,100)
sliderBack.BorderSizePixel = 0
sliderBack.Parent = settingsFrame

local sliderValueLabel = Instance.new("TextLabel")
sliderValueLabel.Size = UDim2.new(1,0,0,20)
sliderValueLabel.Position = UDim2.new(0,0,0,60)
sliderValueLabel.BackgroundTransparency = 1
sliderValueLabel.TextColor3 = Color3.fromRGB(200,200,200)
sliderValueLabel.Text = "Delay: 0.3s"
sliderValueLabel.Font = Enum.Font.SourceSans
sliderValueLabel.TextSize = 16
sliderValueLabel.Parent = settingsFrame

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5,0,1,0) -- default 50%
sliderFill.BackgroundColor3 = Color3.fromRGB(0,200,0)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBack

local sliderButton = Instance.new("TextButton")
sliderButton.Size = UDim2.new(0,20,0,20)
sliderButton.Position = UDim2.new(0.5,-10,0,-5)
sliderButton.BackgroundColor3 = Color3.fromRGB(255,255,255)
sliderButton.Text = ""
sliderButton.Parent = sliderBack

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,-10,0,20)
statusLabel.Position = UDim2.new(0,5,1,-25)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
statusLabel.Text = "Status: Idle"
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 16
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- Scroll Frame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1,-10,1,-60)
scrollFrame.Position = UDim2.new(0,5,0,30)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 8
scrollFrame.CanvasSize = UDim2.new(0,0,0,0)
scrollFrame.Parent = frame

local uiLayout = Instance.new("UIListLayout")
uiLayout.Padding = UDim.new(0,5)
uiLayout.Parent = scrollFrame
uiLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ==========================
-- Checkbox creation
-- ==========================
local checkboxes = {}
local function createCheckbox(text, order, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1,-10,0,30)
	button.BackgroundColor3 = Color3.fromRGB(40,40,40)
	button.TextColor3 = Color3.fromRGB(200,200,200)
	button.Text = "[ ] "..text
	button.Font = Enum.Font.SourceSansBold
	button.TextSize = 16
	button.LayoutOrder = order
	button.Parent = scrollFrame

	local state = false
	local function setState(val)
		state = val
		button.Text = (state and "[☑] " or "[ ] ") .. text
		if state then
			for _, other in pairs(checkboxes) do
				if other ~= setState then
					other(false)
				end
			end
			callback(true)
		else
			callback(false)
		end
		if DEBUG_MODE then
			print("[DEBUG] Checkbox", text, "set to", state)
		end
	end
	button.MouseButton1Click:Connect(function()
		setState(not state)
	end)
	checkboxes[text] = setState
	scrollFrame.CanvasSize = UDim2.new(0,0,0,uiLayout.AbsoluteContentSize.Y + 10)
end

-- Random teleport positions
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


-- ==========================
-- Helper functions
-- ==========================

local function tpTo(char,pos)
	if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
	local hrp = char.HumanoidRootPart

	if safeModeEnabled then
		-- Safe mode: move smoothly with tween, stop ~5 studs before target
		local targetPos = pos + Vector3.new(0, 3, 0) -- a bit above ground
		local direction = (targetPos - hrp.Position).Unit
		local stopPos = targetPos - direction * 5 -- stop 5 studs early

		local dist = (stopPos - hrp.Position).Magnitude
		local speed = 16 -- humanoid walk speed equivalent
		local time = dist / speed

		local tween = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {
			CFrame = CFrame.new(stopPos)
		})
		tween:Play()
		tween.Completed:Wait()

		if DEBUG_MODE then print("[DEBUG][SafeMode] Tweened to near", pos) end
	else
		-- Normal instant teleport
		pcall(function()
			hrp.CFrame = CFrame.new(pos + Vector3.new(0,10,0))
			if DEBUG_MODE then print("[DEBUG][TP] Instant teleported to", pos) end
		end)
	end
end


-- helper: random teleport
local function randomTeleport(char)
    local spot = teleportSpots[math.random(1, #teleportSpots)]
    print("[DEBUG] Random teleporting to:", spot)
    tpTo(char, spot)
end

-- ==========================
-- Farming settings
-- ==========================
-- Each resource has a timeout (seconds) for how long we try to farm it
local resourceTimeouts = {
	Coins = 5,
	XPAgility = 5,
	XPJump = 5,
	AppleBarrel = 5 / 2,
	BerryBush = 20 / 2,
	FallenTree = 25 / 2,
	FoodPallet = 10 / 2,
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

local Farmer = {Running=false, Mode=nil}

-- Global Teleport delay (used in farming loop)
local TeleportDelay = 0.3

-- Slider drag
local draggingSlider = false
sliderButton.MouseButton1Down:Connect(function()
	draggingSlider = true
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = false
	end
end)

RunService.RenderStepped:Connect(function()
	if draggingSlider then
		local mouseX = UserInputService:GetMouseLocation().X
		local relative = math.clamp((mouseX - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X,0,1)
		sliderButton.Position = UDim2.new(relative,-10,0,-5)
		sliderFill.Size = UDim2.new(relative,0,1,0)

		-- Scale delay between 0.1s (fastest) and 1.0s (slowest)
		TeleportDelay = 0.1 + (1 - relative) * 0.9

		sliderValueLabel.Text = string.format("Delay: %.1fs", TeleportDelay)

		if DEBUG_MODE then print("[DEBUG] TeleportDelay set to",TeleportDelay) end
	end
end)

-- Toggle settings
settingsButton.MouseButton1Click:Connect(function()
	scrollFrame.Visible = not scrollFrame.Visible
	settingsFrame.Visible = not settingsFrame.Visible
end)

safeModeButton.MouseButton1Click:Connect(function()
    safeModeEnabled = not safeModeEnabled
    if safeModeEnabled then
        safeModeButton.Text = "Safe Mode: ON"
        safeModeButton.BackgroundColor3 = Color3.fromRGB(30, 150, 30)
    else
        safeModeButton.Text = "Safe Mode: OFF"
        safeModeButton.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
    end
end)

closeButton.MouseButton1Click:Connect(function()
    Farmer.Running = false
    Farmer.Mode = nil
    if DEBUG_MODE then print("[DEBUG] Closing UI and stopping all loops...") end
    if screenGui then
        screenGui:Destroy()
    end
end)

-- ==========================
-- Farming loop
-- ==========================
local function startFarming()
	while true do
		task.wait(0.1)
		if not Farmer.Running or not Farmer.Mode then continue end

		local char = player.Character or player.CharacterAdded:Wait()
		local current = Farmer.Mode
		local timeout = resourceTimeouts[current] or 10
		local folder = resourcePaths[current]

		if not folder then
			statusLabel.Text = "Waiting for " .. current .. "..."
			if DEBUG_MODE then print("[DEBUG] Resource folder missing for", current) end
			task.wait(1)
			continue
		end

		local targets = {}
		for _, obj in ipairs(folder:GetChildren()) do
			if obj.Name == current or obj.Parent.Name == current then
				table.insert(targets,obj)
			end
		end

		if #targets == 0 then
			statusLabel.Text = "Waiting for " .. current .. "..."
			if DEBUG_MODE then print("[DEBUG] No targets found for", current) end
			-- nothing found → random teleport + wait
	        randomTeleport(char)
	        task.wait(3) -- small pause so map loads & resources can spawn
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
				statusLabel.Text = "Collecting " .. current .. "..."
				if DEBUG_MODE then print("[DEBUG] Moving to object at", pos) end
				tpTo(char,pos)
				task.wait(TeleportDelay)
			end

			local cd = obj:FindFirstChildOfClass("ClickDetector")
			if cd then
			    print("Found ClickDetector for:", obj.Name, "Parent:", cd.Parent:GetFullName())
			else
			    print("No ClickDetector found for", obj.Name)
			end

			-- Fire ClickDetector if exists
			pcall(function() fireclickdetector(obj:FindFirstChildOfClass("ClickDetector")) end)

			local startTime = tick()
			while obj and obj.Parent and Farmer.Running and Farmer.Mode == current do
				if tick() - startTime > timeout then
					if DEBUG_MODE then print("[DEBUG] Timeout reached for", obj.Name) end
					break
				end
				task.wait(TeleportDelay)
			end
		end
	end
end

-- ==========================
-- UI Setup
-- ==========================
local order = 0
createCheckbox("Coins",order,function(state)
	Farmer.Running=state
	Farmer.Mode=state and "Coins" or nil
end) order = order + 1

createCheckbox("XP Agility",order,function(state)
	Farmer.Running=state
	Farmer.Mode=state and "XPAgility" or nil
end) order = order + 1

createCheckbox("XP Jump",order,function(state)
	Farmer.Running=state
	Farmer.Mode=state and "XPJump" or nil
end) order = order + 1

for _,resName in ipairs(manualResources) do
	createCheckbox(resName,order,function(state)
		Farmer.Running=state
		Farmer.Mode=state and resName or nil
	end)
	order = order + 1
end

if DEBUG_MODE then print("[DEBUG] AutoFarm loaded with",order,"checkboxes") end

-- ==========================
-- Start farming in background
-- ==========================
task.spawn(startFarming)
