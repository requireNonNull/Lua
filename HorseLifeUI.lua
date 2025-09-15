-- 🦄 Farmy v3.1 (Modern Themed UI) - Full script
-- Features:
--  - Themes: Dark, White, Pitch Black, Dark Purple, Rainbow (applies to all accents)
--  - Dropdown theme selector (Settings → Design)
--  - Tabs: Farming, Settings, Info (only one visible at a time)
--  - Headers in tabs (Design, Farm, Stats, Changelog)
--  - Scrolling frames with hidden scrollbars (auto-resize CanvasSize)
--  - Runtime statistics auto-updating every second
--  - Hardcoded changelog at top
--  - Minimize toggles UI and sets FarmUI.Status ("Open" / "Minimized")
--  - Rounded corners and modern spacing/hover feedback
-- Drop into a LocalScript (StarterGui) or appropriate environment.

local VERSION = "v3.2"
local DEBUG_MODE = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local startTime = tick()

-- Hardcoded changelog (edit here)
local CHANGELOG = {
    "v3.1 - Consistent theming, dropdown selector, uptime stats, minimized status variable",
    "v3.0 - Added Info tab, Stats, Changelog, and new themes",
    "v2.4 - Improved rounded layout, tab system, hidden scrollbar"
}

-- ==========================
-- UI Class
-- ==========================
local FarmUI = {}
FarmUI.__index = FarmUI

local Themes = {
    Dark = {
        Background = Color3.fromRGB(25,25,25),
        Accent1 = Color3.fromRGB(0,170,255),
        Accent2 = Color3.fromRGB(0,255,170),
        Button = Color3.fromRGB(40,40,40),
        ButtonHover = Color3.fromRGB(55,55,55),
        Text = Color3.fromRGB(255,255,255),
    },
    White = {
        Background = Color3.fromRGB(245,245,245),
        Accent1 = Color3.fromRGB(0,170,255),
        Accent2 = Color3.fromRGB(0,120,200),
        Button = Color3.fromRGB(225,225,225),
        ButtonHover = Color3.fromRGB(210,210,210),
        Text = Color3.fromRGB(30,30,30),
    },
    PitchBlack = {
        Background = Color3.fromRGB(10,10,10),
        Accent1 = Color3.fromRGB(80,80,80),
        Accent2 = Color3.fromRGB(150,150,150),
        Button = Color3.fromRGB(20,20,20),
        ButtonHover = Color3.fromRGB(35,35,35),
        Text = Color3.fromRGB(255,255,255),
    },
    DarkPurple = {
        Background = Color3.fromRGB(20,15,30),
        Accent1 = Color3.fromRGB(120,0,200),
        Accent2 = Color3.fromRGB(200,0,255),
        Button = Color3.fromRGB(40,25,60),
        ButtonHover = Color3.fromRGB(60,40,80),
        Text = Color3.fromRGB(240,240,240),
    },
    Rainbow = "Rainbow"
}

-- Constructor
function FarmUI.new()
    local self = setmetatable({}, FarmUI)

    -- state
    self.CurrentTheme = "Dark"
    self.RainbowTask = nil
    self.CurrentTab = nil
    self.Status = "Open" -- static status variable for later use ("Open" / "Minimized")

    -- ScreenGui
    self.Screen = Instance.new("ScreenGui")
    self.Screen.Name = "FarmUI"
    self.Screen.ResetOnSpawn = false
    self.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.Screen.Parent = game:GetService("CoreGui")

    -- Outline (gradient border)
    self.Outline = Instance.new("Frame")
    self.Outline.Size = UDim2.new(0, 380, 0, 520)
    self.Outline.Position = UDim2.new(0.5, -190, 0.5, -260)
    self.Outline.BorderSizePixel = 0
    self.Outline.Parent = self.Screen
    Instance.new("UICorner", self.Outline).CornerRadius = UDim.new(0, 18)

    self.OutlineGradient = Instance.new("UIGradient")
    self.OutlineGradient.Rotation = 45
    self.OutlineGradient.Parent = self.Outline

    -- Main (inset)
    self.Main = Instance.new("Frame")
    self.Main.Size = UDim2.new(1, -8, 1, -8)
    self.Main.Position = UDim2.new(0, 4, 0, 4)
    self.Main.BorderSizePixel = 0
    self.Main.Parent = self.Outline
    Instance.new("UICorner", self.Main).CornerRadius = UDim.new(0, 14)

    -- Title bar (rounded top)
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Size = UDim2.new(1, 0, 0, 44)
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Parent = self.Main
    Instance.new("UICorner", self.TitleBar).CornerRadius = UDim.new(0, 14)

    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Size = UDim2.new(1, -96, 1, 0)
    self.TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Font = Enum.Font.GothamBold
    self.TitleLabel.Text = "🦄 Farmy " .. VERSION
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.TextSize = 18
    self.TitleLabel.Parent = self.TitleBar

    -- Control buttons
    self.CloseButton = Instance.new("ImageButton")
    self.CloseButton.Size = UDim2.new(0, 20, 0, 20)
    self.CloseButton.Position = UDim2.new(1, -28, 0.5, -10)
    self.CloseButton.BackgroundTransparency = 1
    self.CloseButton.Image = "rbxassetid://6035047409"
    self.CloseButton.Parent = self.TitleBar

    self.MinimizeButton = Instance.new("TextButton")
    self.MinimizeButton.Size = UDim2.new(0, 20, 0, 20)
    self.MinimizeButton.Position = UDim2.new(1, -56, 0.5, -10)
    self.MinimizeButton.BackgroundTransparency = 1
    self.MinimizeButton.Font = Enum.Font.GothamBold
    self.MinimizeButton.Text = "—"
    self.MinimizeButton.TextSize = 20
    self.MinimizeButton.Parent = self.TitleBar

    -- Tabs container
    self.TabsContainer = Instance.new("Frame")
    self.TabsContainer.Size = UDim2.new(1, 0, 1, -56)
    self.TabsContainer.Position = UDim2.new(0, 0, 0, 56)
    self.TabsContainer.BackgroundTransparency = 1
    self.TabsContainer.Parent = self.Main

    -- Tab buttons row
    self.TabButtons = Instance.new("Frame")
    self.TabButtons.Size = UDim2.new(1, 0, 0, 36)
    self.TabButtons.BackgroundTransparency = 1
    self.TabButtons.Parent = self.TabsContainer
    local listLayout = Instance.new("UIListLayout", self.TabButtons)
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.Padding = UDim.new(0, 8)
    Instance.new("UIPadding", self.TabButtons).PaddingLeft = UDim.new(0, 8)

    -- Content area
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Size = UDim2.new(1, -16, 1, -40)
    self.ContentArea.Position = UDim2.new(0, 8, 0, 40)
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Parent = self.TabsContainer

    -- finalize
    self:makeDraggable(self.TitleBar)
    self:setupEvents()
    self:applyTheme(self.CurrentTheme)
    return self
end

-- Dragging
function FarmUI:makeDraggable(handle)
    local dragging, dragInput, startPos, startInputPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = self.Outline.Position
            startInputPos = input.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - startInputPos
            self.Outline.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Event wiring (close/minimize)
function FarmUI:setupEvents()
    self.CloseButton.MouseButton1Click:Connect(function()
        self.Screen:Destroy()
    end)

    self.MinimizeButton.MouseButton1Click:Connect(function()
        self.Minimized = not self.Minimized
        if self.Minimized then
            TweenService:Create(self.Outline, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(0,380,0,56)}):Play()
            self.TabsContainer.Visible = false
            self.TitleLabel.Text = "⏳ Minimized"
            self.Status = "Minimized"
        else
            TweenService:Create(self.Outline, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(0,380,0,520)}):Play()
            self.TabsContainer.Visible = true
            self.TitleLabel.Text = "🦄 Farmy " .. VERSION
            self.Status = "Open"
            -- ensure only current tab visible
            for _,child in ipairs(self.ContentArea:GetChildren()) do
                if child:IsA("ScrollingFrame") then child.Visible = (child == self.CurrentTab) end
            end
        end
    end)
end

-- Apply theme (full recolor)
function FarmUI:applyTheme(name)
    -- stop previous rainbow
    self.CurrentTheme = name
    if self.RainbowTask then
        self.RainbowTask.Running = false
        self.RainbowTask = nil
    end

    if name == "Rainbow" then
        -- set base dark background for readability
        self.Main.BackgroundColor3 = Color3.fromRGB(30,30,30)
        self.TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
        -- start rainbow loop as a task object we can control
        local tflag = { Running = true }
        self.RainbowTask = tflag
        task.spawn(function()
            while tflag.Running and self.CurrentTheme == "Rainbow" do
                local t = tick()
                local r = 0.5 + 0.5 * math.sin(t * 1.2)
                local g = 0.5 + 0.5 * math.sin(t * 1.2 + 2)
                local b = 0.5 + 0.5 * math.sin(t * 1.2 + 4)
                self.OutlineGradient.Color = ColorSequence.new(Color3.new(r,g,b), Color3.new(b,r,g))
                -- recolor tab buttons if any (keep readable)
                for _,btn in ipairs(self.TabButtons:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
                        btn.TextColor3 = Color3.fromRGB(255,255,255)
                    end
                end
                task.wait(0.045)
            end
        end)
        return
    end

    local th = Themes[name]
    if not th then return end

    -- Outline gradient & main background
    self.OutlineGradient.Color = ColorSequence.new(th.Accent1, th.Accent2)
    self.Main.BackgroundColor3 = th.Background
    self.TitleLabel.TextColor3 = th.Text

    -- Tab buttons recolor
    for _,btn in ipairs(self.TabButtons:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.BackgroundColor3 = th.Button
            btn.TextColor3 = th.Text
        end
    end

    -- Content area children recolor (simple pass)
    for _,child in ipairs(self.ContentArea:GetChildren()) do
        -- headers & labels we'll keep default text color; created elements should use theme.Text on creation
        if child:IsA("ScrollingFrame") then
            for _,g in ipairs(child:GetChildren()) do
                if g:IsA("TextLabel") or g:IsA("TextButton") then
                    if g:IsA("TextButton") then
                        g.BackgroundColor3 = th.Button
                        g.TextColor3 = th.Text
                    else
                        g.TextColor3 = th.Text
                    end
                end
            end
        end
    end
end

-- Add tab (with automatic layout + hidden scrollbar)
function FarmUI:addTab(name)
    -- create button
    local th = Themes[self.CurrentTheme]
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 1, 0)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.AutoButtonColor = false
    btn.Name = "TabButton_"..name
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    btn.Parent = self.TabButtons

    -- apply theme colors
    local curTh = Themes[self.CurrentTheme]
    if self.CurrentTheme == "Rainbow" then
        btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
    else
        btn.BackgroundColor3 = curTh.Button
        btn.TextColor3 = curTh.Text
    end

    btn.MouseEnter:Connect(function()
        local theme = Themes[self.CurrentTheme]
        if theme ~= "Rainbow" then btn.BackgroundColor3 = theme.ButtonHover end
    end)
    btn.MouseLeave:Connect(function()
        local theme = Themes[self.CurrentTheme]
        if theme ~= "Rainbow" then btn.BackgroundColor3 = theme.Button end
    end)

    -- content scrolling frame
    local content = Instance.new("ScrollingFrame")
    content.Name = name .. "Content"
    content.Size = UDim2.new(1, 0, 1, 0)
    content.CanvasSize = UDim2.new(0,0,0,0)
    content.ScrollBarThickness = 0
    content.BackgroundTransparency = 1
    content.Visible = false
    content.Parent = self.ContentArea

    -- internal layout + padding
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0,8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0,8)
    pad.PaddingLeft = UDim.new(0,12)
    pad.PaddingRight = UDim.new(0,12)
    pad.PaddingBottom = UDim.new(0,8)
    pad.Parent = content

    -- auto-update CanvasSize
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 12)
    end)

    btn.MouseButton1Click:Connect(function()
        if self.CurrentTab then self.CurrentTab.Visible = false end
        self.CurrentTab = content
        content.Visible = true
        -- ensure selection highlight (simple)
        for _,b in ipairs(self.TabButtons:GetChildren()) do
            if b:IsA("TextButton") then
                b.TextTransparency = (b == btn) and 0 or 0.35
            end
        end
    end)

    if not self.CurrentTab then
        self.CurrentTab = content
        content.Visible = true
        btn.TextTransparency = 0
    end

    return content
end

-- Small helpers for building UI elements inside tabs
function FarmUI:MakeHeader(text, parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 28)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 18
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    lbl.TextColor3 = (Themes[self.CurrentTheme] ~= "Rainbow") and Themes[self.CurrentTheme].Text or Color3.fromRGB(255,255,255)
    lbl.Parent = parent
    return lbl
end

function FarmUI:MakeLabel(text, parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    lbl.TextColor3 = (Themes[self.CurrentTheme] ~= "Rainbow") and Themes[self.CurrentTheme].Text or Color3.fromRGB(255,255,255)
    lbl.Parent = parent
    return lbl
end

function FarmUI:MakeButton(text, parent, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 36)
    btn.BackgroundTransparency = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.Text = text
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    btn.Parent = parent
    -- apply theme colors
    if Themes[self.CurrentTheme] ~= "Rainbow" then
        btn.BackgroundColor3 = Themes[self.CurrentTheme].Button
        btn.TextColor3 = Themes[self.CurrentTheme].Text
    else
        btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
    end
    btn.MouseEnter:Connect(function()
        if Themes[self.CurrentTheme] ~= "Rainbow" then btn.BackgroundColor3 = Themes[self.CurrentTheme].ButtonHover end
    end)
    btn.MouseLeave:Connect(function()
        if Themes[self.CurrentTheme] ~= "Rainbow" then btn.BackgroundColor3 = Themes[self.CurrentTheme].Button end
    end)
    if onClick then btn.MouseButton1Click:Connect(onClick) end
    return btn
end

-- Dropdown builder (renders options under the dropdown button inside the parent)
function FarmUI:MakeDropdown(options, default, parent, onSelect)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -12, 0, 36)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local base = Instance.new("TextButton")
    base.Size = UDim2.new(1, 0, 1, 0)
    base.Text = "Theme: " .. default
    base.Font = Enum.Font.GothamBold
    base.TextSize = 15
    base.Parent = container
    Instance.new("UICorner", base).CornerRadius = UDim.new(0,8)

    -- style per theme
    local applyBaseStyle = function()
        if Themes[self.CurrentTheme] ~= "Rainbow" then
            base.BackgroundColor3 = Themes[self.CurrentTheme].Button
            base.TextColor3 = Themes[self.CurrentTheme].Text
        else
            base.BackgroundColor3 = Color3.fromRGB(40,40,40)
            base.TextColor3 = Color3.fromRGB(255,255,255)
        end
    end
    applyBaseStyle()

    local open = false
    local opts = {} -- store option buttons

    local function closeOptions()
        for _,o in ipairs(opts) do
            if o and o.Parent then o:Destroy() end
        end
        opts = {}
        open = false
    end

    base.MouseButton1Click:Connect(function()
        if open then
            closeOptions()
            return
        end
        -- open options (inserted below base)
        open = true
        for i,opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Name = "DropdownOption"
            ob.Size = UDim2.new(1, -12, 0, 34)
            ob.Position = UDim2.new(0, 0, 0, 36 * i)
            ob.Text = opt
            ob.Font = Enum.Font.Gotham
            ob.TextSize = 14
            ob.Parent = parent
            Instance.new("UICorner", ob).CornerRadius = UDim.new(0,8)
            -- style
            if Themes[self.CurrentTheme] ~= "Rainbow" then
                ob.BackgroundColor3 = Themes[self.CurrentTheme].Button
                ob.TextColor3 = Themes[self.CurrentTheme].Text
            else
                ob.BackgroundColor3 = Color3.fromRGB(40,40,40)
                ob.TextColor3 = Color3.fromRGB(255,255,255)
            end
            ob.ZIndex = base.ZIndex + 1
            table.insert(opts, ob)
            ob.MouseButton1Click:Connect(function()
                base.Text = "Theme: " .. opt
                if onSelect then onSelect(opt) end
                closeOptions()
            end)
        end
    end)

    -- ensure dropdown recolors when theme changes
    self.ApplyDropdownStyle = function()
        applyBaseStyle()
        for _,o in ipairs(opts) do
            if o and o.Parent then
                if Themes[self.CurrentTheme] ~= "Rainbow" then
                    o.BackgroundColor3 = Themes[self.CurrentTheme].Button
                    o.TextColor3 = Themes[self.CurrentTheme].Text
                else
                    o.BackgroundColor3 = Color3.fromRGB(40,40,40)
                    o.TextColor3 = Color3.fromRGB(255,255,255)
                end
            end
        end
    end

    return base
end

-- ==========================
-- Example UI Initialization
-- ==========================
local ui = FarmUI.new()

-- Create tabs
local farmingTab = ui:addTab("Farming")
local settingsTab = ui:addTab("Settings")
local infoTab = ui:addTab("Info")

-- Farming tab content
ui:MakeHeader("Farm", farmingTab)
local farmLbl = ui:MakeLabel("Farming features will be added here.", farmingTab)
farmLbl.Parent = farmingTab
ui:MakeButton("Start Farming (placeholder)", farmingTab, function()
    -- placeholder click
    if DEBUG_MODE then print("Start Farming clicked") end
end).Parent = farmingTab

-- Settings tab content (Design header + dropdown)
ui:MakeHeader("Design", settingsTab)
local themeDropdown = ui:MakeDropdown({"Dark","White","PitchBlack","DarkPurple","Rainbow"}, ui.CurrentTheme, settingsTab, function(opt)
    -- suffix mismatch with names (PitchBlack vs "PitchBlack"): keep consistent
    local mapping = {
        PitchBlack = "PitchBlack",
        DarkPurple = "DarkPurple",
        White = "White",
        Dark = "Dark",
        Rainbow = "Rainbow"
    }
    local key = mapping[opt] or opt
    ui:applyTheme(key)
    -- also recolor dropdown options if any
    if ui.ApplyDropdownStyle then ui.ApplyDropdownStyle() end
end)
themeDropdown.Parent = settingsTab

-- More settings sections
ui:MakeHeader("Farm Settings", settingsTab)
local tpLabel = ui:MakeLabel("TP Speed (placeholder slider below)", settingsTab)
tpLabel.Parent = settingsTab
-- Example slider placeholder (you can replace with real slider later)
local sliderPlaceholder = Instance.new("Frame")
sliderPlaceholder.Size = UDim2.new(1, -12, 0, 10)
sliderPlaceholder.BackgroundColor3 = Color3.fromRGB(80,80,80)
Instance.new("UICorner", sliderPlaceholder).CornerRadius = UDim.new(0,6)
sliderPlaceholder.Parent = settingsTab

-- Info tab content (Stats & Changelog)
ui:MakeHeader("Stats", infoTab)
local runtimeLabel = ui:MakeLabel("Runtime: 0s", infoTab)
runtimeLabel.Parent = infoTab
local startedAtLabel = ui:MakeLabel("Started at: --:--:--", infoTab)
startedAtLabel.Parent = infoTab

ui:MakeHeader("Changelog", infoTab)
local changelogLabel = Instance.new("TextLabel")
changelogLabel.Size = UDim2.new(1, -12, 0, 120)
changelogLabel.BackgroundTransparency = 1
changelogLabel.Font = Enum.Font.Gotham
changelogLabel.TextSize = 14
changelogLabel.TextColor3 = (Themes[ui.CurrentTheme] ~= "Rainbow") and Themes[ui.CurrentTheme].Text or Color3.fromRGB(255,255,255)
changelogLabel.TextWrapped = true
changelogLabel.TextXAlignment = Enum.TextXAlignment.Left
changelogLabel.TextYAlignment = Enum.TextYAlignment.Top
changelogLabel.Parent = infoTab

-- fill changelog text
local changetext = table.concat(CHANGELOG, "\n\n")
changelogLabel.Text = changetext

-- Format helpers
local function formatTime(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- Update runtime each second
spawn(function()
    while true do
        local elapsed = tick() - startTime
        runtimeLabel.Text = "Runtime: " .. formatTime(elapsed)
        local stTime = os.date("!%H:%M:%S", math.floor(startTime)) -- UTC time; you can change to os.date() for local
        startedAtLabel.Text = "Started at (UTC): " .. stTime
        RunService.Heartbeat:Wait() -- update frequently but we'll throttle
        task.wait(1)
    end
end)

-- Ensure newly created elements get themed: we will hook the applyTheme to recolor dynamic dropdown options
-- Recolor existing elements to match initial theme
ui:applyTheme(ui.CurrentTheme)
if ui.ApplyDropdownStyle then ui.ApplyDropdownStyle() end

if DEBUG_MODE then
    print("[Farmy] UI v"..VERSION.." initialized. Status:", ui.Status)
end

-- Expose ui globally for later access (optional)
_G.FarmyUI = ui
