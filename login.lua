local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Lista wspieranych gier (Game ID -> loadstring URL)
local supportedGameIds = {
    [118637423917462] = "https://raw.githubusercontent.com/piotlek12pl/NexoHub/refs/heads/main/games/caseparadise.lua",
    [70390793715007] = "https://raw.githubusercontent.com/piotlek12pl/NexoHub/refs/heads/main/games/hooked.lua",
}

-- Clean up poprzedniej wersji GUI
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

-- Main GUI
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

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(35, 35, 38)
frameStroke.Thickness = 1
frameStroke.Parent = mainFrame

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
    local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        GroupTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.55, 0)
    })
    tween:Play()
    tween.Completed:Wait()
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
avatarStroke.Color = Color3.fromRGB(255, 45, 65) -- Czerwona obwódka jak na zdjęciu
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
    adminLabel.TextColor3 = Color3.fromRGB(255, 45, 65)
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
inputStroke.Color = Color3.fromRGB(45, 45, 50)
inputStroke.Thickness = 1
inputStroke.Parent = inputContainer

local inputBox = Instance.new("TextBox")
inputBox.Name = "InputField"
inputBox.Size = UDim2.new(1, -30, 1, 0)
inputBox.Position = UDim2.new(0.5, 0, 0.5, 0)
inputBox.AnchorPoint = Vector2.new(0.5, 0.5)
inputBox.BackgroundTransparency = 1
inputBox.Text = ""
inputBox.PlaceholderText = "License Key"
inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 125)
inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
inputBox.TextSize = 14
inputBox.Font = Enum.Font.GothamMedium
inputBox.TextXAlignment = Enum.TextXAlignment.Center
inputBox.ClearTextOnFocus = false
inputBox.Parent = inputContainer

-- Animacja dla Pola Tekstowego (Czerwona obwódka po kliknięciu)
inputBox.Focused:Connect(function()
    TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 45, 65)}):Play()
end)
inputBox.FocusLost:Connect(function()
    TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(45, 45, 50)}):Play()
end)

-- Przycisk Submit
local submitBtn = Instance.new("TextButton")
submitBtn.Name = "SubmitButton"
submitBtn.Size = UDim2.new(0.85, 0, 0, 40)
submitBtn.Position = UDim2.new(0.5, 0, 0, 270)
submitBtn.AnchorPoint = Vector2.new(0.5, 0)
submitBtn.BackgroundColor3 = Color3.fromRGB(255, 45, 65) -- Czerwony nowoczesny
submitBtn.Text = "Submit"
submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.TextSize = 14
submitBtn.Font = Enum.Font.GothamBold
submitBtn.AutoButtonColor = false -- Własna animacja hover
submitBtn.Parent = mainFrame

local submitCorner = Instance.new("UICorner")
submitCorner.CornerRadius = UDim.new(0, 8)
submitCorner.Parent = submitBtn

-- Przycisk Get Key
local getKeyBtn = Instance.new("TextButton")
getKeyBtn.Name = "GetKeyButton"
getKeyBtn.Size = UDim2.new(0.85, 0, 0, 30)
getKeyBtn.Position = UDim2.new(0.5, 0, 0, 320)
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
        setclipboard("https://link-to.net/1459465/twoj-link-do-klucza")
    end)
    
    -- Informacja zwrotna na przycisku
    local oldText = getKeyBtn.Text
    getKeyBtn.Text = "Link copied to clipboard!"
    TweenService:Create(getKeyBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(45, 255, 100)}):Play()
    
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
    TweenService:Create(submitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 65, 85)}):Play()
end)
submitBtn.MouseLeave:Connect(function()
    TweenService:Create(submitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 45, 65)}):Play()
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

submitBtn.MouseButton1Click:Connect(function()
    -- Opcjonalny efekt kliknięcia (pulsowanie)
    local clickTween = TweenService:Create(submitBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0.82, 0, 0, 38)
    })
    clickTween:Play()
    clickTween.Completed:Connect(function()
        TweenService:Create(submitBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0.85, 0, 0, 40)
        }):Play()
    end)
    
    -- Weryfikacja klucza przez API Vercel
    local keyValid = false
    local verifyUrl = "https://nexo-hub-phi.vercel.app/api?verify=" .. game:GetService("HttpService"):UrlEncode(inputBox.Text)
    pcall(function()
        local response = game:HttpGet(verifyUrl)
        local data = game:GetService("HttpService"):JSONDecode(response)
        if data and data.valid == true then
            keyValid = true
        end
    end)
    
    if keyValid then
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
        displayStatus("Verifying License", 0.8)
        displayStatus("Bypassing Byfron", 0.8)
        
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
        
        displayStatus("Checking Game", 0.8)
        displayStatus("Injecting Modules", 0.8)
        
        -- Zamykanie GUI
        local gameUrl = supportedGameIds[currentGameId]
        local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            GroupTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.55, 0)
        })
        closeTween:Play()
        closeTween.Completed:Wait()
        gui:Destroy()
        
        -- Wykonanie loadstringa przypisanego do danej gry
        if gameUrl then
            loadstring(game:HttpGet(gameUrl))()
        end
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
