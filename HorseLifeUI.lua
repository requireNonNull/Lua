-- 🦄 Farmy by Breezingfreeze
local VERSION = "v1.6"
local DEBUG_MODE = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- ==========================
-- UI Setup
-- ==========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game:GetService("CoreGui")

-- Gradient outline
local outlineFrame = Instance.new("Frame")
outlineFrame.Name = "Outline"
outlineFrame.Position = UDim2.new(0.5, -160, 0.5, -230)
outlineFrame.Size = UDim2.new(0, 320, 0, 460)
outlineFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
outlineFrame.BorderSizePixel = 0
outlineFrame.Parent = screenGui

local outlineCorner = Instance.new("UICorner")
outlineCorner.CornerRadius = UDim.new(0, 16)
outlineCorner.Parent = outlineFrame

local outlineGradient = Instance.new("UIGradient")
outlineGradient.Color = ColorSequence.new(Color3.fromRGB(0, 170, 255), Color3.fromRGB(0, 255, 170))
outlineGradient.Rotation = 45
outlineGradient.Parent = outlineFrame

-- Inner panel (inset by 4px border)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(1, -8, 1, -8)
mainFrame.Position = UDim2.new(0, 4, 0, 4)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = outlineFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "🦄 Farmy " .. VERSION
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Close button
local closeButton = Instance.new("ImageButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -28, 0.5, -10)
closeButton.BackgroundTransparency = 1
closeButton.Image = "rbxassetid://6035047409"
closeButton.Parent = titleBar

-- Minimize button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.new(0, 20, 0, 20)
minimizeButton.Position = UDim2.new(1, -52, 0.5, -10)
minimizeButton.BackgroundTransparency = 1
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Text = "—"
minimizeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
minimizeButton.TextSize = 20
minimizeButton.Parent = titleBar

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, -20, 1, -56)
contentFrame.Position = UDim2.new(0, 10, 0, 46)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Example gradient button factory
local function createGradientButton(name, text, position)
    local outline = Instance.new("Frame")
    outline.Name = name .. "Outline"
    outline.Size = UDim2.new(1, 0, 0, 40)
    outline.Position = position
    outline.BorderSizePixel = 0
    outline.Parent = contentFrame

    local oc = Instance.new("UICorner")
    oc.CornerRadius = UDim.new(0, 10)
    oc.Parent = outline

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(Color3.fromRGB(0, 170, 255), Color3.fromRGB(0, 255, 170))
    grad.Parent = outline

    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, -6, 1, -6)
    btn.Position = UDim2.new(0, 3, 0, 3)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.BorderSizePixel = 0
    btn.Parent = outline

    local ic = Instance.new("UICorner")
    ic.CornerRadius = UDim.new(0, 8)
    ic.Parent = btn

    return btn
end

local startButton = createGradientButton("StartFarm", "▶️ Start Farming", UDim2.new(0, 0, 0, 0))

-- ==========================
-- Logic
-- ==========================
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        -- shrink with tween
        local tween = TweenService:Create(outlineFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 320, 0, 44) -- only titlebar height + border
        })
        tween:Play()
        contentFrame.Visible = false
        titleLabel.Text = "Status: Idle"
    else
        local tween = TweenService:Create(outlineFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 320, 0, 460)
        })
        tween:Play()
        contentFrame.Visible = true
        titleLabel.Text = "🦄 Farmy " .. VERSION
    end
end)

if DEBUG_MODE then
    print("[Farmy] v" .. VERSION .. " loaded with rounded corners + tween minimize")
end
