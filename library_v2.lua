local UILibrary = {}

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local FONT = Enum.Font.Gotham
local GUI_NAME = "LimboLibrary"
local OPEN_DROPDOWNS = {}
local BUILTIN_ICON_ALIASES = {
    ["local"] = {
        Image = "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png",
        Fallback = "L",
    },
    ["players"] = {
        Image = "rbxasset://textures/ui/PlayerList/StarIcon.png",
        Fallback = "P",
    },
    ["universal"] = {
        Image = "rbxasset://textures/ui/Settings/MenuBarIcons/HomeTab.png",
        Fallback = "U",
    },
    ["scripts"] = {
        Image = "rbxasset://textures/ui/TopBar/coloredlogo.png",
        Fallback = "S",
    },
}

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

local function normalizeIconKey(v)
    if type(v) ~= "string" then
        return nil
    end
    local key = string.lower(v)
    key = string.gsub(key, "%s+", "")
    key = string.gsub(key, "[_%-./]", "")
    return key
end

local function resolveIconSpec(iconSpec, depth)
    depth = (depth or 0) + 1
    if depth > 5 then
        return nil, nil
    end

    local iconType = typeof(iconSpec)
    if iconType == "number" then
        return "rbxassetid://" .. tostring(iconSpec), nil
    end

    if iconType == "string" then
        local raw = tostring(iconSpec)
        if raw == "" then
            return nil, nil
        end

        if string.find(raw, "rbxassetid://", 1, true) or string.find(raw, "rbxasset://", 1, true)
            or string.find(raw, "http://", 1, true) or string.find(raw, "https://", 1, true) then
            return raw, nil
        end

        local numeric = tonumber(raw)
        if numeric then
            return "rbxassetid://" .. tostring(numeric), nil
        end

        local key = normalizeIconKey(raw)
        local iconAliases = UILibrary.Icons or {}
        local aliasSpec = iconAliases[raw] or iconAliases[key] or BUILTIN_ICON_ALIASES[key]
        if aliasSpec ~= nil then
            return resolveIconSpec(aliasSpec, depth)
        end

        if #raw <= 3 then
            return nil, string.upper(raw)
        end
        return nil, nil
    end

    if iconType == "table" then
        local directImage = iconSpec.Image or iconSpec.Url or iconSpec.Source
        local directId = iconSpec.Id or iconSpec.AssetId or iconSpec.ImageId
        local fallbackText = iconSpec.Text or iconSpec.Fallback or iconSpec.Glyph
        local aliasName = iconSpec.Alias or iconSpec.Name or iconSpec.IconName

        local imageFromAlias, textFromAlias = nil, nil
        if aliasName then
            imageFromAlias, textFromAlias = resolveIconSpec(aliasName, depth)
        end

        if typeof(directImage) == "string" and directImage ~= "" then
            local raw = directImage
            if string.find(raw, "rbxassetid://", 1, true) or string.find(raw, "rbxasset://", 1, true)
                or string.find(raw, "http://", 1, true) or string.find(raw, "https://", 1, true) then
                return raw, fallbackText or textFromAlias
            end
            local asNumber = tonumber(raw)
            if asNumber then
                return "rbxassetid://" .. tostring(asNumber), fallbackText or textFromAlias
            end
        end

        if typeof(directId) == "number" then
            return "rbxassetid://" .. tostring(directId), fallbackText or textFromAlias
        end
        if typeof(directId) == "string" and directId ~= "" then
            local asNumber = tonumber(directId)
            if asNumber then
                return "rbxassetid://" .. tostring(asNumber), fallbackText or textFromAlias
            end
            if string.find(directId, "rbxassetid://", 1, true) or string.find(directId, "rbxasset://", 1, true) then
                return directId, fallbackText or textFromAlias
            end
        end

        if imageFromAlias then
            return imageFromAlias, fallbackText or textFromAlias
        end
        if typeof(fallbackText) == "string" and fallbackText ~= "" then
            return nil, string.sub(fallbackText, 1, 3)
        end
        return nil, textFromAlias
    end

    return nil, nil
end

local function normalizeSectionSide(side)
    local s = string.lower(tostring(side or "left"))
    if s == "right" or s == "r" then
        return "Right"
    end
    return "Left"
end

local function isPersistentTabName(name)
    local n = string.lower(tostring(name or ""))
    return n == "local" or n == "players" or n == "universal" or n == "remotes"
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

function UILibrary:SuspendFlingProtect(seconds)
    local untilAt = os.clock() + math.max(0, tonumber(seconds) or 0)
    if untilAt > (self._suspendFlingProtectUntil or 0) then
        self._suspendFlingProtectUntil = untilAt
    end
    return self._suspendFlingProtectUntil
end

function UILibrary:IsFlingProtectSuspended()
    return os.clock() < (self._suspendFlingProtectUntil or 0)
end

function UILibrary:RegisterIcon(name, iconSpec)
    if type(name) ~= "string" or name == "" then
        return false
    end
    local key = normalizeIconKey(name)
    if not key or key == "" then
        return false
    end
    self.Icons = self.Icons or {}
    self.Icons[key] = iconSpec
    self.Icons[name] = iconSpec
    return true
end

function UILibrary:GetIcon(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    local key = normalizeIconKey(name)
    local iconAliases = self.Icons or {}
    return iconAliases[name] or iconAliases[key] or BUILTIN_ICON_ALIASES[key]
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

function Window:PlayInitializeAnimation()
    if self.InitAnimationPlayed or not self.Main or not self.Main.Parent then
        return
    end
    self.InitAnimationPlayed = true

    local overlay = mk("Frame", {
        Parent = self.Main,
        BackgroundColor3 = C.Main,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 50,
    })
    corner(overlay, 5)
    mk("UIGradient", {
        Parent = overlay,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(7, 11, 18)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 18, 29)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 0.35),
        }),
    })

    local panel = mk("Frame", {
        Parent = overlay,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 12),
        Size = UDim2.fromOffset(380, 114),
        BackgroundColor3 = C.Top,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        ZIndex = 52,
    })
    local panelScale = mk("UIScale", {
        Parent = panel,
        Scale = 0.96,
    })
    corner(panel, 6)
    stroke(panel, C.Stroke, 0.35)
    mk("UIPadding", {
        Parent = panel,
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    })

    local line = mk("Frame", {
        Parent = panel,
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 2),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 53,
    })
    corner(line, 99)

    local initTitle = mk("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 6),
        Size = UDim2.new(1, 0, 0, 18),
        Font = FONT,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = "Limbo Interface",
        TextTransparency = 1,
        ZIndex = 53,
    })
    local initSub = mk("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 27),
        Size = UDim2.new(1, 0, 0, 16),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.SubText,
        Text = "Preparing modules...",
        TextTransparency = 1,
        ZIndex = 53,
    })

    local barBack = mk("Frame", {
        Parent = panel,
        Position = UDim2.new(0, 0, 0, 58),
        Size = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        BackgroundTransparency = 0.55,
        ZIndex = 53,
    })
    corner(barBack, 99)

    local barFill = mk("Frame", {
        Parent = barBack,
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 54,
    })
    corner(barFill, 99)

    local steps = {
        { Label = "Preparing modules...", Fill = 0.34, Time = 0.24 },
        { Label = "Building sections...", Fill = 0.72, Time = 0.26 },
        { Label = "Finalizing...", Fill = 1, Time = 0.2 },
    }

    tw(overlay, 0.12, { BackgroundTransparency = 0.08 }):Play()
    tw(panel, 0.14, { BackgroundTransparency = 0 }):Play()
    tw(panelScale, 0.14, { Scale = 1 }):Play()
    tw(initTitle, 0.14, { TextTransparency = 0 }):Play()
    tw(initSub, 0.14, { TextTransparency = 0 }):Play()
    tw(line, 0.22, { Size = UDim2.new(1, 0, 0, 2) }):Play()
    task.wait(0.09)

    for _, step in ipairs(steps) do
        if not overlay.Parent then
            return
        end
        initSub.Text = step.Label
        tw(barFill, step.Time, { Size = UDim2.new(step.Fill, 0, 1, 0) }):Play()
        task.wait(step.Time + 0.02)
    end

    if not overlay.Parent then
        return
    end
    tw(initSub, 0.18, { TextTransparency = 1 }):Play()
    tw(initTitle, 0.2, { TextTransparency = 1 }):Play()
    tw(line, 0.18, { BackgroundTransparency = 1 }):Play()
    tw(barBack, 0.2, { BackgroundTransparency = 1 }):Play()
    tw(barFill, 0.2, { BackgroundTransparency = 1 }):Play()
    tw(panelScale, 0.2, { Scale = 0.97 }):Play()
    tw(panel, 0.2, { BackgroundTransparency = 1 }):Play()
    tw(overlay, 0.2, { BackgroundTransparency = 1 }):Play()
    task.delay(0.22, function()
        if overlay and overlay.Parent then
            overlay:Destroy()
        end
    end)
end

function Window:PlayCloseAnimation()
    if not self.Main or not self.Main.Parent then
        return
    end
    if not self.Main.Visible then
        return
    end

    if self.AnimScaleTween then
        self.AnimScaleTween:Cancel()
    end
    if self.AnimFadeTween then
        self.AnimFadeTween:Cancel()
    end
    if self.AnimStrokeTween then
        self.AnimStrokeTween:Cancel()
    end

    local startPos = self.Main.Position
    local overlay = mk("Frame", {
        Parent = self.Main,
        BackgroundColor3 = C.Main,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 60,
    })
    corner(overlay, 5)

    if self.MainScale then
        tw(self.MainScale, 0.2, { Scale = 0.93 }):Play()
    end
    tw(self.Main, 0.2, {
        BackgroundTransparency = 1,
        Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset + 12),
    }):Play()
    if self.MainStroke then
        tw(self.MainStroke, 0.2, { Transparency = 1 }):Play()
    end
    tw(overlay, 0.2, { BackgroundTransparency = 0.15 }):Play()

    task.wait(0.21)
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

function Window:Cleanup()
    if self.CleanupRan then
        return
    end
    self.CleanupRan = true

    for _, cb in ipairs(self.CloseCallbacks) do
        safe(cb)
    end
    table.clear(self.CloseCallbacks)
end

function Window:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    closeDropdowns(nil)

    self:Cleanup()
    self:PlayCloseAnimation()

    for _, c in ipairs(self.Connections) do
        if c and c.Disconnect then
            pcall(function()
                c:Disconnect()
            end)
        end
    end
    table.clear(self.Connections)
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
        local iconColor = active and C.Text or C.SubText
        if t.IconImageLabel then
            t.IconImageLabel.ImageColor3 = iconColor
        end
        if t.IconTextLabel then
            t.IconTextLabel.TextColor3 = iconColor
        end
        if t.IconDot then
            t.IconDot.BackgroundColor3 = iconColor
        end
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
    local playersTabIcon = options.TabIcon or options.Icon or "players"

    local playersTab = nil
    for _, existingTab in ipairs(self.Tabs) do
        if existingTab.Name == "Players" then
            playersTab = existingTab
            break
        end
    end
    if not playersTab then
        playersTab = self:CreateTab({ Name = "Players", Icon = playersTabIcon })
    elseif playersTab.SetIcon then
        playersTab:SetIcon(playersTabIcon)
    end

    local listSection = playersTab:CreateSection({ Name = "Player List", Side = "Left" })
    local optionsSection = playersTab:CreateSection({ Name = "Player Options", Side = "Right" })

    local listShell = mk("Frame", {
        Parent = listSection.Content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 430),
    })
    local listBack = mk("Frame", {
        Parent = listShell,
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
    })
    corner(listBack, 4)
    stroke(listBack, C.Stroke, 0.55)

    local searchBack = mk("Frame", {
        Parent = listBack,
        BackgroundColor3 = Color3.fromRGB(14, 21, 31),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0, 6),
        Size = UDim2.new(1, -12, 0, 24),
    })
    corner(searchBack, 3)
    stroke(searchBack, C.Stroke, 0.65)

    local searchBox = mk("TextBox", {
        Parent = searchBack,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        PlaceholderColor3 = C.SubText,
        PlaceholderText = "Search player...",
        Text = "",
        ClearTextOnFocus = false,
    })

    local listScroll = mk("ScrollingFrame", {
        Parent = listBack,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0, 34),
        Size = UDim2.new(1, -12, 1, -40),
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

    local function updateListShellHeight()
        local pageHeight = playersTab.Page.AbsoluteSize.Y
        if pageHeight <= 0 then
            return
        end
        local wanted = math.max(300, pageHeight - 44)
        listShell.Size = UDim2.new(1, 0, 0, wanted)
    end

    local selectedPlayer = nil
    local playerSearchQuery = ""
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
    local clickFlingEnabled = false
    local clickFlingConnection = nil
    local clickFlingCooldownUntil = 0

    local selectedName = optionsSection:CreateLabel("Selected: None")
    local selectedUser = optionsSection:CreateLabel("@none")
    --local targetModeButton = optionsSection:CreateButton("Target Mode: Selected")
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

    local function collectModeCandidates()
        local candidates = {}
        if targetMode == "Selected" then
            if selectedPlayer and selectedPlayer ~= localPlayer then
                table.insert(candidates, selectedPlayer)
            end
            return candidates
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer then
                if targetMode == "Others" and selectedPlayer and p == selectedPlayer then
                    -- In Others mode, target everyone except your selected player.
                else
                    table.insert(candidates, p)
                end
            end
        end
        table.sort(candidates, function(a, b)
            return string.lower(tostring(a.Name or "")) < string.lower(tostring(b.Name or ""))
        end)
        return candidates
    end

    local function getTrollTarget()
        local candidates = collectModeCandidates()
        for _, p in ipairs(candidates) do
            if p and p.Parent == Players and getTargetRoot(p) then
                return p
            end
        end
        return nil
    end

    local function refreshSpectateButtonText()
        spectateButton:SetText(spectateTarget and "Stop Spectating" or "Spectate")
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
        local candidates = collectModeCandidates()

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

    local function runBringPlayer(targetPlayer)
        local localRoot = getLocalRoot()
        local targetRoot = getTargetRoot(targetPlayer)
        if not localRoot or not targetRoot then
            return false
        end

        local bringSpot = localRoot.CFrame * CFrame.new(0, 2, -6)
        local endAt = os.clock() + 2.8
        while os.clock() < endAt do
            localRoot = getLocalRoot()
            targetRoot = getTargetRoot(targetPlayer)
            if not localRoot or not targetRoot or not localRoot.Parent then
                break
            end

            local toSpot = bringSpot.Position - targetRoot.Position
            if toSpot.Magnitude < 4 then
                break
            end
            local dir = (toSpot.Magnitude > 0.001) and toSpot.Unit or Vector3.new(0, 0, 0)
            local pushPos = targetRoot.Position - (dir * 2) + Vector3.new(0, 1.2, 0)

            localRoot.CFrame = CFrame.lookAt(pushPos, targetRoot.Position)
            localRoot.AssemblyLinearVelocity = (dir * 180) + Vector3.new(0, 45, 0)
            RunService.Heartbeat:Wait()
        end
        return true
    end

    local function runBringParts()
        local localRoot = getLocalRoot()
        if not localRoot then
            return false, 0
        end

        local moved = 0
        local localCharacter = localPlayer.Character
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Parent and not obj.Anchored then
                if not (localCharacter and obj:IsDescendantOf(localCharacter)) then
                    if not obj.Parent:FindFirstChildOfClass("Humanoid") then
                        obj.CFrame = localRoot.CFrame
                            * CFrame.new(math.random(-7, 7), math.random(3, 8), math.random(-7, 7))
                        obj.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        moved = moved + 1
                        if moved >= 180 then
                            break
                        end
                    end
                end
            end
        end

        return moved > 0, moved
    end

    local function runLaunchPlayerHigh(targetPlayer)
        local localRoot = getLocalRoot()
        local targetRoot = getTargetRoot(targetPlayer)
        if not localRoot or not targetRoot then
            return false
        end

        local endAt = os.clock() + 1.9
        while os.clock() < endAt do
            localRoot = getLocalRoot()
            targetRoot = getTargetRoot(targetPlayer)
            if not localRoot or not targetRoot or not localRoot.Parent then
                break
            end

            localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -1.8)
            localRoot.AssemblyLinearVelocity = Vector3.new(0, 260, 0)
            localRoot.AssemblyAngularVelocity = Vector3.new(0, 1200, 0)
            RunService.Heartbeat:Wait()
        end
        return true
    end

    local function runKidnapPlayer(targetPlayer)
        local localRoot = getLocalRoot()
        local targetRoot = getTargetRoot(targetPlayer)
        if not localRoot or not targetRoot then
            return false
        end

        local kidnapSpot = localRoot.CFrame * CFrame.new(0, 2, -10)
        local endAt = os.clock() + 3.8
        while os.clock() < endAt do
            localRoot = getLocalRoot()
            targetRoot = getTargetRoot(targetPlayer)
            if not localRoot or not targetRoot or not localRoot.Parent then
                break
            end

            local toSpot = kidnapSpot.Position - targetRoot.Position
            local dir = (toSpot.Magnitude > 0.001) and toSpot.Unit or Vector3.new(0, 0, 0)
            local pushPos = targetRoot.Position - (dir * 1.4) + Vector3.new(0, 1.4, 0)
            localRoot.CFrame = CFrame.lookAt(pushPos, targetRoot.Position)
            localRoot.AssemblyLinearVelocity = (dir * 220) + Vector3.new(0, 65, 0)
            RunService.Heartbeat:Wait()
        end
        return true
    end

    local function stopFlingAndRestore()
        if flingRestore then
            flingRestore()
        end
    end

    local function flingForFiveSeconds(targetPlayer, flingOptions)
        flingOptions = flingOptions or {}
        local localRoot = getLocalRoot()
        local targetRoot = getTargetRoot(targetPlayer)
        if not localRoot or not targetRoot then
            return false
        end

        local duration = math.max(0.8, tonumber(flingOptions.Duration) or 5)
        local thrustForce = (typeof(flingOptions.Force) == "Vector3")
            and flingOptions.Force
            or Vector3.new(9999, 9999, 9999)
        local spinBase = tonumber(flingOptions.SpinBase) or 130
        local spinAccel = tonumber(flingOptions.SpinAccel) or 32
        local radiusBase = tonumber(flingOptions.RadiusBase) or 0.2
        local radiusPulse = tonumber(flingOptions.RadiusPulse) or 0.65
        local riseBase = tonumber(flingOptions.RiseBase) or 0.15
        local risePulse = tonumber(flingOptions.RisePulse) or 0.25
        local tangentPower = tonumber(flingOptions.TangentPower) or 650
        local forwardPower = tonumber(flingOptions.ForwardPower) or 220
        local upPower = tonumber(flingOptions.UpPower) or 145
        local angularVelocity = (typeof(flingOptions.AngularVelocity) == "Vector3")
            and flingOptions.AngularVelocity
            or Vector3.new(4200, 6000, 4200)

        UILibrary:SuspendFlingProtect(duration + 0.9)
        stopFlingAndRestore()

        local startCFrame = localRoot.CFrame
        local oldLinear = localRoot.AssemblyLinearVelocity
        local oldAngular = localRoot.AssemblyAngularVelocity
        local startAt = os.clock()
        local endAt = os.clock() + duration
        local done = false
        local thrust = Instance.new("BodyThrust")
        thrust.Name = "YeetForce"
        thrust.Force = thrustForce
        thrust.Parent = localRoot

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

            if thrust and thrust.Parent then
                thrust:Destroy()
            end

            flingRestore = nil
        end

        flingRestore = restore
        flingConnection = RunService.Heartbeat:Connect(function()
            local currentRoot = getLocalRoot()
            local currentTargetRoot = getTargetRoot(targetPlayer)
            local targetCharacter = targetPlayer and targetPlayer.Character
            if os.clock() >= endAt or not currentRoot or not currentTargetRoot or not targetCharacter or not targetCharacter:FindFirstChild("Head") then
                restore()
                return
            end

            local now = os.clock()
            local elapsed = now - startAt
            local theta = now * (spinBase + elapsed * spinAccel)
            local closeRadius = radiusBase + math.abs(math.sin(elapsed * 16)) * radiusPulse
            local rise = riseBase + math.sin(elapsed * 22) * risePulse
            local offset = Vector3.new(
                math.cos(theta) * closeRadius,
                rise,
                math.sin(theta) * closeRadius
            )

            local attackCFrame = currentTargetRoot.CFrame * CFrame.new(offset) * CFrame.Angles(theta * 2.4, theta * 1.6, theta * 2.2)
            currentRoot.CFrame = attackCFrame
            if thrust.Parent ~= currentRoot then
                thrust.Parent = currentRoot
            end
            thrust.Location = currentTargetRoot.Position

            local tangent = Vector3.new(-math.sin(theta), 0, math.cos(theta))
            local shove = (tangent * tangentPower)
                + (currentTargetRoot.CFrame.LookVector * forwardPower)
                + Vector3.new(0, upPower, 0)
            currentRoot.AssemblyLinearVelocity = shove
            currentRoot.AssemblyAngularVelocity = angularVelocity
        end)

        task.delay(duration + 0.2, restore)
        return true
    end

    local function runSuperFling(targetPlayer)
        return flingForFiveSeconds(targetPlayer, {
            Duration = 6,
            Force = Vector3.new(18000, 18000, 18000),
            SpinBase = 185,
            SpinAccel = 44,
            RadiusBase = 0.35,
            RadiusPulse = 0.85,
            RiseBase = 0.25,
            RisePulse = 0.35,
            TangentPower = 980,
            ForwardPower = 360,
            UpPower = 240,
            AngularVelocity = Vector3.new(7600, 9800, 7600),
        })
    end

    local function runZombieAnimationFling(targetPlayer)
        local track = nil
        local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if not animator then
                animator = Instance.new("Animator")
                animator.Parent = humanoid
            end
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://616158929"
            local ok, loaded = pcall(function()
                return animator:LoadAnimation(anim)
            end)
            anim:Destroy()
            if ok and loaded then
                track = loaded
                pcall(function()
                    track.Looped = true
                    track:Play(0.1, 1, 1.15)
                end)
            end
        end

        local okFling = flingForFiveSeconds(targetPlayer, {
            Duration = 5.4,
            TangentPower = 760,
            ForwardPower = 280,
            UpPower = 170,
            AngularVelocity = Vector3.new(5000, 6900, 5000),
        })

        task.delay(5.6, function()
            if track then
                pcall(function()
                    track:Stop(0.1)
                    track:Destroy()
                end)
            end
        end)

        return okFling
    end

    local function getPlayerFromPart(part)
        if not part then
            return nil
        end
        local model = part:FindFirstAncestorOfClass("Model")
        if not model then
            return nil
        end
        return Players:GetPlayerFromCharacter(model)
    end

    local function setClickFlingEnabled(state, silent)
        state = state == true
        if clickFlingEnabled == state then
            return
        end

        clickFlingEnabled = state
        if clickFlingConnection then
            clickFlingConnection:Disconnect()
            clickFlingConnection = nil
        end

        if clickFlingEnabled then
            local mouse = localPlayer:GetMouse()
            clickFlingConnection = mouse.Button1Down:Connect(function()
                if not clickFlingEnabled then
                    return
                end
                if os.clock() < clickFlingCooldownUntil then
                    return
                end

                local clickedPlayer = getPlayerFromPart(mouse.Target)
                if not clickedPlayer or clickedPlayer == localPlayer then
                    return
                end

                selectedPlayer = clickedPlayer
                UILibrary:SetSelectedPlayer(clickedPlayer)
                selectedName:Set("Selected: " .. tostring(clickedPlayer.DisplayName or clickedPlayer.Name))
                selectedUser:Set("@" .. tostring(clickedPlayer.Name))
                clickFlingCooldownUntil = os.clock() + 5.3

                local ok = flingForFiveSeconds(clickedPlayer)
                if ok then
                    notify("Fling Click", "Flinging " .. tostring(clickedPlayer.Name) .. ".", 2.1)
                end
            end)
        end

        if not silent then
            notify("Fling Click", clickFlingEnabled and "Enabled." or "Disabled.", 1.9)
        end
    end

    local function refreshTargetSelectionLabels()
        if selectedPlayer and selectedPlayer.Parent == Players then
            selectedName:Set("Selected: " .. tostring(selectedPlayer.DisplayName or selectedPlayer.Name))
            selectedUser:Set("@" .. tostring(selectedPlayer.Name))
        else
            selectedName:Set("Selected: None")
            selectedUser:Set("@none")
        end
        --targetModeButton:SetText("Target Mode: " .. targetMode)
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

        local filtered = {}
        local query = string.lower(playerSearchQuery or "")
        if query == "" then
            filtered = allPlayers
        else
            for _, p in ipairs(allPlayers) do
                local name = string.lower(tostring(p.Name or ""))
                local display = string.lower(tostring(p.DisplayName or ""))
                if string.find(name, query, 1, true) or string.find(display, query, 1, true) then
                    table.insert(filtered, p)
                end
            end
        end

        if #filtered == 0 then
            mk("TextLabel", {
                Parent = listScroll,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 26),
                Font = FONT,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = C.SubText,
                Text = "No matching players",
            })
            return
        end

        for _, p in ipairs(filtered) do
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

    -- track(self.Connections, targetModeButton.Button.MouseButton1Click:Connect(function()
    --     local idx = 1
    --     for i, mode in ipairs(targetModes) do
    --         if mode == targetMode then
    --             idx = i
    --             break
    --         end
    --     end
    --     idx = idx + 1
    --     if idx > #targetModes then
    --         idx = 1
    --     end
    --     targetMode = targetModes[idx]
    --     refreshTargetSelectionLabels()
    --     notify("Target Mode", "Now using: " .. targetMode, 2.1)
    -- end))

    track(self.Connections, spectateButton.Button.MouseButton1Click:Connect(function()
        if spectateTarget then
            stopSpectate()
            notify("Spectate", "Stopped spectating.")
            return
        end
        local target = getTrollTarget()
        if not target then
            notify("Spectate", "No valid target for mode: " .. targetMode, 2.4)
            return
        end
        local ok = startSpectate(target)
        if ok then
            notify("Spectate", "Now watching " .. tostring(target.Name) .. " (" .. targetMode .. ").")
        else
            notify("Spectate", "Target is not available.", 2.8)
        end
    end))

    optionsSection:CreateButton("Teleport To", function()
        local target = getTrollTarget()
        if not target then
            notify("Teleport", "No valid target for mode: " .. targetMode, 2.4)
            return
        end
        local ok = teleportToPlayer(target)
        if ok then
            notify("Teleport", "Teleported to " .. tostring(target.Name) .. " (" .. targetMode .. ").")
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
            notify("Fling", "No valid target for mode: " .. targetMode, 2.4)
            return
        end
        local ok = flingForFiveSeconds(target)
        if ok then
            notify("Fling", "Flinging " .. tostring(target.Name) .. " (" .. targetMode .. ") for 5 seconds.", 2.3)
        else
            notify("Fling", "Could not fling target right now.", 2.8)
        end
    end)

    optionsSection:CreateButton("FE Bring Player", function()
        applyToTargets("FE Bring Player", function(targetPlayer)
            return runBringPlayer(targetPlayer)
        end)
    end)

    optionsSection:CreateButton("FE bring parts", function()
        local ok, moved = runBringParts()
        if ok then
            notify("FE bring parts", "Moved " .. tostring(moved) .. " part(s).", 2.2)
        else
            notify("FE bring parts", "No movable parts found.", 2.5)
        end
    end)

    optionsSection:CreateButton("FE launch player High", function()
        applyToTargets("FE launch player High", function(targetPlayer)
            return runLaunchPlayerHigh(targetPlayer)
        end)
    end)

    optionsSection:CreateButton("FE kidnap", function()
        local target = getTrollTarget()
        if not target then
            notify("FE kidnap", "No valid target for mode: " .. targetMode, 2.4)
            return
        end
        local ok = runKidnapPlayer(target)
        if ok then
            notify("FE kidnap", "Attempting to kidnap " .. tostring(target.Name) .. ".", 2.2)
        else
            notify("FE kidnap", "Could not kidnap target right now.", 2.8)
        end
    end)

    optionsSection:CreateToggle("Fling Click on person you want (toggle)", function(v)
        setClickFlingEnabled(v, false)
    end, false)

    optionsSection:CreateButton("Super fling", function()
        local target = getTrollTarget()
        if not target then
            notify("Super fling", "No valid target for mode: " .. targetMode, 2.4)
            return
        end
        local ok = runSuperFling(target)
        if ok then
            notify("Super fling", "Super flinging " .. tostring(target.Name) .. ".", 2.2)
        else
            notify("Super fling", "Could not fling target right now.", 2.8)
        end
    end)

    optionsSection:CreateButton("FE Zombie Animation/fling", function()
        local target = getTrollTarget()
        if not target then
            notify("FE Zombie Animation/fling", "No valid target for mode: " .. targetMode, 2.4)
            return
        end
        local ok = runZombieAnimationFling(target)
        if ok then
            notify("FE Zombie Animation/fling", "Zombie-flinging " .. tostring(target.Name) .. ".", 2.2)
        else
            notify("FE Zombie Animation/fling", "Could not run right now.", 2.8)
        end
    end)

    headsitButton = optionsSection:CreateButton("Headsit: OFF", function()
        local target = getTrollTarget()
        if not target then
            notify("Headsit", "No valid target for mode: " .. targetMode, 2.4)
            return
        end
        local enabled = setTrollLoopMode("Headsit")
        notify("Headsit", enabled and ("Now headsitting " .. tostring(target.Name) .. " (" .. targetMode .. ").") or "Headsit stopped.", 2.2)
    end)

    bangButton = optionsSection:CreateButton("Bang: OFF", function()
        local target = getTrollTarget()
        if not target then
            notify("Bang", "No valid target for mode: " .. targetMode, 2.4)
            return
        end
        local enabled = setTrollLoopMode("Bang")
        notify("Bang", enabled and ("Now banging " .. tostring(target.Name) .. " (" .. targetMode .. ").") or "Bang stopped.", 2.2)
    end)

    spinButton = optionsSection:CreateButton("Spin on Target: OFF", function()
        local target = getTrollTarget()
        if not target then
            notify("Spin", "No valid target for mode: " .. targetMode, 2.4)
            return
        end
        local enabled = setTrollLoopMode("Spin")
        notify("Spin", enabled and ("Now spinning on " .. tostring(target.Name) .. " (" .. targetMode .. ").") or "Spin stopped.", 2.2)
    end)

    annoyButton = optionsSection:CreateButton("Annoy Loop: OFF", function()
        local target = getTrollTarget()
        if not target then
            notify("Annoy", "No valid target for mode: " .. targetMode, 2.4)
            return
        end
        local enabled = setTrollLoopMode("Annoy")
        notify("Annoy", enabled and ("Now annoying " .. tostring(target.Name) .. " (" .. targetMode .. ").") or "Annoy loop stopped.", 2.2)
    end)

    -- optionsSection:CreateButton("Refresh Player List", function()
    --     refreshPlayerList()
    -- end)

    track(self.Connections, searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        playerSearchQuery = searchBox.Text or ""
        refreshPlayerList()
    end))

    track(self.Connections, playersTab.Page:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        updateListShellHeight()
    end))

    track(self.Connections, Players.PlayerAdded:Connect(function()
        refreshPlayerList()
    end))
    track(self.Connections, Players.PlayerRemoving:Connect(function(leavingPlayer)
        if selectedPlayer and leavingPlayer == selectedPlayer then
            selectedPlayer = nil
            if targetMode == "Selected" then
                stopTrollLoop()
            end
        end
        if spectateTarget and leavingPlayer == spectateTarget then
            stopSpectate()
        end
        refreshTargetSelectionLabels()
        refreshPlayerList()
    end))

    self:OnClose(function()
        setClickFlingEnabled(false, true)
        stopSpectate()
        stopTrollLoop()
        stopFlingAndRestore()
    end)

    setSelectedPlayer(UILibrary:GetSelectedPlayer())
    updateListShellHeight()
    task.defer(function()
        updateListShellHeight()
    end)
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

function Window:CreateLocalCategory(options)
    if self.LocalCategory then
        return self.LocalCategory
    end

    options = options or {}
    local localPlayer = Players.LocalPlayer
    if not localPlayer then
        return nil
    end
    local localTabIcon = options.TabIcon or options.Icon or "local"

    local localTab = nil
    for _, existingTab in ipairs(self.Tabs) do
        if existingTab.Name == "Local" then
            localTab = existingTab
            break
        end
    end
    if not localTab then
        localTab = self:CreateTab({ Name = "Local", Icon = localTabIcon })
    elseif localTab.SetIcon then
        localTab:SetIcon(localTabIcon)
    end

    local flySection = localTab:CreateSection({ Name = "Fly", Side = "Left" })
    local otherSection = localTab:CreateSection({ Name = "Other", Side = "Right" })

    local flyEnabled = false
    local flySpeed = tonumber(options.FlySpeed) or 80
    flySpeed = math.clamp(flySpeed, 20, 250)
    local flyKey = keycode(options.FlyKey) or Enum.KeyCode.F
    local flyControls = {
        Forward = false,
        Back = false,
        Left = false,
        Right = false,
        Up = false,
        Down = false,
    }
    local flyBV = nil
    local flyBG = nil

    local flingProtectEnabled = false
    local flingProtectSafeCFrame = nil
    local flingProtectStunUntil = 0
    local flingProtectViolation = 0

    local flyInputConnectionBegan = nil
    local flyInputConnectionEnded = nil
    local flyVelocityConnection = nil
    local flyCharacterAddedConnection = nil
    local flingProtectConnection = nil

    local flyToggleControl = nil

    local function notify(title, content, duration)
        UILibrary:Notify({
            Title = title,
            Content = content,
            Duration = duration or 2.2,
        })
    end

    local function getLocalRoot()
        local character = localPlayer.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end

    local function getLocalHumanoid()
        local character = localPlayer.Character
        return character and character:FindFirstChildOfClass("Humanoid")
    end

    local function stopFly()
        local humanoid = getLocalHumanoid()
        if humanoid then
            humanoid.PlatformStand = false
        end

        if flyBV then
            pcall(function()
                flyBV:Destroy()
            end)
            flyBV = nil
        end

        if flyBG then
            pcall(function()
                flyBG:Destroy()
            end)
            flyBG = nil
        end
    end

    local function startFly()
        local rootPart = getLocalRoot()
        local humanoid = getLocalHumanoid()
        if not rootPart or not humanoid then
            return false
        end

        if flyBV then
            flyBV:Destroy()
            flyBV = nil
        end
        if flyBG then
            flyBG:Destroy()
            flyBG = nil
        end

        flyBG = Instance.new("BodyGyro")
        flyBG.Name = "LimboFlyBG"
        flyBG.P = 9e4
        flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBG.CFrame = rootPart.CFrame
        flyBG.Parent = rootPart

        flyBV = Instance.new("BodyVelocity")
        flyBV.Name = "LimboFlyBV"
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.Parent = rootPart

        humanoid.PlatformStand = true
        return true
    end

    local function setControlFromKey(keyCode, isDown)
        if keyCode == Enum.KeyCode.W then
            flyControls.Forward = isDown
        elseif keyCode == Enum.KeyCode.S then
            flyControls.Back = isDown
        elseif keyCode == Enum.KeyCode.A then
            flyControls.Left = isDown
        elseif keyCode == Enum.KeyCode.D then
            flyControls.Right = isDown
        elseif keyCode == Enum.KeyCode.Space then
            flyControls.Up = isDown
        elseif keyCode == Enum.KeyCode.LeftControl then
            flyControls.Down = isDown
        end
    end

    local function updateFlyVelocity()
        if not flyEnabled or not flyBV or not flyBG then
            return
        end

        local rootPart = getLocalRoot()
        if not rootPart then
            stopFly()
            flyEnabled = false
            if flyToggleControl and flyToggleControl.Set then
                flyToggleControl:Set(false, true)
            end
            return
        end

        local cam = workspace.CurrentCamera
        if not cam then
            return
        end

        local move = Vector3.new(0, 0, 0)
        if flyControls.Forward then
            move = move + cam.CFrame.LookVector
        end
        if flyControls.Back then
            move = move - cam.CFrame.LookVector
        end
        if flyControls.Left then
            move = move - cam.CFrame.RightVector
        end
        if flyControls.Right then
            move = move + cam.CFrame.RightVector
        end
        if flyControls.Up then
            move = move + Vector3.new(0, 1, 0)
        end
        if flyControls.Down then
            move = move - Vector3.new(0, 1, 0)
        end

        if move.Magnitude > 0 then
            move = move.Unit * flySpeed
        end

        flyBV.Velocity = move
        flyBG.CFrame = cam.CFrame
    end

    local function setFlyEnabled(state, silent)
        state = state == true
        if state == flyEnabled then
            return
        end

        flyEnabled = state
        if flyEnabled then
            local ok = startFly()
            if not ok then
                flyEnabled = false
                if not silent then
                    notify("Fly", "Character not ready.", 1.8)
                end
                return
            end
        else
            stopFly()
        end
    end

    local function resetFlingProtectState()
        flingProtectSafeCFrame = nil
        flingProtectStunUntil = 0
        flingProtectViolation = 0
    end

    local function setFlingProtectEnabled(state)
        flingProtectEnabled = state == true
        if flingProtectEnabled then
            local root = getLocalRoot()
            if root then
                flingProtectSafeCFrame = root.CFrame
            end
            flingProtectStunUntil = 0
            flingProtectViolation = 0
        else
            resetFlingProtectState()
        end
        notify("Fling Protect", flingProtectEnabled and "Enabled." or "Disabled.", 1.8)
    end

    flyInputConnectionBegan = track(self.Connections, UIS.InputBegan:Connect(function(input, gpe)
        if gpe then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        local key = input.KeyCode
        if key == flyKey then
            local newState = not flyEnabled
            if flyToggleControl and flyToggleControl.Set then
                flyToggleControl:Set(newState, true)
            end
            setFlyEnabled(newState, false)
        end
        setControlFromKey(key, true)
    end))
    flyInputConnectionEnded = track(self.Connections, UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            setControlFromKey(input.KeyCode, false)
        end
    end))

    flyVelocityConnection = track(self.Connections, RunService.Heartbeat:Connect(function()
        updateFlyVelocity()
    end))

    flyCharacterAddedConnection = track(self.Connections, localPlayer.CharacterAdded:Connect(function()
        task.defer(function()
            if flyEnabled then
                startFly()
            end
        end)
    end))

    flingProtectConnection = track(self.Connections, RunService.Heartbeat:Connect(function()
        if not flingProtectEnabled then
            return
        end
        if flyEnabled then
            return
        end
        if UILibrary:IsFlingProtectSuspended() then
            local root = getLocalRoot()
            if root then
                flingProtectSafeCFrame = root.CFrame
            end
            flingProtectViolation = 0
            flingProtectStunUntil = 0
            return
        end

        local root = getLocalRoot()
        local humanoid = getLocalHumanoid()
        if not root or not humanoid then
            return
        end
        if humanoid.Sit or humanoid.SeatPart then
            return
        end

        local now = os.clock()

        local lv = root.AssemblyLinearVelocity
        local av = root.AssemblyAngularVelocity
        local horiz = Vector3.new(lv.X, 0, lv.Z).Magnitude
        local vert = math.abs(lv.Y)
        local spin = av.Magnitude

        local suspicious = horiz > 90 or spin > 45 or vert > 105
        local extreme = horiz > 180 or spin > 105 or vert > 175

        if not suspicious then
            if horiz < 36 and spin < 20 and vert < 40 then
                flingProtectSafeCFrame = root.CFrame
            end
            flingProtectViolation = math.max(0, flingProtectViolation - 0.35)
        else
            flingProtectViolation = math.min(4, flingProtectViolation + (extreme and 1.9 or 0.7))
        end

        if extreme or flingProtectViolation > 2 then
            local oldPos = root.Position
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            root.AssemblyLinearVelocity = Vector3.new(0, math.clamp(lv.Y, -20, 20), 0)

            if flingProtectSafeCFrame then
                local safePos = flingProtectSafeCFrame.Position
                if (oldPos - safePos).Magnitude > 16 then
                    root.CFrame = flingProtectSafeCFrame + Vector3.new(0, 2.5, 0)
                end
            end

            if humanoid.Sit then
                humanoid.Sit = false
            end
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            flingProtectViolation = 0
            flingProtectStunUntil = now + 0.32
            return
        end

        if now < flingProtectStunUntil then
            root.AssemblyLinearVelocity = Vector3.new(lv.X * 0.14, math.clamp(lv.Y, -28, 28), lv.Z * 0.14)
            root.AssemblyAngularVelocity = av * 0.08
            return
        end

        if suspicious then
            root.AssemblyLinearVelocity = Vector3.new(lv.X * 0.3, math.clamp(lv.Y, -42, 42), lv.Z * 0.3)
            root.AssemblyAngularVelocity = av * 0.2
        end
    end))

    flyToggleControl = flySection:CreateToggle("Fly", function(v)
        setFlyEnabled(v, true)
    end, false)

    flySection:CreateKeybind("Fly Toggle Key", function(key, changed)
        if changed then
            flyKey = key
            notify("Fly Keybind", "Set to " .. tostring(key.Name) .. ".", 1.8)
        end
    end, flyKey)

    flySection:CreateSlider("Fly Speed", 20, 400, flySpeed, function(v)
        flySpeed = tonumber(v) or flySpeed
    end)
    flySection:CreateLabel("Fly controls: WASD + Space/Ctrl")

    otherSection:CreateToggle("Fling Protect", function(v)
        setFlingProtectEnabled(v)
    end, false)

    self:OnClose(function()
        setFlyEnabled(false, true)
        flingProtectEnabled = false
        resetFlingProtectState()
        flyControls.Forward = false
        flyControls.Back = false
        flyControls.Left = false
        flyControls.Right = false
        flyControls.Up = false
        flyControls.Down = false
    end)

    self.LocalCategory = {
        Tab = localTab,
        FlySection = flySection,
        OtherSection = otherSection,
        SetFlyEnabled = function(_, state)
            if flyToggleControl and flyToggleControl.Set then
                flyToggleControl:Set(state == true, true)
            end
            setFlyEnabled(state == true, true)
        end,
        GetFlyEnabled = function()
            return flyEnabled
        end,
        SetFlySpeed = function(_, speed)
            flySpeed = math.clamp(tonumber(speed) or flySpeed, 20, 400)
        end,
        GetFlySpeed = function()
            return flySpeed
        end,
        SetFlingProtect = function(_, state)
            setFlingProtectEnabled(state == true)
        end,
        GetFlingProtect = function()
            return flingProtectEnabled
        end,
    }

    return self.LocalCategory
end

function Window:CreateRemotesCategory(options)
    if self.RemotesCategory then
        return self.RemotesCategory
    end

    options = options or {}
    local remotesTabIcon = "scripts"
    local defaultSourceUrl = "https://raw.githubusercontent.com/coder-isxt/roblox/refs/heads/main/simplespy.lua"
    local sourcePath = tostring(options.SourcePath or options.Source or defaultSourceUrl)
    local sourceUrl = options.SourceUrl or options.Url
    if type(sourceUrl) == "string" and sourceUrl == "" then
        sourceUrl = nil
    end
    if not sourceUrl and (string.sub(sourcePath, 1, 7) == "http://" or string.sub(sourcePath, 1, 8) == "https://") then
        sourceUrl = sourcePath
    end

    local remotesTab = nil
    for _, existingTab in ipairs(self.Tabs) do
        if existingTab.Name == "Remotes" then
            remotesTab = existingTab
            break
        end
    end
    if not remotesTab then
        remotesTab = self:CreateTab({ Name = "Remotes", Icon = remotesTabIcon })
    elseif remotesTab.SetIcon then
        remotesTab:SetIcon(remotesTabIcon)
    end

    local logsSection = remotesTab:CreateSection({ Name = "Logs", Side = "Left" })
    local actionsSection = remotesTab:CreateSection({ Name = "Controls", Side = "Right" })
    local settingsSection = remotesTab:CreateSection({ Name = "Status", Side = "Right" })
    local scriptSection = remotesTab:CreateSection({ Name = "Script", Side = "Right" })
    settingsSection.Frame.LayoutOrder = 10
    actionsSection.Frame.LayoutOrder = 20
    scriptSection.Frame.LayoutOrder = 30
    local selectedLabel = settingsSection:CreateLabel("Selected: None")
    local selectedMetaLabel = settingsSection:CreateLabel("Method: - | Time: -")
    local selectedTypeLabel = settingsSection:CreateLabel("Type: -")
    local logsHintLabel = logsSection:CreateLabel("Select a log entry, then use Controls.")
    logsHintLabel.Frame.LayoutOrder = -1000000
    scriptSection:CreateLabel("Latest generated script for selected log.")

    local function iconizeRemoteLabel(text)
        local value = tostring(text or "")
        local eventIcon = (utf8 and utf8.char and utf8.char(0x1F4E1)) or "[event]"
        local functionIcon = (utf8 and utf8.char and utf8.char(0x2699)) or "[func]"
        if string.sub(value, 1, 3) == "[E]" then
            return eventIcon .. " " .. string.gsub(string.sub(value, 4), "^%s*", "")
        end
        if string.sub(value, 1, 3) == "[F]" then
            return functionIcon .. " " .. string.gsub(string.sub(value, 4), "^%s*", "")
        end
        return value
    end

    local hostLogSection = setmetatable({}, {
        __index = logsSection,
    })
    local newestLogOrder = 0
    local function applyNewestTopOrder(control)
        newestLogOrder -= 1
        if control and control.Frame then
            control.Frame.LayoutOrder = newestLogOrder
        end
        return control
    end
    function hostLogSection:CreateButton(a, b)
        if typeof(a) == "table" then
            local payload = {}
            for k, v in pairs(a) do
                payload[k] = v
            end
            if payload.Name then
                payload.Name = iconizeRemoteLabel(payload.Name)
            end
            if payload.Text then
                payload.Text = iconizeRemoteLabel(payload.Text)
            end
            return applyNewestTopOrder(logsSection:CreateButton(payload, b))
        end
        return applyNewestTopOrder(logsSection:CreateButton(iconizeRemoteLabel(a), b))
    end

    local scriptShell = mk("Frame", {
        Parent = scriptSection.Content,
        BackgroundColor3 = Color3.fromRGB(8, 12, 20),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 220),
    })
    corner(scriptShell, 4)
    stroke(scriptShell, C.Stroke, 0.55)

    local scriptScroll = mk("ScrollingFrame", {
        Parent = scriptShell,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0, 6),
        Size = UDim2.new(1, -12, 1, -12),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = C.Stroke,
    })

    local scriptBox = mk("TextBox", {
        Parent = scriptScroll,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, -2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = false,
        MultiLine = true,
        ClearTextOnFocus = false,
        TextEditable = false,
        TextColor3 = C.Text,
        PlaceholderColor3 = C.SubText,
        PlaceholderText = "-- Script will appear here",
        Text = "",
    })

    local cachedCode = ""
    local function refreshScriptCanvas()
        local h = math.max(scriptBox.TextBounds.Y + 10, scriptScroll.AbsoluteSize.Y)
        scriptScroll.CanvasSize = UDim2.new(0, 0, 0, h)
    end
    track(self.Connections, scriptBox:GetPropertyChangedSignal("TextBounds"):Connect(refreshScriptCanvas))
    track(self.Connections, scriptScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshScriptCanvas))

    local function setCode(text)
        cachedCode = tostring(text or "")
        scriptBox.Text = cachedCode
        refreshScriptCanvas()
    end
    local function getCode()
        local current = tostring(scriptBox.Text or cachedCode or "")
        cachedCode = current
        return current
    end
    local function setSelectionText(text)
        local value = tostring(text or "None")
        if selectedLabel and selectedLabel.Set then
            selectedLabel:Set("Selected: " .. value)
        end
        if selectedMetaLabel and selectedMetaLabel.Set then
            selectedMetaLabel:Set("Method: - | Time: -")
        end
        if selectedTypeLabel and selectedTypeLabel.Set then
            selectedTypeLabel:Set("Type: -")
        end
    end
    local function setSelectionInfo(info)
        if typeof(info) ~= "table" then
            setSelectionText(info)
            return
        end

        local name = tostring(info.Name or "None")
        local method = tostring(info.Method or "-")
        local ts = tostring(info.Time or "-")
        local rtype = tostring(info.Type or "-")

        if selectedLabel and selectedLabel.Set then
            selectedLabel:Set("Selected: " .. name)
        end
        if selectedMetaLabel and selectedMetaLabel.Set then
            selectedMetaLabel:Set(string.format("Method: %s | Time: %s", method, ts))
        end
        if selectedTypeLabel and selectedTypeLabel.Set then
            selectedTypeLabel:Set("Type: " .. rtype)
        end
    end

    local genv = (typeof(getgenv) == "function" and getgenv()) or _G

    if genv.SimpleSpyExecuted and type(genv.SimpleSpyShutdown) == "function" then
        pcall(genv.SimpleSpyShutdown)
    end

    genv.__SimpleSpyHost = {
        Library = UILibrary,
        Window = self,
        LogSection = hostLogSection,
        ActionSection = actionsSection,
        SettingsSection = settingsSection,
        SetCode = function(_, text)
            setCode(text)
        end,
        GetCode = function(_)
            return getCode()
        end,
        SetSelection = function(_, text)
            setSelectionText(text)
        end,
        SetSelectionInfo = function(_, info)
            setSelectionInfo(info)
        end,
    }

    local loaded = false
    local loadErr = nil
    local chunk = nil

    if not chunk and typeof(loadstring) == "function" and type(sourceUrl) == "string" and sourceUrl ~= "" then
        local okHttp, bodyOrErr = pcall(function()
            return game:HttpGet(sourceUrl)
        end)
        if okHttp and type(bodyOrErr) == "string" and bodyOrErr ~= "" then
            local compiled, compileErr = loadstring(bodyOrErr)
            if compiled then
                chunk = compiled
            else
                loadErr = compileErr
            end
        else
            loadErr = bodyOrErr
        end
    end

    if not chunk and typeof(loadfile) == "function" and typeof(isfile) == "function" and isfile(sourcePath) then
        local okChunk, result = pcall(loadfile, sourcePath)
        if okChunk then
            chunk = result
        else
            loadErr = result
        end
    end

    if not chunk and typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(sourcePath) and typeof(loadstring) == "function" then
        local okRead, source = pcall(readfile, sourcePath)
        if okRead and type(source) == "string" and source ~= "" then
            local compiled, compileErr = loadstring(source)
            if compiled then
                chunk = compiled
            else
                loadErr = compileErr
            end
        end
    end

    if chunk then
        local okRun, runErr = pcall(chunk)
        loaded = okRun
        if not okRun then
            loadErr = runErr
        end
    else
        loadErr = loadErr or ("SimpleSpy source not found. url=" .. tostring(sourceUrl) .. " path=" .. tostring(sourcePath))
    end

    genv.__SimpleSpyHost = nil

    if loaded then
        UILibrary:NotifyInfo({
            Title = "Remotes",
            Content = "Remotes loaded, spy them in Remotes.",
            Duration = 2.2,
        })
    else
        local errText = tostring(loadErr or "unknown error")
        actionsSection:CreateLabel("SimpleSpy load failed.")
        settingsSection:CreateParagraph("Error", errText)
        UILibrary:NotifyError({
            Title = "Remotes",
            Content = "SimpleSpy failed to load. See Remotes tab for details.",
            Duration = 4,
        })
    end

    self:OnClose(function()
        if genv.SimpleSpyExecuted and type(genv.SimpleSpyShutdown) == "function" then
            pcall(genv.SimpleSpyShutdown)
        end
    end)

    self.RemotesCategory = {
        Tab = remotesTab,
        LogsSection = logsSection,
        ActionsSection = actionsSection,
        SettingsSection = settingsSection,
        ScriptSection = scriptSection,
        SetCode = setCode,
        GetCode = getCode,
        SetSelection = setSelectionText,
        SetSelectionInfo = setSelectionInfo,
        SourceUrl = sourceUrl,
        SourcePath = sourcePath,
        Loaded = loaded,
        Error = loadErr,
    }

    return self.RemotesCategory
end

function Window:CreateUniversalCategory(options)
    if self.UniversalCategory then
        return self.UniversalCategory
    end

    options = options or {}
    local universalTabIcon = options.TabIcon or options.Icon or "universal"

    local universalTab = nil
    for _, existingTab in ipairs(self.Tabs) do
        if existingTab.Name == "Universal" then
            universalTab = existingTab
            break
        end
    end
    if not universalTab then
        universalTab = self:CreateTab({ Name = "Universal", Icon = universalTabIcon })
    elseif universalTab.SetIcon then
        universalTab:SetIcon(universalTabIcon)
    end

    local otherSection = universalTab:CreateSection({ Name = "Other", Side = "Left" })
    local infoSection = universalTab:CreateSection({ Name = "Info", Side = "Right" })
    local developerEnabled = false
    local remotesAllowed = self._remotesAllowed ~= false
    local remotesOptions = self._remotesOptions or {}

    local function notify(title, content, duration)
        UILibrary:Notify({
            Title = title,
            Content = content,
            Duration = duration or 2.4,
        })
    end

    local function removeTab(tabRef)
        if not tabRef then
            return
        end

        if self.ActiveTab == tabRef then
            self:SelectTab(universalTab)
        end

        for i = #self.Tabs, 1, -1 do
            if self.Tabs[i] == tabRef then
                table.remove(self.Tabs, i)
                break
            end
        end

        if tabRef.Button and tabRef.Button.Parent then
            tabRef.Button:Destroy()
        end
        if tabRef.Page and tabRef.Page.Parent then
            tabRef.Page:Destroy()
        end

        if self.SectionsLabel then
            local hasCustom = false
            for _, t in ipairs(self.Tabs) do
                if not isPersistentTabName(t.Name) then
                    hasCustom = true
                    break
                end
            end
            self.SectionsLabel.Visible = hasCustom
        end
    end

    local function removeRemotesTab()
        local category = self.RemotesCategory
        if not category then
            return
        end
        local tabRef = category.Tab
        local genv = (typeof(getgenv) == "function" and getgenv()) or _G
        if genv.SimpleSpyExecuted and type(genv.SimpleSpyShutdown) == "function" then
            pcall(genv.SimpleSpyShutdown)
        end
        self.RemotesCategory = nil
        removeTab(tabRef)
    end

    local function setDeveloperEnabled(state, silent)
        state = state == true
        if developerEnabled == state then
            return
        end
        developerEnabled = state

        if developerEnabled then
            if remotesAllowed then
                self:CreateRemotesCategory(remotesOptions)
            end
        else
            removeRemotesTab()
        end

        if not silent then
            notify("Developer", developerEnabled and "Enabled." or "Disabled.", 1.9)
        end
    end

    local developerToggle = otherSection:CreateToggle("Developer", function(v)
        setDeveloperEnabled(v, false)
    end, options.DeveloperEnabled == true)
    local function runExternalLoader(name, url, useAsync)
        local ok, err = pcall(function()
            local source
            if useAsync and type(game.HttpGetAsync) == "function" then
                source = game:HttpGetAsync(url)
            else
                source = game:HttpGet(url)
            end
            local compiled, compileErr = loadstring(source)
            if not compiled then
                error(compileErr or "loadstring compile failed")
            end
            compiled()
        end)
        if ok then
            notify(name, "Loaded.", 2.0)
        else
            UILibrary:NotifyError({
                Title = name,
                Content = tostring(err),
                Duration = 3.2,
            })
        end
    end
    otherSection:CreateButton("Load Remotespy", function()
        runExternalLoader("Load Remotespy", "https://rawscripts.net/raw/Universal-Script-RemoteSpy-for-Xeno-and-Solara-32578", false)
    end)
    otherSection:CreateButton("Load SimpleSpy", function()
        runExternalLoader("Load SimpleSpy", "https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua", true)
    end)
    otherSection:CreateButton("Load DevEx", function()
        runExternalLoader("Load DevEx", "https://rawscripts.net/raw/Universal-Script-Dex-with-tags-78265", false)
    end)

    otherSection:CreateParagraph("Universal", "Persistent tab for cross-game tools.")
    otherSection:CreateLabel("Remotes tab is available only in Developer mode.")
    infoSection:CreateParagraph("Developer Tabs", "Developer mode enables Remotes.")
    infoSection:CreateLabel("Turn Developer on to use SimpleSpy remotes.")

    setDeveloperEnabled(options.DeveloperEnabled == true, true)

    self.UniversalCategory = {
        Tab = universalTab,
        InfoSection = infoSection,
        DeveloperSection = infoSection,
        UniversalSection = otherSection,
        OtherSection = otherSection,
        DeveloperToggle = developerToggle,
        SetDeveloperEnabled = function(_, state)
            if developerToggle and developerToggle.Set then
                developerToggle:Set(state == true, true)
            end
            setDeveloperEnabled(state == true, true)
        end,
        GetDeveloperEnabled = function()
            return developerEnabled
        end,
        GetDeveloperTabs = function()
            return self.RemotesCategory and self.RemotesCategory.Tab or nil
        end,
        Options = options,
    }

    return self.UniversalCategory
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
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Text = tostring(text or ""),
    })

    local function refreshHeight()
        local needed = math.max(24, lbl.TextBounds.Y + 2)
        shell.Size = UDim2.new(1, 0, 0, needed)
    end
    track(self.Window.Connections, lbl:GetPropertyChangedSignal("Text"):Connect(refreshHeight))
    track(self.Window.Connections, lbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshHeight))
    task.defer(refreshHeight)

    return {
        Frame = shell,
        Label = lbl,
        Set = function(_, v)
            lbl.Text = tostring(v or "")
            refreshHeight()
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

function Section:SetSide(side)
    local requested = normalizeSectionSide(side)
    local column, resolved = self.Tab:_column(requested)
    self.Frame.Parent = column
    self.RequestedSide = requested
    self.Side = requested
    self.ResolvedSide = resolved
    return self
end

function Section:GetSide()
    return self.RequestedSide or self.Side or "Left", self.ResolvedSide
end

function Tab:_column(side)
    local requested = normalizeSectionSide(side)
    return (requested == "Right") and self.Right or self.Left, requested
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
    local requestedSide = normalizeSectionSide(side)
    local column, resolvedSide = self:_column(requestedSide)

    local frame = mk("Frame", {
        Name = name .. "_Section",
        Parent = column,
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
        RequestedSide = requestedSide,
        Side = requestedSide,
        ResolvedSide = resolvedSide,
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

function Tab:SetIcon(iconSpec)
    self.Icon = iconSpec
    if self._ApplyIcon then
        self:_ApplyIcon(iconSpec)
    end
    return self
end

function Tab:GetIcon()
    return self.Icon
end

function Window:CreateTab(a, iconMaybe)
    local name, icon, requestedLayoutOrder = "Tab", nil, nil
    if typeof(a) == "table" then
        name = tostring(a.Name or a.Title or "Tab")
        icon = a.Icon
        requestedLayoutOrder = tonumber(a.LayoutOrder)
    else
        name = tostring(a or "Tab")
        icon = iconMaybe
    end
    local tabNameLower = string.lower(name)
    local tabLayoutOrder = nil

    if requestedLayoutOrder then
        tabLayoutOrder = requestedLayoutOrder
    elseif tabNameLower == "local" then
        tabLayoutOrder = 10
    elseif tabNameLower == "players" then
        tabLayoutOrder = 20
    elseif tabNameLower == "universal" then
        tabLayoutOrder = 30
    elseif tabNameLower == "remotes" then
        tabLayoutOrder = 40
    elseif tabNameLower == "scripts" then
        tabLayoutOrder = 50
    else
        tabLayoutOrder = self.NextCustomTabOrder or 200
        self.NextCustomTabOrder = tabLayoutOrder + 1
        if self.SectionsLabel then
            self.SectionsLabel.Visible = true
        end
    end

    local btn = mk("TextButton", {
        Parent = self.TabList,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 28),
        LayoutOrder = tabLayoutOrder,
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
    local iconImageLabel = mk("ImageLabel", {
        Parent = iconHolder,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ImageColor3 = C.SubText,
        Visible = false,
    })
    local iconTextLabel = mk("TextLabel", {
        Parent = iconHolder,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = FONT,
        TextSize = 11,
        TextColor3 = C.SubText,
        Text = "",
        Visible = false,
    })
    local iconDot = mk("Frame", {
        Parent = iconHolder,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 6, 0, 6),
        BackgroundColor3 = C.SubText,
        BorderSizePixel = 0,
        Visible = false,
    })
    corner(iconDot, 99)

    local function applyIcon(iconSpec)
        local resolvedImage, resolvedFallback = resolveIconSpec(iconSpec)

        iconImageLabel.Visible = false
        iconTextLabel.Visible = false
        iconDot.Visible = false

        if resolvedImage then
            iconImageLabel.Image = resolvedImage
            iconImageLabel.Visible = true
        elseif typeof(resolvedFallback) == "string" and resolvedFallback ~= "" then
            iconTextLabel.Text = string.sub(string.upper(resolvedFallback), 1, 3)
            iconTextLabel.Visible = true
        else
            iconDot.Visible = true
        end
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
        Icon = nil,
        Window = self,
        Button = btn,
        ButtonBack = back,
        Indicator = ind,
        Label = lbl,
        IconHolder = iconHolder,
        IconImageLabel = iconImageLabel,
        IconTextLabel = iconTextLabel,
        IconDot = iconDot,
        Page = page,
        Left = left,
        Right = right,
        Sections = {},
        DefaultSection = nil,
        _ApplyIcon = applyIcon,
    }, Tab)
    tab:SetIcon(icon)

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
    local sectionsLabel = mk("TextLabel", {
        Parent = tabList,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = FONT,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.SubText,
        Text = "Sections",
        LayoutOrder = 150,
        Visible = false,
    })
    mk("UIPadding", {
        Parent = sectionsLabel,
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 2),
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
        SectionsLabel = sectionsLabel,
        PageHolder = pageHolder,
        Tabs = {},
        ActiveTab = nil,
        NextCustomTabOrder = 200,
        Connections = {},
        CloseCallbacks = {},
        ToggleKey = toggleKey,
        VisibleState = false,
        Animating = false,
        InitAnimationPlayed = false,
        CleanupRan = false,
        Destroyed = false,
    }, Window)
    w._remotesAllowed = o.IncludeRemotes ~= false
    w._remotesOptions = o.RemotesOptions or {}

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
    track(w.Connections, sg.Destroying:Connect(function()
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

    if o.IncludeLocal ~= false then
        task.defer(function()
            if w and not w.Destroyed then
                pcall(function()
                    w:CreateLocalCategory(o.LocalOptions)
                end)
            end
        end)
    end

    if o.IncludeUniversal ~= false then
        task.defer(function()
            if w and not w.Destroyed then
                pcall(function()
                    w:CreateUniversalCategory(o.UniversalOptions)
                end)
            end
        end)
    end

    if o.IncludeRemotes ~= false and o.IncludeUniversal == false then
        task.defer(function()
            if w and not w.Destroyed then
                pcall(function()
                    w:CreateRemotesCategory(o.RemotesOptions)
                end)
            end
        end)
    end

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
    task.defer(function()
        if w and not w.Destroyed then
            w:PlayInitializeAnimation()
        end
    end)
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

