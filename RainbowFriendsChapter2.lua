local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local teleportPosition = Vector3.new(53, 138, -8)
local lookyTeleportPosition = Vector3.new(1260, -171, 526)
local stopLoop = false

-- 🛑 Stop if space is pressed
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.Space and not processed then
		stopLoop = true
		print("🛑 Script stopped by SPACEBAR")
	end
end)

-- 🚪 Toggle noclip
local function setNoclip(enabled)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = not enabled
		end
	end
end

-- 🔍 Check if any models named modelName exist inside container (recursive)
local function anyModelsExist(container, modelName)
	for _, obj in ipairs(container:GetChildren()) do
		if obj:IsA("Model") and obj.Name == modelName then
			return true
		elseif obj:IsA("Folder") or obj:IsA("Model") then
			if anyModelsExist(obj, modelName) then
				return true
			end
		end
	end
	return false
end

-- 🔁 Generic collector (LightBulb, GasCanister, CakeMix)
local function collectModels(modelName)
	local perTripLimit = 9

	while not stopLoop and anyModelsExist(workspace, modelName) do
		local collectedThisTrip = 0

		for _, obj in ipairs(workspace:GetChildren()) do
			if stopLoop or collectedThisTrip >= perTripLimit then break end

			if obj:IsA("Model") and obj.Name == modelName then
				local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
				if part then
					setNoclip(true)
					humanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)
					collectedThisTrip += 1
					task.wait(0.1)
				end
			end
		end

		setNoclip(false)

		if collectedThisTrip == 0 then
			print("⚠️ No more", modelName, "found this batch.")
			break
		end

		-- Teleport back to collection point
		humanoidRootPart.CFrame = CFrame.new(teleportPosition)
		task.wait(1)
	end

	if stopLoop then
		print("🛑 Stopped during", modelName, "collection.")
	else
		print("✅ Done collecting all", modelName)
	end
end

-- 🔁 Looky collector under workspace.ignore
local function collectLookysFromIgnore()
	local ignore = workspace:WaitForChild("ignore")

	while not stopLoop and anyModelsExist(ignore, "Looky") do
		local lookyModels = {}

		local function gatherLookys(container)
			for _, obj in ipairs(container:GetChildren()) do
				if obj:IsA("Model") and obj.Name == "Looky" then
					table.insert(lookyModels, obj)
				elseif obj:IsA("Folder") or obj:IsA("Model") then
					gatherLookys(obj)
				end
			end
		end
		gatherLookys(ignore)

		for _, looky in ipairs(lookyModels) do
			if stopLoop then break end

			local part = looky.PrimaryPart or looky:FindFirstChildWhichIsA("BasePart")
			if part then
				setNoclip(true)
				humanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)
				task.wait(0.1)
				setNoclip(false)

				-- Teleport back to collection point after each Looky
				humanoidRootPart.CFrame = CFrame.new(teleportPosition)
				task.wait(1)
			end
		end
	end

	-- After Looky done, teleport in loop to given pos until stopped
	while not stopLoop do
		humanoidRootPart.CFrame = CFrame.new(lookyTeleportPosition)
		task.wait(0.1)
	end

	if stopLoop then
		print("🛑 Looky collection stopped early.")
	else
		print("✅ All Lookys collected.")
	end
end

-- 🧠 Detect current active phase
local function detectCurrentPhase()
	if anyModelsExist(workspace, "LightBulb") then
		return "LightBulb"
	elseif anyModelsExist(workspace, "GasCanister") then
		return "GasCanister"
	elseif anyModelsExist(workspace:WaitForChild("ignore"), "Looky") then
		return "Looky"
	elseif anyModelsExist(workspace, "CakeMix") then
		return "CakeMix"
	end
	return nil
end

-- 🧩 Main logic
task.spawn(function()
	setNoclip(true)

	local phase = detectCurrentPhase()
	if not phase then
		print("❌ No phase detected.")
		return
	end

	print("📌 Detected phase:", phase)

	if phase == "LightBulb" then
		collectModels("LightBulb")
		if stopLoop then return end

		collectModels("GasCanister")
		if stopLoop then return end

		collectLookysFromIgnore()
		if stopLoop then return end

		collectModels("CakeMix")

	elseif phase == "GasCanister" then
		collectModels("GasCanister")
		if stopLoop then return end

		collectLookysFromIgnore()
		if stopLoop then return end

		collectModels("CakeMix")

	elseif phase == "Looky" then
		collectLookysFromIgnore()
		if stopLoop then return end

		collectModels("CakeMix")

	elseif phase == "CakeMix" then
		collectModels("CakeMix")
	end

	print("🎉 ✅ All collection phases completed.")
end)
