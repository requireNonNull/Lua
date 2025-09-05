-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Player references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Game objects
local itemsFolder = workspace:WaitForChild("Items")
local items = itemsFolder:GetChildren()
local rebirthEvent = ReplicatedStorage:WaitForChild("ResetFolder"):WaitForChild("RebirthEvent")

-- Variables
local teleportCount = 0
local startTime = tick()
local loopRunning = false
local currentIndex = 1

-- Helper function to create rounded corners on UI objects
local function addUICorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = parent
    return corner
end

-- Helper function to create hover effect on buttons
local function createHoverEffect(button)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.25), {BackgroundTransparency = 0.2}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
    end)
end

-- Create ScreenGui container
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportControlGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main Frame container
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 220)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0
mainFrame.Parent = screenGui
addUICorner(mainFrame, 12)

-- Toggle Button (Start/Stop loop)
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 280, 0, 40)
toggleButton.Position = UDim2.new(0, 20, 0, 20)
toggleButton.Text = "Start Loop"
toggleButton.Font = Enum.Font.GothamSemibold
toggleButton.TextSize = 18
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
toggleButton.AutoButtonColor = false
toggleButton.Parent = mainFrame
addUICorner(toggleButton, 12)

-- Gradient for toggle button
local toggleGradient = Instance.new("UIGradient", toggleButton)
toggleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 90, 170))
}
toggleGradient.Rotation = 45

-- Text Stroke for better text visibility
local toggleTextStroke = Instance.new("TextStroke")
toggleTextStroke.Transparency = 0
toggleTextStroke.Color = Color3.fromRGB(0, 0, 0)
toggleTextStroke.Parent = toggleButton

-- Toggle Button Stroke (Outline)
local toggleStroke = Instance.new("UIStroke", toggleButton)
toggleStroke.Thickness = 2
toggleStroke.Color = Color3.fromRGB(255, 255, 255)

-- Terminate Button (Stop & Remove UI)
local terminateButton = Instance.new("TextButton")
terminateButton.Size = UDim2.new(0, 280, 0, 40)
terminateButton.Position = UDim2.new(0, 20, 0, 70)
terminateButton.Text = "Terminate Script"
terminateButton.Font = Enum.Font.GothamSemibold
terminateButton.TextSize = 18
terminateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
terminateButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
terminateButton.AutoButtonColor = false
terminateButton.Parent = mainFrame
addUICorner(terminateButton, 12)

-- Gradient for terminate button
local terminateGradient = Instance.new("UIGradient", terminateButton)
terminateGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 0, 0))
}
terminateGradient.Rotation = 45

-- Text Stroke for terminate button
local terminateTextStroke = Instance.new("TextStroke")
terminateTextStroke.Transparency = 0
terminateTextStroke.Color = Color3.fromRGB(0, 0, 0)
terminateTextStroke.Parent = terminateButton

-- Terminate Button Stroke (Outline)
local terminateStroke = Instance.new("UIStroke", terminateButton)
terminateStroke.Thickness = 2
terminateStroke.Color = Color3.fromRGB(255, 255, 255)

-- Info Label for status updates
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0, 280, 0, 80)
infoLabel.Position = UDim2.new(0, 20, 0, 130)
infoLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
infoLabel.BackgroundTransparency = 0.2
infoLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
infoLabel.TextWrapped = true
infoLabel.Font = Enum.Font.GothamSemibold
infoLabel.TextSize = 16
infoLabel.Text = ""
infoLabel.Parent = mainFrame
addUICorner(infoLabel, 10)

-- Show a small notification for rebirth event
local function showRebirthNotification()
    local notifLabel = Instance.new("TextLabel")
    notifLabel.Size = UDim2.new(0, 220, 0, 40)
    notifLabel.Position = UDim2.new(0.5, -110, 0, 10)
    notifLabel.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    notifLabel.BackgroundTransparency = 0.15
    notifLabel.TextColor3 = Color3.new(1, 1, 1)
    notifLabel.Font = Enum.Font.GothamSemibold
    notifLabel.TextSize = 18
    notifLabel.Text = "🎉 Rebirth Triggered!"
    notifLabel.ZIndex = 10
    notifLabel.Parent = screenGui
    addUICorner(notifLabel, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Parent = notifLabel

    -- Tween fade out after 1.5 seconds
    task.delay(1.5, function()
        local tween = TweenService:Create(notifLabel, TweenInfo.new(0.5), {
            TextTransparency = 1,
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Wait()
        notifLabel:Destroy()
    end)
end

-- Update Info Label continuously with loop status and stats
task.spawn(function()
    while screenGui.Parent do
        local elapsed = math.floor(tick() - startTime)
        local minutes = math.floor(elapsed / 60)
        local seconds = elapsed % 60

        local serverId = game.JobId ~= "" and game.JobId or "Local Server"
        local status = loopRunning and "🟢 RUNNING" or "🔴 STOPPED"

        infoLabel.Text = string.format(
            "Loop: %s\nTeleports: %d\nTime Played: %02d:%02d\nServer ID:\n%s",
            status,
            teleportCount,
            minutes,
            seconds,
            serverId
        )
        task.wait(1)
    end
end)

-- Main teleport loop (runs only when loopRunning is true)
task.spawn(function()
    while screenGui.Parent do
        if loopRunning then
            if currentIndex > #items then
                currentIndex = 1
            end

            local model = items[currentIndex]
            if model:IsA("Model") then
                local targetPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                if targetPart then
                    humanoidRootPart.CFrame = targetPart.CFrame
                    teleportCount += 1

                    -- Trigger rebirth every 120 teleports
                    if teleportCount % 120 == 0 then
                        rebirthEvent:FireServer()
                        showRebirthNotification()
                    end
                end
            end

            currentIndex += 1
        end
        task.wait(0.1)
    end
end)

-- Toggle button click handler (start/stop loop)
toggleButton.MouseButton1Click:Connect(function()
    loopRunning = not loopRunning
    toggleButton.Text = loopRunning and "Stop Loop" or "Start Loop"
end)

-- Terminate button click handler (destroy UI and stop loop)
terminateButton.MouseButton1Click:Connect(function()
    loopRunning = false
    screenGui:Destroy()
end)

-- Apply hover effects to buttons
createHoverEffect(toggleButton)
createHoverEffect(terminateButton)
