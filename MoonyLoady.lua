-- 🦄 Moony Loady v1.2 (Advanced Multi-Game Loader)
local VERSION = "v1.2"
local DEBUG_MODE = true

-- ==========================
local GamesList = {
    {
        Name = "HorseLife",
        URL_UI = "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/HorseLifeUI.lua",
        URL_KEYS = "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/HorseLifeUIKeys.lua",
        URL_VER = "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/HorseLifeUIVersion.lua",
        Version = "0.0.6"
    },
    -- Add more games here
}

-- Roblox services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- ==========================
local function isOutdated(current, latest)
    local c1,c2,c3 = current:match("(%d+)%.(%d+)%.(%d+)")
    local l1,l2,l3 = latest:match("(%d+)%.(%d+)%.(%d+)")
    c1,c2,c3 = tonumber(c1), tonumber(c2), tonumber(c3)
    l1,l2,l3 = tonumber(l1), tonumber(l2), tonumber(l3)
    if l1 > c1 then return true end
    if l1 == c1 and l2 > c2 then return true end
    if l1 == c1 and l2 == c2 and l3 > c3 then return true end
    return false
end

-- ==========================
local LoaderUI = {}
LoaderUI.__index = LoaderUI

function LoaderUI.new()
    local self = setmetatable({}, LoaderUI)

    -- ==========================
    -- Root ScreenGui
    self.Screen = Instance.new("ScreenGui")
    self.Screen.Name = "MoonyLoadyUI"
    self.Screen.ResetOnSpawn = false
    self.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.Screen.Parent = game:GetService("CoreGui")

    -- Outline
    self.Outline = Instance.new("Frame")
    self.Outline.Size = UDim2.new(0, 360, 0, 220)
    self.Outline.Position = UDim2.new(0.5, -180, 0.5, -110)
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
    self.Main.BackgroundColor3 = Color3.fromRGB(0,0,0)
    self.Main.Parent = self.Outline
    Instance.new("UICorner", self.Main).CornerRadius = UDim.new(0, 14)

    -- Title Bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Size = UDim2.new(1, 0, 0, 42)
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Parent = self.Main
    Instance.new("UICorner", self.TitleBar).CornerRadius = UDim.new(0,14)

    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Size = UDim2.new(1, -28, 1, 0)
    self.TitleLabel.Position = UDim2.new(0,12,0,0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Font = Enum.Font.GothamBold
    self.TitleLabel.Text = "🦄 Moony Loady"
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.TextSize = 18
    self.TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    self.TitleLabel.Parent = self.TitleBar

    -- Close button
    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Size = UDim2.new(0,20,0,20)
    self.CloseButton.Position = UDim2.new(1,-28,0.5,-10)
    self.CloseButton.BackgroundTransparency = 1
    self.CloseButton.Font = Enum.Font.GothamBold
    self.CloseButton.Text = "X"
    self.CloseButton.TextSize = 18
    self.CloseButton.TextColor3 = Color3.fromRGB(255,255,255)
    self.CloseButton.Parent = self.TitleBar

    -- Tabs container
    self.TabsContainer = Instance.new("Frame")
    self.TabsContainer.Size = UDim2.new(1,0,1,-50)
    self.TabsContainer.Position = UDim2.new(0,0,0,50)
    self.TabsContainer.BackgroundTransparency = 1
    self.TabsContainer.Parent = self.Main

    -- Tab buttons row
    self.TabButtons = Instance.new("Frame")
    self.TabButtons.Size = UDim2.new(1,0,0,36)
    self.TabButtons.BackgroundTransparency = 1
    self.TabButtons.Parent = self.TabsContainer
    local layoutButtons = Instance.new("UIListLayout", self.TabButtons)
    layoutButtons.FillDirection = Enum.FillDirection.Horizontal
    layoutButtons.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layoutButtons.Padding = UDim.new(0,8)
    Instance.new("UIPadding", self.TabButtons).PaddingLeft = UDim.new(0,8)

    -- Content Area
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Size = UDim2.new(1,-16,1,-40)
    self.ContentArea.Position = UDim2.new(0,8,0,40)
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Parent = self.TabsContainer

    -- ==========================
    -- Functions to build tabs
    local function showGamesTab()
        self.TitleLabel.Text = "Games"
        self.TabButtons:ClearAllChildren()

        -- Re-add close button
        self.CloseButton.Parent = self.TabButtons

        -- Scrollable list
        local gamesContent = Instance.new("ScrollingFrame")
        gamesContent.Size = UDim2.new(1,0,1,0)
        gamesContent.BackgroundTransparency = 1
        gamesContent.CanvasSize = UDim2.new(0,0,0,0)
        gamesContent.ScrollBarThickness = 6
        gamesContent.Parent = self.ContentArea
        self.CurrentTab = gamesContent

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.Padding = UDim.new(0,8)
        layout.Parent = gamesContent

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0,8)
        padding.PaddingLeft = UDim.new(0,12)
        padding.Parent = gamesContent

        for _, gameInfo in ipairs(GamesList) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.6,0,0,36)
            btn.Text = gameInfo.Name
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
            btn.Parent = gamesContent

            btn.MouseButton1Click:Connect(function()
                -- Remove Games tab and go to game key input
                showGameKeyTab(gameInfo)
            end)
        end
    end

    local function showGameKeyTab(gameInfo)
        self.CurrentTab.Visible = false
        self.TitleLabel.Text = gameInfo.Name
        self.TabButtons:ClearAllChildren()

        -- Back button
        local backBtn = Instance.new("TextButton")
        backBtn.Size = UDim2.new(0,60,1,0)
        backBtn.Text = "← Back"
        backBtn.Font = Enum.Font.GothamBold
        backBtn.TextSize = 14
        backBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
        backBtn.TextColor3 = Color3.fromRGB(255,255,255)
        Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0,6)
        backBtn.Parent = self.TabButtons

        backBtn.MouseButton1Click:Connect(function()
            self.CurrentTab:Destroy()
            showGamesTab()
        end)

        local keyContent = Instance.new("Frame")
        keyContent.Size = UDim2.new(1,0,1,0)
        keyContent.BackgroundTransparency = 1
        keyContent.Parent = self.ContentArea
        self.CurrentTab = keyContent

        -- Key header
        local header = Instance.new("TextLabel")
        header.Text = "Key ("..gameInfo.Name..")"
        header.Size = UDim2.new(1,0,0,28)
        header.Position = UDim2.new(0,0,0,8)
        header.BackgroundTransparency = 1
        header.Font = Enum.Font.GothamBold
        header.TextSize = 18
        header.TextColor3 = Color3.fromRGB(255,255,255)
        header.TextXAlignment = Enum.TextXAlignment.Center
        header.Parent = keyContent

        -- Input Box
        local inputBox = Instance.new("TextBox")
        inputBox.Size = UDim2.new(0.8,0,0,36)
        inputBox.Position = UDim2.new(0.1,0,0,48)
        inputBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
        inputBox.TextColor3 = Color3.fromRGB(255,255,255)
        inputBox.Font = Enum.Font.Gotham
        inputBox.TextSize = 14
        inputBox.PlaceholderText = "Enter your key"
        inputBox.ClearTextOnFocus = false
        Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0,6)
        inputBox.Parent = keyContent

        -- Check Key Button
        local checkBtn = Instance.new("TextButton")
        checkBtn.Size = UDim2.new(0.5,0,0,36)
        checkBtn.Position = UDim2.new(0.25,0,0,96)
        checkBtn.Text = "Check Key"
        checkBtn.Font = Enum.Font.GothamBold
        checkBtn.TextSize = 14
        checkBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        checkBtn.TextColor3 = Color3.fromRGB(255,255,255)
        Instance.new("UICorner", checkBtn).CornerRadius = UDim.new(0,6)
        checkBtn.Parent = keyContent

        -- Key checking logic
        checkBtn.MouseButton1Click:Connect(function()
            checkBtn.Active = false
            inputBox.Active = false

            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

            self.TitleLabel.Text = "🔄 Scanning Key..."
            task.spawn(function()
                local keySuccess, keysRaw = pcall(function()
                    return game:HttpGet(gameInfo.URL_KEYS)
                end)
                local verSuccess, latestVer = pcall(function()
                    return game:HttpGet(gameInfo.URL_VER)
                end)

                local key = inputBox.Text
                if keySuccess and keysRaw then
                    keysRaw = keysRaw:gsub("return",""):gsub("{",""):gsub("}",""):gsub("\"","")
                    local keysList = {}
                    for k in keysRaw:gmatch("[^,]+") do table.insert(keysList,k:match("^%s*(.-)%s*$")) end

                    if table.find(keysList,key) then
                        if verSuccess and latestVer then
                            latestVer = latestVer:match("%d+%.%d+%.%d+")
                            if isOutdated(VERSION, latestVer) then
                                self.TitleLabel.Text = "⚠️ Update available ("..latestVer..")"
                                wait(1)
                            end
                        end

                        self.TitleLabel.Text = "✅ Access Granted"
                        wait(1)
                        self.Screen:Destroy()
                        local uiCode = game:HttpGet(gameInfo.URL_UI)
                        loadstring(uiCode)()
                    else
                        self.TitleLabel.Text = "❌ Access Denied"
                        -- Optional tween for shake effect
                        local pos = self.Outline.Position
                        for i = 1,3 do
                            TweenService:Create(self.Outline, tweenInfo, {Position = pos + UDim2.new(0,10,0,0)}):Play()
                            wait(0.05)
                            TweenService:Create(self.Outline, tweenInfo, {Position = pos + UDim2.new(0,-10,0,0)}):Play()
                            wait(0.05)
                        end
                        TweenService:Create(self.Outline, tweenInfo, {Position = pos}):Play()
                        checkBtn.Active = true
                        inputBox.Active = true
                    end
                else
                    self.TitleLabel.Text = "⚠️ Failed to fetch keys"
                    checkBtn.Active = true
                    inputBox.Active = true
                end
            end)
        end)
    end

    -- ==========================
    showGamesTab()  -- initialize loader with Games tab

    -- Close button
    self.CloseButton.MouseButton1Click:Connect(function()
        self.Screen:Destroy()
    end)

    -- Rainbow gradient
    task.spawn(function()
        while self.Screen.Parent do
            local t = tick()
            local r = 0.5 + 0.5 * math.sin(t)
            local g = 0.5 + 0.5 * math.sin(t + 2)
            local b = 0.5 + 0.5 * math.sin(t + 4)
            self.OutlineGradient.Color = ColorSequence.new(Color3.new(r,g,b), Color3.new(b,r,g))
            task.wait(0.05)
        end
    end)

    return self
end

-- ==========================
local loader = LoaderUI.new()
if DEBUG_MODE then
    print("[MoonyLoady] Loader v"..VERSION.." initialized with "..#GamesList.." game(s)")
end
