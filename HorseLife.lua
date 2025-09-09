-- // AutoFarm Script (Manual Resources with HP) v3.0
-- Single-select UI checkboxes with scrollable UI and full debug

local VERSION = "v3.1"
local DEBUG_MODE = true -- Always debug every step

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

-- ==========================
-- Helper functions
-- ==========================
local function tpTo(char,pos)
	if char and char:FindFirstChild("HumanoidRootPart") then
		pcall(function()
			char:PivotTo(CFrame.new(pos + Vector3.new(0,10,0)))
			if DEBUG_MODE then print("[DEBUG] Teleported to", pos) end
		end)
	end
end

local resourceArgs = {5,true}
local manualResources = {
	"AppleBarrel","BerryBush","FallenTree","FoodPallet","LargeBerryBush",
	"SilkBush","StoneDeposit","Stump","Treasure"
}

local Farmer = {Running=false, Mode=nil}

-- Per-object HP reading
local function getObjectHP(obj)
	local success, hp = pcall(function()
		if not obj or not obj.Parent then return nil end
		local gui = obj:FindFirstChild("DefaultResourceNodeGui")
		if not gui then return nil end
		local bar = gui:FindFirstChild("Bar")
		if not bar or not bar:FindFirstChild("Background") then return nil end
		local hpText = bar.Background:FindFirstChild("HP")
		if not hpText or not hpText:IsA("TextLabel") then return nil end
		return tonumber(hpText.Text)
	end)
	if not success then
		if DEBUG_MODE then print("[DEBUG] getObjectHP error for",obj.Name) end
	end
	return hp
end

-- ==========================
-- Farming loop
-- ==========================
local function startFarming()
	while true do
		task.wait(0.1)
		if not Farmer.Running or not Farmer.Mode then continue end

		local char = player.Character or player.CharacterAdded:Wait()
		local current = Farmer.Mode

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
			if DEBUG_MODE then print("[DEBUG] Scan folder missing for", current) end
			task.wait(1)
			continue
		end

		local targets = {}
		for _, obj in ipairs(scanFolder:GetChildren()) do
			if obj.Name == current then table.insert(targets,obj) end
		end

		if #targets == 0 then
			statusLabel.Text = "Waiting for " .. current .. "..."
			if DEBUG_MODE then print("[DEBUG] No targets found for", current) end
			task.wait(1)
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
				task.wait(0.3)
			end

			-- Fire ClickDetector
			pcall(function() fireclickdetector(obj:FindFirstChildOfClass("ClickDetector")) end)

			--local remote = obj:FindFirstChild("RemoteEvent") or obj:FindFirstChild("RemoteFunction")

			-- Infinite spam until HP gone or object disappears
			local spamStart = tick()
			while obj and obj.Parent and Farmer.Running and Farmer.Mode == current do
				local hp = getObjectHP(obj)
				if hp == 0 or not hp then
					if DEBUG_MODE then print("[DEBUG] Object", obj.Name, "finished or missing HP") end
					break
				end

				--if remote then
					--pcall(function()
						--if remote.ClassName == "RemoteEvent" then remote:FireServer(unpack(resourceArgs))
						--elseif remote.ClassName == "RemoteFunction" then remote:InvokeServer(unpack(resourceArgs)) end
						--if DEBUG_MODE then print("[DEBUG] Fired remote for", obj.Name) end
					--end)
				--end

				task.wait(0.4)
				if tick()-spamStart > 40 then -- safety timeout for high HP
					if DEBUG_MODE then print("[DEBUG] Timeout reached for", obj.Name) end
					break
				end
			end
		end
		task.wait(0.2) -- small delay before re-scan
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
