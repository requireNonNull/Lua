-- 🦄 Farmy v5.1 (Games Tab Integration)
local VERSION = "v0.1.1"
local DEBUG_MODE = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")
local player = Players.LocalPlayer

-- ==========================
-- UI Class
local FarmUI = {}
FarmUI.__index = FarmUI
FarmUI.Status = "Open"

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

    -- Root
    self.Screen = Instance.new("ScreenGui")
    self.Screen.Name = "FarmUI"
    self.Screen.ResetOnSpawn = false
    self.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.Screen.Parent = game:GetService("CoreGui")

    -- Outline
    self.Outline = Instance.new("Frame")
    self.Outline.Size = UDim2.new(0,360,0,500)
    self.Outline.Position = UDim2.new(0.5,-180,0.5,-250)
    self.Outline.BorderSizePixel = 0
    self.Outline.Parent = self.Screen
    Instance.new("UICorner", self.Outline).CornerRadius = UDim.new(0,18)
    self.OutlineGradient = Instance.new("UIGradient")
    self.OutlineGradient.Rotation = 45
    self.OutlineGradient.Parent = self.Outline

    -- Main frame
    self.Main = Instance.new("Frame")
    self.Main.Size = UDim2.new(1,-8,1,-8)
    self.Main.Position = UDim2.new(0,4,0,4)
    self.Main.BorderSizePixel = 0
    self.Main.BackgroundColor3 = Color3.fromRGB(0,0,0)
    self.Main.Parent = self.Outline
    Instance.new("UICorner", self.Main).CornerRadius = UDim.new(0,14)

    -- Title bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Size = UDim2.new(1,0,0,42)
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.BackgroundColor3 = Color3.fromRGB(0,0,0)
    self.TitleBar.Parent = self.Main
    Instance.new("UICorner", self.TitleBar).CornerRadius = UDim.new(0,14)

    -- Title Label
    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Size = UDim2.new(1,-80,1,0)
    self.TitleLabel.Position = UDim2.new(0,12,0,0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Font = Enum.Font.GothamBold
    self.TitleLabel.Text = "🌑 Moony Loady "..VERSION
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.TextSize = 18
    self.TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    self.TitleLabel.Parent = self.TitleBar

    -- Close & Minimize
    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Size = UDim2.new(0,20,0,20)
    self.CloseButton.Position = UDim2.new(1,-28,0.5,-10)
    self.CloseButton.BackgroundTransparency = 1
    self.CloseButton.Font = Enum.Font.GothamBold
    self.CloseButton.Text = "X"
    self.CloseButton.TextSize = 18
    self.CloseButton.TextColor3 = Color3.fromRGB(255,255,255)
    self.CloseButton.Parent = self.TitleBar

    self.MinimizeButton = Instance.new("TextButton")
    self.MinimizeButton.Size = UDim2.new(0,20,0,20)
    self.MinimizeButton.Position = UDim2.new(1,-52,0.5,-10)
    self.MinimizeButton.BackgroundTransparency = 1
    self.MinimizeButton.Font = Enum.Font.GothamBold
    self.MinimizeButton.Text = "—"
    self.MinimizeButton.TextSize = 20
    self.MinimizeButton.TextColor3 = Color3.fromRGB(255,255,255)
    self.MinimizeButton.Parent = self.TitleBar

    -- Tabs
    self.TabsContainer = Instance.new("Frame")
    self.TabsContainer.Size = UDim2.new(1,0,1,-50)
    self.TabsContainer.Position = UDim2.new(0,0,0,50)
    self.TabsContainer.BackgroundTransparency = 1
    self.TabsContainer.Parent = self.Main

    self.TabButtons = Instance.new("Frame")
    self.TabButtons.Size = UDim2.new(1,0,0,36)
    self.TabButtons.BackgroundTransparency = 1
    self.TabButtons.Parent = self.TabsContainer
    local layout = Instance.new("UIListLayout",self.TabButtons)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0,8)
    Instance.new("UIPadding",self.TabButtons).PaddingLeft = UDim.new(0,8)

    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Size = UDim2.new(1,-16,1,-40)
    self.ContentArea.Position = UDim2.new(0,8,0,40)
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Parent = self.TabsContainer

    self.CurrentTab = nil
    self.CurrentTheme = nil
    self.Minimized = false

    -- Init
    self:applyTheme("Rainbow")
    self:makeDraggable(self.TitleBar)
    self:setupEvents()
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
            self.Outline.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
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
            self.TitleLabel.Text = "🌑 Moony Loady "..VERSION
        else
            TweenService:Create(self.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0,360,0,500)}):Play()
            self.TabsContainer.Visible = true
            self.TitleLabel.Text = "🌑 Moony Loady "..VERSION
            for _,tab in ipairs(self.ContentArea:GetChildren()) do
                if tab:IsA("ScrollingFrame") then
                    tab.Visible = (tab == self.CurrentTab)
                end
            end
        end
    end)
end

-- ==========================
-- Theme
function FarmUI:applyTheme(name)
    self.CurrentTheme = name
    self.Main.BackgroundColor3 = Color3.fromRGB(0,0,0)
    self.TitleBar.BackgroundColor3 = Color3.fromRGB(0,0,0)
    
    if name == "Rainbow" then
        task.spawn(function()
            while self.CurrentTheme == "Rainbow" do
                local t = tick()
                local r = 0.5 + 0.5*math.sin(t)
                local g = 0.5 + 0.5*math.sin(t+2)
                local b = 0.5 + 0.5*math.sin(t+4)
                self.OutlineGradient.Color = ColorSequence.new(Color3.new(r,g,b), Color3.new(b,r,g))
                task.wait(0.05)
            end
        end)
    else
        local th = Themes[name]
        self.OutlineGradient.Color = ColorSequence.new(th.Accent1,th.Accent2)
    end
end

-- ==========================
-- Tabs
function FarmUI:addTab(name)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0,100,1,0)
    button.Text = name
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.BackgroundColor3 = Color3.fromRGB(30,30,30)
    button.TextColor3 = Color3.fromRGB(255,255,255)
    button.AutoButtonColor = false
    Instance.new("UICorner",button).CornerRadius = UDim.new(0,8)
    button.Parent = self.TabButtons

    local content = Instance.new("ScrollingFrame")
    content.Name = name.."Content"
    content.Size = UDim2.new(1,0,1,0)
    content.CanvasSize = UDim2.new(0,0,0,0)
    content.ScrollBarThickness = 4
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
        content.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+16)
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
local gamesTab = ui:addTab("Games")
local settingsTab = ui:addTab("Settings")
local infoTab = ui:addTab("Info")

-- ==========================
-- Settings Tab: Theme Buttons
ui.ThemeButtons = {}
local themesList = {"Dark","White","PitchBlack","DarkPurple","Rainbow"}
for i,themeName in ipairs(themesList) do
    local btn = Instance.new("TextButton")
    btn.Text = themeName
    btn.Size = UDim2.new(1,-16,0,36)
    btn.Position = UDim2.new(0,8,0,(i-1)*42)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,8)
    btn.Parent = settingsTab
    ui.ThemeButtons[themeName] = btn

    btn.MouseButton1Click:Connect(function()
        ui:applyTheme(themeName)
    end)
end
ui.ThemeButtons[ui.CurrentTheme].BackgroundTransparency = 0.6

-- ==========================
-- Games Data
local GamesList = {
    {
        Name = "HorseLife",
        URL_KEYS = "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/HorseLifeUIKeys.lua",
        URL_UI  = "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/HorseLifeUI.lua",
        URL_VER = "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/HorseLifeUIVersion.lua",
        Status  = "✅ Exploit Working",
        StatusFile = "https://raw.githubusercontent.com/requireNonNull/Lua/main/HorseLifeUIStatus.lua"
    },
    {
        Name = "PetSimulator",
        URL_KEYS = "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/PetSimKeys.lua",
        URL_UI  = "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/PetSimUI.lua",
        URL_VER = "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/PetSimVersion.lua",
        Status  = "⚠️ Limited",
        StatusFile = "https://raw.githubusercontent.com/requireNonNull/Lua/main/PetSimUIStatus.lua"
    },
}

local function daysAgo(dateString)
    local y,m,d = dateString:match("(%d+)-(%d+)-(%d+)")
    if not y then return "unknown" end
    
    local lastDate = os.time({
        year = tonumber(y),
        month = tonumber(m),
        day = tonumber(d),
        hour = 12 -- Mitte des Tages, vermeidet Zeitzonen-/DST-Bugs
    })
    local now = os.time()
    local days = math.floor((now - lastDate) / (24*60*60))
    if days < 0 then days = 0 end
    
    if days == 0 then
        return "today"
    elseif days == 1 then
        return "1 day ago"
    else
        return days.." days ago"
    end
end

-- Add Games to Tab (Dynamic CanvasSize + Scan Simulation)
local function addGamesSection(parent)
    local header = Instance.new("TextLabel")
    header.Text = "Games"
    header.Size = UDim2.new(1,0,0,28)
    header.Position = UDim2.new(0,0,0,8)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextSize = 18
    header.TextColor3 = Color3.fromRGB(255,255,255)
    header.TextXAlignment = Enum.TextXAlignment.Center
    header.Parent = parent

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,-40)
    scroll.Position = UDim2.new(0,0,0,36)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 0
    scroll.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,24) -- more vertical padding
    layout.Parent = scroll

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0,12)
    padding.PaddingBottom = UDim.new(0,12)
    padding.PaddingLeft = UDim.new(0,12)
    padding.PaddingRight = UDim.new(0,12)
    padding.Parent = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 16)
    end)

    local function addGameBlock(gameInfo)
    local gameFrame = Instance.new("Frame")
    gameFrame.Size = UDim2.new(0.9,0,0,180)
    gameFrame.BackgroundTransparency = 1
    gameFrame.Parent = scroll

    -- Layout für automatische Anordnung
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,8) -- Abstand zwischen Elementen
    layout.Parent = gameFrame

    -- Titel
    local title = Instance.new("TextLabel")
    title.Text = gameInfo.Name
    title.Size = UDim2.new(1,0,0,28)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = gameFrame

    -- Info Label
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Text = "Fetching status..."
    infoLabel.Size = UDim2.new(1,0,0,36)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 14
    infoLabel.TextColor3 = Color3.fromRGB(200,200,200)
    infoLabel.TextXAlignment = Enum.TextXAlignment.Center
    infoLabel.TextYAlignment = Enum.TextYAlignment.Center
    infoLabel.TextWrapped = true
    infoLabel.Parent = gameFrame

    -- Key Box
    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(0.8,0,0,36)
    keyBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
    keyBox.TextColor3 = Color3.fromRGB(255,255,255)
    keyBox.Text = ""
    keyBox.PlaceholderText = "Enter key here..."
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextSize = 14
    keyBox.ClearTextOnFocus = false
    Instance.new("UICorner",keyBox).CornerRadius = UDim.new(0,6)
    keyBox.Parent = gameFrame

    -- Check Button
    local checkBtn = Instance.new("TextButton")
    checkBtn.Size = UDim2.new(0.5,0,0,36)
    checkBtn.Text = "Check Key"
    checkBtn.Font = Enum.Font.GothamBold
    checkBtn.TextSize = 14
    checkBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    checkBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner",checkBtn).CornerRadius = UDim.new(0,6)
    checkBtn.Parent = gameFrame

    -- Fetch status von GitHub
    task.spawn(function()
        local ok, statusData = pcall(function()
            return loadstring(game:HttpGet(gameInfo.StatusFile))()
        end)
        if ok and statusData then
            infoLabel.Text = statusData.Status.." \n>> Last checked "..daysAgo(statusData.LastCheckedDate)
        else
            infoLabel.Text = "<-> Status unavailable <->"
        end
    end)

    -- Key Check Logic
    checkBtn.MouseButton1Click:Connect(function()
        checkBtn.Active = false
        keyBox.Active = false
        local originalTitle = ui.TitleLabel.Text

        -- Minimize UI
        if not ui.Minimized then
            ui.Minimized = true
            TweenService:Create(ui.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0,360,0,50)}):Play()
            ui.TabsContainer.Visible = false
        end
        ui.TitleLabel.Text = "🔄 Scanning Key..."

        task.delay(math.random(2,6), function()
            local key = keyBox.Text
            local ok, keys = pcall(function()
                return loadstring(game:HttpGet(gameInfo.URL_KEYS))()
            end)

            if ok and table.find(keys,key) then
                ui.TitleLabel.Text = "✅ Access Granted"
                task.wait(1)
                ui.Screen:Destroy()
                loadstring(game:HttpGet(gameInfo.URL_UI))()
            else
                ui.TitleLabel.Text = "❌ Access Denied"
                task.wait(2)
                -- Restore window
                ui.Minimized = false
                TweenService:Create(ui.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0,360,0,500)}):Play()
                ui.TabsContainer.Visible = true
                ui.TitleLabel.Text = originalTitle
                checkBtn.Active = true
                keyBox.Active = true
            end
        end)
    end)
end


    for _,gameInfo in ipairs(GamesList) do
        addGameBlock(gameInfo)
    end
end

addGamesSection(gamesTab)
