-- Modern UI for HorseLife - Visual redesign (fixed gradient border, button outlines, minimize behavior)
-- Version: v1.4 -> updated

local VERSION = "v1.5"
local COLORS = {
    Background = Color3.fromRGB(24, 24, 24),
    Panel = Color3.fromRGB(40, 40, 40),
    Accent = Color3.fromRGB(0, 170, 255),
    TextPrimary = Color3.fromRGB(230, 230, 230),
    TextSecondary = Color3.fromRGB(180, 180, 180),
    ToggleOn = Color3.fromRGB(0, 170, 255), -- Blue toggle color
    ToggleOff = Color3.fromRGB(100, 100, 100),
}

local GRADIENT_COLORS = {
    Start = Color3.fromRGB(0, 0, 255),  -- Blue
    End = Color3.fromRGB(0, 255, 255),  -- Cyan
}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- parent to PlayerGui if possible (safer); fallback to CoreGui for environments that need it
local guiParent = (player and player:FindFirstChild("PlayerGui")) or game:GetService("CoreGui")

-- cleanup previous GUI
local existing = guiParent:FindFirstChild("HorseLifeUI")
if existing then
    existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HorseLifeUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = guiParent
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Layout constants
local WINDOW_WIDTH = 300
local WINDOW_HEIGHT = 460
local BORDER_THICKNESS = 2
local TITLE_HEIGHT = 36
local TAB_HEIGHT = 30

-- Create the gradient outline (outer frame) and inner main panel
local outline = Instance.new("Frame")
outline.Name = "Outline"
outline.Size = UDim2.new(0, WINDOW_WIDTH + BORDER_THICKNESS * 2, 0, WINDOW_HEIGHT + BORDER_THICKNESS * 2)
outline.Position = UDim2.new(0, 60, 0, 100)
outline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)  -- gradient will cover it
outline.BorderSizePixel = 0
outline.Parent = screenGui
local outlineCorner = Instance.new("UICorner", outline)
outlineCorner.CornerRadius = UDim.new(0, 14)

local outlineGradient = Instance.new("UIGradient", outline)
outlineGradient.Color = ColorSequence.new(GRADIENT_COLORS.Start, GRADIENT_COLORS.End)
outlineGradient.Rotation = 0

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(1, -BORDER_THICKNESS * 2, 1, -BORDER_THICKNESS * 2)
mainFrame.Position = UDim2.new(0, BORDER_THICKNESS, 0, BORDER_THICKNESS)
mainFrame.BackgroundColor3 = COLORS.Panel
mainFrame.BorderSizePixel = 0
mainFrame.Parent = outline
local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 12)

-- Title Bar
local titleBar = Instance.new("Frame", mainFrame)
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, TITLE_HEIGHT)
titleBar.BackgroundColor3 = COLORS.Background
titleBar.BorderSizePixel = 0
titleBar.Position = UDim2.new(0, 0, 0, 0)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -76, 1, 0) -- leave room for buttons
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.Text = "🦄 Farmy " .. VERSION
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextColor3 = COLORS.TextPrimary
titleLabel.TextSize = 20
titleLabel.BackgroundTransparency = 1
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextYAlignment = Enum.TextYAlignment.Center

-- Status string (used when minimized)
local statusMessage = "Status: Idle"

-- Close button (image) - using the id you had previously
local closeBtn = Instance.new("ImageButton", titleBar)
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0.5, -12)
closeBtn.Image = "rbxassetid://6035047409" -- close icon
closeBtn.BackgroundTransparency = 1
closeBtn.Name = "CloseBtn"

-- Minimize: use a text glyph (reliable) instead of an external image id that can disappear
local minimizeBtn = Instance.new("TextButton", titleBar)
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
minimizeBtn.Position = UDim2.new(1, -60, 0.5, -12)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Text = "—" -- stable glyph
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 22
minimizeBtn.TextColor3 = COLORS.TextSecondary

-- Content area: tabs & content container
local tabButtonsFrame = Instance.new("Frame", mainFrame)
tabButtonsFrame.Name = "TabButtons"
tabButtonsFrame.Size = UDim2.new(1, 0, 0, TAB_HEIGHT)
tabButtonsFrame.Position = UDim2.new(0, 0, 0, TITLE_HEIGHT)
tabButtonsFrame.BackgroundTransparency = 1

local contentHolder = Instance.new("Frame", mainFrame)
contentHolder.Name = "ContentHolder"
contentHolder.Size = UDim2.new(1, -20, 1, -(TITLE_HEIGHT + TAB_HEIGHT) - 16)
contentHolder.Position = UDim2.new(0, 10, 0, TITLE_HEIGHT + TAB_HEIGHT + 6)
contentHolder.BackgroundTransparency = 1

-- Tab frames container
local tabNames = { "Main", "Settings", "Changelog" }
local tabFrames = {}

local function switchTab(tabName)
    for name, frame in pairs(tabFrames) do
        frame.Visible = (name == tabName)
    end
end

-- Helper: create a small gradient-outline button (outline frame with inner TextButton)
local function createGradientButton(parent, size, pos, innerText, innerFont, textSize, innerBg, innerTextColor)
    local out = Instance.new("Frame")
    out.Size = size
    out.Position = pos
    out.BackgroundTransparency = 0
    out.BorderSizePixel = 0
    out.Parent = parent
    local outCorner = Instance.new("UICorner", out)
    outCorner.CornerRadius = UDim.new(0, 8)

    local g = Instance.new("UIGradient", out)
    g.Color = ColorSequence.new(GRADIENT_COLORS.Start, GRADIENT_COLORS.End)

    local inner = Instance.new("TextButton")
    inner.Size = UDim2.new(1, -6, 1, -6)
    inner.Position = UDim2.new(0, 3, 0, 3)
    inner.BackgroundColor3 = innerBg or COLORS.Background
    inner.BorderSizePixel = 0
    inner.Text = innerText or ""
    inner.Font = innerFont or Enum.Font.Gotham
    inner.TextSize = textSize or 16
    inner.TextColor3 = innerTextColor or COLORS.TextPrimary
    inner.Parent = out
    inner.AutoButtonColor = true
    local innerCorner = Instance.new("UICorner", inner)
    innerCorner.CornerRadius = UDim.new(0, 6)

    return out, inner
end

-- Create tab buttons (uses small gradient outline)
for i, name in ipairs(tabNames) do
    local xPos = UDim2.new(0, (i - 1) * 100, 0, 0)
    local out, btn = createGradientButton(tabButtonsFrame, UDim2.new(0, 100, 1, 0), xPos, name, Enum.Font.Gotham, 16, COLORS.Background, COLORS.TextSecondary)
    btn.Parent = out
    btn.MouseEnter:Connect(function()
        btn.TextColor3 = COLORS.Accent
    end)
    btn.MouseLeave:Connect(function()
        btn.TextColor3 = COLORS.TextSecondary
    end)
    btn.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
end

-- Create the content frames (one per tab) inside contentHolder
for _, name in ipairs(tabNames) do
    local frame = Instance.new("Frame", contentHolder)
    frame.Name = name .. "Tab"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = (name == "Main")
    tabFrames[name] = frame
end

-- MAIN TAB
local mainTab = tabFrames["Main"]

-- Start button using gradient-border helper
local startOut, startBtn = createGradientButton(mainTab, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0), "▶️ Start Farming", Enum.Font.GothamBold, 18, COLORS.Accent, COLORS.TextPrimary)
startOut.Parent = mainTab
startBtn.MouseEnter:Connect(function()
    startBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
end)
startBtn.MouseLeave:Connect(function()
    startBtn.BackgroundColor3 = COLORS.Accent
end)
startBtn.MouseButton1Click:Connect(function()
    if startBtn.Text:find("Start") then
        startBtn.Text = "⏹ Stop Farming"
    else
        startBtn.Text = "▶️ Start Farming"
    end
end)

-- SETTINGS TAB
local settingsTab = tabFrames["Settings"]
local safeLabel = Instance.new("TextLabel", settingsTab)
safeLabel.Size = UDim2.new(0, 200, 0, 24)
safeLabel.Position = UDim2.new(0, 0, 0, 0)
safeLabel.Text = "Safe Mode"
safeLabel.Font = Enum.Font.GothamBold
safeLabel.TextSize = 18
safeLabel.TextColor3 = COLORS.TextPrimary
safeLabel.BackgroundTransparency = 1
safeLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Toggle (kept as frame + knob). Works on mouse click.
local toggle = Instance.new("Frame", settingsTab)
toggle.Size = UDim2.new(0, 50, 0, 24)
toggle.Position = UDim2.new(0, 200, 0, 0)
toggle.BackgroundColor3 = COLORS.ToggleOff
toggle.BorderSizePixel = 0
local toggleCorner = Instance.new("UICorner", toggle)
toggleCorner.CornerRadius = UDim.new(0, 12)

local knob = Instance.new("Frame", toggle)
knob.Size = UDim2.new(0, 20, 0, 20)
knob.Position = UDim2.new(0, 2, 0, 2)
knob.BackgroundColor3 = COLORS.Panel
knob.BorderSizePixel = 0
local knobCorner = Instance.new("UICorner", knob)
knobCorner.CornerRadius = UDim.new(1, 0)

toggle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if toggle.BackgroundColor3 == COLORS.ToggleOff then
            toggle.BackgroundColor3 = COLORS.ToggleOn
            knob:TweenPosition(UDim2.new(1, -22, 0, 2), "Out", "Quad", 0.18, true)
        else
            toggle.BackgroundColor3 = COLORS.ToggleOff
            knob:TweenPosition(UDim2.new(0, 2, 0, 2), "Out", "Quad", 0.18, true)
        end
    end
end)

-- CHANGELOG TAB
local changelogTab = tabFrames["Changelog"]
local changelogLabel = Instance.new("TextLabel", changelogTab)
changelogLabel.Size = UDim2.new(1, -20, 1, -20)
changelogLabel.Position = UDim2.new(0, 10, 0, 10)
changelogLabel.Text = "📋 Changelog\n\n- Initial Release\n- Redesigned UI\n- Added tab system\n- Toggle switches for settings\n- Clean UI layout\n\nFuture updates: Bug fixes, new farming features."
changelogLabel.Font = Enum.Font.Gotham
changelogLabel.TextSize = 16
changelogLabel.TextColor3 = COLORS.TextSecondary
changelogLabel.BackgroundTransparency = 1
changelogLabel.TextYAlignment = Enum.TextYAlignment.Top
changelogLabel.TextWrapped = true

changelogLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
    if changelogLabel.TextBounds.Y > changelogLabel.Size.Y.Offset then
        changelogLabel.TextSize = math.max(14, changelogLabel.TextSize - 2)
    end
end)

-- Dragging support (drag the whole outline window)
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = outline.Position

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
    if dragging and input == dragInput and dragStart and startPos then
        local delta = input.Position - dragStart
        outline.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Close functionality
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Minimize / restore behavior
local minimized = false
local originalOutlineSize = outline.Size
local originalMainSize = mainFrame.Size
local function setMinimized(min)
    minimized = min
    if min then
        -- shrink the outline and inner main so only title bar shows
        outline.Size = UDim2.new(0, WINDOW_WIDTH + BORDER_THICKNESS * 2, 0, TITLE_HEIGHT + BORDER_THICKNESS * 2)
        mainFrame.Size = UDim2.new(1, -BORDER_THICKNESS * 2, 0, TITLE_HEIGHT)
        -- hide tabs & content fully
        tabButtonsFrame.Visible = false
        contentHolder.Visible = false
        for _, f in pairs(tabFrames) do f.Visible = false end
        -- replace title text with status for later use
        titleLabel.Text = statusMessage
    else
        -- restore sizes & visibility
        outline.Size = originalOutlineSize
        mainFrame.Size = originalMainSize
        tabButtonsFrame.Visible = true
        contentHolder.Visible = true
        switchTab("Main")
        titleLabel.Text = "🦄 Farmy " .. VERSION
    end
end

minimizeBtn.MouseButton1Click:Connect(function()
    setMinimized(not minimized)
end)

-- Make sure initial tab is visible
switchTab("Main")

-- Optional: expose a small API on the screenGui for changing statusMessage externally
screenGui:SetAttribute("StatusMessage", statusMessage)
function screenGui:SetStatus(msg)
    statusMessage = tostring(msg or "")
    screenGui:SetAttribute("StatusMessage", statusMessage)
    if minimized then
        titleLabel.Text = statusMessage
    end
end

-- End of script
