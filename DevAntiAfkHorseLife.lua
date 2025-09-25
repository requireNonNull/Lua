-- Anti-AFK Script with Synapse X Custom Lua Functions
local isActive = false  -- State of Anti-AFK behavior
local gui = Instance.new("ScreenGui", game.GetService("CoreGui"))

-- Anti-AFK Key Press Function
local function keyPress(keyCode)
    -- Using Synapse X keypress function with Win Key Codes
    keypress(keyCode)
end

-- Anti-AFK Key Release Function
local function keyRelease(keyCode)
    -- Using Synapse X keyrelease function with Win Key Codes
    keyrelease(keyCode)
end

-- Perform movement and other AFK actions in a loop
local function performMovementLoop()
    while isActive do
        if isrbxactive() then  -- Check if Roblox window is in focus
            -- Move forward with 'W' (0x57)
            keyPress(0x57)  -- 'W' key press
            wait(0.5)
            keyRelease(0x57)  -- 'W' key release
            
            -- Simulate circular movement (W, A, S, D)
            keyPress(0x41)  -- 'A' key press (left)
            wait(0.25)
            keyRelease(0x41)  -- 'A' key release

            keyPress(0x53)  -- 'S' key press (down)
            wait(0.25)
            keyRelease(0x53)  -- 'S' key release

            keyPress(0x44)  -- 'D' key press (right)
            wait(0.25)
            keyRelease(0x44)  -- 'D' key release

            -- Press 'C' occasionally to simulate another action (0x43)
            keyPress(0x43)  -- 'C' key press
            wait(0.2)
            keyRelease(0x43)  -- 'C' key release

            -- Press '1' to simulate using a hotkey (0x31)
            --keyPress(0x31)  -- '1' key press
            --wait(0.2)
            --keyRelease(0x31)  -- '1' key release

            -- Press '1' again to simulate another action
            --keyPress(0x31)  -- '1' key press
            --wait(0.2)
            --keyRelease(0x31)  -- '1' key release
            
            -- Wait between loops with a bit of randomness
            wait(1 + math.random() * 2)  -- Random wait between 1 and 3 seconds
        end
    end
end

-- UI Elements Setup
local toggleButton = Instance.new("TextButton")
toggleButton.Text = "Toggle Anti-AFK"
toggleButton.Size = UDim2.new(0, 200, 0, 50)
toggleButton.Position = UDim2.new(0.5, -100, 0, 50)  -- 20% from top and center horizontally
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)  -- Green color
toggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)  -- Black text
toggleButton.Parent = gui

-- Delete UI Button (Red X)
local deleteButton = Instance.new("TextButton")
deleteButton.Text = "X"
deleteButton.Size = UDim2.new(0, 50, 0, 50)
deleteButton.Position = UDim2.new(0.5, 120, 0, 50)  -- Position next to the toggle button
deleteButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- Red color
deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text
deleteButton.Parent = gui

-- Toggle Button Click Handler
toggleButton.MouseButton1Click:Connect(function()
    isActive = not isActive
    if isActive then
        -- Start Anti-AFK behavior
        toggleButton.Text = "Stop Anti-AFK"
        performMovementLoop()
    else
        -- Stop Anti-AFK behavior
        toggleButton.Text = "Toggle Anti-AFK"
    end
end)

-- Delete Button Click Handler (To stop loop and delete UI)
deleteButton.MouseButton1Click:Connect(function()
    isActive = false  -- Stop the loop
    gui:Destroy()  -- Destroy the UI
end)

-- Add GUI to Player's Screen
gui.Parent = game.GetService("CoreGui")
