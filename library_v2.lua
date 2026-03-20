local UILibrary = {}

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local FONT = Enum.Font.Gotham
local GUI_NAME = "XenoUILibraryV2"
local OPEN_DROPDOWNS = {}

local C = {
    Main = Color3.fromRGB(10, 14, 21),
    Top = Color3.fromRGB(11, 16, 24),
    Sidebar = Color3.fromRGB(10, 14, 21),
    SidebarActive = Color3.fromRGB(22, 31, 45),
    Panel = Color3.fromRGB(11, 16, 24),
    PanelInset = Color3.fromRGB(13, 19, 28),
    Control = Color3.fromRGB(20, 29, 41),
    ControlHover = Color3.fromRGB(25, 36, 50),
    ControlPress = Color3.fromRGB(30, 43, 60),
    Stroke = Color3.fromRGB(31, 42, 58),
    Accent = Color3.fromRGB(90, 182, 255),
    Text = Color3.fromRGB(224, 233, 248),
    SubText = Color3.fromRGB(140, 159, 187),
}

local function mk(className, props)
    local x = Instance.new(className)
    for k, v in pairs(props or {}) do
        x[k] = v
    end
    return x
end

local function corner(x, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 4)
    c.Parent = x
    return c
end

local function stroke(x, color, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or C.Stroke
    s.Thickness = 1
    s.Transparency = trans or 0.5
    s.Parent = x
    return s
end

local function tw(x, t, p)
    return TweenService:Create(x, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p)
end

local function safe(cb, ...)
    if typeof(cb) ~= "function" then
        return
    end
    local ok, err = pcall(cb, ...)
    if not ok then
        warn("[library_v2] callback error:", err)
    end
end

local function clamp(v, a, b)
    return math.max(a, math.min(b, v))
end

local function roundStep(v, s)
    if s <= 0 then
        return v
    end
    return math.floor((v / s) + 0.5) * s
end

local function closeDropdowns(except)
    for d in pairs(OPEN_DROPDOWNS) do
        if d ~= except and d.SetOpen then
            d:SetOpen(false)
        end
    end
end

local function keycode(v)
    if typeof(v) == "EnumItem" and v.EnumType == Enum.KeyCode then
        return v
    end
    return nil
end

local function guiParent()
    if typeof(gethui) == "function" then
        local ok, v = pcall(gethui)
        if ok and typeof(v) == "Instance" then
            return v
        end
    end
    local ok, cg = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and cg then
        return cg
    end
    local lp = Players.LocalPlayer
    if lp then
        return lp:FindFirstChildOfClass("PlayerGui")
    end
    return nil
end

local function protect(sg)
    if syn and typeof(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, sg)
    elseif typeof(protectgui) == "function" then
        pcall(protectgui, sg)
    end
end

local function track(conns, c)
    table.insert(conns, c)
    return c
end

local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

function UILibrary:GetSelectedPlayer()
    return self._selectedPlayer
end

function UILibrary:SetSelectedPlayer(player)
    self._selectedPlayer = player
end

function Window:IsVisible()
    return self.VisibleState == true
end

function Window:SetVisible(v)
    local shouldShow = v == true
    if self.VisibleState == shouldShow and (self.Main.Visible == shouldShow or shouldShow) then
        return
    end

    self.VisibleState = shouldShow
    self.Animating = true

    if self.AnimScaleTween then
        self.AnimScaleTween:Cancel()
    end
    if self.AnimFadeTween then
        self.AnimFadeTween:Cancel()
    end
    if self.AnimStrokeTween then
        self.AnimStrokeTween:Cancel()
    end

    if shouldShow then
        self.Main.Visible = true
        if self.MainScale then
            self.MainScale.Scale = 0.97
        end
        self.Main.BackgroundTransparency = 1
        if self.MainStroke then
            self.MainStroke.Transparency = 1
        end

        self.AnimScaleTween = tw(self.MainScale, 0.16, { Scale = 1 })
        self.AnimFadeTween = tw(self.Main, 0.16, { BackgroundTransparency = 0 })
        self.AnimStrokeTween = tw(self.MainStroke, 0.16, { Transparency = 0.2 })
        self.AnimScaleTween:Play()
        self.AnimFadeTween:Play()
        self.AnimStrokeTween:Play()
        task.delay(0.17, function()
            if self and self.Main and self.VisibleState then
                self.Animating = false
            end
        end)
    else
        self.AnimScaleTween = tw(self.MainScale, 0.14, { Scale = 0.97 })
        self.AnimFadeTween = tw(self.Main, 0.14, { BackgroundTransparency = 1 })
        self.AnimStrokeTween = tw(self.MainStroke, 0.14, { Transparency = 1 })
        self.AnimScaleTween:Play()
        self.AnimFadeTween:Play()
        self.AnimStrokeTween:Play()
        task.delay(0.15, function()
            if self and self.Main and not self.VisibleState then
                self.Main.Visible = false
                self.Animating = false
            end
        end)
    end
end

function Window:Toggle()
    self:SetVisible(not self:IsVisible())
end

function Window:SetTitle(s)
    self.TitleLabel.Text = tostring(s or "")
end

function Window:OnClose(cb)
    if typeof(cb) == "function" then
        table.insert(self.CloseCallbacks, cb)
    end
    return self
end

function Window:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    closeDropdowns(nil)
    for _, c in ipairs(self.Connections) do
        if c and c.Disconnect then
            pcall(function()
                c:Disconnect()
            end)
        end
    end
    table.clear(self.Connections)
    for _, cb in ipairs(self.CloseCallbacks) do
        safe(cb)
    end
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    if UILibrary._window == self then
        UILibrary._window = nil
        UILibrary._toastHost = nil
    end
end

function Window:SelectTab(tabOrName)
    local picked = nil
    if typeof(tabOrName) == "table" then
        picked = tabOrName
    else
        for _, t in ipairs(self.Tabs) do
            if t.Name == tostring(tabOrName) then
                picked = t
                break
            end
        end
    end
    if not picked then
        return nil
    end
    closeDropdowns(nil)
    self.ActiveTab = picked
    for _, t in ipairs(self.Tabs) do
        local active = t == picked
        t.Page.Visible = active
        t.Indicator.BackgroundTransparency = active and 0 or 1
        t.ButtonBack.BackgroundTransparency = active and 0.2 or 1
        t.Label.TextColor3 = active and C.Text or C.SubText
    end
    return picked
end

function Window:SwitchToTab(t)
    return self:SelectTab(t)
end

function Window:GetTabs()
    return self.Tabs
end

function Window:CreatePlayersCategory(options)
    if self.PlayerCategory then
        return self.PlayerCategory
    end

    options = options or {}
    local localPlayer = Players.LocalPlayer
    if not localPlayer then
        return nil
    end

    local playersTab = nil
    for _, existingTab in ipairs(self.Tabs) do
        if existingTab.Name == "Players" then
            playersTab = existingTab
            break
        end
    end
    if not playersTab then
        playersTab = self:CreateTab("Players")
    end

    local listSection = playersTab:CreateSection({ Name = "Player List", Side = "Left" })
    local optionsSection = playersTab:CreateSection({ Name = "Player Options", Side = "Right" })

    local listShell = mk("Frame", {
        Parent = listSection.Content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 300),
    })
    local listBack = mk("Frame", {
        Parent = listShell,
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
    })
    corner(listBack, 4)
    stroke(listBack, C.Stroke, 0.55)

    local listScroll = mk("ScrollingFrame", {
        Parent = listBack,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0, 6),
        Size = UDim2.new(1, -12, 1, -12),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Stroke,
    })
    mk("UIListLayout", {
        Parent = listScroll,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })

    local selectedPlayer = nil
    local targetMode = "Selected"
    local targetModes = { "Selected", "Others", "All" }

    local spectateTarget = nil
    local spectatePrevSubject = nil
    local spectateConnection = nil

    local trollMode = nil
    local trollConnection = nil
    local trollJumpTick = 0

    local flingConnection = nil
    local flingRestore = nil

    local selectedName = optionsSection:CreateLabel("Selected: None")
    local selectedUser = optionsSection:CreateLabel("@none")
    local targetModeButton = optionsSection:CreateButton("Target Mode: Selected")
    local spectateButton = optionsSection:CreateButton("Spectate")

    local headsitButton = nil
    local bangButton = nil
    local spinButton = nil
    local annoyButton = nil

    local function notify(title, content, duration)
        UILibrary:Notify({
            Title = title,
            Content = content,
            Duration = duration or 2.4,
        })
    end

    local function getLocalRoot()
        local character = localPlayer.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end

    local function getTargetRoot(player)
        local character = player and player.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end

    local function getTargetHum(player)
        local character = player and player.Character
        return character and character:FindFirstChildOfClass("Humanoid")
    end

    local function getOtherPlayersSorted()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer then
                table.insert(list, p)
            end
        end
        table.sort(list, function(a, b)
            return string.lower(a.Name) < string.lower(b.Name)
        end)
        return list
    end

    local function getTrollTarget()
        if not selectedPlayer or selectedPlayer == localPlayer then
            return nil
        end
        if selectedPlayer.Parent ~= Players then
            return nil
        end
        return selectedPlayer
    end

    local function refreshSpectateButtonText()
        local watchingSelected = spectateTarget and selectedPlayer and (spectateTarget == selectedPlayer)
        spectateButton:SetText(watchingSelected and "Stop Spectating" or "Spectate")
    end

    local function refreshTrollButtonTexts()
        if headsitButton then
            headsitButton:SetText((trollMode == "Headsit") and "Headsit: ON" or "Headsit: OFF")
        end
        if bangButton then
            bangButton:SetText((trollMode == "Bang") and "Bang: ON" or "Bang: OFF")
        end
        if spinButton then
            spinButton:SetText((trollMode == "Spin") and "Spin on Target: ON" or "Spin on Target: OFF")
        end
        if annoyButton then
            annoyButton:SetText((trollMode == "Annoy") and "Annoy Loop: ON" or "Annoy Loop: OFF")
        end
    end

    local function stopSpectate()
        if spectateConnection then
            spectateConnection:Disconnect()
            spectateConnection = nil
        end
        spectateTarget = nil
        local cam = workspace.CurrentCamera
        if cam then
            if spectatePrevSubject then
                cam.CameraSubject = spectatePrevSubject
            elseif localPlayer.Character then
                local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    cam.CameraSubject = hum
                end
            end
        end
        spectatePrevSubject = nil
        refreshSpectateButtonText()
    end

    local function startSpectate(targetPlayer)
        if not targetPlayer then
            return false
        end
        local targetHum = getTargetHum(targetPlayer)
        local cam = workspace.CurrentCamera
        if not targetHum or not cam then
            return false
        end

        stopSpectate()
        spectateTarget = targetPlayer
        spectatePrevSubject = cam.CameraSubject
        cam.CameraSubject = targetHum

        spectateConnection = RunService.Heartbeat:Connect(function()
            if not spectateTarget then
                return
            end
            local hum = getTargetHum(spectateTarget)
            local currentCam = workspace.CurrentCamera
            if not hum or not currentCam then
                stopSpectate()
                return
            end
            if currentCam.CameraSubject ~= hum then
                currentCam.CameraSubject = hum
            end
        end)

        refreshSpectateButtonText()
        return true
    end

    local function stopTrollLoop()
        trollMode = nil
        if trollConnection then
            trollConnection:Disconnect()
            trollConnection = nil
        end
        local localRoot = getLocalRoot()
        if localRoot then
            localRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
        refreshTrollButtonTexts()
    end

    local function setTrollLoopMode(modeName)
        if trollMode == modeName then
            stopTrollLoop()
            return false
        end

        trollMode = modeName
        if trollConnection then
            trollConnection:Disconnect()
            trollConnection = nil
        end

        trollConnection = RunService.Heartbeat:Connect(function()
            local targetPlayer = getTrollTarget()
            local localRoot = getLocalRoot()
            local localCharacter = localPlayer.Character
            local localHum = localCharacter and localCharacter:FindFirstChildOfClass("Humanoid")
            local targetRoot = getTargetRoot(targetPlayer)
            if not trollMode or not targetPlayer or not localRoot or not targetRoot or not localHum then
                return
            end

            local now = os.clock()
            if trollMode == "Headsit" then
                localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2.8, 0)
            elseif trollMode == "Bang" then
                local sway = math.sin(now * 10) * 0.32
                localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0.15, 1.05 + sway) * CFrame.Angles(0, math.rad(180), 0)
            elseif trollMode == "Spin" then
                local radius = 3.4
                local spinSpeed = 4.6
                local theta = now * spinSpeed
                local offset = Vector3.new(math.cos(theta) * radius, 1.9, math.sin(theta) * radius)
                local spinPos = targetRoot.Position + offset
                localRoot.CFrame = CFrame.lookAt(spinPos, targetRoot.Position)
                localRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            elseif trollMode == "Annoy" then
                local jitter = Vector3.new(
                    math.sin(now * 17) * 2.1,
                    2 + math.abs(math.cos(now * 11)) * 1.7,
                    math.cos(now * 19) * 2.1
                )
                local annoyPos = targetRoot.Position + jitter
                localRoot.CFrame = CFrame.lookAt(annoyPos, targetRoot.Position)
                localRoot.AssemblyLinearVelocity = Vector3.new(
                    math.sin(now * 21) * 35,
                    localRoot.AssemblyLinearVelocity.Y,
                    math.cos(now * 23) * 35
                )
                if now - trollJumpTick > 0.55 then
                    trollJumpTick = now
                    pcall(function()
                        localHum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end)
                end
            end
        end)

        refreshTrollButtonTexts()
        return true
    end

    local function getPlayableTargets()
        local candidates = {}
        if targetMode == "All" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= localPlayer then
                    table.insert(candidates, p)
                end
            end
        elseif targetMode == "Others" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= localPlayer then
                    table.insert(candidates, p)
                end
            end
        else
            if selectedPlayer and selectedPlayer ~= localPlayer then
                table.insert(candidates, selectedPlayer)
            end
        end

        local valid = {}
        for _, p in ipairs(candidates) do
            if p and p.Parent == Players and getTargetRoot(p) then
                table.insert(valid, p)
            end
        end
        return valid
    end

    local function applyToTargets(actionName, callback)
        local targets = getPlayableTargets()
        if #targets == 0 then
            notify(actionName, "No valid targets for mode: " .. targetMode, 2.8)
            return false
        end
        local successCount = 0
        for _, p in ipairs(targets) do
            local ok, result = pcall(callback, p)
            if ok and result ~= false then
                successCount = successCount + 1
            end
        end
        notify(actionName, "Applied to " .. tostring(successCount) .. "/" .. tostring(#targets) .. " target(s).", 2.5)
        return successCount > 0
    end

    local function teleportToPlayer(targetPlayer)
        local localRoot = getLocalRoot()
        local targetRoot = getTargetRoot(targetPlayer)
        if not localRoot or not targetRoot then
            return false
        end
        localRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
        return true
    end

    local function runPushLock(targetPlayer)
        local localRoot = getLocalRoot()
        local localHum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
        local targetRoot = getTargetRoot(targetPlayer)
        if not localRoot or not localHum or not targetRoot then
            return false
        end

        local endAt = os.clock() + 2.6
        while os.clock() < endAt do
            targetRoot = getTargetRoot(targetPlayer)
            if not targetRoot or not localRoot.Parent then
                break
            end
            localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
            localRoot.AssemblyLinearVelocity = targetRoot.CFrame.LookVector * 95
            RunService.Heartbeat:Wait()
        end
        return true
    end

    local function stopFlingAndRestore()
        if flingRestore then
            flingRestore()
        end
    end

    local function flingForFiveSeconds(targetPlayer)
        local localRoot = getLocalRoot()
        local targetRoot = getTargetRoot(targetPlayer)
        if not localRoot or not targetRoot then
            return false
        end

        stopFlingAndRestore()

        local startCFrame = localRoot.CFrame
        local oldLinear = localRoot.AssemblyLinearVelocity
        local oldAngular = localRoot.AssemblyAngularVelocity
        local endAt = os.clock() + 5
        local done = false

        local function restore()
            if done then
                return
            end
            done = true

            if flingConnection then
                flingConnection:Disconnect()
                flingConnection = nil
            end

            local currentRoot = getLocalRoot()
            if currentRoot and currentRoot.Parent then
                currentRoot.AssemblyAngularVelocity = oldAngular
                currentRoot.AssemblyLinearVelocity = oldLinear
                currentRoot.CFrame = startCFrame
            end
            flingRestore = nil
        end

        flingRestore = restore
        flingConnection = RunService.Heartbeat:Connect(function()
            local currentRoot = getLocalRoot()
            local currentTargetRoot = getTargetRoot(targetPlayer)
            if os.clock() >= endAt or not currentRoot or not currentTargetRoot then
                restore()
                return
            end

            local now = os.clock()
            local theta = now * 65
            local orbitOffset = Vector3.new(
                math.cos(theta) * 0.16,
                0.08 + math.sin(theta * 0.55) * 0.06,
                math.sin(theta) * 0.16
            )
            currentRoot.CFrame = currentTargetRoot.CFrame * CFrame.new(orbitOffset) * CFrame.Angles(0, theta * 1.4, 0)
            currentRoot.AssemblyAngularVelocity = Vector3.new(0, 900, 0)
            local tangential = Vector3.new(-math.sin(theta), 0, math.cos(theta))
            currentRoot.AssemblyLinearVelocity = (tangential * 340) + Vector3.new(0, 60, 0)
        end)

        task.delay(5.2, restore)
        return true
    end

    local function refreshTargetSelectionLabels()
        if selectedPlayer and selectedPlayer.Parent == Players then
            selectedName:Set("Selected: " .. tostring(selectedPlayer.DisplayName or selectedPlayer.Name))
            selectedUser:Set("@" .. tostring(selectedPlayer.Name))
        else
            selectedName:Set("Selected: None")
            selectedUser:Set("@none")
        end
        targetModeButton:SetText("Target Mode: " .. targetMode)
        refreshSpectateButtonText()
        refreshTrollButtonTexts()
    end

    local function setSelectedPlayer(player)
        if player == localPlayer then
            player = nil
        end
        if player and player.Parent ~= Players then
            player = nil
        end
        selectedPlayer = player
        UILibrary:SetSelectedPlayer(player)
        refreshTargetSelectionLabels()
    end

    local function refreshPlayerList()
        for _, child in ipairs(listScroll:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        local allPlayers = getOtherPlayersSorted()
        if #allPlayers == 0 then
            mk("TextLabel", {
                Parent = listScroll,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 26),
                Font = FONT,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = C.SubText,
                Text = "No players",
            })
            return
        end

        for _, p in ipairs(allPlayers) do
            local displayText = tostring(p.DisplayName or p.Name) .. "  @" .. tostring(p.Name)
            local row = mk("TextButton", {
                Parent = listScroll,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 30),
                Font = FONT,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = C.Text,
                AutoButtonColor = false,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = displayText,
                BackgroundColor3 = (selectedPlayer == p) and C.ControlPress or C.Control,
            })
            corner(row, 3)
            stroke(row, C.Stroke, 0.6)
            mk("UIPadding", {
                Parent = row,
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 6),
            })
            track(self.Connections, row.MouseEnter:Connect(function()
                if selectedPlayer ~= p then
                    tw(row, 0.1, { BackgroundColor3 = C.ControlHover }):Play()
                end
            end))
            track(self.Connections, row.MouseLeave:Connect(function()
                tw(row, 0.1, { BackgroundColor3 = (selectedPlayer == p) and C.ControlPress or C.Control }):Play()
            end))
            track(self.Connections, row.MouseButton1Click:Connect(function()
                setSelectedPlayer(p)
                refreshPlayerList()
            end))
        end
    end

    track(self.Connections, targetModeButton.Button.MouseButton1Click:Connect(function()
        local idx = 1
        for i, mode in ipairs(targetModes) do
            if mode == targetMode then
                idx = i
                break
            end
        end
        idx = idx + 1
        if idx > #targetModes then
            idx = 1
        end
        targetMode = targetModes[idx]
        refreshTargetSelectionLabels()
        notify("Target Mode", "Now using: " .. targetMode, 2.1)
    end))

    track(self.Connections, spectateButton.Button.MouseButton1Click:Connect(function()
        if not selectedPlayer then
            notify("Spectate", "Select a valid player first.", 2.4)
            return
        end
        if spectateTarget == selectedPlayer then
            stopSpectate()
            notify("Spectate", "Stopped spectating.")
            return
        end
        local ok = startSpectate(selectedPlayer)
        if ok then
            notify("Spectate", "Now watching " .. tostring(selectedPlayer.Name) .. ".")
        else
            notify("Spectate", "Target is not available.", 2.8)
        end
    end))

    optionsSection:CreateButton("Teleport To", function()
        local target = getTrollTarget()
        if not target then
            notify("Teleport", "Select a valid player first.", 2.4)
            return
        end
        local ok = teleportToPlayer(target)
        if ok then
            notify("Teleport", "Teleported to " .. tostring(target.Name) .. ".")
        else
            notify("Teleport", "Unable to teleport right now.", 2.8)
        end
    end)

    optionsSection:CreateButton("Bring", function()
        local targets = getPlayableTargets()
        if #targets == 0 then
            notify("Bring", "No valid targets for mode: " .. targetMode, 2.8)
        else
            notify("Bring", "Unavailable in client-only mode.", 2.8)
        end
    end)

    optionsSection:CreateButton("Push Lock", function()
        applyToTargets("Push Lock", function(targetPlayer)
            return runPushLock(targetPlayer)
        end)
    end)

    optionsSection:CreateButton("Fling", function()
        local target = getTrollTarget()
        if not target then
            notify("Fling", "Select a valid player first.", 2.4)
            return
        end
        local ok = flingForFiveSeconds(target)
        if ok then
            notify("Fling", "Flinging " .. tostring(target.Name) .. " for 5 seconds.", 2.3)
        else
            notify("Fling", "Could not fling target right now.", 2.8)
        end
    end)

    headsitButton = optionsSection:CreateButton("Headsit: OFF", function()
        local target = getTrollTarget()
        if not target then
            notify("Headsit", "Select a valid player first.", 2.4)
            return
        end
        local enabled = setTrollLoopMode("Headsit")
        notify("Headsit", enabled and ("Now headsitting " .. tostring(target.Name) .. ".") or "Headsit stopped.", 2.2)
    end)

    bangButton = optionsSection:CreateButton("Bang: OFF", function()
        local target = getTrollTarget()
        if not target then
            notify("Bang", "Select a valid player first.", 2.4)
            return
        end
        local enabled = setTrollLoopMode("Bang")
        notify("Bang", enabled and ("Now banging " .. tostring(target.Name) .. ".") or "Bang stopped.", 2.2)
    end)

    spinButton = optionsSection:CreateButton("Spin on Target: OFF", function()
        local target = getTrollTarget()
        if not target then
            notify("Spin", "Select a valid player first.", 2.4)
            return
        end
        local enabled = setTrollLoopMode("Spin")
        notify("Spin", enabled and ("Now spinning on " .. tostring(target.Name) .. ".") or "Spin stopped.", 2.2)
    end)

    annoyButton = optionsSection:CreateButton("Annoy Loop: OFF", function()
        local target = getTrollTarget()
        if not target then
            notify("Annoy", "Select a valid player first.", 2.4)
            return
        end
        local enabled = setTrollLoopMode("Annoy")
        notify("Annoy", enabled and ("Now annoying " .. tostring(target.Name) .. ".") or "Annoy loop stopped.", 2.2)
    end)

    optionsSection:CreateButton("Refresh Player List", function()
        refreshPlayerList()
    end)

    track(self.Connections, Players.PlayerAdded:Connect(function()
        refreshPlayerList()
    end))
    track(self.Connections, Players.PlayerRemoving:Connect(function(leavingPlayer)
        if selectedPlayer and leavingPlayer == selectedPlayer then
            selectedPlayer = nil
            stopTrollLoop()
        end
        if spectateTarget and leavingPlayer == spectateTarget then
            stopSpectate()
        end
        refreshTargetSelectionLabels()
        refreshPlayerList()
    end))

    self:OnClose(function()
        stopSpectate()
        stopTrollLoop()
        stopFlingAndRestore()
    end)

    setSelectedPlayer(UILibrary:GetSelectedPlayer())
    refreshPlayerList()
    refreshTargetSelectionLabels()

    self.PlayerCategory = {
        Tab = playersTab,
        PlayerListSection = listSection,
        OptionsSection = optionsSection,
        RefreshPlayerList = refreshPlayerList,
        GetSelectedPlayer = function()
            return selectedPlayer
        end,
        SetSelectedPlayer = function(_, player)
            setSelectedPlayer(player)
            refreshPlayerList()
        end,
    }

    return self.PlayerCategory
end

local function controlShell(section, h)
    return mk("Frame", {
        Parent = section.Content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, h),
    })
end

local function controlBack(parent, h)
    local b = mk("Frame", {
        Parent = parent,
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, h),
    })
    corner(b, 4)
    stroke(b, C.Stroke, 0.55)
    return b
end

local function asOptions(list)
    local out = {}
    for _, v in ipairs(list or {}) do
        table.insert(out, tostring(v))
    end
    return out
end

function Section:CreateButton(a, b)
    local text, cb
    if typeof(a) == "table" then
        text = tostring(a.Name or a.Text or "Button")
        cb = a.Callback or b
    else
        text = tostring(a or "Button")
        cb = b
    end

    local shell = controlShell(self, 34)
    local btn = mk("TextButton", {
        Parent = shell,
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        AutoButtonColor = false,
        Font = FONT,
        TextSize = 13,
        TextColor3 = C.Text,
        Text = text,
    })
    corner(btn, 4)
    stroke(btn, C.Stroke, 0.55)

    track(self.Window.Connections, btn.MouseEnter:Connect(function()
        tw(btn, 0.1, { BackgroundColor3 = C.ControlHover }):Play()
    end))
    track(self.Window.Connections, btn.MouseLeave:Connect(function()
        tw(btn, 0.1, { BackgroundColor3 = C.Control }):Play()
    end))
    track(self.Window.Connections, btn.MouseButton1Down:Connect(function()
        tw(btn, 0.05, { BackgroundColor3 = C.ControlPress }):Play()
    end))
    track(self.Window.Connections, btn.MouseButton1Click:Connect(function()
        safe(cb)
    end))

    return {
        Frame = shell,
        Button = btn,
        SetText = function(_, t)
            btn.Text = tostring(t or "")
        end,
        Fire = function()
            safe(cb)
        end,
    }
end

function Section:CreateToggle(a, b, c)
    local text, default, cb
    if typeof(a) == "table" then
        text = tostring(a.Name or a.Text or "Toggle")
        default = a.CurrentValue == true or a.Default == true
        cb = a.Callback or b
    else
        text = tostring(a or "Toggle")
        default = c == true
        cb = b
    end

    local value = default
    local shell = controlShell(self, 34)
    local back = controlBack(shell, 34)

    local box = mk("Frame", {
        Parent = back,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 9, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(9, 14, 22),
        BorderSizePixel = 0,
    })
    corner(box, 3)
    stroke(box, C.Stroke, 0.45)

    mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -38, 1, 0),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = text,
    })

    local hit = mk("TextButton", {
        Parent = back,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
    })

    local controller = { Frame = shell }
    function controller:Set(v, skip)
        value = v == true
        tw(box, 0.1, { BackgroundColor3 = value and C.Accent or Color3.fromRGB(9, 14, 22) }):Play()
        if not skip then
            safe(cb, value)
        end
    end
    function controller:Get()
        return value
    end

    track(self.Window.Connections, hit.MouseButton1Click:Connect(function()
        controller:Set(not value)
    end))
    track(self.Window.Connections, back.MouseEnter:Connect(function()
        tw(back, 0.1, { BackgroundColor3 = C.ControlHover }):Play()
    end))
    track(self.Window.Connections, back.MouseLeave:Connect(function()
        tw(back, 0.1, { BackgroundColor3 = C.Control }):Play()
    end))

    controller:Set(value, true)
    return controller
end
function Section:CreateSlider(a, b, c, d, e)
    local name, minV, maxV, defV, step, suf, cb
    if typeof(a) == "table" then
        name = tostring(a.Name or a.Text or "Slider")
        if typeof(a.Range) == "table" then
            minV = tonumber(a.Range[1]) or 0
            maxV = tonumber(a.Range[2]) or 100
        else
            minV = tonumber(a.Min) or 0
            maxV = tonumber(a.Max) or 100
        end
        defV = tonumber(a.CurrentValue) or tonumber(a.Default) or minV
        step = tonumber(a.Increment) or 1
        suf = tostring(a.Suffix or "")
        cb = a.Callback or e
    else
        name = tostring(a or "Slider")
        minV = tonumber(b) or 0
        maxV = tonumber(c) or 100
        defV = tonumber(d) or minV
        step = 1
        suf = ""
        cb = e
    end
    if minV > maxV then
        minV, maxV = maxV, minV
    end
    local value = roundStep(clamp(defV, minV, maxV), step)

    local shell = controlShell(self, 52)
    local back = controlBack(shell, 52)
    mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 4),
        Size = UDim2.new(1, -70, 0, 16),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = name,
    })
    local val = mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -64, 0, 4),
        Size = UDim2.new(0, 58, 0, 16),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = C.SubText,
        Text = "",
    })
    local bar = mk("Frame", {
        Parent = back,
        BackgroundColor3 = Color3.fromRGB(8, 12, 20),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 1, -14),
        Size = UDim2.new(1, -20, 0, 6),
    })
    corner(bar, 99)
    local fill = mk("Frame", {
        Parent = bar,
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
    })
    corner(fill, 99)
    local knob = mk("Frame", {
        Parent = bar,
        BackgroundColor3 = Color3.fromRGB(235, 243, 255),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 10, 0, 10),
    })
    corner(knob, 99)

    local drag = false
    local controller = { Frame = shell }
    local function draw()
        local alpha = (maxV == minV) and 0 or ((value - minV) / (maxV - minV))
        alpha = clamp(alpha, 0, 1)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        val.Text = tostring(value) .. suf
    end
    function controller:Set(v, skip)
        value = roundStep(clamp(tonumber(v) or minV, minV, maxV), step)
        draw()
        if not skip then
            safe(cb, value)
        end
    end
    function controller:Get()
        return value
    end
    local function at(x)
        local a = clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        controller:Set(minV + ((maxV - minV) * a))
    end
    track(self.Window.Connections, bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            at(i.Position.X)
        end
    end))
    track(self.Window.Connections, UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            at(i.Position.X)
        end
    end))
    track(self.Window.Connections, UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = false
        end
    end))
    draw()
    return controller
end

function Section:CreateDropdown(a, b, c, d)
    local name, opts, cur, multi, cb
    if typeof(a) == "table" then
        name = tostring(a.Name or a.Text or "Dropdown")
        opts = asOptions(a.Options or a.Values or {})
        cur = a.CurrentOption
        multi = a.MultipleOptions == true
        cb = a.Callback or d
    else
        name = tostring(a or "Dropdown")
        opts = asOptions(b or {})
        cur = c
        multi = false
        cb = d
    end

    local chosen = nil
    local map = {}
    local shell = controlShell(self, 34)
    shell.ClipsDescendants = true
    local back = controlBack(shell, 34)

    mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -36, 1, 0),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = name,
    })
    local valueLbl = mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -36, 1, 0),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = C.SubText,
        Text = "",
    })
    local arrow = mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -18, 0, 0),
        Size = UDim2.new(0, 12, 1, 0),
        Font = FONT,
        TextSize = 13,
        TextColor3 = C.SubText,
        Text = "v",
    })
    local hit = mk("TextButton", {
        Parent = back,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
    })
    local menu = mk("Frame", {
        Parent = shell,
        BackgroundColor3 = Color3.fromRGB(12, 18, 28),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
    })
    corner(menu, 4)
    stroke(menu, C.Stroke, 0.55)
    mk("UIPadding", {
        Parent = menu,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
    })
    mk("UIListLayout", {
        Parent = menu,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })

    local controller = { Frame = shell, Open = false }
    local function multiList()
        local t = {}
        for _, o in ipairs(opts) do
            if map[o] then
                table.insert(t, o)
            end
        end
        return t
    end
    local function showText()
        if multi then
            local t = multiList()
            if #t == 0 then
                valueLbl.Text = "None"
            elseif #t <= 2 then
                valueLbl.Text = table.concat(t, ", ")
            else
                valueLbl.Text = tostring(#t) .. " selected"
            end
        else
            valueLbl.Text = chosen or "None"
        end
    end
    local function rebuild()
        for _, ch in ipairs(menu:GetChildren()) do
            if ch:IsA("TextButton") then
                ch:Destroy()
            end
        end
        for i, o in ipairs(opts) do
            local btt = mk("TextButton", {
                Parent = menu,
                BackgroundColor3 = C.Control,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 24),
                AutoButtonColor = false,
                Font = FONT,
                TextSize = 12,
                TextColor3 = C.Text,
                Text = o,
                LayoutOrder = i,
            })
            corner(btt, 4)
            stroke(btt, C.Stroke, 0.6)
            local function paint()
                local on = multi and map[o] or (chosen == o)
                btt.BackgroundColor3 = on and C.ControlPress or C.Control
            end
            paint()
            track(self.Window.Connections, btt.MouseButton1Click:Connect(function()
                if multi then
                    map[o] = not map[o]
                    paint()
                    showText()
                    safe(cb, multiList())
                else
                    chosen = o
                    showText()
                    safe(cb, chosen)
                    controller:SetOpen(false)
                    rebuild()
                end
            end))
        end
    end
    function controller:SetOpen(v)
        local open = v == true
        if self.Open == open then
            return
        end
        self.Open = open
        if open then
            closeDropdowns(self)
            OPEN_DROPDOWNS[self] = true
            menu.Visible = true
            arrow.Text = "^"
            local h = (#opts * 28) + 10
            tw(shell, 0.12, { Size = UDim2.new(1, 0, 0, 34 + 6 + h) }):Play()
            tw(menu, 0.12, { Size = UDim2.new(1, 0, 0, h) }):Play()
        else
            OPEN_DROPDOWNS[self] = nil
            arrow.Text = "v"
            tw(shell, 0.12, { Size = UDim2.new(1, 0, 0, 34) }):Play()
            tw(menu, 0.1, { Size = UDim2.new(1, 0, 0, 0) }):Play()
            task.delay(0.1, function()
                if not self.Open and menu.Parent then
                    menu.Visible = false
                end
            end)
        end
    end
    function controller:SetValues(v)
        opts = asOptions(v)
        if not multi then
            local ok = false
            for _, o in ipairs(opts) do
                if o == chosen then
                    ok = true
                    break
                end
            end
            if not ok then
                chosen = opts[1]
            end
        else
            local keep = {}
            for _, o in ipairs(opts) do
                if map[o] then
                    keep[o] = true
                end
            end
            map = keep
        end
        showText()
        rebuild()
    end
    function controller:SetValue(v, skip)
        if multi then
            if typeof(v) == "table" then
                table.clear(map)
                for _, o in ipairs(v) do
                    map[tostring(o)] = true
                end
                showText()
                rebuild()
                if not skip then
                    safe(cb, multiList())
                end
            end
        else
            local target = tostring(v or "")
            local found = false
            for _, o in ipairs(opts) do
                if o == target then
                    found = true
                    break
                end
            end
            chosen = found and target or opts[1]
            showText()
            rebuild()
            if not skip then
                safe(cb, chosen)
            end
        end
    end
    function controller:GetValue()
        return multi and multiList() or chosen
    end
    controller.Set = controller.SetValue
    controller.Refresh = controller.SetValues

    track(self.Window.Connections, hit.MouseButton1Click:Connect(function()
        controller:SetOpen(not controller.Open)
    end))

    rebuild()
    if multi then
        if typeof(cur) == "table" then
            controller:SetValue(cur, true)
        else
            showText()
        end
    else
        if cur ~= nil then
            controller:SetValue(cur, true)
        elseif #opts > 0 then
            controller:SetValue(opts[1], true)
        else
            showText()
        end
    end
    return controller
end
function Section:CreateInput(a, b, c)
    local name, ph, def, cb, clear
    if typeof(a) == "table" then
        name = tostring(a.Name or a.Text or "Input")
        ph = tostring(a.PlaceholderText or "")
        def = tostring(a.CurrentValue or a.Default or "")
        cb = a.Callback or b
        clear = a.RemoveTextAfterFocusLost == true
    else
        name = tostring(a or "Input")
        ph = ""
        def = tostring(c or "")
        cb = b
        clear = false
    end

    local shell = controlShell(self, 34)
    local back = controlBack(shell, 34)
    mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.46, 0, 1, 0),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = name,
    })
    local inBack = mk("Frame", {
        Parent = back,
        BackgroundColor3 = Color3.fromRGB(8, 12, 20),
        BorderSizePixel = 0,
        Position = UDim2.new(0.48, 0, 0.5, -11),
        Size = UDim2.new(0.52, -10, 0, 22),
    })
    corner(inBack, 3)
    stroke(inBack, C.Stroke, 0.6)
    local box = mk("TextBox", {
        Parent = inBack,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        PlaceholderColor3 = C.SubText,
        PlaceholderText = ph,
        Text = def,
        ClearTextOnFocus = false,
    })
    local controller = { Frame = shell }
    function controller:SetValue(v, skip)
        box.Text = tostring(v or "")
        if not skip then
            safe(cb, box.Text)
        end
    end
    function controller:GetValue()
        return box.Text
    end
    controller.Set = controller.SetValue
    controller.Get = controller.GetValue
    track(self.Window.Connections, box.FocusLost:Connect(function(enter)
        safe(cb, box.Text, enter)
        if clear then
            box.Text = ""
        end
    end))
    return controller
end

function Section:CreateTextbox(...)
    return self:CreateInput(...)
end

function Section:CreateKeybind(a, b, c)
    local name, cb, def
    if typeof(a) == "table" then
        name = tostring(a.Name or a.Text or "Keybind")
        cb = a.Callback or b
        def = keycode(a.CurrentKeybind or a.Default or a.Key)
    else
        name = tostring(a or "Keybind")
        cb = b
        def = keycode(c)
    end
    local bound = def or Enum.KeyCode.Unknown
    local listening = false

    local shell = controlShell(self, 34)
    local back = controlBack(shell, 34)
    mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.55, 0, 1, 0),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = name,
    })
    local btn = mk("TextButton", {
        Parent = back,
        BackgroundColor3 = Color3.fromRGB(8, 12, 20),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -124, 0.5, -11),
        Size = UDim2.new(0, 114, 0, 22),
        AutoButtonColor = false,
        Font = FONT,
        TextSize = 12,
        TextColor3 = C.SubText,
        Text = "",
    })
    corner(btn, 3)
    stroke(btn, C.Stroke, 0.6)

    local function keyText(k)
        return (k == Enum.KeyCode.Unknown) and "None" or k.Name
    end

    local controller = { Frame = shell }
    function controller:SetValue(v, skip)
        local k = keycode(v)
        if not k then
            return
        end
        bound = k
        btn.Text = keyText(k)
        if not skip then
            safe(cb, bound, true)
        end
    end
    function controller:GetValue()
        return bound
    end
    controller.Set = controller.SetValue
    controller.Get = controller.GetValue
    controller:SetValue(bound, true)

    track(self.Window.Connections, btn.MouseButton1Click:Connect(function()
        listening = true
        btn.Text = "..."
    end))
    track(self.Window.Connections, UIS.InputBegan:Connect(function(i, gpe)
        if gpe or i.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if listening then
            listening = false
            controller:SetValue(i.KeyCode, false)
            return
        end
        if bound ~= Enum.KeyCode.Unknown and i.KeyCode == bound then
            safe(cb, bound, false)
        end
    end))
    return controller
end

function Section:CreateLabel(text)
    local shell = controlShell(self, 24)
    local lbl = mk("TextLabel", {
        Parent = shell,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = FONT,
        TextSize = 13,
        TextColor3 = C.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(text or ""),
    })
    return {
        Frame = shell,
        Label = lbl,
        Set = function(_, v)
            lbl.Text = tostring(v or "")
        end,
    }
end

function Section:CreateParagraph(a, b)
    local title, content
    if typeof(a) == "table" then
        title = tostring(a.Title or "Paragraph")
        content = tostring(a.Content or "")
    else
        title = tostring(a or "Paragraph")
        content = tostring(b or "")
    end

    local shell = mk("Frame", {
        Parent = self.Content,
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    corner(shell, 4)
    stroke(shell, C.Stroke, 0.55)
    mk("UIPadding", {
        Parent = shell,
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    })
    local t = mk("TextLabel", {
        Parent = shell,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = title,
    })
    local cLbl = mk("TextLabel", {
        Parent = shell,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = FONT,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = C.SubText,
        Text = content,
    })
    return {
        Frame = shell,
        Set = function(_, nt, nc)
            t.Text = tostring(nt or t.Text)
            cLbl.Text = tostring(nc or cLbl.Text)
        end,
    }
end

function Tab:_column(side)
    local s = string.lower(tostring(side or "left"))
    return (s == "right" or s == "r") and self.Right or self.Left
end

function Tab:CreateSection(a, b)
    local name, side
    if typeof(a) == "table" then
        name = tostring(a.Name or a.Title or "Section")
        side = tostring(a.Side or "Left")
    else
        name = tostring(a or "Section")
        side = tostring(b or "Left")
    end

    local frame = mk("Frame", {
        Name = name .. "_Section",
        Parent = self:_column(side),
        BackgroundColor3 = C.PanelInset,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    corner(frame, 4)
    stroke(frame, C.Stroke, 0.5)
    mk("UIPadding", {
        Parent = frame,
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    })
    mk("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.SubText,
        Text = name,
    })
    local content = mk("Frame", {
        Parent = frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    mk("UIListLayout", {
        Parent = content,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    })
    local sec = setmetatable({
        Name = name,
        Window = self.Window,
        Tab = self,
        Frame = frame,
        Content = content,
    }, Section)
    table.insert(self.Sections, sec)
    return sec
end

function Tab:_def()
    if not self.DefaultSection then
        self.DefaultSection = self:CreateSection("General", "Left")
    end
    return self.DefaultSection
end

function Tab:CreateButton(...)
    return self:_def():CreateButton(...)
end
function Tab:CreateToggle(...)
    return self:_def():CreateToggle(...)
end
function Tab:CreateSlider(...)
    return self:_def():CreateSlider(...)
end
function Tab:CreateDropdown(...)
    return self:_def():CreateDropdown(...)
end
function Tab:CreateInput(...)
    return self:_def():CreateInput(...)
end
function Tab:CreateTextbox(...)
    return self:_def():CreateTextbox(...)
end
function Tab:CreateLabel(...)
    return self:_def():CreateLabel(...)
end
function Tab:CreateParagraph(...)
    return self:_def():CreateParagraph(...)
end
function Tab:CreateKeybind(...)
    return self:_def():CreateKeybind(...)
end
function Window:CreateTab(a, iconMaybe)
    local name, icon = "Tab", nil
    if typeof(a) == "table" then
        name = tostring(a.Name or a.Title or "Tab")
        icon = a.Icon
    else
        name = tostring(a or "Tab")
        icon = iconMaybe
    end

    local btn = mk("TextButton", {
        Parent = self.TabList,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 28),
        Text = "",
        AutoButtonColor = false,
    })
    local back = mk("Frame", {
        Parent = btn,
        BackgroundColor3 = C.SidebarActive,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
    })
    corner(back, 3)
    local ind = mk("Frame", {
        Parent = btn,
        BackgroundColor3 = C.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, -6),
        Position = UDim2.new(0, 0, 0, 3),
    })
    corner(ind, 99)

    local iconHolder = mk("Frame", {
        Parent = btn,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 10, 0.5, -7),
    })
    local iconImage
    if typeof(icon) == "number" then
        iconImage = "rbxassetid://" .. tostring(icon)
    elseif typeof(icon) == "string" then
        if string.find(icon, "rbxassetid://", 1, true) then
            iconImage = icon
        elseif tonumber(icon) then
            iconImage = "rbxassetid://" .. tostring(icon)
        end
    end
    if iconImage then
        mk("ImageLabel", {
            Parent = iconHolder,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ImageColor3 = C.SubText,
            Image = iconImage,
        })
    else
        local dot = mk("Frame", {
            Parent = iconHolder,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 6, 0, 6),
            BackgroundColor3 = C.SubText,
            BorderSizePixel = 0,
        })
        corner(dot, 99)
    end

    local lbl = mk("TextLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 28, 0, 0),
        Size = UDim2.new(1, -32, 1, 0),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.SubText,
        Text = name,
    })

    local page = mk("Frame", {
        Parent = self.PageHolder,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    })
    local left = mk("ScrollingFrame", {
        Parent = page,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0.5, -4, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Stroke,
    })
    mk("UIListLayout", {
        Parent = left,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })
    local right = mk("ScrollingFrame", {
        Parent = page,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 4, 0, 0),
        Size = UDim2.new(0.5, -4, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Stroke,
    })
    mk("UIListLayout", {
        Parent = right,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })

    local tab = setmetatable({
        Name = name,
        Window = self,
        Button = btn,
        ButtonBack = back,
        Indicator = ind,
        Label = lbl,
        Page = page,
        Left = left,
        Right = right,
        Sections = {},
        DefaultSection = nil,
    }, Tab)

    table.insert(self.Tabs, tab)
    track(self.Connections, btn.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end))
    track(self.Connections, btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tw(back, 0.1, { BackgroundTransparency = 0.72 }):Play()
        end
    end))
    track(self.Connections, btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tw(back, 0.1, { BackgroundTransparency = 1 }):Play()
        end
    end))

    if not self.ActiveTab then
        self:SelectTab(tab)
    end
    return tab
end

function UILibrary:CreateWindow(arg)
    if self._window and self._window.Destroy then
        self._window:Destroy()
    end

    local o = typeof(arg) == "table" and arg or { Title = arg }
    local title = tostring(o.Title or o.Name or "UI Library")
    local subtitle = tostring(o.Subtitle or o.SubTitle or "")
    local size = (typeof(o.Size) == "UDim2") and o.Size or UDim2.fromOffset(900, 520)
    local toggleKey = Enum.KeyCode.Insert
    local parent = (typeof(o.Parent) == "Instance") and o.Parent or guiParent()
    if not parent then
        error("[library_v2] no ScreenGui parent")
    end

    local old = parent:FindFirstChild(GUI_NAME)
    if old then
        old:Destroy()
    end

    local sg = mk("ScreenGui", {
        Name = GUI_NAME,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = nil,
    })
    protect(sg)
    sg.Parent = parent

    local main = mk("Frame", {
        Parent = sg,
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = size,
        BackgroundColor3 = C.Main,
        BorderSizePixel = 0,
        Active = true,
        Visible = false,
    })
    corner(main, 5)
    local mainStroke = stroke(main, C.Stroke, 0.45)
    local mainScale = mk("UIScale", {
        Parent = main,
        Scale = 1,
    })
    mk("UISizeConstraint", {
        Parent = main,
        MinSize = Vector2.new(720, 430),
    })

    local top = mk("Frame", {
        Parent = main,
        BackgroundColor3 = C.Top,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
    })
    corner(top, 5)
    mk("Frame", {
        Parent = top,
        BackgroundColor3 = C.Top,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0.5, 0),
    })

    local titleLbl = mk("TextLabel", {
        Parent = top,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -90, 1, 0),
        Font = FONT,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = subtitle ~= "" and (title .. "  |  " .. subtitle) or title,
    })
    local hide = mk("TextButton", {
        Parent = top,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -38, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Font = FONT,
        TextSize = 14,
        TextColor3 = C.SubText,
        Text = "-",
        AutoButtonColor = false,
    })
    corner(hide, 3)
    local close = mk("TextButton", {
        Parent = top,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Font = FONT,
        TextSize = 14,
        TextColor3 = C.SubText,
        Text = "x",
        AutoButtonColor = false,
    })
    corner(close, 3)

    local body = mk("Frame", {
        Parent = main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 1, -32),
    })
    local side = mk("Frame", {
        Parent = body,
        BackgroundColor3 = C.Sidebar,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 164, 1, 0),
    })
    mk("UIPadding", {
        Parent = side,
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    })
    local tabList = mk("Frame", {
        Parent = side,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
    })
    mk("UIListLayout", {
        Parent = tabList,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })

    local content = mk("Frame", {
        Parent = body,
        BackgroundColor3 = C.Panel,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 164, 0, 0),
        Size = UDim2.new(1, -164, 1, 0),
    })
    mk("UIPadding", {
        Parent = content,
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    })
    local pageHolder = mk("Frame", {
        Parent = content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
    })

    local toastHost = mk("Frame", {
        Parent = sg,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 10),
        Size = UDim2.new(0, 320, 1, -20),
    })
    mk("UIListLayout", {
        Parent = toastHost,
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })

    local w = setmetatable({
        ScreenGui = sg,
        Main = main,
        MainStroke = mainStroke,
        MainScale = mainScale,
        TitleLabel = titleLbl,
        TabList = tabList,
        PageHolder = pageHolder,
        Tabs = {},
        ActiveTab = nil,
        Connections = {},
        CloseCallbacks = {},
        ToggleKey = toggleKey,
        VisibleState = false,
        Animating = false,
        Destroyed = false,
    }, Window)

    UILibrary._window = w
    UILibrary._toastHost = toastHost

    local dragging = false
    local dragFrom = Vector2.new(0, 0)
    local startPos = UDim2.new()
    track(w.Connections, top.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragFrom = i.Position
            startPos = main.Position
        end
    end))
    track(w.Connections, UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragFrom
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    track(w.Connections, UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    track(w.Connections, hide.MouseButton1Click:Connect(function()
        w:SetVisible(false)
    end))
    track(w.Connections, close.MouseButton1Click:Connect(function()
        w:Destroy()
    end))
    track(w.Connections, UIS.InputBegan:Connect(function(i, gpe)
        if gpe then
            return
        end
        if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == w.ToggleKey then
            w:Toggle()
        end
    end))

    if o.IncludePlayers ~= false then
        task.defer(function()
            if w and not w.Destroyed then
                pcall(function()
                    w:CreatePlayersCategory(o.PlayersOptions)
                end)
            end
        end)
    end

    w:SetVisible(true)
    return w
end

function UILibrary:SetVisibility(v)
    if self._window then
        self._window:SetVisible(v == true)
    end
end

function UILibrary:IsVisible()
    return self._window and self._window:IsVisible() or false
end

function UILibrary:Destroy()
    if self._window then
        self._window:Destroy()
    end
end

function UILibrary:Notify(args)
    args = args or {}
    local title = tostring(args.Title or "Notification")
    local content = tostring(args.Content or "")
    local duration = tonumber(args.Duration) or 3

    local host = self._toastHost
    if not host or not host.Parent then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = title,
                Text = content,
                Duration = duration,
            })
        end)
        return
    end

    duration = math.max(duration, 0.2)

    local toast = mk("Frame", {
        Parent = host,
        BackgroundColor3 = C.Top,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = -os.clock(),
        ClipsDescendants = true,
    })
    local toastStroke = stroke(toast, C.Stroke, 0.25)
    local pop = mk("UIScale", {
        Parent = toast,
        Scale = 0.96,
    })
    corner(toast, 4)
    mk("UIPadding", {
        Parent = toast,
        PaddingTop = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    })
    mk("UIListLayout", {
        Parent = toast,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    })

    local t = mk("TextLabel", {
        Parent = toast,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = title,
        LayoutOrder = 1,
    })
    local c = mk("TextLabel", {
        Parent = toast,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = FONT,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = C.SubText,
        Text = content,
        LayoutOrder = 2,
    })

    local timerTrack = mk("Frame", {
        Parent = toast,
        BackgroundColor3 = Color3.fromRGB(17, 25, 38),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 3),
        LayoutOrder = 3,
    })
    corner(timerTrack, 99)
    local timerFill = mk("Frame", {
        Parent = timerTrack,
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
    })
    corner(timerFill, 99)

    toast.BackgroundTransparency = 1
    toastStroke.Transparency = 1
    t.TextTransparency = 1
    c.TextTransparency = 1
    timerTrack.BackgroundTransparency = 1
    timerFill.BackgroundTransparency = 1

    tw(pop, 0.16, { Scale = 1 }):Play()
    tw(toast, 0.16, { BackgroundTransparency = 0 }):Play()
    tw(toastStroke, 0.16, { Transparency = 0.25 }):Play()
    tw(t, 0.16, { TextTransparency = 0 }):Play()
    tw(c, 0.16, { TextTransparency = 0 }):Play()
    tw(timerTrack, 0.16, { BackgroundTransparency = 0 }):Play()
    tw(timerFill, 0.16, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(timerFill, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 0, 1, 0),
    }):Play()

    task.delay(duration, function()
        if not toast.Parent then
            return
        end
        tw(pop, 0.14, { Scale = 0.95 }):Play()
        tw(toast, 0.14, { BackgroundTransparency = 1 }):Play()
        tw(toastStroke, 0.14, { Transparency = 1 }):Play()
        tw(t, 0.14, { TextTransparency = 1 }):Play()
        tw(c, 0.14, { TextTransparency = 1 }):Play()
        tw(timerTrack, 0.14, { BackgroundTransparency = 1 }):Play()
        tw(timerFill, 0.14, { BackgroundTransparency = 1 }):Play()
        task.delay(0.15, function()
            if toast.Parent then
                toast:Destroy()
            end
        end)
    end)
end

function UILibrary:NotifyInfo(args)
    return self:Notify(args)
end

function UILibrary:NotifyWarning(args)
    args = args or {}
    args.Title = args.Title or "Warning"
    return self:Notify(args)
end

function UILibrary:NotifyError(args)
    args = args or {}
    args.Title = args.Title or "Error"
    return self:Notify(args)
end

return UILibrary
