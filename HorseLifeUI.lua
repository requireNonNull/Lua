-- 🦄 Farmy v5.0 (Modern UI Framework)
local VERSION = "v8.0"
local DEBUG_MODE = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ==========================
-- UI Class
-- ==========================
local FarmUI = {}
FarmUI.__index = FarmUI

FarmUI.Status = "Open" -- static variable for minimized/open

-- Themes
local Themes = {
    Dark = {Accent1 = Color3.fromRGB(0,170,255), Accent2 = Color3.fromRGB(0,255,170)},
    White = {Accent1 = Color3.fromRGB(255,255,255), Accent2 = Color3.fromRGB(200,200,200)},
    PitchBlack = {Accent1 = Color3.fromRGB(40,40,40), Accent2 = Color3.fromRGB(80,80,80)},
    DarkPurple = {Accent1 = Color3.fromRGB(120,0,200), Accent2 = Color3.fromRGB(200,0,255)},
    Rainbow = "Rainbow"
}

-- ==========================
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
    self.Outline.Size = UDim2.new(0, 360, 0, 500)
    self.Outline.Position = UDim2.new(0.5, -180, 0.5, -250)
    self.Outline.BorderSizePixel = 0
    self.Outline.Parent = self.Screen
    Instance.new("UICorner", self.Outline).CornerRadius = UDim.new(0, 18)

    self.OutlineGradient = Instance.new("UIGradient")
    self.OutlineGradient.Rotation = 45
    self.OutlineGradient.Parent = self.Outline

    -- Main frame
    self.Main = Instance.new("Frame")
    self.Main.Size = UDim2.new(1, -8, 1, -8)
    self.Main.Position = UDim2.new(0, 4, 0, 4)
    self.Main.BorderSizePixel = 0
    self.Main.Parent = self.Outline
    Instance.new("UICorner", self.Main).CornerRadius = UDim.new(0, 14)

    -- Title bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Size = UDim2.new(1, 0, 0, 42)
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Parent = self.Main
    Instance.new("UICorner", self.TitleBar).CornerRadius = UDim.new(0, 14)

    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Size = UDim2.new(1, -80, 1, 0)
    self.TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Font = Enum.Font.GothamBold
    self.TitleLabel.Text = "🦄 Farmy " .. VERSION
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.TextSize = 18
    self.TitleLabel.Parent = self.TitleBar

    -- Close & Minimize buttons
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
    self.TabsContainer.Size = UDim2.new(1, 0, 1, -50)
    self.TabsContainer.Position = UDim2.new(0, 0, 0, 50)
    self.TabsContainer.BackgroundTransparency = 1
    self.TabsContainer.Parent = self.Main

    -- Tab buttons row
    self.TabButtons = Instance.new("Frame")
    self.TabButtons.Size = UDim2.new(1, 0, 0, 36)
    self.TabButtons.BackgroundTransparency = 1
    self.TabButtons.Parent = self.TabsContainer
    local layout = Instance.new("UIListLayout", self.TabButtons)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, 8)

    Instance.new("UIPadding", self.TabButtons).PaddingLeft = UDim.new(0, 8)

    -- Content area
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Size = UDim2.new(1, -16, 1, -40)
    self.ContentArea.Position = UDim2.new(0, 8, 0, 40)
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Parent = self.TabsContainer

    -- Init
    self.CurrentTab = nil
    self.CurrentTheme = nil
    self.Minimized = false

    -- Setup
    self:makeDraggable(self.TitleBar)
    self:setupEvents()
    self:applyTheme("Dark") -- default
    return self
end

-- ==========================
-- Dragging
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

-- ==========================
-- Events
function FarmUI:setupEvents()
    self.CloseButton.MouseButton1Click:Connect(function()
        self.Screen:Destroy()
    end)

    self.MinimizeButton.MouseButton1Click:Connect(function()
        self.Minimized = not self.Minimized
        FarmUI.Status = self.Minimized and "Minimized" or "Open"

        if self.Minimized then
            TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0,360,0,50)}):Play()
            self.TabsContainer.Visible = false
            self.TitleLabel.Text = "⏳ Minimized"
        else
            TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0,360,0,500)}):Play()
            self.TabsContainer.Visible = true
            self.TitleLabel.Text = "🦄 Farmy " .. VERSION
            -- restore current tab only
            for _,tab in ipairs(self.ContentArea:GetChildren()) do
                if tab:IsA("ScrollingFrame") then
                    tab.Visible = (tab == self.CurrentTab)
                end
            end
        end
    end)
end

-- ==========================
-- Theme Application

function FarmUI:applyTheme(name)
    self.CurrentTheme = name
    -- always keep background pitch black
    self.Main.BackgroundColor3 = Color3.fromRGB(0,0,0)
    self.TitleBar.BackgroundColor3 = Color3.fromRGB(0,0,0)
    
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
        self.OutlineGradient.Color = ColorSequence.new(th.Accent1, th.Accent2)
    end

    -- update theme buttons to show active
    if self.ThemeButtons then
        for tName,button in pairs(self.ThemeButtons) do
            if tName == name then
                button.BackgroundTransparency = 0.6
            else
                button.BackgroundTransparency = 0
            end
        end
    end
end

-- ==========================
-- Add Tabs
function FarmUI:addTab(name)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 100, 1, 0)
    button.Text = name
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.BackgroundColor3 = Color3.fromRGB(30,30,30) -- fixed background
    button.TextColor3 = Color3.fromRGB(255,255,255) -- fixed text color
    button.AutoButtonColor = false
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    button.Parent = self.TabButtons

    -- hover effect
    button.MouseEnter:Connect(function()
        if self.CurrentTheme ~= "Rainbow" then
            button.BackgroundColor3 = th.ButtonHover
        end
    end)
    button.MouseLeave:Connect(function()
        if self.CurrentTheme ~= "Rainbow" then
            button.BackgroundColor3 = th.Button
        end
    end)

    -- content scrolling frame
    local content = Instance.new("ScrollingFrame")
    content.Name = name.."Content"
    content.Size = UDim2.new(1,0,1,0)
    content.CanvasSize = UDim2.new(0,0,0,0)
    content.ScrollBarThickness = 0
    content.BackgroundTransparency = 1
    content.Visible = false
    content.Parent = self.ContentArea

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,6)
    layout.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0,8)
    padding.PaddingBottom = UDim.new(0,8)
    padding.PaddingLeft = UDim.new(0,8)
    padding.PaddingRight = UDim.new(0,8)
    padding.Parent = content

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 16)
    end)

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
-- Initialize UI
local ui = FarmUI.new()
local farmingTab = ui:addTab("Farming")
local settingsTab = ui:addTab("Settings")
local infoTab = ui:addTab("Info")

-- ==========================
-- Settings Tab: Design Header + Theme Button
-- ==========================
local headerDesign = Instance.new("TextLabel")
headerDesign.Text = "Design"
headerDesign.Size = UDim2.new(1,0,0,28)
headerDesign.BackgroundTransparency = 1
headerDesign.Font = Enum.Font.GothamBold
headerDesign.TextSize = 18
headerDesign.TextColor3 = Color3.fromRGB(255,255,255)
headerDesign.Parent = settingsTab

ui.ThemeButtons = {}
local themesList = {"Dark","White","PitchBlack","DarkPurple","Rainbow"}
for i,themeName in ipairs(themesList) do
    local btn = Instance.new("TextButton")
    btn.Text = themeName
    btn.Size = UDim2.new(1, -16, 0, 36)
    btn.Position = UDim2.new(0, 8, 0, 28 + (i-1)*42)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    btn.Parent = settingsTab
    ui.ThemeButtons[themeName] = btn

    btn.MouseButton1Click:Connect(function()
        ui:applyTheme(themeName)
    end)
end

-- mark initial theme button as active
ui.ThemeButtons[ui.CurrentTheme].BackgroundTransparency = 0.6

-- ==========================
-- Farming Tab: Placeholder buttons to test scrolling
for i=1,25 do
    local btn = Instance.new("TextButton")
    btn.Text = "Farm Action #" .. i
    btn.Size = UDim2.new(0.9,0,0,36)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.Parent = farmingTab
end

-- ==========================
-- Info Tab
local infoTab = ui:addTab("Info")

-- Stats Header
local statsHeader = Instance.new("TextLabel")
statsHeader.Text = "Stats"
statsHeader.Size = UDim2.new(1, -16, 0, 24)
statsHeader.Position = UDim2.new(0, 8, 0, 8)
statsHeader.BackgroundTransparency = 1
statsHeader.Font = Enum.Font.GothamBold
statsHeader.TextSize = 18
statsHeader.TextColor3 = Color3.fromRGB(255,255,255)
statsHeader.TextXAlignment = Enum.TextXAlignment.Left
statsHeader.Parent = infoTab

-- Stats placeholder
local statsLabel = Instance.new("TextLabel")
statsLabel.Text = "Runtime: 0s\nOther stats here..."
statsLabel.Size = UDim2.new(1, -16, 0, 48)
statsLabel.Position = UDim2.new(0, 8, 0, 32)
statsLabel.BackgroundTransparency = 1
statsLabel.Font = Enum.Font.Gotham
statsLabel.TextSize = 14
statsLabel.TextColor3 = Color3.fromRGB(255,255,255)
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.TextWrapped = true
statsLabel.Parent = infoTab

-- Changelog Header
local changelogHeader = Instance.new("TextLabel")
changelogHeader.Text = "Changelog"
changelogHeader.Size = UDim2.new(1, -16, 0, 24)
changelogHeader.Position = UDim2.new(0, 8, 0, 88)
changelogHeader.BackgroundTransparency = 1
changelogHeader.Font = Enum.Font.GothamBold
changelogHeader.TextSize = 18
changelogHeader.TextColor3 = Color3.fromRGB(255,255,255)
changelogHeader.TextXAlignment = Enum.TextXAlignment.Left
changelogHeader.Parent = infoTab

-- Changelog Scrollable Frame
local changelogFrame = Instance.new("ScrollingFrame")
changelogFrame.Size = UDim2.new(1, -16, 1, -120) -- leave space for headers
changelogFrame.Position = UDim2.new(0, 8, 0, 120)
changelogFrame.BackgroundTransparency = 1
changelogFrame.ScrollBarThickness = 0 -- invisible scroll
changelogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
changelogFrame.Parent = infoTab

-- UIListLayout for auto layout
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = changelogFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0,4)
padding.PaddingBottom = UDim.new(0,4)
padding.PaddingLeft = UDim.new(0,8)
padding.PaddingRight = UDim.new(0,8)
padding.Parent = changelogFrame

-- Changelog Label
local changelogLabel = Instance.new("TextLabel")
changelogLabel.Text = "- v2.7: Theme buttons, titlebar themed, scrolling test\n- v2.4: Minor fixes\n- v2.3: Theme dropdown fix, titlebar themed fix, scrolling test fix\n- v2.0: Initial rewrite\nAdd more changelog lines here..."
changelogLabel.Size = UDim2.new(1, 0, 0, 0) -- auto-height
changelogLabel.BackgroundTransparency = 1
changelogLabel.Font = Enum.Font.Gotham
changelogLabel.TextSize = 14
changelogLabel.TextColor3 = Color3.fromRGB(255,255,255)
changelogLabel.TextXAlignment = Enum.TextXAlignment.Left
changelogLabel.TextYAlignment = Enum.TextYAlignment.Top
changelogLabel.TextWrapped = true
changelogLabel.Parent = changelogFrame

-- Auto-resize function
local function updateCanvasSize()
    changelogLabel.Size = UDim2.new(1, 0, 0, changelogLabel.TextBounds.Y)
    changelogFrame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end

updateCanvasSize()
changelogLabel:GetPropertyChangedSignal("Text"):Connect(updateCanvasSize)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)


-- Update runtime every second
local startTime = tick()
RunService.Heartbeat:Connect(function()
    if statsLabel and statsLabel.Parent then
        local elapsed = math.floor(tick()-startTime)
        statsLabel.Text = "Runtime: " .. elapsed .. "s"
    end
end)

if DEBUG_MODE then
    print("[Farmy] UI v"..VERSION.." initialized.")
end
