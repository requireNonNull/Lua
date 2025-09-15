-- 🦄 Moony Loady v1.5 (Farmy-style modern, minimized titlebar only)
local VERSION = "v1.6"
local DEBUG_MODE = true

local GamesList = {
    {
        Name = "HorseLife",
        URL_UI = "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/HorseLifeUI.lua",
        URL_KEYS = "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/HorseLifeUIKeys.lua",
        URL_VER = "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/HorseLifeUIVersion.lua",
        Version = "0.0.6"
    },
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local LoaderUI = {}
LoaderUI.__index = LoaderUI

-- Tween helper
local function tweenObject(obj, properties, duration, easingStyle, easingDir)
    local tweenInfo = TweenInfo.new(duration or 0.4, easingStyle or Enum.EasingStyle.Quad, easingDir or Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Minimize frame: hide everything except title bar
function LoaderUI:minimizeFrame()
    if self.CurrentTab then
        self.CurrentTab.Visible = false
    end
    tweenObject(self.Outline, {Size = UDim2.new(0, 360, 0, 42)}, 0.3)
end

-- Restore frame: show full content area
function LoaderUI:restoreFrame()
    tweenObject(self.Outline, {Size = UDim2.new(0, 360, 0, 220)}, 0.3)
    if self.CurrentTab then
        self.CurrentTab.Visible = true
    end
end

-- Show game tab
function LoaderUI:showGameTab(gameInfo)
    if self.CurrentTab then
        self.CurrentTab:Destroy()
    end

    local tab = Instance.new("Frame")
    tab.Size = UDim2.new(1,0,1,0)
    tab.BackgroundTransparency = 1
    tab.Parent = self.ContentArea
    self.CurrentTab = tab

    -- Header only
    local header = Instance.new("TextLabel")
    header.Text = gameInfo.Name
    header.Size = UDim2.new(1,-16,0,28)
    header.Position = UDim2.new(0,8,0,8)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextSize = 18
    header.TextColor3 = Color3.fromRGB(255,255,255)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = tab

    -- Key Input Box (empty text, modern spacing)
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(0.8,0,0,36)
    inputBox.Position = UDim2.new(0.1,0,0,64) -- more space below header
    inputBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
    inputBox.TextColor3 = Color3.fromRGB(255,255,255)
    inputBox.Text = "" -- make sure no placeholder text
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 14
    inputBox.ClearTextOnFocus = false
    Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0,6)
    inputBox.Parent = tab

    -- Check Key Button
    local checkBtn = Instance.new("TextButton")
    checkBtn.Size = UDim2.new(0.5,0,0,36)
    checkBtn.Position = UDim2.new(0.25,0,0,120) -- more spacing below input
    checkBtn.Text = "Check Key"
    checkBtn.Font = Enum.Font.GothamBold
    checkBtn.TextSize = 14
    checkBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    checkBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", checkBtn).CornerRadius = UDim.new(0,6)
    checkBtn.Parent = tab

    -- Key checking logic
    checkBtn.MouseButton1Click:Connect(function()
        checkBtn.Active = false
        inputBox.Active = false

        -- Minimize before scanning
        self:minimizeFrame()
        self.TitleLabel.Text = "🔄 Scanning Key..."
        task.wait(3) -- static delay

        task.spawn(function()
            local keySuccess, keysRaw = pcall(function() return game:HttpGet(gameInfo.URL_KEYS) end)
            local verSuccess, latestVer = pcall(function() return game:HttpGet(gameInfo.URL_VER) end)
            local key = inputBox.Text

            if keySuccess and keysRaw then
                keysRaw = keysRaw:gsub("return",""):gsub("{",""):gsub("}",""):gsub("\"","")
                local keysList = {}
                for k in keysRaw:gmatch("[^,]+") do table.insert(keysList,k:match("^%s*(.-)%s*$")) end

                if table.find(keysList,key) then
                    if verSuccess and latestVer then
                        latestVer = latestVer:match("%d+%.%d+%.%d+")
                        if latestVer ~= VERSION then
                            self.TitleLabel.Text = "⚠️ Update available ("..latestVer..")"
                            wait(1)
                        end
                    end

                    self.TitleLabel.Text = "✅ Access Granted"
                    wait(0.5)
                    self.Screen:Destroy()
                    local uiCode = game:HttpGet(gameInfo.URL_UI)
                    loadstring(uiCode)()
                else
                    self.TitleLabel.Text = "❌ Access Denied"
                    self:restoreFrame()
                    checkBtn.Active = true
                    inputBox.Active = true
                end
            else
                self.TitleLabel.Text = "⚠️ Failed to fetch keys"
                self:restoreFrame()
                checkBtn.Active = true
                inputBox.Active = true
            end
        end)
    end)
end

-- ==========================
function LoaderUI.new()
    local self = setmetatable({}, LoaderUI)

    -- Root
    self.Screen = Instance.new("ScreenGui")
    self.Screen.Name = "MoonyLoadyUI"
    self.Screen.ResetOnSpawn = false
    self.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.Screen.Parent = game:GetService("CoreGui")

    -- Outline
    self.Outline = Instance.new("Frame")
    self.Outline.Size = UDim2.new(0, 360, 0, 220)
    self.Outline.Position = UDim2.new(0.5,-180,0.5,-110)
    self.Outline.BorderSizePixel = 0
    self.Outline.Parent = self.Screen
    Instance.new("UICorner", self.Outline).CornerRadius = UDim.new(0,18)

    self.OutlineGradient = Instance.new("UIGradient")
    self.OutlineGradient.Rotation = 45
    self.OutlineGradient.Parent = self.Outline

    -- Main
    self.Main = Instance.new("Frame")
    self.Main.Size = UDim2.new(1,-8,1,-8)
    self.Main.Position = UDim2.new(0,4,0,4)
    self.Main.BorderSizePixel = 0
    self.Main.BackgroundColor3 = Color3.fromRGB(0,0,0)
    self.Main.Parent = self.Outline
    Instance.new("UICorner", self.Main).CornerRadius = UDim.new(0,14)

    -- Title Bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Size = UDim2.new(1,0,0,42)
    self.TitleBar.Position = UDim2.new(0,0,0,0)
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.BackgroundColor3 = Color3.fromRGB(0,0,0)
    self.TitleBar.Parent = self.Main
    Instance.new("UICorner", self.TitleBar).CornerRadius = UDim.new(0,14)

    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Size = UDim2.new(1,-28,1,0)
    self.TitleLabel.Position = UDim2.new(0,12,0,0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Font = Enum.Font.GothamBold
    self.TitleLabel.Text = "🦄 Moony Loady"
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.TextSize = 18
    self.TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    self.TitleLabel.Parent = self.TitleBar

    -- Close Button
    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Size = UDim2.new(0,20,0,20)
    self.CloseButton.Position = UDim2.new(1,-28,0.5,-10)
    self.CloseButton.BackgroundTransparency = 1
    self.CloseButton.Font = Enum.Font.GothamBold
    self.CloseButton.Text = "X"
    self.CloseButton.TextSize = 18
    self.CloseButton.TextColor3 = Color3.fromRGB(255,255,255)
    self.CloseButton.Parent = self.TitleBar
    self.CloseButton.MouseButton1Click:Connect(function() self.Screen:Destroy() end)

    -- Tabs
    self.TabsContainer = Instance.new("Frame")
    self.TabsContainer.Size = UDim2.new(1,0,1,-42)
    self.TabsContainer.Position = UDim2.new(0,0,0,42)
    self.TabsContainer.BackgroundTransparency = 1
    self.TabsContainer.Parent = self.Main

    self.TabButtons = Instance.new("Frame")
    self.TabButtons.Size = UDim2.new(1,0,0,36)
    self.TabButtons.Position = UDim2.new(0,0,0,0)
    self.TabButtons.BackgroundTransparency = 1
    self.TabButtons.Parent = self.TabsContainer
    local layout = Instance.new("UIListLayout", self.TabButtons)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0,8)
    Instance.new("UIPadding", self.TabButtons).PaddingLeft = UDim.new(0,8)

    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Size = UDim2.new(1,-16,1,-40)
    self.ContentArea.Position = UDim2.new(0,8,0,40)
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Parent = self.TabsContainer

    -- Games Tab
    local gamesBtn = Instance.new("TextButton")
    gamesBtn.Size = UDim2.new(0,100,1,0)
    gamesBtn.Text = "Games"
    gamesBtn.Font = Enum.Font.GothamBold
    gamesBtn.TextSize = 14
    gamesBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    gamesBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", gamesBtn).CornerRadius = UDim.new(0,8)
    gamesBtn.Parent = self.TabButtons

    local gamesContent = Instance.new("Frame")
    gamesContent.Size = UDim2.new(1,0,1,0)
    gamesContent.BackgroundTransparency = 1
    gamesContent.Visible = true
    gamesContent.Parent = self.ContentArea
    self.CurrentTab = gamesContent

    for _, gameInfo in ipairs(GamesList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.6,0,0,36)
        btn.Position = UDim2.new(0.2,0,0,(_-1)*42)
        btn.Text = gameInfo.Name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
        btn.Parent = gamesContent

        btn.MouseButton1Click:Connect(function()
            tweenObject(gamesContent, {BackgroundTransparency = 1}, 0.3).Completed:Wait()
            self:showGameTab(gameInfo)
        end)
    end

    -- Rainbow Gradient
    task.spawn(function()
        while self.Screen.Parent do
            local t = tick()
            local r = 0.5 + 0.5*math.sin(t)
            local g = 0.5 + 0.5*math.sin(t+2)
            local b = 0.5 + 0.5*math.sin(t+4)
            self.OutlineGradient.Color = ColorSequence.new(Color3.new(r,g,b), Color3.new(b,r,g))
            task.wait(0.05)
        end
    end)

    return self
end

-- Init loader
local loader = LoaderUI.new()
if DEBUG_MODE then
    print("[MoonyLoady "..VERSION.."] Loader initialized with "..#GamesList.." game(s)")
end
