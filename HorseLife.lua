-- // AutoFarm Script (Manual Resources)
-- Single-select UI checkboxes with scrollable UI and debug mode

local VERSION = "v2.1"
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
statusLabel.AnchorPoint = Vector2.new(0,1)
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
scrollFrame.Size = UDim2.new(1,-10,1,-60) -- leaves space for labels
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
		button.Text = (state and "[X] " or "[ ] ") .. text
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
	for _, part in ipairs(getXPParts()) do
		if part.Name==xpName and part.Parent then
			tpTo(player.Character, part.Position)
			repeat task.wait(0.3) until not part.Parent
		end
	end
end

-- Resources (manual list)
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
		if obj.Name == name and obj:IsA("Model") then
			local cd = obj:FindFirstChildOfClass("ClickDetector")
			local re = obj:FindFirstChild("RemoteEvent")
			if cd and re then
				table.insert(targets,{Model=obj,Click=cd,Remote=re})
			end
		end
	end

	if DEBUG_MODE then
		print("[DEBUG] Found", #targets, "targets for", name)
	end
	return targets
end

-- Farming Loop (WITH dynamic re-scan before each TP)
task.spawn(function()
	while true do
		if Farmer.Running and Farmer.Mode then
			local char = player.Character or player.CharacterAdded:Wait()

			if Farmer.Mode == "Coins" then
				for _, coin in ipairs(getCoinParts()) do
					if not Farmer.Running or Farmer.Mode~="Coins" then break end
					if coin and coin.Parent then
						statusLabel.Text = "Collecting Coins..."
						tpTo(char, coin.Position)
						repeat task.wait(0.3) until not coin.Parent
					end
				end

			elseif Farmer.Mode=="XPAgility" or Farmer.Mode=="XPJump" then
				statusLabel.Text="Training "..Farmer.Mode.."..."
				doXP(Farmer.Mode)

			else
				-- new logic: repeatedly find a single live resource model, process it, then re-scan
				local current = Farmer.Mode
				local resFolder = workspace:FindFirstChild("Interactions")
					and workspace.Interactions:FindFirstChild("Resource")

				if not resFolder then
					statusLabel.Text = "Waiting for Resource folder..."
					task.wait(2)
				else
					-- loop: find one matching resource and process it; repeat until none left or mode changed
					local foundAny = false
					repeat
						if not Farmer.Running or Farmer.Mode~=current then break end

						-- find a single live model of this resource type
						local found = nil
						for _, obj in ipairs(resFolder:GetChildren()) do
							if not Farmer.Running or Farmer.Mode~=current then break end
							if obj and obj:IsA("Model") and obj.Name == current and obj.Parent then
								local cd = obj:FindFirstChildOfClass("ClickDetector")
								local re = obj:FindFirstChild("RemoteEvent") or obj:FindFirstChild("RemoteFunction")
								if cd and re then
									found = { Model = obj, Click = cd, Remote = re }
									break
								end
							end
						end

						if not found then
							-- nothing right now
							if DEBUG_MODE then print("[DEBUG] No live resource found for", current) end
							break
						end

						foundAny = true

						-- double-check it's still parented before teleporting
						if not (found.Model and found.Model.Parent) then
							-- it vanished; continue to next iteration to find another
							if DEBUG_MODE then print("[DEBUG] Found resource vanished before TP:", found.Model and found.Model.Name) end
							task.wait(0.1)
							continue
						end

						-- Process the found resource
						statusLabel.Text = "Farming " .. current .. "..."
						tpTo(char, found.Model:GetPivot().Position)

						if DEBUG_MODE then print("[DEBUG] Clicking", found.Model.Name) end
						pcall(function() fireclickdetector(found.Click) end)
						task.wait(0.25)

						-- Spam remote until model disappears (or mode changes)
						local timeout = 8
						local elapsed = 0
						repeat
							if not (found.Model and found.Model.Parent) then break end
							if DEBUG_MODE then print("[DEBUG] Firing remote for", found.Model.Name, "(", (found.Remote and found.Remote.ClassName or "nil"), ")") end
							pcall(function()
								if found.Remote and found.Remote.ClassName == "RemoteEvent" then
									found.Remote:FireServer(unpack(resourceArgs))
								elseif found.Remote and found.Remote.ClassName == "RemoteFunction" then
									found.Remote:InvokeServer(unpack(resourceArgs))
								end
							end)
							local waitTime = math.random(4,10)/10 -- 0.4 - 1.0
							task.wait(waitTime)
							elapsed = elapsed + waitTime
						until not (found.Model and found.Model.Parent) or Farmer.Mode~=current or elapsed >= timeout

						-- small breathe before re-scan to avoid tight loop
						task.wait(0.15)
					until not Farmer.Running or Farmer.Mode~=current

					-- if no resource was found at all, wait for them to spawn
					if not foundAny then
						statusLabel.Text = "Waiting for "..current.."..."
						task.wait(1)
					end
				end
			end
		else
			statusLabel.Text="Status: Idle"
			task.wait(1)
		end

		RunService.RenderStepped:Wait()
	end
end)


-- UI Setup ------------------------
local order=0
createCheckbox("Coins",order,function(state)
	Farmer.Running=state
	Farmer.Mode=state and "Coins" or nil
end) order=order+1

createCheckbox("XP Agility",order,function(state)
	Farmer.Running=state
	Farmer.Mode=state and "XPAgility" or nil
end) order=order+1

createCheckbox("XP Jump",order,function(state)
	Farmer.Running=state
	Farmer.Mode=state and "XPJump" or nil
end) order=order+1

-- Add manual resources
for _,resName in ipairs(manualResources) do
	createCheckbox(resName,order,function(state)
		Farmer.Running=state
		Farmer.Mode=state and resName or nil
	end)
	order=order+1
end

if DEBUG_MODE then print("[DEBUG] AutoFarm loaded with",order,"checkboxes") end
