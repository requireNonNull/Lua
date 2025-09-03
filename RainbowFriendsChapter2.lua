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
					humanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)
					collectedThisTrip += 1
					task.wait(0.1)
				end
			end
		end

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
				humanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)
				task.wait(0.1)

				-- Teleport back to collection point after each Looky
				humanoidRootPart.CFrame = CFrame.new(teleportPosition)
				task.wait(1)
			end
		end
	end

	if stopLoop then
		print("🛑 Looky collection stopped early.")
	else
		print("✅ All Lookys collected.")
	end
end

-- ⏳ Wait for a model to appear before starting its phase
local function waitForModelToAppear(container, modelName)
	print("⏳ Waiting for model:", modelName)
	while not stopLoop and not anyModelsExist(container, modelName) do
		task.wait(0.5)
	end
	return not stopLoop
end

-- 🧩 Main logic
task.spawn(function()
	local phaseOrder = {
		{ name = "LightBulb", container = workspace },
		{ name = "GasCanister", container = workspace },
		{ name = "Looky", container = workspace:WaitForChild("ignore") },
		{ name = "CakeMix", container = workspace },
	}

	for _, phase in ipairs(phaseOrder) do
		if stopLoop then break end

		local success = waitForModelToAppear(phase.container, phase.name)
		if not success then break end

		if phase.name == "Looky" then
			collectLookysFromIgnore()
		else
			collectModels(phase.name)
		end
	end

	if not stopLoop then
		print("🎉 ✅ All collection phases completed. Teleporting to Looky position.")
		humanoidRootPart.CFrame = CFrame.new(lookyTeleportPosition)
	else
		print("🛑 Script stopped before completion.")
	end
end)
