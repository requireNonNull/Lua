-- // AutoFarm Script (Manual Resources)
-- Single-select UI checkboxes with scrollable UI and debug mode

local VERSION = "v2.4"
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
--statusLabel.AnchorPoint = Vector2.new(0,1)
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
	if not resFolder then
		if DEBUG_MODE then print("[DEBUG][getResourceTargets] Resource folder missing") end
		return {}
	end

	local targets = {}
	for i, obj in ipairs(resFolder:GetChildren()) do
		if obj and obj:IsA("Model") and obj.Name == name then
			local cd = obj:FindFirstChildOfClass("ClickDetector")
			local re = obj:FindFirstChild("RemoteEvent") or obj:FindFirstChild("RemoteFunction")
			table.insert(targets, { Model = obj, Click = cd, Remote = re })

			if DEBUG_MODE then
				local fullname = pcall(function() return obj:GetFullName() end) and obj:GetFullName() or tostring(obj)
				print("[DEBUG][getResourceTargets] #" .. i .. " ->", fullname,
					" parent=" .. tostring(obj.Parent and obj.Parent.Name or "nil"),
					" Click=" .. tostring((cd and "yes") or "no"),
					" RemoteClass=" .. tostring(re and re.ClassName or "nil"),
					" RemoteName=" .. tostring(re and re.Name or "nil"))
			end
		end
	end

	if DEBUG_MODE then print("[DEBUG][getResourceTargets] total targets for", name, "=", #targets) end
	return targets
end

-- Farming Loop (with debug + dynamic rescan + anti-freeze)
task.spawn(function()
	while true do
		if Farmer.Running and Farmer.Mode then
			local char = player.Character or player.CharacterAdded:Wait()

			-- =========================
			-- COINS
			-- =========================
			if Farmer.Mode == "Coins" then
				if DEBUG_MODE then print("[DEBUG][Loop] Farming Coins...") end

				for _, coin in ipairs(getCoinParts()) do
					if not Farmer.Running or Farmer.Mode ~= "Coins" then break end
					if coin and coin.Parent then
						statusLabel.Text = "Collecting Coins..."
						if DEBUG_MODE then print("[DEBUG][Coin] Teleporting to coin:", coin:GetFullName()) end

						tpTo(char, coin.Position)
						local start = tick()
						repeat task.wait(0.3) until not coin.Parent or tick() - start > 6

						if DEBUG_MODE then print("[DEBUG][Coin] Coin collected or timeout") end
					end
				end

			-- =========================
			-- XP (Agility / Jump)
			-- =========================
			elseif Farmer.Mode == "XPAgility" or Farmer.Mode == "XPJump" then
				statusLabel.Text = "Training " .. Farmer.Mode .. "..."
				if DEBUG_MODE then print("[DEBUG][Loop] Training XP:", Farmer.Mode) end
				doXP(Farmer.Mode)

			-- =========================
			-- MANUAL RESOURCES
			-- =========================
			else
				local current = Farmer.Mode
				if DEBUG_MODE then print("[DEBUG][Loop] Farming resource:", current) end

				while Farmer.Running and Farmer.Mode == current do
					local targets = getResourceTargets(current)

					if #targets == 0 then
						statusLabel.Text = "Waiting for " .. current .. "..."
						if DEBUG_MODE then print("[DEBUG][Resource] No live targets for", current) end
						task.wait(1)
					else
						for idx, res in ipairs(targets) do
							if not Farmer.Running or Farmer.Mode ~= current then break end

							local model = res.Model
							if not model or not model.Parent then
								if DEBUG_MODE then print("[DEBUG][Resource] Target #" .. idx .. " already gone") end
								continue
							end

							local fullName = pcall(function() return model:GetFullName() end) and model:GetFullName() or tostring(model)
							statusLabel.Text = "Farming " .. current .. "..."
							if DEBUG_MODE then print("[DEBUG][Resource] Processing target #" .. idx, fullName) end

							-- Teleport to resource
							local pos
							local ok, pivot = pcall(function() return model:GetPivot().Position end)
							if ok then pos = pivot
							elseif model.PrimaryPart then pos = model.PrimaryPart.Position
							else
								for _, d in ipairs(model:GetDescendants()) do
									if d:IsA("BasePart") then pos = d.Position break end
								end
							end
							if pos then tpTo(char, pos) end

							-- First click
							pcall(function() fireclickdetector(res.Click) end)
							task.wait(0.3)

							-- Spam remote until despawn OR timeout
							local spamStart = tick()
							while model and model.Parent and Farmer.Running and Farmer.Mode == current do
								if res.Remote then
									if res.Remote.ClassName == "RemoteEvent" then
										pcall(function() res.Remote:FireServer(unpack(resourceArgs)) end)
									elseif res.Remote.ClassName == "RemoteFunction" then
										pcall(function() res.Remote:InvokeServer(unpack(resourceArgs)) end)
									end
								end

								task.wait(math.random(4,10)/10)
								if tick() - spamStart > 8 then
									if DEBUG_MODE then print("[DEBUG][Resource] Timeout, forcing next target") end
									break
								end
							end

							if DEBUG_MODE then print("[DEBUG][Resource] Finished target:", fullName) end
							-- force rescan after each
							break
						end
					end
					task.wait(0.5) -- small pause before rescanning
				end
			end
		else
			statusLabel.Text = "Status: Idle"
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
