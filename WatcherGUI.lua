-- DEEP FINDER: searches for UI, prompts, clicks, and script source lines with keywords
local keywords = {"Ride","Pet","Unequip","Mount","Dismount","Interact"}
local function containsKeyword(s)
    if not s then return false end
    s = tostring(s)
    for _,k in ipairs(keywords) do
        if string.find(s, k) then return true end
    end
    return false
end

local function try(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    return ok, a, b, c
end

local function inspectConnections(inst)
    local events = {"MouseButton1Click","Activated","Triggered","InputBegan","Touched","Changed"}
    for _, evname in ipairs(events) do
        local ev = inst[evname]
        if ev then
            local ok, conns = pcall(function() return getconnections(ev) end)
            if ok and type(conns)=="table" and #conns>0 then
                print(("  -> %d connections on %s.%s"):format(#conns, inst:GetFullName(), evname))
                for i,conn in ipairs(conns) do
                    -- printing Function may show a pointer or function obj — still useful
                    print(("     [%d] func: %s"):format(i, tostring(conn.Function)))
                end
            end
        end
    end
end

local function checkInstance(inst)
    if not inst then return end
    local cls = inst.ClassName
    local fullname = inst:GetFullName()

    -- name match
    if containsKeyword(inst.Name) then
        print("NAME match:", fullname, cls)
    end

    -- gui text match (safe pcall)
    if inst:IsA("GuiObject") then
        local ok, txt = pcall(function() return inst.Text end)
        if ok and containsKeyword(txt) then
            print("GUI Text match:", fullname, cls, "Text:", txt)
        end
        local ok2, tip = pcall(function() return inst.ToolTip end)
        if ok2 and containsKeyword(tip) then
            print("GUI ToolTip match:", fullname, cls, "ToolTip:", tip)
        end
    end

    -- ProximityPrompt / ClickDetector
    if inst:IsA("ProximityPrompt") then
        print("ProximityPrompt:", fullname, "ActionText=", inst.ActionText, "ObjectParent=", tostring(inst.Parent and inst.Parent:GetFullName()))
        inspectConnections(inst)
    end
    if inst:IsA("ClickDetector") then
        print("ClickDetector:", fullname, "Parent=", tostring(inst.Parent and inst.Parent:GetFullName()))
        inspectConnections(inst)
    end

    -- Seats and parts that might have prompts
    if inst:IsA("Seat") or inst:IsA("VehicleSeat") or inst:IsA("Model") or inst:IsA("BasePart") then
        -- check descendants quickly for prompts
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
                print("  descendant prompt under", fullname, "->", d.ClassName, d.Name, "full:", d:GetFullName())
            end
        end
    end

    -- inspect LocalScript/ModuleScript source (if accessible)
    if inst:IsA("LocalScript") or inst:IsA("ModuleScript") or inst:IsA("Script") then
        local ok, src = pcall(function() return inst.Source end)
        if ok and src and type(src) == "string" and containsKeyword(src) then
            print("SCRIPT source match in:", fullname, "class:", cls)
            -- print a few matching lines
            for line in src:gmatch("[^\r\n]+") do
                for _,k in ipairs(keywords) do
                    if string.find(line, k) then
                        print("   >", line)
                        break
                    end
                end
            end
        end
    end

    -- look for GUI templates parented somewhere else (ReplicatedStorage etc.)
    if containsKeyword(tostring(inst.Name)) and (inst:IsA("Folder") or inst:IsA("ScreenGui") or inst:IsA("BillboardGui") or inst:IsA("Frame")) then
        print("POTENTIAL template:", fullname, cls)
    end

    -- inspect connections on GUI objects too
    if inst:IsA("GuiObject") then
        inspectConnections(inst)
    end
end

-- scan current descendants
for _, inst in ipairs(game:GetDescendants()) do
    pcall(checkInstance, inst)
end

-- set watchers on likely roots so we catch runtime creations
local roots = {
    workspace,
    game:GetService("ReplicatedStorage"),
    game:GetService("ReplicatedFirst"),
    game:GetService("StarterGui"),
    game:GetService("StarterPlayer"),
    game:GetService("Players"),
    -- CoreGui may be accessible in exploit environment:
    (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) or nil
}
-- add local player's PlayerGui/PlayerScripts if available
local player = game.Players.LocalPlayer
if player then
    roots[#roots+1] = player:FindFirstChild("PlayerGui")
    roots[#roots+1] = player:FindFirstChild("PlayerScripts")
end

for _, root in ipairs(roots) do
    if root and root:IsA("Instance") then
        root.DescendantAdded:Connect(function(inst)
            pcall(function()
                print("DescendantAdded:", inst:GetFullName())
                checkInstance(inst)
            end)
        end)
    end
end

print("Deep finder started. Watch output while you open the horse UI / press E / approach the horse.")
