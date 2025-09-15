-- 🦄 Farmy (Modern UI Framework)
local VERSION = "v0.0.8"
local EXPLOIT_NAME = "🦄 Farmy"
local DEBUG_MODE = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")
local player = Players.LocalPlayer

-- ==========================
-- UI Class
-- ==========================
local FarmUI = {}
FarmUI.__index = FarmUI

FarmUI.Status = "Open" -- static variable for minimized/open
FarmUI.LoadingActive = false

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

    -- Title label
    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Size = UDim2.new(1, -80, 1, 0)
    self.TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Font = Enum.Font.GothamBold
    self.TitleLabel.Text = EXPLOIT_NAME .. " " .. VERSION
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.TextSize = 18
    self.TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    self.TitleLabel.Parent = self.TitleBar
    
    -- Close & Minimize buttons (text buttons, white)
    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Size = UDim2.new(0, 20, 0, 20)
    self.CloseButton.Position = UDim2.new(1, -28, 0.5, -10)
    self.CloseButton.BackgroundTransparency = 1
    self.CloseButton.Font = Enum.Font.GothamBold
    self.CloseButton.Text = "X" -- UTF-8 cross
    self.CloseButton.TextSize = 18
    self.CloseButton.TextColor3 = Color3.fromRGB(255,255,255)
    self.CloseButton.Parent = self.TitleBar
    
    self.MinimizeButton = Instance.new("TextButton")
    self.MinimizeButton.Size = UDim2.new(0, 20, 0, 20)
    self.MinimizeButton.Position = UDim2.new(1, -52, 0.5, -10)
    self.MinimizeButton.BackgroundTransparency = 1
    self.MinimizeButton.Font = Enum.Font.GothamBold
    self.MinimizeButton.Text = "—" -- minus for minimize
    self.MinimizeButton.TextSize = 20
    self.MinimizeButton.TextColor3 = Color3.fromRGB(255,255,255)
    self.MinimizeButton.Parent = self.TitleBar

    -- STOP button (hidden by default, replaces close+minimize when farming)
    self.StopButton = Instance.new("TextButton")
    self.StopButton.Size = UDim2.new(0, 60, 0, 30) -- slightly bigger
    self.StopButton.Position = UDim2.new(1, -70, 0.5, -15)
    self.StopButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    self.StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.StopButton.Font = Enum.Font.GothamBold
    self.StopButton.TextSize = 14
    self.StopButton.Text = "🚫 STOP"
    self.StopButton.Visible = false
    Instance.new("UICorner", self.StopButton).CornerRadius = UDim.new(0, 6)
    self.StopButton.Parent = self.TitleBar

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
    self.Minimized = true -- start minimized
    self.TaskActive = false
    FarmUI.Status = "Minimized"
    
    -- Setup
    self:applyTheme("Rainbow") -- default
    self:makeDraggable(self.TitleBar)
    self:setupEvents()
    
    -- Force minimized visuals at start
    self.Outline.Size = UDim2.new(0,360,0,50)
    self.TabsContainer.Visible = false
    self.TitleLabel.Text = "⏳ Starting..."
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
        if self.LoadingActive then return end -- 🚫 block minimize during loading

        self.Minimized = not self.Minimized
        FarmUI.Status = self.Minimized and "Minimized" or "Open"

        if self.Minimized then
            TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0,360,0,50)}):Play()
            self.TabsContainer.Visible = false
        else
            TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0,360,0,500)}):Play()
            self.TabsContainer.Visible = true
            -- restore current tab only
            for _,tab in ipairs(self.ContentArea:GetChildren()) do
                if tab:IsA("ScrollingFrame") then
                    tab.Visible = (tab == self.CurrentTab)
                end
            end
        end
    end)
    
    self.StopButton.MouseButton1Click:Connect(function()
    -- force stop farming
    self.TaskActive = false
    self:stopTitleAnimation()
    self.TitleLabel.Text = EXPLOIT_NAME .. " " .. VERSION

    -- restore UI
    self.Minimized = false
    FarmUI.Status = "Open"
    TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0,360,0,500)}):Play()
    self.TabsContainer.Visible = true

    -- restore only current tab visible
    for _,tab in ipairs(self.ContentArea:GetChildren()) do
        if tab:IsA("ScrollingFrame") then
            tab.Visible = (tab == self.CurrentTab)
        end
    end
            
    -- hide STOP, restore normal controls
    self.CloseButton.Visible = true
    self.MinimizeButton.Visible = true
    self.StopButton.Visible = false
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
-- Title Animations
function FarmUI:animateTitle(text, mode, duration)
    -- mode can be "dots" or "fade"
    -- duration = how long to keep animating (seconds), nil = infinite until stopped
    
    if self.TitleAnimationRunning then
        self.TitleAnimationRunning = false
        task.wait() -- yield 1 frame to stop old loop
    end
    
    self.TitleAnimationRunning = true
    local startTime = tick()
    
    task.spawn(function()
        if mode == "dots" then
            local base = text
            local i = 0
            while self.TitleAnimationRunning do
                i = (i % 3) + 1
                self.TitleLabel.Text = base .. string.rep(".", i)
                task.wait(0.5)
                if duration and tick() - startTime >= duration then break end
            end
            
        elseif mode == "fade" then
            self.TitleLabel.Text = text
            while self.TitleAnimationRunning do
                -- fade out
                TweenService:Create(self.TitleLabel, TweenInfo.new(0.5), {TextTransparency = 0.5}):Play()
                task.wait(0.5)
                -- fade in
                TweenService:Create(self.TitleLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
                task.wait(0.5)
                if duration and tick() - startTime >= duration then break end
            end
        else
            self.TitleLabel.Text = text
        end
        
        -- restore
        self.TitleAnimationRunning = false
    end)
end

function FarmUI:stopTitleAnimation()
    self.TitleAnimationRunning = false
    self.TitleLabel.TextTransparency = 0
end

-- ==========================
-- Initialization Animation
function FarmUI:initLoadingAnimation(steps, delayTime, autoOpen)
    delayTime = delayTime or 1.5
    autoOpen = autoOpen or false
    self.LoadingActive = true

    -- visually disable button
    self.MinimizeButton.AutoButtonColor = false
    self.MinimizeButton.TextTransparency = 0.5

    task.spawn(function()
        for _, step in ipairs(steps) do
            self:animateTitle(step, "fade", delayTime)
            task.wait(delayTime)
        end

        -- restore
        self:stopTitleAnimation()
        self.TitleLabel.Text = EXPLOIT_NAME .. " " .. VERSION
        self.MinimizeButton.AutoButtonColor = true
        self.MinimizeButton.TextTransparency = 0
        self.LoadingActive = false

        if autoOpen then
            self.Minimized = false
            FarmUI.Status = "Open"
            TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0,360,0,500)}):Play()
            self.TabsContainer.Visible = true
        end
    end)
end

-- ==========================
-- Initialize UI
local ui = FarmUI.new()
local farmingTab = ui:addTab("Farming")
local settingsTab = ui:addTab("Settings")
local infoTab = ui:addTab("Info")

-- init loading sequence
ui:initLoadingAnimation(
    {"Loading", "Checking", "Configuring", "Almost ready"},
    1.0, -- delay per step
    true -- auto open
)

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
-- Farming Tab: Placeholder buttons to test

local function attachTestTask(button, label)
    button.MouseButton1Click:Connect(function()
        if ui.TaskActive then return end -- 🚫 already busy, ignore new clicks
        ui.TaskActive = true
        -- hide normal buttons, show STOP
        ui.CloseButton.Visible = false
        ui.MinimizeButton.Visible = false
        ui.StopButton.Visible = true


        -- minimize UI when task starts
        if not ui.Minimized then
            ui.Minimized = true
            FarmUI.Status = "Minimized"
            TweenService:Create(ui.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0,360,0,50)}):Play()
            ui.TabsContainer.Visible = false
        end

        -- Start looping animation
        ui:animateTitle(label, "dots")

        -- Stop after 5s and restore
        task.delay(5, function()
            ui:stopTitleAnimation()
            ui.TitleLabel.Text = EXPLOIT_NAME .. " " .. VERSION

            -- unminimize back
            ui.Minimized = false
            FarmUI.Status = "Open"
            TweenService:Create(ui.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0,360,0,500)}):Play()
            ui.TabsContainer.Visible = true

            -- restore only current tab visible
            for _,tab in ipairs(ui.ContentArea:GetChildren()) do
                if tab:IsA("ScrollingFrame") then
                    tab.Visible = (tab == ui.CurrentTab)
                end
            end

            -- ✅ unlock for next task
            ui.TaskActive = false
            -- restore buttons
            ui.CloseButton.Visible = true
            ui.MinimizeButton.Visible = true
            ui.StopButton.Visible = false
        end)
    end)
end

local function createSection(parent, title, yOffset)
    -- Section header
    local header = Instance.new("TextLabel")
    header.Text = title
    header.Size = UDim2.new(1, 0, 0, 28)
    header.Position = UDim2.new(0, 0, 0, yOffset)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextSize = 18
    header.TextColor3 = Color3.fromRGB(255,255,255)
    header.TextXAlignment = Enum.TextXAlignment.Center
    header.Parent = parent
    return header
end

local currentY = 8 -- initial padding

-- Coins Section
createSection(farmingTab, "Coins", currentY)
currentY = currentY + 32 -- header height + spacing

local btn = Instance.new("TextButton")
btn.Text = "Collect Coins"
btn.Size = UDim2.new(0.9, 0, 0, 36)
btn.Position = UDim2.new(0.05, 0, 0, currentY)
btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.Font = Enum.Font.Gotham
btn.TextSize = 14
Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
btn.Parent = farmingTab
attachTestTask(btn, "Collecting Coins") -- 🟢 test task
currentY = currentY + 42 -- button height + spacing

-- XP Section
createSection(farmingTab, "XP", currentY)
currentY = currentY + 32

for i=1,2 do
    local btn = Instance.new("TextButton")
    btn.Text = "Gain XP #" .. i
    btn.Size = UDim2.new(0.9, 0, 0, 36)
    btn.Position = UDim2.new(0.05, 0, 0, currentY)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.Parent = farmingTab
    attachTestTask(btn, "Collecting XP") -- 🟢 test task
    currentY = currentY + 42
end

-- Resources Section
createSection(farmingTab, "Resources", currentY)
currentY = currentY + 32

for i=1,20 do
    local btn = Instance.new("TextButton")
    btn.Text = "Resource #" .. i
    btn.Size = UDim2.new(0.9, 0, 0, 36)
    btn.Position = UDim2.new(0.05, 0, 0, currentY)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.Parent = farmingTab
    attachTestTask(btn, "Collecting Resource " .. i .. " of 20") -- 🟢 test task
    currentY = currentY + 42
end

-- ==========================
-- Info Tab

-- Stats Header (centered)
local statsHeader = Instance.new("TextLabel")
statsHeader.Text = "Stats"
statsHeader.Size = UDim2.new(1, 0, 0, 28) -- full width
statsHeader.Position = UDim2.new(0, 0, 0, 8) -- top margin
statsHeader.BackgroundTransparency = 1
statsHeader.Font = Enum.Font.GothamBold
statsHeader.TextSize = 18
statsHeader.TextColor3 = Color3.fromRGB(255,255,255)
statsHeader.TextXAlignment = Enum.TextXAlignment.Center
statsHeader.Parent = infoTab

-- Stats Label (below header)
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -16, 0, 80)
statsLabel.Position = UDim2.new(0, 8, 0, 44)
statsLabel.BackgroundTransparency = 1
statsLabel.Font = Enum.Font.Gotham
statsLabel.TextSize = 14
statsLabel.TextColor3 = Color3.fromRGB(255,255,255)
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.TextWrapped = true
statsLabel.Parent = infoTab

-- Changelog Header (centered)
local changelogHeader = Instance.new("TextLabel")
changelogHeader.Text = "Changelog"
changelogHeader.Size = UDim2.new(1, 0, 0, 28)
changelogHeader.Position = UDim2.new(0, 0, 0, 140)
changelogHeader.BackgroundTransparency = 1
changelogHeader.Font = Enum.Font.GothamBold
changelogHeader.TextSize = 18
changelogHeader.TextColor3 = Color3.fromRGB(255,255,255)
changelogHeader.TextXAlignment = Enum.TextXAlignment.Center
changelogHeader.Parent = infoTab

-- Changelog Scrollable Frame
local changelogFrame = Instance.new("ScrollingFrame")
changelogFrame.Size = UDim2.new(1, -16, 1, -200) -- leave space for headers
changelogFrame.Position = UDim2.new(0, 8, 0, 180)
changelogFrame.BackgroundTransparency = 1
changelogFrame.ScrollBarThickness = 4
changelogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
changelogFrame.Parent = infoTab

-- Layout
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
changelogLabel.Text = "- v0.0.1: Added main farming logic\n- v0.0.2: Added polished ui\n"
changelogLabel.Size = UDim2.new(1, 0, 0, 0)
changelogLabel.BackgroundTransparency = 1
changelogLabel.Font = Enum.Font.Gotham
changelogLabel.TextSize = 14
changelogLabel.TextColor3 = Color3.fromRGB(255,255,255)
changelogLabel.TextXAlignment = Enum.TextXAlignment.Left
changelogLabel.TextYAlignment = Enum.TextYAlignment.Top
changelogLabel.TextWrapped = true
changelogLabel.RichText = true
changelogLabel.AutomaticSize = Enum.AutomaticSize.Y
changelogLabel.Parent = changelogFrame

-- Auto-update canvas size
local function updateCanvasSize()
    task.defer(function()
        changelogFrame.CanvasSize = UDim2.new(0, 0, 0, changelogLabel.AbsoluteSize.Y + 8)
    end)
end

updateCanvasSize()
changelogLabel:GetPropertyChangedSignal("Text"):Connect(updateCanvasSize)
changelogLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvasSize)

-- ==========================
-- Stats updater
local startTime = tick()  -- for runtime
local fpsStartTime = tick() -- for FPS calculation
local frameCount = 0
local fps = 0

RunService.Heartbeat:Connect(function(delta)
    frameCount += 1

    -- Update FPS every second
    if tick() - fpsStartTime >= 1 then
        fps = frameCount
        frameCount = 0
        fpsStartTime = tick()
    end

    -- Runtime
    local runtime = tick() - startTime
    local hours = math.floor(runtime/3600)
    local minutes = math.floor((runtime%3600)/60)
    local seconds = math.floor(runtime%60)

    -- Approx ping (local)
    local pingStat = StatsService.Network.ServerStatsItem["Data Ping"]
    local ping = pingStat and math.floor(pingStat:GetValue()) or 0

    -- Update stats text
    statsLabel.Text = string.format(
        "PlaceID: %d\nRuntime: %02d:%02d:%02d\nFPS: %d\nPlayers: %d\nPing: %d ms",
        game.PlaceId,
        hours, minutes, seconds,
        fps,
        #Players:GetPlayers(),
        ping
    )
end)

if DEBUG_MODE then
    print("[Farmy] UI "..VERSION.." initialized.")
end
