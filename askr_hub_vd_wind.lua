--========================================
-- ASKURI HUB | Violence District
-- Wind UI Version
--========================================

-- LOAD WIND UI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- SERVICES
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

--========================================
-- STATE VARIABLES
--========================================
-- Generator ESP
local GeneratorESPEnabled = false
local GeneratorESPObjects = {}

-- Generator Progress Labels
local GeneratorProgressEnabled = false
local GeneratorLabels = {}

-- Generator Counter HUD
local GeneratorCounterEnabled = false
local GeneratorCounterGUI = nil
local GeneratorCounterLoop = nil

-- Speed Modifier
local SpeedEnabled = false
local SpeedMultiplier = 1

-- Player ESP
local KillerESPEnabled = false
local SurvivorESPEnabled = false
local PlayerESPObjects = {}

-- Gift ESP
local GiftESPEnabled = false
local GiftESPObjects = {}

-- Tree ESP
local TreeESPEnabled = false
local TreeESPObjects = {}

-- Gift Labels
local GiftLabelsEnabled = false
local GiftLabels = {}

-- Tree Labels
local TreeLabelsEnabled = false
local TreeLabels = {}

-- Exit Gate ESP
local ExitGateESPEnabled = false
local ExitGateESPObjects = {}

-- Exit Gate Labels
local ExitGateLabelsEnabled = false
local ExitGateLabels = {}

local AutoSkillCheckEnabled = false
local AutoSkillCheckConnection = nil

-- Auto Generator
local AutoGeneratorEnabled = false
local AutoGeneratorConnection = nil
local KillerSafeRadius = 60
local CurrentTargetGenerator = nil
local IsTeleportingToSafe = false
local IsRepairing = false

--========================================
-- SHARED CONFIG
--========================================
local MAP_NAME = "Map"
local GENERATOR_NAME = "Generator"
local GENERATOR_COLOR = Color3.fromRGB(255, 210, 60)
local FILL_TRANSPARENCY = 0.35
local GIFT_COLOR = Color3.fromRGB(0, 255, 128)
local GIFT_NAME = "Gift"
local TREE_COLOR = Color3.fromRGB(0, 100, 0)
local TREE_NAME = "ChristmasTree"
local EXIT_NAME = "Gate"
local EXIT_COLOR = Color3.fromRGB(0, 255, 255)
local EXIT_LABEL_COLOR = Color3.fromRGB(255, 255, 255)
local ESP_COLORS = {
    Killer = Color3.fromRGB(255, 60, 60),
    Survivor = Color3.fromRGB(80, 170, 255),
}
local BASE_WALKSPEED = 16
local MAX_WALKSPEED = 65
local TARGET_GENERATORS = 5

--========================================
-- CORE FUNCTIONS (COPIED FROM LUNA VERSION)
--========================================

-- GENERATOR ESP
local function genESP_getMap()
    return Workspace:FindFirstChild(MAP_NAME)
end

local function genESP_getGenerators()
    local gens = {}
    local map = genESP_getMap()
    if not map then return gens end
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == GENERATOR_NAME then
            table.insert(gens, obj)
        end
    end
    return gens
end

local function genESP_isGeneratorCompleted(gen)
    local progress = gen:GetAttribute("RepairProgress")
    return typeof(progress) == "number" and progress >= 100
end

local function genESP_addGeneratorESP(gen)
    if GeneratorESPObjects[gen] then return end
    if genESP_isGeneratorCompleted(gen) then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "VD_GeneratorESP"
    highlight.Adornee = gen
    highlight.FillColor = GENERATOR_COLOR
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = FILL_TRANSPARENCY
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = gen
    GeneratorESPObjects[gen] = highlight
end

local function genESP_removeAllGeneratorESP()
    for _, h in pairs(GeneratorESPObjects) do
        if h then h:Destroy() end
    end
    table.clear(GeneratorESPObjects)
end

local function genESP_hookGeneratorProgress(gen)
    gen:GetAttributeChangedSignal("RepairProgress"):Connect(function()
        local progress = gen:GetAttribute("RepairProgress")
        if typeof(progress) == "number" and progress >= 100 then
            local esp = GeneratorESPObjects[gen]
            if esp then
                esp:Destroy()
                GeneratorESPObjects[gen] = nil
            end
        end
    end)
end

local function genESP_setupMapListeners(map)
    if not map then return end
    map.DescendantAdded:Connect(function(descendant)
        if not GeneratorESPEnabled then return end
        if descendant:IsA("Model") and descendant.Name == GENERATOR_NAME then
            task.wait(0.1)
            genESP_addGeneratorESP(descendant)
            genESP_hookGeneratorProgress(descendant)
        end
    end)
end

local function genESP_applyESPToMap()
    local map = genESP_getMap()
    if not map then return end
    local generators = genESP_getGenerators()
    for _, gen in ipairs(generators) do
        genESP_addGeneratorESP(gen)
        genESP_hookGeneratorProgress(gen)
    end
end

-- GENERATOR LABELS
local function genLabel_getProgressColor(percent)
    if percent >= 67 then return Color3.fromRGB(80, 200, 120)
    elseif percent >= 34 then return Color3.fromRGB(255, 200, 80)
    else return Color3.fromRGB(255, 90, 90) end
end

local function genLabel_getGeneratorAdornee(gen)
    if gen.PrimaryPart then return gen.PrimaryPart end
    for _, obj in ipairs(gen:GetDescendants()) do
        if obj:IsA("BasePart") then return obj end
    end
    return nil
end

local function genLabel_createGeneratorLabel(gen)
    if GeneratorLabels[gen] then return end
    local adornee = genLabel_getGeneratorAdornee(gen)
    if not adornee then return end
    local gui = Instance.new("BillboardGui")
    gui.Name = "VD_GeneratorProgress"
    gui.Adornee = adornee
    gui.Size = UDim2.new(0, 140, 0, 50)
    gui.StudsOffset = Vector3.new(0, 4, 0)
    gui.AlwaysOnTop = true
    gui.Parent = adornee.Parent
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.5, 0)
    title.BackgroundTransparency = 1
    title.Text = "GENERATOR"
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.TextColor3 = Color3.new(1,1,1)
    title.TextStrokeTransparency = 0
    title.Parent = gui
    local percent = Instance.new("TextLabel")
    percent.Name = "Percent"
    percent.Position = UDim2.new(0, 0, 0.5, 0)
    percent.Size = UDim2.new(1, 0, 0.5, 0)
    percent.BackgroundTransparency = 1
    percent.Font = Enum.Font.GothamBold
    percent.TextScaled = true
    percent.TextStrokeTransparency = 0
    percent.Parent = gui
    GeneratorLabels[gen] = gui
end

local function genLabel_hookGeneratorProgress(gen)
    genLabel_createGeneratorLabel(gen)
    local function update()
        local progress = gen:GetAttribute("RepairProgress")
        if typeof(progress) ~= "number" then return end
        if progress >= 100 then
            if GeneratorLabels[gen] then
                GeneratorLabels[gen]:Destroy()
                GeneratorLabels[gen] = nil
            end
            return
        end
        local gui = GeneratorLabels[gen]
        if not gui then return end
        local label = gui:FindFirstChild("Percent")
        if label then
            local pVal = math.floor(progress)
            label.Text = pVal .. "%"
            label.TextColor3 = genLabel_getProgressColor(pVal)
        end
    end
    update()
    gen:GetAttributeChangedSignal("RepairProgress"):Connect(update)
end

local function genLabel_removeAllLabels()
    for _, gui in pairs(GeneratorLabels) do
        if gui then gui:Destroy() end
    end
    table.clear(GeneratorLabels)
end

local function genLabel_setupMapListeners(map)
    if not map then return end
    map.DescendantAdded:Connect(function(descendant)
        if not GeneratorProgressEnabled then return end
        if descendant:IsA("Model") and descendant.Name == GENERATOR_NAME then
            task.wait(0.1)
            genLabel_hookGeneratorProgress(descendant)
        end
    end)
end

local function genLabel_applyLabelsToMap()
    local map = Workspace:FindFirstChild(MAP_NAME)
    if not map then return end
    local generators = genESP_getGenerators()
    for _, gen in ipairs(generators) do
        genLabel_hookGeneratorProgress(gen)
    end
end

-- PLAYER ESP
local function playerESP_isKiller(player)
    if not player then return false end
    local team = player.Team
    return team and team.Name == "Killer"
end

local function playerESP_addESP(player, color)
    local char = player.Character
    if not char or PlayerESPObjects[char] then return end
    local h = Instance.new("Highlight")
    h.Name = "VD_PlayerESP"
    h.Adornee = char
    h.FillColor = color
    h.OutlineColor = Color3.new(1,1,1)
    h.FillTransparency = 0.45
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = char
    PlayerESPObjects[char] = h
end

local function playerESP_removeAllESP()
    for _, h in pairs(PlayerESPObjects) do
        if h then h:Destroy() end
    end
    table.clear(PlayerESPObjects)
end

local function playerESP_updatePlayer(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    local existingESP = PlayerESPObjects[player.Character]
    if existingESP then
        existingESP:Destroy()
        PlayerESPObjects[player.Character] = nil
    end
    local isKiller = playerESP_isKiller(player)
    if isKiller and KillerESPEnabled then
        playerESP_addESP(player, ESP_COLORS.Killer)
    elseif not isKiller and SurvivorESPEnabled then
        playerESP_addESP(player, ESP_COLORS.Survivor)
    end
end

RunService.Heartbeat:Connect(function()
    if not KillerESPEnabled and not SurvivorESPEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            playerESP_updatePlayer(p)
        end
    end
end)

-- GIFT/TREE ESP & LABELS
local function createGenericLabel(target, name, color, yOffset)
    local adornee = (target:IsA("Model") and (target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart"))) or (target:IsA("BasePart") and target)
    if not adornee then return nil end
    local gui = Instance.new("BillboardGui")
    gui.Name = "VD_Label_" .. name
    gui.Adornee = adornee
    gui.Size = UDim2.new(0, 100, 0, 40)
    gui.StudsOffset = Vector3.new(0, yOffset or 3, 0)
    gui.AlwaysOnTop = true
    gui.Parent = adornee.Parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.Parent = gui
    return gui
end

local function addObjectESP(obj, color, list)
    if list[obj] then return end
    local h = Instance.new("Highlight")
    h.Adornee = obj
    h.FillColor = color
    h.OutlineColor = Color3.new(1,1,1)
    h.FillTransparency = 0.5
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = obj
    list[obj] = h
end

local function applyObjectESP(name, color, list, enabled)
    if not enabled then return end
    local map = genESP_getMap()
    if not map then return end
    for _, o in ipairs(map:GetDescendants()) do
        if o:IsA("Model") and o.Name == name then addObjectESP(o, color, list) end
    end
end

local function applyObjectLabels(name, color, list, enabled, yOff)
    if not enabled then return end
    local map = genESP_getMap()
    if not map then return end
    for _, o in ipairs(map:GetDescendants()) do
        if o:IsA("Model") and o.Name == name then
            if not list[o] then list[o] = createGenericLabel(o, name:upper(), color, yOff) end
        end
    end
end

local function removeObjects(list)
    for _, o in pairs(list) do if o then o:Destroy() end end
    table.clear(list)
end

local function genCounter_countGenerators()
    local map = genESP_getMap()
    if not map then return 0 end
    local count = 0
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == GENERATOR_NAME then
            local progress = obj:GetAttribute("RepairProgress")
            if typeof(progress) == "number" and progress >= 99.9 then
                count = count + 1
            end
        end
    end
    return count
end

local function genCounter_countSurvivors()
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Team and p.Team.Name == "Survivors" then
            if p.Character then
                local humanoid = p.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    count = count + 1
                end
            end
        end
    end
    return count
end

local function genCounter_create()
    if GeneratorCounterGUI then return GeneratorCounterGUI end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VD_GeneratorCounterHUD"
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 220, 0, 50)
    MainFrame.Position = UDim2.new(0.5, -110, 0.05, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BackgroundTransparency = 0.2
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true -- Enable input handling
    MainFrame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(255, 210, 60)
    UIStroke.Thickness = 2
    UIStroke.Parent = MainFrame
    
    local CountLabel = Instance.new("TextLabel")
    CountLabel.Name = "CountLabel"
    CountLabel.Size = UDim2.new(1, 0, 1, 0) -- Full width
    CountLabel.Position = UDim2.new(0, 0, 0, 0)
    CountLabel.BackgroundTransparency = 1
    CountLabel.Font = Enum.Font.GothamBold
    CountLabel.Text = "Generators Left: 5"
    CountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    CountLabel.TextSize = 20
    CountLabel.TextXAlignment = Enum.TextXAlignment.Center -- Centered
    CountLabel.Parent = MainFrame

    -- Dragging Logic
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    GeneratorCounterGUI = ScreenGui
    return ScreenGui
end

local function genCounter_update()
    if not GeneratorCounterEnabled or not GeneratorCounterGUI then return end
    local mainFrame = GeneratorCounterGUI:FindFirstChild("MainFrame")
    local countLabel = mainFrame and mainFrame:FindFirstChild("CountLabel")
    if not countLabel then return end
    local completed = genCounter_countGenerators()
    local survivorsAlive = genCounter_countSurvivors()
    local left = (survivorsAlive == 1) and 0 or math.max(0, TARGET_GENERATORS - completed)
    countLabel.Text = (left == 0) and "EXIT GATES POWERED" or "Generators Left: " .. left
    if left == 0 then
        countLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
        mainFrame.UIStroke.Color = Color3.fromRGB(80, 255, 120)
    else
        countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        mainFrame.UIStroke.Color = Color3.fromRGB(255, 210, 60)
    end
end

-- AUTOMATION
local function qte_getUIElements()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local prompt = pg and pg:FindFirstChild("SkillCheckPromptGui")
    local frame = prompt and prompt:FindFirstChild("Check")
    if not frame then return nil end
    return { frame = frame, needle = frame:FindFirstChild("Line"), target = frame:FindFirstChild("Goal") }
end

local function qte_checkFrame()
    if not AutoSkillCheckEnabled then return end
    local ui = qte_getUIElements()
    if not ui or not ui.frame.Visible or not ui.needle or not ui.target then return end
    local needle = ui.needle.Rotation % 360
    local target = ui.target.Rotation % 360
    local sStart = (target + 104) % 360
    local sEnd = (target + 114) % 360
    local inZone = (sStart > sEnd and (needle >= sStart or needle <= sEnd)) or (needle >= sStart and needle <= sEnd)
    if inZone then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.defer(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
    end
end

local function autoGen_getKillerPosition()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team and p.Team.Name == "Killer" then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                return p.Character.HumanoidRootPart.Position
            end
        end
    end
    return nil
end

local function autoGen_getOpenSide(gen)
    local pivots = {
        CFrame.new(0, 0, -3.5), -- Front
        CFrame.new(0, 0, 3.5),  -- Back
        CFrame.new(-3.5, 0, 0), -- Left
        CFrame.new(3.5, 0, 0)   -- Right
    }
    local baseCFrame = gen.PrimaryPart and gen.PrimaryPart.CFrame or (gen:FindFirstChildWhichIsA("BasePart") and gen:FindFirstChildWhichIsA("BasePart").CFrame)
    if not baseCFrame then return nil end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, gen}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    for _, offset in ipairs(pivots) do
        local targetCF = baseCFrame * offset
        local rayResult = Workspace:Raycast(baseCFrame.Position, targetCF.Position - baseCFrame.Position, rayParams)
        if not rayResult then
            local occupied = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    if (p.Character.HumanoidRootPart.Position - targetCF.Position).Magnitude < 1.5 then occupied = true break end
                end
            end
            if not occupied then return targetCF end
        end
    end
    return nil
end

local function autoGen_teleportAndInteract(targetGen)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    if IsTeleportingToSafe then return end
    IsTeleportingToSafe = true
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local targetCFrame = autoGen_getOpenSide(targetGen)
    if targetCFrame then
        hrp.CFrame = targetCFrame * CFrame.new(0, 2, 0)
        task.wait(0.1)
        hrp.CFrame = targetCFrame
        task.wait(0.15)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        IsRepairing = true
    end
    IsTeleportingToSafe = false
end

local function autoGen_stopInteraction()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    IsRepairing = false
end

local function autoGen_update()
    if not AutoGeneratorEnabled then return end
    if IsTeleportingToSafe then return end
    
    local completedGens = genCounter_countGenerators()
    local survivorCount = genCounter_countSurvivors()
    
    if completedGens >= 5 or survivorCount == 1 then
        local map = genESP_getMap()
        local gate = map and (map:FindFirstChild("Gate") or map:FindFirstChild("ExitGate"))
        if not gate and map then
            for _, o in ipairs(map:GetChildren()) do if o.Name:find("Gate") or o.Name:find("Exit") then gate = o break end end
        end
        if gate and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local gatePart = gate.PrimaryPart or gate:FindFirstChildWhichIsA("BasePart")
            if gatePart then
                LocalPlayer.Character.HumanoidRootPart.CFrame = gatePart.CFrame * CFrame.new(0, 0, 25)
                AutoGeneratorEnabled = false
                autoGen_stopInteraction()
                WindUI:Notify({ Title = "ESCAPED!", Content = "Auto Escape Triggered. Auto Gen Disabled.", Duration = 5, Icon = "check" })
                return
            end
        end
    end

    local killerPos = autoGen_getKillerPosition()
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if killerPos and myHRP and (myHRP.Position - killerPos).Magnitude < KillerSafeRadius then
        autoGen_stopInteraction()
        local generators = genESP_getGenerators()
        local furthestGen, maxDist = nil, -1
        for _, gen in ipairs(generators) do
            local p = gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")
            if p then
                local d = (p.Position - killerPos).Magnitude
                if d > maxDist then maxDist = d furthestGen = gen end
            end
        end
        if furthestGen then CurrentTargetGenerator = furthestGen autoGen_teleportAndInteract(furthestGen) return end
    end

    if CurrentTargetGenerator and (CurrentTargetGenerator:GetAttribute("RepairProgress") or 0) >= 100 then
        CurrentTargetGenerator = nil
        autoGen_stopInteraction()
    end

    if not CurrentTargetGenerator then
        local generators = genESP_getGenerators()
        local bestGen, bestProg = nil, -1
        for _, gen in ipairs(generators) do
            local prog = gen:GetAttribute("RepairProgress") or 0
            if prog < 100 and autoGen_getOpenSide(gen) then
                if prog > bestProg then bestProg = prog bestGen = gen end
            end
        end
        if bestGen then CurrentTargetGenerator = bestGen autoGen_teleportAndInteract(bestGen) end
    elseif myHRP then
        local tPart = CurrentTargetGenerator.PrimaryPart or CurrentTargetGenerator:FindFirstChildWhichIsA("BasePart")
        if tPart and (myHRP.Position - tPart.Position).Magnitude > 5 then
            autoGen_teleportAndInteract(CurrentTargetGenerator)
        elseif not IsRepairing then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            IsRepairing = true
        end
    end
end

-- SPEED
local function speed_applySpeed()
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    if SpeedEnabled then
        local target = BASE_WALKSPEED + ((SpeedMultiplier - 1) / 99 * (MAX_WALKSPEED - BASE_WALKSPEED))
        humanoid.WalkSpeed = target
    else
        humanoid.WalkSpeed = 16
    end
end

-- EXIT GATES
local function getGateAdornee(gateModel)
    if gateModel.PrimaryPart then return gateModel.PrimaryPart end
    local part = gateModel:FindFirstChildWhichIsA("BasePart")
    if part then return part end
    local lever = gateModel:FindFirstChild("ExitLever")
    return lever and lever:FindFirstChild("Lever")
end

local function exit_applyToMap()
    local map = Workspace:FindFirstChild(MAP_NAME)
    if not map then return end
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == EXIT_NAME then
            if ExitGateESPEnabled then
                local h = Instance.new("Highlight")
                h.Adornee = obj
                h.FillColor = EXIT_COLOR
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = obj
                ExitGateESPObjects[obj] = h
            end
            if ExitGateLabelsEnabled then
                local adornee = getGateAdornee(obj)
                if adornee then
                    local gui = createGenericLabel(obj, "EXIT GATE", EXIT_LABEL_COLOR, 6)
                    ExitGateLabels[obj] = gui
                end
            end
        end
    end
end

-- MAP LISTENERS
Workspace.ChildRemoved:Connect(function(child)
    if child.Name == MAP_NAME then
        genESP_removeAllGeneratorESP()
        genLabel_removeAllLabels()
        -- ... clean up others
    end
end)

Workspace.ChildAdded:Connect(function(child)
    if child.Name == MAP_NAME then
        task.wait(1)
        if GeneratorESPEnabled then genESP_applyESPToMap() end
        if GeneratorProgressEnabled then genLabel_applyLabelsToMap() end
        if ExitGateESPEnabled or ExitGateLabelsEnabled then exit_applyToMap() end
        applyObjectESP(GIFT_NAME, GIFT_COLOR, GiftESPObjects, GiftESPEnabled)
        applyObjectLabels(GIFT_NAME, GIFT_COLOR, GiftLabels, GiftLabelsEnabled, 2.5)
        applyObjectESP(TREE_NAME, TREE_COLOR, TreeESPObjects, TreeESPEnabled)
        applyObjectLabels(TREE_NAME, TREE_COLOR, TreeLabels, TreeLabelsEnabled, 12)
    end
end)

-- ASSET SYSTEM (Professional GitHub Hosting)
local ASKR_FOLDER = "ASKR_HUB"
local LOGO_NAME = "askrlogo.png"
local LOGO_PATH = ASKR_FOLDER .. "/assets/" .. LOGO_NAME
-- Using the CORRECT RAW URL so Roblox can download the image data directly
local ASKR_LOGO_URL = "https://raw.githubusercontent.com/Netshh/askr-hub/main/askrlogo.png" 

if not isfolder(ASKR_FOLDER) then makefolder(ASKR_FOLDER) end
if not isfolder(ASKR_FOLDER .. "/assets") then makefolder(ASKR_FOLDER .. "/assets") end

-- Cleanup old broken files if any
if isfile(LOGO_PATH) and #readfile(LOGO_PATH) < 1000 then delfile(LOGO_PATH) end

local function downloadBranding()
    if isfile(LOGO_PATH) and #readfile(LOGO_PATH) > 1000 then return true end
    -- GitHub raw links are standard and safe for HttpGet
    local success, content = pcall(function() return game:HttpGet(ASKR_LOGO_URL) end)
    if success and #content > 1000 then
        writefile(LOGO_PATH, content)
        task.wait(0.5)
        return true
    end
    return false
end

downloadBranding()
local ASKR_ID = isfile(LOGO_PATH) and getcustomasset(LOGO_PATH) or "rbxassetid://15263660561"

--========================================
-- WIND UI SETUP
--========================================
local Window = WindUI:CreateWindow({
    Title = "ASKR HUB",
    Icon = ASKR_ID,
    Author = "By Haceng",
    Folder = "ASKR_HUB_VD",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    -- KEY SYSTEM (This is how you make money!)
    KeySystem = {
        Key = { "ASKR_PREMIUM_2026", "HACENG_WINS" }, -- Put your keys here
        Note = "Get the key from our Discord or Linkvertise!",
        URL = "https://link-to-your-monetized-key-page.com", -- Put your Linkvertise link here
        SaveKey = true -- Automatically saves the key on their PC
    },
    OpenButton = {
        Enabled = false
    }
})

Window.IsPC = false

local function createBrandingLogo()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ASKR_FloatingLogo"
    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if not ScreenGui.Parent then ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

    local LogoButton = Instance.new("ImageButton")
    LogoButton.Name = "Logo"
    LogoButton.Size = UDim2.new(0, 60, 0, 60)
    LogoButton.Position = UDim2.new(0, 50, 0.5, -30)
    LogoButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    LogoButton.BackgroundTransparency = 0.2
    LogoButton.Image = ASKR_ID -- Corrected to use the verified ID
    LogoButton.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(1, 0)
    Corner.Parent = LogoButton

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(180, 100, 255)
    Stroke.Thickness = 2
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Parent = LogoButton

    -- Dragging Logic
    local dragging, dragInput, dragStart, startPos
    LogoButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = LogoButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    LogoButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            LogoButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Hover & Click
    LogoButton.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(LogoButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 65, 0, 65)}):Play()
    end)
    LogoButton.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(LogoButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60)}):Play()
    end)
    LogoButton.MouseButton1Click:Connect(function()
        Window:Toggle()
    end)
end

createBrandingLogo()

-- HOME TAB
local HomeTab = Window:Tab({ Title = "Home", Icon = "house" })
local InfoSection = HomeTab:Section({ Title = "Information" })
InfoSection:Paragraph({ Title = "ASKURI HUB | Violence District", Desc = "Welcome to the premium script hub for Violence District." })
InfoSection:Paragraph({ Title = "Status", Desc = "Script is active and running on Wind UI." })

-- VISUAL TAB
local VisualTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
local ESPSection = VisualTab:Section({ Title = "ESP Features" })

ESPSection:Toggle({
    Title = "Killer ESP",
    Value = false,
    Callback = function(val)
        KillerESPEnabled = val
        if not val then playerESP_removeAllESP() end
    end
})

ESPSection:Toggle({
    Title = "Survivor ESP",
    Value = false,
    Callback = function(val)
        SurvivorESPEnabled = val
        if not val then playerESP_removeAllESP() end
    end
})

ESPSection:Toggle({
    Title = "Generator ESP",
    Value = false,
    Callback = function(val)
        GeneratorESPEnabled = val
        if val then genESP_applyESPToMap() else genESP_removeAllGeneratorESP() end
    end
})

ESPSection:Toggle({
    Title = "Generator Progress",
    Value = false,
    Callback = function(val)
        GeneratorProgressEnabled = val
        if val then genLabel_applyLabelsToMap() else genLabel_removeAllLabels() end
    end
})

ESPSection:Toggle({
    Title = "Exit Gate Features",
    Value = false,
    Callback = function(val)
        ExitGateESPEnabled = val
        ExitGateLabelsEnabled = val
        if val then exit_applyToMap() else
            removeObjects(ExitGateESPObjects)
            removeObjects(ExitGateLabels)
        end
    end
})

ESPSection:Toggle({
    Title = "Christmas Gift ESP",
    Value = false,
    Callback = function(val)
        GiftESPEnabled = val
        if val then applyObjectESP(GIFT_NAME, GIFT_COLOR, GiftESPObjects, true) else removeObjects(GiftESPObjects) end
    end
})

ESPSection:Toggle({
    Title = "Gift Labels",
    Value = false,
    Callback = function(val)
        GiftLabelsEnabled = val
        if val then applyObjectLabels(GIFT_NAME, GIFT_COLOR, GiftLabels, true, 2.5) else removeObjects(GiftLabels) end
    end
})

ESPSection:Toggle({
    Title = "Christmas Tree ESP",
    Value = false,
    Callback = function(val)
        TreeESPEnabled = val
        if val then applyObjectESP(TREE_NAME, TREE_COLOR, TreeESPObjects, true) else removeObjects(TreeESPObjects) end
    end
})

ESPSection:Toggle({
    Title = "Tree Labels",
    Value = false,
    Callback = function(val)
        TreeLabelsEnabled = val
        if val then applyObjectLabels(TREE_NAME, TREE_COLOR, TreeLabels, true, 12) else removeObjects(TreeLabels) end
    end
})

ESPSection:Toggle({
    Title = "Generator Counter HUD",
    Value = false,
    Callback = function(val)
        GeneratorCounterEnabled = val
        if val then
            genCounter_create()
            task.spawn(function()
                while GeneratorCounterEnabled do
                    genCounter_update()
                    task.wait(0.5)
                end
                if GeneratorCounterGUI then GeneratorCounterGUI:Destroy() GeneratorCounterGUI = nil end
            end)
        else
            if GeneratorCounterGUI then GeneratorCounterGUI:Destroy() GeneratorCounterGUI = nil end
        end
    end
})

-- AUTOMATION TAB
local AutoTab = Window:Tab({ Title = "Automation", Icon = "zap" })
local AutoSection = AutoTab:Section({ Title = "Gameplay" })

AutoSection:Toggle({
    Title = "Auto Perfect Skill Checks",
    Value = false,
    Callback = function(val)
        AutoSkillCheckEnabled = val
        if val then
            if not AutoSkillCheckConnection then
                AutoSkillCheckConnection = RunService.Heartbeat:Connect(qte_checkFrame)
            end
        else
            if AutoSkillCheckConnection then
                AutoSkillCheckConnection:Disconnect()
                AutoSkillCheckConnection = nil
            end
        end
    end
})

AutoSection:Toggle({
    Title = "Auto Generator (AFK)",
    Value = false,
    Callback = function(val)
        AutoGeneratorEnabled = val
        if val then
            if not AutoGeneratorConnection then
                AutoGeneratorConnection = RunService.Heartbeat:Connect(autoGen_update)
            end
        else
            if AutoGeneratorConnection then
                AutoGeneratorConnection:Disconnect()
                AutoGeneratorConnection = nil
            end
            autoGen_stopInteraction()
            CurrentTargetGenerator = nil
        end
    end
})

AutoSection:Slider({
    Title = "Safety Radius",
    Value = { Min = 30, Max = 150, Default = 60 },
    Callback = function(val) KillerSafeRadius = val end
})

-- MISC TAB
local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })
local SpeedSection = MiscTab:Section({ Title = "Movement" })

SpeedSection:Toggle({
    Title = "Enable Speed Multiplier",
    Value = false,
    Callback = function(val)
        SpeedEnabled = val
        speed_applySpeed()
    end
})

SpeedSection:Slider({
    Title = "Speed Intensity",
    Value = { Min = 1, Max = 100, Default = 1 },
    Callback = function(val)
        SpeedMultiplier = val
        speed_applySpeed()
    end
})

-- INITIALIZATION
WindUI:Notify({
    Title = "ASKURI HUB",
    Content = "Violence District loaded with Wind UI!",
    Duration = 5,
    Icon = "check"
})

print("[ASKURI HUB] Wind UI Version Initialized")
