  local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Services required for script functionality
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Plots = workspace:WaitForChild("Required"):WaitForChild("Plots")

local Window = Fluent:CreateWindow({
    Title = "NexoHub v1.0",
    SubTitle = "| Skateboard for Brainrots",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Dashboard = Window:AddTab({ Title = "Dashboard", Icon = "home" }),
    Automation = Window:AddTab({ Title = "Automation", Icon = "cpu" }),
    LocalPlayer = Window:AddTab({ Title = "Local Player", Icon = "user" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Upgrades = Window:AddTab({ Title = "Upgrades", Icon = "trending-up" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "package" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

do
    -- Community Section
    Tabs.Dashboard:AddParagraph({
        Title = "Welcome to NexoHub",
        Content = "#1 Roblox Scripts Provider!"
    })

    Tabs.Dashboard:AddButton({
        Title = "Click to Redirect to Our Discord! 🔗",
        Description = "Copies the Discord invite link to your clipboard.",
        Callback = function()
            setclipboard("https://dsc.gg/nexohub")
            Fluent:Notify({
                Title = "Discord",
                Content = "Link copied to clipboard! Paste it in your browser.",
                Duration = 5
            })
        end
    })
end

do
    -- Automation Section
    Tabs.Automation:AddSection("Base Automation")

    local AutoCollect = Tabs.Automation:AddToggle("AutoCollect", {Title = "Auto Collect Money", Default = false })

    -- Unified function for parsing abbreviated currency values (supports K, M, B, T, Q, Qi, Sx, Sp...)
    local function parseAbbreviated(str)
        if not str then return 0 end
        local suffixes = {
            k = 1e3, K = 1e3,
            m = 1e6, M = 1e6,
            b = 1e9, B = 1e9,
            t = 1e12, T = 1e12,
            q = 1e15, Q = 1e15,
            qi = 1e18, Qi = 1e18,
            sx = 1e21, Sx = 1e21,
            sp = 1e24, Sp = 1e24,
            oc = 1e27, Oc = 1e27,
            no = 1e30, No = 1e30,
            dc = 1e33, Dc = 1e33
        }
        local clean = tostring(str):gsub("%$", ""):gsub("/s", ""):gsub("/S", ""):gsub(",", "")
        local numStr = clean:match("[%d%.]+")
        if not numStr then return 0 end
        local val = tonumber(numStr) or 0
        local suffix = clean:match("[a-zA-Z]+")
        if suffix and suffixes[suffix] then
            val = val * suffixes[suffix]
        end
        return val
    end

    -- Background Autocollect loop
    task.spawn(function()
        while task.wait(1) do
            if Options.AutoCollect.Value then
                local plotId = LocalPlayer:GetAttribute("Plot")
                if plotId then
                    local myPlot = Plots:FindFirstChild(tostring(plotId))
                    if myPlot then
                        local slots = myPlot:FindFirstChild("Slots")
                        if slots then
                            for _, slot in pairs(slots:GetChildren()) do
                                local placedValue = slot:GetAttribute("Placed")
                                if placedValue then
                                    Remotes.CollectMoney:FireServer(placedValue)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Auto Rebirth logic
    local RebirthData = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("RebirthData"))
    local AutoRebirth = Tabs.Automation:AddToggle("AutoRebirth", {Title = "Auto Rebirth", Default = false })

    AutoRebirth:OnChanged(function()
        if Options.AutoRebirth.Value then
            Window:Dialog({
                Title = "NexoHub - Reminder",
                Content = "Remember! You need to have enabled Auto Collect Money for this to work effectively!",
                Buttons = {
                    {
                        Title = "Understood",
                        Callback = function()
                            -- Logic continues in the task.spawn loop
                        end
                    }
                }
            })
        end
    end)

    task.spawn(function()
        while task.wait(2) do
            if Options.AutoRebirth.Value then
                local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
                local money = leaderstats and leaderstats:FindFirstChild("Money")
                local rebirths = leaderstats and (leaderstats:FindFirstChild("Rebirths") or leaderstats:FindFirstChild("Rebirth"))
                
                if money and rebirths then
                    local currentRebirths = tonumber(rebirths.Value) or 0
                    local nextRebirthLevel = currentRebirths + 1
                    local requirementData = RebirthData[nextRebirthLevel]
                    
                    if requirementData and requirementData.MoneyRequirement then
                        local moneyVal = parseAbbreviated(money.Value)
                        local reqVal = tonumber(requirementData.MoneyRequirement) or 0
                        
                        -- Rebirth Debugging (uncomment for F9 logs)
                        print(string.format("NexoHub Rebirth Log | Have: %s | Need: %s | Next Lvl: %d", tostring(moneyVal), tostring(reqVal), nextRebirthLevel))

                        if moneyVal >= reqVal then
                            Remotes.RequestRebirth:FireServer()
                            Fluent:Notify({
                                Title = "Auto Rebirth",
                                Content = "Attempting rebirth level " .. tostring(nextRebirthLevel),
                                Duration = 3
                            })
                            task.wait(2)
                        end
                    end
                end
            end
        end
    end)
    Tabs.Automation:AddSection("Brainrot Automation")

    local AutoSell = Tabs.Automation:AddToggle("AutoSell", {Title = "Auto Sell Brainrots", Default = false })

    task.spawn(function()
        while task.wait(2) do
            if Options.AutoSell.Value then
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                
                if humanoid and backpack then
                    -- 1. Sell held item if it's a Brainrot
                    local currentTool = character:FindFirstChildOfClass("Tool")
                    if currentTool and currentTool:HasTag("Brainrot") then
                        Remotes.SellBrainrot:FireServer()
                        task.wait(0.2)
                    end

                    -- 2. Scan backpack and sell remaining brainrots
                    for _, tool in pairs(backpack:GetChildren()) do
                        if tool:IsA("Tool") and tool:HasTag("Brainrot") then
                            humanoid:EquipTool(tool)
                            task.wait(0.3) -- Equip delay
                            Remotes.SellBrainrot:FireServer()
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
    end)

    local AutoGrab = Tabs.Automation:AddToggle("AutoGrab", {Title = "Auto Grab Best Brainrot", Default = false })

    -- Auto Grab loop
    task.spawn(function()
        while task.wait(1) do
            if Options.AutoGrab.Value then
                local required = workspace:FindFirstChild("Required")
                local brainrotsFolder = required and required:FindFirstChild("Brainrots")
                
                if brainrotsFolder then
                    local children = brainrotsFolder:GetChildren()
                    local bestBrainrot = nil
                    local maxMPS = -1

                    for _, brainrot in pairs(children) do
                        local gui = brainrot:FindFirstChild("BrainrotGui", true)
                        local mpsLabel = gui and gui:FindFirstChild("MoneyPerSecond")
                        local hitbox = brainrot:FindFirstChild("Hitbox")
                        
                        -- Check if model has any prompt (collectible indicator)
                        local hasPrompt = false
                        for _, v in pairs(brainrot:GetDescendants()) do
                            if v:IsA("ProximityPrompt") or v.Name:lower():find("prompt") then
                                hasPrompt = true
                                break
                            end
                        end

                        if mpsLabel and hitbox and hasPrompt then
                            local mps = parseAbbreviated(mpsLabel.Text)
                            if mps > maxMPS then
                                maxMPS = mps
                                bestBrainrot = brainrot
                            end
                        end
                    end

                    if bestBrainrot and LocalPlayer.Character then
                        local hitbox = bestBrainrot:FindFirstChild("Hitbox")
                        local prompt = nil
                        for _, v in pairs(bestBrainrot:GetDescendants()) do
                            if v:IsA("ProximityPrompt") or v.Name:lower():find("prompt") then
                                prompt = v
                                break
                            end
                        end

                        if hitbox and prompt then
                            Fluent:Notify({
                                Title = "Auto Grab",
                                Content = "Picking up: " .. tostring(maxMPS) .. " MPS",
                                Duration = 2
                            })

                            LocalPlayer.Character:PivotTo(hitbox.CFrame)
                            task.wait(0.3)
                            
                            if fireproximityprompt then
                                fireproximityprompt(prompt)
                            else
                                prompt:InputHoldBegin()
                                task.wait(prompt.HoldDuration + 0.1)
                                prompt:InputHoldEnd()
                            end

                            -- Delivery sequence
                            task.wait(1)
                            LocalPlayer.Character:PivotTo(CFrame.new(-860, 7, -350))
                            
                            -- Auto-walk to checkpoint
                            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            if humanoid then
                                local targetPos = Vector3.new(-854, 7, -378)
                                humanoid:MoveTo(targetPos)
                                
                                -- Wait for arrival or timeout (fail-safe)
                                local reached = false
                                local connection
                                connection = humanoid.MoveToFinished:Connect(function()
                                    reached = true
                                    connection:Disconnect()
                                end)
                                
                                -- 4-second delivery timeout
                                local start = tick()
                                repeat task.wait() until reached or tick() - start > 4
                                if connection then connection:Disconnect() end
                            end
                        end
                    end
                end
            end
        end
    end)
end

do
    Tabs.LocalPlayer:AddSection("Movement")

    local FlightToggle = Tabs.LocalPlayer:AddToggle("Flight", {Title = "Flight", Default = false })
    
    local FlightSpeedSlider = Tabs.LocalPlayer:AddSlider("FlightSpeed", {
        Title = "Flight Speed",
        Description = "Adjusts your flying speed",
        Default = 50,
        Min = 10,
        Max = 500,
        Rounding = 1,
        Callback = function(Value)
            -- Value fetched directly from Options.FlightSpeed.Value in loop
        end
    })

    Tabs.LocalPlayer:AddSection("Character")

    local EnableChangers = Tabs.LocalPlayer:AddToggle("EnableChangers", {Title = "Enable Changers", Default = false })

    local wsCustom = false
    local jpCustom = false

    local WalkSpeedSlider = Tabs.LocalPlayer:AddSlider("WalkSpeed", {
        Title = "Walk Speed",
        Description = "Enforces your walking speed",
        Default = 16,
        Min = 16,
        Max = 1000,
        Rounding = 1,
        Callback = function(Value)
            wsCustom = true
        end
    })

    local JumpPowerSlider = Tabs.LocalPlayer:AddSlider("JumpPower", {
        Title = "Jump Power",
        Description = "Enforces your jump power",
        Default = 50,
        Min = 50,
        Max = 800,
        Rounding = 1,
        Callback = function(Value)
            jpCustom = true
        end
    })

    -- Reset to defaults when toggled off
    EnableChangers:OnChanged(function()
        if not Options.EnableChangers.Value then
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
                humanoid.JumpPower = 50
                humanoid.UseJumpPower = false
            end
        end
    end)

    -- Persistence & Enforcement logic
    RunService.Heartbeat:Connect(function()
        if Options.EnableChangers.Value then
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                -- Enforce WalkSpeed if not flying and user has adjusted it
                if not Options.Flight.Value and wsCustom then
                    humanoid.WalkSpeed = Options.WalkSpeed.Value
                end
                
                -- Enforce JumpPower user has adjusted it
                if jpCustom then
                    humanoid.UseJumpPower = true
                    humanoid.JumpPower = Options.JumpPower.Value
                end
            end
        end
    end)

    local flightConnection
    local function startFlight()
        if flightConnection then flightConnection:Disconnect() end
        
        flightConnection = RunService.Heartbeat:Connect(function()
            if not Options.Flight.Value then
                if flightConnection then flightConnection:Disconnect() flightConnection = nil end
                return
            end

            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local camera = workspace.CurrentCamera

            if root and humanoid then
                local moveDir = Vector3.new(0, 0, 0)
                
                if UserInputService:GetFocusedTextBox() == nil then
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                end

                root.AssemblyLinearVelocity = moveDir.Unit * (moveDir.Magnitude > 0 and Options.FlightSpeed.Value or 0)
                
                -- Noclip logic
                for _, v in pairs(character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end
        end)
    end

    FlightToggle:OnChanged(function()
        if Options.Flight.Value then
            startFlight()
        else
            if flightConnection then flightConnection:Disconnect() flightConnection = nil end
            -- Reset physics state if character exists
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
        end
    end)
end

do
    Tabs.Teleport:AddSection("Plots")

    Tabs.Teleport:AddButton({
        Title = "My Plot",
        Description = "Teleport to your plot's spawn location.",
        Callback = function()
            local plotId = LocalPlayer:GetAttribute("Plot")
            if plotId then
                local myPlot = Plots:FindFirstChild(tostring(plotId))
                if myPlot then
                    local spawnLoc = myPlot:FindFirstChild("SpawnLocation")
                    if spawnLoc and LocalPlayer.Character then
                        LocalPlayer.Character:PivotTo(spawnLoc.CFrame + Vector3.new(0, 3, 0))
                        Fluent:Notify({
                            Title = "Teleport",
                            Content = "Teleported to Plot #" .. tostring(plotId),
                            Duration = 3
                        })
                    else
                        -- Failsafe: teleport to the plot center if SpawnLocation is missing
                        if LocalPlayer.Character then
                            LocalPlayer.Character:PivotTo(myPlot:GetPivot() + Vector3.new(0, 3, 0))
                        end
                    end
                else
                    Fluent:Notify({
                        Title = "Teleport Error",
                        Content = "Could not find plot in workspace!",
                        Duration = 3
                    })
                end
            else
                Fluent:Notify({
                    Title = "Teleport Error",
                    Content = "You don't have a plot assigned yet!",
                    Duration = 3
                })
            end
        end
    })

    Tabs.Teleport:AddSection("Zones")

    local zones = {
        { Name = "Celestial", CF = CFrame.new(-819.566345, 1050.99951, 2019.97437, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { Name = "Secret", CF = CFrame.new(-819.566345, 720.499634, 1485.47437, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { Name = "Divine", CF = CFrame.new(-819.566345, 960.499512, 2019.97437, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { Name = "Cosmic", CF = CFrame.new(-819.566345, 540.499634, 1004.97437, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { Name = "Legendary", CF = CFrame.new(-819.566345, 317.499634, 380.474365, 1, 0, 0, 0, 1, 0, 0, 0, 1) }
    }

    for _, zone in ipairs(zones) do
        Tabs.Teleport:AddButton({
            Title = zone.Name,
            Description = "Teleport to the " .. zone.Name .. " zone.",
            Callback = function()
                if LocalPlayer.Character then
                    LocalPlayer.Character:PivotTo(zone.CF)
                    Fluent:Notify({
                        Title = "Teleport",
                        Content = "Teleported to " .. zone.Name,
                        Duration = 3
                    })
                end
            end
        })
    end
end

do
    Tabs.Upgrades:AddSection("Base Upgrades")

    Tabs.Upgrades:AddButton({
        Title = "Upgrade Base",
        Description = "Remotely upgrades your main base.",
        Callback = function()
            Remotes.UpgradeBase:FireServer()
            Fluent:Notify({
                Title = "Upgrades",
                Content = "Attempted to upgrade base!",
                Duration = 3
            })
        end
    })

    Tabs.Upgrades:AddSection("Speed Upgrades")

    Tabs.Upgrades:AddButton({
        Title = "Buy Speed (+1)",
        Description = "Purchases +1 speed level.",
        Callback = function()
            local success, result = pcall(function()
                return Remotes.BuySpeed:InvokeServer(1)
            end)
            Fluent:Notify({
                Title = "Speed Upgrade",
                Content = success and "Purchased +1 Speed!" or "Purchase Error!",
                Duration = 3
            })
        end
    })

    Tabs.Upgrades:AddButton({
        Title = "Buy Speed (+5)",
        Description = "Purchases +5 speed levels.",
        Callback = function()
            local success, result = pcall(function()
                return Remotes.BuySpeed:InvokeServer(5)
            end)
            Fluent:Notify({
                Title = "Speed Upgrade",
                Content = success and "Purchased +5 Speed!" or "Purchase Error!",
                Duration = 3
            })
        end
    })

    Tabs.Upgrades:AddSection("Other Upgrades")

    Tabs.Upgrades:AddButton({
        Title = "Buy Carry (+1)",
        Description = "Purchases +1 carry capacity level.",
        Callback = function()
            local success, result = pcall(function()
                return Remotes.BuyCarry:InvokeServer(1)
            end)
            Fluent:Notify({
                Title = "Carry Upgrade",
                Content = success and "Purchased +1 Carry Level!" or "Purchase Error!",
                Duration = 3
            })
        end
    })

    Tabs.Upgrades:AddButton({
        Title = "Buy Boost (+1)",
        Description = "Purchases +1 boost power level.",
        Callback = function()
            local success, result = pcall(function()
                return Remotes.BuyBoost:InvokeServer(1)
            end)
            Fluent:Notify({
                Title = "Boost Upgrade",
                Content = success and "Purchased +1 Boost Level!" or "Purchase Error!",
                Duration = 3
            })
        end
    })

    Tabs.Upgrades:AddButton({
        Title = "Buy Boost (+5)",
        Description = "Purchases +5 boost power levels (5x recall).",
        Callback = function()
            local successCount = 0
            for i = 1, 5 do
                local success = pcall(function()
                    return Remotes.BuyBoost:InvokeServer(1)
                end)
                if success then
                    successCount = successCount + 1
                end
                task.wait(0.1)
            end
            Fluent:Notify({
                Title = "Boost Upgrade",
                Content = "Attempted 5 purchases. Successful: " .. tostring(successCount),
                Duration = 3
            })
        end
    })
end

do
    Tabs.Misc:AddSection("Helpers")

    Tabs.Misc:AddButton({
        Title = "Skip Tutorial",
        Description = "Removes all tutorial points from the map.",
        Callback = function()
            local tutorialPoints = workspace:FindFirstChild("Required") and workspace.Required:FindFirstChild("TutorialPoints")
            if tutorialPoints then
                tutorialPoints:ClearAllChildren()
                Fluent:Notify({
                    Title = "Misc",
                    Content = "Tutorial points cleared successfully!",
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Misc",
                    Content = "TutorialPoints folder not found.",
                    Duration = 3
                })
            end
        end
    })

    Tabs.Misc:AddButton({
        Title = "Delete ALL Guards",
        Description = "Removes all guards from the map.",
        Callback = function()
            local guards = workspace:FindFirstChild("Required") and workspace.Required:FindFirstChild("Guards")
            if guards then
                guards:ClearAllChildren()
                Fluent:Notify({
                    Title = "Misc",
                    Content = "All guards cleared successfully!",
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Misc",
                    Content = "Guards folder not found.",
                    Duration = 3
                })
            end
        end
    })
end

-- Loaded Notification
Fluent:Notify({
    Title = "NexoHub",
    Content = "Dashboard initialized successfully.",
    Duration = 5
})

Window:SelectTab(1)
