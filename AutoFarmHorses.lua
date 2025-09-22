local horseFolder = workspace.MobFolder
local validHorseNames = {"Gargoyle", "Flora"}

-- Early debug: Check if the horseFolder exists
if not horseFolder then
    error("Error: horseFolder (workspace.MobFolder) is not found!")
end

-- Early debug: Check if LocalPlayer is available
if not game.Players.LocalPlayer then
    error("Error: LocalPlayer is not found!")
end

-- Function to teleport to horse
function teleportToHorse(horse)
    if horse and horse:IsA("Part") then
        local horsePosition = horse.Position
        print("Teleporting to horse at position: " .. tostring(horsePosition))
        pcall(function() 
            game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(horsePosition) * CFrame.Angles(0, math.pi, 0))
        end)
        wait(0.1)
        print("Teleported to horse at position: " .. tostring(horsePosition))
    else
        print("Error in teleportToHorse: Horse is not a valid Part.")
    end
end

-- Function to move mouse and fire events
function moveMouseAndFireEvent(horse)
    if horse and horse:IsA("Part") then
        local camera = game:GetService("Workspace").CurrentCamera
        if camera then
            local screenPosition = camera:WorldToScreenPoint(horse.Position)
            if isrbxactive() then
                print("Moving mouse to: " .. tostring(screenPosition))
                pcall(function() 
                    mousemoveabs(screenPosition.X, screenPosition.Y)
                end)

                local tameEvent = horse:FindFirstChild("TameEvent")
                if tameEvent then
                    local args = {"BeginAggro"}
                    pcall(function() 
                        tameEvent:FireServer(unpack(args))
                        print("Fired BeginAggro event.")
                    end)
                    wait(1)
                    local args = {"SuccessfulFeed"}
                    pcall(function() 
                        tameEvent:FireServer(unpack(args))
                        print("Fired SuccessfulFeed event.")
                    end)
                else
                    print("Error in moveMouseAndFireEvent: TameEvent not found on horse.")
                end
            else
                print("Error in moveMouseAndFireEvent: Roblox is not in focus, cannot perform actions.")
            end
        else
            print("Error in moveMouseAndFireEvent: Camera is not available.")
        end
    else
        print("Error in moveMouseAndFireEvent: Horse is not a valid Part.")
    end
end

-- Function to wait for DisplayAnimalGui to disable
function waitForAnimalGuiToDisable()
    local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
    -- Wait until DisplayAnimalGui is disabled or deleted
    while playerGui:FindFirstChild("DisplayAnimalGui") and playerGui.DisplayAnimalGui.Enabled do
        task.wait(0.1)
    end
    -- If DisplayAnimalGui is deleted, wait for 1 second before checking again
    if not playerGui:FindFirstChild("DisplayAnimalGui") then
        print("DisplayAnimalGui deleted, waiting for 1 second.")
        task.wait(1)
    end
end

-- Main farming loop
function farmingLoop()
    print("Starting farming loop - Version 1.1.2")

    while true do
        local horses = horseFolder:GetChildren()
        print("Checking for horses, found: " .. #horses)

        -- If no horses are found, wait longer to prevent the loop from spamming
        if #horses == 0 then
            print("No horses found. Waiting for 5 seconds.")
            task.wait(5)  -- Wait for new horses if none are found
        else
            for _, horse in pairs(horses) do
                print("Checking horse: " .. horse.Name)

                if horse and horse.Name ~= "" and table.find(validHorseNames, horse.Name) then
                    print("Valid horse found: " .. horse.Name)

                    while horse.Parent == horseFolder do
                        pcall(function()  -- Wrap this in pcall to handle any errors that arise
                            teleportToHorse(horse)
                        end)
                        pcall(function()  -- Wrap this in pcall to handle any errors that arise
                            moveMouseAndFireEvent(horse)
                        end)
                        task.wait(0.1)
                    end

                    print("Horse deleted, now checking for DisplayAnimalGui.")
                    task.wait(0.2)
                    waitForAnimalGuiToDisable()
                    task.wait(0.1)

                    -- Debugging: Check if remote exists before firing it
                    local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("PurchaseItemRemote", 10)
                    if remote then
                        local args = {"WesternLasso", 1}
                        pcall(function()
                            print("Firing PurchaseItemRemote with args:", args)
                            remote:InvokeServer(unpack(args))
                        end)
                    else
                        print("PurchaseItemRemote not found!")
                    end
                    task.wait(1)  -- Small delay before moving to the next horse
                else
                    print("Horse is not valid or not in the valid list.")
                end
            end
        end
    end
end

-- Start the farming loop
farmingLoop()
