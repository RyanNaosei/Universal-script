```lua
--[[
    SCRIPT UNIVERSAL PARA [TNM] TROCA DE TIRO NA MARÉ
    GUI: Kavo UI + Botão Flutuante + FPS Boost
    Features: ESP, Silent Aim, God Mode, Munição Infinita, Speed, Noclip, Kill All, Anti-Aim, No Recoil, Fullbright, FPS Boost
    ATENÇÃO: Use por sua conta e risco. Em caso de erro, tente re-executar.
]]

-- Carregar Interface Kavo UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("[TNM] Maré Hub - Universal", "DarkTheme")
local player = game.Players.LocalPlayer
local camera = game.Workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")

-- Configurações Globais via getgenv()
getgenv().Settings = {
    ESP = { Enabled = false, Box = true, Tracer = true, Name = true, Distance = true, Health = true, Weapon = true },
    SilentAim = { Enabled = false, FOV = 150, Smooth = 0.15, Prediction = 0.165, HitChance = 100, ShowFOV = true, FOVColor = Color3.fromRGB(255, 255, 255) },
    GodMode = false,
    InfAmmo = false,
    Speed = { Enabled = false, Walk = 32, Jump = 50 },
    Noclip = false,
    KillAll = false,
    AntiAim = { Enabled = false, Pitch = -90, YawSpeed = 10 },
    NoRecoil = false,
    Fullbright = false,
    FPSBoost = { Enabled = false, Quality = 1, Shadows = false, Textures = false, Effects = false } -- Quality: 1=Baixa, 2=Média, 3=Alta
}

-- Variáveis Globais do Script
getgenv().SilentTarget = nil
getgenv().FOVCircle = Drawing.new("Circle")
getgenv().FOVCircle.Thickness = 1
getgenv().FOVCircle.NumSides = 100
getgenv().FOVCircle.Radius = Settings.SilentAim.FOV
getgenv().FOVCircle.Color = Settings.SilentAim.FOVColor
getgenv().FOVCircle.Filled = false
getgenv().FOVCircle.Visible = Settings.SilentAim.ShowFOV
getgenv().FOVCircle.Transparency = 0.7

-- Cache para ESP
local espCache = {}
local playerESP = {}

-- ============================================= --
--            BOTÃO FLUTUANTE                   --
-- ============================================= --

-- Criar botão flutuante usando ScreenGui (mais compatível que Drawing para clique)
local function createFloatingButton()
    -- Verifica se já existe para não duplicar
    if getgenv().FloatingButton then
        pcall(function() getgenv().FloatingButton:Destroy() end)
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MareHubFloatingButton"
    screenGui.Parent = game.CoreGui
    
    local button = Instance.new("ImageButton")
    button.Name = "MainButton"
    button.Parent = screenGui
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    button.BackgroundTransparency = 0.2
    button.BorderColor3 = Color3.fromRGB(0, 0, 0)
    button.BorderSizePixel = 0
    button.Position = UDim2.new(0, 50, 0, 400)
    button.Size = UDim2.new(0, 50, 0, 50)
    button.Draggable = true
    button.Image = "rbxasset://textures/ui/Controls/icon_off.png" -- Ícone padrão
    
    -- Arredondar bordas
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Sombra
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Parent = button
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.Position = UDim2.new(0, -2, 0, -2)
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.ZIndex = 0
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 10)
    shadowCorner.Parent = shadow
     -- Texto de status
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Parent = button
    statusText.BackgroundTransparency = 1
    statusText.Position = UDim2.new(0, 0, 0, 60)
    statusText.Size = UDim2.new(1, 0, 0, 20)
    statusText.Font = Enum.Font.GothamBold
    statusText.Text = "HUB OFF"
    statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusText.TextScaled = true
    statusText.TextStrokeTransparency = 0.5
    
    -- Função para alternar hub
    local hubActive = false
    button.MouseButton1Click:Connect(function()
        hubActive = not hubActive
        Library:ToggleUI()
        
        if hubActive then
            button.Image = "rbxasset://textures/ui/Controls/icon_on.png"
            statusText.Text = "HUB ON"
            statusText.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            button.Image = "rbxasset://textures/ui/Controls/icon_off.png"
            statusText.Text = "HUB OFF"
            statusText.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end)
    
    -- Menu flutuante ao segurar botão direito
    local menuFrame = Instance.new("Frame")
    menuFrame.Name = "MenuFrame"
    menuFrame.Parent = button
    menuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    menuFrame.BackgroundTransparency = 0.1
    menuFrame.Position = UDim2.new(0, 60, 0, 0)
    menuFrame.Size = UDim2.new(0, 150, 0, 80)
    menuFrame.Visible = false
    menuFrame.ZIndex = 10
    
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 6)
    menuCorner.Parent = menuFrame
    
    -- Botão Destroy no menu flutuante
    local destroyBtn = Instance.new("TextButton")
    destroyBtn.Parent = menuFrame
    destroyBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    destroyBtn.BackgroundTransparency = 0.3
    destroyBtn.Position = UDim2.new(0, 10, 0, 10)
    destroyBtn.Size = UDim2.new(0, 130, 0, 25)
    destroyBtn.Font = Enum.Font.GothamBold
    destroyBtn.Text = "DESTROY"
    destroyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    destroyBtn.TextScaled = true
    
    local destroyCorner = Instance.new("UICorner")
    destroyCorner.CornerRadius = UDim.new(0, 4)
    destroyCorner.Parent = destroyBtn
    
    destroyBtn.MouseButton1Click:Connect(function()
        -- Destroy tudo
        for _, v in pairs(playerESP) do
            for _, d in pairs(v) do
                pcall(function() d:Remove() end)
            end
        end
        pcall(function() FOVCircle:Remove() end)
        pcall(function() Library:Destroy() end)
        pcall(function() screenGui:Destroy() end)
        getgenv().Settings = nil
        script:Destroy()
    end)
   -- Botão Reset no menu flutuante
    local resetBtn = Instance.new("TextButton")
    resetBtn.Parent = menuFrame
    resetBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
    resetBtn.BackgroundTransparency = 0.3
    resetBtn.Position = UDim2.new(0, 10, 0, 45)
    resetBtn.Size = UDim2.new(0, 130, 0, 25)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.Text = "RESET GUI"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.TextScaled = true
    
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 4)
    resetCorner.Parent = resetBtn
    
    resetBtn.MouseButton1Click:Connect(function()
        Library:Destroy()
        wait(0.1)
        Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
        Window = Library.CreateLib("[TNM] Maré Hub - Universal", "DarkTheme")
        setupGUI() -- Recriar GUI
        if hubActive then
            Library:ToggleUI()
        end
    end)
    
    -- Abrir/fechar menu ao passar o mouse
    button.MouseEnter:Connect(function()
        menuFrame.Visible = true
    end)
    
    button.MouseLeave:Connect(function()
        wait(0.5)
        if not menuFrame:IsMouseOver() and not button:IsMouseOver() then
            menuFrame.Visible = false
        end
    end)
    
    menuFrame.MouseLeave:Connect(function()
        wait(0.5)
        if not menuFrame:IsMouseOver() and not button:IsMouseOver() then
            menuFrame.Visible = false
        end
    end)
    
    getgenv().FloatingButton = screenGui
    return screenGui
end

-- Função helper para verificar se mouse está sobre objeto
function Instance:IsMouseOver()
    local mouse = game.Players.LocalPlayer:GetMouse()
    local absPos, absSize = self.AbsolutePosition, self.AbsoluteSize
    return mouse.X >= absPos.X and mouse.X <= absPos.X + absSize.X and
           mouse.Y >= absPos.Y and mouse.Y <= absPos.Y + absSize.Y
end

-- Criar botão flutuante imediatamente
createFloatingButton()
-- ============================================= --
--            FUNÇÕES DE FPS BOOST              --
-- ============================================= --

-- Aplicar configurações de FPS Boost
local function applyFPSBoost()
    local lighting = game:GetService("Lighting")
    local workspace = game:GetService("Workspace")
    
    if Settings.FPSBoost.Enabled then
        -- Qualidade gráfica
        if Settings.FPSBoost.Quality == 1 then -- Baixa
            settings().Rendering.QualityLevel = 1
            lighting.GlobalShadows = false
            lighting.FogEnd = 100
            workspace.DescendantAdded:Connect(function(descendant)
                if descendant:IsA("BasePart") or descendant:IsA("Decal") or descendant:IsA("Texture") then
                    task.spawn(function()
                        descendant.Material = Enum.Material.Plastic
                        if descendant:IsA("Decal") or descendant:IsA("Texture") then
                            descendant.Transparency = 1
                        end
                    end)
                end
            end)
            
            -- Remover texturas existentes
            for _, descendant in pairs(workspace:GetDescendants()) do
                if descendant:IsA("Decal") or descendant:IsA("Texture") then
                    descendant.Transparency = 1
                end
                if descendant:IsA("BasePart") then
                    descendant.Material = Enum.Material.Plastic
                end
            end
            
        elseif Settings.FPSBoost.Quality == 2 then -- Média
            settings().Rendering.QualityLevel = 3
            lighting.GlobalShadows = false
            lighting.FogEnd = 500
            
        elseif Settings.FPSBoost.Quality == 3 then -- Alta (padrão)
            settings().Rendering.QualityLevel = 10
            lighting.GlobalShadows = true
            lighting.FogEnd = 10000
        end
        
        -- Configurações adicionais
        lighting.Brightness = Settings.FPSBoost.Quality == 1 and 1.5 or 1
        lighting.Outlines = not Settings.FPSBoost.Effects
        
        -- Reduzir partículas
        if Settings.FPSBoost.Effects then
            for _, descendant in pairs(workspace:GetDescendants()) do
                if descendant:IsA("ParticleEmitter") or descendant:IsA("Smoke") or descendant:IsA("Fire") then
                    descendant.Enabled = false
                end
                if descendant:IsA("BloomEffect") or descendant:IsA("BlurEffect") or descendant:IsA("ColorCorrectionEffect") then
                    descendant.Enabled = false
                end
            end
        end
        
    else
        -- Restaurar configurações padrão
        settings().Rendering.QualityLevel = 10
        lighting.GlobalShadows = true
        lighting.FogEnd = 10000
        lighting.Brightness = 1
        lighting.Outlines = true
        
        -- Reativar partículas (pode não restaurar completamente)
        for _, descendant in pairs(workspace:GetDescendants()) do
            if descendant:IsA("Decal") or descendant:IsA("Texture") then
                descendant.Transparency = 0
            end
            if descendant:IsA("BasePart") then
                descendant.Material = descendant.Material == Enum.Material.Plastic and descendant.Material or descendant.Material
            end
            if descendant:IsA("ParticleEmitter") or descendant:IsA("Smoke") or descendant:IsA("Fire") then
                descendant.Enabled = true
            end
        end
    end
end

-- ============================================= --
--                FUNÇÕES PRINCIPAIS              --
-- ============================================= --

-- Função para encontrar remotos de tiro/dano (bypass básico)
local function findRemotes()
    local remotes = {}
    for _, v in pairs(getgc(true)) do
        if type(v) == "function" then
            local info = debug.getinfo(v)
            if info and info.name then
                if info.name:find("Fire") or info.name:find("Shoot") or info.name:find("Damage") then
                    local constants = debug.getconstants(v)
                    for _, const in pairs(constants) do
                        if type(const) == "string" and (const:find("Remote") or const:find("Event")) then
                            table.insert(remotes, const)
                        end
                    end
                end
            end
        end
    end
    return remotes
end
-- 1. ESP com Drawing (Wallhack)
local function CreateESP(player)
    local esp = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        Weapon = Drawing.new("Text"),
        Tracer = Drawing.new("Line")
    }
    
    esp.Box.Thickness = 1
    esp.Box.Filled = false
    esp.Box.Color = Color3.fromRGB(255, 255, 255)
    
    esp.Name.Size = 14
    esp.Name.Center = true
    esp.Name.Outline = true
    
    esp.Distance.Size = 12
    esp.Distance.Center = true
    esp.Distance.Outline = true
    
    esp.Health.Size = 12
    esp.Health.Center = true
    esp.Health.Outline = true
    
    esp.Weapon.Size = 12
    esp.Weapon.Center = true
    esp.Weapon.Outline = true
    
    esp.Tracer.Thickness = 1
    esp.Tracer.Color = Color3.fromRGB(255, 0, 0)
    
    return esp
end

-- Atualizar ESP a cada frame
RunService.Heartbeat:Connect(function()
    -- ESP
    if Settings.ESP.Enabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local char = p.Character
                local root = char.HumanoidRootPart
                local hum = char.Humanoid
                local head = char:FindFirstChild("Head")
                local pos, onScreen = camera:WorldToViewportPoint(root.Position)
                
                if onScreen then
                    if not playerESP[p] then
                        playerESP[p] = CreateESP(p)
                    end
                    
                    local esp = playerESP[p]
                    local scale = 1 / (pos.Z * 0.1) or 1
                    local boxSize = Vector2.new(2000 * scale, 2500 * scale)
                    local boxPos = Vector2.new(pos.X - boxSize.X/2, pos.Y - boxSize.Y/2)
                    
                    -- Box
                    if Settings.ESP.Box then
                        esp.Box.Position = boxPos
                        esp.Box.Size = boxSize
                        esp.Box.Color = p.TeamColor == player.TeamColor and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                        esp.Box.Visible = true
                    else
                        esp.Box.Visible = false
                    end
                    
                    -- Nome
                    if Settings.ESP.Name then
                        esp.Name.Position = Vector2.new(pos.X, boxPos.Y - 20)
                        esp.Name.Text = p.Name
                        esp.Name.Color = p.TeamColor == player.TeamColor and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end
                    
                    -- Distância
                    if Settings.ESP.Distance then
                        local dist = (player.Character.HumanoidRootPart.Position - root.Position).Magnitude
                        esp.Distance.Position = Vector2.new(pos.X, boxPos.Y + boxSize.Y + 5)
                        esp.Distance.Text = math.floor(dist) .. " studs"
                        esp.Distance.Color = Color3.fromRGB(255, 255, 255)
                        esp.Distance.Visible = true
                    else
                        esp.Distance.Visible = false
                    end
                    
                    -- Vida
                    if Settings.ESP.Health then
                        esp.Health.Position = Vector2.new(pos.X, boxPos.Y + boxSize.Y + 20)
                        esp.Health.Text = "HP: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                        esp.Health.Color = Color3.fromRGB(0, 255, 0)
                        esp.Health.Visible = true
                    else
                        esp.Health.Visible = false
                    end
                    
                    -- Arma (procura ferramenta na mão)
                    if Settings.ESP.Weapon then
                        local tool = char:FindFirstChildOfClass("Tool")
                        esp.Weapon.Position = Vector2.new(pos.X, boxPos.Y + boxSize.Y + 35)
                        esp.Weapon.Text = tool and tool.Name or "Nenhuma"
                        esp.Weapon.Color = Color3.fromRGB(255, 255, 0)
                        esp.Weapon.Visible = true
                    else
                        esp.Weapon.Visible = false
                    end
                    
                    -- Tracer
                    if Settings.ESP.Tracer then
                        esp.Tracer.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                        esp.Tracer.Color = p.TeamColor == player.TeamColor and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                        esp.Tracer.Visible = true
                    else
                        esp.Tracer.Visible = false
                    end
                else
                    if playerESP[p] then
                        for _, v in pairs(playerESP[p]) do
                            if v.Visible then v.Visible = false end
                        end
                    end
                end
            end
        end
    else
        for _, esp in pairs(playerESP) do
            for _, v in pairs(esp) do
                if v.Visible then v.Visible = false end
            end
        end
    end
    
    -- 2. Silent Aim (Aimbot Silencioso)
    if Settings.SilentAim.Enabled then
        FOVCircle.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        FOVCircle.Radius = Settings.SilentAim.FOV
        FOVCircle.Color = Settings.SilentAim.FOVColor
        FOVCircle.Visible = Settings.SilentAim.ShowFOV
        
        local closest = nil
        local shortest = math.huge
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                if p.Team ~= player.Team then
                    local head = p.Character:FindFirstChild("Head")
                    if head then
                        local headPos, onScreen = camera:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local dist = (Vector2.new(headPos.X, headPos.Y) - Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)).Magnitude
                            if dist < shortest and dist < Settings.SilentAim.FOV then
                                shortest = dist
                                closest = p
                            end
                        end
                    end
                end
            end
        end
        
        getgenv().SilentTarget = closest
    else
        FOVCircle.Visible = false
        getgenv().SilentTarget = nil
    end
        -- 3. God Mode (Invencível)
    if Settings.GodMode and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.MaxHealth = math.huge
        player.Character.Humanoid.Health = math.huge
    end
    
    -- 4. Munição Infinita
    if Settings.InfAmmo and player.Character then
        local tool = player.Character:FindFirstChildOfClass("Tool")
        if tool then
            local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("CurrentAmmo") or tool:FindFirstChild("AmmoCount")
            if ammo then
                ammo.Value = ammo.MaxValue or 999
            end
        end
    end
    
    -- 5. Speed Hack
    if Settings.Speed.Enabled and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = Settings.Speed.Walk
        player.Character.Humanoid.JumpPower = Settings.Speed.Jump
    else
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = 16
            player.Character.Humanoid.JumpPower = 50
        end
    end
    
    -- 6. Noclip
    if Settings.Noclip and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- 7. Kill All (Teleporte + One Shot)
    if Settings.KillAll and player.Character then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Team ~= player.Team then
                player.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame
                wait(0.1)
                p.Character.Humanoid.Health = 0
            end
        end
        Settings.KillAll = false
    end
    
    -- 8. Anti-Aim / Spinbot
    if Settings.AntiAim.Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(tick() * Settings.AntiAim.YawSpeed), 0)
    end
end)
-- 9. No Recoil/Spread (Hook de funções de tiro)
local function hookShoot()
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if key == "Recoil" or key == "Spread" or key == "CameraShake" or key == "BulletSpread" then
            if Settings.NoRecoil then
                return 0
            end
        end
        return oldIndex(self, key)
    end)
end

pcall(hookShoot)

-- 10. Fullbright + No Fog
local function setFullbright()
    local lighting = game:GetService("Lighting")
    if Settings.Fullbright then
        lighting.Ambient = Color3.fromRGB(255, 255, 255)
        lighting.Brightness = 2
        lighting.FogEnd = 100000
        lighting.GlobalShadows = false
    else
        lighting.Ambient = Color3.fromRGB(0, 0, 0)
        lighting.Brightness = 1
        lighting.FogEnd = 10000
        lighting.GlobalShadows = true
    end
end

-- Silent Aim Hook (Câmera)
local __namecall
__namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if Settings.SilentAim.Enabled and getgenv().SilentTarget and method == "FireServer" then
        local remoteName = tostring(self)
        local remotesList = findRemotes()
        
        for _, remote in pairs(remotesList) do
            if remoteName:find(remote) then
                if getgenv().SilentTarget and getgenv().SilentTarget.Character and getgenv().SilentTarget.Character:FindFirstChild("Head") then
                    args[2] = getgenv().SilentTarget.Character.Head.Position
                    args[3] = getgenv().SilentTarget.Character.Head.Position
                    return __namecall(self, unpack(args))
                end
            end
        end
    end
    
    return __namecall(self, ...)
end)

-- ============================================= --
--                INTERFACE GRÁFICA              --
-- ============================================= --

function setupGUI()
    -- Aba: Aimbot
    local aimTab = Window:NewTab("Aimbot")
    local aimSection = aimTab:NewSection("Silent Aim")
    aimSection:NewToggle("Ativar Silent Aim", "Mira automática na cabeça", function(state) Settings.SilentAim.Enabled = state end)
    aimSection:NewSlider("FOV", "Alcance da mira", 500, 10, function(value) Settings.SilentAim.FOV = value FOVCircle.Radius = value end)
    aimSection:NewSlider("Suavização", "Menos suave = mais rápido", 1, 0, function(value) Settings.SilentAim.Smooth = value end)
    aimSection:NewSlider("Predição", "Prever movimento", 0.5, 0, function(value) Settings.SilentAim.Prediction = value end)
    aimSection:NewToggle("Mostrar FOV", "Desenha círculo do FOV", function(state) Settings.SilentAim.ShowFOV = state end)
      -- Aba: ESP
    local espTab = Window:NewTab("Visual")
    local espSection = espTab:NewSection("ESP / Wallhack")
    espSection:NewToggle("Ativar ESP", "Mostra jogadores através de paredes", function(state) Settings.ESP.Enabled = state end)
    espSection:NewToggle("Box 2D", "Caixa ao redor do jogador", function(state) Settings.ESP.Box = state end)
    espSection:NewToggle("Tracers", "Linha do centro da tela", function(state) Settings.ESP.Tracer = state end)
    espSection:NewToggle("Nome", "Mostra nome do jogador", function(state) Settings.ESP.Name = state end)
    espSection:NewToggle("Distância", "Mostra distância", function(state) Settings.ESP.Distance = state end)
    espSection:NewToggle("Vida", "Barra de vida", function(state) Settings.ESP.Health = state end)
    espSection:NewToggle("Arma", "Arma atual", function(state) Settings.ESP.Weapon = state end)

    local visualTab = espTab
    local visualSection = visualTab:NewSection("Efeitos")
    visualSection:NewToggle("Fullbright", "Clareia tudo, remove neblina", function(state) Settings.Fullbright = state setFullbright() end)

    -- NOVA ABA: FPS BOOST
    local fpsTab = Window:NewTab("FPS Boost")
    local fpsSection = fpsTab:NewSection("Otimização de Performance")
    fpsSection:NewToggle("Ativar FPS Boost", "Reduz gráficos para aumentar FPS", function(state) 
        Settings.FPSBoost.Enabled = state 
        applyFPSBoost()
    end)
    
    local qualitySection = fpsTab:NewSection("Qualidade Gráfica")
    qualitySection:NewDropdown("Nível Gráfico", "Selecione a qualidade", {"Baixa (Máx FPS)", "Média", "Alta (Padrão)"}, function(value)
        if value == "Baixa (Máx FPS)" then
            Settings.FPSBoost.Quality = 1
        elseif value == "Média" then
            Settings.FPSBoost.Quality = 2
        elseif value == "Alta (Padrão)" then
            Settings.FPSBoost.Quality = 3
        end
        if Settings.FPSBoost.Enabled then
            applyFPSBoost()
        end
    end)
    
    local optimizeSection = fpsTab:NewSection("Configurações Extras")
    optimizeSection:NewToggle("Desativar Sombras", "Remove sombras globais", function(state)
        Settings.FPSBoost.Shadows = state
        game:GetService("Lighting").GlobalShadows = not state
    end)
    
    optimizeSection:NewToggle("Desativar Texturas", "Remove decalques e texturas", function(state)
        Settings.FPSBoost.Textures = state
        applyFPSBoost()
    end)
    
    optimizeSection:NewToggle("Desativar Efeitos", "Remove partículas e efeitos visuais", function(state)
        Settings.FPSBoost.Effects = state
        applyFPSBoost()
    end)
    
    -- Informações de FPS
    local fpsInfoSection = fpsTab:NewSection("Monitor")
    local fpsLabel = fpsInfoSection:NewLabel("FPS: Aguardando...")
     -- Monitor de FPS simples
    local frameCount = 0
    local lastTime = tick()
    spawn(function()
        while wait(0.5) do
            if fpsLabel and fpsLabel.Update then
                local currentTime = tick()
                local fps = math.floor(frameCount / (currentTime - lastTime))
                fpsLabel:UpdateText("FPS: " .. fps)
                frameCount = 0
                lastTime = currentTime
            end
        end
    end)
    
    RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
    end)

    -- Aba: Player
    local playerTab = Window:NewTab("Player")
    local playerSection = playerTab:NewSection("Hacks de Jogador")
    playerSection:NewToggle("God Mode", "Invencível", function(state) Settings.GodMode = state end)
    playerSection:NewToggle("Munição Infinita", "Sem recarregar", function(state) Settings.InfAmmo = state end)
    playerSection:NewToggle("No Recoil/Spread", "Tiros 100% precisos", function(state) Settings.NoRecoil = state end)

    local speedSection = playerTab:NewSection("Speed Hack")
    speedSection:NewToggle("Ativar Speed", "Aumenta velocidade", function(state) Settings.Speed.Enabled = state end)
    speedSection:NewSlider("Walk Speed", "Velocidade andando", 150, 16, function(value) Settings.Speed.Walk = value end)
    speedSection:NewSlider("Jump Power", "Altura do pulo", 200, 50, function(value) Settings.Speed.Jump = value end)

    playerSection:NewToggle("Noclip", "Atravessa paredes", function(state) Settings.Noclip = state end)

    -- Aba: Exploits
    local exploitTab = Window:NewTab("Exploits")
    local exploitSection = exploitTab:NewSection("Ataques")
    exploitSection:NewButton("Kill All", "Mata todos os inimigos", function() Settings.KillAll = true end)

    local aaSection = exploitTab:NewSection("Anti-Aim")
    aaSection:NewToggle("Spinbot", "Gira sem parar", function(state) Settings.AntiAim.Enabled = state end)
    aaSection:NewSlider("Velocidade da rotação", "Quão rápido gira", 50, 1, function(value) Settings.AntiAim.YawSpeed = value end)
end

-- Inicializar GUI
setupGUI()
-- ============================================= --
--                 KEYBINDS                     --
-- ============================================= --

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        Library:ToggleUI()
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        -- Destroy via tecla
        for _, v in pairs(playerESP) do
            for _, d in pairs(v) do
                pcall(function() d:Remove() end)
            end
        end
        pcall(function() FOVCircle:Remove() end)
        pcall(function() Library:Destroy() end)
        if getgenv().FloatingButton then
            pcall(function() getgenv().FloatingButton:Destroy() end)
        end
        getgenv().Settings = nil
        script:Destroy()
    end
end)

-- Mensagem de boas-vindas
print("✅ [TNM] Maré Hub carregado! Pressione INSERT para abrir/fechar o menu.")
print("✅ Botão flutuante adicionado! Clique nele para ligar/desligar o menu.")

-- Instruções no Chat
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Maré Hub",
    Text = "Carregado! Botão flutuante na tela | INSERT = Menu | RightShift = Destroy",
    Duration = 8
})
```

    
