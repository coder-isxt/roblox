


-- Its running too much backwards. And not even dodging anything at that time. It just runs. there is no logic for this.
-- It needs better logic in the dodging, and actually take use of safespots combined with the proactive dodging. It should also not just run backwards, but also sidestep and jump more intelligently.



-- // IMPORTS // --
local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/coder-isxt/roblox/refs/heads/main/library.lua"))()

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
Window = UILibrary:CreateWindow("Fabled Legacy")

Tabs = {
    Main = Window:CreateTab("Main"),
    Settings = Window:CreateTab("Settings"),
}

-- // NOTIFICATIONS AND PARAGRAPHS // --
UILibrary:Notify({
    Title = "Welcome " .. Player.DisplayName,
    Content = "Script Loaded!",
    Duration = 5
})

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

-- // ACCURATE DISTANCE MATH // --
local function GetDistanceToPart(posOrPart, part)
    local pos = posOrPart
    if typeof(posOrPart) ~= "Vector3" then
        pos = posOrPart.Position
    end
    local relPos = part.CFrame:PointToObjectSpace(pos)
    local halfSize = part.Size / 2
    local closestPoint = Vector3.new(
        math.clamp(relPos.X, -halfSize.X, halfSize.X),
        math.clamp(relPos.Y, -halfSize.Y, halfSize.Y),
        math.clamp(relPos.Z, -halfSize.Z, halfSize.Z)
    )
    return (relPos - closestPoint).Magnitude
end

local function GetAttackDuration(part)
    local bColor = part.BrickColor.Name
    -- Fast attacks (red / tawny) are short
    if bColor == "Bright red" or bColor == "Really red" or bColor == "Tawny" then
        return 0.5
    end
    -- Longer parts (wide/long sweep actors) should be considered longer duration
    local maxDim = math.max(part.Size.X, part.Size.Z)
    if maxDim > 18 then
        return 3.0
    end
    return 2.0
end

-- // TIMELINE-BASED SAFETY CHECK // --
local function IsSafeAtTime(position, arrivalDelay)
    local checkTime = os.clock() + arrivalDelay
    
    for part, data in pairs(ActiveThreats) do
        if part and part.Parent then
            -- Use stored Impact/End windows if available, otherwise fall back
            local impact = data.ImpactTime or data.StartTime or 0
            local fin = data.EndTime or (data.StartTime and data.StartTime + 1.0) or (impact + 1.0)

            if checkTime >= impact and checkTime <= fin then
                local relPos = part.CFrame:PointToObjectSpace(position)
                local extra = (data.IsLong and 8) or 4
                local size = part.Size / 2 + Vector3.new(extra, extra, extra) -- Safety buffer

                if math.abs(relPos.X) < size.X and 
                   math.abs(relPos.Z) < size.Z and 
                   math.abs(relPos.Y) < size.Y then
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
        local isLong = math.max(descendant.Size.X, descendant.Size.Z) > 14 or nameLower:find("slash")
        local isBlue = (bColor == "Medium bluish green" or bColor == "Med. bluish green" or bColor == "Pastel blue-green")

        ActiveThreats[descendant] = {
            Instance = descendant,
            StartTime = startT,
            ImpactTime = startT + 0.06, -- small reaction delay until the part becomes dangerous
            EndTime = startT + duration + (descendant.Size.Magnitude / 25),
            IsLong = isLong or isBlue,
            IsBlue = isBlue,
            LastPos = descendant.Position,
            Connection = conn
        }
    end
    HighlightPart(descendant)
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
        
        -- // REWRITTEN DODGE LOOP // --
        -- // UPDATED LIVE DODGE LOOP WITH SHORTEST-PATH LOGIC // --
        -- // MULTI-THREAT & SMART JUMP DODGE LOOP // --
        local lastLogicTick = 0
        DodgeLoop = RunService.Heartbeat:Connect(function()
            local currentTime = os.clock()
            if currentTime - lastLogicTick < 0.033 then return end 
            lastLogicTick = currentTime

            local character = Player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChild("Humanoid")
            if not hrp or not humanoid then return end

            -- Purge threats that no longer exist or have expired so dodging stops
            do
                local toRemove = {}
                for part, d in pairs(ActiveThreats) do
                    local gone = (not part) or (not part.Parent) or (not part:IsDescendantOf(workspace))
                    local expired = d.EndTime and (currentTime > d.EndTime + 0.25)
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
            
            -- 1. SCAN ALL ACTIVE HAZARDS
            for part, data in pairs(ActiveThreats) do
                if part and part.Parent then
                    local relPos = part.CFrame:PointToObjectSpace(hrp.Position)
                    local halfSize = part.Size / 2
                    -- Dynamic margin based on threat length
                    local dynExtra = (data.IsLong and 8) or 0
                    local margin = 4 + dynExtra

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
                            requiredAge = 0.12 -- bluish circles: respond a bit sooner but not instant
                        elseif isLong then
                            requiredAge = 0.14 -- react earlier for long sweeps
                        end

                        if age >= requiredAge then
                            table.insert(overlappingThreats, part)
                            -- Enhanced Jump Detection: Check name or thin vertical profile
                            if part.Name:lower():find("slash") then 
                                shouldJump = true 
                            end
                        end
                    end

                    -- Update velocity estimate for sweep prediction
                    do
                        local last = data.LastPos or part.Position
                        local dt = 0.033
                        local vel = (part.Position - last) / dt
                        data.Velocity = vel
                        data.LastPos = part.Position
                    end
                end
            end

            -- 2. REACTION LOGIC
            if #overlappingThreats > 0 then
                -- Execute Jump if a slash is detected
                if shouldJump then 
                    humanoid.Jump = true 
                end

                local bestPoint = nil
                local candidates = {}
                
                -- Generate potential exits for the "primary" threat (the first one)
                local primary = overlappingThreats[1]
                local cf = primary.CFrame
                local size = primary.Size
                local relPos = cf:PointToObjectSpace(hrp.Position)
                local primaryData = ActiveThreats[primary]
                local safetyBuffer = 12 + ((primaryData and primaryData.IsLong) and 8 or 0)

                -- Exit points based on shortest axis
                if size.X < size.Z then
                    table.insert(candidates, cf:PointToWorldSpace(Vector3.new(size.X/2 + safetyBuffer, 0, relPos.Z)))
                    table.insert(candidates, cf:PointToWorldSpace(Vector3.new(-(size.X/2 + safetyBuffer), 0, relPos.Z)))
                else
                    table.insert(candidates, cf:PointToWorldSpace(Vector3.new(relPos.X, 0, size.Z/2 + safetyBuffer)))
                    table.insert(candidates, cf:PointToWorldSpace(Vector3.new(relPos.X, 0, -(size.Z/2 + safetyBuffer))))
                end

                -- Predict sweep direction and offer perpendicular sidesteps
                local primaryVel = (primaryData and primaryData.Velocity) or Vector3.new()
                if primaryVel.Magnitude > 1 then
                    local sweepDir = primaryVel.Unit
                    local perp = Vector3.new(-sweepDir.Z, 0, sweepDir.X)
                    local offset = (math.max(size.X, size.Z) / 2) + safetyBuffer + 6
                    table.insert(candidates, cf.Position + perp * offset)
                    table.insert(candidates, cf.Position - perp * offset)
                    -- also add candidates relative to our position
                    table.insert(candidates, hrp.Position + perp * (offset * 0.8))
                    table.insert(candidates, hrp.Position - perp * (offset * 0.8))
                end

                -- Add conservative fallback candidates: move further back and sideways
                local backDir = -hrp.CFrame.LookVector
                local rightDir = hrp.CFrame.RightVector
                table.insert(candidates, hrp.Position + backDir * 22)
                table.insert(candidates, hrp.Position + backDir * 22 + rightDir * 15)
                table.insert(candidates, hrp.Position + backDir * 22 - rightDir * 15)

                -- 3. GLOBAL SAFETY TEST: Pick the point that is inside the FEWEST threats
                local bestHazardCount = math.huge
                local bestDist = math.huge

                for _, p in ipairs(candidates) do
                    -- Use stricter travel-time aware safety test: check further ahead
                    local dist = (p - hrp.Position).Magnitude
                    local travelTime = dist / math.max(humanoid.WalkSpeed, 6)
                    local arrivalDelay = travelTime + 0.15
                    
                    -- Check not just at arrival, but also 0.2 seconds after arrival
                    if not IsSafeAtTime(p, arrivalDelay) or not IsSafeAtTime(p, arrivalDelay + 0.2) then
                        continue
                    end

                    -- Count static overlaps at arrival as secondary metric (fewer is better)
                    local currentHazardCount = 0
                    for part, d in pairs(ActiveThreats) do
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

                if bestPoint then
                    humanoid:MoveTo(bestPoint)
                    CurrentSafePoint = bestPoint
                end
            else
                -- Completely safe? Stop moving.
                if CurrentSafePoint then
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
end)

Tabs.Main:CreateToggle("Dodge Debug", function(state)
    DodgeDebug = state
    UILibrary:Notify({ Title = "Debug Mode", Content = DodgeDebug and "Debug ON" or "Debug OFF", Duration = 2 })
    VisualsEnabled = state
end)

local AutoFaceEnabled = false
local AutoFaceConnection = nil

local function GetClosestEnemy(maxDist)
    local character = Player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local closestDist = maxDist or 300
    local closestEnemy = nil
    
    local targets = {}
    if workspace:FindFirstChild("Enemies") then 
        for _, v in ipairs(workspace.Enemies:GetChildren()) do table.insert(targets, v) end
    end
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then table.insert(targets, v) end
    end
    
    for _, model in ipairs(targets) do
        if model:IsA("Model") and model ~= character then
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
end)

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
                         Vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                         task.wait(0.05)
                         Vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    end
                    
                    local cdQ = Player:FindFirstChild("cooldownQ")
                    if cdQ and cdQ.Value == 0 then
                         Vim:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                         task.wait(0.05)
                         Vim:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                    end
                end
            end
        end)
    end
end)

Window:OnClose(function()
    DodgeEnabled = false
    AutoFaceEnabled = false
    AutoSkillsEnabled = false
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
end)


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
end)

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
end)
