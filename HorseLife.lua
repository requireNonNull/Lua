-- Diagnostic: test which payload the server accepts for GetCurrencyNodeRemote
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local hrp = (player.Character and player.Character:FindFirstChild("HumanoidRootPart"))

local ok, remote = pcall(function()
	return ReplicatedStorage:WaitForChild("Remotes",5):WaitForChild("GetCurrencyNodeRemote",5)
end)
if not ok or not remote then
	warn("Couldn't find Remotes/GetCurrencyNodeRemote in ReplicatedStorage.")
	return
end
print("Diagnostic: found remote, class:", remote.ClassName)

local function waitForGone(inst, timeout)
	local t = 0
	while inst and inst.Parent and t < timeout do
		task.wait(0.2)
		t = t + 0.2
	end
	return not (inst and inst.Parent)
end

local function safeFire(...) 
	-- wrap calls to avoid runtime errors
	local ok, err = pcall(function(...) 
		if remote and remote.FireServer then
			remote:FireServer(...)
		end
	end, ...)
	return ok, err
end

local function safeInvoke(...)
	local ok, res = pcall(function(...) 
		if remote and remote.InvokeServer then
			return remote:InvokeServer(...)
		end
	end, ...)
	return ok, res
end

-- get spawned coins
local function getSpawnedCoins()
	local coins = {}
	local ok, spawned = pcall(function()
		return workspace:WaitForChild("Interactions",3):WaitForChild("CurrencyNodes",3):WaitForChild("Spawned",3)
	end)
	if not ok or not spawned then
		warn("Spawned folder not found under Interactions.CurrencyNodes")
		return coins
	end
	for _, v in ipairs(spawned:GetChildren()) do
		if v and (v:IsA("BasePart") or v:IsA("MeshPart")) and v.Name == "Coins" then
			table.insert(coins, v)
		end
	end
	return coins
end

local coins = getSpawnedCoins()
if #coins == 0 then
	warn("No coins found in Spawned. Aborting.")
	return
end

print("Found", #coins, "spawned coins. Starting diagnostic. Output will appear below.")

local function tryAllPayloadsForCoin(coin)
	if not coin or not coin.Parent then
		return false, "coin missing"
	end
	local timeout = 3
	local methods = {}

	-- method 1: FireServer(coin)
	table.insert(methods, {name="FireServer(coin)", fn=function() return safeFire(coin) end})

	-- method 2: InvokeServer(coin) (if RemoteFunction)
	table.insert(methods, {name="InvokeServer(coin)", fn=function() return safeInvoke(coin) end})

	-- method 3: FireServer(coin:GetFullName())
	table.insert(methods, {name="FireServer(fullname)", fn=function() return safeFire(coin:GetFullName()) end})

	-- method 4: FireServer(coin.Name)
	table.insert(methods, {name="FireServer(name)", fn=function() return safeFire(coin.Name) end})

	-- method 5: FireServer(coin.Position)
	table.insert(methods, {name="FireServer(position)", fn=function() return safeFire(coin.Position) end})

	-- method 6: FireServer(root Coins) if exists at CurrencyNodes.Coins
	local rootCoins
	pcall(function()
		rootCoins = workspace:WaitForChild("Interactions"):WaitForChild("CurrencyNodes"):FindFirstChild("Coins")
	end)
	if rootCoins then
		table.insert(methods, {name="FireServer(rootCoins)", fn=function() return safeFire(rootCoins) end})
	end

	-- run methods without teleport first
	for i, m in ipairs(methods) do
		if not coin.Parent then break end
		print(("Trying %s on coin %s ..."):format(m.name, coin:GetDebugId and coin:GetDebugId() or coin:GetFullName()))
		m.fn()
		local success = waitForGone(coin, timeout)
		if success then
			return true, ("succeeded with %s (no teleport)"):format(m.name)
		end
		-- small gap between attempts
		task.wait(0.25)
	end

	-- if nothing worked, try teleport near coin and repeat once
	local oldCFrame
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		oldCFrame = hrp.CFrame
		local safePos = CFrame.new(coin.Position + Vector3.new(0,3,0))
		pcall(function() hrp.CFrame = safePos end)
		task.wait(0.15)
		for i, m in ipairs(methods) do
			if not coin.Parent then break end
			print(("Trying (after teleport) %s on coin %s ..."):format(m.name, coin:GetDebugId and coin:GetDebugId() or coin:GetFullName()))
			m.fn()
			local success = waitForGone(coin, timeout)
			if success then
				return true, ("succeeded with %s (after teleport)"):format(m.name)
			end
			task.wait(0.25)
		end
		-- don't restore if user wants to stay teleported; restore anyway
		if oldCFrame then
			pcall(function() hrp.CFrame = oldCFrame end)
		end
	end

	return false, "no payload worked"
end

-- iterate through coins and test
for idx, coin in ipairs(coins) do
	if not coin.Parent then
		print(("Coin [%d] already gone, skipping"):format(idx))
	else
		print(("--- Testing coin %d/%d: %s"):format(idx, #coins, coin:GetDebugId and coin:GetDebugId() or coin:GetFullName()))
		local ok, info = tryAllPayloadsForCoin(coin)
		if ok then
			print(("Coin %d result: SUCCESS - %s"):format(idx, info))
		else
			print(("Coin %d result: FAILURE - %s"):format(idx, info))
		end
		-- small wait between coins
		task.wait(0.35)
	end
end

print("Diagnostic complete.")
