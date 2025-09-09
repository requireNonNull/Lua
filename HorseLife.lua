-- // AutoFarm Script (Manual Resources)
-- Single-select UI checkboxes with scrollable UI and debug mode

local VERSION = "v2.3"
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


-- Farming Loop (full debug)
task.spawn(function()
	while true do
		if Farmer.Running and Farmer.Mode then
			local char = player.Character or player.CharacterAdded:Wait()

			-- Coins farming
			if Farmer.Mode == "Coins" then
				if DEBUG_MODE then print("[DEBUG][Loop] Farming Coins") end
				for _, coin in ipairs(getCoinParts()) do
					if not Farmer.Running or Farmer.Mode ~= "Coins" then break end
					if coin and coin.Parent then
						statusLabel.Text = "Collecting Coins..."
						if DEBUG_MODE then print("[DEBUG][Coins] TP to coin at", tostring(coin.Position)) end
						tpTo(char, coin.Position)
						repeat 
							task.wait(0.3) 
						until not coin.Parent or not Farmer.Running or Farmer.Mode ~= "Coins"
						if DEBUG_MODE then print("[DEBUG][Coins] Collected one coin") end
					end
				end

			-- XP training
			elseif Farmer.Mode == "XPAgility" or Farmer.Mode == "XPJump" then
				if DEBUG_MODE then print("[DEBUG][Loop] Training", Farmer.Mode) end
				statusLabel.Text = "Training " .. Farmer.Mode .. "..."
				doXP(Farmer.Mode)

			-- Manual resources
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
								if DEBUG_MODE then print("[DEBUG][Resource] Target #" .. idx .. " is gone before farming") end
							else
								local fullName = pcall(function() return model:GetFullName() end) and model:GetFullName() or tostring(model)
								statusLabel.Text = "Farming " .. current .. "..."
								if DEBUG_MODE then print("[DEBUG][Resource] Processing target #" .. idx, fullName) end

								-- Get position safely
								local pos
								local ok, pivot = pcall(function() return model:GetPivot().Position end)
								if ok then
									pos = pivot
								elseif model.PrimaryPart then
									pos = model.PrimaryPart.Position
								else
									for _, d in ipairs(model:GetDescendants()) do
										if d:IsA("BasePart") then
											pos = d.Position
											break
										end
									end
								end
								if pos then
									tpTo(char, pos)
								else
									if DEBUG_MODE then print("[DEBUG][Resource] No valid position found for", fullName) end
								end

								-- First click
								local okClick, clickErr = pcall(function() fireclickdetector(res.Click) end)
								if DEBUG_MODE then 
									print("[DEBUG][Resource] fireclickdetector ok=", tostring(okClick), "err=", tostring(clickErr)) 
								end
								task.wait(0.3)

								-- Keep interacting until destroyed or timeout
								local spamStart = tick()
								local timeout = 8
								local cycles = 0
								while model and model.Parent and Farmer.Running and Farmer.Mode == current do
									if not res.Remote then
										if DEBUG_MODE then print("[DEBUG][Resource] No remote found for", fullName) end
										break
									end

									if res.Remote.ClassName == "RemoteEvent" then
										local okRemote, err = pcall(function() res.Remote:FireServer(unpack(resourceArgs)) end)
										if DEBUG_MODE then print("[DEBUG][Resource] FireServer ok=", tostring(okRemote), "err=", tostring(err)) end
									elseif res.Remote.ClassName == "RemoteFunction" then
										local okRemote, retOrErr = pcall(function() return res.Remote:InvokeServer(unpack(resourceArgs)) end)
										if DEBUG_MODE then print("[DEBUG][Resource] InvokeServer ok=", tostring(okRemote), "ret=", tostring(retOrErr)) end
									else
										if DEBUG_MODE then print("[DEBUG][Resource] Unknown remote type:", res.Remote.ClassName) end
									end

									cycles += 1
									task.wait(math.random(4,10)/10)

									if tick() - spamStart > timeout then
										if DEBUG_MODE then print("[DEBUG][Resource] Timeout farming", fullName, "after", cycles, "cycles") end
										break
									end
								end

								if DEBUG_MODE then
									print(string.format("[DEBUG][Resource] Done %s | alive=%s | cycles=%d", 
										fullName, tostring(model and model.Parent ~= nil), cycles))
								end
							end
						end
					end
					task.wait(0.2) -- pause before re-scan
				end
			end
		else
			if statusLabel.Text ~= "Status: Idle" then
				statusLabel.Text = "Status: Idle"
				if DEBUG_MODE then print("[DEBUG][Loop] Idle") end
			end
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
