if getgenv().Nexo_Authorized ~= "NexoHub_Session_Success" then
    game:GetService("Players").LocalPlayer:Kick("\n\n[Nexo Security]\nUnauthorized execution detected.\nPlease execute the script via the official loader.\ndsc.gg/nexohub")
    return
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 1. NAMETAG DATA & LOGIC
local NametagSystem = {}

local function lerpColor(c1, c2, t)
    return Color3.new(c1.R + (c2.R - c1.R) * t, c1.G + (c2.G - c1.G) * t, c1.B + (c2.B - c1.B) * t)
end

local function getGradientColor(stops, t)
    local count = #stops
    if count <= 1 then return stops[1] or Color3.new(1, 1, 1) end
    local progress = (t % 1) * count
    local index = math.floor(progress)
    local ratio = progress - index
    return lerpColor(stops[index % count + 1], stops[(index + 1) % count + 1], ratio)
end

NametagSystem.Nameplates = {
    {id = "default", name = "Default", stops = {Color3.fromRGB(255, 255, 255)}, speed = 0, anim = "none"},
    {id = "bloodmoon", name = "Crimson", stops = {Color3.fromRGB(190, 15, 15), Color3.fromRGB(120, 0, 5), Color3.fromRGB(210, 25, 20)}, speed = 0.15, anim = "scroll"},
    {id = "cherry", name = "Cherry", stops = {Color3.fromRGB(230, 25, 50), Color3.fromRGB(180, 10, 30), Color3.fromRGB(255, 70, 70)}, speed = 0.25, anim = "scroll"},
    {id = "sunset", name = "Sunset Blaze", stops = {Color3.fromRGB(240, 70, 0), Color3.fromRGB(255, 140, 20), Color3.fromRGB(220, 40, 0)}, speed = 0.2, anim = "scroll"},
    {id = "coral", name = "Coral Reef", stops = {Color3.fromRGB(255, 110, 90), Color3.fromRGB(240, 80, 110), Color3.fromRGB(255, 150, 110)}, speed = 0.2, anim = "scroll"},
    {id = "gold", name = "Royal Gold", stops = {Color3.fromRGB(255, 170, 0), Color3.fromRGB(255, 220, 40), Color3.fromRGB(230, 130, 0)}, speed = 0.25, anim = "scroll"},
    {id = "honey", name = "Honey", stops = {Color3.fromRGB(255, 195, 70), Color3.fromRGB(240, 170, 50), Color3.fromRGB(255, 215, 100)}, speed = 0.2, anim = "scroll"},
    {id = "toxic", name = "Radioactive", stops = {Color3.fromRGB(20, 255, 60), Color3.fromRGB(180, 255, 0), Color3.fromRGB(0, 200, 40)}, speed = 0.35, anim = "scroll"},
    {id = "emerald", name = "Emerald", stops = {Color3.fromRGB(0, 200, 90), Color3.fromRGB(40, 255, 130), Color3.fromRGB(0, 150, 70)}, speed = 0.2, anim = "scroll"},
    {id = "mint", name = "Mint Breeze", stops = {Color3.fromRGB(110, 255, 200), Color3.fromRGB(180, 255, 230), Color3.fromRGB(50, 230, 170)}, speed = 0.2, anim = "scroll"},
    {id = "aurora", name = "Aurora", stops = {Color3.fromRGB(0, 230, 130), Color3.fromRGB(20, 180, 210), Color3.fromRGB(50, 130, 255), Color3.fromRGB(130, 70, 230), Color3.fromRGB(20, 180, 210)}, speed = 0.15, anim = "scroll"},
    {id = "ocean", name = "Deep Sea", stops = {Color3.fromRGB(0, 180, 255), Color3.fromRGB(0, 70, 200), Color3.fromRGB(0, 220, 240)}, speed = 0.25, anim = "scroll"},
    {id = "ice", name = "Arctic", stops = {Color3.fromRGB(110, 200, 255), Color3.fromRGB(200, 235, 255), Color3.fromRGB(70, 160, 255)}, speed = 0.2, anim = "scroll"},
    {id = "sapphire", name = "Sapphire", stops = {Color3.fromRGB(10, 60, 220), Color3.fromRGB(40, 110, 255), Color3.fromRGB(0, 40, 160)}, speed = 0.2, anim = "scroll"},
    {id = "galaxy", name = "Nebula", stops = {Color3.fromRGB(110, 0, 210), Color3.fromRGB(200, 30, 170), Color3.fromRGB(30, 20, 140)}, speed = 0.15, anim = "scroll"},
    {id = "midnight", name = "Midnight", stops = {Color3.fromRGB(25, 10, 80), Color3.fromRGB(50, 20, 110), Color3.fromRGB(10, 5, 50)}, speed = 0.15, anim = "scroll"},
    {id = "storm", name = "Thunderstorm", stops = {Color3.fromRGB(15, 0, 70), Color3.fromRGB(80, 0, 255), Color3.fromRGB(5, 0, 40)}, speed = 0.45, anim = "scroll"},
    {id = "grape", name = "Violet", stops = {Color3.fromRGB(140, 0, 200), Color3.fromRGB(190, 60, 255), Color3.fromRGB(90, 0, 140)}, speed = 0.2, anim = "scroll"},
    {id = "lavender", name = "Lavender", stops = {Color3.fromRGB(180, 150, 255), Color3.fromRGB(210, 190, 255), Color3.fromRGB(150, 120, 240)}, speed = 0.2, anim = "scroll"},
    {id = "pink", name = "Cotton Candy", stops = {Color3.fromRGB(255, 120, 190), Color3.fromRGB(255, 180, 220), Color3.fromRGB(230, 90, 200)}, speed = 0.2, anim = "scroll"},
    {id = "bubblegum", name = "Bubblegum", stops = {Color3.fromRGB(255, 10, 130), Color3.fromRGB(255, 80, 180), Color3.fromRGB(210, 0, 110)}, speed = 0.3, anim = "scroll"},
    {id = "peach", name = "Peach Sorbet", stops = {Color3.fromRGB(255, 170, 120), Color3.fromRGB(255, 140, 150), Color3.fromRGB(255, 200, 140)}, speed = 0.2, anim = "scroll"},
    {id = "rose", name = "Rose", stops = {Color3.fromRGB(255, 50, 110), Color3.fromRGB(255, 130, 160), Color3.fromRGB(220, 30, 90)}, speed = 0.25, anim = "scroll"},
    {id = "chrome", name = "Chrome", stops = {Color3.fromRGB(210, 210, 220), Color3.fromRGB(140, 140, 160), Color3.fromRGB(245, 245, 255)}, speed = 0.3, anim = "scroll"},
    {id = "obsidian", name = "Obsidian", stops = {Color3.fromRGB(55, 55, 65), Color3.fromRGB(90, 90, 105), Color3.fromRGB(30, 30, 35)}, speed = 0.2, anim = "scroll"},
    {id = "mocha", name = "Mocha", stops = {Color3.fromRGB(110, 55, 15), Color3.fromRGB(60, 28, 5), Color3.fromRGB(140, 70, 25)}, speed = 0.2, anim = "scroll"},
    {id = "void", name = "Void", stops = {Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 255, 100), Color3.fromRGB(0, 0, 0)}, speed = 0.4, anim = "scroll"}
}

function NametagSystem.buildAnimatedGradient(plate, time)
    local offset = time * plate.speed
    local kps = {}
    for i = 0, 6 do
        local ratio = i / 6
        table.insert(kps, ColorSequenceKeypoint.new(ratio, getGradientColor(plate.stops, ratio + offset)))
    end
    return ColorSequence.new(kps)
end

local currentPlate = NametagSystem.Nameplates[1]
local nametagsEnabled = true
local verifiedEnabled = false
local verifiedBadgeId = "rbxassetid://86891257055936"

local customNametag = {
    enabled = false,
    text = ".gg/nexohub",
    color1 = Color3.fromRGB(255, 0, 0),
    color2 = Color3.fromRGB(0, 0, 255),
    speed = 0.2,
    anim = "none"
}

-- 3. CORE LOGIC
local function updateNametag(char)
    if not nametagsEnabled or not currentPlate then return end
    local head = char:WaitForChild("Head", 5)
    local headTag = head and head:WaitForChild("HeadTag")
    if headTag then
        for _, label in ipairs(headTag:GetChildren()) do
            if label:IsA("TextLabel") then
                if label.Name == "Role" then
                    if customNametag.enabled then
                        label.Visible = true
                        label.Text = customNametag.text
                        label.BackgroundTransparency = 0.3
                        label.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    elseif currentPlate.id == "default" then
                        label.Visible = false
                    else
                        label.Visible = true
                        label.Text = currentPlate.name
                        label.BackgroundTransparency = 0.3
                        label.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    end
                else
                    label.Visible = true
                    label.ClipsDescendants = false
                end
                
                if currentPlate.id ~= "default" then
                    label.TextColor3 = Color3.new(1, 1, 1)
                    local grad = label:FindFirstChild("AntigravityGrad") or Instance.new("UIGradient")
                    grad.Name = "AntigravityGrad"
                    grad.Parent = label
                else
                    local grad = label:FindFirstChild("AntigravityGrad")
                    if grad then grad:Destroy() end
                end
            end
        end
    end
end

-- 4. FAKE GIFT SYSTEM
local FakeGiftSystem = {}
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local giftColors = {
    {robux = 10000000, color = Color3.fromRGB(255, 20, 100)},
    {robux = 1000000, color = Color3.fromRGB(255, 0, 115)},
    {robux = 100000, color = Color3.fromRGB(255, 0, 230)},
    {robux = 10000, color = Color3.fromRGB(0, 179, 255)},
    {robux = 1000, color = Color3.fromRGB(255, 140, 0)},
    {robux = 1, color = Color3.fromRGB(0, 218, 18)}
}

function FakeGiftSystem.formatCommas(num)
    local str = tostring(math.floor(num))
    return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

function FakeGiftSystem.trigger(donorName, robux)
    local donorId = 1
    pcall(function() donorId = Players:GetUserIdFromNameAsync(donorName) end)
    
    local giftTemplate = game:GetService("StarterGui"):FindFirstChild("UITemplates"):FindFirstChild("Gift")
    if not giftTemplate then return end
    
    local gift = giftTemplate:Clone()
    gift.Parent = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("CustomCoreGui", 5) or LocalPlayer.PlayerGui:FindFirstChild("MainGUI")
    if not gift:FindFirstChild("Main") then gift:Destroy() return end

    local color = giftColors[6].color
    for _, v in ipairs(giftColors) do
        if robux >= v.robux then color = v.color break end
    end

    -- Setup Initial State
    gift.Main.Visible = false
    gift.Surprise.Visible = true
    gift.Surprise.Surprise.Player.Text = "@" .. donorName
    gift.UIScale.Scale = 0
    
    -- Main Setup
    gift.Main.Claim.BackgroundColor3 = color
    gift.Main.Amount.TextColor3 = color
    gift.Main.Info.Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. donorId .. "&w=420&h=420"
    gift.Main.Info.Avatar.DisplayName.Text = "<b>" .. donorName .. "</b> @" .. donorName
    gift.Main.Info.Date.Text = "Just now"
    gift.Main.Message.Text = "Enjoy the gift! 🎁"
    
    -- Intro Tween
    TweenService:Create(gift.UIScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Scale = 1}):Play()
    
    local function openGift()
        if gift:GetAttribute("Opened") then return end
        gift:SetAttribute("Opened", true)
        
        if SoundService:FindFirstChild("SFX") then
            if SoundService.SFX:FindFirstChild("GiftOpen") then SoundService.SFX.GiftOpen:Play() end
            if SoundService.SFX:FindFirstChild("StickyNote") then SoundService.SFX.StickyNote:Play() end
        end
        
        gift.Surprise.Visible = false
        gift.Main.Visible = true
        gift.Main.Amount.Text = "\238\128\130 0"
        
        -- Counting Animation
        task.spawn(function()
            local speed = robux >= 1000000 and 120 or 60
            for i = 0, speed do
                local current = math.floor((robux / speed) * i)
                gift.Main.Amount.Text = "\238\128\130 " .. FakeGiftSystem.formatCommas(current)
                task.wait(0.01)
            end
            gift.Main.Amount.Text = "\238\128\130 " .. FakeGiftSystem.formatCommas(robux)
            
            -- Pop effect on finish
            TweenService:Create(gift.Main.Amount.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1.2}):Play()
            task.wait(0.3)
            TweenService:Create(gift.Main.Amount.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Scale = 1}):Play()
        end)
    end

    gift.Surprise.Activated:Connect(openGift)
    gift.Main.Claim.Activated:Connect(function()
        TweenService:Create(gift.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 0}):Play()
        task.wait(0.3)
        gift:Destroy()
    end)
end

-- 5. NOTIFICATION SYSTEM
local NotificationSystem = {}

function NotificationSystem.trigger(msg, popupType)
    local mainGui = LocalPlayer.PlayerGui:FindFirstChild("MainGUI")
    local templates = game:GetService("StarterGui"):FindFirstChild("UITemplates")
    local pType = popupType or "success"
    local popupTemplate = templates and templates:FindFirstChild(pType .. "Popup")
    
    if mainGui and popupTemplate then
        if SoundService:FindFirstChild("SFX") and SoundService.SFX:FindFirstChild("BellRing") then
            SoundService.SFX.BellRing:Play()
        end
        local popup = popupTemplate:Clone()
        popup.Message.Text = msg or "Notification"
        popup.Parent = mainGui:FindFirstChild("Popups") or mainGui
        popup.Transparency = 1
        popup.UIScale.Scale = 0
        TweenService:Create(popup, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Transparency = 0}):Play()
        TweenService:Create(popup.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
        task.delay(4, function()
            TweenService:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
            TweenService:Create(popup.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Scale = 0}):Play()
            task.wait(0.3)
            popup:Destroy()
        end)
    end
end

-- 6. STANDALONE BALANCE CHANGER (EXACT PORT FROM ROBLOXFAKE.LUA)
local BalanceSystem = {
    amount = 419670118,
    giftbux = 0,
    enabled = false
}

local G2L_Fake = {};
local ContentProvider = game:GetService("ContentProvider")

-- ScreenGui
G2L_Fake["1"] = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"));
G2L_Fake["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling;
G2L_Fake["1"].Enabled = false;

-- ImageLabel (background)
G2L_Fake["2"] = Instance.new("ImageLabel", G2L_Fake["1"]);
G2L_Fake["2"]["BorderSizePixel"] = 0;
G2L_Fake["2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["2"]["Image"] = [[rbxassetid://113016467492725]];
G2L_Fake["2"]["Size"] = UDim2.new(0, 1330, 0, 801);
G2L_Fake["2"]["Visible"] = false;
G2L_Fake["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);

-- Frame (main purchase prompt)
G2L_Fake["3"] = Instance.new("CanvasGroup", G2L_Fake["1"]);
G2L_Fake["3"]["GroupTransparency"] = 1;
G2L_Fake["3"]["BorderSizePixel"] = 0;
G2L_Fake["3"]["BackgroundColor3"] = Color3.fromRGB(30, 33, 36);
G2L_Fake["3"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L_Fake["3"]["Size"] = UDim2.new(0, 385, 0, 204);
G2L_Fake["3"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
G2L_Fake["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);

G2L_Fake["4"] = Instance.new("UICorner", G2L_Fake["3"]);
G2L_Fake["4"]["CornerRadius"] = UDim.new(0, 9);

-- buyitem label
G2L_Fake["5"] = Instance.new("TextLabel", G2L_Fake["3"]);
G2L_Fake["5"]["TextWrapped"] = true;
G2L_Fake["5"]["BorderSizePixel"] = 0;
G2L_Fake["5"]["TextSize"] = 14;
G2L_Fake["5"]["TextScaled"] = true;
G2L_Fake["5"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["5"]["FontFace"] = Font.new([[rbxassetid://16658221428]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L_Fake["5"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["5"]["BackgroundTransparency"] = 1;
G2L_Fake["5"]["Size"] = UDim2.new(0, 71, 0, 29);
G2L_Fake["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L_Fake["5"]["Text"] = [[Buy item]];
G2L_Fake["5"]["Position"] = UDim2.new(0.042, 0, 0.05, 0);

-- GamepassName
G2L_Fake["6"] = Instance.new("TextLabel", G2L_Fake["3"]);
G2L_Fake["6"]["TextWrapped"] = true;
G2L_Fake["6"]["BorderSizePixel"] = 0;
G2L_Fake["6"]["TextSize"] = 15;
G2L_Fake["6"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L_Fake["6"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["6"]["FontFace"] = Font.new([[rbxassetid://16658221428]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L_Fake["6"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["6"]["BackgroundTransparency"] = 1;
G2L_Fake["6"]["RichText"] = true;
G2L_Fake["6"]["Size"] = UDim2.new(0, 257, 0, 29);
G2L_Fake["6"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L_Fake["6"]["Text"] = [[FOR ME?????????]];
G2L_Fake["6"]["Position"] = UDim2.new(0.226, 0, 0.34, 0);

-- GamepassIcon
G2L_Fake["7"] = Instance.new("ImageLabel", G2L_Fake["3"]);
G2L_Fake["7"]["BorderSizePixel"] = 0;
G2L_Fake["7"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["7"]["BackgroundTransparency"] = 1;
G2L_Fake["7"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
G2L_Fake["7"]["Size"] = UDim2.new(0, 61, 0, 69);
G2L_Fake["7"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L_Fake["7"]["Position"] = UDim2.new(0.04156, 0, 0.28431, 0);
Instance.new("UICorner", G2L_Fake["7"]).CornerRadius = UDim.new(0, 5);

-- RobuxIcon (balance, top-right)
G2L_Fake["8"] = Instance.new("ImageLabel", G2L_Fake["3"]);
G2L_Fake["8"]["BorderSizePixel"] = 0;
G2L_Fake["8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["8"]["ImageColor3"] = Color3.fromRGB(221, 222, 224);
G2L_Fake["8"]["Image"] = [[rbxassetid://85055734888070]];
G2L_Fake["8"]["Size"] = UDim2.new(0, 14, 0, 15);
G2L_Fake["8"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L_Fake["8"]["BackgroundTransparency"] = 1;
G2L_Fake["8"]["Position"] = UDim2.new(0.66753, 0, 0.11765, 0);

-- RobuxIcon (price)
G2L_Fake["9"] = Instance.new("ImageLabel", G2L_Fake["3"]);
G2L_Fake["9"]["BorderSizePixel"] = 0;
G2L_Fake["9"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["9"]["ImageColor3"] = Color3.fromRGB(221, 222, 224);
G2L_Fake["9"]["Image"] = [[rbxassetid://85055734888070]];
G2L_Fake["9"]["Size"] = UDim2.new(0, 14, 0, 14);
G2L_Fake["9"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L_Fake["9"]["BackgroundTransparency"] = 1;
G2L_Fake["9"]["Position"] = UDim2.new(0.223, 0, 0.49, 0);

-- GamepassPrice
G2L_Fake["a"] = Instance.new("TextLabel", G2L_Fake["3"]);
G2L_Fake["a"]["TextWrapped"] = true;
G2L_Fake["a"]["BorderSizePixel"] = 0;
G2L_Fake["a"]["TextSize"] = 15;
G2L_Fake["a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L_Fake["a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["a"]["FontFace"] = Font.new([[rbxassetid://16658221428]], Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
G2L_Fake["a"]["TextColor3"] = Color3.fromRGB(221, 222, 224);
G2L_Fake["a"]["BackgroundTransparency"] = 1;
G2L_Fake["a"]["Size"] = UDim2.new(0, 118, 0, 31);
G2L_Fake["a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L_Fake["a"]["Text"] = [[100,000]];
G2L_Fake["a"]["Position"] = UDim2.new(0.271, 0, 0.443, 0);

-- Balance label
G2L_Fake["b"] = Instance.new("TextLabel", G2L_Fake["3"]);
G2L_Fake["b"]["TextWrapped"] = true;
G2L_Fake["b"]["BorderSizePixel"] = 0;
G2L_Fake["b"]["TextSize"] = 15;
G2L_Fake["b"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L_Fake["b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["b"]["FontFace"] = Font.new([[rbxassetid://16658221428]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L_Fake["b"]["TextColor3"] = Color3.fromRGB(221, 222, 224);
G2L_Fake["b"]["BackgroundTransparency"] = 1;
G2L_Fake["b"]["Size"] = UDim2.new(0, 121, 0, 29);
G2L_Fake["b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L_Fake["b"]["Text"] = [[419,670,118]];
G2L_Fake["b"]["Position"] = UDim2.new(0.71948, 0, 0.0802, 0);

-- ExitButton
G2L_Fake["c"] = Instance.new("ImageButton", G2L_Fake["3"]);
G2L_Fake["c"]["BorderSizePixel"] = 0;
G2L_Fake["c"]["BackgroundTransparency"] = 1;
G2L_Fake["c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["c"]["ImageColor3"] = Color3.fromRGB(221, 222, 224);
G2L_Fake["c"]["Image"] = [[rbxassetid://91733972775823]];
G2L_Fake["c"]["Size"] = UDim2.new(0, 18, 0, 18);
G2L_Fake["c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L_Fake["c"]["Position"] = UDim2.new(0.8961, 0, 0.10784, 0);

-- ButtonBG
G2L_Fake["d"] = Instance.new("CanvasGroup", G2L_Fake["3"]);
G2L_Fake["d"]["BorderSizePixel"] = 0;
G2L_Fake["d"]["BackgroundColor3"] = Color3.fromRGB(39, 62, 143);
G2L_Fake["d"]["Size"] = UDim2.new(0, 353, 0, 34);
G2L_Fake["d"]["Position"] = UDim2.new(0.042, 0, 0.7549, 0);
G2L_Fake["d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);

G2L_Fake["e"] = Instance.new("UICorner", G2L_Fake["d"]);
G2L_Fake["e"]["CornerRadius"] = UDim.new(0, 9);

-- Filling
G2L_Fake["f"] = Instance.new("Frame", G2L_Fake["d"]);
G2L_Fake["f"]["BorderSizePixel"] = 0;
G2L_Fake["f"]["BackgroundColor3"] = Color3.fromRGB(44, 76, 194);
G2L_Fake["f"]["Size"] = UDim2.new(0, 0, 1, 0);
G2L_Fake["f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);

-- BuyButton
G2L_Fake["10"] = Instance.new("TextButton", G2L_Fake["3"]);
G2L_Fake["10"]["BorderSizePixel"] = 0;
G2L_Fake["10"]["TextSize"] = 17;
G2L_Fake["10"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["10"]["BackgroundColor3"] = Color3.fromRGB(44, 76, 194);
G2L_Fake["10"]["FontFace"] = Font.new([[rbxassetid://16658221428]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L_Fake["10"]["Size"] = UDim2.new(0, 353, 0, 34);
G2L_Fake["10"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L_Fake["10"]["Text"] = [[Buy]];
G2L_Fake["10"]["Visible"] = false;
G2L_Fake["10"]["Position"] = UDim2.new(0.042, 0, 0.7549, 0);

G2L_Fake["11"] = Instance.new("UICorner", G2L_Fake["10"]);
G2L_Fake["11"]["CornerRadius"] = UDim.new(0, 9);

-- SuccessFrame
G2L_Fake["12"] = Instance.new("CanvasGroup", G2L_Fake["1"]);
G2L_Fake["12"]["BorderSizePixel"] = 0;
G2L_Fake["12"]["BackgroundColor3"] = Color3.fromRGB(31, 34, 37);
G2L_Fake["12"]["Size"] = UDim2.new(0, 469, 0, 195);
G2L_Fake["12"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
G2L_Fake["12"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L_Fake["12"]["Visible"] = false;
G2L_Fake["12"]["GroupTransparency"] = 1;

G2L_Fake["13"] = Instance.new("UICorner", G2L_Fake["12"]);
G2L_Fake["13"]["CornerRadius"] = UDim.new(0, 9);

-- Purchase completed title
G2L_Fake["14"] = Instance.new("TextLabel", G2L_Fake["12"]);
G2L_Fake["14"]["TextWrapped"] = true;
G2L_Fake["14"]["BorderSizePixel"] = 0;
G2L_Fake["14"]["TextSize"] = 14;
G2L_Fake["14"]["TextScaled"] = true;
G2L_Fake["14"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["14"]["FontFace"] = Font.new([[rbxassetid://16658221428]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L_Fake["14"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["14"]["BackgroundTransparency"] = 1;
G2L_Fake["14"]["Size"] = UDim2.new(0, 203, 0, 23);
G2L_Fake["14"]["Position"] = UDim2.new(0.02194, 0, 0.06, 0);
G2L_Fake["14"]["Text"] = [[Purchase completed]];

-- Success GamepassName
G2L_Fake["15"] = Instance.new("TextLabel", G2L_Fake["12"]);
G2L_Fake["15"]["TextWrapped"] = true;
G2L_Fake["15"]["BorderSizePixel"] = 0;
G2L_Fake["15"]["TextSize"] = 15;
G2L_Fake["15"]["TextXAlignment"] = Enum.TextXAlignment.Center;
G2L_Fake["15"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["15"]["FontFace"] = Font.new([[rbxassetid://16658221428]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
G2L_Fake["15"]["TextColor3"] = Color3.fromRGB(93, 95, 99);
G2L_Fake["15"]["BackgroundTransparency"] = 1;
G2L_Fake["15"]["RichText"] = true;
G2L_Fake["15"]["Size"] = UDim2.new(0, 428, 0, 29);
G2L_Fake["15"]["Position"] = UDim2.new(0.5, 0, 0.67, 0);
G2L_Fake["15"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L_Fake["15"]["Text"] = [[You have successfuly bought <b>ITEM</b>]];

-- Success RobuxIcon (big checkmark icon)
G2L_Fake["16"] = Instance.new("ImageLabel", G2L_Fake["12"]);
G2L_Fake["16"]["BorderSizePixel"] = 0;
G2L_Fake["16"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["16"]["ImageColor3"] = Color3.fromRGB(221, 222, 224);
G2L_Fake["16"]["Image"] = [[rbxassetid://80606856464773]];
G2L_Fake["16"]["Size"] = UDim2.new(0, 53, 0, 52);
G2L_Fake["16"]["BackgroundTransparency"] = 1;
G2L_Fake["16"]["Position"] = UDim2.new(0.45478, 0, 0.31382, 0);

-- Success ExitButton
G2L_Fake["17"] = Instance.new("ImageButton", G2L_Fake["12"]);
G2L_Fake["17"]["BorderSizePixel"] = 0;
G2L_Fake["17"]["BackgroundTransparency"] = 1;
G2L_Fake["17"]["ImageColor3"] = Color3.fromRGB(205, 205, 207);
G2L_Fake["17"]["Image"] = [[rbxassetid://91733972775823]];
G2L_Fake["17"]["Size"] = UDim2.new(0, 20, 0, 20);
G2L_Fake["17"]["Position"] = UDim2.new(0.90463, 0, 0.07195, 0);

-- OK ButtonBG
G2L_Fake["18"] = Instance.new("CanvasGroup", G2L_Fake["12"]);
G2L_Fake["18"]["BorderSizePixel"] = 0;
G2L_Fake["18"]["BackgroundColor3"] = Color3.fromRGB(39, 62, 143);
G2L_Fake["18"]["Size"] = UDim2.new(0, 431, 0, 34);
G2L_Fake["18"]["Position"] = UDim2.new(0.042, 0, 0.78, 0);

G2L_Fake["19"] = Instance.new("UICorner", G2L_Fake["18"]);
G2L_Fake["19"]["CornerRadius"] = UDim.new(0, 9);

-- OK Filling
G2L_Fake["1a"] = Instance.new("Frame", G2L_Fake["18"]);
G2L_Fake["1a"]["BorderSizePixel"] = 0;
G2L_Fake["1a"]["BackgroundColor3"] = Color3.fromRGB(44, 76, 194);
G2L_Fake["1a"]["Size"] = UDim2.new(0, 0, 1, 0);

-- OK Button
G2L_Fake["1b"] = Instance.new("TextButton", G2L_Fake["12"]);
G2L_Fake["1b"]["BorderSizePixel"] = 0;
G2L_Fake["1b"]["TextSize"] = 17;
G2L_Fake["1b"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L_Fake["1b"]["BackgroundColor3"] = Color3.fromRGB(44, 76, 194);
G2L_Fake["1b"]["FontFace"] = Font.new([[rbxassetid://16658221428]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L_Fake["1b"]["Size"] = UDim2.new(0, 430, 0, 34);
G2L_Fake["1b"]["Text"] = [[OK]];
G2L_Fake["1b"]["Position"] = UDim2.new(0.042, 0, 0.78, 0);
G2L_Fake["1b"]["BackgroundTransparency"] = 1;

G2L_Fake["1c"] = Instance.new("UICorner", G2L_Fake["1b"]);
G2L_Fake["1c"]["CornerRadius"] = UDim.new(0, 9);

-- Preloader (hidden off-screen to force-render textures)
local Preloader = Instance.new("ImageLabel")
Preloader.Name = "AssetPreloader"
Preloader.Parent = G2L_Fake["1"]
Preloader.Size = UDim2.new(0, 1, 0, 1)
Preloader.Position = UDim2.new(2, 0, 2, 0)
Preloader.BackgroundTransparency = 1
Preloader.ImageTransparency = 0.99
Preloader.Visible = true

local tweenInfo_Fake = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function formatBalance(num)
    local str = tostring(math.floor(num))
    return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local isInterceptionDisabled = false
local lastCapturedId = nil

local function updatePurchaseInfo(id, infoType)
    if not id or isInterceptionDisabled then return end
    
    isInterceptionDisabled = true
    local MarketplaceService = game:GetService("MarketplaceService")
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(id, infoType or Enum.InfoType.GamePass)
    end)
    
    local iconId = nil
    if success and info then
        G2L_Fake["6"].RichText = true
        G2L_Fake["6"].Text = "<b>" .. tostring(info.Name):upper() .. "</b>"
        
        local priceNum = info.PriceInRobux or 0
        local priceStr = tostring(priceNum):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        G2L_Fake["a"].Text = priceStr
        
        if info.IconImageAssetId and info.IconImageAssetId ~= 0 then
            iconId = "rbxassetid://" .. info.IconImageAssetId
        elseif info.AssetId then
            iconId = "rbxthumb://type=Asset&id=" .. info.AssetId .. "&w=150&h=150"
        end
        
        if iconId then
            G2L_Fake["7"].Image = iconId
            Preloader.Image = iconId
            pcall(function()
                ContentProvider:PreloadAsync({iconId})
            end)
            task.wait(0.25)
        end
    else
        G2L_Fake["6"].Text = "GAMEPASS (" .. tostring(id) .. ")"
        G2L_Fake["a"].Text = "???"
    end
    isInterceptionDisabled = false

    G2L_Fake["b"].Text = formatBalance(BalanceSystem.amount)

    task.spawn(function()
        G2L_Fake["1"].Enabled = true
        G2L_Fake["3"].Visible = true
        G2L_Fake["12"].Visible = false
        G2L_Fake["3"].GroupTransparency = 1
        
        G2L_Fake["10"].Visible = true
        G2L_Fake["10"].BackgroundTransparency = 1
        G2L_Fake["10"].TextTransparency = 0
        G2L_Fake["f"].Size = UDim2.new(0, 0, 1, 0)
        G2L_Fake["d"].Visible = true
        
        local fadeIn = TweenService:Create(G2L_Fake["3"], tweenInfo_Fake, {GroupTransparency = 0})
        fadeIn:Play()
        fadeIn.Completed:Wait()

        task.wait(1)
        local fillingTween = TweenService:Create(G2L_Fake["f"], TweenInfo.new(3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
        fillingTween:Play()
        fillingTween.Completed:Wait()
        
        G2L_Fake["10"].BackgroundTransparency = 0
        G2L_Fake["d"].Visible = false
    end)
end

-- Buy Button
G2L_Fake["10"].Activated:Connect(function()
    if G2L_Fake["f"].Size.X.Scale < 0.99 then return end
    
    local fadeOutFirst = TweenService:Create(G2L_Fake["3"], tweenInfo_Fake, {GroupTransparency = 1})
    fadeOutFirst:Play()
    
    fadeOutFirst.Completed:Connect(function()
        G2L_Fake["3"].Visible = false
        
        local rawText = G2L_Fake["6"].Text:gsub("<b>", ""):gsub("</b>", "")
        G2L_Fake["15"].Text = "You have successfuly bought " .. rawText
        
        G2L_Fake["12"].Visible = true
        G2L_Fake["12"].GroupTransparency = 1
        G2L_Fake["1a"].Size = UDim2.new(0, 0, 1, 0)
        G2L_Fake["1b"].BackgroundTransparency = 1
        
        local fadeInSecond = TweenService:Create(G2L_Fake["12"], tweenInfo_Fake, {GroupTransparency = 0})
        fadeInSecond:Play()
        fadeInSecond.Completed:Wait()
        
        task.wait(0.5)
        local successFilling = TweenService:Create(G2L_Fake["1a"], TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
        successFilling:Play()
        successFilling.Completed:Wait()
        
        G2L_Fake["1b"].BackgroundTransparency = 0
    end)
end)

-- OK Button
G2L_Fake["1b"].Activated:Connect(function()
    if G2L_Fake["1a"].Size.X.Scale < 0.99 then return end
    
    local price = tonumber((G2L_Fake["a"].Text:gsub(",", ""))) or 0
    BalanceSystem.amount = BalanceSystem.amount - price
    BalanceSystem.giftbux = BalanceSystem.giftbux + math.floor(math.sqrt(price) * 5)
    
    -- Try to trigger VFX effect using fireclient
    task.spawn(function()
        local createVfx = nil
        -- Search for CreateVfx remote in all LocalScripts
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") and obj.Name == "CreateVfx" then
                createVfx = obj
                break
            end
        end
        if createVfx and fireclient then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local spawnPos = hrp and hrp.Position or Vector3.new(0, 5, 0)
            pcall(function()
                fireclient(createVfx, "GiveCurrency", spawnPos, LocalPlayer.Character, price)
            end)
        end
    end)
    
    local fadeOutSuccess = TweenService:Create(G2L_Fake["12"], tweenInfo_Fake, {GroupTransparency = 1})
    fadeOutSuccess:Play()
    
    fadeOutSuccess.Completed:Connect(function()
        G2L_Fake["1"].Enabled = false
        G2L_Fake["12"].Visible = false
        NotificationSystem.trigger("gift sent!", "gift")
    end)
end)

-- Exit Button for Success Frame
G2L_Fake["17"].Activated:Connect(function()
    local fadeOutSuccess = TweenService:Create(G2L_Fake["12"], tweenInfo_Fake, {GroupTransparency = 1})
    fadeOutSuccess:Play()
    fadeOutSuccess.Completed:Connect(function()
        G2L_Fake["1"].Enabled = false
        G2L_Fake["12"].Visible = false
    end)
end)

-- Exit Button for Purchase Frame
G2L_Fake["c"].MouseButton1Click:Connect(function()
    local fadeOut = TweenService:Create(G2L_Fake["3"], tweenInfo_Fake, {GroupTransparency = 1})
    fadeOut.Completed:Connect(function()
        G2L_Fake["1"].Enabled = false
    end)
    fadeOut:Play()
end)

-- Intercept Purchases
local MarketplaceService = game:GetService("MarketplaceService")
local old; old = hookmetamethod(game, "__namecall", function(self, ...)
    if isInterceptionDisabled or not BalanceSystem.enabled then return old(self, ...) end
    local method = getnamecallmethod()
    local args = {...}
    
    if self == MarketplaceService then
        if method == "GetProductInfo" then
            lastCapturedId = args[1]
        elseif method == "PromptGamePassPurchase" or method == "PromptPurchase" or method == "PromptProductPurchase" then
            local id = args[2] or args[1]
            if id and (type(id) == "number" or type(id) == "string") then
                task.spawn(updatePurchaseInfo, tonumber(id), method == "PromptGamePassPurchase" and Enum.InfoType.GamePass or method == "PromptProductPurchase" and Enum.InfoType.Product or Enum.InfoType.Asset)
                return
            end
        end
    end
    
    if self.Name == "Prompt" and method == "FireServer" then
        if lastCapturedId then
            task.spawn(updatePurchaseInfo, tonumber(lastCapturedId), Enum.InfoType.GamePass)
            return
        end
    end
    
    return old(self, ...)
end)

G2L_Fake["1"].Enabled = false

-- 2. GUI SETUP
local Window = Fluent:CreateWindow({
    Title = "NexoHub v1.0",
    SubTitle = "PLS DONATE",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Nametag = Window:AddTab({ Title = "Nametags", Icon = "user" }),
    FakeGift = Window:AddTab({ Title = "Fake Gift", Icon = "gift" }),
    RobuxSpoofer = Window:AddTab({ Title = "Robux Spoofer", Icon = "coins" }),
    AvatarChanger = Window:AddTab({ Title = "Avatar Changer", Icon = "user-check" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Nametag Tab Logic
Tabs.Nametag:AddSection("Nametag Styles")

local plateNames = {}
for _, p in ipairs(NametagSystem.Nameplates) do table.insert(plateNames, p.name) end

local Dropdown = Tabs.Nametag:AddDropdown("NametagSelect", {
    Title = "Select Nametag",
    Values = plateNames,
    Multi = false,
    Default = "Default",
})

Dropdown:OnChanged(function(Value)
    for _, p in ipairs(NametagSystem.Nameplates) do
        if p.name == Value then
            currentPlate = p
            break
        end
    end
    if nametagsEnabled and LocalPlayer.Character then
        updateNametag(LocalPlayer.Character)
    end
end)

Tabs.Nametag:AddToggle("ShowVerifiedBadge", {Title = "Show Verified Badge", Default = false})
Options.ShowVerifiedBadge:OnChanged(function()
    verifiedEnabled = Options.ShowVerifiedBadge.Value
    if nametagsEnabled and LocalPlayer.Character then
        updateNametag(LocalPlayer.Character)
    end
end)

Tabs.Nametag:AddSection("Custom Nametag")

Tabs.Nametag:AddToggle("EnableCustomNametag", {Title = "Enable Custom Nametag", Default = false})
Options.EnableCustomNametag:OnChanged(function()
    customNametag.enabled = Options.EnableCustomNametag.Value
    if nametagsEnabled and LocalPlayer.Character then
        updateNametag(LocalPlayer.Character)
    end
end)

Tabs.Nametag:AddInput("CustomRoleText", {
    Title = "Custom Role Text",
    Default = ".gg/nexohub",
    Placeholder = "Enter role...",
    Callback = function(Value) 
        customNametag.text = Value 
        if nametagsEnabled and LocalPlayer.Character then updateNametag(LocalPlayer.Character) end
    end
})

Tabs.Nametag:AddColorpicker("CustomColor1", {
    Title = "Primary Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value) customNametag.color1 = Value end
})

Tabs.Nametag:AddColorpicker("CustomColor2", {
    Title = "Secondary Color",
    Default = Color3.fromRGB(0, 0, 255),
    Callback = function(Value) customNametag.color2 = Value end
})

Tabs.Nametag:AddDropdown("CustomAnim", {
    Title = "Animation Type",
    Values = {"none", "scroll"},
    Multi = false,
    Default = "none",
    Callback = function(Value) customNametag.anim = Value end
})

Tabs.Nametag:AddSlider("CustomSpeed", {
    Title = "Animation Speed",
    Description = "Speed of the scrolling effect.",
    Default = 0.2,
    Min = 0.05,
    Max = 1,
    Rounding = 2,
})

-- Fake Gift Tab Logic
local donorName = "SpyderSammy"
local giftAmount = 1000000

Tabs.FakeGift:AddInput("DonorName", {
    Title = "Donor Username",
    Default = "SpyderSammy",
    Placeholder = "Enter username...",
    Callback = function(Value) donorName = Value end
})

Tabs.FakeGift:AddInput("GiftAmount", {
    Title = "Robux Amount",
    Default = "1000000",
    Placeholder = "Enter amount...",
    Numeric = true,
    Callback = function(Value) giftAmount = tonumber(Value) or 0 end
})

Tabs.FakeGift:AddButton({
    Title = "Trigger Fake Gift",
    Description = "Spawns a gift box from the selected user.",
    Callback = function()
        FakeGiftSystem.trigger(donorName, giftAmount)
    end
})

-- Robux Spoofer Tab Logic
Tabs.RobuxSpoofer:AddToggle("EnableSpoofer", {Title = "Enable Robux Spoofer", Default = false})
Options.EnableSpoofer:OnChanged(function()
    BalanceSystem.enabled = Options.EnableSpoofer.Value
end)

Tabs.RobuxSpoofer:AddInput("BalanceAmount", {
    Title = "Initial Balance",
    Default = "1000000",
    Numeric = true,
    Callback = function(Value)
        BalanceSystem.amount = tonumber(Value) or 0
    end
})

-- Avatar Changer Tab Logic
local avatarUserId = ""

local function avatarClearVisuals(char)
    for _, inst in ipairs(char:GetChildren()) do
        if inst:IsA("Accessory") or inst:IsA("Hat") or inst:IsA("Shirt")
        or inst:IsA("Pants") or inst:IsA("ShirtGraphic") or inst:IsA("CharacterMesh") then
            inst:Destroy()
        end
    end
    local head = char:FindFirstChild("Head")
    if head then
        for _, d in ipairs(head:GetChildren()) do
            if d:IsA("Decal") and d.Name:lower() == "face" then d:Destroy() end
        end
    end
    local bc = char:FindFirstChildOfClass("BodyColors")
    if bc then bc:Destroy() end
end

local function avatarAttachAccessory(char, accessory)
    local handle = accessory:FindFirstChild("Handle")
    if not handle then return end
    local targetAtt, accAtt
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            for _, att in ipairs(part:GetChildren()) do
                if att:IsA("Attachment") then
                    local match = handle:FindFirstChild(att.Name)
                    if match and match:IsA("Attachment") then
                        targetAtt = att
                        accAtt = match
                        break
                    end
                end
            end
        end
        if targetAtt then break end
    end
    if targetAtt and accAtt then
        handle.CFrame = targetAtt.WorldCFrame * accAtt.CFrame:Inverse()
    else
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then handle.CFrame = root.CFrame end
    end
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = (targetAtt and targetAtt.Parent) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    weld.Parent = handle
    accessory.Parent = char
end

local function applyAppearance(userId)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local ok, model = pcall(function()
        return game:GetService("Players"):GetCharacterAppearanceAsync(userId)
    end)
    if not ok or not model then return false, tostring(model) end
    avatarClearVisuals(char)
    local bc = model:FindFirstChildOfClass("BodyColors")
    if bc then bc:Clone().Parent = char end
    for _, item in ipairs(model:GetChildren()) do
        if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("CharacterMesh") then
            item:Clone().Parent = char
        end
    end
    for _, acc in ipairs(model:GetChildren()) do
        if acc:IsA("Accessory") or acc:IsA("Hat") then
            avatarAttachAccessory(char, acc:Clone())
        end
    end
    local head = char:FindFirstChild("Head")
    if head then
        local face = model:FindFirstChild("face", true)
        if face and face:IsA("Decal") then
            face:Clone().Parent = head
        end
    end
    return true
end

Tabs.AvatarChanger:AddInput("AvatarUserId", {
    Title = "User ID",
    Placeholder = "Enter player's User ID...",
    Callback = function(Value) avatarUserId = Value end
})

Tabs.AvatarChanger:AddButton({
    Title = "Apply Skin",
    Description = "Copies clothes, accessories and face from given User ID.",
    Callback = function()
        local id = tonumber(avatarUserId)
        if not id then
            Fluent:Notify({Title = "Avatar Changer", Content = "Invalid User ID!", Duration = 3})
            return
        end
        task.spawn(function()
            local ok, err = applyAppearance(id)
            if ok then
                Fluent:Notify({Title = "Avatar Changer", Content = "Skin applied!", Duration = 3})
            else
                Fluent:Notify({Title = "Avatar Changer", Content = "Failed: " .. tostring(err):sub(1,60), Duration = 5})
            end
        end)
    end
})

Tabs.AvatarChanger:AddButton({
    Title = "Reset Character",
    Description = "Restores your original Roblox appearance.",
    Callback = function()
        task.spawn(function()
            local ok, err = applyAppearance(LocalPlayer.UserId)
            if ok then
                Fluent:Notify({Title = "Avatar Changer", Content = "Character reset!", Duration = 3})
            else
                Fluent:Notify({Title = "Avatar Changer", Content = "Reset failed: " .. tostring(err):sub(1,50), Duration = 5})
            end
        end)
    end
})

RunService.RenderStepped:Connect(function()
    if not nametagsEnabled then return end
    local char = LocalPlayer.Character
    local head = char and char:FindFirstChild("Head")
    local headTag = head and head:FindFirstChild("HeadTag")
    if headTag then
        for _, label in ipairs(headTag:GetChildren()) do
            if label:IsA("TextLabel") then
                -- Gradient Animation
                local grad = label:FindFirstChild("AntigravityGrad")
                if grad then
                    if customNametag.enabled then
                        if customNametag.anim == "scroll" then
                            local offset = os.clock() * customNametag.speed
                            local stops = {customNametag.color1, customNametag.color2, customNametag.color1}
                            local kps = {}
                            for i = 0, 6 do
                                local ratio = i / 6
                                table.insert(kps, ColorSequenceKeypoint.new(ratio, getGradientColor(stops, ratio + offset)))
                            end
                            grad.Color = ColorSequence.new(kps)
                        else
                            grad.Color = ColorSequence.new(customNametag.color1, customNametag.color2)
                        end
                    elseif currentPlate.id ~= "default" then
                        grad.Color = NametagSystem.buildAnimatedGradient(currentPlate, os.clock())
                    end
                end
                
                -- Verified Badge Logic
                if label.Name ~= "Role" and label.Text ~= "" then
                    local badge = label:FindFirstChild("VerifiedBadge")
                    if verifiedEnabled then
                        if not badge then
                            badge = Instance.new("ImageLabel")
                            badge.Name = "VerifiedBadge"
                            badge.BackgroundTransparency = 1
                            badge.Image = verifiedBadgeId
                            badge.Size = UDim2.new(0, 14, 0, 14) -- Reduced size
                            badge.ZIndex = label.ZIndex + 20
                            badge.Parent = label
                        end
                        badge.Image = verifiedBadgeId
                        badge.Visible = true
                        
                        -- Force Position next to text
                        local textService = game:GetService("TextService")
                        local success, size = pcall(function()
                            return textService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(1000, 1000))
                        end)
                        if success and label.AbsoluteSize.X > 0 and label.AbsoluteSize.Y > 0 then
                            local badgeSizeX = badge.AbsoluteSize.X > 0 and badge.AbsoluteSize.X or 14
                            local badgeSizeY = badge.AbsoluteSize.Y > 0 and badge.AbsoluteSize.Y or 14
                            badge.Position = UDim2.new(0.5, (size.X / 2) + 5, 0.5, -(badgeSizeY / 2))
                        end
                    elseif badge then
                        badge:Destroy()
                    end
                end
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    updateNametag(char)
end)

if LocalPlayer.Character then updateNametag(LocalPlayer.Character) end

-- Finalize managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("PlsDonate")
SaveManager:SetFolder("PlsDonate/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({Title = "NexoHub", Content = "Script loaded successfully!", Duration = 5})
SaveManager:LoadAutoloadConfig()
