local UILibrary = {}

--[[
    library_v2.lua layout
    1) Services
    2) Definitions / Variables
    3) Shared Helper Functions
    4) Core Object Methods
    5) UI Category Builders
    6) UI Control Builders
    7) Public API
]]

-- Services
local Services = {
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
}

-- Service aliases kept for compatibility/readability in existing code
local TweenService = Services.TweenService
local UIS = Services.UserInputService
local Players = Services.Players
local RunService = Services.RunService

-- Definitions / Variables
local FONT = Enum.Font.Gotham
local GUI_NAME = "LimboLibrary"
local OPEN_DROPDOWNS = {}
local BUILTIN_ICON_ALIASES = {
    ["local"] = {
        Image = "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png",
        Fallback = "L",
    },
    ["players"] = {
        Image = "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon.png",
        Fallback = "P",
    },
    ["config"] = {
        Image = "rbxasset://textures/ui/Settings/icon_localization-16.png",
        Fallback = "C",
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

-- Shared Helper Functions
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
    if typeof(v) == "string" and v ~= "" then
        local ok, k = pcall(function()
            return Enum.KeyCode[v]
        end)
        if ok then
            return k
        end
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

-- Core Object Definitions
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

-- Core Object Methods
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

-- UI Category Builders
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
    local punchFlingEnabled = false
    local punchFlingConnection = nil
    local punchFlingCooldownUntil = 0
    local punchAnimationIds
    if type(options.PunchAnimationIds) == "table" and #options.PunchAnimationIds > 0 then
        punchAnimationIds = options.PunchAnimationIds
    elseif options.PunchAnimationId then
        punchAnimationIds = { tostring(options.PunchAnimationId) }
    else
        punchAnimationIds = {
            "913402848",
            "180426354",
        }
    end
    local punchAnimationId = tostring(punchAnimationIds[1] or "913402848")
    local punchAnimationIndex = 0
    local punchActivateRange = tonumber(options.PunchActivateRange) or 180
    local punchRange = tonumber(options.PunchRange) or 15
    local punchReachPadding = tonumber(options.PunchReachPadding) or 4
    local punchApproachSpeed = tonumber(options.PunchApproachSpeed) or 64
    local punchApproachTimeout = tonumber(options.PunchApproachTimeout) or 2.4
    local punchStepTeleport = tonumber(options.PunchStepTeleport) or 6
    local punchAnimationSpeed = tonumber(options.PunchAnimationSpeed) or 3.15
    local punchAnimationVisibleTime = tonumber(options.PunchAnimationVisibleTime) or 2.2
    local punchSpamInterval = tonumber(options.PunchSpamInterval) or 0.045
    local punchFlingDuration = tonumber(options.PunchFlingDuration) or 2
    local punchAnimationTrack = nil
    local punchAnimationSpamConnection = nil

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

    local function getLocalHumanoid()
        local character = localPlayer.Character
        return character and character:FindFirstChildOfClass("Humanoid")
    end

    local function getTargetRoot(player)
        local character = player and player.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end

    local function getTargetHum(player)
        local character = player and player.Character
        return character and character:FindFirstChildOfClass("Humanoid")
    end

    local function getDistanceToTarget(player)
        local localRoot = getLocalRoot()
        local targetRoot = getTargetRoot(player)
        if not localRoot or not targetRoot then
            return math.huge
        end
        return (localRoot.Position - targetRoot.Position).Magnitude
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
        local restoreCFrame = (typeof(flingOptions.RestoreCFrame) == "CFrame" and flingOptions.RestoreCFrame) or localRoot.CFrame
        local targetStartPos = targetRoot.Position
        local targetMoveStopDistance = math.max(0, tonumber(flingOptions.TargetMoveStopDistance) or 20)

        UILibrary:SuspendFlingProtect(duration + 0.9)
        stopFlingAndRestore()

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
                currentRoot.CFrame = restoreCFrame
                local hum = getLocalHumanoid()
                if hum then
                    hum.PlatformStand = false
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
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

            if targetMoveStopDistance > 0 then
                local movedDistance = (currentTargetRoot.Position - targetStartPos).Magnitude
                if movedDistance >= targetMoveStopDistance then
                    restore()
                    return
                end
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

    local function stopPunchAnimation()
        if punchAnimationSpamConnection then
            punchAnimationSpamConnection:Disconnect()
            punchAnimationSpamConnection = nil
        end
        if punchAnimationTrack then
            pcall(function()
                punchAnimationTrack:Stop(0)
                punchAnimationTrack:Destroy()
            end)
            punchAnimationTrack = nil
        end
    end

    local function loadNextPunchAnimationTrack()
        local humanoid = getLocalHumanoid()
        if not humanoid then
            return nil
        end

        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = humanoid
        end

        if type(punchAnimationIds) == "table" and #punchAnimationIds > 0 then
            punchAnimationIndex += 1
            if punchAnimationIndex > #punchAnimationIds then
                punchAnimationIndex = 1
            end
            local nextId = punchAnimationIds[punchAnimationIndex]
            if nextId then
                punchAnimationId = tostring(nextId)
            end
        end

        local animation = Instance.new("Animation")
        if string.find(punchAnimationId, "rbxassetid://", 1, true) then
            animation.AnimationId = tostring(punchAnimationId)
        else
            animation.AnimationId = "rbxassetid://" .. tostring(punchAnimationId)
        end

        local ok, track = pcall(function()
            return animator:LoadAnimation(animation)
        end)
        animation:Destroy()
        if not ok then
            return nil
        end
        return track
    end

    local function runToTargetForPunch(player)
        local localRoot = getLocalRoot()
        local targetRoot = getTargetRoot(player)
        if not localRoot or not targetRoot then
            return false
        end

        local timeoutAt = os.clock() + punchApproachTimeout
        while os.clock() < timeoutAt do
            localRoot = getLocalRoot()
            targetRoot = getTargetRoot(player)
            if not localRoot or not targetRoot then
                break
            end

            local distance = (localRoot.Position - targetRoot.Position).Magnitude
            if distance <= (punchRange + punchReachPadding) then
                return true
            end

            local toward = targetRoot.Position - localRoot.Position
            local planar = Vector3.new(toward.X, 0, toward.Z)
            if planar.Magnitude > 0.001 then
                local unit = planar.Unit
                localRoot.CFrame = CFrame.lookAt(
                    localRoot.Position,
                    Vector3.new(targetRoot.Position.X, localRoot.Position.Y, targetRoot.Position.Z)
                )
                localRoot.AssemblyLinearVelocity = Vector3.new(
                    unit.X * punchApproachSpeed,
                    localRoot.AssemblyLinearVelocity.Y,
                    unit.Z * punchApproachSpeed
                )

                if distance > (punchRange + punchReachPadding + 5) and punchStepTeleport > 0 then
                    local step = math.min(punchStepTeleport, math.max(0, distance - (punchRange + punchReachPadding)))
                    if step > 0 then
                        local stepPos = localRoot.Position + (unit * step)
                        localRoot.CFrame = CFrame.lookAt(
                            stepPos,
                            Vector3.new(targetRoot.Position.X, stepPos.Y, targetRoot.Position.Z)
                        )
                    end
                end
            end

            RunService.Heartbeat:Wait()
        end
        return getDistanceToTarget(player) <= (punchRange + punchReachPadding)
    end

    local function playRunAnimationSpam(duration, targetPlayer)
        stopPunchAnimation()
        local track = loadNextPunchAnimationTrack()
        if not track then
            return false
        end

        punchAnimationTrack = track
        local stopAt = os.clock() + math.max(0.3, tonumber(duration) or 0.3)
        local nextRestartAt = 0

        pcall(function()
            track.Looped = true
            track:Play(0.02, 1, punchAnimationSpeed)
        end)

        punchAnimationSpamConnection = RunService.Heartbeat:Connect(function()
            if os.clock() >= stopAt then
                stopPunchAnimation()
                return
            end

            if targetPlayer and targetPlayer.Parent == Players then
                local localRoot = getLocalRoot()
                local targetRoot = getTargetRoot(targetPlayer)
                if localRoot and targetRoot then
                    local toward = targetRoot.Position - localRoot.Position
                    local planar = Vector3.new(toward.X, 0, toward.Z)
                    if planar.Magnitude > 0.001 then
                        local unit = planar.Unit
                        localRoot.CFrame = CFrame.lookAt(
                            localRoot.Position,
                            Vector3.new(targetRoot.Position.X, localRoot.Position.Y, targetRoot.Position.Z)
                        )
                        localRoot.AssemblyLinearVelocity = Vector3.new(
                            unit.X * (punchApproachSpeed + 18),
                            localRoot.AssemblyLinearVelocity.Y,
                            unit.Z * (punchApproachSpeed + 18)
                        )
                    end
                end
            end

            if os.clock() >= nextRestartAt then
                nextRestartAt = os.clock() + math.max(0.01, punchSpamInterval)
                if punchAnimationTrack then
                    pcall(function()
                        punchAnimationTrack:Stop(0)
                        punchAnimationTrack:Play(0, 1, punchAnimationSpeed + 0.75)
                    end)
                end
            end
        end)

        task.delay(math.max(duration, punchAnimationVisibleTime) + 0.15, function()
            stopPunchAnimation()
        end)
        return true
    end

    local function runAnimationSpamFling(targetPlayer)
        local preAttackRoot = getLocalRoot()
        local safeRestoreCFrame = preAttackRoot and preAttackRoot.CFrame or nil
        local suspendFor = punchApproachTimeout + punchFlingDuration + 1.1
        UILibrary:SuspendFlingProtect(suspendFor)

        local reached = runToTargetForPunch(targetPlayer)
        if not reached then
            notify("Run Fling", "Couldn't get close enough.", 1.8)
            return false
        end

        local spamDuration = punchFlingDuration + 0.45
        playRunAnimationSpam(spamDuration, targetPlayer)
        task.wait(0.08)

        return flingForFiveSeconds(targetPlayer, {
            Duration = punchFlingDuration,
            RestoreCFrame = safeRestoreCFrame,
            Force = Vector3.new(18500, 18500, 18500),
            SpinBase = 235,
            SpinAccel = 56,
            RadiusBase = 0.12,
            RadiusPulse = 0.42,
            RiseBase = 0.22,
            RisePulse = 0.2,
            TangentPower = 1350,
            ForwardPower = 520,
            UpPower = 250,
            AngularVelocity = Vector3.new(8200, 10200, 8200),
        })
    end

    local setPunchFlingEnabled

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
        if clickFlingEnabled and punchFlingEnabled then
            setPunchFlingEnabled(false, true)
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
                clickFlingCooldownUntil = os.clock() + 2.35

                local ok = flingForFiveSeconds(clickedPlayer, {
                    Duration = 2,
                })
                if ok then
                    notify("Fling Click", "Flinging " .. tostring(clickedPlayer.Name) .. ".", 2.1)
                end
            end)
        end

        if not silent then
            notify("Fling Click", clickFlingEnabled and "Enabled." or "Disabled.", 1.9)
        end
    end

    setPunchFlingEnabled = function(state, silent)
        state = state == true
        if punchFlingEnabled == state then
            return
        end

        punchFlingEnabled = state
        if punchFlingConnection then
            punchFlingConnection:Disconnect()
            punchFlingConnection = nil
        end
        if punchFlingEnabled and clickFlingEnabled then
            setClickFlingEnabled(false, true)
        end
        if not punchFlingEnabled then
            stopPunchAnimation()
        end

        if punchFlingEnabled then
            local mouse = localPlayer:GetMouse()
            punchFlingConnection = mouse.Button1Down:Connect(function()
                if not punchFlingEnabled then
                    return
                end

                if os.clock() < punchFlingCooldownUntil then
                    return
                end

                local clickedPlayer = getPlayerFromPart(mouse.Target)
                if not clickedPlayer or clickedPlayer == localPlayer then
                    return
                end
                if getDistanceToTarget(clickedPlayer) > punchActivateRange then
                    return
                end

                punchFlingCooldownUntil = os.clock() + 2.2
                selectedPlayer = clickedPlayer
                UILibrary:SetSelectedPlayer(clickedPlayer)
                selectedName:Set("Selected: " .. tostring(clickedPlayer.DisplayName or clickedPlayer.Name))
                selectedUser:Set("@" .. tostring(clickedPlayer.Name))

                task.spawn(function()
                    if not punchFlingEnabled then
                        return
                    end
                    if clickedPlayer.Parent ~= Players then
                        return
                    end

                    local ok = runAnimationSpamFling(clickedPlayer)
                    if ok then
                        notify("Run Fling", "Run-spam flinging " .. tostring(clickedPlayer.Name) .. ".", 2.0)
                    end
                end)
            end)
        end

        if not silent then
            notify("Run Fling", punchFlingEnabled and "Enabled." or "Disabled.", 1.9)
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
        local ok = flingForFiveSeconds(target, {
            Duration = 2,
        })
        if ok then
            notify("Fling", "Flinging " .. tostring(target.Name) .. " (" .. targetMode .. ") for 2 seconds.", 2.3)
        else
            notify("Fling", "Could not fling target right now.", 2.8)
        end
    end)

    optionsSection:CreateButton("Run Fling", function()
        local target = getTrollTarget()
        if not target then
            notify("Run Fling", "No valid target for mode: " .. targetMode, 2.4)
            return
        end
        task.spawn(function()
            local ok = runAnimationSpamFling(target)
            if ok then
                notify("Run Fling", "Run-spam flinging " .. tostring(target.Name) .. " (" .. targetMode .. ").", 2.2)
            else
                notify("Run Fling", "Could not run-fling target right now.", 2.8)
            end
        end)
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
        setPunchFlingEnabled(false, true)
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
        SetClickFlingEnabled = function(_, state, silent)
            setClickFlingEnabled(state == true, silent == true)
        end,
        GetClickFlingEnabled = function()
            return clickFlingEnabled
        end,
        SetPunchFlingEnabled = function(_, state, silent)
            setPunchFlingEnabled(state == true, silent == true)
        end,
        GetPunchFlingEnabled = function()
            return punchFlingEnabled
        end,
        SetPunchAnimationId = function(_, id)
            punchAnimationId = tostring(id or punchAnimationId)
            punchAnimationIds = { punchAnimationId }
            punchAnimationIndex = 0
        end,
        SetPunchRange = function(_, range)
            punchRange = math.max(2, tonumber(range) or punchRange)
        end,
        SetPunchActivateRange = function(_, range)
            punchActivateRange = math.max(5, tonumber(range) or punchActivateRange)
        end,
        SetPunchFlingDuration = function(_, seconds)
            punchFlingDuration = math.max(0.5, tonumber(seconds) or punchFlingDuration)
        end,
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

-- UI Category Builders
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
    local visualsSection = localTab:CreateSection({ Name = "Visuals", Side = "Left" })
    local funSection = localTab:CreateSection({ Name = "Fun Features", Side = "Right" })
    local otherSection = localTab:CreateSection({ Name = "Other", Side = "Right" })
    flySection.Frame.LayoutOrder = 10
    visualsSection.Frame.LayoutOrder = 20

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
    local fpsBoostToggle = nil
    local noShadowsToggle = nil
    local noCameraCollisionToggle = nil
    local noFogToggle = nil
    local fullBrightToggle = nil
    local xbox360Toggle = nil
    local killBrickEnabled = false
    local killBrickConnection = nil
    local unanchoredFlingEnabled = false
    local unanchoredFlingConnection = nil
    local unanchoredFlingCooldownUntil = 0
    local spinFlingEnabled = false
    local spinFlingConnection = nil
    local spinFlingPartState = {}
    local spinFlingSpinRate = tonumber(options.SpinFlingSpinRate) or 3600
    local spinFlingWalkAssistSpeed = tonumber(options.SpinFlingWalkAssistSpeed) or 22
    local spinFlingYaw = 0
    local spinFlingLastStepAt = 0
    local spinFlingBodyVelocity = nil
    local spinFlingBodyGyro = nil
    local spinFlingAutoRotateLocked = false
    local spinFlingAutoRotateWas = true

    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChildOfClass("Terrain")

    local fpsBoostEnabled = false
    local noShadowsEnabled = false
    local noCameraCollisionEnabled = false
    local noFogEnabled = false
    local fullBrightEnabled = false
    local xbox360Enabled = false
    local fpsBoostWorkspaceAddedConnection = nil
    local fpsBoostLightingAddedConnection = nil
    local noShadowsWorkspaceAddedConnection = nil
    local noShadowsTrackedProps = setmetatable({}, { __mode = "k" })
    local fpsBoostTrackedProps = setmetatable({}, { __mode = "k" })
    local fpsBoostTerrainOriginal = nil
    local xbox360WorkspaceAddedConnection = nil
    local xbox360TrackedProps = setmetatable({}, { __mode = "k" })
    local xbox360CursorOriginal = nil
    local xbox360CursorSaved = false
    local xbox360StyleEffect = nil
    local cameraOcclusionOriginal = nil
    local cameraOcclusionOriginalSaved = false
    local baseLightingSnapshot = nil

    local function notify(title, content, duration)
        UILibrary:Notify({
            Title = title,
            Content = content,
            Duration = duration or 2.2,
        })
    end

    local function captureBaseLightingSnapshot()
        if baseLightingSnapshot then
            return
        end
        baseLightingSnapshot = {}
        local props = {
            "Ambient",
            "OutdoorAmbient",
            "Brightness",
            "ClockTime",
            "GlobalShadows",
            "FogStart",
            "FogEnd",
            "FogColor",
            "ExposureCompensation",
            "EnvironmentDiffuseScale",
            "EnvironmentSpecularScale",
            "Technology",
        }
        for _, prop in ipairs(props) do
            local ok, value = pcall(function()
                return Lighting[prop]
            end)
            if ok then
                baseLightingSnapshot[prop] = value
            end
        end
    end

    local function applyVisualLightingState()
        captureBaseLightingSnapshot()
        local target = {}
        for prop, value in pairs(baseLightingSnapshot or {}) do
            target[prop] = value
        end

        if xbox360Enabled then
            target.Brightness = 1.8
            target.ClockTime = 14
            target.Ambient = Color3.fromRGB(148, 148, 148)
            target.OutdoorAmbient = Color3.fromRGB(116, 116, 116)
            target.FogColor = Color3.fromRGB(182, 186, 193)
            target.FogStart = 40
            target.FogEnd = 650
            target.ExposureCompensation = -0.05
            if target.EnvironmentDiffuseScale ~= nil then
                target.EnvironmentDiffuseScale = 0
            end
            if target.EnvironmentSpecularScale ~= nil then
                target.EnvironmentSpecularScale = 0
            end
            if target.Technology ~= nil then
                target.Technology = Enum.Technology.Compatibility
            end
        end

        if fullBrightEnabled then
            target.Brightness = 2.6
            target.ClockTime = 13.2
            target.Ambient = Color3.fromRGB(255, 255, 255)
            target.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            target.ExposureCompensation = 0
        end

        if noFogEnabled then
            target.FogStart = 0
            target.FogEnd = 100000
            target.FogColor = Color3.fromRGB(255, 255, 255)
        end

        if noShadowsEnabled then
            target.GlobalShadows = false
        end

        if fpsBoostEnabled then
            if target.EnvironmentDiffuseScale ~= nil then
                target.EnvironmentDiffuseScale = 0
            end
            if target.EnvironmentSpecularScale ~= nil then
                target.EnvironmentSpecularScale = 0
            end
        end

        for prop, value in pairs(target) do
            pcall(function()
                Lighting[prop] = value
            end)
        end
    end

    local function snapshotFpsProperty(inst, prop)
        local ok, current = pcall(function()
            return inst[prop]
        end)
        if not ok then
            return false
        end
        local entry = fpsBoostTrackedProps[inst]
        if not entry then
            entry = {}
            fpsBoostTrackedProps[inst] = entry
        end
        if entry[prop] == nil then
            entry[prop] = current
        end
        return true
    end

    local function setFpsProperty(inst, prop, value)
        if not snapshotFpsProperty(inst, prop) then
            return
        end
        pcall(function()
            inst[prop] = value
        end)
    end

    local function applyFpsBoostToInstance(inst)
        if not inst then
            return
        end

        if inst:IsA("ParticleEmitter")
            or inst:IsA("Trail")
            or inst:IsA("Beam")
            or inst:IsA("Smoke")
            or inst:IsA("Fire")
            or inst:IsA("Sparkles") then
            setFpsProperty(inst, "Enabled", false)
        end

        if inst:IsA("PostEffect") then
            setFpsProperty(inst, "Enabled", false)
        end

        if inst:IsA("Decal") or inst:IsA("Texture") then
            setFpsProperty(inst, "Transparency", 1)
        end

        if inst:IsA("MeshPart") then
            setFpsProperty(inst, "TextureID", "")
            setFpsProperty(inst, "RenderFidelity", Enum.RenderFidelity.Performance)
        end

        if inst:IsA("SpecialMesh") then
            setFpsProperty(inst, "TextureId", "")
        end

        if inst:IsA("BasePart") then
            setFpsProperty(inst, "MaterialVariant", "")
        end
    end

    local function restoreFpsBoostState()
        if fpsBoostWorkspaceAddedConnection then
            fpsBoostWorkspaceAddedConnection:Disconnect()
            fpsBoostWorkspaceAddedConnection = nil
        end
        if fpsBoostLightingAddedConnection then
            fpsBoostLightingAddedConnection:Disconnect()
            fpsBoostLightingAddedConnection = nil
        end

        for inst, props in pairs(fpsBoostTrackedProps) do
            if inst and type(props) == "table" then
                for prop, value in pairs(props) do
                    pcall(function()
                        inst[prop] = value
                    end)
                end
            end
            fpsBoostTrackedProps[inst] = nil
        end
        fpsBoostTrackedProps = setmetatable({}, { __mode = "k" })

        if Terrain and fpsBoostTerrainOriginal then
            for prop, value in pairs(fpsBoostTerrainOriginal) do
                pcall(function()
                    Terrain[prop] = value
                end)
            end
        end
    end

    local function applyFpsBoostState()
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)

        for _, inst in ipairs(workspace:GetDescendants()) do
            applyFpsBoostToInstance(inst)
        end
        for _, inst in ipairs(Lighting:GetDescendants()) do
            applyFpsBoostToInstance(inst)
        end

        if Terrain then
            if not fpsBoostTerrainOriginal then
                fpsBoostTerrainOriginal = {}
                local terrainProps = {
                    "WaterWaveSize",
                    "WaterWaveSpeed",
                    "WaterReflectance",
                    "WaterTransparency",
                    "Decoration",
                }
                for _, prop in ipairs(terrainProps) do
                    local ok, value = pcall(function()
                        return Terrain[prop]
                    end)
                    if ok then
                        fpsBoostTerrainOriginal[prop] = value
                    end
                end
            end
            pcall(function()
                Terrain.WaterWaveSize = 0
            end)
            pcall(function()
                Terrain.WaterWaveSpeed = 0
            end)
            pcall(function()
                Terrain.WaterReflectance = 0
            end)
            pcall(function()
                Terrain.WaterTransparency = 1
            end)
            pcall(function()
                Terrain.Decoration = false
            end)
        end
    end

    local function setFpsBoostEnabled(state, silent)
        state = state == true
        if fpsBoostEnabled == state then
            return
        end

        fpsBoostEnabled = state
        self.LibrarySettings.FpsBoost = state
        if fpsBoostEnabled then
            restoreFpsBoostState()
            applyFpsBoostState()

            fpsBoostWorkspaceAddedConnection = workspace.DescendantAdded:Connect(function(inst)
                if fpsBoostEnabled then
                    applyFpsBoostToInstance(inst)
                end
            end)
            fpsBoostLightingAddedConnection = Lighting.DescendantAdded:Connect(function(inst)
                if fpsBoostEnabled then
                    applyFpsBoostToInstance(inst)
                end
            end)
        else
            restoreFpsBoostState()
        end

        applyVisualLightingState()
        if not silent then
            notify("FPS Boost", fpsBoostEnabled and "Enabled." or "Disabled.", 1.9)
        end
    end

    local function snapshotNoShadowsProperty(inst, prop)
        local ok, current = pcall(function()
            return inst[prop]
        end)
        if not ok then
            return false
        end
        local entry = noShadowsTrackedProps[inst]
        if not entry then
            entry = {}
            noShadowsTrackedProps[inst] = entry
        end
        if entry[prop] == nil then
            entry[prop] = current
        end
        return true
    end

    local function setNoShadowsProperty(inst, prop, value)
        if not snapshotNoShadowsProperty(inst, prop) then
            return
        end
        pcall(function()
            inst[prop] = value
        end)
    end

    local function applyNoShadowsToInstance(inst)
        if not inst then
            return
        end
        if inst:IsA("BasePart") then
            setNoShadowsProperty(inst, "CastShadow", false)
        end
    end

    local function restoreNoShadowsState()
        if noShadowsWorkspaceAddedConnection then
            noShadowsWorkspaceAddedConnection:Disconnect()
            noShadowsWorkspaceAddedConnection = nil
        end
        for inst, props in pairs(noShadowsTrackedProps) do
            if inst and type(props) == "table" then
                for prop, value in pairs(props) do
                    pcall(function()
                        inst[prop] = value
                    end)
                end
            end
            noShadowsTrackedProps[inst] = nil
        end
        noShadowsTrackedProps = setmetatable({}, { __mode = "k" })
    end

    local function setNoShadowsEnabled(state, silent)
        state = state == true
        if noShadowsEnabled == state then
            return
        end

        noShadowsEnabled = state
        self.LibrarySettings.NoShadows = state
        if noShadowsEnabled then
            restoreNoShadowsState()
            for _, inst in ipairs(workspace:GetDescendants()) do
                applyNoShadowsToInstance(inst)
            end
            noShadowsWorkspaceAddedConnection = workspace.DescendantAdded:Connect(function(inst)
                if noShadowsEnabled then
                    applyNoShadowsToInstance(inst)
                end
            end)
        else
            restoreNoShadowsState()
        end

        applyVisualLightingState()
        if not silent then
            notify("No shadows", noShadowsEnabled and "Enabled." or "Disabled.", 1.9)
        end
    end

    local function setNoCameraCollisionEnabled(state, silent)
        state = state == true
        if noCameraCollisionEnabled == state then
            return
        end

        noCameraCollisionEnabled = state
        self.LibrarySettings.NoCameraCollision = state
        if noCameraCollisionEnabled then
            if not cameraOcclusionOriginalSaved then
                local ok, current = pcall(function()
                    return localPlayer.DevCameraOcclusionMode
                end)
                if ok then
                    cameraOcclusionOriginal = current
                    cameraOcclusionOriginalSaved = true
                end
            end
            pcall(function()
                localPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
            end)
        else
            pcall(function()
                localPlayer.DevCameraOcclusionMode = cameraOcclusionOriginalSaved
                        and (cameraOcclusionOriginal or Enum.DevCameraOcclusionMode.Zoom)
                    or Enum.DevCameraOcclusionMode.Zoom
            end)
        end

        if not silent then
            notify("No Camera Collision", noCameraCollisionEnabled and "Enabled." or "Disabled.", 1.9)
        end
    end

    local function snapshotXbox360Property(inst, prop)
        local ok, current = pcall(function()
            return inst[prop]
        end)
        if not ok then
            return false
        end
        local entry = xbox360TrackedProps[inst]
        if not entry then
            entry = {}
            xbox360TrackedProps[inst] = entry
        end
        if entry[prop] == nil then
            entry[prop] = current
        end
        return true
    end

    local function setXbox360Property(inst, prop, value)
        if not snapshotXbox360Property(inst, prop) then
            return
        end
        pcall(function()
            inst[prop] = value
        end)
    end

    local function applyXbox360ToInstance(inst)
        if not inst then
            return
        end

        if inst:IsA("BasePart") then
            setXbox360Property(inst, "Reflectance", 0)
            local mat = nil
            local okMat, currentMat = pcall(function()
                return inst.Material
            end)
            if okMat then
                mat = currentMat
            end
            if mat and mat ~= Enum.Material.Neon and mat ~= Enum.Material.ForceField then
                setXbox360Property(inst, "Material", Enum.Material.Plastic)
            end
        end

        if inst:IsA("Decal") or inst:IsA("Texture") then
            local currentTransparency = 0
            pcall(function()
                currentTransparency = inst.Transparency
            end)
            setXbox360Property(inst, "Transparency", math.clamp(currentTransparency + 0.12, 0, 0.45))
            setXbox360Property(inst, "Color3", Color3.fromRGB(224, 224, 224))
        end

    end

    local function restoreXbox360State()
        if xbox360WorkspaceAddedConnection then
            xbox360WorkspaceAddedConnection:Disconnect()
            xbox360WorkspaceAddedConnection = nil
        end

        for inst, props in pairs(xbox360TrackedProps) do
            if inst and type(props) == "table" then
                for prop, value in pairs(props) do
                    pcall(function()
                        inst[prop] = value
                    end)
                end
            end
            xbox360TrackedProps[inst] = nil
        end
        xbox360TrackedProps = setmetatable({}, { __mode = "k" })

        if xbox360StyleEffect and xbox360StyleEffect.Parent then
            xbox360StyleEffect:Destroy()
        end
        xbox360StyleEffect = nil

        if xbox360CursorSaved then
            local okMouse, mouse = pcall(function()
                return localPlayer:GetMouse()
            end)
            if okMouse and mouse then
                pcall(function()
                    mouse.Icon = xbox360CursorOriginal or ""
                end)
            end
            xbox360CursorSaved = false
            xbox360CursorOriginal = nil
        end
    end

    local function applyXbox360State()
        for _, inst in ipairs(workspace:GetDescendants()) do
            applyXbox360ToInstance(inst)
        end

        xbox360WorkspaceAddedConnection = workspace.DescendantAdded:Connect(function(inst)
            if xbox360Enabled then
                applyXbox360ToInstance(inst)
            end
        end)

        local okMouse, mouse = pcall(function()
            return localPlayer:GetMouse()
        end)
        if okMouse and mouse then
            if not xbox360CursorSaved then
                xbox360CursorSaved = true
                xbox360CursorOriginal = mouse.Icon
            end
            pcall(function()
                mouse.Icon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
            end)
        end

        if xbox360StyleEffect and xbox360StyleEffect.Parent then
            xbox360StyleEffect:Destroy()
        end
        xbox360StyleEffect = Instance.new("ColorCorrectionEffect")
        xbox360StyleEffect.Name = "LimboXbox360Style"
        xbox360StyleEffect.Brightness = -0.02
        xbox360StyleEffect.Contrast = -0.08
        xbox360StyleEffect.Saturation = -0.22
        xbox360StyleEffect.TintColor = Color3.fromRGB(236, 232, 224)
        xbox360StyleEffect.Parent = Lighting
    end

    local function setNoFogEnabled(state, silent)
        state = state == true
        if noFogEnabled == state then
            return
        end
        noFogEnabled = state
        self.LibrarySettings.NoFog = state
        applyVisualLightingState()
        if not silent then
            notify("No fog", noFogEnabled and "Enabled." or "Disabled.", 1.9)
        end
    end

    local function setFullBrightEnabled(state, silent)
        state = state == true
        if fullBrightEnabled == state then
            return
        end
        fullBrightEnabled = state
        self.LibrarySettings.FullBright = state
        applyVisualLightingState()
        if not silent then
            notify("Full bright", fullBrightEnabled and "Enabled." or "Disabled.", 1.9)
        end
    end

    local function setXbox360Enabled(state, silent)
        state = state == true
        if xbox360Enabled == state then
            return
        end
        xbox360Enabled = state
        self.LibrarySettings.Xbox360 = state
        if xbox360Enabled then
            restoreXbox360State()
            applyXbox360State()
        else
            restoreXbox360State()
            if fpsBoostEnabled then
                applyFpsBoostState()
            end
            if noShadowsEnabled then
                for _, inst in ipairs(workspace:GetDescendants()) do
                    applyNoShadowsToInstance(inst)
                end
            end
        end
        applyVisualLightingState()
        if not silent then
            notify("Xbox360 2016", xbox360Enabled and "Enabled." or "Disabled.", 1.9)
        end
    end

    local function getLocalRoot()
        local character = localPlayer.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end

    local function getLocalHumanoid()
        local character = localPlayer.Character
        return character and character:FindFirstChildOfClass("Humanoid")
    end

    local function refreshFlyPlatformStand()
        local humanoid = getLocalHumanoid()
        if humanoid then
            humanoid.PlatformStand = flyEnabled
        end
    end

    local function stopFly()
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

        refreshFlyPlatformStand()
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

        refreshFlyPlatformStand()
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

    local function getFlyMoveDirection(cam)
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
        return move
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

        local move = getFlyMoveDirection(cam)

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
        self.LibrarySettings.FlyEnabled = state
        if flyEnabled then
            local ok = startFly()
            if not ok then
                flyEnabled = false
                self.LibrarySettings.FlyEnabled = false
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
        self.LibrarySettings.FlingProtect = flingProtectEnabled
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

    local function runExternalLoader(name, url, useAsync, controlsHint)
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
            if type(controlsHint) == "string" and controlsHint ~= "" then
                notify("Controls", controlsHint, 5)
            end
        else
            UILibrary:NotifyError({
                Title = name,
                Content = tostring(err),
                Duration = 3.2,
            })
        end
    end

    local function setKillBrickEnabled(state, silent)
        state = state == true
        if killBrickEnabled == state then
            return
        end

        killBrickEnabled = state
        if killBrickConnection then
            killBrickConnection:Disconnect()
            killBrickConnection = nil
        end

        if killBrickEnabled then
            killBrickConnection = RunService.Heartbeat:Connect(function()
                local character = localPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if not root then
                    return
                end
                local parts = workspace:GetPartBoundsInRadius(root.Position, 10)
                for _, part in ipairs(parts) do
                    if part:IsA("BasePart") and part.Parent and not (character and part:IsDescendantOf(character)) then
                        part.CanTouch = true
                    end
                end
            end)
        end

        if not silent then
            notify("FE Toggle Kill Brick", killBrickEnabled and "Enabled." or "Disabled.", 1.9)
        end
    end

    local function setUnanchoredPartFlingEnabled(state, silent)
        state = state == true
        if unanchoredFlingEnabled == state then
            return
        end

        unanchoredFlingEnabled = state
        if unanchoredFlingConnection then
            unanchoredFlingConnection:Disconnect()
            unanchoredFlingConnection = nil
        end

        if unanchoredFlingEnabled then
            local mouse = localPlayer:GetMouse()
            unanchoredFlingConnection = mouse.Button1Down:Connect(function()
                if not unanchoredFlingEnabled then
                    return
                end
                if os.clock() < unanchoredFlingCooldownUntil then
                    return
                end

                local obj = mouse.Target
                local character = localPlayer.Character
                if not obj or not obj:IsA("BasePart") or obj.Anchored then
                    return
                end
                if character and obj:IsDescendantOf(character) then
                    return
                end

                unanchoredFlingCooldownUntil = os.clock() + 0.1
                local spin = Instance.new("BodyAngularVelocity")
                spin.Name = "LimboPartFlingSpin"
                spin.Parent = obj
                spin.AngularVelocity = Vector3.new(99999, 99999, 99999)
                spin.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                spin.P = math.huge
                task.delay(1.5, function()
                    if spin and spin.Parent then
                        spin:Destroy()
                    end
                end)
            end)
        end

        if not silent then
            notify("Fling Click Unanchored Parts", unanchoredFlingEnabled and "Enabled." or "Disabled.", 1.9)
        end
    end

    local function setSpinFlingCharacterCollision(enabled)
        local character = localPlayer.Character
        if not character then
            return
        end

        if enabled then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    local partName = tostring(part.Name)
                    local allowCollisionPart = (partName == "HumanoidRootPart")
                    if not allowCollisionPart then
                        continue
                    end
                    if not spinFlingPartState[part] then
                        spinFlingPartState[part] = {
                            CanCollide = part.CanCollide,
                            CanTouch = part.CanTouch,
                            CanQuery = part.CanQuery,
                        }
                    end
                    part.CanCollide = true
                    part.CanTouch = true
                    part.CanQuery = true
                    pcall(function()
                        part.CollisionGroup = "Default"
                    end)
                end
            end
            return
        end

        for part, state in pairs(spinFlingPartState) do
            if part and part.Parent and type(state) == "table" then
                part.CanCollide = state.CanCollide == true
                part.CanTouch = state.CanTouch ~= false
                part.CanQuery = state.CanQuery ~= false
            end
            spinFlingPartState[part] = nil
        end
        table.clear(spinFlingPartState)
    end

    local function destroySpinFlingMovers()
        if spinFlingBodyVelocity then
            pcall(function()
                spinFlingBodyVelocity:Destroy()
            end)
            spinFlingBodyVelocity = nil
        end
        if spinFlingBodyGyro then
            pcall(function()
                spinFlingBodyGyro:Destroy()
            end)
            spinFlingBodyGyro = nil
        end
    end

    local function ensureSpinFlingMovers(root)
        if not root then
            return nil, nil
        end
        if not spinFlingBodyGyro or spinFlingBodyGyro.Parent ~= root then
            destroySpinFlingMovers()

            local bg = Instance.new("BodyGyro")
            bg.Name = "LimboSpinFlingBG"
            bg.P = 9e4
            bg.D = 160
            bg.MaxTorque = Vector3.new(0, 8e7, 0)
            bg.CFrame = root.CFrame
            bg.Parent = root
            spinFlingBodyGyro = bg

            local bv = Instance.new("BodyVelocity")
            bv.Name = "LimboSpinFlingBV"
            bv.P = 12500
            bv.MaxForce = Vector3.new(8e7, 0, 8e7)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = root
            spinFlingBodyVelocity = bv
        end
        return spinFlingBodyGyro, spinFlingBodyVelocity
    end

    local function setSpinFlingEnabled(state, silent)
        state = state == true
        if spinFlingEnabled == state then
            return
        end

        spinFlingEnabled = state
        if spinFlingConnection then
            spinFlingConnection:Disconnect()
            spinFlingConnection = nil
        end

        if not spinFlingEnabled then
            setSpinFlingCharacterCollision(false)
            local root = getLocalRoot()
            if root then
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
            end
            local hum = getLocalHumanoid()
            if hum and spinFlingAutoRotateLocked then
                hum.AutoRotate = spinFlingAutoRotateWas
            end
            spinFlingAutoRotateLocked = false
            spinFlingAutoRotateWas = true
            destroySpinFlingMovers()
            spinFlingYaw = 0
            spinFlingLastStepAt = 0
            if not silent then
                notify("Crazy Mode", "Disabled.", 1.9)
            end
            return
        end

        spinFlingConnection = RunService.Heartbeat:Connect(function()
            local character = localPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not character or not humanoid or humanoid.Health <= 0 or not root then
                return
            end

            if not spinFlingAutoRotateLocked then
                spinFlingAutoRotateLocked = true
                spinFlingAutoRotateWas = humanoid.AutoRotate
            end
            humanoid.AutoRotate = false

            UILibrary:SuspendFlingProtect(0.25)
            setSpinFlingCharacterCollision(true)
            local bg, bv = ensureSpinFlingMovers(root)
            if not bg or not bv then
                return
            end

            local now = os.clock()
            if spinFlingLastStepAt <= 0 then
                spinFlingLastStepAt = now
            end
            local dt = math.max(1 / 240, now - spinFlingLastStepAt)
            spinFlingLastStepAt = now

            spinFlingYaw = (spinFlingYaw + (spinFlingSpinRate * dt)) % 360
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            local yawCf = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(spinFlingYaw), 0)
            bg.CFrame = yawCf

            local moveDir = humanoid.MoveDirection
            local desiredPlanar = Vector3.new(0, 0, 0)
            if moveDir.Magnitude > 0.001 then
                desiredPlanar = moveDir.Unit * spinFlingWalkAssistSpeed
            end

            bv.Velocity = desiredPlanar
        end)

        if not silent then
            notify("Crazy Mode", "Enabled. Walk into players to fling.", 2.1)
        end
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
            if spinFlingEnabled then
                task.wait(0.1)
                setSpinFlingCharacterCollision(true)
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
    self.LibraryConfigItems.FlyEnabled = flyToggleControl

    local flyKeybind = flySection:CreateKeybind("Fly Toggle Key", function(key, changed)
        if changed then
            flyKey = key
            self.LibrarySettings.FlyKey = key.Name
            notify("Fly Keybind", "Set to " .. tostring(key.Name) .. ".", 1.8)
        end
    end, flyKey)
    self.LibraryConfigItems.FlyKey = flyKeybind

    local flySpeedSlider = flySection:CreateSlider("Fly Speed", 20, 400, flySpeed, function(v)
        flySpeed = tonumber(v) or flySpeed
        self.LibrarySettings.FlySpeed = flySpeed
    end)
    self.LibraryConfigItems.FlySpeed = flySpeedSlider
    flySection:CreateLabel("Fly controls: WASD + Space/Ctrl")

    fpsBoostToggle = visualsSection:CreateToggle("FPS Boost", function(v)
        setFpsBoostEnabled(v, false)
    end, false)
    self.LibraryConfigItems.FpsBoost = fpsBoostToggle
    visualsSection:CreateLabel("Strips heavy effects and textures for faster loading/FPS.")

    noShadowsToggle = visualsSection:CreateToggle("No shadows", function(v)
        setNoShadowsEnabled(v, false)
    end, false)
    self.LibraryConfigItems.NoShadows = noShadowsToggle

    noCameraCollisionToggle = visualsSection:CreateToggle("No Camera Collision", function(v)
        setNoCameraCollisionEnabled(v, false)
    end, false)
    self.LibraryConfigItems.NoCameraCollision = noCameraCollisionToggle

    noFogToggle = visualsSection:CreateToggle("No fog", function(v)
        setNoFogEnabled(v, false)
    end, false)
    self.LibraryConfigItems.NoFog = noFogToggle

    fullBrightToggle = visualsSection:CreateToggle("Full bright", function(v)
        setFullBrightEnabled(v, false)
    end, false)
    self.LibraryConfigItems.FullBright = fullBrightToggle

    xbox360Toggle = visualsSection:CreateToggle("Xbox360 2016", function(v)
        setXbox360Enabled(v, false)
    end, false)
    self.LibraryConfigItems.Xbox360 = xbox360Toggle
    visualsSection:CreateLabel("Old 2016 console look: cursor, lighting and materials.")

    local clickFlingToggle, punchFlingToggle = nil, nil
    clickFlingToggle = funSection:CreateToggle("Click Player to Fling", function(v)
        local playersCategory = self.PlayerCategory or self:CreatePlayersCategory()
        if not playersCategory or type(playersCategory.SetClickFlingEnabled) ~= "function" then
            notify("Fun Features", "Players category is unavailable.", 2.2)
            if clickFlingToggle and clickFlingToggle.Set then
                clickFlingToggle:Set(false, true)
            end
            return
        end
        if v and punchFlingToggle and punchFlingToggle.Set and punchFlingToggle:Get() then
            punchFlingToggle:Set(false, true)
        end
        playersCategory:SetClickFlingEnabled(v, false)
    end, false)
    funSection:CreateLabel("Click a player's character to fling them.")

    punchFlingToggle = funSection:CreateToggle("Run Spam Fling", function(v)
        local playersCategory = self.PlayerCategory or self:CreatePlayersCategory()
        if not playersCategory or type(playersCategory.SetPunchFlingEnabled) ~= "function" then
            notify("Fun Features", "Players category is unavailable.", 2.2)
            if punchFlingToggle and punchFlingToggle.Set then
                punchFlingToggle:Set(false, true)
            end
            return
        end
        if v and clickFlingToggle and clickFlingToggle.Set and clickFlingToggle:Get() then
            clickFlingToggle:Set(false, true)
        end
        playersCategory:SetPunchFlingEnabled(v, false)
    end, false)
    funSection:CreateLabel("Spam run animation fast, then fling clicked target.")


    local partFlingToggle = funSection:CreateToggle("Fling Click Unanchored Parts", function(v)
        setUnanchoredPartFlingEnabled(v, false)
    end, false)
    funSection:CreateLabel("Click an unanchored part to spin-fling it.")

    local spinFlingToggle = funSection:CreateToggle("Crazy Mode", function(v)
        setSpinFlingEnabled(v, false)
    end, false)
    funSection:CreateLabel("Crazy spin + collision fling when you touch players.")


    local flingProtectToggle = otherSection:CreateToggle("Fling Protect", function(v)
        setFlingProtectEnabled(v)
    end, false)
    self.LibraryConfigItems.FlingProtect = flingProtectToggle

    self:OnClose(function()
        setFlyEnabled(false, true)
        setFpsBoostEnabled(false, true)
        setNoShadowsEnabled(false, true)
        setNoCameraCollisionEnabled(false, true)
        setNoFogEnabled(false, true)
        setFullBrightEnabled(false, true)
        setXbox360Enabled(false, true)
        setKillBrickEnabled(false, true)
        setUnanchoredPartFlingEnabled(false, true)
        setSpinFlingEnabled(false, true)
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
        VisualsSection = visualsSection,
        FunSection = funSection,
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
        SetFpsBoost = function(_, state)
            if fpsBoostToggle and fpsBoostToggle.Set then
                fpsBoostToggle:Set(state == true, true)
            end
            setFpsBoostEnabled(state == true, true)
        end,
        GetFpsBoost = function()
            return fpsBoostEnabled
        end,
        SetNoShadows = function(_, state)
            if noShadowsToggle and noShadowsToggle.Set then
                noShadowsToggle:Set(state == true, true)
            end
            setNoShadowsEnabled(state == true, true)
        end,
        GetNoShadows = function()
            return noShadowsEnabled
        end,
        SetNoCameraCollision = function(_, state)
            if noCameraCollisionToggle and noCameraCollisionToggle.Set then
                noCameraCollisionToggle:Set(state == true, true)
            end
            setNoCameraCollisionEnabled(state == true, true)
        end,
        GetNoCameraCollision = function()
            return noCameraCollisionEnabled
        end,
        SetNoFog = function(_, state)
            if noFogToggle and noFogToggle.Set then
                noFogToggle:Set(state == true, true)
            end
            setNoFogEnabled(state == true, true)
        end,
        GetNoFog = function()
            return noFogEnabled
        end,
        SetFullBright = function(_, state)
            if fullBrightToggle and fullBrightToggle.Set then
                fullBrightToggle:Set(state == true, true)
            end
            setFullBrightEnabled(state == true, true)
        end,
        GetFullBright = function()
            return fullBrightEnabled
        end,
        SetXbox360 = function(_, state)
            if xbox360Toggle and xbox360Toggle.Set then
                xbox360Toggle:Set(state == true, true)
            end
            setXbox360Enabled(state == true, true)
        end,
        GetXbox360 = function()
            return xbox360Enabled
        end,
        SetXbox2016 = function(_, state)
            if xbox360Toggle and xbox360Toggle.Set then
                xbox360Toggle:Set(state == true, true)
            end
            setXbox360Enabled(state == true, true)
        end,
        GetXbox2016 = function()
            return xbox360Enabled
        end,
        SetFlingProtect = function(_, state)
            setFlingProtectEnabled(state == true)
        end,
        GetFlingProtect = function()
            return flingProtectEnabled
        end,
        SetKillBrick = function(_, state)
            if killBrickToggle and killBrickToggle.Set then
                killBrickToggle:Set(state == true, true)
            end
            setKillBrickEnabled(state == true, true)
        end,
        GetKillBrick = function()
            return killBrickEnabled
        end,
        SetUnanchoredPartFling = function(_, state)
            if partFlingToggle and partFlingToggle.Set then
                partFlingToggle:Set(state == true, true)
            end
            setUnanchoredPartFlingEnabled(state == true, true)
        end,
        GetUnanchoredPartFling = function()
            return unanchoredFlingEnabled
        end,
        SetSpinFling = function(_, state)
            if spinFlingToggle and spinFlingToggle.Set then
                spinFlingToggle:Set(state == true, true)
            end
            setSpinFlingEnabled(state == true, true)
        end,
        GetSpinFling = function()
            return spinFlingEnabled
        end,
    }

    return self.LocalCategory
end

-- UI Category Builders
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
    scriptSection.Frame.Visible = false
    local selectedLabel = settingsSection:CreateLabel("Selected: None")
    local selectedMetaLabel = settingsSection:CreateLabel("Method: - | Time: -")
    local selectedTypeLabel = settingsSection:CreateLabel("Type: -")
    local logsHintLabel = logsSection:CreateLabel("Select a log entry, then use Controls.")
    logsHintLabel.Frame.LayoutOrder = -1000000
    scriptSection:CreateLabel("Latest generated script for selected log.")

    local REMOTE_LOG_ICONS = {
        RemoteEvent = "rbxassetid://4229806545",
        RemoteFunction = "rbxassetid://4229810474",
        BindableEvent = "rbxassetid://4229809371",
        BindableFunction = "rbxassetid://4229807624",
    }

    local function iconizeRemoteLabel(text)
        local value = tostring(text or "")
        local noRich = string.gsub(value, "<.->", "")
        local trimmed = string.gsub(noRich, "^%s+", "")
        local upperValue = string.upper(trimmed)

        local function stripLeadingToken(raw)
            local stripped = string.gsub(raw, "^%s*%[?%s*[A-Z][A-Z]?%s*%]?%s*[:|%-]?%s*", "")
            stripped = string.gsub(stripped, "^%s+", "")
            if stripped == "" then
                return raw
            end
            return stripped
        end

        local function byPrefix(prefix, icon)
            if string.sub(upperValue, 1, #prefix) == prefix then
                return stripLeadingToken(trimmed), icon
            end
            return nil, nil
        end

        local cleaned, icon = byPrefix("[BE]", REMOTE_LOG_ICONS.BindableEvent)
        if icon then
            return cleaned, icon
        end
        cleaned, icon = byPrefix("[BF]", REMOTE_LOG_ICONS.BindableFunction)
        if icon then
            return cleaned, icon
        end
        cleaned, icon = byPrefix("[E]", REMOTE_LOG_ICONS.RemoteEvent)
        if icon then
            return cleaned, icon
        end
        cleaned, icon = byPrefix("[F]", REMOTE_LOG_ICONS.RemoteFunction)
        if icon then
            return cleaned, icon
        end

        local token = string.match(upperValue, "^%[?([A-Z][A-Z]?)%]?")
        if token == "BE" then
            return stripLeadingToken(trimmed), REMOTE_LOG_ICONS.BindableEvent
        elseif token == "BF" then
            return stripLeadingToken(trimmed), REMOTE_LOG_ICONS.BindableFunction
        elseif token == "E" then
            return stripLeadingToken(trimmed), REMOTE_LOG_ICONS.RemoteEvent
        elseif token == "F" then
            return stripLeadingToken(trimmed), REMOTE_LOG_ICONS.RemoteFunction
        end

        if string.find(upperValue, "BINDABLEEVENT", 1, true) then
            return trimmed, REMOTE_LOG_ICONS.BindableEvent
        end
        if string.find(upperValue, "BINDABLEFUNCTION", 1, true) then
            return trimmed, REMOTE_LOG_ICONS.BindableFunction
        end
        if string.find(upperValue, "REMOTEFUNCTION", 1, true) then
            return trimmed, REMOTE_LOG_ICONS.RemoteFunction
        end
        if string.find(upperValue, "REMOTEEVENT", 1, true) or string.find(upperValue, "UNRELIABLEREMOTEEVENT", 1, true) then
            return trimmed, REMOTE_LOG_ICONS.RemoteEvent
        end

        return trimmed, nil
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
            local sourceLabel = payload.Name or payload.Text
            local mappedText, mappedIcon = iconizeRemoteLabel(sourceLabel)
            if payload.Name then
                payload.Name = mappedText
            end
            if payload.Text then
                payload.Text = mappedText
            end
            payload.Icon = mappedIcon or payload.Icon
            payload.TextXAlignment = payload.TextXAlignment or Enum.TextXAlignment.Left
            return applyNewestTopOrder(logsSection:CreateButton(payload, b))
        end
        local mappedText, mappedIcon = iconizeRemoteLabel(a)
        return applyNewestTopOrder(logsSection:CreateButton({
            Name = mappedText,
            Icon = mappedIcon,
            TextXAlignment = Enum.TextXAlignment.Left,
            Callback = b,
        }))
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
        local trimmed = string.gsub(string.gsub(value, "^%s+", ""), "%s+$", "")
        local lower = string.lower(trimmed)
        local hasSelection = trimmed ~= "" and lower ~= "none" and lower ~= "-"
        scriptSection.Frame.Visible = hasSelection
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
        local trimmed = string.gsub(string.gsub(name, "^%s+", ""), "%s+$", "")
        local lower = string.lower(trimmed)
        local hasSelection = trimmed ~= "" and lower ~= "none" and lower ~= "-"
        scriptSection.Frame.Visible = hasSelection
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

-- UI Category Builders
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
        self.LibrarySettings.DeveloperMode = state

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

    local developerToggle = otherSection:CreateToggle("Remotes", function(v)
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

    self.LibraryConfigItems.DeveloperMode = developerToggle

    return self.UniversalCategory
end

--UI Category Builders
function Window:CreateConfigCategory(options)
    if self.ConfigCategory then
        return self.ConfigCategory
    end

    local configTab = self:CreateTab({ Name = "Config", Icon = "config", LayoutOrder = 25 })
    local managementSection = configTab:CreateSection({ Name = "Management", Side = "Left" })
    local listSection = configTab:CreateSection({ Name = "Configs", Side = "Right" })

    local configNameInput = managementSection:CreateInput("Config Name", "e.g. Default", "", function() end)
    
    local function refreshConfigList()
        for _, child in ipairs(listSection.Content:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                child:Destroy()
            end
        end

        local configs = self:GetLibraryConfigs()
        if #configs == 0 then
            listSection:CreateLabel("No configs found.")
        else
            for _, name in ipairs(configs) do
                listSection:CreateLabel("Config: " .. name)
                listSection:CreateButton({ Name = "Load " .. name, Callback = function()
                    if self:LoadLibraryConfig(name) then
                        UILibrary:NotifyInfo({ Title = "Config", Content = "Loaded " .. name, Duration = 2 })
                    else
                        UILibrary:NotifyError({ Title = "Config", Content = "Failed to load " .. name })
                    end
                end })
                listSection:CreateButton({ Name = "Delete " .. name, Callback = function()
                    if self:DeleteLibraryConfig(name) then
                        UILibrary:NotifyInfo({ Title = "Config", Content = "Deleted " .. name, Duration = 2 })
                        refreshConfigList()
                    else
                        UILibrary:NotifyError({ Title = "Config", Content = "Failed to delete " .. name })
                    end
                end })
            end
        end
    end

    managementSection:CreateButton("Save Current", function()
        local name = configNameInput:GetValue()
        if name == "" then
            UILibrary:NotifyError({ Title = "Config", Content = "Please enter a name." })
            return
        end
        if self:SaveLibraryConfig(name) then
            UILibrary:NotifyInfo({ Title = "Config", Content = "Saved " .. name, Duration = 2 })
            refreshConfigList()
        else
            UILibrary:NotifyError({ Title = "Config", Content = "Failed to save " .. name })
        end
    end)

    managementSection:CreateButton("Refresh List", refreshConfigList)

    refreshConfigList()

    self.ConfigCategory = {
        Tab = configTab,
        ManagementSection = managementSection,
        ListSection = listSection,
        RefreshList = refreshConfigList,
    }

    return self.ConfigCategory
end

-- Config Management Implementation
function Window:GetLibraryConfigs()
    if not isfolder("Limbo") then
        pcall(makefolder, "Limbo")
    end
    if not isfolder(self.ConfigFolder) then
        pcall(makefolder, self.ConfigFolder)
    end

    local configs = {}
    local ok, files = pcall(listfiles, self.ConfigFolder)
    if ok and type(files) == "table" then
        for _, file in ipairs(files) do
            local name = string.match(file, "([^/\\]+)$")
            if string.find(name, "%.json$") then
                table.insert(configs, (string.gsub(name, "%.json$", "")))
            end
        end
    end
    return configs
end

function Window:SaveLibraryConfig(name)
    if not name or name == "" then
        return false
    end
    if not isfolder(self.ConfigFolder) then
        pcall(makefolder, self.ConfigFolder)
    end

    -- Update settings from items before saving
    for flag, item in pairs(self.LibraryConfigItems) do
        local val = nil
        local ok, result = pcall(function() return item:Get() end)
        if ok then
            val = result
        end

        -- Handle Keybinds which return KeyCode object
        if typeof(val) == "EnumItem" then
            val = val.Name
        end
        self.LibrarySettings[flag] = val
    end

    local ok, json = pcall(function()
        return game:GetService("HttpService"):JSONEncode(self.LibrarySettings)
    end)
    if ok then
        local okWrite = pcall(writefile, self.ConfigFolder .. "/" .. name .. ".json", json)
        return okWrite
    end
    return false
end

function Window:LoadLibraryConfig(name)
    local path = self.ConfigFolder .. "/" .. name .. ".json"
    if not isfile(path) then
        return false
    end

    local ok, content = pcall(readfile, path)
    if not ok then
        return false
    end

    local ok2, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(content)
    end)
    if not ok2 then
        return false
    end

    for flag, value in pairs(data) do
        local item = self.LibraryConfigItems[flag]
        if item then
            if item.Set then
                item:Set(value, false)
            elseif item.SetValue then
                item:SetValue(value, false)
            end
        end
    end
    return true
end

function Window:DeleteLibraryConfig(name)
    local path = self.ConfigFolder .. "/" .. name .. ".json"
    if isfile(path) then
        local ok = pcall(delfile, path)
        return ok
    end
    return false
end

-- UI Control Builder Primitives
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
    local text, cb, iconImage, textAlign
    if typeof(a) == "table" then
        text = tostring(a.Name or a.Text or "Button")
        cb = a.Callback or b
        iconImage = a.Icon or a.Image or a.IconImage
        textAlign = a.TextXAlignment
    else
        text = tostring(a or "Button")
        cb = b
    end

    local hasIcon = type(iconImage) == "string" and iconImage ~= ""
    local function renderButtonText(value)
        local base = tostring(value or "")
        if hasIcon then
            return "      " .. base
        end
        return base
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
        TextXAlignment = textAlign or (hasIcon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center),
        Text = renderButtonText(text),
    })
    corner(btn, 4)
    stroke(btn, C.Stroke, 0.55)
    if hasIcon then
        mk("ImageLabel", {
            Parent = btn,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.new(0, 8, 0.5, -8),
            Image = iconImage,
            ImageColor3 = Color3.new(1, 1, 1),
        })
    end

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
            btn.Text = renderButtonText(t)
        end,
        Fire = function()
            safe(cb)
        end,
    }
end

-- UI Control Builders
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

    local shell = controlShell(self, 62)
    local back = controlBack(shell, 62)
    mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 11, 0, 7),
        Size = UDim2.new(1, -108, 0, 18),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = name,
    })
    local valBack = mk("Frame", {
        Parent = back,
        BackgroundColor3 = Color3.fromRGB(8, 12, 20),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -90, 0, 6),
        Size = UDim2.new(0, 80, 0, 20),
    })
    corner(valBack, 4)
    stroke(valBack, C.Stroke, 0.55)
    local val = mk("TextLabel", {
        Parent = valBack,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = C.Text,
        Text = "",
    })
    local bar = mk("Frame", {
        Parent = back,
        BackgroundColor3 = Color3.fromRGB(8, 12, 20),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 11, 0, 39),
        Size = UDim2.new(1, -22, 0, 8),
    })
    corner(bar, 99)
    stroke(bar, C.Stroke, 0.65)
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
        Size = UDim2.new(0, 14, 0, 14),
    })
    corner(knob, 99)
    stroke(knob, C.Stroke, 0.2)
    local hit = mk("TextButton", {
        Parent = back,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 33),
        Size = UDim2.new(1, -16, 0, 20),
        Text = "",
        AutoButtonColor = false,
    })

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
    track(self.Window.Connections, hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            at(i.Position.X)
            tw(knob, 0.08, { Size = UDim2.new(0, 16, 0, 16) }):Play()
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
            tw(knob, 0.08, { Size = UDim2.new(0, 14, 0, 14) }):Play()
        end
    end))
    track(self.Window.Connections, back.MouseEnter:Connect(function()
        tw(back, 0.1, { BackgroundColor3 = C.ControlHover }):Play()
    end))
    track(self.Window.Connections, back.MouseLeave:Connect(function()
        tw(back, 0.1, { BackgroundColor3 = C.Control }):Play()
    end))
    draw()
    return controller
end

-- UI Control Builders
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

-- UI Control Builders
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

-- UI Section/Tab Builders
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

-- UI Core Builder
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

-- Public API: window construction
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
        LibrarySettings = {},
        LibraryConfigItems = {},
        ConfigFolder = "Limbo",
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

    if o.IncludeConfig ~= false then
        task.defer(function()
            if w and not w.Destroyed then
                pcall(function()
                    w:CreateConfigCategory(o.ConfigOptions)
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

-- Public API: window lifecycle helpers
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

-- Public API: notifications
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
