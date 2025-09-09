-- // AutoFarm Script (Manual Resources)
-- Single-select UI checkboxes with scrollable UI and debug mode

local VERSION = "v2.7"
local DEBUG_MODE = true -- Output debug info

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- UI ------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 300)
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

-- Checkbox creation
local checkboxes = {}
local function createCheckbox(text, order, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1,-10,0,30)
	button.BackgroundColor3 = Color3.fromRGB(40,40,40)
	button.TextColor3 = Color3.fromRGB(200,200,200)
	button.Text = "[ ] "..text
	button.Font = Enum.Font.SourceSans
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

-- Helpers
local character = player.Character or player.CharacterAdded:Wait()
local function tpTo(char,pos)
	if char and char:FindFirstChild("HumanoidRootPart") then
		char:PivotTo(CFrame.new(pos+Vector3.new(0,10,0)))
		if DEBUG_MODE then
			print("[DEBUG] TPS to:", pos)
		end
	end
end

-- Farmer
local Farmer = {Running=false, Mode=nil}
local resourceArgs = {5,true}

-- Manual resources
local manualResources = {
	"AppleBarrel",
	"BerryBush",
	"FallenTree",
	"FoodPallet",
	"LargeBerryBush",
	"SilkBush",
	"StoneDeposit",
	"Stump",
	"Treasure",
}

local function getResourceTargets(name)
	local resFolder = workspace:FindFirstChild("Interactions") 
		and workspace.Interactions:FindFirstChild("Resource")
	if not resFolder then return {} end

	local targets = {}
	for _, obj in ipairs(resFolder:GetChildren()) do
		if obj and obj.Name == name then
			table.insert(targets,obj)
		end
	end
	return targets
end

-- =======================================
-- FARMING LOOP (Name-only, continuous)
-- =======================================
local function startFarming()
	while Farmer.Running do
		local char = player.Character
		if not char then
			task.wait(1)
			continue
		end

		local current = Farmer.Mode
		if not current then
			task.wait(0.5)
			continue
		end

		local scanFolder
		if current == "Coins" or current == "XPAgility" or current == "XPJump" then
			scanFolder = workspace:FindFirstChild("Interactions")
				and workspace.Interactions:FindFirstChild("CurrencyNodes")
				and workspace.Interactions.CurrencyNodes:FindFirstChild("Spawned")
		else
			scanFolder = workspace:FindFirstChild("Interactions")
				and workspace.Interactions:FindFirstChild("Resource")
		end
		if not scanFolder then
			statusLabel.Text = "Waiting for " .. current .. "..."
			task.wait(1)
			continue
		end

		local targets = {}
		for _, obj in ipairs(scanFolder:GetChildren()) do
			if obj.Name == current then
				table.insert(targets, obj)
			end
		end

		if #targets == 0 then
			statusLabel.Text = "Waiting for " .. current .. "..."
			task.wait(1)
			continue
		end

		for _, obj in ipairs(targets) do
			if not Farmer.Running or Farmer.Mode ~= current then break end

			local pos
			local ok, pivot = pcall(function() return obj:GetPivot().Position end)
			if ok then pos = pivot
			elseif obj.PrimaryPart then pos = obj.PrimaryPart.Position
			else
				local part = obj:FindFirstChildWhichIsA("BasePart")
				if part then pos = part.Position end
			end

			if pos then
				statusLabel.Text = "Collecting " .. current .. "..."
				tpTo(char, pos + Vector3.new(0,10,0))
				task.wait(0.3)
			end

			pcall(function() fireclickdetector(obj:FindFirstChildWhichIsA("ClickDetector")) end)

			local remote = obj:FindFirstChild("RemoteEvent") or obj:FindFirstChild("RemoteFunction")
			local spamStart = tick()
			while obj.Parent and Farmer.Running and Farmer.Mode == current do
				if remote then
					if remote.ClassName == "RemoteEvent" then
						pcall(function() remote:FireServer(unpack(resourceArgs)) end)
					elseif remote.ClassName == "RemoteFunction" then
						pcall(function() remote:InvokeServer(unpack(resourceArgs)) end)
					end
				end
				task.wait(math.random(4,10)/10)
				if tick() - spamStart > 8 then break end
			end
		end

		task.wait(0.5)
	end
end

-- UI Setup ------------------------
local order=0
local function setupCheckbox(name)
	createCheckbox(name, order, function(state)
		Farmer.Running = state
		Farmer.Mode = state and name or nil
		if state then
			-- Start farming in separate thread
			spawn(startFarming)
		end
	end)
	order = order + 1
end

-- Coins & XP
setupCheckbox("Coins")
setupCheckbox("XPAgility")
setupCheckbox("XPJump")

-- Manual resources
for _, resName in ipairs(manualResources) do
	setupCheckbox(resName) end

if DEBUG_MODE then print("[DEBUG] AutoFarm loaded with", order, "checkboxes") end
