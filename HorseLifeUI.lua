-- 🦄 Farmy v2.0 (OOP UI Framework)
local VERSION = "v2.1"
local DEBUG_MODE = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- ==========================
-- UI Class
-- ==========================
local FarmUI = {}
FarmUI.__index = FarmUI

-- Themes
local Themes = {
    Dark = {
        Background = Color3.fromRGB(25,25,25),
        Accent1 = Color3.fromRGB(0,170,255),
        Accent2 = Color3.fromRGB(0,255,170),
        Text = Color3.fromRGB(255,255,255),
    },
    Green = {
        Background = Color3.fromRGB(20,30,20),
        Accent1 = Color3.fromRGB(0,200,100),
        Accent2 = Color3.fromRGB(0,255,170),
        Text = Color3.fromRGB(240,240,240),
    },
    Rainbow = "Rainbow" -- special case
}

-- Constructor
function FarmUI.new()
    local self = setmetatable({}, FarmUI)

    -- Root ScreenGui
    self.Screen = Instance.new("ScreenGui")
    self.Screen.Name = "FarmUI"
    self.Screen.ResetOnSpawn = false
    self.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.Screen.Parent = game:GetService("CoreGui")

    -- Outline frame
    self.Outline = Instance.new("Frame")
    self.Outline.Size = UDim2.new(0, 320, 0, 460)
    self.Outline.Position = UDim2.new(0.5, -160, 0.5, -230)
    self.Outline.BorderSizePixel = 0
    self.Outline.Parent = self.Screen
    Instance.new("UICorner", self.Outline).CornerRadius = UDim.new(0, 16)

    self.OutlineGradient = Instance.new("UIGradient")
    self.OutlineGradient.Rotation = 45
    self.OutlineGradient.Parent = self.Outline

    -- Main frame
    self.Main = Instance.new("Frame")
    self.Main.Size = UDim2.new(1, -8, 1, -8)
    self.Main.Position = UDim2.new(0, 4, 0, 4)
    self.Main.BorderSizePixel = 0
    self.Main.Parent = self.Outline
    Instance.new("UICorner", self.Main).CornerRadius = UDim.new(0, 12)

    -- Title bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Size = UDim2.new(1, 0, 0, 36)
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Parent = self.Main
    self.TitleBar.ClipsDescendants = true
    Instance.new("UICorner", self.TitleBar).CornerRadius = UDim.new(0, 12)

    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Size = UDim2.new(1, -80, 1, 0)
    self.TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Font = Enum.Font.GothamBold
    self.TitleLabel.Text = "🦄 Farmy " .. VERSION
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.Parent = self.TitleBar

    -- Buttons
    self.CloseButton = Instance.new("ImageButton")
    self.CloseButton.Size = UDim2.new(0, 20, 0, 20)
    self.CloseButton.Position = UDim2.new(1, -28, 0.5, -10)
    self.CloseButton.BackgroundTransparency = 1
    self.CloseButton.Image = "rbxassetid://6035047409"
    self.CloseButton.Parent = self.TitleBar

    self.MinimizeButton = Instance.new("TextButton")
    self.MinimizeButton.Size = UDim2.new(0, 20, 0, 20)
    self.MinimizeButton.Position = UDim2.new(1, -52, 0.5, -10)
    self.MinimizeButton.BackgroundTransparency = 1
    self.MinimizeButton.Font = Enum.Font.GothamBold
    self.MinimizeButton.Text = "—"
    self.MinimizeButton.TextSize = 20
    self.MinimizeButton.Parent = self.TitleBar

    -- Tabs container
    self.TabsContainer = Instance.new("Frame")
    self.TabsContainer.Size = UDim2.new(1, 0, 1, -46)
    self.TabsContainer.Position = UDim2.new(0, 0, 0, 46)
    self.TabsContainer.BackgroundTransparency = 1
    self.TabsContainer.Parent = self.Main

    -- Tab buttons
    self.TabButtons = Instance.new("Frame")
    self.TabButtons.Size = UDim2.new(1, 0, 0, 30)
    self.TabButtons.BackgroundTransparency = 1
    self.TabButtons.Parent = self.TabsContainer

    local layout = Instance.new("UIListLayout", self.TabButtons)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 8)

    -- Content area
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Size = UDim2.new(1, -20, 1, -30)
    self.ContentArea.Position = UDim2.new(0, 10, 0, 30)
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Parent = self.TabsContainer

    self.CurrentTab = nil
    self.CurrentTheme = nil
    self.Minimized = false

    self:makeDraggable(self.TitleBar)
    self:setupEvents()
    self:applyTheme("Dark") -- default
    return self
end

-- ==========================
-- Methods
-- ==========================
function FarmUI:makeDraggable(dragHandle)
    local dragging, dragInput, startPos, startInputPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = self.Outline.Position
            startInputPos = input.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - startInputPos
            self.Outline.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function FarmUI:setupEvents()
    self.CloseButton.MouseButton1Click:Connect(function()
        self.Screen:Destroy()
    end)

    self.MinimizeButton.MouseButton1Click:Connect(function()
        self.Minimized = not self.Minimized
        if self.Minimized then
            TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0, 320, 0, 44)}):Play()
            self.TabsContainer.Visible = false
            self.TitleLabel.Text = "⏳ Waiting..."
        else
            TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0, 320, 0, 460)}):Play()
            self.TabsContainer.Visible = true
            self.TitleLabel.Text = "🦄 Farmy " .. VERSION
            -- restore only current tab
            for _,tab in ipairs(self.ContentArea:GetChildren()) do
                if tab:IsA("ScrollingFrame") then
                    tab.Visible = (tab == self.CurrentTab)
                end
            end
        end
    end)
end

function FarmUI:applyTheme(name)
    self.CurrentTheme = name
    if name == "Rainbow" then
        task.spawn(function()
            while self.CurrentTheme == "Rainbow" do
                local t = tick()
                local r = 0.5 + 0.5 * math.sin(t)
                local g = 0.5 + 0.5 * math.sin(t + 2)
                local b = 0.5 + 0.5 * math.sin(t + 4)
                self.OutlineGradient.Color = ColorSequence.new(Color3.new(r,g,b), Color3.new(b,r,g))
                task.wait(0.05)
            end
        end)
    else
        local th = Themes[name]
        self.Main.BackgroundColor3 = th.Background
        self.OutlineGradient.Color = ColorSequence.new(th.Accent1, th.Accent2)
        self.TitleLabel.TextColor3 = th.Text
    end
end

function FarmUI:addTab(name)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 100, 1, 0)
    button.Text = name
    button.BackgroundTransparency = 0.2
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.Parent = self.TabButtons

    local content = Instance.new("ScrollingFrame")
    content.Name = name.."Content"
    content.Size = UDim2.new(1, 0, 1, 0)
    content.CanvasSize = UDim2.new(0,0,0,600)
    content.ScrollBarThickness = 0
    content.BackgroundTransparency = 1
    content.Visible = false
    content.Parent = self.ContentArea

    button.MouseButton1Click:Connect(function()
        if self.CurrentTab then self.CurrentTab.Visible = false end
        self.CurrentTab = content
        content.Visible = true
    end)

    if not self.CurrentTab then
        self.CurrentTab = content
        content.Visible = true
    end

    return content
end

-- ==========================
-- Example Usage
-- ==========================
local ui = FarmUI.new()

local farmingTab = ui:addTab("Farming")
local settingsTab = ui:addTab("Settings")

-- Add a slider under Settings (example placeholder)
local slider = Instance.new("TextLabel")
slider.Text = "TP Speed Slider (placeholder)"
slider.Size = UDim2.new(1,0,0,30)
slider.Parent = settingsTab

-- Theme buttons
for _,themeName in ipairs({"Dark","Green","Rainbow"}) do
    local btn = Instance.new("TextButton")
    btn.Text = "Theme: "..themeName
    btn.Size = UDim2.new(1,0,0,30)
    btn.Parent = settingsTab
    btn.MouseButton1Click:Connect(function()
        ui:applyTheme(themeName)
    end)
end

if DEBUG_MODE then
    print("[Farmy] UI v"..VERSION.." initialized.")
end
