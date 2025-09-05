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
local rebirthCount = 0
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

-- ===== SPLASH SCREEN =====
local splashFrame = Instance.new("Frame")
splashFrame.Size = UDim2.new(0, 300, 0, 150)
splashFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
splashFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
splashFrame.BackgroundTransparency = 1 -- start invisible
splashFrame.Parent = screenGui
addUICorner(splashFrame, 15)

local splashText = Instance.new("TextLabel")
splashText.Size = UDim2.new(1, 0, 1, 0)
splashText.BackgroundTransparency = 1
splashText.Text = "Breezingfreeze"
splashText.Font = Enum.Font.GothamBold
splashText.TextSize = 36
splashText.TextColor3 = Color3.fromRGB(0, 170, 255)
splashText.TextStrokeTransparency = 0
splashText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
splashText.Parent = splashFrame

-- Fade in splash
local fadeInTween = TweenService:Create(splashFrame, TweenInfo.new(1), {BackgroundTransparency = 0})
fadeInTween:Play()
fadeInTween.Completed:Wait()

-- Wait visible for 2 seconds
task.wait(2)

-- Fade out splash
local fadeOutTween = TweenService:Create(splashFrame, TweenInfo.new(1), {BackgroundTransparency = 1})
fadeOutTween:Play()
fadeOutTween.Completed:Wait()

-- Remove splash
splashFrame:Destroy()

-- ===== MAIN UI =====

-- Main Frame container
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 360, 0, 270)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0
mainFrame.Parent = screenGui
addUICorner(mainFrame, 12)

-- TAB BUTTONS CONTAINER
local tabButtonsFrame = Instance.new("Frame")
tabButtonsFrame.Size = UDim2.new(1, 0, 0, 40)
tabButtonsFrame.Position = UDim2.new(0, 0, 0, 0)
tabButtonsFrame.BackgroundTransparency = 1
tabButtonsFrame.Parent = mainFrame

-- Helper to create tabs buttons
local function createTabButton(text, positionX)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 1, 0)
    btn.Position = UDim2.new(0, positionX, 0, 0)
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 18
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.AutoButtonColor = false
    btn.Parent = tabButtonsFrame
    addUICorner(btn, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.8
    stroke.Color = Color3.fromRGB(70, 70, 70)
    stroke.Parent = btn

    createHoverEffect(btn)

    return btn, stroke
end

-- Create two tab buttons
local mainTabButton, mainTabStroke = createTabButton("Main", 0)
local infoTabButton, infoTabStroke = createTabButton("Info", 180)

-- CONTENT FRAMES
local mainTabFrame = Instance.new("Frame")
mainTabFrame.Size = UDim2.new(1, 0, 1, -40)
mainTabFrame.Position = UDim2.new(0, 0, 0, 40)
mainTabFrame.BackgroundTransparency = 1
mainTabFrame.Parent = mainFrame

local infoTabFrame = Instance.new("Frame")
infoTabFrame.Size = UDim2.new(1, 0, 1, -40)
infoTabFrame.Position = UDim2.new(0, 0, 0, 40)
infoTabFrame.BackgroundTransparency = 1
infoTabFrame.Visible = false -- start hidden
infoTabFrame.Parent = mainFrame

-- ===== MAIN TAB CONTENT =====

-- Toggle Button (Start/Stop loop)
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 320, 0, 45)
toggleButton.Position = UDim2.new(0, 20, 0, 20)
toggleButton.Text = "Start Loop"
toggleButton.Font = Enum.Font.GothamSemibold
toggleButton.TextSize = 20
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
toggleButton.AutoButtonColor = false
toggleButton.Parent = mainTabFrame
addUICorner(toggleButton, 15)

local toggleGradient = Instance.new("UIGradient", toggleButton)
toggleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 90, 170))
}
toggleGradient.Rotation = 45

toggleButton.TextStrokeTransparency = 0
toggleButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

local toggleStroke = Instance.new("UIStroke", toggleButton)
toggleStroke.Thickness = 2
toggleStroke.Color = Color3.fromRGB(255, 255, 255)

-- Terminate Button (Stop & Remove UI)
local terminateButton = Instance.new("TextButton")
terminateButton.Size = UDim2.new(0, 320, 0, 45)
terminateButton.Position = UDim2.new(0, 20, 0, 80)
terminateButton.Text = "Terminate Script"
terminateButton.Font = Enum.Font.GothamSemibold
terminateButton.TextSize = 20
terminateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
terminateButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
terminateButton.AutoButtonColor = false
terminateButton.Parent = mainTabFrame
addUICorner(terminateButton, 15)

local terminateGradient = Instance.new("UIGradient", terminateButton)
terminateGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 0, 0))
}
terminateGradient.Rotation = 45

terminateButton.TextStrokeTransparency = 0
terminateButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

local terminateStroke = Instance.new("UIStroke", terminateButton)
terminateStroke.Thickness = 2
terminateStroke.Color = Color3.fromRGB(255, 255, 255)

-- ===== INFO TAB CONTENT =====

local infoContainer = Instance.new("ScrollingFrame")
infoContainer.Size = UDim2.new(1, -40, 1, -60)
infoContainer.Position = UDim2.new(0, 20, 0, 20)
infoContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
infoContainer.BackgroundTransparency = 0.2
infoContainer.BorderSizePixel = 0
infoContainer.ScrollBarThickness = 6
infoContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
infoContainer.Parent = infoTabFrame
addUICorner(infoContainer, 12)

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = infoContainer
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 12)

-- Helper function to create labeled info text
local function createInfoLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 18
    lbl.Text = text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = infoContainer
    return lbl
end

-- Welcome header
local welcomeLabel = Instance.new("TextLabel")
welcomeLabel.Size = UDim2.new(1, 0, 0, 40)
welcomeLabel.BackgroundTransparency = 1
welcomeLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
welcomeLabel.Font = Enum.Font.GothamBold
welcomeLabel.TextSize = 24
welcomeLabel.Text = "Welcome to Find The Corgis Hack"
welcomeLabel.TextWrapped = true
welcomeLabel.Parent = infoContainer

local authorLabel = Instance.new("TextLabel")
authorLabel.Size = UDim2.new(1, 0, 0, 30)
authorLabel.BackgroundTransparency = 1
authorLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
authorLabel.Font = Enum.Font.GothamItalic
authorLabel.TextSize = 16
authorLabel.Text = "Script by Breezingfreeze"
authorLabel.Parent = infoContainer

-- Info labels (will be updated)
local statusLabel = createInfoLabel("Status: 🔴 STOPPED")
local teleportsLabel = createInfoLabel("Teleports Done: 0")
local rebirthsLabel = createInfoLabel("Rebirths Fired: 0")
local uptimeLabel = createInfoLabel("Uptime: 00:00:00")
local serverIdLabel = createInfoLabel("Server ID: N/A")

-- Update info labels every second
task.spawn(function()
    while screenGui.Parent do
        local elapsed = tick() - startTime
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = math.floor(elapsed % 60)

        local uptimeStr = string.format("%02d:%02d:%02d", hours, minutes, seconds)
        local statusText = loopRunning and "🟢 RUNNING" or "🔴 STOPPED"
        local serverId = (game.JobId ~= "" and game.JobId) or "N/A"

        -- Update labels
        uptimeLabel.Text = "Uptime: " .. uptimeStr
        statusLabel.Text = "Status: " .. statusText
        teleportsLabel.Text = "Teleports Done: " .. tostring(teleportCount)
        rebirthsLabel.Text = "Rebirths Fired: " .. tostring(rebirthCount)
        serverIdLabel.Text = "Server ID: " .. serverId

        -- Adjust canvas size for scrolling frame
        local contentSize = uiListLayout.AbsoluteContentSize
        infoContainer.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + 20)

        task.wait(1)
    end
end)

-- ===== TAB BUTTON LOGIC =====

local function setActiveTab(tabName)
    if tabName == "Main" then
        mainTabFrame.Visible = true
        infoTabFrame.Visible = false

        mainTabButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
        mainTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        mainTabStroke.Color = Color3.fromRGB(0, 170, 255)

        infoTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        infoTabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        infoTabStroke.Color = Color3.fromRGB(70, 70, 70)

    elseif tabName == "Info" then
        mainTabFrame.Visible = false
        infoTabFrame.Visible = true

        infoTabButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
        infoTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        infoTabStroke.Color = Color3.fromRGB(0, 170, 255)

        mainTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        mainTabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        mainTabStroke.Color = Color3.fromRGB(70, 70, 70)
    end
end

-- Initialize active tab
setActiveTab("Main")

-- Connect tab buttons
mainTabButton.MouseButton1Click:Connect(function()
    setActiveTab("Main")
end)

infoTabButton.MouseButton1Click:Connect(function()
    setActiveTab("Info")
end)

-- ===== TELEPORT & REBIRTH LOOP =====

local function teleportToNextItem()
    if #items == 0 then return end

    local item = items[currentIndex]
    if item and item:IsA("BasePart") then
        humanoidRootPart.CFrame = item.CFrame + Vector3.new(0, 3, 0) -- Teleport slightly above item
        teleportCount = teleportCount + 1
    end

    currentIndex = currentIndex + 1
    if currentIndex > #items then
        currentIndex = 1
    end
end

local function fireRebirth()
    if rebirthEvent then
        rebirthEvent:FireServer()
        rebirthCount = rebirthCount + 1
    end
end

local teleportDelay = 0.2
local rebirthInterval = 20 -- seconds

local rebirthTimer = 0

local loopCoroutine

local function startLoop()
    if loopRunning then return end
    loopRunning = true
    toggleButton.Text = "Stop Loop"
    statusLabel.Text = "Status: 🟢 RUNNING"

    rebirthTimer = 0

    loopCoroutine = task.spawn(function()
        while loopRunning do
            teleportToNextItem()

            rebirthTimer = rebirthTimer + teleportDelay
            if rebirthTimer >= rebirthInterval then
                fireRebirth()
                rebirthTimer = 0
            end

            task.wait(teleportDelay)
        end
    end)
end

local function stopLoop()
    if not loopRunning then return end
    loopRunning = false
    toggleButton.Text = "Start Loop"
    statusLabel.Text = "Status: 🔴 STOPPED"
end

toggleButton.MouseButton1Click:Connect(function()
    if loopRunning then
        stopLoop()
    else
        startLoop()
    end
end)

-- Terminate script: stop loop and remove GUI
terminateButton.MouseButton1Click:Connect(function()
    stopLoop()
    screenGui:Destroy()
end)

