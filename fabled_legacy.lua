


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
    if bColor == "Bright red" or bColor == "Really red" or bColor == "Tawny" then
        return 0.5
    end
    return 2.0
end

-- // TIMELINE-BASED SAFETY CHECK // --
local function IsSafeAtTime(position, arrivalDelay)
    local checkTime = os.clock() + arrivalDelay
    
    for part, data in pairs(ActiveThreats) do
        if part and part.Parent then
            -- Only consider the attack "Dangerous" if our arrival time 
            -- falls BETWEEN the ImpactTime and the EndTime.
            if checkTime >= data.ImpactTime and checkTime <= data.EndTime then
                local relPos = part.CFrame:PointToObjectSpace(position)
                local size = part.Size / 2 + Vector3.new(4, 4, 4) -- Safety buffer
                
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
        ActiveThreats[descendant] = {
            Instance = descendant,
            StartTime = os.clock(),
            Connection = conn
        }
    end
    HighlightPart(descendant)
end

-- // OPTIMIZED SAFE POINT GENERATOR // --
local function GetBestSafePoint(hrp)
    if not StartPosition then StartPosition = hrp.Position end

    -- 1. Path Persistence: If current destination is still safe and valid, stick to it
    if CurrentSafePoint and (CurrentSafePoint - StartPosition).Magnitude <= 70 and IsSafeAtTime(CurrentSafePoint, 0.5) then
        return CurrentSafePoint
    end

    local candidates = {}
    local hrpPos = hrp.Position
    local right = hrp.CFrame.RightVector
    local forward = hrp.CFrame.LookVector

    -- 2. Immediate Sidestep Candidates (Highest Priority)
    local sideOffsets = {8, 15, -8, -15}
    for _, offset in ipairs(sideOffsets) do
        table.insert(candidates, hrpPos + (right * offset))
    end

    -- 3. Backstep and Diagonal Candidates
    local backDir = -forward
    local diagonalOffsets = {10, 15}
    for _, d in ipairs(diagonalOffsets) do
        table.insert(candidates, hrpPos + (backDir * d)) -- Straight back
        table.insert(candidates, hrpPos + (backDir + right).Unit * d) -- Back-right
        table.insert(candidates, hrpPos + (backDir - right).Unit * d) -- Back-left
    end

    -- 4. Single-Pass Selection (Replaces table.sort for performance)
    local bestPoint = nil
    local bestScore = -math.huge

    for _, point in ipairs(candidates) do
        if (point - StartPosition).Magnitude <= 70 then
            -- Safety Check
            if IsSafeAtTime(point, 0.6) then
                local dist = (point - hrpPos).Magnitude
                local dirToPoint = (point - hrpPos).Unit
                local dotRight = math.abs(right:Dot(dirToPoint))
                local dotForward = forward:Dot(dirToPoint)

                -- Score: Prefer sidestepping (high dotRight) over backpedaling (low/negative dotForward)
                local score = -dist + (dotRight * 10) - (dotForward * 5)
                if score > bestScore then
                    bestScore = score
                    bestPoint = point
                end
            end
        end
    end

    CurrentSafePoint = bestPoint or StartPosition
    return CurrentSafePoint
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
        
        local MovingToPoint = false
        local MoveIssuedTime = 0
        local LastTargetPoint = nil
        
        -- Throttling variables
        local lastMathUpdate = 0
        local lastEnemyUpdate = 0
        
        -- // REWRITTEN DODGE LOOP // --
        -- // UPDATED LIVE DODGE LOOP WITH SHORTEST-PATH LOGIC // --
        local lastLogicTick = 0
        DodgeLoop = RunService.Heartbeat:Connect(function()
            local currentTime = os.clock()
            if currentTime - lastLogicTick < 0.033 then return end 
            lastLogicTick = currentTime

            local character = Player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChild("Humanoid")
            if not hrp or not humanoid then return end

            local inDanger = false
            local SlashDetected = false
            local currentThreat = nil

            for part, data in pairs(ActiveThreats) do
                if part and part.Parent then
                    local relPos = part.CFrame:PointToObjectSpace(hrp.Position)
                    local halfSize = part.Size / 2
                    local margin = 5 
                    
                    local isInside = math.abs(relPos.X) < (halfSize.X + margin) and 
                                    math.abs(relPos.Z) < (halfSize.Z + margin) and
                                    math.abs(relPos.Y) < (halfSize.Y + margin)

                    if isInside then
                        local bColor = part.BrickColor.Name
                        local age = currentTime - data.StartTime
                        
                        -- Check for "Blueish" attacks specifically (often have faster or unique timing)
                        local isBlue = bColor:find("blue") or bColor:find("green")
                        local isFastTrack = (bColor == "Bright red" or bColor == "Really red" or bColor == "Tawny" or isBlue)
                        
                        -- Reduced delay for blue attacks to ensure we react before they pulse
                        local activationDelay = isFastTrack and 0.05 or 0.8
                        
                        if age >= activationDelay then
                            inDanger = true
                            currentThreat = part
                            if part.Name:lower():find("slash") or part.Size.Y < 7 then 
                                SlashDetected = true 
                            end
                            break 
                        end
                    end
                end
            end

            if inDanger and currentThreat then
                if SlashDetected then humanoid.Jump = true end
                
                local cf = currentThreat.CFrame
                local size = currentThreat.Size
                local relPos = cf:PointToObjectSpace(hrp.Position)
                
                -- DETERMINING THE SHORTEST EXIT (The "Side that isn't so long")
                -- Compare X and Z dimensions to find the "thickness" of the attack
                local bestPoint
                local safetyBuffer = 10 -- Extra studs to ensure we clear the zone

                if size.X < size.Z then
                    -- The attack is "long" on the Z axis (like a beam pointing forward)
                    -- We MUST exit via the X axis (sidestep)
                    local sideX = relPos.X >= 0 and 1 or -1
                    bestPoint = cf:PointToWorldSpace(Vector3.new((size.X/2 + safetyBuffer) * sideX, 0, relPos.Z))
                else
                    -- The attack is "wide" on the X axis (like a horizontal sweep)
                    -- We MUST exit via the Z axis (backstep/forward step)
                    local sideZ = relPos.Z >= 0 and 1 or -1
                    bestPoint = cf:PointToWorldSpace(Vector3.new(relPos.X, 0, (size.Z/2 + safetyBuffer) * sideZ))
                end

                if bestPoint then
                    humanoid:MoveTo(bestPoint)
                    CurrentSafePoint = bestPoint
                end
            else
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
