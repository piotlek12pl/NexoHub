if getgenv().Nexo_Authorized ~= "NexoHub_Session_Success" then
    game:GetService("Players").LocalPlayer:Kick("\n\n[Nexo Security]\nUnauthorized execution detected.\nPlease execute the script via the official loader.\ndsc.gg/nexohub")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

-- Fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Window
local Window = Fluent:CreateWindow({
    Title = "NexoHub v1.0",
    SubTitle = "Hooked!",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Auto Farm", Icon = "swords" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- SETTINGS
local AutoFarm = false
local Priority = "Health"
local GodMode = false

local orbitRadius = 6
local orbitSpeed = 4

local target = nil
local angle = 0
local attacking = false

-- UI

Tabs.Main:AddToggle("AutoFarm", {
    Title = "Auto Farm",
    Default = false
})

Options.AutoFarm:OnChanged(function(v)
    AutoFarm = v
end)

Tabs.Main:AddDropdown("Priority", {
    Title = "Priority by",
    Values = {"Health","Distance"},
    Multi = false,
    Default = "Health"
})

Options.Priority:OnChanged(function(v)
    Priority = v
end)

Tabs.Main:AddToggle("GodMode", {
    Title = "Enable God",
    Default = false
})

Options.GodMode:OnChanged(function(v)
    GodMode = v
end)

-- enemy finder
function getEnemy()

    local myTeam = player.Team
    if not myTeam then return nil end

    local enemyTeam

    if myTeam.Name == "Green" then
        enemyTeam = "Yellow"
    elseif myTeam.Name == "Yellow" then
        enemyTeam = "Green"
    else
        return nil
    end

    local best = nil
    local bestValue = math.huge

    for _,p in pairs(Players:GetPlayers()) do
        
        if p ~= player and p.Team and p.Team.Name == enemyTeam then
            
            if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character:FindFirstChild("HumanoidRootPart") then
                
                local hum = p.Character.Humanoid
                
                if hum.Health > 0 then
                    
                    if Priority == "Health" then
                        
                        if hum.Health < bestValue then
                            bestValue = hum.Health
                            best = p
                        end
                        
                    elseif Priority == "Distance" then
                        
                        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        
                        if myRoot then
                            local dist = (myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude
                            
                            if dist < bestValue then
                                bestValue = dist
                                best = p
                            end
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
    end

    return best
end

function getRoot(plr)
    if plr and plr.Character then
        return plr.Character:FindFirstChild("HumanoidRootPart")
    end
end

-- autoclick
task.spawn(function()

    while true do
        
        if attacking and AutoFarm then
            
            VirtualUser:Button1Down(Vector2.new(), workspace.CurrentCamera.CFrame)
            task.wait()
            VirtualUser:Button1Up(Vector2.new(), workspace.CurrentCamera.CFrame)
            
        end
        
        task.wait(0.05)
        
    end

end)

-- main loop
RunService.RenderStepped:Connect(function(dt)

    if not player.Character then return end
    
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChild("Humanoid")
    
    if not root or not humanoid then return end

    -- god mode
    if GodMode then
        if humanoid.Health < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end
    end

    if not AutoFarm then
        attacking = false
        return
    end

    if not target then
        target = getEnemy()
    end

    local enemyRoot = getRoot(target)

    if target and target.Character then
        
        local enemyHum = target.Character:FindFirstChild("Humanoid")

        if enemyHum and enemyHum.Health <= 0 then
            target = nil
            return
        end
        
    end

    if enemyRoot then
        
        attacking = true

        angle += orbitSpeed * dt

        local offset = Vector3.new(
            math.cos(angle) * orbitRadius,
            2,
            math.sin(angle) * orbitRadius
        )

        root.CFrame = CFrame.new(enemyRoot.Position + offset, enemyRoot.Position)

    else
        attacking = false
    end

end)

player:GetPropertyChangedSignal("Team"):Connect(function()
    target = nil
end)

-- Save system

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("OrbitFarm")
SaveManager:SetFolder("OrbitFarm/config")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "AutoFarm",
    Content = "Script loaded successfully.",
    Duration = 6
})

SaveManager:LoadAutoloadConfig()
