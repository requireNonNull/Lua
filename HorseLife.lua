-- // AutoFarm Script (Coins, XP, Resources)
-- Single-select UI checkboxes with scrollable UI and debug mode

-- CONFIG ------------------------
local DEBUG_MODE = true -- set to true to output debug info to console

-- UI ------------------------
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = game:GetService("CoreGui")

-- Outer draggable frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 300)
frame.Position = UDim2.new(0, 50, 0, 150)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

-- Draggable logic
local dragging, dragInput, dragStart, startPos

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
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(update)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "AutoFarm Menu"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame

-- Version
local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(1, -10, 0, 20)
versionLabel.Position = UDim2.new(0, 5, 1, -55)
versionLabel.BackgroundTransparency = 1
versionLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
versionLabel.Text = "v1.6"
versionLabel.Font = Enum.Font.SourceSansItalic
versionLabel.TextSize = 14
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.Parent = frame

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 25)
statusLabel.Position = UDim2.new(0, 5, 1, -30)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Text = "Status: Idle"
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 16
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- Scrolling Frame for checkboxes
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -60)
scrollFrame.Position = UDim2.new(0, 5, 0, 30)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 8
scrollFrame.CanvasSize = UDim2.new(0,0,0,0)
scrollFrame.Parent = frame

local uiLayout = Instance.new("UIListLayout")
uiLayout.Padding = UDim.new(0, 5)
uiLayout.Parent = scrollFrame
uiLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Checkbox creation
local checkboxes = {}
local function createCheckbox(text, order, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -10, 0, 30)
	button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	button.TextColor3 = Color3.fromRGB(200, 200, 200)
	button.Text = "[ ] " .. text
	button.Font = Enum.Font.SourceSans
	button.TextSize = 16
	button.LayoutOrder = order
	button.Parent = scrollFrame

	local state = false
	local function setState(val)
		state = val
		button.Text = (state and "[X] " or "[ ] ") .. text
		if state then
			-- uncheck all others
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
	-- update canvas
	scrollFrame.CanvasSize = UDim2.new(0,0,0,uiLayout.AbsoluteContentSize.Y + 10)
end

-- Helpers
local character = player.Character or player.CharacterAdded:Wait()

local function tpTo(char, pos)
	if char and char:FindFirstChild("HumanoidRootPart") then
		char:PivotTo(CFrame.new(pos + Vector3.new(0,10,0)))
		if DEBUG_MODE then
			print("[DEBUG] TPS to position:", pos)
		end
	end
end

-- Farmer
local Farmer = {Running=false, Mode=nil}

-- Coins
local function getCoinParts()
	local spawned = workspace:FindFirstChild("Interactions") 
		and workspace.Interactions:FindFirstChild("CurrencyNodes") 
		and workspace.Interactions.CurrencyNodes:FindFirstChild("Spawned")
	if not spawned then return {} end
	local coins = {}
	for _, obj in ipairs(spawned:GetChildren()) do
		if (obj:IsA("BasePart") or obj:IsA("MeshPart")) and obj.Name == "Coins" then
			table.insert(coins,obj)
		end
	end
	return coins
end

-- XP
local function getXPParts()
	local spawned = workspace:FindFirstChild("Interactions") 
		and workspace.Interactions:FindFirstChild("CurrencyNodes") 
		and workspace.Interactions.CurrencyNodes:FindFirstChild("Spawned")
	if not spawned then return {} end
	local xpParts = {}
	for _, name in ipairs({"XPAgility","XPJump"}) do
		local part = spawned:FindFirstChild(name)
		if part then table.insert(xpParts,part) end
	end
	return xpParts
end

local function doXP(xpName)
	local parts = getXPParts()
	for _, part in ipairs(parts) do
		if part.Name == xpName and part.Parent then
			tpTo(player.Character, part.Position)
			repeat task.wait(0.3) until not part.Parent
		end
	end
end

-- Resources
local resourceArgs = {5,true}
local function getResourceModels(name)
	local resFolder = workspace:WaitForChild("Interactions"):WaitForChild("Resource")
	local targets = {}
	local model = resFolder:FindFirstChild(name)
	if model then
		for _, obj in ipairs(model:GetChildren()) do
			if obj:IsA("Model") then
				local cd = obj:FindFirstChildOfClass("ClickDetector")
				local re = obj:FindFirstChild("RemoteEvent")
				if cd and re then
					table.insert(targets,{Model=obj,Click=cd,Remote=re})
				end
			end
		end
	end
	if DEBUG_MODE then
		print("[DEBUG] Found", #targets, "targets for resource", name)
	end
	return targets
end

-- Farming loop
task.spawn(function()
	while true do
		if Farmer.Running and Farmer.Mode then
			local char = player.Character or player.CharacterAdded:Wait()
			if Farmer.Mode == "Coins" then
				local coins = getCoinParts()
				for _, coin in ipairs(coins) do
					if not Farmer.Running or Farmer.Mode ~= "Coins" then break end
					if coin and coin.Parent then
						statusLabel.Text = "Collecting Coins..."
						tpTo(char, coin.Position)
						repeat task.wait(0.3) until not coin.Parent
					end
				end
			elseif Farmer.Mode == "XPAgility" or Farmer.Mode == "XPJump" then
				statusLabel.Text = "Training " .. Farmer.Mode .. "..."
				doXP(Farmer.Mode)
			else
				local currentMode = Farmer.Mode
				local targets = getResourceModels(Farmer.Mode)
				if #targets > 0 then
					for _, res in ipairs(targets) do
						if not Farmer.Running or Farmer.Mode ~= currentMode then break end
						if res.Model and res.Model.Parent then
							statusLabel.Text = "Farming " .. Farmer.Mode .. "..."
							tpTo(char, res.Model:GetPivot().Position)
							fireclickdetector(res.Click)
							task.wait(0.3)
							repeat
								if DEBUG_MODE then print("[DEBUG] Firing RemoteEvent for", res.Model.Name) end
								res.Remote:FireServer(unpack(resourceArgs))
								task.wait(math.random(4,10)/10)
							until not res.Model.Parent or Farmer.Mode ~= currentMode
						end
					end
				else
					statusLabel.Text = "Waiting for " .. Farmer.Mode .. "..."
					if DEBUG_MODE then print("[DEBUG] No targets for resource", Farmer.Mode) end
					task.wait(2)
				end
			end
		else
			statusLabel.Text = "Status: Idle"
			task.wait(1)
		end
		RunService.RenderStepped:Wait()
	end
end)

-- UI Setup
local order = 0
createCheckbox("Coins", order, function(state)
	Farmer.Running = state
	Farmer.Mode = state and "Coins" or nil
end)
order = order + 1

createCheckbox("XP Agility", order, function(state)
	Farmer.Running = state
	Farmer.Mode = state and "XPAgility" or nil
end)
order = order + 1

createCheckbox("XP Jump", order, function(state)
	Farmer.Running = state
	Farmer.Mode = state and "XPJump" or nil
end)
order = order + 1

-- Add all resources dynamically
local resFolder = workspace:WaitForChild("Interactions"):WaitForChild("Resource")
for _, resource in ipairs(resFolder:GetChildren()) do
	if resource:IsA("Folder") or resource:IsA("Model") then
		local resName = resource.Name
		createCheckbox(resName, order, function(state)
			Farmer.Running = state
			Farmer.Mode = state and resName or nil
		end)
		order = order + 1
	end
end

if DEBUG_MODE then print("[DEBUG] AutoFarm UI loaded with", order, "checkboxes") end
