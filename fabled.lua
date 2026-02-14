-- https://github.com/x2Swiftz/UI-Library/blob/main/Libraries/FluentUI-Example.lua

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

-- // BUTTONS // --

-- // BUTTONS // --


local DodgeEnabled = false
local DodgeConnection = nil
local DodgeLoop = nil

-- // CONFIGURATION // --
local VALID_NAMES = {["part"] = true, ["mage"] = true, ["slash"] = true, ["hitbox"] = true, ["indicator"] = true}
local VALID_COLORS = {
    ["Faded green"] = true,
    ["Medium bluish green"] = true,
    ["Med. bluish green"] = true, -- For compatibility
    ["Bright red"] = true,
    ["Really red"] = true,
    ["Pastel blue-green"] = true,
    ["Medium stone grey"] = true,
    ["Tawny"] = true
}
local ActiveThreats = {}

-- // ACCURATE DISTANCE MATH // --
-- Calculates distance to the nearest edge of a part (essential for long beams)
local function GetDistanceToPart(hrp, part)
    local relPos = part.CFrame:PointToObjectSpace(hrp.Position)
    local halfSize = part.Size / 2
    local closestPoint = Vector3.new(
        math.clamp(relPos.X, -halfSize.X, halfSize.X),
        math.clamp(relPos.Y, -halfSize.Y, halfSize.Y),
        math.clamp(relPos.Z, -halfSize.Z, halfSize.Z)
    )
    return (relPos - closestPoint).Magnitude
end

local function IsPositionSafe(position)
    for part, _ in pairs(ActiveThreats) do
        if part and part.Parent then
            local relPos = part.CFrame:PointToObjectSpace(position)
            local size = part.Size / 2 + Vector3.new(2, 2, 2) -- Safety buffer
            if math.abs(relPos.X) < size.X and math.abs(relPos.Y) < size.Y and math.abs(relPos.Z) < size.Z then
                return false
            end
        end
    end
    return true
end

local function GetBestSafePoint(hrp)
    -- Find the closest threat to determine the best escape direction
    local closestPart = nil
    local minDist = math.huge
    
    for part, _ in pairs(ActiveThreats) do
        if part and part.Parent then
            local dist = (part.Position - hrp.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closestPart = part
            end
        end
    end
    
    if not closestPart then return hrp.Position end

    local cf = closestPart.CFrame
    local size = closestPart.Size
    local relPos = cf:PointToObjectSpace(hrp.Position)
    local halfSize = size / 2
    local safetyMargin = 4 -- Reduced margin for faster escape

    local candidates = {}
    
    -- Generate 4 cardinal exit points relative to the closest threat
    local signX = (relPos.X >= 0) and 1 or -1
    local signZ = (relPos.Z >= 0) and 1 or -1
    
    table.insert(candidates, cf:PointToWorldSpace(Vector3.new((halfSize.X + safetyMargin) * signX, relPos.Y, relPos.Z))) -- Closest X
    table.insert(candidates, cf:PointToWorldSpace(Vector3.new(relPos.X, relPos.Y, (halfSize.Z + safetyMargin) * signZ))) -- Closest Z
    table.insert(candidates, cf:PointToWorldSpace(Vector3.new(-(halfSize.X + safetyMargin) * signX, relPos.Y, relPos.Z))) -- Opposite X
    table.insert(candidates, cf:PointToWorldSpace(Vector3.new(relPos.X, relPos.Y, -(halfSize.Z + safetyMargin) * signZ))) -- Opposite Z

    table.sort(candidates, function(a, b)
        return (a - hrp.Position).Magnitude < (b - hrp.Position).Magnitude
    end)

    for _, point in ipairs(candidates) do
        if IsPositionSafe(point) then
            return point
        end
    end
    
    -- Fallback: Expanded Radial Search
    local radialCandidates = {}
    for r = 5, 50, 5 do -- More granular radius
        for angle = 0, 360, 15 do -- Higher precision (360 degrees)
            local rad = math.rad(angle)
            local offset = Vector3.new(math.cos(rad) * r, 0, math.sin(rad) * r)
            table.insert(radialCandidates, hrp.Position + offset)
        end
    end

    table.sort(radialCandidates, function(a, b)
        return (a - hrp.Position).Magnitude < (b - hrp.Position).Magnitude
    end)

    for _, point in ipairs(radialCandidates) do
        if IsPositionSafe(point) then
            return point
        end
    end

    return candidates[1] -- Desperate fallback
end

-- // VISUALIZER // --
local function HighlightPart(part)
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
local function ProcessPart(descendant)
    if not DodgeEnabled or not descendant:IsA("BasePart") then return end
    
    local nameLower = descendant.Name:lower()
    local bColor = descendant.BrickColor.Name

    -- 1. Identity & Color Checks
    if not VALID_NAMES[nameLower] or not VALID_COLORS[bColor] then return end
    if nameLower == "hitbox" and bColor == "Medium stone grey" then return end
    
    -- 2. Character Exclusion
    local model = descendant:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then return end

    -- Register Threat
    if not ActiveThreats[descendant] then
        local conn = descendant.AncestryChanged:Connect(function(_, parent)
            if not parent then ActiveThreats[descendant] = nil end
        end)
        ActiveThreats[descendant] = conn
    end

    -- 3. Visuals & Dodge
    HighlightPart(descendant)
end

-- // TOGGLE KEYBIND // --
Tabs.Main:CreateKeybind("Toggle Dodge & Visualizer", function()
    DodgeEnabled = not DodgeEnabled
    
    UILibrary:Notify({
        Title = "Auto Dodge System",
        Content = DodgeEnabled and "ENABLED - Scanning..." or "DISABLED",
        Duration = 3
    })

    if DodgeEnabled then
        for _, conn in pairs(ActiveThreats) do conn:Disconnect() end
        ActiveThreats = {}
        
        -- Initial Scan for parts already there
        for _, item in ipairs(workspace:GetDescendants()) do
            ProcessPart(item)
        end
        
        -- Start Listening for new parts
        DodgeConnection = workspace.DescendantAdded:Connect(ProcessPart)
        
        -- Continuous Dodge Loop (Faster Reflexes & Awareness)
        local lastMoveTime = 0
        DodgeLoop = RunService.Heartbeat:Connect(function()
            local character = Player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChild("Humanoid")
            if not hrp or not humanoid then return end

            local closestThreat = nil
            local closestDist = math.huge
            local sizeOfClosest = Vector3.new(0,0,0)
            local SlashDetected = false
            local sizeOfClosest = Vector3.new(0,0,0)
            local closestSize = Vector3.new(0, 0, 0)
            local safetyMargin = 2
            local sizeX = 0
            local sizeZ = 0
            local inDanger = false
            
            for part, _ in pairs(ActiveThreats) do
                if part and part.Parent then
                    local dist = (part.Position - hrp.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestSize = part.Size
                        closestThreat = part
                        sizeOfClosest = part.Size
                    end

                    local relPos = part.CFrame:PointToObjectSpace(hrp.Position)
                    local size = part.Size
                    local halfSize = size / 2
                    
                    -- Check if inside or near the hitbox (2 stud margin)
                    if math.abs(relPos.X) < (halfSize.X + safetyMargin) and 
                       math.abs(relPos.Y) < (halfSize.Y + safetyMargin) and 
                       math.abs(relPos.Z) < (halfSize.Z + safetyMargin) then
                        sizeX = halfSize.X
                        sizeZ = halfSize.Z
                        
                       inDanger = true
                    end
                end
            end

             -- Proactive Slash Dodge (Jump)
            for part, _ in pairs(ActiveThreats) do
                if part and part.Parent and part.Name:lower():find("slash") then
                    local dist = (part.Position - hrp.Position).Magnitude
                    if dist < 15 then
                       SlashDetected = true
                        break
                    end

                end
            end

            if inDanger and os.clock() - lastMoveTime > 0.05 then
                local safePoint = GetBestSafePoint(hrp)
                if SlashDetected == true then 
                       Vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        task.wait(0.1)
                        Vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end
                if safePoint then
                    humanoid:MoveTo(safePoint)
                    lastMoveTime = os.clock()
                end
            end
        end)
    else
        if DodgeConnection then
            DodgeConnection:Disconnect()
            DodgeConnection = nil
        end
        if DodgeLoop then
            DodgeLoop:Disconnect()
            DodgeLoop = nil
        end
         -- FULL DISCONNECT
        for _, conn in pairs(ActiveThreats) do conn:Disconnect() end
    end
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


-- Settings Tab
Tabs.Settings:CreateButton("Load Remotespy", function()
    loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-RemoteSpy-for-Xeno-and-Solara-32578"))()
end)

Tabs.Settings:CreateButton("Load DevEx", function()
    loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Dex-with-tags-78265"))()
end)
