-- 🦄 Farmy by Breezingfreeze
local VERSION = "v2.0"
local DEBUG_MODE = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- =====================================
-- UI Manager (OOP-like table)
-- =====================================
local UIManager = {}
UIManager.__index = UIManager

-- Themes
local THEMES = {
    Default = { Start = Color3.fromRGB(0, 170, 255), End = Color3.fromRGB(0, 255, 170) },
    Purple  = { Start = Color3.fromRGB(170, 0, 255), End = Color3.fromRGB(255, 0, 170) },
    Red     = { Start = Color3.fromRGB(255, 60, 60), End = Color3.fromRGB(255, 140, 140) },
    Rainbow = "Rainbow"
}

-- Constructor
function UIManager.new()
    local self = setmetatable({}, UIManager)

    -- ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "FarmUI"
    self.gui.ResetOnSpawn = false
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.gui.Parent = game:GetService("CoreGui")

    -- Outline
    self.outline = Instance.new("Frame")
    self.outline.Size = UDim2.new(0, 320, 0, 460)
    self.outline.Position = UDim2.new(0.5, -160, 0.5, -230)
    self.outline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.outline.BorderSizePixel = 0
    self.outline.Parent = self.gui

    local oc = Instance.new("UICorner", self.outline)
    oc.CornerRadius = UDim.new(0, 16)

    self.gradient = Instance.new("UIGradient", self.outline)
    self.gradient.Color = ColorSequence.new(THEMES.Default.Start, THEMES.Default.End)
    self.gradient.Rotation = 45

    -- Inner panel
    self.main = Instance.new("Frame", self.outline)
    self.main.Size = UDim2.new(1, -8, 1, -8)
    self.main.Position = UDim2.new(0, 4, 0, 4)
    self.main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    self.main.BorderSizePixel = 0
    local mc = Instance.new("UICorner", self.main)
    mc.CornerRadius = UDim.new(0, 12)

    -- Title bar
    self:BuildTitleBar()

    -- Tab system
    self.tabs = {}
    self.currentTab = nil
    self:BuildTabs()

    -- Dragging
    self:EnableDragging()

    -- Theme loop (rainbow)
    self.rainbowRunning = false

    return self
end

-- TitleBar
function UIManager:BuildTitleBar()
    local bar = Instance.new("Frame", self.main)
    bar.Name = "TitleBar"
    bar.Size = UDim2.new(1, 0, 0, 36)
    bar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

    local title = Instance.new("TextLabel", bar)
    title.Name = "Title"
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "🦄 Farmy " .. VERSION
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    self.titleLabel = title

    local close = Instance.new("TextButton", bar)
    close.Text = "✖"
    close.Font = Enum.Font.GothamBold
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -34, 0.5, -15)
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.fromRGB(200, 80, 80)
    close.MouseButton1Click:Connect(function() self.gui:Destroy() end)

    local minimize = Instance.new("TextButton", bar)
    minimize.Text = "—"
    minimize.Font = Enum.Font.GothamBold
    minimize.Size = UDim2.new(0, 30, 0, 30)
    minimize.Position = UDim2.new(1, -68, 0.5, -15)
    minimize.BackgroundTransparency = 1
    minimize.TextColor3 = Color3.fromRGB(200, 200, 200)

    local minimized = false
    minimize.MouseButton1Click:Connect(function()
        minimized = not minimized
        local goal = minimized and UDim2.new(0, 320, 0, 44) or UDim2.new(0, 320, 0, 460)
        TweenService:Create(self.outline, TweenInfo.new(0.3), {Size = goal}):Play()
        for _, tab in pairs(self.tabs) do
            tab.Frame.Visible = not minimized
        end
        self.titleLabel.Text = minimized and "⏳ Waiting..." or "🦄 Farmy " .. VERSION
    end)
end

-- Tabs
function UIManager:BuildTabs()
    local tabBar = Instance.new("Frame", self.main)
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 30)
    tabBar.Position = UDim2.new(0, 0, 0, 36)
    tabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

    local uiList = Instance.new("UIListLayout", tabBar)
    uiList.FillDirection = Enum.FillDirection.Horizontal
    uiList.SortOrder = Enum.SortOrder.LayoutOrder

    self:AddTab("Farming")
    self:AddTab("Settings")
end

function UIManager:AddTab(name)
    local btn = Instance.new("TextButton", self.main.TabBar)
    btn.Size = UDim2.new(0, 80, 1, 0)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14

    local frame = Instance.new("ScrollingFrame", self.main)
    frame.Name = name .. "Tab"
    frame.Size = UDim2.new(1, -20, 1, -76)
    frame.Position = UDim2.new(0, 10, 0, 66)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.CanvasSize = UDim2.new(0, 0, 2, 0)
    frame.ScrollBarThickness = 6

    self.tabs[name] = {Button = btn, Frame = frame}
    btn.MouseButton1Click:Connect(function() self:SwitchTab(name) end)

    -- fill sample UI
    if name == "Farming" then
        self:BuildFarmingTab(frame)
    elseif name == "Settings" then
        self:BuildSettingsTab(frame)
    end

    if not self.currentTab then
        self:SwitchTab(name)
    end
end

function UIManager:SwitchTab(name)
    for k, v in pairs(self.tabs) do
        v.Frame.Visible = (k == name)
    end
    self.currentTab = name
end

-- Farming tab sample
function UIManager:BuildFarmingTab(frame)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 200, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, 10)
    btn.Text = "▶️ Start Farming"
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
end

-- Settings tab
function UIManager:BuildSettingsTab(frame)
    -- Slider (TP Speed)
    local sliderLabel = Instance.new("TextLabel", frame)
    sliderLabel.Text = "TP Speed"
    sliderLabel.Position = UDim2.new(0, 10, 0, 10)
    sliderLabel.Size = UDim2.new(0, 200, 0, 20)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.TextSize = 14

    local slider = Instance.new("Frame", frame)
    slider.Position = UDim2.new(0, 10, 0, 40)
    slider.Size = UDim2.new(0, 200, 0, 6)
    slider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

    local fill = Instance.new("Frame", slider)
    fill.Size = UDim2.new(0.5, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)

    -- Theme buttons
    local y = 80
    for theme, colors in pairs(THEMES) do
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 200, 0, 30)
        btn.Position = UDim2.new(0, 10, 0, y)
        btn.Text = "Theme: " .. theme
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.MouseButton1Click:Connect(function() self:SetTheme(theme) end)
        y = y + 40
    end
end

-- Themes
function UIManager:SetTheme(theme)
    if theme == "Rainbow" then
        self.rainbowRunning = true
        task.spawn(function()
            while self.rainbowRunning do
                for h = 0, 1, 0.01 do
                    local c = Color3.fromHSV(h, 1, 1)
                    self.gradient.Color = ColorSequence.new(c, c)
                    task.wait(0.03)
                end
            end
        end)
    else
        self.rainbowRunning = false
        self.gradient.Color = ColorSequence.new(THEMES[theme].Start, THEMES[theme].End)
    end
end

-- Dragging
function UIManager:EnableDragging()
    local dragToggle = nil
    local dragStart = nil
    local startPos = nil

    self.main.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = true
            dragStart = input.Position
            startPos = self.outline.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragToggle and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.outline.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = false
        end
    end)
end

-- =====================================
-- Init
-- =====================================
local ui = UIManager.new()

if DEBUG_MODE then
    print("[Farmy] v" .. VERSION .. " UI loaded with tabs, dragging, themes, slider")
end
