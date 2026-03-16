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
local InfinityHook = false

---- Remotes and TEvent
local TEvent = nil
local HookFire = nil
local HookHit = nil

task.spawn(function()
    print("[NexoDebug] Loading TEvent library...")
    local success, err = pcall(function()
        TEvent = require(game:GetService("ReplicatedStorage").Shared.Core.TEvent)
    end)
    
    if success and TEvent then
        print("[NexoDebug] TEvent loaded successfully.")
        pcall(function() HookFire = TEvent.Remote.new("HookFire") end)
        pcall(function() HookHit = TEvent.Remote.new("HookHit") end)
    end
    
    -- Fallback search if TEvent fails or remotes still nil
    if not HookFire or not HookHit then
        for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("RemoteEvent") then
                if v.Name == "HookFire" then HookFire = v
                elseif v.Name == "HookHit" then HookHit = v end
            end
        end
    end
    
    if HookFire then print("[NexoDebug] HookFire Remote initialized.") else warn("[NexoDebug] HookFire NOT FOUND!") end
    if HookHit then print("[NexoDebug] HookHit Remote initialized.") else warn("[NexoDebug] HookHit NOT FOUND!") end
end)

-- Target Detection
local function getEnemies()
    local enemies = {}
    local lp = game.Players.LocalPlayer
    local myTeam = lp.Team
    if not myTeam then return enemies end
    
    local mySide = myTeam:GetAttribute("Side")
    -- If Side attribute is missing, fallback to Team Name logic
    local enemyTeamName = (myTeam.Name == "Green") and "Yellow" or "Green"

    -- Players
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= lp and p.Team then
            local isEnemy = false
            if mySide then
                isEnemy = p.Team:GetAttribute("Side") ~= mySide
            else
                isEnemy = p.Team.Name == enemyTeamName
            end
            
            if isEnemy then
                local c = p.Character
                if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 then
                    table.insert(enemies, p)
                end
            end
        end
    end
    
    -- Bots
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m:GetAttribute("IsBot") then
            local botTeamName = m:GetAttribute("BotTeamName")
            local isEnemy = false
            if mySide then
                local botTeam = game:GetService("Teams"):FindFirstChild(botTeamName or "")
                if botTeam then
                    isEnemy = botTeam:GetAttribute("Side") ~= mySide
                end
            else
                isEnemy = botTeamName == enemyTeamName
            end
            
            if isEnemy then
                local hum = m:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 and m:FindFirstChild("HumanoidRootPart") then
                    table.insert(enemies, m)
                end
            end
        end
    end
    return enemies
end

-- UI

Tabs.Main:AddToggle("AutoFarm", {
    Title = "Auto Farm (Orbit)",
    Default = false
})

Tabs.Main:AddToggle("InfinityHook", {
    Title = "Silent Hook (Hooking ALL Players)",
    Default = false
})

Options.AutoFarm:OnChanged(function(v)
    AutoFarm = v
end)

Options.InfinityHook:OnChanged(function(v)
    InfinityHook = v
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

Tabs.Main:AddSection("Hitbox Expander")

Tabs.Main:AddToggle("HitboxExpander", {
    Title = "Enable Hitbox Expander",
    Default = false
})

Tabs.Main:AddSlider("HitboxSize", {
    Title = "Hitbox Size",
    Description = "Adjust enemy hitbox size for easier hits",
    Default = 2,
    Min = 2,
    Max = 20,
    Rounding = 1,
})

Tabs.Main:AddToggle("HitboxVisual", {
    Title = "Visual Hitboxes",
    Default = false
})

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
            -- Multiple clicks per wait to increase DPS
            for i = 1, 5 do
                VirtualUser:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                VirtualUser:Button1Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end
        end
        task.wait()
    end
end)

-- Infinity Hook Loop
task.spawn(function()
    local hookCounter = 0
    print("[NexoDebug] Infinity Hook Loop active")
    while true do
        task.wait(0.1)
        if InfinityHook then
            if not HookFire or not HookHit then
                -- Silently wait for remotes to load
            else
                local targetList = getEnemies()
                local lroot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                
                if lroot and #targetList > 0 then
                    for _, target in ipairs(targetList) do
                        local tchar = target:IsA("Player") and target.Character or target
                        local troot = tchar and tchar:FindFirstChild("HumanoidRootPart")
                        
                        if troot then
                            hookCounter = hookCounter + 1
                            local fireTime = TEvent and TEvent.UnixTimeFloat() or tick()
                            -- Game ID format: UserId_Timestamp_Counter
                            local hookId = string.format("%s_%d_%d", tostring(player.UserId), math.floor(fireTime * 1000), hookCounter)
                            local direction = (troot.Position - lroot.Position).Unit
                            
                            -- Fire Hook Fire
                            HookFire:FireServer({
                                ["hookId"] = hookId,
                                ["startPosition"] = lroot.Position + (direction * 2),
                                ["direction"] = direction,
                                ["distance"] = 2000,
                                ["hookFlyTime"] = 0.01,
                                ["hookBackSpeed"] = 1500,
                                ["fireTime"] = fireTime
                            })
                            
                            -- Fire Hook Hit immediately
                            task.spawn(function()
                                task.wait(0.02)
                                HookHit:FireServer({
                                    ["hookId"] = hookId,
                                    ["targetPlayer"] = target,
                                    ["targetPartName"] = "HumanoidRootPart",
                                    ["hookBackSpeed"] = 1500
                                })
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- Hitbox Expander Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        local active = Options.HitboxExpander and Options.HitboxExpander.Value
        local size = Options.HitboxSize and Options.HitboxSize.Value or 2
        local visual = Options.HitboxVisual and Options.HitboxVisual.Value
        
        -- Process Players
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local char = p.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local isEnemy = false
                    local myTeam = player.Team
                    if myTeam then
                        local mySide = myTeam:GetAttribute("Side")
                        if mySide then
                            isEnemy = p.Team and p.Team:GetAttribute("Side") ~= mySide
                        else
                            local enemyTeamName = (myTeam.Name == "Green") and "Yellow" or "Green"
                            isEnemy = p.Team and p.Team.Name == enemyTeamName
                        end
                    end
                    
                    if active and isEnemy then
                        root.Size = Vector3.new(size, size, size)
                        root.Transparency = visual and 0.5 or 1
                        root.CanCollide = false
                    else
                        root.Size = Vector3.new(2, 2, 1)
                        root.Transparency = 1
                    end
                end
            end
        end
        
        -- Process Bots
        for _, m in ipairs(workspace:GetDescendants()) do
            if m:IsA("Model") and m:GetAttribute("IsBot") then
                local root = m:FindFirstChild("HumanoidRootPart")
                if root then
                    local isEnemy = false
                    local myTeam = player.Team
                    if myTeam then
                        local mySide = myTeam:GetAttribute("Side")
                        local botTeamName = m:GetAttribute("BotTeamName")
                        if mySide then
                            local botTeam = game:GetService("Teams"):FindFirstChild(botTeamName or "")
                            isEnemy = botTeam and botTeam:GetAttribute("Side") ~= mySide
                        else
                            local enemyTeamName = (myTeam.Name == "Green") and "Yellow" or "Green"
                            isEnemy = botTeamName == enemyTeamName
                        end
                    end
                    
                    if active and isEnemy then
                        root.Size = Vector3.new(size, size, size)
                        root.Transparency = visual and 0.5 or 1
                        root.CanCollide = false
                    else
                        root.Size = Vector3.new(2, 2, 1)
                        root.Transparency = 1
                    end
                end
            end
        end
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
