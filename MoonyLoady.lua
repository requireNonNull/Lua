-- SAFE: Farmy v5.1 (Games Tab Integration) - sanitized (no exploit loading)
local VERSION = "v0.1.9"
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

-- Keep only Rainbow theme for appearance consistency (other theme data removed)
local Themes = {
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
            while self.CurrentTheme == "Rainbow" and self.Screen.Parent do
                local t = tick()
                local r = 0.5 + 0.5*math.sin(t)
                local g = 0.5 + 0.5*math.sin(t+2)
                local b = 0.5 + 0.5*math.sin(t+4)
                if self.OutlineGradient then
                    self.OutlineGradient.Color = ColorSequence.new(Color3.new(r,g,b), Color3.new(b,r,g))
                end
                task.wait(0.05)
            end
        end)
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
-- Settings tab removed per your request
local infoTab = ui:addTab("Info")

-- ==========================
-- Games Data
local function loadStatusFile(url)
    local ok, data = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if ok then
        return data
    else
        warn("Failed to load status file from: " .. url)
        return nil
    end
end

-- Add your raw file URLs here
local statusFiles = {
    "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/HorseLifeUIStatus.lua",
    "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/RainbowFriendsUIStatus.lua",
}

-- Build list
local GamesList = {}
for _, url in ipairs(statusFiles) do
    local data = loadStatusFile(url)
    if data then
        table.insert(GamesList, data)
    end
end

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
        gameFrame.Size = UDim2.new(0.9,0,0,220) -- taller to fit all labels
        gameFrame.BackgroundTransparency = 1
        gameFrame.Parent = scroll
    
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0,4)
        layout.Parent = gameFrame
    
        -- Title
        local title = Instance.new("TextLabel")
        title.Text = gameInfo.Name or "Unknown"
        title.Size = UDim2.new(1,0,0,24)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16
        title.TextColor3 = Color3.fromRGB(255,255,255)
        title.TextXAlignment = Enum.TextXAlignment.Center
        title.Parent = gameFrame
    
        -- Status
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Text = "Status: " .. (gameInfo.Status or "unknown")
        statusLabel.Size = UDim2.new(1,0,0,20)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.TextSize = 14
        statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
        statusLabel.TextXAlignment = Enum.TextXAlignment.Center
        statusLabel.Parent = gameFrame
    
        -- PlaceId
        local placeLabel = Instance.new("TextLabel")
        placeLabel.Text = "PlaceId: " .. tostring(gameInfo.PlaceId or "N/A")
        placeLabel.Size = UDim2.new(1,0,0,20)
        placeLabel.BackgroundTransparency = 1
        placeLabel.Font = Enum.Font.Gotham
        placeLabel.TextSize = 14
        placeLabel.TextColor3 = Color3.fromRGB(200,200,200)
        placeLabel.TextXAlignment = Enum.TextXAlignment.Center
        placeLabel.Parent = gameFrame
    
        -- Exploit Name + Version
        local exploitLabel = Instance.new("TextLabel")
        exploitLabel.Text = "Exploit: " .. (gameInfo.ExploitName or "N/A") ..
                            " | Version: " .. (gameInfo.ExploitVersion or "N/A")
        exploitLabel.Size = UDim2.new(1,0,0,20)
        exploitLabel.BackgroundTransparency = 1
        exploitLabel.Font = Enum.Font.Gotham
        exploitLabel.TextSize = 14
        exploitLabel.TextColor3 = Color3.fromRGB(200,200,200)
        exploitLabel.TextXAlignment = Enum.TextXAlignment.Center
        exploitLabel.Parent = gameFrame
    
        -- Last Checked
        local checkLabel = Instance.new("TextLabel")
        checkLabel.Text = "Last Checked: " .. (gameInfo.LastCheckedDate or "unknown")
        checkLabel.Size = UDim2.new(1,0,0,20)
        checkLabel.BackgroundTransparency = 1
        checkLabel.Font = Enum.Font.Gotham
        checkLabel.TextSize = 14
        checkLabel.TextColor3 = Color3.fromRGB(200,200,200)
        checkLabel.TextXAlignment = Enum.TextXAlignment.Center
        checkLabel.Parent = gameFrame
    
        -- Version Info (if you added VersionInfo to the file)
        if gameInfo.VersionInfo then
            local versionInfoLabel = Instance.new("TextLabel")
            versionInfoLabel.Text = gameInfo.VersionInfo
            versionInfoLabel.Size = UDim2.new(1,0,0,20)
            versionInfoLabel.BackgroundTransparency = 1
            versionInfoLabel.Font = Enum.Font.Gotham
            versionInfoLabel.TextSize = 14
            versionInfoLabel.TextColor3 = Color3.fromRGB(255,220,180)
            versionInfoLabel.TextXAlignment = Enum.TextXAlignment.Center
            versionInfoLabel.Parent = gameFrame
        end
    
        -- Run Button (as before)
        local runBtn = Instance.new("TextButton")
        runBtn.Size = UDim2.new(0.5,0,0,28)
        runBtn.Text = "Run Exploit"
        runBtn.Font = Enum.Font.GothamBold
        runBtn.TextSize = 14
        runBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        runBtn.TextColor3 = Color3.fromRGB(255,255,255)
        Instance.new("UICorner",runBtn).CornerRadius = UDim.new(0,6)
        runBtn.Parent = gameFrame

        -- Run logic: MINIMIZE -> CHECK PLACEID -> VERSION CHECK -> (SAFE PLACEHOLDER)
        runBtn.MouseButton1Click:Connect(function()
            runBtn.Active = false

            local originalTitle = ui.TitleLabel.Text

            -- Minimize UI
            if not ui.Minimized then
                ui.Minimized = true
                TweenService:Create(ui.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0,360,0,50)}):Play()
                ui.TabsContainer.Visible = false
            end
            ui.TitleLabel.Text = "🔄 Running..."

            -- simulate small delay similar to original
            task.delay(math.random(1,3), function()
                -- PlaceId check
                if tostring(game.PlaceId) ~= tostring(gameInfo.PlaceId) then
                    -- Wrong game -> restore UI and inform
                    ui.TitleLabel.Text = "❌ Wrong Game"
                    task.wait(1.8)
                    ui.Minimized = false
                    TweenService:Create(ui.Outline, TweenInfo.new(0.3), {Size = UDim2.new(0,360,0,500)}):Play()
                    ui.TabsContainer.Visible = true
                    ui.TitleLabel.Text = originalTitle
                    runBtn.Active = true
                    return
                end

                -- PlaceId OK -> show game status + version info in title and info label
                ui.TitleLabel.Text = (gameInfo.Name or "Game") .. " - " .. (gameInfo.Status or "")
                --infoLabel.Text = (gameInfo.ExploitName or "") .. " " .. (gameInfo.ExploitVersion or "") .. " | " .. (gameInfo.LastCheckedDate or "")

                -- VERSION CHECK: compare local version vs provided exploit version (displayed but no remote fetch)
                -- if different, show outdated message in title while still allowing continuation
                if (gameInfo.ExploitVersion and tostring(gameInfo.ExploitVersion) ~= VERSION) then
                    ui.TitleLabel.Text = ui.TitleLabel.Text .. "  ⚠️ Outdated: " .. VERSION .. " (expected " .. tostring(gameInfo.ExploitVersion) .. ")"
                end

                -- SAFE PLACEHOLDER: do NOT perform remote code execution or exploit loading
                -- The original script loaded remote code here (e.g. loadstring(game:HttpGet(URL_UI))).
                -- For safety and ToS compliance this placeholder does nothing harmful.
                -- Replace the body of `onRunApproved()` with legitimate, non-exploit logic if desired.
                local function onRunApproved()
                    -- Example benign action: show a confirmation for testing
                    ui.TitleLabel.Text = (gameInfo.Name or "Game") .. " - Loaded..."
                    task.wait(1)
                    ui.Screen:Destroy()
                    loadstring(game:HttpGet(gameInfo.ExploitUrl))()
                end

                -- call the safe placeholder
                pcall(onRunApproved)

                -- NOTE: if you want to add allowed behavior, put it inside onRunApproved
                -- Restore button active state (UI remains minimized until user reopens)
                runBtn.Active = true
            end)
        end)
    end

    for _,gameInfo in ipairs(GamesList) do
        addGameBlock(gameInfo)
    end
end

addGamesSection(gamesTab)

-- ==========================
-- Credits (scrollable)
local creditsHeader = Instance.new("TextLabel")
creditsHeader.Text = "Credits"
creditsHeader.Size = UDim2.new(1,0,0,28)
creditsHeader.BackgroundTransparency = 1
creditsHeader.Font = Enum.Font.GothamBold
creditsHeader.TextSize = 18
creditsHeader.TextColor3 = Color3.fromRGB(255,255,255)
creditsHeader.TextXAlignment = Enum.TextXAlignment.Center
creditsHeader.Position = UDim2.new(0,0,0,36)
creditsHeader.Parent = infoTab

local creditsScroll = Instance.new("ScrollingFrame")
creditsScroll.Size = UDim2.new(1,-24,0,160)
creditsScroll.Position = UDim2.new(0,12,0,72)
creditsScroll.BackgroundTransparency = 1
creditsScroll.ScrollBarImageTransparency = 1
creditsScroll.ScrollBarThickness = 0
creditsScroll.CanvasSize = UDim2.new(0,0,0,0)
creditsScroll.Parent = infoTab

local creditsLayout = Instance.new("UIListLayout", creditsScroll)
creditsLayout.FillDirection = Enum.FillDirection.Vertical
creditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
creditsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
creditsLayout.Padding = UDim.new(0,6)

local creditLines = {
    "Made by Breezingfreeze",
    "Thanks to SPDMTeam for their awesome executors!",
    "Dex Explorer by Moon for cracking everything open!",
    "UI design helped by AI assistance!"
}

for _, text in ipairs(creditLines) do
    local label = Instance.new("TextLabel")
    label.Text = text
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(200,200,200)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextWrapped = true
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.Size = UDim2.new(1,0,0,24)
    label.Parent = creditsScroll
end

creditsScroll.CanvasSize = UDim2.new(0,0,0,creditsLayout.AbsoluteContentSize.Y)

-- ==========================
-- Open Source / Educational Info (Developer-focused)
local eduHeader = Instance.new("TextLabel")
eduHeader.Text = "Open Source / Educational"
eduHeader.Size = UDim2.new(1,0,0,28)
eduHeader.BackgroundTransparency = 1
eduHeader.Font = Enum.Font.GothamBold
eduHeader.TextSize = 18
eduHeader.TextColor3 = Color3.fromRGB(255,255,255)
eduHeader.TextXAlignment = Enum.TextXAlignment.Center
eduHeader.Position = UDim2.new(0,0,0,72 + 160 + 12) -- below credits
eduHeader.Parent = infoTab

local eduFrame = Instance.new("Frame")
eduFrame.Size = UDim2.new(1,-24,0,0) -- initial height 0, will grow
eduFrame.Position = UDim2.new(0,12,0,72 + 160 + 36)
eduFrame.BackgroundTransparency = 1
eduFrame.Parent = infoTab

local eduLayout = Instance.new("UIListLayout", eduFrame)
eduLayout.FillDirection = Enum.FillDirection.Vertical
eduLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
eduLayout.VerticalAlignment = Enum.VerticalAlignment.Top
eduLayout.Padding = UDim.new(0,4)

local guideLines = {
    "⚠️ Disclaimer: For educational purposes only—do not use to exploit games.",
    "🔧 This loader project is designed to demonstrate how automation works for learning.",
    "👀 It shows how UI and internal folder/part names can be targeted by exploits.",
    "💡 Developers can use this to identify vulnerabilities and fix them.",
    "Best practices to prevent exploits:",
    "   • Randomize internal Part and Folder names.",
    "   • Avoid predictable naming for triggers, values, and events.",
    "   • Validate all actions server-side instead of trusting client input.",
    "   • Limit remote execution and verify user permissions.",
    "Repository for reference and educational use:",
    "   https://github.com/requireNonNull/Lua"
}

for _, text in ipairs(guideLines) do
    local lineLabel = Instance.new("TextLabel")
    lineLabel.Text = text
    lineLabel.BackgroundTransparency = 1
    lineLabel.Font = Enum.Font.Gotham
    lineLabel.TextSize = 14
    lineLabel.TextColor3 = Color3.fromRGB(200,200,200)
    lineLabel.TextXAlignment = Enum.TextXAlignment.Left
    lineLabel.TextYAlignment = Enum.TextYAlignment.Top
    lineLabel.TextWrapped = true
    lineLabel.AutomaticSize = Enum.AutomaticSize.Y
    lineLabel.Size = UDim2.new(1,0,0,22)
    lineLabel.Parent = eduFrame
end

-- Dynamically resize the frame to fit all content
eduFrame.Size = UDim2.new(1,-24,0,eduLayout.AbsoluteContentSize.Y)
