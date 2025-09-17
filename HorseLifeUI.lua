local VERSION = "v0.1.2"
local EXPLOIT_NAME = "Horse Life 🐎 Menu"
local DEBUG_MODE = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")
local player = Players.LocalPlayer

-- Load Logic
local Logic = loadstring(game:HttpGet("https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/HorseLifeLogic.lua"))()

function ShowToast(message)
    pcall(function()
        if arceus and arceus.show_toast then
            arceus.show_toast(message)
        end
    end)
end

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

    self.BaseTabWidth = 100   -- each tab button is 100px wide
    self.BasePadding = 8      -- padding between tabs
    self.MinWidth = 464       -- minimum menu width

    local initialWidth = self.MinWidth
    local initialOpenHeight = 500
    local topPercent = 0.1 -- 10% from top
    
    -- Root ScreenGui
    self.Screen = Instance.new("ScreenGui")
    self.Screen.Name = "FarmUI"
    self.Screen.ResetOnSpawn = false
    self.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.Screen.Parent = game:GetService("CoreGui")

    -- Outline frame
    self.Outline = Instance.new("Frame")
    self.Outline.Size = UDim2.new(0, initialWidth, 0, initialOpenHeight)
    self.Outline.Position = UDim2.new(0.5, -initialWidth/2, topPercent, 0)
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
    self.MinimizeButton.TextSize = 18
    self.MinimizeButton.TextColor3 = Color3.fromRGB(255,255,255)
    self.MinimizeButton.Parent = self.TitleBar

    -- STOP button (hidden by default, replaces close+minimize when farming)
    self.StopButton = Instance.new("TextButton")
    self.StopButton.Size = UDim2.new(0, 20, 0, 20)
    self.StopButton.Position = UDim2.new(1, -28, 0.5, -10)
    self.StopButton.BackgroundTransparency = 1
    self.StopButton.Font = Enum.Font.GothamBold
    self.StopButton.Text = "⏹️" -- UTF-8 cross
    self.StopButton.TextSize = 18
    self.StopButton.TextColor3 = Color3.fromRGB(255,255,255)
    self.StopButton.Visible = false
    self.StopButton.Parent = self.TitleBar
    
    self.taskToggleButton = Instance.new("TextButton")
    self.taskToggleButton.Size = UDim2.new(0, 20, 0, 20)
    self.taskToggleButton.Position = UDim2.new(1, -52, 0.5, -10)
    self.taskToggleButton.BackgroundTransparency = 1
    self.taskToggleButton.Font = Enum.Font.GothamBold
    self.taskToggleButton.Text = "⏸️"
    self.taskToggleButton.TextSize = 18
    self.taskToggleButton.TextColor3 = Color3.fromRGB(255,255,255)
    self.taskToggleButton.Visible = false
    self.taskToggleButton.Parent = self.TitleBar

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
    
    -- Force minimized visuals at start (use MinWidth)
    self.Outline.Size = UDim2.new(0, self.MinWidth, 0, 50)
    self.Outline.Position = UDim2.new(0.5, -self.MinWidth/2, topPercent, 0)
    self.TabsContainer.Visible = false
    self.TitleLabel.Text = "Starting..."
    return self
end

function FarmUI:updateWidth()
    local tabCount = 0
    for _, child in ipairs(self.TabButtons:GetChildren()) do
        if child:IsA("TextButton") then
            tabCount += 1
        end
    end

    local neededWidth = tabCount * self.BaseTabWidth + (tabCount - 1) * self.BasePadding + 40
    if neededWidth < self.MinWidth then
        neededWidth = self.MinWidth
    end

    local currentHeight = self.Outline.Size.Y.Offset
    local currentVerticalPosition = self.Outline.Position.Y.Scale
    self.Outline.Size = UDim2.new(0, neededWidth, 0, currentHeight)
    self.Outline.Position = UDim2.new(0.5, -neededWidth/2, currentVerticalPosition, 0)
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
            local targetW = math.max(self.MinWidth, self.Outline.Size.X.Offset)
            TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0, targetW, 0, 50)}):Play()
            self.TabsContainer.Visible = false
        else
            local targetW = math.max(self.MinWidth, self.Outline.Size.X.Offset)
            TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0, targetW, 0, 500)}):Play()
            self.TabsContainer.Visible = true
            -- restore current tab only
            for _,tab in ipairs(self.ContentArea:GetChildren()) do
                if tab:IsA("ScrollingFrame") then
                    tab.Visible = (tab == self.CurrentTab)
                end
            end
        end
    end)
    
-- ==========================
-- Stop button functionality
self.StopButton.MouseButton1Click:Connect(function()
    if self.CurrentResource then
        Logic.stop(self.CurrentResource) -- 🔗 stop farming logic
    end

    -- force stop farming
    self.TaskActive = false
    self.CurrentResource = nil
    self:stopTitleAnimation()
    self.TitleLabel.Text = EXPLOIT_NAME .. " " .. VERSION

    -- restore UI
    self.Minimized = false
    FarmUI.Status = "Open"
    local targetW = math.max(self.MinWidth, self.Outline.Size.X.Offset) 
    TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0, targetW, 0, 500)}):Play()
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
    self.taskToggleButton.Visible = false
end)

-- ==========================
-- Toggle button functionality
self.taskToggleButton.MouseButton1Click:Connect(function()
    if not self.CurrentResource then return end -- 🚫 no active task

    if not self.TaskActive then
        -- Resume farming
        self.TaskActive = true
        self.taskToggleButton.Text = "⏸️"
        self:stopTitleAnimation()
        self:animateTitle("Collecting " .. self.CurrentResource, "dots")

        Logic.toggle(self.CurrentResource) -- 🔗 resume

        -- keep UI minimized while running
        self.Minimized = true
        FarmUI.Status = "Minimized"
        local targetW = math.max(self.MinWidth, self.Outline.Size.X.Offset)
        TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0, targetW, 0, 50)}):Play()
        self.TabsContainer.Visible = false

        -- Show Stop button and toggle
        self.StopButton.Visible = true
        self.taskToggleButton.Visible = true
        self.CloseButton.Visible = false
        self.MinimizeButton.Visible = false

    else
        -- Pause farming
        self.TaskActive = false
        self.taskToggleButton.Text = "▶️"
        self:stopTitleAnimation()
        self:animateTitle("Paused: " .. self.CurrentResource, "fade")

        Logic.toggle(self.CurrentResource) -- 🔗 pause

        -- keep minimized while paused
        self.Minimized = true
        FarmUI.Status = "Minimized"
        local targetW = math.max(self.MinWidth, self.Outline.Size.X.Offset)
        TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0, targetW, 0, 50)}):Play()
        self.TabsContainer.Visible = false
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

local function createButton(text, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 36)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent

    -- inner frame with corner + stroke + gradient
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(40,40,40)
    bg.BorderSizePixel = 0
    bg.Parent = btn

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,6)
    corner.Parent = bg

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80,80,80)
    stroke.Thickness = 1
    stroke.Transparency = 0 -- opaque
    stroke.Parent = bg

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(55,55,55)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30,30,30))
    }
    gradient.Rotation = math.random(0,359)
    gradient.Parent = bg

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = btn
    label.Active = false

    return btn
end

-- ==========================
-- Add Tabs (with transparent highlight)
function FarmUI:addTab(name)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 100, 1, 0)
    button.Text = name
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.BackgroundColor3 = Color3.fromRGB(30,30,30) -- default background
    button.BackgroundTransparency = 0 -- fully visible
    button.TextColor3 = Color3.fromRGB(255,255,255)
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

    local function updateTabHighlight(selectedButton)
        for _,tabButton in ipairs(self.TabButtons:GetChildren()) do
            if tabButton:IsA("TextButton") then
                if tabButton == selectedButton then
                    tabButton.BackgroundTransparency = 0.6 -- semi-transparent highlight
                else
                    tabButton.BackgroundTransparency = 0 -- normal
                end
            end
        end
    end

    button.MouseButton1Click:Connect(function()
        if self.CurrentTab then self.CurrentTab.Visible = false end
        self.CurrentTab = content
        content.Visible = true

        -- highlight current tab
        updateTabHighlight(button)
    end)

    -- if no current tab, make this one default
    if not self.CurrentTab then
        self.CurrentTab = content
        content.Visible = true
        updateTabHighlight(button)
    end

    -- 👇 auto-resize outline when new tab added
    self:updateWidth()

    return content
end

-- ==========================
-- Title Animations
function FarmUI:animateTitle(text, mode, duration)
    self.AnimationId = (self.AnimationId or 0) + 1
    local thisId = self.AnimationId
    local startTime = tick()
    
    task.spawn(function()
        if mode == "dots" then
            local base = text
            local i = 0
            while self.AnimationId == thisId do
                i = (i % 3) + 1
                self.TitleLabel.Text = base .. string.rep(".", i)
                task.wait(0.5)
                if duration and tick() - startTime >= duration then break end
            end
            
        elseif mode == "fade" then
            self.TitleLabel.Text = text
            while self.AnimationId == thisId do
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
    end)
end

function FarmUI:stopTitleAnimation()
    self.AnimationId = (self.AnimationId or 0) + 1 -- invalidate current loop
    self.TitleLabel.TextTransparency = 0
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
        ShowToast("Menu " .. VERSION .. " init.")
        ShowToast("Logic " .. Logic.GetVersion() .. " init.")

        if autoOpen then
            self:updateWidth() -- ensure outline width matches tab count
            self.Minimized = false
            FarmUI.Status = "Open"
            local targetW = math.max(self.MinWidth, self.Outline.Size.X.Offset) 
            TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0, targetW, 0, 500)}):Play()
            self.TabsContainer.Visible = true
        end
    end)
end

-- ==========================
-- Initialize UI
local ui = FarmUI.new()
local farmingTab = ui:addTab("Farming")
local teleportsTab = ui:addTab("Teleports")
local settingsTab = ui:addTab("Settings")
local infoTab = ui:addTab("Info")

-- init loading sequence
ui:initLoadingAnimation(
    {"Loading", "Checking", "Injecting Logic", "Almost ready"},
    0.5, -- delay per step
    true -- auto open
)

-- ==========================
-- Settings Tab Scrollable Container
local settingsContainer = Instance.new("ScrollingFrame")
settingsContainer.Size = UDim2.new(1, -16, 1, -16)
settingsContainer.Position = UDim2.new(0, 8, 0, 8)
settingsContainer.BackgroundTransparency = 1
settingsContainer.ScrollBarThickness = 0
settingsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
settingsContainer.Parent = settingsTab

-- Layout for spacing & centering
local settingsLayout = Instance.new("UIListLayout")
settingsLayout.Padding = UDim.new(0, 12)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
settingsLayout.Parent = settingsContainer

-- Top + bottom padding
local settingsPadding = Instance.new("UIPadding")
settingsPadding.PaddingTop = UDim.new(0, 12)
settingsPadding.PaddingBottom = UDim.new(0, 12)
settingsPadding.Parent = settingsContainer

-- Header
createSection(settingsContainer, "Design", 0)

-- ==========================
-- Theme buttons
ui.ThemeButtons = {}
local themesList = {"Dark","White","PitchBlack","DarkPurple","Rainbow"}
local currentActiveBtn = nil

-- Create theme buttons using createButton
for _, themeName in ipairs(themesList) do
    local btn = createButton(themeName, settingsContainer)
    table.insert(ui.ThemeButtons, btn)

    btn.MouseButton1Click:Connect(function()
        currentActiveBtn = btn
        ui:applyTheme(themeName)
    end)
end

-- Initially select the current theme
if ui.CurrentTheme then
    for _, btn in ipairs(ui.ThemeButtons) do
        if btn:FindFirstChildWhichIsA("TextLabel").Text == ui.CurrentTheme then
            currentActiveBtn = btn
            break
        end
    end
end

-- ==========================
-- Farming Tab: Placeholder buttons to test

-- Attach a farming resource button
local function attachFarmButton(button, resourceName)
    button.MouseButton1Click:Connect(function()
        if ui.TaskActive then return end -- use ui instead of self
        ui.TaskActive = true
        ui.CurrentResource = resourceName

        ui.CloseButton.Visible = false
        ui.MinimizeButton.Visible = false
        ui.StopButton.Visible = true
        ui.taskToggleButton.Visible = true
        ui.taskToggleButton.Text = "⏸️"

        if not ui.Minimized then
            ui.Minimized = true
            FarmUI.Status = "Minimized"
            local targetW = math.max(ui.MinWidth, ui.Outline.Size.X.Offset)
            TweenService:Create(ui.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0, targetW, 0, 50)}):Play()
            ui.TabsContainer.Visible = false
        end

        ui:animateTitle("Collecting " .. resourceName, "dots")
        Logic.start(resourceName)
    end)
end

-- ==========================
-- Farming Tab Scrollable Container
local farmingFrame = Instance.new("ScrollingFrame")
farmingFrame.Size = UDim2.new(1, -16, 1, -16)
farmingFrame.Position = UDim2.new(0, 8, 0, 8)
farmingFrame.BackgroundTransparency = 1
farmingFrame.ScrollBarThickness = 0
farmingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
farmingFrame.Parent = farmingTab

-- Layout for spacing & centering
local farmingLayout = Instance.new("UIListLayout")
farmingLayout.Padding = UDim.new(0, 12) -- vertical spacing between sections/buttons
farmingLayout.SortOrder = Enum.SortOrder.LayoutOrder
farmingLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
farmingLayout.Parent = farmingFrame

-- Top + bottom padding
local farmingPadding = Instance.new("UIPadding")
farmingPadding.PaddingTop = UDim.new(0, 12)    -- same as spacing
farmingPadding.PaddingBottom = UDim.new(0, 12) -- extra space at the bottom
farmingPadding.Parent = farmingFrame

-- Helper function for sections
local function addSection(title)
    local header = createSection(farmingFrame, title, 0)
    header.LayoutOrder = #farmingFrame:GetChildren() + 1
    return header
end

-- === Coins Section ===
addSection("Coins")
do
    local btn = createButton("Collect Coins", farmingFrame)
    attachFarmButton(btn, "Coins")
    btn.LayoutOrder = #farmingFrame:GetChildren() + 1
end

-- === XP Section ===
addSection("XP")
do
    local btn = createButton("Gain XP Jump", farmingFrame)
    attachFarmButton(btn, "XPJump")
    btn.LayoutOrder = #farmingFrame:GetChildren() + 1
end
do
    local btn = createButton("Gain XP Agility", farmingFrame)
    attachFarmButton(btn, "XPAgility")
    btn.LayoutOrder = #farmingFrame:GetChildren() + 1
end

-- === Resources Section ===
addSection("Resources")
for _, resourceName in ipairs(Logic.ResourceList) do
    if resourceName ~= "Coins" and resourceName ~= "XPJump" and resourceName ~= "XPAgility" then
        local btn = createButton("Collect " .. resourceName, farmingFrame)
        attachFarmButton(btn, resourceName)
        btn.LayoutOrder = #farmingFrame:GetChildren() + 1
    end
end
-- ==========================
-- Info Tab

local infoContainer = Instance.new("Frame")
infoContainer.Size = UDim2.new(1, -16, 1, -16)
infoContainer.Position = UDim2.new(0, 8, 0, 8)
infoContainer.BackgroundTransparency = 1
infoContainer.Parent = infoTab

local infoLayout = Instance.new("UIListLayout")
infoLayout.Padding = UDim.new(0, 12)
infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
infoLayout.Parent = infoContainer

-- === Stats Section ===
local statsHeader = createSection(infoContainer, "Stats", 0)

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -16, 0, 80)
statsLabel.BackgroundTransparency = 1
statsLabel.Font = Enum.Font.Gotham
statsLabel.TextSize = 14
statsLabel.TextColor3 = Color3.fromRGB(255,255,255)
statsLabel.TextXAlignment = Enum.TextXAlignment.Center
statsLabel.TextYAlignment = Enum.TextYAlignment.Center
statsLabel.TextWrapped = true
statsLabel.Parent = infoContainer

-- === Changelog Section ===
local changelogHeader = createSection(infoContainer, "Changelog", 0)

local changelogFrame = Instance.new("ScrollingFrame")
changelogFrame.Size = UDim2.new(1, -16, 0, 200)
changelogFrame.BackgroundTransparency = 1
changelogFrame.ScrollBarThickness = 0
changelogFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
changelogFrame.CanvasSize = UDim2.new(0,0,0,0)
changelogFrame.Parent = infoContainer

local changelogLayout = Instance.new("UIListLayout")
changelogLayout.Padding = UDim.new(0, 4)
changelogLayout.SortOrder = Enum.SortOrder.LayoutOrder
changelogLayout.Parent = changelogFrame

local changelogLabel = Instance.new("TextLabel")
changelogLabel.Size = UDim2.new(1, -16, 0, 0)
changelogLabel.AutomaticSize = Enum.AutomaticSize.Y
changelogLabel.BackgroundTransparency = 1
changelogLabel.Font = Enum.Font.Gotham
changelogLabel.TextSize = 14
changelogLabel.TextColor3 = Color3.fromRGB(255,255,255)
changelogLabel.TextXAlignment = Enum.TextXAlignment.Center
changelogLabel.TextYAlignment = Enum.TextYAlignment.Top
changelogLabel.TextWrapped = true
changelogLabel.RichText = true
changelogLabel.Text = "- v0.0.1: WIP\n- v0.0.2: WIP\n"
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
    print("Horse Life 🐎 Menu " .. VERSION .. " initialized.")
end
