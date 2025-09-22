local horseFolder = workspace.MobFolder
local validHorseNames = {"Gargoyle", "Flora"}

function teleportToHorse(horse)
    if horse and horse:IsA("Part") then
        local horsePosition = horse.Position
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(horsePosition) * CFrame.Angles(0, math.pi, 0))
        wait(0.1)
        print("Teleported to horse at position: " .. tostring(horsePosition))
    else
        print("Horse is not a valid Part.")
    end
end

function moveMouseAndFireEvent(horse)
    if horse and horse:IsA("Part") then
        local camera = game:GetService("Workspace").CurrentCamera
        if camera then
            local screenPosition = camera:WorldToScreenPoint(horse.Position)
            if isrbxactive() then
                mousemoveabs(screenPosition.X, screenPosition.Y)
                print("Moving mouse to: " .. tostring(screenPosition))
                local tameEvent = horse:FindFirstChild("TameEvent")
                if tameEvent then
                    local args = {"BeginAggro"}
                    tameEvent:FireServer(unpack(args))
                    print("Fired BeginAggro event.")
                    wait(1)
                    local args = {"SuccessfulFeed"}
                    tameEvent:FireServer(unpack(args))
                    print("Fired SuccessfulFeed event.")
                else
                    print("TameEvent not found on horse.")
                end
            else
                print("Roblox is not in focus, cannot perform actions.")
            end
        else
            print("Camera is not available.")
        end
    else
        print("Horse is not a valid Part.")
    end
end

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

function farmingLoop()
    while true do
        local horses = horseFolder:GetChildren()
        
        -- If no horses are found, wait longer to prevent the loop from spamming
        if #horses == 0 then
            task.wait(5)  -- Wait for new horses if none are found
        else
            for _, horse in pairs(horses) do
                if horse and horse.Name ~= "" and table.find(validHorseNames, horse.Name) then
                    while horse.Parent == horseFolder do
                        teleportToHorse(horse)
                        moveMouseAndFireEvent(horse)
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
                end
            end
        end
    end
end

farmingLoop()
