


-- Its running too much backwards. And not even dodging anything at that time. It just runs. there is no logic for this.
-- It needs better logic in the dodging, and actually take use of safespots combined with the proactive dodging. It should also not just run backwards, but also sidestep and jump more intelligently.



-- // IMPORTS // --
local UILibrarySource = nil
if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile("copy/library.lua") then
    UILibrarySource = readfile("copy/library.lua")
else
    UILibrarySource = game:HttpGet("https://raw.githubusercontent.com/coder-isxt/roblox/refs/heads/main/library.lua")
end
local UILibrary = loadstring(UILibrarySource)()

-- // SERVICES // --
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Vim = game:GetService("VirtualInputManager")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // GLOBAL VARIABLES // --
local Window
local Tabs

-- // UI CREATION // --
if type(UILibrary.SetConfigStorage) == "function" then
    UILibrary:SetConfigStorage("FabledLegacyFarm", "settings.json")
end
Window = UILibrary:CreateWindow({Title="Fabled Legacy", IncludeCustomization = true})

Tabs = {
    Main = Window:CreateTab("Main"),
    Farming = Window:CreateTab("Farming"),
    Settings = Window:CreateTab("Settings"),
}

-- // NOTIFICATIONS AND PARAGRAPHS // --
UILibrary:Notify({
    Title = "Welcome " .. Player.DisplayName,
    Content = "Script Loaded!",
    Duration = 5
})

local function click_bind(KeyCode)
    Vim:SendKeyEvent(true, KeyCode, false, game)
    task.wait(0.05)
    Vim:SendKeyEvent(false, KeyCode, false, game)
end

-- // CONFIGURATION // --
local DodgeEnabled = false
local VisualsEnabled = false
local DodgeConnection = nil
local DodgeLoop = nil
local StartPosition = nil
local CurrentSafePoint = nil
local DodgeDebug = false
local DodgeCommittedThreats = {} 

local VALID_NAMES = {["part"] = true, ["mage"] = true, ["slash"] = true, ["hitbox"] = true, ["indicator"] = true}
local VALID_COLORS = {
    ["Faded green"] = true,
    ["Medium bluish green"] = true,
    ["Med. bluish green"] = true, 
    ["Bright red"] = true,
    ["Really red"] = true,
    ["Pastel blue-green"] = true,
    ["Medium stone grey"] = true,
    ["Tawny"] = true
}
local ActiveThreats = {}
local ActiveGunmechs = {}
local DODGE_LOGIC_INTERVAL = 1 / 45
local THREAT_PURGE_INTERVAL = 0.18
local PROACTIVE_LOOKAHEAD = 0.22
local FAR_LOOKAHEAD = 0.38


local function GetAttackDuration(part)
    local bColor = part.BrickColor.Name
    -- Fast attacks (red / tawny) are short
    if bColor == "Bright red" or bColor == "Really red" or bColor == "Tawny" then
        return 0.4
    end
    -- Longer parts (wide/long sweep actors) should be considered longer duration
    local maxDim = math.max(part.Size.Y, part.Size.Z)
    if maxDim > 14 then
        return 2.5
    end
    return 1.6
end

-- // TIMELINE-BASED SAFETY CHECK // --
local function IsSafeAtTime(position, arrivalDelay, ignoreList, threatList)
    local checkTime = os.clock() + arrivalDelay
    local source = threatList or ActiveThreats

    for key, data in pairs(source) do
        local part = data and data.Instance or key
        if ignoreList and ignoreList[part] then continue end
        if part and part.Parent then
            -- Use stored Impact/End windows if available, otherwise fall back
            local impact = data.ImpactTime or data.StartTime or 0
            local fin = data.EndTime or (data.StartTime and data.StartTime + 1.0) or (impact + 1.0)

            -- Optimization: Distance check before expensive CFrame math
            local center = part.Position
            if data.Velocity then
                local dt = math.clamp(arrivalDelay, 0, 0.45)
                center = center + (data.Velocity * dt)
            end
            local earlyRadius = (data.Radius or (part.Size.Magnitude / 2)) + 18
            if (center - position).Magnitude > earlyRadius then continue end

            if checkTime >= impact and checkTime <= fin then
                local cf = part.CFrame
                local offset = position - center
                local relX = math.abs(offset:Dot(cf.RightVector))
                local relY = math.abs(offset:Dot(cf.UpVector))
                local relZ = math.abs(offset:Dot(cf.LookVector))
                local extra = (data.IsLong and 8) or 4
                local size = part.Size / 2 + Vector3.new(extra + 2, extra + 2, extra + 2) -- Safety buffer + 2 magnitude check

                if relX < size.X and relZ < size.Z and relY < size.Y then
                    return false -- We will be inside the hitbox when it is active
                end
            end
        end
    end
    return true
end



-- // VISUALIZER // --
local function HighlightPart(part)
    if not VisualsEnabled then return end
    if not part or part:FindFirstChild("DodgeVisualizer") then return end
    local highlight = Instance.new("SelectionBox")
    highlight.Name = "DodgeVisualizer"
    highlight.Adornee = part
    highlight.Color3 = part.Color
    highlight.LineThickness = 0.1
    highlight.SurfaceTransparency = 0.7
    highlight.Parent = part
    task.delay(4, function() if highlight then highlight:Destroy() end end)
end

-- // CORE LOGIC // --
-- // ENHANCED THREAT CACHING // --
local function ProcessPart(descendant)
    if not DodgeEnabled or not descendant:IsA("BasePart") then return end
    
    local nameLower = descendant.Name:lower()
    local bColor = descendant.BrickColor.Name
    
    -- Filter using live metadata from your config
    if not VALID_NAMES[nameLower] or not VALID_COLORS[bColor] then return end
    if nameLower == "hitbox" and bColor == "Medium stone grey" then return end
    
    local model = descendant:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then return end

    if not ActiveThreats[descendant] then
        local conn = descendant.AncestryChanged:Connect(function(_, parent)
            if not parent then ActiveThreats[descendant] = nil end
        end)
        -- Only store the part and the moment it appeared
        local startT = os.clock()
        local duration = GetAttackDuration(descendant)
        local isLong = math.max(descendant.Size.Y, descendant.Size.Z) > 14 or nameLower:find("slash")
        local isBlue = (bColor == "Medium bluish green" or bColor == "Med. bluish green" or bColor == "Faded green" or bColor == "Pastel blue-green")

        ActiveThreats[descendant] = {
            Instance = descendant,
            StartTime = startT,
            ImpactTime = startT + 0.03, -- small reaction delay until the part becomes dangerous
            EndTime = startT + duration + (descendant.Size.Magnitude / 23),
            IsLong = isLong or isBlue,
            IsBlue = isBlue,
            LastPos = descendant.Position,
            Connection = conn,
            Radius = descendant.Size.Magnitude / 2 -- Cache radius for distance checks
        }
    end
    HighlightPart(descendant)
end


local function IsPathSafe(startPos, endPos, speed, ignoreList, threatList)
    local vector = endPos - startPos
    local dist = vector.Magnitude
    if dist < 1 then return true end
    
    local travelTime = dist / math.max(speed, 11)
    local stepSize = 4
    local steps = math.ceil(dist / stepSize)
    
    for i = 1, steps do
        local alpha = i / steps
        local checkPos = startPos:Lerp(endPos, alpha)
        local timeAtPoint = travelTime * alpha
        if not IsSafeAtTime(checkPos, timeAtPoint, ignoreList, threatList) then
            return false
        end
    end
    return true
end

-- // TOGGLE KEYBIND // --
Tabs.Main:CreateKeybind("Toggle Dodge", function()
    DodgeEnabled = not DodgeEnabled
    
    UILibrary:Notify({
        Title = "Auto Dodge System",
        Content = DodgeEnabled and "ENABLED - Scanning..." or "DISABLED",
        Duration = 3
    })

    if DodgeEnabled then
        for _, data in pairs(ActiveThreats) do data.Connection:Disconnect() end
        ActiveThreats = {}
        DodgeCommittedThreats = {} 
        local char = Player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            StartPosition = char.HumanoidRootPart.Position
        end
        
        DodgeConnection = workspace.DescendantAdded:Connect(ProcessPart)
        task.spawn(function()
            for _, desc in ipairs(workspace:GetDescendants()) do
                if not DodgeEnabled then
                    break
                end
                if desc:IsA("BasePart") then
                    ProcessPart(desc)
                end
            end
        end)
        
        -- // REWRITTEN DODGE LOOP // --
        local lastLogicTick = 0
        local lastPurgeTick = 0
        local lastMoveTick = 0
        DodgeLoop = RunService.Heartbeat:Connect(function()
            local currentTime = os.clock()
            if currentTime - lastLogicTick < DODGE_LOGIC_INTERVAL then return end
            lastLogicTick = currentTime

            local character = Player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChild("Humanoid")
            if not hrp or not humanoid then return end

            if currentTime - lastPurgeTick >= THREAT_PURGE_INTERVAL then
                lastPurgeTick = currentTime
                local toRemove = {}
                for part, d in pairs(ActiveThreats) do
                    local gone = (not part) or (not part.Parent) or (not part:IsDescendantOf(workspace))
                    local expired = d.EndTime and (currentTime > d.EndTime + 0.75)
                    if gone or expired then table.insert(toRemove, part) end
                end
                for _, p in ipairs(toRemove) do
                    local d = ActiveThreats[p]
                    if d and d.Connection then pcall(function() d.Connection:Disconnect() end) end
                    ActiveThreats[p] = nil
                end
            end

            local overlappingThreats = {}
            local shouldJump = false
            local ignoreSet = {}
            local nearbyThreats = {}
            local nearestThreat = nil
            local nearestDist = math.huge

            for part, data in pairs(ActiveThreats) do
                if part and part.Parent then
                    local partDist = (part.Position - hrp.Position).Magnitude
                    if partDist <= ((data.Radius or part.Size.Magnitude / 2) + 85) then
                        nearbyThreats[#nearbyThreats + 1] = data
                    end
                    if partDist < nearestDist then
                        nearestDist = partDist
                        nearestThreat = part
                    end

                    local relPos = part.CFrame:PointToObjectSpace(hrp.Position)
                    local halfSize = part.Size / 2
                    local dynExtra = (data.IsLong and 8) or 0
                    local margin = 6 + dynExtra

                    local isInside = math.abs(relPos.X) < (halfSize.X + margin) and 
                                    math.abs(relPos.Z) < (halfSize.Z + margin) and
                                    math.abs(relPos.Y) < (halfSize.Y + margin)

                    if isInside then
                        local bColor = part.BrickColor.Name
                        local age = currentTime - data.StartTime
                        local isFast = (bColor:find("red") or bColor:find("blue") or bColor:find("green") or bColor == "Tawny")
                        local isLong = data.IsLong
                        local isBlue = data.IsBlue

                        local requiredAge = 0.6
                        if isFast then
                            requiredAge = 0.05
                        elseif isBlue then
                            requiredAge = 0.15 -- bluish circles: respond a bit sooner but not instant
                        elseif isLong then
                            requiredAge = 0.12 -- react earlier for long sweeps
                        end

                        if age >= requiredAge then
                            table.insert(overlappingThreats, part)
                            ignoreSet[part] = true
                            if part.Name:lower():find("slash") then 
                                shouldJump = true 
                            end
                        end
                    end

                    do
                        local last = data.LastPos or part.Position
                        local dt = DODGE_LOGIC_INTERVAL
                        local vel = (part.Position - last) / dt
                        data.Velocity = vel
                        data.LastPos = part.Position
                    end
                end
            end

            local imminentDanger = (not IsSafeAtTime(hrp.Position, PROACTIVE_LOOKAHEAD, nil, nearbyThreats))
                or (not IsSafeAtTime(hrp.Position, FAR_LOOKAHEAD, nil, nearbyThreats))

            if #overlappingThreats > 0 or imminentDanger then
                if shouldJump and humanoid.FloorMaterial ~= Enum.Material.Air then
                    click_bind(Enum.KeyCode.Space)
                end

                local bestPoint = nil
                local candidates = {}
                local primary = overlappingThreats[1] or nearestThreat
                if not primary or not primary.Parent then
                    return
                end
                local cf = primary.CFrame
                local size = primary.Size
                local relPos = cf:PointToObjectSpace(hrp.Position)
                local primaryData = ActiveThreats[primary]
                local safetyBuffer = 14 + ((primaryData and primaryData.IsLong) and 10 or 0)

                if size.X < size.Z then
                    table.insert(candidates, cf:PointToWorldSpace(Vector3.new(size.X/2 + safetyBuffer, 0, relPos.Z)))
                    table.insert(candidates, cf:PointToWorldSpace(Vector3.new(-(size.X/2 + safetyBuffer), 0, relPos.Z)))
                else
                    table.insert(candidates, cf:PointToWorldSpace(Vector3.new(relPos.X, 0, size.Z/2 + safetyBuffer)))
                    table.insert(candidates, cf:PointToWorldSpace(Vector3.new(relPos.X, 0, -(size.Z/2 + safetyBuffer))))
                end

                local primaryVel = (primaryData and primaryData.Velocity) or Vector3.new()
                if primaryVel.Magnitude > 1 then
                    local sweepDir = primaryVel.Unit
                    local perp = Vector3.new(-sweepDir.Z, 0, sweepDir.X)
                    local offset = (math.max(size.X, size.Z) / 2) + safetyBuffer + 6
                    table.insert(candidates, cf.Position + perp * offset)
                    table.insert(candidates, cf.Position - perp * offset)
                    table.insert(candidates, hrp.Position + perp * (offset * 0.8))
                    table.insert(candidates, hrp.Position - perp * (offset * 0.8))
                end

                local backDir = -hrp.CFrame.LookVector
                local rightDir = hrp.CFrame.RightVector
                local fwdDir = hrp.CFrame.LookVector

                table.insert(candidates, hrp.Position + backDir * 22)
                table.insert(candidates, hrp.Position + backDir * 22 + rightDir * 15)
                table.insert(candidates, hrp.Position + backDir * 22 - rightDir * 15)
                table.insert(candidates, hrp.Position + rightDir * 18)
                table.insert(candidates, hrp.Position - rightDir * 18)
                table.insert(candidates, hrp.Position + fwdDir * 12 + rightDir * 12)
                table.insert(candidates, hrp.Position + fwdDir * 12 - rightDir * 12)

                local bestHazardCount = math.huge
                local bestDist = math.huge

                for _, p in ipairs(candidates) do
                    local dist = (p - hrp.Position).Magnitude
                    local travelTime = dist / math.max(humanoid.WalkSpeed, 6)
                    local arrivalDelay = travelTime + 0.17

                    if not IsSafeAtTime(p, arrivalDelay, nil, nearbyThreats) or not IsSafeAtTime(p, arrivalDelay + 0.14, nil, nearbyThreats) then
                        continue
                    end

                    if not IsPathSafe(hrp.Position, p, humanoid.WalkSpeed, ignoreSet, nearbyThreats) then
                        continue
                    end

                    local currentHazardCount = 0
                    for _, d in ipairs(nearbyThreats) do
                        local part = d.Instance
                        if part and part.Parent then
                            local pRel = part.CFrame:PointToObjectSpace(p)
                            local hSize = part.Size / 2 + Vector3.new((d.IsLong and 6) or 4, (d.IsLong and 6) or 4, (d.IsLong and 6) or 4)
                            if math.abs(pRel.X) < hSize.X and math.abs(pRel.Z) < hSize.Z and math.abs(pRel.Y) < hSize.Y then
                                currentHazardCount = currentHazardCount + 1
                            end
                        end
                    end

                    if currentHazardCount < bestHazardCount then
                        bestHazardCount = currentHazardCount
                        bestDist = dist
                        bestPoint = p
                    elseif currentHazardCount == bestHazardCount and dist < bestDist then
                        bestDist = dist
                        bestPoint = p
                    end
                end

                if bestPoint and (currentTime - lastMoveTick) > 0.06 then
                    lastMoveTick = currentTime
                    humanoid:MoveTo(bestPoint)
                    CurrentSafePoint = bestPoint
                end
            else
                if CurrentSafePoint and (currentTime - lastMoveTick) > 0.14 then
                    lastMoveTick = currentTime
                    CurrentSafePoint = nil
                    humanoid:MoveTo(hrp.Position)
                end
            end
        end)
    else
        if DodgeConnection then DodgeConnection:Disconnect() DodgeConnection = nil end
        if DodgeLoop then DodgeLoop:Disconnect() DodgeLoop = nil end
        for _, data in pairs(ActiveThreats) do data.Connection:Disconnect() end
        ActiveThreats = {}
        DodgeCommittedThreats = {}
    end
end, nil, "main.toggle_dodge_key")

Tabs.Main:CreateToggle("Dodge Debug", function(state)
    DodgeDebug = state
    UILibrary:Notify({ Title = "Debug Mode", Content = DodgeDebug and "Debug ON" or "Debug OFF", Duration = 2 })
    VisualsEnabled = state
end, false, "main.dodge_debug")

local AutoFaceEnabled = false
local AutoFaceConnection = nil
local ClosestEnemyCache = {}

local function GetClosestEnemy(maxDist)
    local character = Player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local distCap = maxDist or 300
    local cacheKey = tostring(distCap)
    local cached = ClosestEnemyCache[cacheKey]
    local now = os.clock()
    if cached and (now - cached.Time) < 0.12 and cached.Ref and cached.Ref.Parent then
        if (cached.Ref.Position - hrp.Position).Magnitude <= distCap + 2 then
            return cached.Ref
        end
    end

    local closestDist = distCap
    local closestEnemy = nil
    
    local function checkTarget(model)
        if model ~= character then
            local hum = model:FindFirstChild("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
            if hum and root and hum.Health > 0 then
                if not Players:GetPlayerFromCharacter(model) then
                    local dist = (root.Position - hrp.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestEnemy = root
                    end
                end
            end
        end
    end

    -- Optimized: Check Enemies folder first, fallback to workspace scan only if needed or desired
    if workspace:FindFirstChild("Enemies") then 
        for _, v in ipairs(workspace.Enemies:GetChildren()) do checkTarget(v) end
    else
        for _, v in ipairs(workspace:GetChildren()) do
            if v:IsA("Model") then checkTarget(v) end
        end
    end
    
    ClosestEnemyCache[cacheKey] = {
        Ref = closestEnemy,
        Time = now
    }
    return closestEnemy
end

Tabs.Main:CreateToggle("Auto Face Enemy", function(state)
    AutoFaceEnabled = state
    local char = Player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.AutoRotate = not state end

    if state then
        AutoFaceConnection = RunService.Heartbeat:Connect(function()
            local target = GetClosestEnemy()
            local character = Player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if hrp and DodgeEnabled and target then
                char.Humanoid.AutoRotate = false
                local gyro = hrp:FindFirstChild("FaceGyro") or Instance.new("BodyGyro")
                gyro.Name = "FaceGyro"
                gyro.MaxTorque = Vector3.new(0, 400000, 0)
                gyro.P = 3000; gyro.D = 100
                gyro.Parent = hrp
                gyro.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z))
            end
        end)
    else
        if AutoFaceConnection then AutoFaceConnection:Disconnect() end
        local char = Player.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.AutoRotate = true end
        if char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart:FindFirstChild("FaceGyro") then
            char.HumanoidRootPart.FaceGyro:Destroy()
        end
    end
end, false, "main.auto_face_enemy")

local AutoSkillsEnabled = false
Tabs.Main:CreateToggle("Auto Skills (E & Q)", function(state)
    AutoSkillsEnabled = state
    if state then
        task.spawn(function()
            while AutoSkillsEnabled do
                task.wait(0.1)
                local target = GetClosestEnemy(100)
                if target and DodgeEnabled then
                    local cdE = Player:FindFirstChild("cooldownE")
                    if cdE and cdE.Value == 0 then
                        click_bind(Enum.KeyCode.E)
                    end
                    
                    local cdQ = Player:FindFirstChild("cooldownQ")
                    if cdQ and cdQ.Value == 0 then
                         click_bind(Enum.KeyCode.Q)
                    end
                end
            end
        end)
    end
end, false, "main.auto_skills")


-- // FARMING TAB // --
local FarmingEnabled = UILibrary:RegisterValue("FarmingEnabled", false)

print(FarmingEnabled:Get())

local FarmingLoop = nil
local FarmingKey = Enum.KeyCode.B

local FarmHeight = 12
local FarmOffset = 8
local FarmAttackRange = 25
local FarmAttackInterval = 0.25
local FarmUseMouse1 = false
local FarmSkillKeys = { Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.R }
local FarmOrbitTarget = nil
local FarmOrbitHeight = nil
local FarmOrbitAngle = 0
local FarmOrbitRadius = 12
local FarmOrbitSpeed = 4.1
local FarmNeokazeName = "general neokaze"
local FarmNeokazeOrbitRadius = 33
local FarmNeokazeEngageRange = 98
local FarmMueName = "mue no ikari"
local FarmMueOrbitRadius = 34
local FarmMueEngageRange = 90
local FarmMaxExtraHeight = 10
local FarmDodgeExtraRadius = 13
local FarmDodgeSpeedMultiplier = 1.4
local FarmOrbitDirection = 1
local FarmOrbitRadiusOffset = 0
local FarmHeightOffset = 0
local FarmOrbitSpeedMultiplier = 1
local FarmNextRandomizeTime = 0
local FarmLastStepTime = 0
local FarmLastAttackTime = 0
local FarmCombatScore = 0
local FarmScoreMin = -250
local FarmScoreMax = 350
local FarmScoreDecayPerSec = 3.5
local FarmLastPlayerHealth = nil
local FarmLastDamageTakenTime = 0
local FarmLastDamageDealtTime = 0
local FarmLastTargetHumanoid = nil
local FarmLastTargetHealth = nil
local FarmTargetCache = { Root = nil, Dist = nil, Time = 0, HrPos = nil, Cap = nil }

local function add_farm_score(delta)
    FarmCombatScore = math.clamp(FarmCombatScore + delta, FarmScoreMin, FarmScoreMax)
end
local function send_mouse1()
    Vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.03)
    Vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function get_enemies_container()
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    return enemies:FindFirstChild("Enemies") or enemies:FindFirstChild("enemies") or enemies
end

local function is_enemy_model(model)
    if not model or not model:IsA("Model") then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if not hum or not root or hum.Health <= 0 then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    return true
end

local function get_closest_enemy_root(maxDist)
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local now = os.clock()
    local cap = maxDist or 9999
    if FarmTargetCache.Root
        and FarmTargetCache.Root.Parent
        and FarmTargetCache.Cap == cap
        and (now - FarmTargetCache.Time) < 0.09
        and FarmTargetCache.HrPos
        and (FarmTargetCache.HrPos - hrp.Position).Magnitude < 6
    then
        local distNow = (FarmTargetCache.Root.Position - hrp.Position).Magnitude
        if distNow <= cap + 2 then
            return FarmTargetCache.Root, distNow
        end
    end

    local container = get_enemies_container()
    if not container then return nil end

    local bestRoot = nil
    local bestDist = maxDist or 9999

    for _, model in ipairs(container:GetChildren()) do
        if is_enemy_model(model) then
            local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
            local dist = (root.Position - hrp.Position).Magnitude
            if dist < bestDist then
                bestDist = dist
                bestRoot = root
            end
        end
    end

    FarmTargetCache.Root = bestRoot
    FarmTargetCache.Dist = bestDist
    FarmTargetCache.Time = now
    FarmTargetCache.HrPos = hrp.Position
    FarmTargetCache.Cap = cap
    return bestRoot, bestDist
end
local function get_target_settings(targetRoot)
    local model = targetRoot and targetRoot:FindFirstAncestorOfClass("Model")
    local targetName = ((model and model.Name) or (targetRoot and targetRoot.Name) or ""):lower()
    local isNeokaze = targetName:find(FarmNeokazeName, 1, true) ~= nil
    local isMue = targetName:find(FarmMueName, 1, true) ~= nil

    return {
        isNeokaze = isNeokaze,
        isMue = isMue,
        engageRange = isMue and FarmMueEngageRange or (isNeokaze and FarmNeokazeEngageRange or FarmAttackRange),
        orbitRadius = isMue and FarmMueOrbitRadius or (isNeokaze and FarmNeokazeOrbitRadius or FarmOrbitRadius),
        dodgeExtraRadius = isMue and (FarmDodgeExtraRadius + 12) or (isNeokaze and (FarmDodgeExtraRadius + 8) or FarmDodgeExtraRadius),
        dodgeSpeedMultiplier = isMue and (FarmDodgeSpeedMultiplier + 0.45) or (isNeokaze and (FarmDodgeSpeedMultiplier + 0.35) or FarmDodgeSpeedMultiplier),
        maxExtraHeight = isMue and (FarmMaxExtraHeight + 4) or (isNeokaze and (FarmMaxExtraHeight + 2) or FarmMaxExtraHeight),
        dangerFlipChance = isMue and 0.72 or (isNeokaze and 0.68 or 0.55),
        safeFlipChance = isMue and 0.45 or (isNeokaze and 0.40 or 0.35),
        randomizeMin = isMue and 0.22 or (isNeokaze and 0.24 or 0.30),
        randomizeJitter = isMue and 0.35 or (isNeokaze and 0.40 or 0.55),
        shortLookahead = isMue and 0.28 or (isNeokaze and 0.24 or 0.16),
        longLookahead = isMue and 0.55 or (isNeokaze and 0.50 or 0.35),
        radiusOffsetMin = isMue and 0 or (isNeokaze and 2 or 0),
        radiusOffsetMax = isMue and 8 or (isNeokaze and 9 or 2),
        dodgeThreshold = isMue and 1 or (isNeokaze and 1 or 1),
        panicThreshold = isMue and 2 or (isNeokaze and 1 or 2),
        panicDuration = isMue and 0.75 or (isNeokaze and 0.65 or 0.25),
        attackDangerTolerance = 0,
        attackInterval = isMue and 0.18 or (isNeokaze and 0.20 or 0.12),
        hardMinRadius = isMue and 32 or (isNeokaze and 30 or 0),
        survivalMode = isNeokaze,
        preferredRadius = isMue and 38 or (isNeokaze and 36 or FarmOrbitRadius),
        strikeMaxRadius = isMue and 52 or (isNeokaze and 48 or FarmAttackRange),
        radiusErrorPenalty = isMue and 0.08 or (isNeokaze and 0.12 or 0.05),
        behindBias = isMue and 3.5 or (isNeokaze and 5.0 or 1.5),
        coverBias = isMue and 3.0 or (isNeokaze and 5.5 or 0.5),
    }
end

local function is_farm_danger_part(part)
    if not part or not part:IsA("BasePart") then return false end

    local nameLower = part.Name:lower()
    local bColor = part.BrickColor.Name
    if not VALID_NAMES[nameLower] or not VALID_COLORS[bColor] then return false end
    if nameLower == "hitbox" and bColor == "Medium stone grey" then return false end

    local model = part:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then return false end

    return true
end

local function is_farm_position_safe(position)
    if not IsSafeAtTime(position, 0.08) or not IsSafeAtTime(position, 0.22) then
        return false
    end

    local nearby = workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(8, 8, 8))
    for _, part in ipairs(nearby) do
        if is_farm_danger_part(part) then
            return false
        end
    end

    return true
end

local function has_cover_from_target(targetRoot, position, ignoreList)
    if not targetRoot then return false end

    local origin = targetRoot.Position + Vector3.new(0, 2, 0)
    local direction = (position + Vector3.new(0, 2, 0)) - origin
    if direction.Magnitude < 2 then return false end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignoreList or {}
    params.IgnoreWater = true

    local hit = workspace:Raycast(origin, direction, params)
    return hit ~= nil
end

local function farm_step()
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local now = os.clock()
    local dt = (FarmLastStepTime > 0) and math.clamp(now - FarmLastStepTime, 0.005, 0.05) or (1 / 60)
    FarmLastStepTime = now
    add_farm_score(-(FarmScoreDecayPerSec * dt))

    if FarmLastPlayerHealth then
        local lost = FarmLastPlayerHealth - hum.Health
        if lost > 0.05 then
            -- Taking damage is heavily penalized so behavior shifts defensive.
            add_farm_score(-(lost * 3.8))
            FarmLastDamageTakenTime = now
        end
    end
    FarmLastPlayerHealth = hum.Health

    local targetRoot = get_closest_enemy_root(700)
    if not targetRoot then
        FarmOrbitTarget = nil
        FarmOrbitHeight = nil
        FarmLastAttackTime = 0
        FarmLastTargetHumanoid = nil
        FarmLastTargetHealth = nil
        FarmTargetCache.Root = nil
        return
    end

    local flatToEnemy = Vector3.new(targetRoot.Position.X - hrp.Position.X, 0, targetRoot.Position.Z - hrp.Position.Z)
    local flatDistance = flatToEnemy.Magnitude
    local targetSettings = get_target_settings(targetRoot)

    if flatDistance <= targetSettings.engageRange then
        local targetModel = targetRoot:FindFirstAncestorOfClass("Model")
        local targetHum = targetModel and targetModel:FindFirstChildOfClass("Humanoid")
        if targetHum and targetHum.Health > 0 then
            if FarmLastTargetHumanoid ~= targetHum then
                FarmLastTargetHumanoid = targetHum
                FarmLastTargetHealth = targetHum.Health
            else
                local dealt = FarmLastTargetHealth and (FarmLastTargetHealth - targetHum.Health) or 0
                if dealt and dealt > 0.01 then
                    -- Reward actual damage output (DPS pressure).
                    add_farm_score(dealt * 1.45)
                    FarmLastDamageDealtTime = now
                end
                FarmLastTargetHealth = targetHum.Health
            end
        else
            FarmLastTargetHumanoid = nil
            FarmLastTargetHealth = nil
        end

        if FarmOrbitTarget ~= targetRoot then
            FarmOrbitTarget = targetRoot
            FarmOrbitHeight = nil
            FarmOrbitDirection = (math.random() < 0.5) and -1 or 1
            FarmOrbitRadiusOffset = 0
            FarmHeightOffset = 0
            FarmOrbitSpeedMultiplier = 1
            FarmNextRandomizeTime = 0

            local rel = hrp.Position - targetRoot.Position
            FarmOrbitAngle = math.atan2(rel.Z, rel.X)
        end

        local minHeight = targetRoot.Position.Y + FarmHeight
        local maxHeight = minHeight + targetSettings.maxExtraHeight
        if not FarmOrbitHeight then
            FarmOrbitHeight = minHeight
        end

        local dangerScore = 0
        if not IsSafeAtTime(hrp.Position, 0.02) then dangerScore = dangerScore + 1 end
        if not IsSafeAtTime(hrp.Position, targetSettings.shortLookahead) then dangerScore = dangerScore + 1 end
        if not IsSafeAtTime(hrp.Position, targetSettings.longLookahead) then dangerScore = dangerScore + 1 end
        if targetSettings.survivalMode and not IsSafeAtTime(hrp.Position, 0.75) then dangerScore = dangerScore + 2 end
        if not is_farm_position_safe(hrp.Position) then dangerScore = dangerScore + 1 end
        local inDangerNow = dangerScore >= targetSettings.dodgeThreshold
        local panicActive = dangerScore >= targetSettings.panicThreshold

        -- Reward successful dodging under pressure if we are not getting hit.
        if inDangerNow and (now - FarmLastDamageTakenTime) > 0.9 then
            add_farm_score(0.65 * dt * 60)
        end

        local safetyBias = math.clamp((-FarmCombatScore) / 130, 0, 1.6)
        local aggressionBias = math.clamp(FarmCombatScore / 130, 0, 1.3)

        if now >= FarmNextRandomizeTime then
            if math.random() < (inDangerNow and targetSettings.dangerFlipChance or targetSettings.safeFlipChance) then
                FarmOrbitDirection = -FarmOrbitDirection
            end
            FarmOrbitRadiusOffset = math.random(targetSettings.radiusOffsetMin, targetSettings.radiusOffsetMax)
            FarmHeightOffset = math.random(-1, 2)
            FarmOrbitSpeedMultiplier = 0.85 + math.random() * 0.55
            FarmNextRandomizeTime = now + targetSettings.randomizeMin + (math.random() * targetSettings.randomizeJitter)
        end

        if panicActive then
            FarmLastAttackTime = now + targetSettings.panicDuration
        end

        local orbitSpeedNow = FarmOrbitSpeed * FarmOrbitSpeedMultiplier * (inDangerNow and targetSettings.dodgeSpeedMultiplier or 1)
        FarmOrbitAngle = FarmOrbitAngle + (orbitSpeedNow * FarmOrbitDirection * dt)

        local baseRadius = math.max(8, targetSettings.orbitRadius + FarmOrbitRadiusOffset)
        local preferredRadius = (targetSettings.preferredRadius or baseRadius) + (safetyBias * 2.4) - (aggressionBias * 1.6)
        local strikeMaxRadius = (targetSettings.strikeMaxRadius or targetSettings.engageRange) + (safetyBias * 3.0) - (aggressionBias * 1.5)
        if targetSettings.hardMinRadius and targetSettings.hardMinRadius > 0 then
            baseRadius = math.max(baseRadius, targetSettings.hardMinRadius)
            preferredRadius = math.max(preferredRadius, targetSettings.hardMinRadius - 1)
        end
        strikeMaxRadius = math.max(strikeMaxRadius, preferredRadius + 3)
        local radiusCandidates = inDangerNow and {
            baseRadius + 4,
            baseRadius + targetSettings.dodgeExtraRadius,
            baseRadius + targetSettings.dodgeExtraRadius + 6,
        } or {
            baseRadius,
            baseRadius + 4,
        }
        if targetSettings.survivalMode then
            radiusCandidates = {
                baseRadius + 6,
                baseRadius + targetSettings.dodgeExtraRadius,
                baseRadius + targetSettings.dodgeExtraRadius + 8,
                baseRadius + targetSettings.dodgeExtraRadius + 14,
            }
        end

        local angleStep = inDangerNow and 0.40 or 0.55
        local angleCandidates = {
            FarmOrbitAngle,
            FarmOrbitAngle + (angleStep * FarmOrbitDirection),
            FarmOrbitAngle - (angleStep * FarmOrbitDirection),
            FarmOrbitAngle + (angleStep * 2 * FarmOrbitDirection),
            FarmOrbitAngle - (angleStep * 2 * FarmOrbitDirection),
        }
        if targetSettings.survivalMode then
            angleCandidates = {
                FarmOrbitAngle,
                FarmOrbitAngle + (0.30 * FarmOrbitDirection),
                FarmOrbitAngle - (0.30 * FarmOrbitDirection),
                FarmOrbitAngle + (0.65 * FarmOrbitDirection),
                FarmOrbitAngle - (0.65 * FarmOrbitDirection),
                FarmOrbitAngle + (1.10 * FarmOrbitDirection),
                FarmOrbitAngle - (1.10 * FarmOrbitDirection),
                FarmOrbitAngle + (1.55 * FarmOrbitDirection),
                FarmOrbitAngle - (1.55 * FarmOrbitDirection),
            }
        end

        local baseY = math.clamp(targetRoot.Position.Y + FarmHeight + FarmHeightOffset, minHeight, maxHeight)
        local dodgeMaxHeight = maxHeight + (inDangerNow and 6 or 0)
        local heightCandidates = inDangerNow and {
            baseY,
            math.min(dodgeMaxHeight, baseY + 2),
            math.min(dodgeMaxHeight, baseY + 5),
            math.min(dodgeMaxHeight, baseY + 8),
        } or {
            baseY,
            math.min(maxHeight, baseY + 2),
            math.min(maxHeight, baseY + 4),
        }
        if targetSettings.survivalMode then
            local hardMaxY = dodgeMaxHeight + 5
            heightCandidates = {
                baseY + 1,
                math.min(hardMaxY, baseY + 4),
                math.min(hardMaxY, baseY + 7),
                math.min(hardMaxY, baseY + 10),
            }
        end

        local bestPos = nil
        local bestLookY = baseY
        local bestScore = -math.huge
        local targetModel = targetRoot and targetRoot:FindFirstAncestorOfClass("Model")
        local rayIgnore = {Player.Character, targetModel}

        for _, radius in ipairs(radiusCandidates) do
            for _, ang in ipairs(angleCandidates) do
                local offset = Vector3.new(math.cos(ang), 0, math.sin(ang)) * radius
                for _, y in ipairs(heightCandidates) do
                    local candidate = Vector3.new(
                        targetRoot.Position.X + offset.X,
                        y,
                        targetRoot.Position.Z + offset.Z
                    )

                    local safeNow = IsSafeAtTime(candidate, 0.05)
                    local safeShort = IsSafeAtTime(candidate, 0.18)
                    local safeLong = IsSafeAtTime(candidate, targetSettings.longLookahead)
                    local safeFar = (not targetSettings.survivalMode) or IsSafeAtTime(candidate, 0.8)
                    local probeSafe = is_farm_position_safe(candidate)
                    local pathSafe = IsPathSafe(hrp.Position, candidate, math.max(hum.WalkSpeed, 16))
                    local strictSafe = safeNow and safeShort and safeLong and safeFar and probeSafe and pathSafe
                    local candidateFlatDist = Vector3.new(
                        candidate.X - targetRoot.Position.X,
                        0,
                        candidate.Z - targetRoot.Position.Z
                    ).Magnitude

                    if (inDangerNow or targetSettings.survivalMode) and not strictSafe then
                        continue
                    end
                    if targetSettings.survivalMode and (not panicActive) and candidateFlatDist > strikeMaxRadius then
                        continue
                    end

                    local score = 0
                    if safeNow then score = score + 1 end
                    if safeShort then score = score + 1 end
                    if safeLong then score = score + 1 end
                    if safeFar then score = score + 2 end
                    if probeSafe then score = score + 2 end
                    if pathSafe then score = score + 2 else score = score - 2 end
                    if strictSafe then score = score + 4 end

                    local moveDist = (candidate - hrp.Position).Magnitude
                    if inDangerNow then
                        score = score + (moveDist * 0.02)
                    else
                        score = score - (moveDist * 0.01)
                    end

                    -- Keep Neokaze within a hittable ring: safe but not too far.
                    local radiusError = math.abs(candidateFlatDist - preferredRadius)
                    score = score - (radiusError * (targetSettings.radiusErrorPenalty or 0.06))

                    if targetSettings.survivalMode then
                        local targetLook = targetRoot.CFrame.LookVector
                        local toCandidateFlat = Vector3.new(
                            candidate.X - targetRoot.Position.X,
                            0,
                            candidate.Z - targetRoot.Position.Z
                        )
                        local toCandidateDir = (toCandidateFlat.Magnitude > 0.01) and toCandidateFlat.Unit or Vector3.new(0, 0, 1)
                        local frontDot = targetLook:Dot(toCandidateDir)
                        -- frontDot < 0 => behind target
                        score = score + ((-frontDot) * (targetSettings.behindBias or 4.0))

                        if has_cover_from_target(targetRoot, candidate, rayIgnore) then
                            score = score + (targetSettings.coverBias or 4.5)
                        end
                    end

                    if score > bestScore then
                        bestScore = score
                        bestPos = candidate
                        bestLookY = y
                    end
                end
            end
        end

        if not bestPos then
            local escapeRadius = baseRadius + targetSettings.dodgeExtraRadius + 10
            if targetSettings.strikeMaxRadius and not panicActive then
                escapeRadius = math.min(escapeRadius, targetSettings.strikeMaxRadius + 6)
            end
            bestLookY = math.min(dodgeMaxHeight, baseY + 6)
            for i = 0, 11 do
                local tryAngle = FarmOrbitAngle + (i * math.pi / 6)
                local offset = Vector3.new(math.cos(tryAngle), 0, math.sin(tryAngle)) * escapeRadius
                local candidate = Vector3.new(
                    targetRoot.Position.X + offset.X,
                    bestLookY,
                    targetRoot.Position.Z + offset.Z
                )
                if IsSafeAtTime(candidate, 0.05) and
                   (not targetSettings.survivalMode or IsSafeAtTime(candidate, 0.8)) and
                   IsSafeAtTime(candidate, targetSettings.longLookahead) and
                   is_farm_position_safe(candidate) then
                    bestPos = candidate
                    break
                end
            end
            if targetSettings.survivalMode and not bestPos then
                for i = 0, 23 do
                    local tryAngle = FarmOrbitAngle + (i * math.pi / 12)
                    local offset = Vector3.new(math.cos(tryAngle), 0, math.sin(tryAngle)) * (escapeRadius + 8)
                    local candidate = Vector3.new(
                        targetRoot.Position.X + offset.X,
                        math.min(dodgeMaxHeight + 5, bestLookY + 2),
                        targetRoot.Position.Z + offset.Z
                    )
                    if IsSafeAtTime(candidate, 0.05) and IsSafeAtTime(candidate, 0.8) and IsSafeAtTime(candidate, targetSettings.longLookahead) then
                        bestPos = candidate
                        bestLookY = candidate.Y
                        break
                    end
                end
            end
            if not bestPos then
                local offset = Vector3.new(math.cos(FarmOrbitAngle), 0, math.sin(FarmOrbitAngle)) * escapeRadius
                bestPos = Vector3.new(
                    targetRoot.Position.X + offset.X,
                    bestLookY,
                    targetRoot.Position.Z + offset.Z
                )
            end
        end

        -- Neokaze panic: force an extra outward push immediately when danger is detected.
        if panicActive and targetSettings.hardMinRadius and targetSettings.hardMinRadius > 0 then
            local away = hrp.Position - targetRoot.Position
            local awayFlat = Vector3.new(away.X, 0, away.Z)
            local awayDir = (awayFlat.Magnitude > 0.01) and awayFlat.Unit or Vector3.new(math.cos(FarmOrbitAngle), 0, math.sin(FarmOrbitAngle))
            local forcedRadius = targetSettings.hardMinRadius + targetSettings.dodgeExtraRadius + 10
            local forcedPos = Vector3.new(
                targetRoot.Position.X + awayDir.X * forcedRadius,
                math.clamp(bestPos.Y + 2, minHeight, dodgeMaxHeight),
                targetRoot.Position.Z + awayDir.Z * forcedRadius
            )
            if IsSafeAtTime(forcedPos, 0.05) and IsSafeAtTime(forcedPos, targetSettings.longLookahead) then
                bestPos = forcedPos
                bestLookY = forcedPos.Y
            end
        end

        FarmOrbitHeight = math.clamp(bestPos.Y, minHeight, dodgeMaxHeight)
        hrp.CFrame = CFrame.new(bestPos, Vector3.new(targetRoot.Position.X, bestLookY, targetRoot.Position.Z))
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

        local canAttack = (dangerScore <= targetSettings.attackDangerTolerance) and (now >= FarmLastAttackTime)
        if targetSettings.survivalMode then
            canAttack = canAttack and (not panicActive) and IsSafeAtTime(hrp.Position, 0.55) and (flatDistance <= strikeMaxRadius)
        end
        local adaptiveAttackInterval = math.clamp(
            targetSettings.attackInterval + (safetyBias * 0.06) - (aggressionBias * 0.035),
            targetSettings.survivalMode and 0.15 or 0.09,
            0.30
        )
        if canAttack and now - FarmLastAttackTime >= adaptiveAttackInterval then
            FarmLastAttackTime = now
            if FarmUseMouse1 then
                send_mouse1()
            end
            for _, key in ipairs(FarmSkillKeys) do
                click_bind(key)
            end
            -- Safe pressure + successful action gets small reward.
            if dangerScore == 0 then
                add_farm_score(0.8)
            end
        end

        return
    end

    FarmOrbitTarget = nil
    FarmOrbitHeight = nil
    FarmLastAttackTime = 0

    local toPlayer = hrp.Position - targetRoot.Position
    local flat = Vector3.new(toPlayer.X, 0, toPlayer.Z)
    local dir = (flat.Magnitude > 0.001) and flat.Unit or Vector3.new(0, 0, 1)

    local approachRadius = math.max(FarmOffset, targetSettings.orbitRadius)
    local targetPos = targetRoot.Position + dir * approachRadius + Vector3.new(0, FarmHeight + 4, 0)
    hrp.CFrame = CFrame.new(targetPos, Vector3.new(targetRoot.Position.X, targetPos.Y, targetRoot.Position.Z))
end
local function set_farming(state)
    if FarmingEnabled:Get() == state then return end
    FarmingEnabled:Set(state)

    if FarmingEnabled:Get() then
        FarmingLoop = RunService.Heartbeat:Connect(function()
            pcall(farm_step)
        end)
    else
        if FarmingLoop then
            FarmingLoop:Disconnect()
            FarmingLoop = nil
        end
        FarmOrbitTarget = nil
        FarmOrbitHeight = nil
        FarmOrbitDirection = 1
        FarmOrbitRadiusOffset = 0
        FarmHeightOffset = 0
        FarmOrbitSpeedMultiplier = 1
        FarmNextRandomizeTime = 0
        FarmLastStepTime = 0
        FarmLastAttackTime = 0
        FarmCombatScore = 0
        FarmLastPlayerHealth = nil
        FarmLastDamageTakenTime = 0
        FarmLastDamageDealtTime = 0
        FarmLastTargetHumanoid = nil
        FarmLastTargetHealth = nil
        FarmTargetCache.Root = nil
        FarmTargetCache.Time = 0
        FarmTargetCache.HrPos = nil
    end

    UILibrary:Notify({
        Title = "Simple Farm",
        Content = FarmingEnabled:Get() and "ENABLED" or "DISABLED",
        Duration = 2
    })
end

Tabs.Farming:CreateToggle("Simple Auto Farm", function(state)
    set_farming(state)
end, FarmingEnabled:Get())

local farm_key = Tabs.Farming:CreateKeybind("Toggle Farm Key", function()
    set_farming(not FarmingEnabled:Get())
end, FarmingKey, "farming.toggle_farm_key")

Tabs.Farming:CreateParagraph("Info", "Simple farm: press B or use toggle to move above nearest enemy and attack with Mouse1 + E/Q.")


Window:OnClose(function()
    DodgeEnabled = false
    AutoFaceEnabled = false
    AutoSkillsEnabled = false
    --set_farming(false)
    if DodgeConnection then DodgeConnection:Disconnect() end
    if DodgeLoop then DodgeLoop:Disconnect() end
    if AutoFaceConnection then AutoFaceConnection:Disconnect() end
    for _, data in pairs(ActiveThreats) do data.Connection:Disconnect() end
    ActiveThreats = {}
    DodgeCommittedThreats = {}
    local char = Player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.AutoRotate = true end
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:FindFirstChild("FaceGyro") then hrp.FaceGyro:Destroy() end
end)


Tabs.Main:CreateKeybind("Track Specific Parts (2s)", function()
    UILibrary:Notify({
        Title = "Tracking Started",
        Content = "Searching for Valid Parts...",
        Duration = 2
    })
    
    local addedParts = {}
    
    -- Valid colors for all specified parts
    local validColors = {
        ["Faded green"] = true,
        ["Medium bluish green"] = true,
        ["Bright red"] = true,
        ["Pastel blue-green"] = true,
        ["Medium stone grey"] = true
    }

    local connection = workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            -- 1. Name Validation (Case Insensitive)
            local name = descendant.Name:lower()
            local isValidName = (name == "part" or name == "mage" or name == "slash" or name == "hitbox" or name == "indicator")
            
            if not isValidName then return end

            -- 2. Color Validation
            local bColor = descendant.BrickColor.Name
            if not validColors[bColor] then return end

            -- 3. Specific Exclusion: Hitbox + Medium stone grey (Own ability)
            if name == "hitbox" and bColor == "Medium stone grey" then return end

            -- 4. Humanoid Exclusion (Ignore Players/NPCs)
            local model = descendant:FindFirstAncestorOfClass("Model")
            if model and model:FindFirstChildOfClass("Humanoid") then return end

            -- If all checks pass, track it
            table.insert(addedParts, descendant)
        end
    end)

    task.wait(2)
    connection:Disconnect()

    -- Output results to Console
    print("------------------------------------------------")
    print("TRACKING RESULT: " .. #addedParts .. " parts matched criteria.")
    for _, part in ipairs(addedParts) do
        print(string.format("Found: %s | Size: %s | Color: %s | Parent: %s", part.Name, tostring(part.Size), part.BrickColor.Name, part.Parent.Name))
    end
    print("------------------------------------------------")
    
    UILibrary:Notify({
        Title = "Tracking Ended",
        Content = "Found " .. #addedParts .. " parts. Check F9 console.",
        Duration = 3
    })
end, nil, "main.track_specific_parts_key")


Tabs.Main:CreateKeybind("Track Parts (2s)", function()
    UILibrary:Notify({
        Title = "Tracking Started",
        Content = "Tracking workspace parts for 2 seconds...",
        Duration = 2
    })
    
    local addedParts = {}
    local connection = workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") and not descendant.Parent:FindFirstChild("Humanoid") then
            table.insert(addedParts, descendant)
        end
    end)

    task.wait(2)
    connection:Disconnect()

    print("------------------------------------------------")
    print("TRACKING RESULT: " .. #addedParts .. " parts found.")
    for _, part in ipairs(addedParts) do
        print("Name:", part.Name)
        print("Parent:", part.Parent)
        print("Transparency:", part.Transparency)
        print("Size:", part.Size)
        print("Color:", part.Color)
        print("BrickColor:", part.BrickColor)
        print("CanCollide:", part.CanCollide)
        print("Anchored:", part.Anchored)
        print("CollisionGroup:", part.CollisionGroup)
        local tags = game:GetService("CollectionService"):GetTags(part)
        print("Tags:", table.concat(tags, ", "))
        print("------------------------------------------------")
    end
    
    UILibrary:Notify({
        Title = "Tracking Ended",
        Content = "Check console (F9) for details.",
        Duration = 3
    })
end, nil, "main.track_parts_key")

Tabs.Main:CreateKeybind("Print Touching Parts", function()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if not character then return end
    
    local touchingParts = {}
    local checkedParts = {}
    
    for _, limb in pairs(character:GetDescendants()) do
        if limb:IsA("BasePart") then
            local parts = workspace:GetPartsInPart(limb)
            for _, part in pairs(parts) do
                if not part:IsDescendantOf(character) and not checkedParts[part] then
                    checkedParts[part] = true
                    table.insert(touchingParts, part)
                end
            end
        end
    end

    print("------------------------------------------------")
    print("TOUCHING RESULT: " .. #touchingParts .. " parts found.")
    for _, part in ipairs(touchingParts) do
        print("Name:", part.Name)
        print("Parent:", part.Parent)
        print("Transparency:", part.Transparency)
        print("Size:", part.Size)
        print("Color:", part.Color)
        print("BrickColor:", part.BrickColor)
        print("CanCollide:", part.CanCollide)
        print("Anchored:", part.Anchored)
        print("CollisionGroup:", part.CollisionGroup)
        local tags = game:GetService("CollectionService"):GetTags(part)
        print("Tags:", table.concat(tags, ", "))
        print("------------------------------------------------")
    end
    
    UILibrary:Notify({
        Title = "Scan Complete",
        Content = "Found " .. #touchingParts .. " touching parts. Check F9.",
        Duration = 3
    })
end, nil, "main.print_touching_parts_key")
