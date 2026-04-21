local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- System Zapisywania Kluczy
local KEY_FOLDER = "NexoHub"
local KEY_FILE = KEY_FOLDER .. "/key.txt"

local function getGameName()
    local gid = tostring(game.GameId)
    local pid = tostring(game.PlaceId)
    local actualName = "Unknown Game"
    
    -- Próba pobrania prawdziwej nazwy gry z serwerów Roblox (najpewniejsza metoda)
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        actualName = info.Name
    end)
    
    -- Debug w konsoli F9 dla Ciebie (możesz sprawdzić co skrypt widzi)
    warn("[NexoHub] Debug - GameId: " .. gid .. " | PlaceId: " .. pid .. " | Name: " .. actualName)
    
    if gid == "70390793715007" or pid == "70390793715007" or actualName:find("Hooked") then 
        return "Hooked!" 
    end
    if gid == "118637423917462" or pid == "118637423917462" or actualName:find("Case Paradise") then 
        return "Case Paradise" 
    end
    if gid == "84259959693333" or pid == "84259959693333" or actualName:find("Skateboard for Brainrots") then 
        return "Skateboard for Brainrots" 
    end
    if gid == "8737602449" or pid == "8737602449" or actualName:find("PLS DONATE") then 
        return "PLS DONATE" 
    end
    
    return actualName
end

-- Lista permanentnych kluczy (Master Keys)
local permanentKeys = {
    ["NEXO-ADMIN-PERM-99"] = true,
    ["NEXO-A7K9P"] = true, -- uzywany
    ["NEXO-9XB2M"] = true, -- uzywany
    ["NEXO-OWNER-KEY-01"] = true,
    ["NEXO-VIP-FOREVER"] = true,
    ["DEVELOPER-BYPASS"] = true
}

-- ===== XOR DECRYPTION (odpowiada XOR w nexohub.js) =====
-- Zamienia hex string -> bytes -> XOR z kluczem -> string
-- Używamy bit32.bxor() zamiast ~ (tylko Lua 5.3+, nie działa na wszystkich egzekutorach)
local function xorDecryptHex(hexStr, key)
    local result = {}
    local keyBytes = {}
    for i = 1, #key do
        keyBytes[#keyBytes + 1] = string.byte(key, i)
    end
    local keyLen = #keyBytes
    local byteIdx = 0
    for i = 1, #hexStr - 1, 2 do
        local byte = tonumber(hexStr:sub(i, i+1), 16)
        local keyByte = keyBytes[(byteIdx % keyLen) + 1]
        result[#result + 1] = string.char(bit32.bxor(byte, keyByte))
        byteIdx = byteIdx + 1
    end
    return table.concat(result)
end

-- Globalny token sesji (po weryfikacji klucza)
local sessionToken = nil

-- Funkcja weryfikująca klucz API
local function verifyKey(key)
    local keyValid = false
    local executorName = identifyexecutor and identifyexecutor() or "Unknown Executor"
    local gameName = getGameName()
    
    local verifyUrl = "https://nexohub-new.vercel.app/api?verify=" .. HttpService:UrlEncode(key) .. "&executor=" .. HttpService:UrlEncode(executorName) .. "&game=" .. HttpService:UrlEncode(gameName)
    
    pcall(function()
        local response = game:HttpGet(verifyUrl)
        local data = HttpService:JSONDecode(response)
        if data and data.valid == true then
            keyValid = true
            -- Odbieramy jednorazowy session token z backendu (nawet dla kluczy VIP)
            if data.token then
                sessionToken = data.token
            end
            
            -- Jeżeli backend zaakceptował (np. VIP keys to my traktujemy to jako permanent w UI)
            if key:match("NEXO%-ADMIN") or key:match("VIP") or key:match("OWNER") then
                getgenv().Nexo_PermanentKey = true
            end
        end
    end)
    return keyValid
end

-- Lista wspieranych gier (tylko weryfikacja Game ID, prawdziwe URLe są ukryte na serwerze!)
local supportedGameIds = {
    [118637423917462] = true,
    [70390793715007] = true,
    [8737602449] = true,
    [84259959693333] = true,
}

-- ==========================================
-- AUTO LOGIN (Definicje stanów)
-- ==========================================
local isAutoLogin = false
local autoLoginGameUrl = nil
if isfolder and not isfolder(KEY_FOLDER) then
    pcall(function() makefolder(KEY_FOLDER) end)
end

if isfile and isfile(KEY_FILE) then
    local savedKey = nil
    pcall(function() savedKey = readfile(KEY_FILE) end)
    
    if savedKey and savedKey ~= "" then
        print("[NexoHub] Found Saved Key!")
        if verifyKey(savedKey) then
            print("[NexoHub] Loading Script..")
            isAutoLogin = true
        else
            print("[NexoHub] Key is Expired!")
            if delfile then pcall(function() delfile(KEY_FILE) end) end
        end
    end
end
-- ==========================================

-- Clean up poprzedniej wersji GUI i Blura
local uiName = "NexoLogin"
pcall(function() 
    if CoreGui:FindFirstChild(uiName) then 
        CoreGui[uiName]:Destroy() 
    end 
end)
pcall(function() 
    if player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild(uiName) then 
        player.PlayerGui[uiName]:Destroy() 
    end 
end)
pcall(function()
    if game:GetService("Lighting"):FindFirstChild("NexoBlur") then
        game:GetService("Lighting").NexoBlur:Destroy()
    end
end)

-- Main GUI & Efekt Blur
local blur = Instance.new("BlurEffect")
blur.Name = "NexoBlur"
blur.Size = 0
blur.Parent = game:GetService("Lighting")

TweenService:Create(blur, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Size = 24
}):Play()

local gui = Instance.new("ScreenGui")
gui.Name = uiName
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local success = pcall(function() 
    gui.Parent = CoreGui 
end)
if not success then 
    gui.Parent = player:WaitForChild("PlayerGui") 
end

-- Nowoczesny Konterner główny (CanvasGroup dla efektu fade)
local mainFrame = Instance.new("CanvasGroup")
mainFrame.Name = "Container"
mainFrame.Size = UDim2.new(0, 320, 0, 380)
mainFrame.Position = UDim2.new(0.5, 0, 0.55, 0) -- Zaczyna trochę niżej do animacji wyjazdu
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 14) -- Ciemnoszary, wręcz czarny (nowoczesny)
mainFrame.BorderSizePixel = 0
mainFrame.GroupTransparency = 1 
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = mainFrame

-- Usunięto obramowanie główne na prośbę użytkownika

-- Przycisk zamykania 'X'
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -10, 0, 10)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "x"
closeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
end)
closeBtn.MouseButton1Click:Connect(function()
    -- Animacja ukrywania Blura
    TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = 0 }):Play()
    
    local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        GroupTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.55, 0)
    })
    closeTween:Play()
    closeTween.Completed:Wait()
    blur:Destroy()
    gui:Destroy()
end)

-- Kontener Avatara
local avatarSize = 85
local avatarBg = Instance.new("Frame")
avatarBg.Name = "AvatarBackground"
avatarBg.Size = UDim2.new(0, avatarSize, 0, avatarSize)
avatarBg.Position = UDim2.new(0.5, 0, 0, 50)
avatarBg.AnchorPoint = Vector2.new(0.5, 0)
avatarBg.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
avatarBg.Parent = mainFrame

local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(1, 0)
avatarCorner.Parent = avatarBg

local avatarStroke = Instance.new("UIStroke")
avatarStroke.Color = Color3.fromRGB(245, 158, 11) -- Bursztynowa obwódka
avatarStroke.Thickness = 2
avatarStroke.Parent = avatarBg

local avatarImg = Instance.new("ImageLabel")
avatarImg.Name = "AvatarImage"
avatarImg.Size = UDim2.new(1, 0, 1, 0)
avatarImg.BackgroundTransparency = 1
avatarImg.Parent = avatarBg

local avatarImgCorner = Instance.new("UICorner")
avatarImgCorner.CornerRadius = UDim.new(1, 0)
avatarImgCorner.Parent = avatarImg

-- Pobieranie głowy gracza (HeadShot)
task.spawn(function()
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size420x420
    local content, isReady = Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)
    if isReady then
        avatarImg.Image = content
    end
end)

-- Nazwa Gracza (Player Name)
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "PlayerName"
nameLabel.Size = UDim2.new(1, 0, 0, 25)
nameLabel.Position = UDim2.new(0.5, 0, 0, 145)
nameLabel.AnchorPoint = Vector2.new(0.5, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = player.Name
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.TextSize = 18
nameLabel.Font = Enum.Font.GothamBold
nameLabel.Parent = mainFrame

-- Czerwony napis ADMIN
local adminLabel = Instance.new("TextLabel")
adminLabel.Name = "AdminRole"
adminLabel.Size = UDim2.new(1, 0, 0, 15)
adminLabel.Position = UDim2.new(0.5, 0, 0, 170)
adminLabel.AnchorPoint = Vector2.new(0.5, 0)
adminLabel.BackgroundTransparency = 1
if player.Name == "piotlek12pl" then
    adminLabel.Text = "ADMIN"
    adminLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
elseif getgenv().Nexo_PermanentKey then
    adminLabel.Text = "VIP ACCESS"
    adminLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
else
    adminLabel.Text = "USER"
    adminLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
end
adminLabel.TextSize = 12
adminLabel.Font = Enum.Font.GothamBlack
adminLabel.Parent = mainFrame

-- Pola Tekstowe (Input Box)
local inputContainer = Instance.new("Frame")
inputContainer.Name = "InputContainer"
inputContainer.Size = UDim2.new(0.85, 0, 0, 45)
inputContainer.Position = UDim2.new(0.5, 0, 0, 210)
inputContainer.AnchorPoint = Vector2.new(0.5, 0)
inputContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
inputContainer.Parent = mainFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = inputContainer

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(35, 35, 38)
inputStroke.Thickness = 1
inputStroke.Parent = inputContainer

local fingerIcon = Instance.new("ImageLabel")
fingerIcon.Name = "FingerprintIcon"
fingerIcon.Size = UDim2.new(0, 20, 0, 20)
fingerIcon.Position = UDim2.new(0, 10, 0.5, 0)
fingerIcon.AnchorPoint = Vector2.new(0, 0.5)
fingerIcon.BackgroundTransparency = 1
fingerIcon.Image = "rbxassetid://1482708142906146856" -- Będzie podmienione na obrazek z linku poprzez proxy Robloxa (lub asset id jeśli dostępne)
fingerIcon.ImageTransparency = 0.2
-- Większość exploitów obsługuje pobieranie obrazków przez getcustomasset lub bezpośrednie linki
pcall(function()
    if getcustomasset then
        -- Jeśli executor wspiera pobieranie do plików
        local fileName = "fox_finger.png"
        writefile(fileName, game:HttpGet("https://cdn.discordapp.com/attachments/1442178184861716622/1482708142906146856/fingerprint_24dp_E3E3E3_FILL0_wght400_GRAD0_opsz24.png?ex=69b7ef10&is=69b69d90&hm=b39091794d2b9dcf7486601877e38b4f6bbb19751ca55c77575c9272f222b008&"))
        fingerIcon.Image = getcustomasset(fileName)
    else
        -- Próba bezpośrednia (może nie działać na każdym)
        fingerIcon.Image = "https://cdn.discordapp.com/attachments/1442178184861716622/1482708142906146856/fingerprint_24dp_E3E3E3_FILL0_wght400_GRAD0_opsz24.png?ex=69b7ef10&is=69b69d90&hm=b39091794d2b9dcf7486601877e38b4f6bbb19751ca55c77575c9272f222b008&"
    end
end)
fingerIcon.Parent = inputContainer

local inputBox = Instance.new("TextBox")
inputBox.Name = "InputField"
inputBox.Size = UDim2.new(1, -50, 1, 0)
inputBox.Position = UDim2.new(0, 40, 0.5, 0)
inputBox.AnchorPoint = Vector2.new(0, 0.5)
inputBox.BackgroundTransparency = 1
inputBox.Text = ""
inputBox.PlaceholderText = "License Key"
inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 125)
inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
inputBox.TextSize = 14
inputBox.Font = Enum.Font.GothamMedium
inputBox.TextXAlignment = Enum.TextXAlignment.Left
inputBox.ClearTextOnFocus = false
inputBox.Parent = inputContainer

-- Animacja dla Pola Tekstowego (Czerwona obwódka po kliknięciu)
inputBox.Focused:Connect(function()
    TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(245, 158, 11)}):Play()
end)
inputBox.FocusLost:Connect(function()
    TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(35, 35, 38)}):Play()
end)

-- Przycisk Authenticate (Outline Mode)
local submitBtn = Instance.new("TextButton")
submitBtn.Name = "SubmitButton"
submitBtn.Size = UDim2.new(0.85, 0, 0, 45) -- Nieco mniejszy, by starczyło miejsca
submitBtn.Position = UDim2.new(0.5, 0, 0, 270)
submitBtn.AnchorPoint = Vector2.new(0.5, 0)
submitBtn.BackgroundTransparency = 1 -- Brak wypełnienia
submitBtn.Text = "AUTHENTICATE"
submitBtn.TextColor3 = Color3.fromRGB(245, 158, 11)
submitBtn.TextSize = 13
submitBtn.Font = Enum.Font.GothamBold
submitBtn.AutoButtonColor = false
submitBtn.Parent = mainFrame

local submitStroke = Instance.new("UIStroke")
submitStroke.Color = Color3.fromRGB(245, 158, 11)
submitStroke.Thickness = 1.5
submitStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
submitStroke.Parent = submitBtn

local submitCorner = Instance.new("UICorner")
submitCorner.CornerRadius = UDim.new(0, 10)
submitCorner.Parent = submitBtn

-- Przycisk Get Key
local getKeyBtn = Instance.new("TextButton")
getKeyBtn.Name = "GetKeyButton"
getKeyBtn.Size = UDim2.new(0.85, 0, 0, 30)
getKeyBtn.Position = UDim2.new(0.5, 0, 0, 325) -- Obniżony o 5px, by nie nachodził
getKeyBtn.AnchorPoint = Vector2.new(0.5, 0)
getKeyBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
getKeyBtn.Text = "Get Key"
getKeyBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
getKeyBtn.TextSize = 13
getKeyBtn.Font = Enum.Font.GothamMedium
getKeyBtn.AutoButtonColor = false
getKeyBtn.Parent = mainFrame

local getKeyCorner = Instance.new("UICorner")
getKeyCorner.CornerRadius = UDim.new(0, 6)
getKeyCorner.Parent = getKeyBtn

local getKeyStroke = Instance.new("UIStroke")
getKeyStroke.Color = Color3.fromRGB(45, 45, 50)
getKeyStroke.Thickness = 1
getKeyStroke.Parent = getKeyBtn

-- Animacja Hover dla przycisku Get Key
getKeyBtn.MouseEnter:Connect(function()
    TweenService:Create(getKeyBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(30, 30, 32)}):Play()
end)
getKeyBtn.MouseLeave:Connect(function()
    TweenService:Create(getKeyBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundColor3 = Color3.fromRGB(20, 20, 22)}):Play()
end)

getKeyBtn.MouseButton1Click:Connect(function()
    -- Tutaj wstawiasz swój docelowy link z Linkvertise (podmień na ten, który wygenerujesz w panelu Linkvertise)
    -- Przykład: setclipboard("https://link-to.net/1459465/nexohub-key")
    -- W Robloxie exploity obsługują setclipboard, ewentualnie otwierają link w oknie robloxa.
    pcall(function()
        setclipboard("https://direct-link.net/1108008/MKwkmFy9Evql")
    end)
    
    -- Informacja zwrotna na przycisku
    local oldText = getKeyBtn.Text
    getKeyBtn.Text = "Link copied to clipboard!"
    TweenService:Create(getKeyBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(245, 158, 11)}):Play()
    
    task.delay(2, function()
        getKeyBtn.Text = oldText
        TweenService:Create(getKeyBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
    end)
end)

-- Napis statusu operacji (ukryty na start)
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.Position = UDim2.new(0.5, 0, 0, 235)
statusLabel.AnchorPoint = Vector2.new(0.5, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 16
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextTransparency = 1
statusLabel.Parent = mainFrame

-- Animacja Hover dla przycisku Submit
submitBtn.MouseEnter:Connect(function()
    TweenService:Create(submitStroke, TweenInfo.new(0.2), {Thickness = 2.5, Color = Color3.fromRGB(255, 215, 0)}):Play()
    TweenService:Create(submitBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 215, 0)}):Play()
end)
submitBtn.MouseLeave:Connect(function()
    TweenService:Create(submitStroke, TweenInfo.new(0.2), {Thickness = 1.5, Color = Color3.fromRGB(245, 158, 11)}):Play()
    TweenService:Create(submitBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(245, 158, 11)}):Play()
end)

local function displayStatus(text, duration)
    statusLabel.Text = text
    local fadeIn = TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 0})
    fadeIn:Play()
    task.wait(duration)
    local fadeOut = TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 1})
    fadeOut:Play()
    fadeOut.Completed:Wait()
end

local function startInjectionSequence()
    -- Ukrywamy textbox i przyciski (Fade out + przesuwanie)
    TweenService:Create(inputContainer, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 220)
    }):Play()
    TweenService:Create(inputBox, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        TextTransparency = 1
    }):Play()
    TweenService:Create(inputStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Transparency = 1
    }):Play()
    
    TweenService:Create(submitBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1,
        TextTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 280)
    }):Play()
    
    TweenService:Create(getKeyBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1,
        TextTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 330)
    }):Play()
    TweenService:Create(getKeyStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Transparency = 1
    }):Play()
    
    task.wait(0.5)
    
    inputContainer.Visible = false
    submitBtn.Visible = false
    getKeyBtn.Visible = false
    
    -- Sekwencja napisów (przyspieszona do 0.8s zamiast 1.5s)
    displayStatus("Verifying License", 0.6)
    
    if isAutoLogin then
        displayStatus("Saved Key Found", 0.6)    
    end
    
    displayStatus("Bypassing Byfron", 0.6)
    
    -- Sprawdzanie czy gra jest wspierana
    local currentGameId = game.PlaceId
    if not supportedGameIds[currentGameId] then
        -- Gra NIE jest wspierana
        statusLabel.Text = ""
        statusLabel.TextTransparency = 1
        
        -- Napis o braku wsparcia
        local unsupportedLabel = Instance.new("TextLabel")
        unsupportedLabel.Name = "UnsupportedLabel"
        unsupportedLabel.Size = UDim2.new(0.9, 0, 0, 60)
        unsupportedLabel.Position = UDim2.new(0.5, 0, 0, 220)
        unsupportedLabel.AnchorPoint = Vector2.new(0.5, 0)
        unsupportedLabel.BackgroundTransparency = 1
        unsupportedLabel.Text = "This Game is not Supported!\nCheck Discord for Supported Games"
        unsupportedLabel.TextColor3 = Color3.fromRGB(255, 45, 65)
        unsupportedLabel.TextSize = 14
        unsupportedLabel.Font = Enum.Font.GothamBold
        unsupportedLabel.TextWrapped = true
        unsupportedLabel.TextTransparency = 1
        unsupportedLabel.Parent = mainFrame
        
        -- Animacja pojawienia się
        TweenService:Create(unsupportedLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
        
        -- Po 4 sekundach zamykamy GUI
        task.wait(4)
        local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            GroupTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.55, 0)
        })
        closeTween:Play()
        closeTween.Completed:Wait()
        gui:Destroy()
        return
    end
    
    displayStatus("Checking Game", 0.6)
    displayStatus("Injecting Modules", 0.6)
    
    -- Zamykanie GUI przed skryptem gry
    local isGameSupported = supportedGameIds[currentGameId]
    TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = 0 }):Play()
    local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        GroupTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.55, 0)
    })
    closeTween:Play()
    closeTween.Completed:Wait()
    blur:Destroy()
    gui:Destroy()
    
    if isGameSupported then
        getgenv().Nexo_Authorized = "NexoHub_Session_Success"
        
        -- Używamy zabezpieczonego endpointu z tokenem i ID gry
        if sessionToken then
            local currentPlaceId = tostring(game.PlaceId)
            local secureUrl = "https://nexohub-new.vercel.app/api/nexohub"
                .. "?token=" .. HttpService:UrlEncode(sessionToken)
                .. "&game=" .. currentPlaceId
            
            local ok, encResponse = pcall(function()
                return game:HttpGet(secureUrl)
            end)
            
            if ok and encResponse and encResponse:sub(1, 12) == "NEXO_ENC_V1|" then
                -- Parsujemy format: "NEXO_ENC_V1|TOKEN|HEX_DATA"
                local parts = {}
                for part in encResponse:gmatch("([^|]+)") do
                    parts[#parts + 1] = part
                end
                
                if #parts >= 3 then
                    local echoToken = parts[2]
                    local hexData   = parts[3]
                    
                    -- Deszyfrujemy XOR używając tokenu jako klucza
                    local decryptedScript = xorDecryptHex(hexData, echoToken)
                    
                    if #decryptedScript > 100 then
                        local fn, compileErr = loadstring(decryptedScript)
                        if fn then
                            fn()
                        else
                            warn("[NexoHub] Compile error: " .. tostring(compileErr))
                        end
                    else
                        warn("[NexoHub] Decryption failed or payload empty.")
                    end
                else
                    warn("[NexoHub] Bad response format from server.")
                end
            else
                warn("[NexoHub] Backend server rejected request. (Token expired or unauthorized)")
            end
        else
            -- Rozłączono z serwerem, brak tokenu sesji - nie ma bezpośrednich fallbacków!
            warn("[NexoHub] No active session token found!")
        end
    end
end

submitBtn.MouseButton1Click:Connect(function()
    -- Opcjonalny efekt kliknięcia (pulsowanie)
    local clickTween = TweenService:Create(submitBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0.82, 0, 0, 38)
    })
    clickTween:Play()
    clickTween.Completed:Connect(function()
        TweenService:Create(submitBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0.85, 0, 0, 45)
        }):Play()
    end)
    
    -- Weryfikacja klucza funkcją API
    local keyValid = verifyKey(inputBox.Text)
    
    if keyValid then
        -- ZAPIS KLUCZA PO POPRAWNYM ZALOGOWANIU
        if writefile then
            pcall(function()
                if isfolder and not isfolder(KEY_FOLDER) then makefolder(KEY_FOLDER) end
                writefile(KEY_FILE, inputBox.Text)
            end)
        end
        startInjectionSequence()
    else
        -- Zły klucz (efekt trzęsienia)
        local originalPos = inputContainer.Position
        for i = 1, 3 do
            TweenService:Create(inputContainer, TweenInfo.new(0.05), {Position = originalPos + UDim2.new(0, -5, 0, 0)}):Play()
            task.wait(0.05)
            TweenService:Create(inputContainer, TweenInfo.new(0.05), {Position = originalPos + UDim2.new(0, 5, 0, 0)}):Play()
            task.wait(0.05)
        end
        TweenService:Create(inputContainer, TweenInfo.new(0.05), {Position = originalPos}):Play()
    end
end)

-- Początkowa Animacja Okienka (Fade in i delikatny najazd z dołu)
TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    GroupTransparency = 0,
    Position = UDim2.new(0.5, 0, 0.5, 0)
}):Play()

-- Logika przeciągania okienka (Draggable) - idealne dla menu!
local dragging
local dragInput
local dragStart
local startPos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Jeśli AutoLogin wykrył poprawny klucz przy starcie skryptu
if isAutoLogin then
    -- Natychmiastowe ukrycie zbędnych elementów przed startem wyjazdu
    inputContainer.Visible = false
    submitBtn.Visible = false
    getKeyBtn.Visible = false
    
    -- Wywołanie z lekkim opóźnieniem by animacja bazowa UI Frame się skończyła
    task.delay(0.6, function()
        startInjectionSequence()
    end)
end
