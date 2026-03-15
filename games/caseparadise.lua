local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Nexo Hub v1.0",
    SubTitle = "Case Paradise | BETA",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

--Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional
local Tabs = {
    Main = Window:AddTab({ Title = "Dashboard", Icon = "home" }),
    LocalPlayer = Window:AddTab({ Title = "Local Player", Icon = "user" }),
    Exploits = Window:AddTab({ Title = "Exploits", Icon = "sword" }),
    Inventory = Window:AddTab({ Title = "Inventory", Icon = "backpack" }),
    Automation = Window:AddTab({ Title = "Automation", Icon = "bot" }),
    Upgrader = Window:AddTab({ Title = "Smart Upgrader", Icon = "arrow-up-circle" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

do
    Fluent:Notify({
        Title = "Notification",
        Content = "This is a notification",
        SubContent = "SubContent", -- Optional
        Duration = 1 -- Set to nil to make the notification not disappear
    })



    Tabs.Main:AddParagraph({
        Title = "UPTIME",
        Content = "99.9% (Stable) 🟢"
    })

    Tabs.Main:AddParagraph({
        Title = "LAST DETECTION",
        Content = "NEVER 🛡️"
    })

    Tabs.Main:AddButton({
        Title = "Click to Redirect to Our Discord! 🔗",
        Description = "Opens the Discord invite link in your browser.",
        Callback = function()
            setclipboard("https://dsc.gg/nexohub")
            -- In Roblox exploits, opening a browser is typically done via request/shell functions,
            -- however replacing it or giving them a clipboard copy is much safer for universal compatibility.
            -- Some exploits support `toclipboard` or `setclipboard` to copy the link.
            -- We'll try to provide a notification that it was copied.
            Fluent:Notify({
                Title = "Discord Link Copied!",
                Content = "The link 'https://dsc.gg/nexohub' has been copied to your clipboard. Paste it in your browser!",
                Duration = 5
            })
        end
    })

    -- LOCAL PLAYER SETTINGS --
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    -- We use local variables to store the current values because sometimes Fluent's 
    -- `Options.SliderName.Value` can act up at the absolute max or min values depending on step size
    local currentWalkSpeed = 16
    local currentJumpPower = 50

    local WalkSpeedSlider = Tabs.LocalPlayer:AddSlider("WS_Slider", {
        Title = "Walk Speed",
        Description = "Adjust your walking speed safely",
        Default = 16,
        Min = 16,
        Max = 200,
        Rounding = 1,
        Callback = function(Value)
            currentWalkSpeed = tonumber(Value) or 16
        end
    })

    local JumpPowerSlider = Tabs.LocalPlayer:AddSlider("JP_Slider", {
        Title = "Jump Power",
        Description = "Zmień wysokość swojego skoku",
        Default = 50,
        Min = 50,
        Max = 500,
        Rounding = 0,
        Callback = function(Value)
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.UseJumpPower = true
                humanoid.JumpPower = Value
            end
        end
    })

    -- NoClip settings
    local noclipEnabled = false
    local noclipSpeed = 50

    local NoclipToggle = Tabs.LocalPlayer:AddToggle("NoclipToggle", {
        Title = "Enable Noclip",
        Default = false,
        Callback = function(Value)
            noclipEnabled = Value
            if noclipEnabled then
                Fluent:Notify({Title="Noclip", Content="Enabled! Use W/A/S/D to fly around.", Duration=3})
            else
                Fluent:Notify({Title="Noclip", Content="Disabled!", Duration=3})
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end
    })

    local NoclipSpeedSlider = Tabs.LocalPlayer:AddSlider("NoclipSpeedSlider", {
        Title = "Noclip Speed",
        Description = "Prędkość latania",
        Default = 50,
        Min = 10,
        Max = 300,
        Rounding = 0,
        Callback = function(Value)
            noclipSpeed = Value
        end
    })

    local chamsEnabled = false
    local ChamsToggle = Tabs.LocalPlayer:AddToggle("ChamsToggle", {
        Title = "Enable Rainbow Chams (Glow)",
        Default = false,
        Callback = function(Value)
            chamsEnabled = Value
            local char = LocalPlayer.Character
            
            if chamsEnabled then
                if char then
                    local highlight = char:FindFirstChild("RainbowChamsHighlight")
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "RainbowChamsHighlight"
                        highlight.FillTransparency = 0.5
                        highlight.OutlineTransparency = 0
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Parent = char
                    end
                end
                Fluent:Notify({Title="Rainbow Chams", Content="Enabled! You are now glowing.", Duration=3})
            else
                -- Usunięcie efektu po wyłączeniu
                if char then
                    local highlight = char:FindFirstChild("RainbowChamsHighlight")
                    if highlight then highlight:Destroy() end
                end
                Fluent:Notify({Title="Rainbow Chams", Content="Disabled!", Duration=3})
            end
        end
    })

    -- Noclip Loop
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")
    
    RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        
        if noclipEnabled and char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local camera = Workspace.CurrentCamera
                local moveDir = Vector3.new(0, 0, 0)
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDir = moveDir - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDir = moveDir + camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDir = moveDir + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    moveDir = moveDir - Vector3.new(0, 1, 0)
                end
                
                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit
                end
                
                hrp.Velocity = moveDir * noclipSpeed
            end
        end
        
        -- Rainbow Chams Color Shifter
        local char = LocalPlayer.Character
        if char and chamsEnabled then
            local highlight = char:FindFirstChild("RainbowChamsHighlight")
            if highlight then
                -- Tęczowa zmiana kolorów bazowana na tick()
                local hue = tick() % 5 / 5
                local color = Color3.fromHSV(hue, 1, 1)
                highlight.FillColor = color
                highlight.OutlineColor = Color3.new(1,1,1)
            end
        end
    end)


    --=========================================
    -- EXPLOITS TAB
    --=========================================

    -- WalkSpeed Bypass (CFrame logic)
    RunService.RenderStepped:Connect(function(deltaTime)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                local selectedSpeed = currentWalkSpeed
                if selectedSpeed > 16 then
                    -- Only apply extra speed if moving
                    if hum.MoveDirection.Magnitude > 0 then
                        -- Calculate the extra speed we need to add, since the humanoid natively moves at 16 (or its current WalkSpeed)
                        local currentWS = hum.WalkSpeed
                        local extraSpeed = selectedSpeed - currentWS
                        if extraSpeed > 0 then
                            local displacement = hum.MoveDirection * (extraSpeed * deltaTime)
                            -- By keeping the Y component 0 we prevent flying/glitching upwards
                            displacement = Vector3.new(displacement.X, 0, displacement.Z)
                            root.CFrame = root.CFrame + displacement
                        end
                    end
                end
            end
        end
    end)

    -- JumpPower Bypass (Velocity logic)
    UserInputService.JumpRequest:Connect(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                local selectedJP = currentJumpPower
                local defaultJumpForce = 50 -- Typical default JumpPower

                if selectedJP > defaultJumpForce then
                    -- Check if on floor to prevent infinite jumping in the air
                    local state = hum:GetState()
                    if state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics then
                        -- JumpPower translates to initial vertical velocity
                        root.Velocity = Vector3.new(root.Velocity.X, selectedJP, root.Velocity.Z)
                    end
                end
            end
        end
    end)

    -- EXPLOITS SETTINGS --
    Tabs.Exploits:AddSection("Changers")

    local MoneyInput = Tabs.Exploits:AddInput("MoneyChangerInput", {
        Title = "[CLIENT-SIDED] Money Changer",
        Default = "",
        Placeholder = "Example: 10000",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local numValue = tonumber(Value)
            if numValue then
                local playerData = LocalPlayer:FindFirstChild("PlayerData")
                if playerData then
                    local currencies = playerData:FindFirstChild("Currencies")
                    if currencies then
                        local balance = currencies:FindFirstChild("Balance")
                        if balance and balance:IsA("NumberValue") then
                            balance.Value = numValue
                            Fluent:Notify({Title="Success", Content="Money changed to " .. tostring(numValue), Duration=3})
                        end
                    end
                end
            end
        end
    })

    local RadiantInput = Tabs.Exploits:AddInput("HazardChangerInput", {
        Title = "[CLIENT-SIDED] Hazard Changer",
        Default = "",
        Placeholder = "Example: 5000",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local numValue = tonumber(Value)
            if numValue then
                local playerData = LocalPlayer:FindFirstChild("PlayerData")
                if playerData then
                    local currencies = playerData:FindFirstChild("Currencies")
                    if currencies then
                        local tickets = currencies:FindFirstChild("Tickets")
                        if tickets and tickets:IsA("NumberValue") then
                            tickets.Value = numValue
                            Fluent:Notify({Title="Success", Content="Radiant tickets changed to " .. tostring(numValue), Duration=3})
                        end
                    end
                end
            end
        end
    })

    Tabs.Exploits:AddSection("Duplicating")

    local selectedSkinToDup = ""
    local dupQuantity = 1
    local nexoRealDup_Registry = {} -- Rejestr klonowanych instancji dla persistencji

    local SkinSelectorDropdown = Tabs.Exploits:AddDropdown("SkinSelectorDropdown", {
        Title = "Select Skin",
        Values = {"Loading..."},
        Multi = false,
        Default = nil,
        Callback = function(Value)
            selectedSkinToDup = Value
        end
    })

    -- Funkcja do odświeżania listy posiadanych skinów w dropdownie
    local function updateOwnedSkinsDropdown()
        local owned = {}
        local inventory = game.Players.LocalPlayer:FindFirstChild("PlayerData") and game.Players.LocalPlayer.PlayerData:FindFirstChild("Inventory")
        if inventory then
            for _, item in ipairs(inventory:GetChildren()) do
                if not item:GetAttribute("NexoDuplicated") then
                    local name = item.Name
                    if not table.find(owned, name) then
                        table.insert(owned, name)
                    end
                end
            end
        end
        table.sort(owned)
        if #owned == 0 then table.insert(owned, "No Skins Owned") end
        SkinSelectorDropdown:SetValues(owned)
    end

    -- Inicjalizacja listy
    task.spawn(updateOwnedSkinsDropdown)

    local DupQuantityInput = Tabs.Exploits:AddInput("DupQuantityInput", {
        Title = "Amount",
        Default = "1",
        Placeholder = "...",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            dupQuantity = tonumber(Value) or 1
        end
    })

    -- Funkcja pomocnicza do wymuszenia odświeżenia UI gry
    local function refreshGameInventoryUI()
        local currentWindow = game.Players.LocalPlayer.PlayerGui:FindFirstChild("Windows") and game.Players.LocalPlayer.PlayerGui.Windows:FindFirstChild("CurrentWindow")
        if currentWindow then
            local oldVal = currentWindow.Value
            currentWindow.Value = ""
            task.wait(0.1)
            currentWindow.Value = oldVal
        end
    end

    Tabs.Exploits:AddButton({
        Title = "Inject Clones",
        Description = "Not Bannable!",
        Callback = function()
            if selectedSkinToDup == "" or selectedSkinToDup == "No Skins Owned" or selectedSkinToDup == "Loading..." then
                Fluent:Notify({Title="Error", Content="Select a skin you own first!", Duration=3})
                return
            end

            local inventory = game.Players.LocalPlayer.PlayerData.Inventory
            local original = inventory:FindFirstChild(selectedSkinToDup)

            if original then
                for i = 1, dupQuantity do
                    -- Tworzymy fizyczny klon w folderze Inventory gracza
                    local clone = original:Clone()
                    clone:SetAttribute("NexoDuplicated", true)
                    clone.Parent = inventory
                    
                    -- Zapisujemy dane do persistencji (żeby odtworzyć po ewentualnym czyszczeniu przez serwer)
                    table.insert(nexoRealDup_Registry, {
                        Name = selectedSkinToDup,
                        Attributes = clone:GetAttributes()
                    })
                end
                
                refreshGameInventoryUI()
                Fluent:Notify({Title="Success", Content="Cloned " .. tostring(dupQuantity) .. " items into real inventory folder!", Duration=3})
            else
                Fluent:Notify({Title="Error", Content="Could not find original item in your inventory!", Duration=3})
            end
        end
    })

    Tabs.Exploits:AddButton({
        Title = "Refresh List",
        Description = "Clears all cloned instances and registry.",
        Callback = function()
            nexoRealDup_Registry = {}
            local inventory = game.Players.LocalPlayer.PlayerData.Inventory
            local count = 0
            for _, item in ipairs(inventory:GetChildren()) do
                if item:GetAttribute("NexoDuplicated") then
                    item:Destroy()
                    count = count + 1
                end
            end
            refreshGameInventoryUI()
            Fluent:Notify({Title="Cleanup", Content="Deleted " .. tostring(count) .. " clones.", Duration=3})
        end
    })

    -- Persistence Guardian (Pilnowanie folderu Inventory)
    task.spawn(function()
        while task.wait(3) do
            if #nexoRealDup_Registry > 0 then
                local inventory = game.Players.LocalPlayer:FindFirstChild("PlayerData") and game.Players.LocalPlayer.PlayerData:FindFirstChild("Inventory")
                if inventory then
                    local clonesFound = 0
                    for _, item in ipairs(inventory:GetChildren()) do
                        if item:GetAttribute("NexoDuplicated") then
                            clonesFound = clonesFound + 1
                        end
                    end

                    -- Jeśli liczba klonów w folderze jest mniejsza niż w rejestrze (serwer usunął), przywracamy
                    if clonesFound < #nexoRealDup_Registry then
                        print("🛡️ [NEXO DUP] Persistence Guardian: Restoring missing clones...")
                        for _, data in ipairs(nexoRealDup_Registry) do
                            local original = inventory:FindFirstChild(data.Name)
                            if original then
                                local clone = original:Clone()
                                for attr, val in pairs(data.Attributes) do
                                    clone:SetAttribute(attr, val)
                                end
                                clone.Parent = inventory
                            end
                        end
                        refreshGameInventoryUI()
                    end
                end
            end
            -- Aktualizujemy też dropdown przy okazji
            updateOwnedSkinsDropdown()
        end
    end)


    
    Tabs.Exploits:AddSection("Others")

    local serverHopDelay = false
    local ServerHopButton = Tabs.Exploits:AddButton({
        Title = "ServerHop (Random Server)",
        Description = "Teleports you to a random active server.",
        Callback = function()
            if serverHopDelay then return end
            serverHopDelay = true
            
            Fluent:Notify({Title="ServerHop", Content="Searching for a new server...", Duration=5})
            
            local HttpService = game:GetService("HttpService")
            local TeleportService = game:GetService("TeleportService")
            local placeId = game.PlaceId
            
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"))
            end)
            
            if success and result and result.data then
                local servers = {}
                for _, server in ipairs(result.data) do
                    if server.playing and server.maxPlayers and server.playing < server.maxPlayers and server.playing > 0 and server.id ~= game.JobId then
                        table.insert(servers, server.id)
                    end
                end
                
                if #servers > 0 then
                    local randomServer = servers[math.random(1, #servers)]
                    Fluent:Notify({Title="ServerHop", Content="Found server! Teleporting...", Duration=5})
                    TeleportService:TeleportToPlaceInstance(placeId, randomServer, LocalPlayer)
                else
                    Fluent:Notify({Title="ServerHop", Content="No suitable servers found.", Duration=5})
                end
            else
                Fluent:Notify({Title="ServerHop", Content="Failed to fetch server list.", Duration=5})
            end
            
            task.wait(5)
            serverHopDelay = false
        end
    })

    local antiAfkEnabled = false
    local AntiAfkToggle = Tabs.Exploits:AddToggle("AntiAfkToggle", {
        Title = "Anti-AFK Disabler",
        Default = false,
        Callback = function(Value)
            antiAfkEnabled = Value
            if antiAfkEnabled then
                Fluent:Notify({Title="Anti-AFK", Content="Enabled! You won't be kicked for idling.", Duration=3})
            else
                Fluent:Notify({Title="Anti-AFK", Content="Disabled!", Duration=3})
            end
        end
    })

    -- Anti-AFK Logic
    LocalPlayer.Idled:Connect(function()
        if antiAfkEnabled then
            local virtualUser = game:GetService("VirtualUser")
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new())
            -- print("🛡️ [NEXO] Anti-AFK: Prevented idle kick.")
        end
    end)

    -- (Spy removed)
    -- INVENTORY SETTINGS --

    -- ============================================
    -- PLAYER INVENTORY VIEWER
    -- ============================================
    Tabs.Inventory:AddSection("Inventory Viewer")

    local viewerTargetPlayer = nil
    local viewerIsActive = false

    -- Helper: find the native inventory GUI frame
    local function findNativeInventoryUI()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        for _, desc in ipairs(playerGui:GetDescendants()) do
            if desc.Name == "InventoryFrame" and desc:FindFirstChild("Contents") then
                return desc
            end
        end
        return nil
    end

    local PlayerNameInput = Tabs.Inventory:AddInput("PlayerNameInput", {
        Title = "Player Name",
        Default = "",
        Placeholder = "(...)",
        Numeric = false,
        Finished = true,
        Callback = function(Value)
            if Value == "" then
                viewerTargetPlayer = nil
                Fluent:Notify({Title="Viewer", Content="Cleared player selection.", Duration=2})
                return
            end

            local searchLower = string.lower(Value)
            local found = nil

            for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
                if string.find(string.lower(plr.Name), searchLower, 1, true) or string.find(string.lower(plr.DisplayName), searchLower, 1, true) then
                    found = plr
                    break
                end
            end

            if found then
                viewerTargetPlayer = found
                local displayInfo = found.DisplayName ~= found.Name and (found.DisplayName .. " (@" .. found.Name .. ")") or found.Name
                Fluent:Notify({Title="Player Found", Content="Selected: " .. displayInfo, Duration=3})
            else
                viewerTargetPlayer = nil
                Fluent:Notify({Title="Error", Content="No player found matching '" .. Value .. "'", Duration=3})
            end
        end
    })

    Tabs.Inventory:AddButton({
        Title = "View Player Inventory",
        Description = "Opens the game's inventory UI with selected player's items.",
        Callback = function()
            if not viewerTargetPlayer then
                Fluent:Notify({Title="Error", Content="No player selected! Type a name first.", Duration=3})
                return
            end

            if not viewerTargetPlayer.Parent then
                Fluent:Notify({Title="Error", Content="Player left the server!", Duration=3})
                viewerTargetPlayer = nil
                return
            end

            local targetPlayerData = viewerTargetPlayer:FindFirstChild("PlayerData")
            if not targetPlayerData then
                Fluent:Notify({Title="Error", Content="Cannot access PlayerData for this player.", Duration=3})
                return
            end

            local targetInventory = targetPlayerData:FindFirstChild("Inventory")
            if not targetInventory then
                Fluent:Notify({Title="Error", Content="Cannot access Inventory for this player.", Duration=3})
                return
            end

            -- Force-open the game's inventory window
            local windowsGui = LocalPlayer.PlayerGui:FindFirstChild("Windows")
            if windowsGui then
                -- Make the Windows ScreenGui visible/enabled
                if windowsGui:IsA("ScreenGui") then
                    windowsGui.Enabled = true
                elseif windowsGui:IsA("GuiObject") then
                    windowsGui.Visible = true
                end

                -- Set CurrentWindow to Inventory
                local currentWindow = windowsGui:FindFirstChild("CurrentWindow")
                if currentWindow then
                    currentWindow.Value = "Inventory"
                end
            end
            task.wait(0.5) -- let the game's own inventory script finish populating

            -- Find native inventory GUI
            local inventoryFrame = findNativeInventoryUI()
            if not inventoryFrame then
                Fluent:Notify({Title="Error", Content="Could not find the game's inventory UI!", Duration=3})
                return
            end

            -- Make sure InventoryFrame and all its ancestors are visible
            local current = inventoryFrame
            while current do
                if current:IsA("GuiObject") then
                    current.Visible = true
                elseif current:IsA("ScreenGui") then
                    current.Enabled = true
                end
                current = current.Parent
            end

            local inventoryParent = inventoryFrame.Parent
            local contents = inventoryFrame.Contents

            -- Load Items module
            local success, Items = pcall(function()
                return require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Items"))
            end)
            if not success or type(Items) ~= "table" then
                Fluent:Notify({Title="Error", Content="Failed to load Items module!", Duration=3})
                return
            end

            -- Load Rarities module
            local rSuccess, Rarities = pcall(function()
                return require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Rarities"))
            end)
            if not rSuccess then Rarities = {} end

            -- Load number formatter
            local fmtSuccess, NumberFormatter = pcall(function()
                return require(game:GetService("ReplicatedStorage"):WaitForChild("FormatNumber").Main).NumberFormatter.with()
            end)

            -- Get ItemTemplate
            local ItemTemplate = game:GetService("ReplicatedStorage").Misc:FindFirstChild("ItemTemplate")
            if not ItemTemplate then
                Fluent:Notify({Title="Error", Content="ItemTemplate not found!", Duration=3})
                return
            end

            -- Clear current contents (preserve UIGridLayout)
            local gridLayout = contents:FindFirstChild("UIGridLayout")
            if gridLayout then gridLayout = gridLayout:Clone() end
            contents:ClearAllChildren()
            if gridLayout then gridLayout.Parent = contents end

            -- Set grid cell sizing (same logic as the game's inventory script)
            if gridLayout then
                local viewportX = game:GetService("Workspace").CurrentCamera.ViewportSize.X
                local ratio = (viewportX - 800) / 3040
                local cols = 5 + 7 * math.clamp(ratio, 0, 1) + 0.5
                local cellFraction = 1 / math.floor(cols)
                local cellPixels = inventoryFrame.AbsoluteSize.X * cellFraction
                gridLayout.CellSize = UDim2.new(cellFraction, 0, 0, cellPixels)
            end

            -- Hide action buttons (view-only mode)
            pcall(function() inventoryParent.Sell.Visible = false end)
            pcall(function() inventoryParent.Equip.Visible = false end)
            pcall(function() inventoryParent.Lock.Visible = false end)
            pcall(function() inventoryParent.SelectedText.Visible = false end)
            pcall(function() inventoryParent.SelectedValueText.Visible = false end)

            -- Get target player's items
            local children = targetInventory:GetChildren()
            if #children == 0 then
                pcall(function() inventoryParent.Empty.Visible = true end)
                Fluent:Notify({Title="Info", Content=viewerTargetPlayer.Name .. " has an empty inventory.", Duration=3})
                viewerIsActive = true
                return
            end
            pcall(function() inventoryParent.Empty.Visible = false end)

            -- Rarity ranking for sorting
            local rarityRanks = {
                ["Consumer Grade"] = 1, ["Industrial Grade"] = 2, ["Mil-Spec"] = 3,
                ["Restricted"] = 4, ["Classified"] = 5, ["Covert"] = 6,
                ["Extraordinary"] = 7, ["Special"] = 8, ["Contraband"] = 9
            }

            -- Build sorted item list
            local itemList = {}
            local totalValue = 0

            for _, item in ipairs(children) do
                local itemData = Items[item.Name]
                if itemData and not item:GetAttribute("Escrow") then
                    local wear = item:GetAttribute("Wear")
                    local stattrak = item:GetAttribute("Stattrak") == true
                    local wearData = nil
                    local price = 0

                    if itemData.Wears then
                        if wear and itemData.Wears[wear] then
                            wearData = itemData.Wears[wear]
                        else
                            -- Wear not replicated — pick the first available wear
                            for wn, wd in pairs(itemData.Wears) do
                                wear = wn
                                wearData = wd
                                break
                            end
                        end
                    end

                    if wearData then
                        if stattrak then
                            price = wearData.StatTrak or wearData.Normal or 0
                        else
                            price = wearData.Normal or wearData.StatTrak or 0
                        end
                    end

                    totalValue = totalValue + price

                    table.insert(itemList, {
                        Instance = item,
                        Data = itemData,
                        Wear = wear or "?",
                        Stattrak = stattrak,
                        Price = price,
                        RarityRank = rarityRanks[itemData.Rarity] or 0
                    })
                end
            end

            -- Sort by price descending
            table.sort(itemList, function(a, b) return a.Price > b.Price end)

            -- Populate the native grid with item cards
            for _, skinInfo in ipairs(itemList) do
                local frame = ItemTemplate:Clone()
                frame:SetAttribute("ItemId", skinInfo.Instance.Name)
                frame:SetAttribute("Price", skinInfo.Price)
                frame:SetAttribute("selected", false)
                frame.ItemName.Text = skinInfo.Data.Name or skinInfo.Instance.Name
                frame.Wear.Text = skinInfo.Wear
                frame.Stattrak.Visible = skinInfo.Stattrak
                frame.Background.ImageColor3 = Rarities[skinInfo.Data.Rarity] or Color3.fromRGB(100, 100, 100)
                frame.ItemImage.Image = skinInfo.Data.Image or ""

                -- Price formatting (same style as game)
                local priceStr = string.format("%.2f", skinInfo.Price)
                local wholePart = math.floor(tonumber(priceStr))
                local decPart = string.match(priceStr, "%.(%d+)")
                if fmtSuccess and NumberFormatter then
                    frame.ItemValue.Text = "$" .. NumberFormatter:Format(wholePart) .. "." .. decPart
                else
                    frame.ItemValue.Text = "$" .. tostring(wholePart) .. "." .. decPart
                end

                -- Handle limited items (same logic as game)
                if skinInfo.Data.Limited then
                    if skinInfo.Data.Limited == "Valentines2026" then
                        frame.Limited.Image = "rbxassetid://101971012944506"
                    elseif skinInfo.Data.Limited == "Hazard2026" then
                        frame.Limited.Image = "rbxassetid://85727053138498"
                    end
                    frame.Limited.Visible = true
                    frame.Limited:SetAttribute("isLimited", true)
                    frame.ItemValue.Visible = false
                end

                -- Remove odds and hide lock (view-only)
                pcall(function() frame.Odds:Destroy() end)
                frame.Locked.Visible = false

                frame.Parent = contents
            end

            -- Reset scroll position
            contents.CanvasPosition = Vector2.new(0, 0)
            viewerIsActive = true

            -- Notify with summary
            local totalStr = string.format("%.2f", totalValue)
            local displayName = viewerTargetPlayer.DisplayName ~= viewerTargetPlayer.Name
                and (viewerTargetPlayer.DisplayName .. " (@" .. viewerTargetPlayer.Name .. ")")
                or viewerTargetPlayer.Name
            Fluent:Notify({
                Title = "📋 " .. displayName,
                Content = tostring(#itemList) .. " skins | Total Value: ~$" .. totalStr,
                Duration = 5
            })
        end
    })

    Tabs.Inventory:AddSection("Auto Sell")

    local maxSellPrice = 0
    local autoSellEnabled = false
    
    local MaxSellInput = Tabs.Inventory:AddInput("MaxSellPriceInput", {
        Title = "Max Sell Price",
        Default = "0",
        Placeholder = "Enter max price (e.g. 50)",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            maxSellPrice = tonumber(Value) or 0
        end
    })
    
    local AutoSellToggle = Tabs.Inventory:AddToggle("AutoSellToggle", {
        Title = "Enable Auto Sell",
        Default = false,
        Callback = function(Value)
            autoSellEnabled = Value
            if autoSellEnabled then
                Fluent:Notify({Title="Auto Sell", Content="Enabled! Selling items under $" .. tostring(maxSellPrice), Duration=3})
            else
                Fluent:Notify({Title="Auto Sell", Content="Disabled!", Duration=3})
            end
        end
    })
    
    -- Auto Sell Loop Logic
    task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local sellRemote = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:WaitForChild("Sell", 5)
        
        while task.wait(1) do
            if autoSellEnabled and sellRemote then
                local playerData = LocalPlayer:FindFirstChild("PlayerData")
                if playerData then
                    -- Support basic common names for inventory folder
                    local foundInv = playerData:FindFirstChild("Inventory") or playerData:FindFirstChild("Skins") or playerData:FindFirstChild("Weapons") or playerData:FindFirstChild("Items")
                    
                    if foundInv then
                        local success, Items = pcall(function()
                            return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Items"))
                        end)
                        
                        if success and type(Items) == "table" then
                            for _, item in ipairs(foundInv:GetChildren()) do
                                if not autoSellEnabled then break end -- Break if turned off mid-sell
                                
                                local itemName = item:GetAttribute("Name") or (item:FindFirstChild("Name") and item.Name.Value) or item.Name
                                local wear = item:GetAttribute("Wear") or (item:FindFirstChild("Wear") and item.Wear.Value) or "Unknown Wear"
                                
                                local isStatTrak = item:GetAttribute("Stattrak") or item:GetAttribute("StatTrak") or item:GetAttribute("statTrak") or false
                                if not isStatTrak and item:FindFirstChild("Stattrak") then isStatTrak = item.Stattrak.Value end
                                if not isStatTrak and item:FindFirstChild("StatTrak") then isStatTrak = item.StatTrak.Value end
                                if not isStatTrak and item:FindFirstChild("statTrak") then isStatTrak = item.statTrak.Value end
                                
                                local isLocked = item:GetAttribute("Locked") or (item:FindFirstChild("Locked") and item.Locked.Value) or false
                                
                                if not isLocked then -- Never logic-sell locked items
                                    local typeStr = isStatTrak and "StatTrak" or "Normal"
                                    local itemData = Items[itemName]
                                    
                                    if itemData and itemData.Wears and itemData.Wears[wear] and itemData.Wears[wear][typeStr] then
                                        local priceVal = itemData.Wears[wear][typeStr]
                                        
                                        -- Sell if marketable and strictly under max sell price
                                        if priceVal ~= -1 and priceVal < maxSellPrice then
                                            -- RemoteEvent takes a table of item parameters based on decompiled code
                                            local sellData = {
                                                [1] = {
                                                    ["Name"] = itemName,
                                                    ["Wear"] = wear,
                                                    ["Stattrak"] = isStatTrak,
                                                    ["Age"] = item:GetAttribute("Age") or (item:FindFirstChild("Age") and item.Age.Value) or 0
                                                }
                                            }
                                            
                                            -- Fire the remote event
                                            sellRemote:InvokeServer(sellData)
                                            -- Add small wait to avoid overwhelming server
                                            task.wait(0.15) 
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    
    -- AUTOMATION SETTINGS --
    Tabs.Automation:AddSection("Farming")
    
    local autoQuestsEnabled = false
    local stopBalanceLimit = 0
    
    local StopBalanceInput = Tabs.Automation:AddInput("StopBalanceInput", {
        Title = "When to Stop (Account Balance $)",
        Default = "",
        Placeholder = "Example when I drop below $1000",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            stopBalanceLimit = tonumber(Value) or 0
        end
    })
    
    local AutoQuestsToggle = Tabs.Automation:AddToggle("AutoQuestsToggle", {
        Title = "Enable Auto Quests",
        Default = false,
        Callback = function(Value)
            autoQuestsEnabled = Value
            if autoQuestsEnabled then
                Fluent:Notify({Title="Auto Quests", Content="Started! Will stop if balance < $" .. tostring(stopBalanceLimit), Duration=3})
            else
                Fluent:Notify({Title="Auto Quests", Content="Disabled!", Duration=3})
            end
        end
    })

    local autoEventsEnabled = false
    local AutoEventsToggle = Tabs.Automation:AddToggle("AutoEventsToggle", {
        Title = "Auto Events (ALL!)",
        Default = false,
        Callback = function(Value)
            autoEventsEnabled = Value
            if autoEventsEnabled then
                Fluent:Notify({Title="Auto Events", Content="Tracking active events in console (F9)!", Duration=3})
            else
                Fluent:Notify({Title="Auto Events", Content="Tracking disabled.", Duration=3})
            end
        end
    })
    
    -- Auto Events Loop Logic (Workspace Detection Refactor)
    task.spawn(function()
        local Players = game:GetService("Players")
        local Workspace = game:GetService("Workspace")
        local LocalPlayer = Players.LocalPlayer

        while task.wait(0.5) do
            if autoEventsEnabled then
                local tempFolder = Workspace:FindFirstChild("Temp")
                local meteorHitbox = tempFolder and tempFolder:FindFirstChild("MeteorHitHitbox")
                
                if meteorHitbox then
                    print("🌟 [AUTO EVENTS] EVENT IS ACTIVE: Meteors Detected in Workspace.Temp!")
                    
                    -- Teleportacja do eventu
                    pcall(function()
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        -- Szukamy części do której można się tepnąć (PrimaryPart lub jakikolwiek BasePart)
                        local targetPart = meteorHitbox.PrimaryPart or meteorHitbox:FindFirstChildWhichIsA("BasePart") or meteorHitbox:FindFirstChild("HumanoidRootPart")
                        
                        if hrp and targetPart then
                            -- Tepamy się 5 studów nad hitbox żeby nie utknąć w ziemi
                            hrp.CFrame = targetPart.CFrame * CFrame.new(0, 5, 0)
                        end
                    end)
                else
                    print("🔍 [AUTO EVENTS] Searching for event... (Checking Workspace.Temp)")
                end
            end
        end
    end)
    

    Tabs.Automation:AddSection("Bonuses")

    local autoExchangeEnabled = false
    local AutoExchangeToggle = Tabs.Automation:AddToggle("AutoExchangeToggle", {
        Title = "Auto Exchange (NPC)",
        Default = false,
        Callback = function(Value)
            autoExchangeEnabled = Value
            if autoExchangeEnabled then
                Fluent:Notify({Title="Auto Exchange", Content="Started! Constantly sending exchange requests.", Duration=3})
            else
                Fluent:Notify({Title="Auto Exchange", Content="Disabled.", Duration=3})
            end
        end
    })
    
    task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local exchangeRemote = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:FindFirstChild("ExchangeEvent")
        
        while task.wait(1) do
            if autoExchangeEnabled and exchangeRemote then
                pcall(function()
                    exchangeRemote:FireServer("Exchange")
                end)
            end
        end
    end)
    
    local autoGiftsEnabled = false
    local AutoGiftsToggle = Tabs.Automation:AddToggle("AutoGiftsToggle", {
        Title = "Enable Auto Gifts",
        Default = false,
        Callback = function(Value)
            autoGiftsEnabled = Value
            if autoGiftsEnabled then
                Fluent:Notify({Title="Auto Gifts", Content="Started! Claiming playtime gifts securely.", Duration=3})
            else
                Fluent:Notify({Title="Auto Gifts", Content="Disabled!", Duration=3})
            end
        end
    })
    
    local autoLevelRewardsEnabled = false
    local AutoLevelRewardsToggle = Tabs.Automation:AddToggle("AutoLevelRewardsToggle", {
        Title = "Enable Auto Level Rewards",
        Default = false,
        Callback = function(Value)
            autoLevelRewardsEnabled = Value
            if autoLevelRewardsEnabled then
                Fluent:Notify({Title="Auto Level Rewards", Content="Started! Opening level cases.", Duration=3})
            else
                Fluent:Notify({Title="Auto Level Rewards", Content="Disabled!", Duration=3})
            end
        end
    })
    
    Tabs.Automation:AddSection("Case Opening")
    
    local caseList = {}
    local caseMap = {}
    local selectedCaseId = nil
    local selectedCaseName = nil
    local casesToOpenAmount = 1
    local autoOpenCasesEnabled = false
    
    local webhookEnabled = true
    local webhookUrl = ""
    _G.announceSkinsMapVar = {}
    local selectedSkinsToAnnounce = {}
    
    local CaseDropdown = Tabs.Automation:AddDropdown("CaseSelect", {
        Title = "Select Case",
        Values = {"Loading..."},
        Multi = false,
        Default = nil,
        Callback = function(Value)
            selectedCaseId = caseMap[Value]
            if Value then
                selectedCaseName = string.split(Value, " | ")[1]
            end
            if selectedCaseId and _G.AnnounceSkinsDropdownVar then
                task.spawn(function()
                    pcall(function()
                        local casesModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Cases"))
                        local itemsModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Items"))
                        
                        local caseData = casesModule[selectedCaseId]
                        if caseData and caseData.Drops then
                            local tempSkins = {}
                            local seenSkins = {}
                            
                            for _, drop in ipairs(caseData.Drops) do
                                local itemData = itemsModule[drop.Item]
                                if itemData then
                                    local wear = drop.Wear
                                    if wear == "All" then wear = "Factory New" end
                                    
                                    local price = 0
                                    if itemData.Wears and itemData.Wears[wear] then
                                        if drop.Stattrak then
                                            price = itemData.Wears[wear].StatTrak or 0
                                        else
                                            price = itemData.Wears[wear].Normal or 0
                                        end
                                    end
                                    
                                    local formattedName = itemData.Name .. " (" .. wear .. ")" .. (drop.Stattrak and " [StatTrak]" or "")
                                    if not seenSkins[formattedName] then
                                        seenSkins[formattedName] = true
                                        local priceStr = tostring(math.floor(price))
                                        local displayStr = formattedName .. " | " .. priceStr .. "$"
                                        
                                        table.insert(tempSkins, {
                                            display = displayStr,
                                            price = price,
                                            rawName = formattedName,
                                            skinName = itemData.Name,
                                            skinWear = wear,
                                            skinPriceFormatted = priceStr .. "$"
                                        })
                                    end
                                end
                            end
                            
                            table.sort(tempSkins, function(a, b) return a.price > b.price end)
                            
                            local finalSkinsList = {}
                            table.clear(_G.announceSkinsMapVar)
                            for _, s in ipairs(tempSkins) do
                                table.insert(finalSkinsList, s.display)
                                _G.announceSkinsMapVar[s.display] = s
                            end
                            
                            if #finalSkinsList > 0 then
                                _G.AnnounceSkinsDropdownVar:SetValues(finalSkinsList)
                                _G.AnnounceSkinsDropdownVar:SetValue({})
                            else
                                _G.AnnounceSkinsDropdownVar:SetValues({"No Skins Found"})
                                _G.AnnounceSkinsDropdownVar:SetValue({})
                            end
                        end
                    end)
                end)
            end
        end
    })
    
    local CaseSlider = Tabs.Automation:AddSlider("CaseAmountSlider", {
        Title = "How Many Cases at Once",
        Description = "Limit is up to 5.",
        Default = 1,
        Min = 1,
        Max = 5,
        Rounding = 0,
        Callback = function(Value)
            casesToOpenAmount = Value
        end
    })
    
    local caseStopBalanceLimit = 0
    local CaseStopLimitInput = Tabs.Automation:AddInput("CaseStopLimitInput", {
        Title = "Stop Limit (Balance)",
        Default = "0",
        Placeholder = "Enter limit...",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local parsed = tonumber(Value)
            if parsed then
                caseStopBalanceLimit = parsed
            else
                caseStopBalanceLimit = 0
            end
        end
    })
    
    local WebhookInput = Tabs.Automation:AddInput("WebhookInput", {
        Title = "Enter Webhook",
        Default = "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Numeric = false,
        Finished = true,
        Callback = function(Value)
            webhookUrl = Value
        end
    })
    
    _G.AnnounceSkinsDropdownVar = Tabs.Automation:AddDropdown("AnnounceSkinsDropdown", {
        Title = "Choose Skins to Announce",
        Values = {"No Case Selected"},
        Multi = true,
        Default = {},
        Callback = function(Value)
            selectedSkinsToAnnounce = Value
        end
    })

    local caseAutoSellEnabled = false
    local caseAutoSellMaxPrice = 0
    local profitStats = {profit = 0, opened = 0, issued = 0, earned = 0}
    
    local CaseAutoSellToggle = Tabs.Automation:AddToggle("CaseAutoSellToggle", {
        Title = "Auto Sell Unboxed Items",
        Default = false,
        Callback = function(Value)
            caseAutoSellEnabled = Value
            if not Value then
                Fluent:Notify({Title="Profit Calculator", Content="Profit Calculator is disabled while Auto Sell is OFF!", Duration=4})
            end
        end
    })
    
    local CaseMaxSellInput = Tabs.Automation:AddInput("CaseMaxSellInput", {
        Title = "Max Sell Price (Auto Sell)",
        Default = "0",
        Placeholder = "Enter max price...",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local parsed = tonumber(Value)
            if parsed then
                caseAutoSellMaxPrice = parsed
            else
                caseAutoSellMaxPrice = 0
            end
        end
    })
    
    local ProfitParagraph = Tabs.Automation:AddParagraph({
        Title = "Profit Calculator",
        Content = "Profit Made: +0$\nOpened: 0 Cases\nIssued on Cases: 0$\nEarned: 0$\n\n⚠ Warning! Profit Calculator is ONLY Working when Auto Sell is Enabled!"
    })
    
    local function UpdateCaseProfitUI()
        local prefix = profitStats.profit > 0 and "+" or ""
        ProfitParagraph:SetDesc(string.format("Profit Made: %s%d$\nOpened: %d Cases\nIssued on Cases: %d$\nEarned: %d$\n\n⚠ Warning! Profit Calculator is ONLY Working when Auto Sell is Enabled!", prefix, profitStats.profit, profitStats.opened, profitStats.issued, profitStats.earned))
    end
    
    local AutoOpenToggle = Tabs.Automation:AddToggle("AutoOpenToggle", {
        Title = "Auto Open Selected Case",
        Default = false,
        Callback = function(Value)
            autoOpenCasesEnabled = Value
            if autoOpenCasesEnabled then
                Fluent:Notify({Title="Case Opening", Content="Auto Opening Started!", Duration=3})
            else
                Fluent:Notify({Title="Case Opening", Content="Stopped.", Duration=3})
            end
        end
    })
    
    task.spawn(function()
        pcall(function()
            local casesModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Cases"))
            
            _G.casePriceMapVar = {}
            local tempSortData = {}
            for caseId, caseData in pairs(casesModule) do
                if type(caseData) == "table" and caseData.Name and caseData.Price ~= nil then
                    if not caseData.AdminOnly then
                        local displayName = caseData.Name .. " | " .. tostring(caseData.Price) .. "$"
                        table.insert(tempSortData, {
                            displayName = displayName,
                            price = tonumber(caseData.Price) or 0
                        })
                        caseMap[displayName] = caseId
                        _G.casePriceMapVar[caseId] = tonumber(caseData.Price) or 0
                        
                        -- Find cheapest valid battle case 
                        -- It cannot be a Level, Group, Free or VIP case. It MUST have a price > 0.
                        if caseData.ForBattles == true and tonumber(caseData.Price) and tonumber(caseData.Price) > 0 then
                            if not caseData.LevelReq and not caseData.GroupOnly and not caseData.VipOnly and not caseData.VIP and not caseData.IsPremium and not caseData.IsFree then
                                local cPrice = tonumber(caseData.Price)
                                if not _G.cheapestBattleCase or cPrice < _G.cheapestBattleCasePrice then
                                    _G.cheapestBattleCase = caseId
                                    _G.cheapestBattleCasePrice = cPrice
                                end
                            end
                        end
                    end
                end
            end
            
            pcall(function() print("[Nexo Hub] Selected Cheapest Battle Case: " .. tostring(_G.cheapestBattleCase) .. " for $" .. tostring(_G.cheapestBattleCasePrice)) end)
            
            table.sort(tempSortData, function(a, b) return a.price < b.price end)
            
            for _, data in ipairs(tempSortData) do
                table.insert(caseList, data.displayName)
            end
            
            CaseDropdown:SetValues(caseList)
            CaseDropdown:SetValue(caseList[1])
        end)
    end)
    
    task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local HttpService = game:GetService("HttpService")
        local openCaseRemote = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:FindFirstChild("OpenCase")
        local reqFunc = request or http_request or (syn and syn.request)
        
        while task.wait(0.5) do
            if autoOpenCasesEnabled and openCaseRemote and selectedCaseId then
                local playerData = LocalPlayer:FindFirstChild("PlayerData")
                if playerData then
                    local currencies = playerData:FindFirstChild("Currencies")
                    local balance = currencies and currencies:FindFirstChild("Balance")
                    local currentBalance = balance and balance.Value or 0
                    
                    if currentBalance >= caseStopBalanceLimit then
                        local cost = (_G.casePriceMapVar[selectedCaseId] or 0) * casesToOpenAmount
                        if caseAutoSellEnabled then
                            profitStats.issued = profitStats.issued + cost
                            profitStats.opened = profitStats.opened + casesToOpenAmount
                            profitStats.profit = profitStats.profit - cost
                            UpdateCaseProfitUI()
                        end
                        
                        local result = nil
                        pcall(function()
                            result = openCaseRemote:InvokeServer(selectedCaseId, casesToOpenAmount, true, false)
                        end)
                        
                        if result and type(result) == "table" then
                            local sellRemote = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:FindFirstChild("Sell")
                            
                            pcall(function()
                                local itemsModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Items"))
                                local sellDataArray = {}
                                local usedInstances = {}
                                local foundInv = playerData:FindFirstChild("Inventory") or playerData:FindFirstChild("Skins") or playerData:FindFirstChild("Weapons") or playerData:FindFirstChild("Items")
                                
                                for _, drop in pairs(result) do
                                    local itemData = itemsModule[drop.Item]
                                    if itemData then
                                        local wear = drop.Wear
                                        if wear == "All" then wear = "Factory New" end
                                        
                                        local price = 0
                                        if itemData.Wears and itemData.Wears[wear] then
                                            if drop.Stattrak then
                                                price = itemData.Wears[wear].StatTrak or 0
                                            else
                                                price = itemData.Wears[wear].Normal or 0
                                            end
                                        end
                                        
                                        if caseAutoSellEnabled and price <= caseAutoSellMaxPrice and sellRemote and foundInv then
                                            for _, item in ipairs(foundInv:GetChildren()) do
                                                if not usedInstances[item] then
                                                    local itemName = item:GetAttribute("Name") or (item:FindFirstChild("Name") and item.Name.Value) or item.Name
                                                    local itemWear = item:GetAttribute("Wear") or (item:FindFirstChild("Wear") and item.Wear.Value) or "Unknown Wear"
                                                    local itemST = item:GetAttribute("Stattrak") or item:GetAttribute("StatTrak") or item:GetAttribute("statTrak") or false
                                                    if not itemST and item:FindFirstChild("Stattrak") then itemST = item.Stattrak.Value end
                                                    if not itemST and item:FindFirstChild("StatTrak") then itemST = item.StatTrak.Value end
                                                    if not itemST and item:FindFirstChild("statTrak") then itemST = item.statTrak.Value end
                                                    local isLocked = item:GetAttribute("Locked") or (item:FindFirstChild("Locked") and item.Locked.Value) or false
                                                    
                                                    if not isLocked and itemName == drop.Item and itemWear == wear and itemST == (drop.Stattrak or false) then
                                                        usedInstances[item] = true
                                                        local age = item:GetAttribute("Age") or (item:FindFirstChild("Age") and item.Age.Value) or 0
                                                        table.insert(sellDataArray, {
                                                            ["Name"] = itemName,
                                                            ["Wear"] = itemWear,
                                                            ["Stattrak"] = itemST,
                                                            ["Age"] = age
                                                        })
                                                        profitStats.earned = profitStats.earned + price
                                                        profitStats.profit = profitStats.profit + price
                                                        UpdateCaseProfitUI()
                                                        break
                                                    end
                                                end
                                            end
                                        end

                                        if webhookEnabled and webhookUrl ~= "" and reqFunc then
                                            local dropFormattedName = itemData.Name .. " (" .. wear .. ")" .. (drop.Stattrak and " [StatTrak]" or "")
                                            local foundMatch = nil
                                            for disp, isSelected in pairs(selectedSkinsToAnnounce) do
                                                if isSelected and _G.announceSkinsMapVar[disp] then
                                                    if _G.announceSkinsMapVar[disp].rawName == dropFormattedName then
                                                        foundMatch = _G.announceSkinsMapVar[disp]
                                                        break
                                                    end
                                                end
                                            end
                                            if foundMatch then
                                                local cName = selectedCaseName or selectedCaseId
                                                
                                                local embedColor = 16766720 -- Gold default
                                                if foundMatch.skinWear == "Factory New" then embedColor = 65280
                                                elseif foundMatch.skinWear == "Minimal Wear" then embedColor = 43520
                                                elseif foundMatch.skinWear == "Field-Tested" then embedColor = 16776960
                                                elseif foundMatch.skinWear == "Well-Worn" then embedColor = 16753920
                                                elseif foundMatch.skinWear == "Battle-Scarred" then embedColor = 16711680 end
                                                
                                                local payload = HttpService:JSONEncode({
                                                    content = "@everyone",
                                                    username = "Nexo Hub | Case Paradise - Beta",
                                                    embeds = {{
                                                        title = "🎉 New Skin Unboxed!",
                                                        description = "You got **" .. foundMatch.skinName .. "** from **" .. cName .. "**!",
                                                        color = embedColor,
                                                        fields = {
                                                            {name = "Wear", value = foundMatch.skinWear, inline = true},
                                                            {name = "Price", value = foundMatch.skinPriceFormatted, inline = true}
                                                        },
                                                        footer = {text = "Nexo Hub | Case Paradise - Beta"}
                                                    }}
                                                })
                                                reqFunc({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload})
                                            end
                                        end
                                    end
                                end
                                
                                if #sellDataArray > 0 and sellRemote then
                                    sellRemote:InvokeServer(sellDataArray)
                                end
                            end)
                        end
                        task.wait(1.5) -- Safety delay similar to quests
                    else
                        Fluent:Notify({Title="Case Opening", Content="Stopped! Reached safety balance stop limit.", Duration=5})
                        AutoOpenToggle:SetValue(false)
                    end
                end
            end
        end
    end)
    
    -- Auto Quests Loop Logic
    task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local openCaseRemote = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:FindFirstChild("OpenCase")
        
        -- Wątek ukrywający GUI bitew, kiedy Auto Quests są włączone
        task.spawn(function()
            local Lighting = game:GetService("Lighting")
            while task.wait(0.1) do
                if autoQuestsEnabled then
                    pcall(function()
                        -- Precyzyjniejsze ukrywanie interfejsu The Battle, tylko w obrębie Case Battles okna!
                        local windowsUI = Players.LocalPlayer.PlayerGui:FindFirstChild("Windows")
                        if windowsUI then
                            local caseBattlesUI = windowsUI:FindFirstChild("Case Battles")
                            if caseBattlesUI then
                                -- Ukrywamy glowny "BattleFrame" (ekran bycia w samej bitwie)
                                local battleFrame = caseBattlesUI:FindFirstChild("BattleFrame")
                                if battleFrame and battleFrame.Visible then
                                    battleFrame.Visible = false
                                end
                            end
                        end
                        
                        -- Czasami gry dodają rozmycie tła w trakcie eventu bitwy, też to wyłączymy
                        for _, effect in ipairs(Lighting:GetChildren()) do
                            if effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect") then
                                effect.Enabled = false
                            end
                        end
                    end)
                end
            end
        end)
        
        local lastBattleAttempt = 0
        
        while task.wait(0.5) do
            if autoQuestsEnabled then
                pcall(function()
                    local DynamicPlayer = Players.LocalPlayer
                    local playerData = DynamicPlayer and DynamicPlayer:FindFirstChild("PlayerData")
                    if playerData then
                        local currencies = playerData:FindFirstChild("Currencies")
                        local balance = currencies and currencies:FindFirstChild("Balance")
                        local currentBalance = balance and balance.Value or 0
                        
                        if currentBalance >= stopBalanceLimit then
                            local questsFolder = playerData:FindFirstChild("Quests")
                            if questsFolder then
                                local didOpen = false
                                local didBattle = false
                                
                                for i = 1, 3 do
                                    if not autoQuestsEnabled then break end
                                    
                                    local questData = questsFolder:FindFirstChild(tostring(i))
                                    if questData and questData:IsA("StringValue") and questData.Value ~= "Finished" then
                                        local actionVal = questData.Value
                                        local reqVal = questData:FindFirstChild("Requirement") and questData.Requirement.Value or 0
                                        local progVal = questData:FindFirstChild("Progress") and questData.Progress.Value or 0
                                        local subjectVal = questData:FindFirstChild("Subject") and questData.Subject.Value or ""
                                        
                                        if progVal < tonumber(reqVal) then
                                            -- Has progress remaining
                                            
                                            if actionVal == "Open" and subjectVal ~= "" and not didOpen then
                                                didOpen = true
                                                if openCaseRemote then
                                                    openCaseRemote:InvokeServer(subjectVal, 5, false, false)
                                                    
                                                    currentBalance = balance and balance.Value or 0
                                                    if currentBalance < stopBalanceLimit then
                                                        Fluent:Notify({Title="Auto Quests", Content="Stopped! Reached safety balance stop limit.", Duration=5})
                                                        AutoQuestsToggle:SetValue(false)
                                                    end
                                                else
                                                    Fluent:Notify({Title="Error", Content="Could not find OpenCase remote.", Duration=5})
                                                    AutoQuestsToggle:SetValue(false)
                                                end
                                                
                                            elseif (actionVal == "Play" or actionVal == "Win" or actionVal == "Battle") and not didBattle then
                                                didBattle = true
                                                
                                                -- Oczekiwanie przynajmniej 3 sekund przed próbą ponownego stworzenia bitwy
                                                if os.clock() - lastBattleAttempt < 3 then
                                                    continue -- Czekamy do 3 sekund (cooldown)
                                                end
                                                lastBattleAttempt = os.clock()
                                                
                                                local createBattleRemote = ReplicatedStorage.Remotes:FindFirstChild("CreateBattle")
                                                local addBotRemote = ReplicatedStorage.Remotes:FindFirstChild("AddBot")
                                                
                                                local battleCase = "Military"
                                                local battleMode = "CRAZY TERMINAL"
                                                
                                                if subjectVal ~= "" then
                                                    local lowerSub = string.lower(subjectVal)
                                                    if lowerSub == "jester" or lowerSub == "shared" or lowerSub == "terminal" or lowerSub == "classic" or lowerSub == "crazy terminal" or lowerSub == "crazy-terminal" or lowerSub == "jackpot" or lowerSub == "crazy jackpot" then
                                                        if lowerSub == "crazy-terminal" then 
                                                            battleMode = "CRAZY TERMINAL" 
                                                        elseif lowerSub == "crazy jackpot" then
                                                            battleMode = "CRAZY JACKPOT"
                                                        else 
                                                            battleMode = string.upper(subjectVal) 
                                                        end
                                                        battleCase = "Military"
                                                    else
                                                        battleCase = subjectVal
                                                    end
                                                end
                                                
                                                if createBattleRemote and battleCase then
                                                    pcall(function() print("[Nexo Hub] Creating auto-battle with case: " .. tostring(battleCase) .. " | Mode: " .. tostring(battleMode)) end)
                                                    
                                                    local casesList = { tostring(battleCase) }
                                                    local battleId
                                                    pcall(function()
                                                        battleId = createBattleRemote:InvokeServer(casesList, 2, battleMode, false)
                                                    end)
                                                    
                                                    if battleId then
                                                        pcall(function() print("[Nexo Hub] Battle Created! ID: " .. tostring(battleId)) end)
                                                        
                                                        -- FIX DLA GUI CRASHA W NATIVE SKRYPCIE - Cichy update wartości id
                                                        pcall(function()
                                                            local bIdVal = DynamicPlayer.PlayerGui:FindFirstChild("Windows") and DynamicPlayer.PlayerGui.Windows:FindFirstChild("Case Battles") and DynamicPlayer.PlayerGui.Windows["Case Battles"]:FindFirstChild("BattlesScript") and DynamicPlayer.PlayerGui.Windows["Case Battles"].BattlesScript:FindFirstChild("BattleId")
                                                            if bIdVal then bIdVal.Value = tonumber(battleId) end
                                                        end)
                                                        
                                                        task.wait(0.6) -- Oczekanie sekunde upewniajac sie ze serwer poprawnie nadał uprawnienia bitwy
                                                        
                                                        if addBotRemote then
                                                            pcall(function() print("[Nexo Hub] Spawning Bot do ID: " .. tostring(battleId)) end)
                                                            pcall(function()
                                                                addBotRemote:FireServer(tonumber(battleId), DynamicPlayer)
                                                            end)
                                                        end
                                                    end
                                                    
                                                    currentBalance = balance and balance.Value or 0
                                                    if currentBalance < stopBalanceLimit then
                                                        Fluent:Notify({Title="Auto Quests", Content="Stopped! Reached safety balance stop limit.", Duration=5})
                                                        AutoQuestsToggle:SetValue(false)
                                                    end
                                                else
                                                    Fluent:Notify({Title="Error", Content="Could not find CreateBattle lub cheapest case.", Duration=5})
                                                    AutoQuestsToggle:SetValue(false)
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                -- Dodatkowa ochrona anty-kick (wspólne opóźnienie dla cyklu wykonywania operacji w for loop)
                                if didOpen or didBattle then
                                    task.wait(1.5)
                                end
                            end
                        else
                            Fluent:Notify({Title="Auto Quests", Content="Stopped! Reached safety balance stop limit.", Duration=5})
                            AutoQuestsToggle:SetValue(false) -- Auto turn off!
                        end
                    end
                end)
            end
        end
    end)
    
    -- Auto Rewards Loop Logic
    task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local updateRewardsRemote = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:FindFirstChild("UpdateRewards")
        local giftsFolder = ReplicatedStorage:FindFirstChild("Gifts")
        local openCaseRemote = ReplicatedStorage.Remotes:FindFirstChild("OpenCase")
        
        local claimedGifts = {}
        
        while task.wait(5) do
            if autoGiftsEnabled and updateRewardsRemote and giftsFolder then
                -- InvokeServer with no arguments returns the current playtime in seconds
                local success, currentPlaytime = pcall(function()
                    return updateRewardsRemote:InvokeServer()
                end)
                
                if success and currentPlaytime then
                    if type(currentPlaytime) == "number" then
                        -- Optional debug print for checking time
                        -- print("[Auto Rewards] Current Playtime from Server: " .. tostring(currentPlaytime))
                        for _, gift in ipairs(giftsFolder:GetChildren()) do
                            if not autoGiftsEnabled then break end
                            
                            if gift:IsA("NumberValue") or gift:IsA("IntValue") then
                                local requiredTime = gift.Value
                                    -- Check if game already says it's claimed
                                    local isGameClaimed = false
                                    if LocalPlayer:FindFirstChild("ClaimedGifts") then
                                        local gameClaimedValue = LocalPlayer.ClaimedGifts:FindFirstChild(gift.Name)
                                        if gameClaimedValue and gameClaimedValue:IsA("BoolValue") and gameClaimedValue.Value == true then
                                            isGameClaimed = true
                                        end
                                    end
                                    
                                    -- If we played long enough and didn't claim it locally yet
                                    if currentPlaytime >= requiredTime and not claimedGifts[gift.Name] and not isGameClaimed then
                                        -- The script checks if we already claimed something by pinging it, 
                                        -- but invoking with the name will claim it if the server agrees.
                                        local claimedResult = updateRewardsRemote:InvokeServer(gift.Name)
                                        
                                        -- If true, it was successfully claimed. If false/nil, probably already claimed
                                        if claimedResult == true then
                                            claimedGifts[gift.Name] = true
                                            -- Game's actual script also fires OpenCase with amount -1 for gifts!
                                            if openCaseRemote then
                                                openCaseRemote:InvokeServer(gift.Name, -1, false)
                                            end
                                            
                                            task.wait(1.5) -- prevent spamming server
                                        end
                                    end
                            end
                        end
                    end
                end
            end
        end
    end)
    
    -- Auto Level Rewards Logic (Full Recode)
    task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local openCaseRemote = ReplicatedStorage:WaitForChild("Remotes", 5) and ReplicatedStorage.Remotes:FindFirstChild("OpenCase")
        
        while task.wait(10) do
            if autoLevelRewardsEnabled and openCaseRemote then
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                local casesFrame = playerGui and playerGui:FindFirstChild("Windows") and playerGui.Windows:FindFirstChild("Cases") and playerGui.Windows.Cases:FindFirstChild("CasesFrame")
                
                if casesFrame then
                    -- Pobierz poziom gracza
                    local currentLevel = 0
                    local success, LevelCalculator = pcall(function()
                        return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("LevelCalculator"))
                    end)
                    
                    if success and LevelCalculator.CalculateLevel then
                        local playerData = LocalPlayer:FindFirstChild("PlayerData")
                        local expValue = playerData and playerData:FindFirstChild("Currencies") and playerData.Currencies:FindFirstChild("Experience")
                        if expValue then
                            local levelData = LevelCalculator.CalculateLevel(expValue.Value)
                            currentLevel = levelData and levelData.Level or 0
                        end
                    end

                    -- Przeszukaj wszystkie frame'y "LevelCases" (może być ich kilka)
                    for _, levelCasesFolder in ipairs(casesFrame:GetChildren()) do
                        if levelCasesFolder.Name == "LevelCases" then
                            -- Przeszukaj konkretne poziomy (LEVEL10, LEVEL20, LEVELS100 itd.)
                            for _, caseFrame in ipairs(levelCasesFolder:GetChildren()) do
                                if not autoLevelRewardsEnabled then break end
                                
                                -- Wyciągnij numer poziomu z nazwy (np. "LEVEL10" -> 10, "LEVELS110" -> 110)
                                local levelReq = tonumber(caseFrame.Name:match("%d+"))
                                
                                if levelReq and currentLevel >= levelReq then
                                    local caseCostLabel = caseFrame:FindFirstChild("CaseCost")
                                    if caseCostLabel and caseCostLabel:IsA("TextLabel") then
                                        local costText = caseCostLabel.Text
                                        
                                        -- Jeśli tekst NIE jest w formacie "mm:ss" (np. "05:20"), to znaczy że można odebrać
                                        -- Szukamy wzorca cyfra cyfra : cyfra cyfra
                                        local isTimer = costText:match("%d+:%d+")
                                        
                                        if not isTimer then
                                            -- Wyślij sygnał otwarcia (podajemy nazwę frame'a jako nazwę skrzynki)
                                            -- Zazwyczaj nazwa skrzynki to LEVEL10, LEVEL20 itd.
                                            local caseName = caseFrame.Name
                                            -- Jeśli nazwa to np. LEVELS110, serwer może oczekiwać LEVEL110
                                            if caseName:find("LEVELS") then
                                                caseName = caseName:gsub("LEVELS", "LEVEL")
                                            end
                                            
                                            pcall(function()
                                                openCaseRemote:InvokeServer(caseName, 1, false, false)
                                            end)
                                            task.wait(7) -- 7 sekund opóźnienia między skrzynkami (zgodnie z prośbą)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    
end


    -- UI initialized successfully



-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- InterfaceManager (Allows you to have a interface managment system)

-- Hand the library over to our managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- You can add indexes of elements the save manager should ignore
SaveManager:SetIgnoreIndexes({})

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)


Window:SelectTab(1)

-- Custom Nametag Logic ([ ★ Nexo User ★ ])
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local char = game:GetService("Players").LocalPlayer.Character
            if not char then
                -- Backup: Sprawdź ścieżkę podaną przez użytkownika jeśli standardowa zawiedzie
                local playersFolder = game:GetService("Workspace"):FindFirstChild("Players")
                if playersFolder then
                    char = playersFolder:FindFirstChild(game:GetService("Players").LocalPlayer.Name)
                end
            end
            
            if char then
                local head = char:FindFirstChild("Head")
                if head then
                    local nametag = head:FindFirstChild("Nametag")
                    if nametag then
                        local developerTag = nametag:FindFirstChild("Developer")
                        if developerTag and developerTag:IsA("TextLabel") then
                            if developerTag.Text ~= "[ ★  Nexo User ★ ]" or not developerTag.Visible then
                                developerTag.Text = "[ ★  Nexo User ★ ]"
                                developerTag.Visible = true
                                developerTag.TextColor3 = Color3.fromRGB(255, 170, 0) -- Złoty kolor Nexo
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ============================================
-- SMART UPGRADER
-- ============================================
do
    Tabs.Upgrader:AddSection("Settings")

    local upgraderMinPrice = 0
    local upgraderMaxPrice = 50
    local upgraderSkipLocked = true
    local upgraderSkipStatTrak = true
    local upgraderSkipLimited = true
    local upgraderMultiplier = 2
    local upgraderDelay = 2
    local upgraderEnabled = false
    local upgraderMinRarity = "Consumer Grade"
    local upgraderMaxRarity = "Contraband"

    -- Stats
    local upgraderAttempts = 0
    local upgraderWins = 0
    local upgraderLosses = 0
    local upgraderProfit = 0

    local rarityOrder = {
        "Consumer Grade", "Industrial Grade", "Mil-Spec",
        "Restricted", "Classified", "Covert",
        "Extraordinary", "Special", "Contraband"
    }
    local rarityRanks = {}
    for i, name in ipairs(rarityOrder) do
        rarityRanks[name] = i
    end

    Tabs.Upgrader:AddInput("UpgraderMinPrice", {
        Title = "Min Skin Price ($)",
        Default = "0",
        Placeholder = "0",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            upgraderMinPrice = tonumber(Value) or 0
        end
    })

    Tabs.Upgrader:AddInput("UpgraderMaxPrice", {
        Title = "Max Skin Price ($)",
        Default = "50",
        Placeholder = "50",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            upgraderMaxPrice = tonumber(Value) or 50
        end
    })

    Tabs.Upgrader:AddDropdown("UpgraderMinRarity", {
        Title = "Min Rarity",
        Values = rarityOrder,
        Multi = false,
        Default = "Consumer Grade",
        Callback = function(Value)
            upgraderMinRarity = Value
        end
    })

    Tabs.Upgrader:AddDropdown("UpgraderMaxRarity", {
        Title = "Max Rarity",
        Values = rarityOrder,
        Multi = false,
        Default = "Contraband",
        Callback = function(Value)
            upgraderMaxRarity = Value
        end
    })

    Tabs.Upgrader:AddDropdown("UpgraderMultiplier", {
        Title = "Target Multiplier",
        Values = {"2x", "3x", "5x", "10x"},
        Multi = false,
        Default = "2x",
        Callback = function(Value)
            upgraderMultiplier = tonumber(string.match(Value, "%d+")) or 2
        end
    })

    Tabs.Upgrader:AddToggle("UpgraderSkipLocked", {
        Title = "Skip Locked Skins",
        Default = true,
        Callback = function(Value) upgraderSkipLocked = Value end
    })

    Tabs.Upgrader:AddToggle("UpgraderSkipStatTrak", {
        Title = "Skip StatTrak Skins",
        Default = true,
        Callback = function(Value) upgraderSkipStatTrak = Value end
    })

    Tabs.Upgrader:AddToggle("UpgraderSkipLimited", {
        Title = "Skip Limited Skins",
        Default = true,
        Callback = function(Value) upgraderSkipLimited = Value end
    })

    Tabs.Upgrader:AddSlider("UpgraderDelay", {
        Title = "Delay Between Upgrades (seconds)",
        Default = 2,
        Min = 1,
        Max = 10,
        Rounding = 1,
        Callback = function(Value)
            upgraderDelay = Value
        end
    })

    Tabs.Upgrader:AddSection("Control")

    Tabs.Upgrader:AddToggle("UpgraderEnabled", {
        Title = "Enable Auto Upgrader",
        Default = false,
        Callback = function(Value)
            upgraderEnabled = Value
            if upgraderEnabled then
                Fluent:Notify({Title="Smart Upgrader", Content="Started! Upgrading skins $" .. upgraderMinPrice .. "-$" .. upgraderMaxPrice .. " at " .. upgraderMultiplier .. "x", Duration=3})
            else
                Fluent:Notify({Title="Smart Upgrader", Content="Stopped.", Duration=3})
            end
        end
    })

    Tabs.Upgrader:AddButton({
        Title = "Reset Stats",
        Description = "Reset attempts/wins/losses/profit counters.",
        Callback = function()
            upgraderAttempts = 0
            upgraderWins = 0
            upgraderLosses = 0
            upgraderProfit = 0
            Fluent:Notify({Title="Smart Upgrader", Content="Stats reset.", Duration=2})
        end
    })

    -- Auto Upgrader Loop
    task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        -- Wait for remotes
        local upgradeRemote = ReplicatedStorage:WaitForChild("Remotes", 10) and ReplicatedStorage.Remotes:WaitForChild("Upgrade", 10)
        if not upgradeRemote then
            warn("[Smart Upgrader] Could not find Upgrade remote!")
            return
        end

        -- Load modules
        local Items, UpgraderModule
        pcall(function()
            Items = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Items"))
            UpgraderModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Upgrader"))
        end)
        if not Items or not UpgraderModule then
            warn("[Smart Upgrader] Could not load Items or Upgrader module!")
            return
        end

        -- Build all possible upgrade targets from the Upgrader module
        local allTargets = {}
        for _, upgraderEntry in pairs(UpgraderModule) do
            for _, drop in ipairs(upgraderEntry.Drops) do
                local itemData = Items[drop.Item]
                if itemData and itemData.Wears then
                    for wearName, wearData in pairs(itemData.Wears) do
                        local price = wearData.Normal or wearData.StatTrak or 0
                        local stattrak = false
                        if not wearData.Normal and wearData.StatTrak then
                            stattrak = true
                            price = wearData.StatTrak
                        end
                        if price and price > 0 then
                            table.insert(allTargets, {
                                Key = drop.Item,
                                Name = itemData.Name,
                                Wear = wearName,
                                Rarity = itemData.Rarity,
                                Stattrak = stattrak,
                                Price = price
                            })
                        end
                    end
                end
            end
        end

        -- Result tracking via OnClientEvent
        local lastResult = nil
        local resultReceived = false

        upgradeRemote.OnClientEvent:Connect(function(result)
            lastResult = result
            resultReceived = true
        end)

        while true do
            task.wait(1)

            if not upgraderEnabled then continue end

            -- Get inventory items
            local playerData = LocalPlayer:FindFirstChild("PlayerData")
            if not playerData then continue end
            local inventory = playerData:FindFirstChild("Inventory")
            if not inventory then continue end

            -- Filter and collect eligible items
            local eligibleItems = {}
            local minRank = rarityRanks[upgraderMinRarity] or 1
            local maxRank = rarityRanks[upgraderMaxRarity] or 9

            for _, item in ipairs(inventory:GetChildren()) do
                if not upgraderEnabled then break end

                local itemData = Items[item.Name]
                if not itemData then continue end
                if item:GetAttribute("Escrow") then continue end

                -- Check locked
                if upgraderSkipLocked and item:GetAttribute("Locked") == true then continue end

                -- Check stattrak
                local isStatTrak = item:GetAttribute("Stattrak") == true
                if upgraderSkipStatTrak and isStatTrak then continue end

                -- Check limited
                if upgraderSkipLimited and itemData.Limited then continue end

                -- Check rarity
                local itemRarityRank = rarityRanks[itemData.Rarity] or 0
                if itemRarityRank < minRank or itemRarityRank > maxRank then continue end

                -- Get price
                local wear = item:GetAttribute("Wear")
                local wearData = nil
                if itemData.Wears then
                    if wear and itemData.Wears[wear] then
                        wearData = itemData.Wears[wear]
                    else
                        for _, wd in pairs(itemData.Wears) do
                            wearData = wd
                            break
                        end
                    end
                end

                local price = 0
                if wearData then
                    if isStatTrak then
                        price = wearData.StatTrak or wearData.Normal or 0
                    else
                        price = wearData.Normal or wearData.StatTrak or 0
                    end
                end

                -- Check price range
                if price > 0 and price >= upgraderMinPrice and price <= upgraderMaxPrice then
                    table.insert(eligibleItems, {
                        Instance = item,
                        UUID = item:GetAttribute("UUID"),
                        Price = price,
                        Name = item.Name
                    })
                end
            end

            if #eligibleItems == 0 then
                upgraderEnabled = false
                Fluent:Notify({Title="Smart Upgrader", Content="No eligible skins found! Stopped.", Duration=5})
                continue
            end

            -- Sort by price ascending (upgrade cheapest first)
            table.sort(eligibleItems, function(a, b) return a.Price < b.Price end)

            -- Select up to 6 items
            local selectedItems = {}
            local totalInputValue = 0
            for i = 1, math.min(6, #eligibleItems) do
                local item = eligibleItems[i]
                table.insert(selectedItems, {
                    UUID = item.UUID,
                    Price = item.Price
                })
                totalInputValue = totalInputValue + item.Price
            end

            if totalInputValue <= 0 then continue end

            -- Find the best matching target
            local targetPrice = totalInputValue * upgraderMultiplier
            local bestTarget = nil
            local bestDiff = math.huge

            for _, target in ipairs(allTargets) do
                -- Target must be >= input value (otherwise no point upgrading)
                if target.Price >= totalInputValue then
                    local diff = math.abs(target.Price - targetPrice)
                    if diff < bestDiff then
                        bestDiff = diff
                        bestTarget = target
                    end
                end
            end

            if not bestTarget then
                Fluent:Notify({Title="Smart Upgrader", Content="No suitable target found for $" .. string.format("%.2f", totalInputValue) .. " input at " .. upgraderMultiplier .. "x. Retrying...", Duration=3})
                task.wait(upgraderDelay)
                continue
            end

            -- Calculate chance for notification
            local chance = math.clamp((totalInputValue / bestTarget.Price) * 100, 0, 75)

            -- Fire the upgrade remote
            local targetData = {
                Key = bestTarget.Key,
                Name = bestTarget.Name,
                Stattrak = bestTarget.Stattrak,
                Price = bestTarget.Price,
                Wear = bestTarget.Wear
            }

            resultReceived = false
            lastResult = nil
            upgraderAttempts = upgraderAttempts + 1

            pcall(function()
                upgradeRemote:FireServer(selectedItems, targetData)
            end)

            -- Wait for result (max 15 seconds)
            local waitStart = tick()
            while not resultReceived and (tick() - waitStart) < 15 do
                task.wait(0.1)
            end

            if resultReceived then
                if lastResult == "Success" then
                    upgraderWins = upgraderWins + 1
                    upgraderProfit = upgraderProfit + (bestTarget.Price - totalInputValue)
                    Fluent:Notify({
                        Title = "✅ Upgrade SUCCESS!",
                        Content = "Won: " .. bestTarget.Name .. " ($" .. string.format("%.2f", bestTarget.Price) .. ") | Chance: " .. string.format("%.1f", chance) .. "%\n" ..
                            "Stats: " .. upgraderWins .. "W/" .. upgraderLosses .. "L | Profit: $" .. string.format("%.2f", upgraderProfit),
                        Duration = 5
                    })
                else
                    upgraderLosses = upgraderLosses + 1
                    upgraderProfit = upgraderProfit - totalInputValue
                    Fluent:Notify({
                        Title = "❌ Upgrade FAILED",
                        Content = "Lost $" .. string.format("%.2f", totalInputValue) .. " | Target was: " .. bestTarget.Name .. " | Chance: " .. string.format("%.1f", chance) .. "%\n" ..
                            "Stats: " .. upgraderWins .. "W/" .. upgraderLosses .. "L | Profit: $" .. string.format("%.2f", upgraderProfit),
                        Duration = 4
                    })
                end
            else
                Fluent:Notify({Title="Smart Upgrader", Content="No response from server. Retrying...", Duration=3})
            end

            -- Wait between upgrades (extra wait for the spin animation)
            task.wait(upgraderDelay + 5)
        end
    end)
end

Fluent:Notify({
    Title = "NexoHub v1.0",
    Content = "The script has been loaded.",
    Duration = 8
})

-- Load Level Module & Print Level on Startup
task.spawn(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local success, LevelCalculator = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("Modules", 5):WaitForChild("LevelCalculator", 5))
    end)
    
    if success and type(LevelCalculator) == "table" and LevelCalculator.CalculateLevel then
        local playerData = LocalPlayer:WaitForChild("PlayerData", 5)
        if playerData then
            local expValue = playerData:FindFirstChild("Currencies") and playerData.Currencies:FindFirstChild("Experience")
            if expValue and expValue:IsA("NumberValue") then
                local levelData = LevelCalculator.CalculateLevel(expValue.Value)
                if levelData and levelData.Level then
                    print("--------------------------------------------------")
                    print("🚀 [NEXO HUB] Wczytano statystyki gracza!")
                    print("🚀 [NEXO HUB] Twój poziom w grze to: " .. tostring(levelData.Level))
                    print("--------------------------------------------------")
                    
                    Fluent:Notify({
                        Title = "Witaj ponownie!",
                        Content = "Twój aktualny poziom w grze to: " .. tostring(levelData.Level),
                        Duration = 5
                    })
                end
            end
        end
    end
end)

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()
