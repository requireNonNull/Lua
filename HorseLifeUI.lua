-- Modern UI for HorseLife - by Breezingfreeze (Visual Redesign Only)

-- Constants
local VERSION = "v1.1"
local COLORS = {
    Background = Color3.fromRGB(24, 24, 24),
    Panel = Color3.fromRGB(40, 40, 40),
    Accent = Color3.fromRGB(0, 170, 255),
    TextPrimary = Color3.fromRGB(230, 230, 230),
    TextSecondary = Color3.fromRGB(180, 180, 180),
    ToggleOn = Color3.fromRGB(0, 200, 100),
    ToggleOff = Color3.fromRGB(100, 100, 100),
}

-- Gradient Colors (Adjustable)
local GRADIENT_COLORS = {
    Start = Color3.fromRGB(0, 0, 255),  -- Blue
    End = Color3.fromRGB(0, 255, 255),  -- Cyan
}

-- Create UI
local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "HorseLifeUI"
gui.ResetOnSpawn = false

-- Main frame with rounded corners on all sides
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 460)
mainFrame.Position = UDim2.new(0, 60, 0, 100)
mainFrame.BackgroundColor3 = COLORS.Panel
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui
local uiCorner = Instance.new("UICorner", mainFrame)
uiCorner.CornerRadius = UDim.new(0, 12)

-- Gradient Background for Main Frame
local gradient = Instance.new("UIGradient", mainFrame)
gradient.Color = ColorSequence.new(GRADIENT_COLORS.Start, GRADIENT_COLORS.End)

-- Title Bar with Minimize and Close
local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = COLORS.Background
titleBar.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Text = "🐴 Farmy " .. VERSION
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextColor3 = COLORS.TextPrimary
titleLabel.TextSize = 20
titleLabel.Size = UDim2.new(1, -36, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("ImageButton", titleBar)
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0.5, -12)
closeBtn.Image = "rbxassetid://6035047409" -- Close icon
closeBtn.BackgroundTransparency = 1

local minimizeBtn = Instance.new("ImageButton", titleBar)
minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
minimizeBtn.Position = UDim2.new(1, -60, 0.5, -12)
minimizeBtn.Image = "rbxassetid://6035047074" -- Minimize icon
minimizeBtn.BackgroundTransparency = 1

-- Close button functionality
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Minimize button functionality
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Size = UDim2.new(0, 300, 0, 36)  -- Only show the title bar
        mainFrame.Position = UDim2.new(0, 60, 0, 100)  -- Adjust position if needed
    else
        mainFrame.Size = UDim2.new(0, 300, 0, 460)  -- Restore full UI size
    end
end)

-- Tabs (Main, Settings, Changelog)
local tabNames = { "Main", "Settings", "Changelog" }
local tabFrames = {}

local tabButtonsFrame = Instance.new("Frame", mainFrame)
tabButtonsFrame.Size = UDim2.new(1, 0, 0, 30)
tabButtonsFrame.Position = UDim2.new(0, 0, 0, 36)
tabButtonsFrame.BackgroundTransparency = 1

local function switchTab(tabName)
    for name, frame in pairs(tabFrames) do
        frame.Visible = (name == tabName)
    end
end

for i, name in ipairs(tabNames) do
    local tabBtn = Instance.new("TextButton", tabButtonsFrame)
    tabBtn.Size = UDim2.new(0, 100, 1, 0)
    tabBtn.Position = UDim2.new(0, (i - 1) * 100, 0, 0)
    tabBtn.BackgroundColor3 = COLORS.Background
    tabBtn.Text = name
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.TextSize = 16
    tabBtn.TextColor3 = COLORS.TextSecondary
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

    tabBtn.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
end

-- Content Frames
for _, name in ipairs(tabNames) do
    local frame = Instance.new("Frame", mainFrame)
    frame.Name = name .. "Tab"
    frame.Size = UDim2.new(1, -20, 1, -76)
    frame.Position = UDim2.new(0, 10, 0, 76)
    frame.BackgroundTransparency = 1
    frame.Visible = (name == "Main")
    tabFrames[name] = frame
end

-- Main Tab Content
local mainTab = tabFrames["Main"]

local startBtn = Instance.new("TextButton", mainTab)
startBtn.Size = UDim2.new(1, 0, 0, 40)
startBtn.Position = UDim2.new(0, 0, 0, 0)
startBtn.Text = "▶️ Start Farming"
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 18
startBtn.TextColor3 = Color3.new(1,1,1)
startBtn.BackgroundColor3 = COLORS.Accent
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)

startBtn.MouseButton1Click:Connect(function()
    -- Test button behavior
    startBtn.Text = (startBtn.Text == "▶️ Start Farming") and "⏹ Stop Farming" or "▶️ Start Farming"
end)

-- Settings Tab Content
local settingsTab = tabFrames["Settings"]

-- Safe Mode Toggle
local safeLabel = Instance.new("TextLabel", settingsTab)
safeLabel.Size = UDim2.new(0, 200, 0, 24)
safeLabel.Position = UDim2.new(0, 0, 0, 0)
safeLabel.Text = "Safe Mode"
safeLabel.Font = Enum.Font.GothamBold
safeLabel.TextSize = 18
safeLabel.TextColor3 = COLORS.TextPrimary
safeLabel.BackgroundTransparency = 1
safeLabel.TextXAlignment = Enum.TextXAlignment.Left

local toggle = Instance.new("Frame", settingsTab)
toggle.Size = UDim2.new(0, 50, 0, 24)
toggle.Position = UDim2.new(0, 200, 0, 0)
toggle.BackgroundColor3 = COLORS.ToggleOff
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 12)

local knob = Instance.new("Frame", toggle)
knob.Size = UDim2.new(0, 20, 0, 20)
knob.Position = UDim2.new(0, 2, 0, 2)
knob.BackgroundColor3 = COLORS.Panel
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

toggle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Test toggle behavior
        if toggle.BackgroundColor3 == COLORS.ToggleOff then
            toggle.BackgroundColor3 = COLORS.ToggleOn
            knob:TweenPosition(UDim2.new(1, -22, 0, 2), "Out", "Quad", 0.2, true)
        else
            toggle.BackgroundColor3 = COLORS.ToggleOff
            knob:TweenPosition(UDim2.new(0, 2, 0, 2), "Out", "Quad", 0.2, true)
        end
    end
end)

-- Changelog Tab Content
local changelogTab = tabFrames["Changelog"]

local changelogLabel = Instance.new("TextLabel", changelogTab)
changelogLabel.Size = UDim2.new(1, -20, 1, -20)
changelogLabel.Position = UDim2.new(0, 10, 0, 10)
changelogLabel.Text = "📋 Changelog\n\n- Initial Release\n- Redesigned UI\n- Added tab system\n- Toggle switches for settings\n- Clean UI layout\n\n" ..
                      "Future updates: Bug fixes, new farming features."
changelogLabel.Font = Enum.Font.Gotham
changelogLabel.TextSize = 16
changelogLabel.TextColor3 = COLORS.TextSecondary
changelogLabel.BackgroundTransparency = 1
changelogLabel.TextYAlignment = Enum.TextYAlignment.Top
changelogLabel.TextWrapped = true

-- Auto Resizing Text (e.g. in changelog)
changelogLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
    if changelogLabel.TextBounds.Y > changelogLabel.Size.Y.Offset then
        changelogLabel.TextSize = math.max(14, changelogLabel.TextSize - 2)
    end
end)

-- Dragging Support
local dragging, dragInput, dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
