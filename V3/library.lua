local UILibrary = {
    _window = nil,
    _selectedPlayer = nil,
    _suspendFlingProtectUntil = 0,
    Connections = {},
    Icons = {},
}

local GUI_NAME = "ZyntraV3"
local FONT = Enum.Font.Inter or Enum.Font.Gotham
local FONT_BOLD = Enum.Font.Inter or Enum.Font.GothamMedium

--[[
    Zyntra UI Library V3
    Aesthetic: Hyper-Modern / Glassmorphism / Premium
    Compatibility: API identical to V2
]]

-- Services
local Services = {
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    TextService = game:GetService("TextService"),
    CoreGui = game:GetService("CoreGui"),
}

local TweenService = Services.TweenService
local UIS = Services.UserInputService
local Players = Services.Players
local RunService = Services.RunService
local TextService = Services.TextService

-- Configuration & Theme
local OPEN_DROPDOWNS = {}

local C = {
    -- Backgrounds
    Main = Color3.fromRGB(8, 8, 10),
    Sidebar = Color3.fromRGB(12, 12, 15),
    Header = Color3.fromRGB(10, 10, 13),
    Panel = Color3.fromRGB(18, 18, 22),
    PanelInset = Color3.fromRGB(25, 25, 30),
    
    -- Accents
    Accent = Color3.fromRGB(0, 162, 255), -- Electric Blue
    AccentGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 162, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 230))
    }),
    
    -- Controls
    Control = Color3.fromRGB(26, 26, 32),
    ControlHover = Color3.fromRGB(34, 34, 42),
    ControlActive = Color3.fromRGB(42, 42, 52),
    
    -- Strokes / Dividers
    Stroke = Color3.fromRGB(40, 40, 45),
    StrokeLight = Color3.fromRGB(55, 55, 60),
    
    -- Text
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(150, 150, 160),
    DisabledText = Color3.fromRGB(90, 90, 100),
    
    -- Status
    Success = Color3.fromRGB(0, 255, 150),
    Warning = Color3.fromRGB(255, 180, 0),
    Error = Color3.fromRGB(255, 70, 70),
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
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = x
    return c
end

local function stroke(x, color, trans, thick, applyTo)
    local s = Instance.new("UIStroke")
    s.Color = color or C.Stroke
    s.Thickness = thick or 1
    s.Transparency = trans or 0.7
    s.ApplyStrokeMode = applyTo or Enum.ApplyStrokeMode.Border
    s.Parent = x
    return s
end

local function tw(x, t, p, style, dir)
    return TweenService:Create(x, TweenInfo.new(t, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), p)
end

local function safe(cb, ...)
    if typeof(cb) ~= "function" then return end
    local ok, err = pcall(cb, ...)
    if not ok then warn("[Zyntra V3] Callback error:", err) end
end

local function guiParent()
    if typeof(gethui) == "function" then
        local ok, v = pcall(gethui)
        if ok and v then return v end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function protect(gui)
    if typeof(syn) == "table" and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    end
end

-- Core Object Definitions
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

-- Window Methods
function Window:SetVisible(v)
    local shouldShow = v == true
    if self.VisibleState == shouldShow then return end
    self.VisibleState = shouldShow
    
    if shouldShow then
        self.Main.Visible = true
        self.Main.GroupTransparency = 1
        self.UIScale.Scale = 0.95
        tw(self.Main, 0.5, {GroupTransparency = 0}, Enum.EasingStyle.Exponential):Play()
        tw(self.UIScale, 0.5, {Scale = 1}, Enum.EasingStyle.Exponential):Play()
    else
        local t = tw(self.Main, 0.4, {GroupTransparency = 1}, Enum.EasingStyle.Exponential)
        tw(self.UIScale, 0.4, {Scale = 0.95}, Enum.EasingStyle.Exponential):Play()
        t:Play()
        t.Completed:Connect(function()
            if not self.VisibleState then
                self.Main.Visible = false
            end
        end)
    end
end

function Window:PlayInitializeAnimation()
    task.spawn(function()
        local overlay = mk("Frame", {
            Parent = self.ScreenGui,
            BackgroundColor3 = C.Main,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 100,
        })
        
        local loader = mk("Frame", {
            Parent = overlay,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = C.Panel,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(250, 4),
        })
        corner(loader, 2)
        
        local fill = mk("Frame", {
            Parent = loader,
            BackgroundColor3 = C.Accent,
            Size = UDim2.new(0, 0, 1, 0),
        })
        corner(fill, 2)
        
        local text = mk("TextLabel", {
            Parent = overlay,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, -20),
            Size = UDim2.fromOffset(200, 20),
            Font = FONT_BOLD,
            Text = "ZYNTRA V3",
            TextColor3 = C.Text,
            TextSize = 18,
            TextTransparency = 1,
        })
        
        tw(text, 0.5, {TextTransparency = 0}):Play()
        task.wait(0.5)
        tw(fill, 0.8, {Size = UDim2.new(1, 0, 1, 0)}, Enum.EasingStyle.Quart):Play()
        task.wait(1.0)
        tw(overlay, 0.4, {BackgroundTransparency = 1}):Play()
        tw(text, 0.3, {TextTransparency = 1}):Play()
        tw(loader, 0.3, {BackgroundTransparency = 1}):Play()
        tw(fill, 0.3, {BackgroundTransparency = 1}):Play()
        task.delay(0.4, function() overlay:Destroy() end)
    end)
end

function Window:SetTitle(s)
    if self.LogoText then self.LogoText.Text = tostring(s or "Zyntra V3") end
end

function Window:SetSubtitle(s)
    if self.LogoSub then self.LogoSub.Text = tostring(s or "Interface") end
end

function Window:Toggle()
    self:SetVisible(not self.VisibleState)
end

function Window:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    if self.ScreenGui then self.ScreenGui:Destroy() end
    if UILibrary._window == self then UILibrary._window = nil end
end

-- Library Methods
function UILibrary:CreateWindow(options)
    options = options or {}
    local title = options.Title or options.Name or "Zyntra V3"
    local subtitle = options.Subtitle or "Interface"
    
    if self._window then
        self._window:Destroy()
    end
    
    local sg = mk("ScreenGui", {
        Name = GUI_NAME,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        DisplayOrder = 100,
        Enabled = true,
        IgnoreGuiInset = true,
    })
    protect(sg)
    
    local parent = guiParent()
    if not parent then
        warn("[Zyntra V3] Could not find a suitable GUI parent!")
        return nil
    end
    sg.Parent = parent
    
    local main = mk("Frame", {
        Name = "Main",
        Parent = sg,
        BackgroundColor3 = C.Main,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -300, 0.5, -210),
        Size = UDim2.fromOffset(600, 420),
        ClipsDescendants = false,
        Visible = true,
    })
    corner(main, 14)
    stroke(main, C.Stroke, 0.4, 1)
    
    -- Shadow
    local shadow = mk("ImageLabel", {
        Name = "Shadow",
        Parent = main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -15, 0, -15),
        Size = UDim2.new(1, 30, 1, 30),
        Image = "rbxassetid://6015667343",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.6,
        ZIndex = -1,
    })
    
    local canvas = mk("Frame", {
        Name = "Container",
        Parent = main,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
    })
    
    local uiScale = mk("UIScale", {
        Parent = main,
        Scale = 1,
    })
    
    -- Sidebar
    local sidebar = mk("Frame", {
        Name = "Sidebar",
        Parent = canvas,
        BackgroundColor3 = C.Sidebar,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 160, 1, 0),
    })
    corner(sidebar, 12)
    
    -- Sidebar Gradient (subtle light at top)
    local sideGrad = mk("UIGradient", {
        Parent = sidebar,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.95),
            NumberSequenceKeypoint.new(1, 1)
        })
    })
    
    local sideStroke = mk("Frame", {
        Name = "Stroke",
        Parent = sidebar,
        BackgroundColor3 = C.Stroke,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundTransparency = 0.5,
    })
    
    local logoHolder = mk("Frame", {
        Name = "LogoHolder",
        Parent = sidebar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 60),
    })
    
    local logoText = mk("TextLabel", {
        Name = "Logo",
        Parent = logoHolder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 15),
        Size = UDim2.new(1, -30, 0, 20),
        Font = FONT_BOLD,
        Text = title,
        TextColor3 = C.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local logoSub = mk("TextLabel", {
        Name = "Subtitle",
        Parent = logoHolder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 35),
        Size = UDim2.new(1, -30, 0, 15),
        Font = FONT,
        Text = subtitle,
        TextColor3 = C.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local tabContainer = mk("ScrollingFrame", {
        Name = "TabContainer",
        Parent = sidebar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 70),
        Size = UDim2.new(1, 0, 1, -80),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0,
    })
    mk("UIListLayout", {
        Parent = tabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })
    mk("UIPadding", {
        Parent = tabContainer,
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    })
    
    -- Content Area
    local content = mk("Frame", {
        Name = "Content",
        Parent = canvas,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 160, 0, 0),
        Size = UDim2.new(1, -160, 1, 0),
    })
    
    local header = mk("Frame", {
        Name = "Header",
        Parent = content,
        BackgroundColor3 = C.Header,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 50),
    })
    
    local headerTitle = mk("TextLabel", {
        Name = "Title",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 15),
        Size = UDim2.new(1, -40, 0, 20),
        Font = FONT_BOLD,
        Text = "Home",
        TextColor3 = C.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local pageContainer = mk("Frame", {
        Name = "Pages",
        Parent = content,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 50),
        Size = UDim2.new(1, 0, 1, -50),
    })
    
    -- Dragging
    local dragging, dragInput, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and UIS:GetFocusedTextBox() == nil then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    local windowObj = setmetatable({
        ScreenGui = sg,
        Main = main,
        CanvasGroup = canvas,
        UIScale = uiScale,
        TabContainer = tabContainer,
        PageContainer = pageContainer,
        HeaderTitle = headerTitle,
        LogoText = logoText,
        LogoSub = logoSub,
        Tabs = {},
        ActiveTab = nil,
        VisibleState = true,
        Destroyed = false,
    }, Window)
    
    windowObj:PlayInitializeAnimation()
    
    print("[Zyntra V3] Window created successfully.")
    self._window = windowObj
    return windowObj
end

-- Aliases for UILibrary
function UILibrary:CreateTab(...) return self._window:AddTab(...) end

-- Tab Implementation
function Window:AddTab(name, icon)
    if typeof(name) == "table" then
        icon = name.Icon
        name = name.Name or name.Text or "Tab"
    end
    
    local tabObj = setmetatable({
        Window = self,
        Name = name,
        Icon = icon,
        Sections = {},
        Active = false,
    }, Tab)
    
    local button = mk("TextButton", {
        Name = name,
        Parent = self.TabContainer,
        BackgroundColor3 = C.Control,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
        AutoButtonColor = false,
        Font = FONT,
        Text = "",
    })
    corner(button, 8)
    
    local label = mk("TextLabel", {
        Parent = button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = FONT,
        Text = name,
        TextColor3 = C.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local iconImg = mk("ImageLabel", {
        Parent = button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0.5, -9),
        Size = UDim2.fromOffset(18, 18),
        Image = icon or "rbxassetid://6034287525",
        ImageColor3 = C.SubText,
    })
    
    local indicator = mk("Frame", {
        Parent = button,
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 2, 0.5, -9),
        Size = UDim2.fromOffset(3, 18),
        BackgroundTransparency = 1,
    })
    corner(indicator, 2)
    
    local page = mk("ScrollingFrame", {
        Name = name,
        Parent = self.PageContainer,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.Accent,
        Visible = false,
    })
    
    local leftColumn = mk("Frame", {
        Name = "Left",
        Parent = page,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -5, 1, 0),
    })
    local rightColumn = mk("Frame", {
        Name = "Right",
        Parent = page,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 5, 0, 0),
        Size = UDim2.new(0.5, -5, 1, 0),
    })
    
    for _, col in ipairs({leftColumn, rightColumn}) do
        mk("UIListLayout", {
            Parent = col,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
        })
    end
    
    mk("UIPadding", {
        Parent = page,
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
    })
    
    tabObj.Button = button
    tabObj.Label = label
    tabObj.IconImg = iconImg
    tabObj.Indicator = indicator
    tabObj.Page = page
    tabObj.LeftColumn = leftColumn
    tabObj.RightColumn = rightColumn
    
    function tabObj:Select()
        if self.Window.ActiveTab then
            local prev = self.Window.ActiveTab
            prev.Active = false
            prev.Page.Visible = false
            tw(prev.Label, 0.3, {TextColor3 = C.SubText}):Play()
            tw(prev.IconImg, 0.3, {ImageColor3 = C.SubText}):Play()
            tw(prev.Indicator, 0.3, {BackgroundTransparency = 1}):Play()
            tw(prev.Button, 0.3, {BackgroundTransparency = 1}):Play()
        end
        
        self.Active = true
        self.Window.ActiveTab = self
        self.Window.HeaderTitle.Text = self.Name
        self.Page.Visible = true
        
        tw(self.Label, 0.3, {TextColor3 = C.Text}):Play()
        tw(self.IconImg, 0.3, {ImageColor3 = C.Text}):Play()
        tw(self.Indicator, 0.3, {BackgroundTransparency = 0}):Play()
        tw(self.Button, 0.3, {BackgroundTransparency = 0.85}):Play()
    end
    
    button.MouseButton1Click:Connect(function()
        tabObj:Select()
    end)
    
    if #self.Tabs == 0 then
        task.defer(function() 
            task.wait(0.1)
            print("[Zyntra V3] Selecting initial tab:", name)
            tabObj:Select() 
        end)
    end
    
    table.insert(self.Tabs, tabObj)
    return tabObj
end

-- Aliases for Tab
Tab.CreateSection = function(self, ...) return self:AddSection(...) end

-- Section Implementation
function Tab:AddSection(data)
    local name, side
    if typeof(data) == "table" then
        name = data.Name or data.Text
        side = tostring(data.Side or "Left"):lower()
    else
        name = data
        side = "left"
    end
    
    local sectionObj = setmetatable({
        Tab = self,
        Name = name,
        Controls = {},
    }, Section)
    
    local parent = (side == "right") and self.RightColumn or self.LeftColumn
    
    local container = mk("Frame", {
        Name = name or "Section",
        Parent = parent,
        BackgroundColor3 = C.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    corner(container, 10)
    stroke(container, C.Stroke, 0.6)
    
    local layout = mk("UIListLayout", {
        Parent = container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })
    mk("UIPadding", {
        Parent = container,
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 12),
    })
    
    if name then
        local title = mk("TextLabel", {
            Name = "Title",
            Parent = container,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Font = FONT_BOLD,
            Text = name:upper(),
            TextColor3 = C.Accent,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = -1,
        })
    end
    
    sectionObj.Container = container
    return sectionObj
end

-- Aliases for Section
Section.CreateButton = function(self, ...) return self:AddButton(...) end
Section.CreateToggle = function(self, ...) return self:AddToggle(...) end
Section.CreateSlider = function(self, ...) return self:AddSlider(...) end
Section.CreateDropdown = function(self, ...) return self:AddDropdown(...) end
Section.CreateInput = function(self, ...) return self:AddTextbox(...) end
Section.CreateTextbox = function(self, ...) return self:AddTextbox(...) end
Section.CreateKeybind = function(self, ...) return self:AddKeybind(...) end
Section.CreateLabel = function(self, ...) return self:AddLabel(...) end
Section.CreateParagraph = function(self, ...) return self:AddParagraph(...) end
Section.CreateDivider = function(self, ...) return self:AddDivider(...) end

-- Controls Implementation
function Section:AddButton(data)
    local title, callback
    if typeof(data) == "table" then
        title = data.Title or data.Name or data.Text or "Button"
        callback = data.Callback
    else
        title = tostring(data or "Button")
        callback = function() end
    end
    
    local btn = mk("TextButton", {
        Parent = self.Container,
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        AutoButtonColor = false,
        Font = FONT,
        Text = "",
    })
    corner(btn, 6)
    stroke(btn, C.StrokeLight, 0.8)
    
    local label = mk("TextLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = FONT,
        Text = title,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local icon = mk("ImageLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -25, 0.5, -8),
        Size = UDim2.fromOffset(16, 16),
        Image = "rbxassetid://6023426915",
        ImageColor3 = C.SubText,
    })
    
    btn.MouseEnter:Connect(function() tw(btn, 0.2, {BackgroundColor3 = C.ControlHover}):Play() end)
    btn.MouseLeave:Connect(function() tw(btn, 0.2, {BackgroundColor3 = C.Control}):Play() end)
    btn.MouseButton1Down:Connect(function() tw(btn, 0.1, {BackgroundColor3 = C.ControlActive}):Play() end)
    btn.MouseButton1Up:Connect(function() tw(btn, 0.1, {BackgroundColor3 = C.ControlHover}):Play() end)
    btn.MouseButton1Click:Connect(function() safe(callback) end)
    
    return {
        SetTitle = function(_, s) label.Text = s end
    }
end

function Section:AddToggle(data)
    local title, default, callback
    if typeof(data) == "table" then
        title = data.Title or data.Name or data.Text or "Toggle"
        default = data.Default or data.CurrentValue or false
        callback = data.Callback
    else
        title = tostring(data or "Toggle")
        default = false
        callback = function() end
    end
    local state = default
    
    local btn = mk("TextButton", {
        Parent = self.Container,
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        AutoButtonColor = false,
        Font = FONT,
        Text = "",
    })
    corner(btn, 6)
    stroke(btn, C.StrokeLight, 0.8)
    
    local label = mk("TextLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = FONT,
        Text = title,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local toggler = mk("Frame", {
        Parent = btn,
        BackgroundColor3 = C.Main,
        Position = UDim2.new(1, -45, 0.5, -9),
        Size = UDim2.fromOffset(36, 18),
    })
    corner(toggler, 9)
    stroke(toggler, C.Stroke, 0.5)
    
    local circle = mk("Frame", {
        Parent = toggler,
        BackgroundColor3 = C.SubText,
        Position = UDim2.new(0, 2, 0.5, -7),
        Size = UDim2.fromOffset(14, 14),
    })
    corner(circle, 7)
    
    local function update()
        if state then
            tw(circle, 0.2, {Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = C.Accent}):Play()
            tw(toggler, 0.2, {BackgroundColor3 = C.Accent, BackgroundTransparency = 0.8}):Play()
        else
            tw(circle, 0.2, {Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = C.SubText}):Play()
            tw(toggler, 0.2, {BackgroundColor3 = C.Main, BackgroundTransparency = 0}):Play()
        end
    end
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        update()
        safe(callback, state)
    end)
    
    update()
    
    return {
        Set = function(_, v) state = v update() safe(callback, state) end,
        Get = function() return state end
    }
end

function Section:AddSlider(data, b, c, d, e)
    local title, min, max, default, precision, callback
    if typeof(data) == "table" then
        title = data.Title or data.Name or data.Text or "Slider"
        min = data.Min or (data.Range and data.Range[1]) or 0
        max = data.Max or (data.Range and data.Range[2]) or 100
        default = data.Default or data.CurrentValue or min
        precision = data.Precision or data.Increment or 0
        callback = data.Callback
    else
        title = tostring(data or "Slider")
        min = tonumber(b) or 0
        max = tonumber(c) or 100
        default = tonumber(d) or min
        precision = 0
        callback = e
    end
    
    local value = math.clamp(default, min, max)
    
    local container = mk("Frame", {
        Parent = self.Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 45),
    })
    
    local label = mk("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 0, 20),
        Font = FONT,
        Text = title,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local valLabel = mk("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -40, 0, 0),
        Size = UDim2.fromOffset(40, 20),
        Font = FONT,
        Text = tostring(value),
        TextColor3 = C.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    
    local sliderBack = mk("Frame", {
        Parent = container,
        BackgroundColor3 = C.Control,
        Position = UDim2.new(0, 0, 0, 28),
        Size = UDim2.new(1, 0, 0, 6),
    })
    corner(sliderBack, 3)
    
    local sliderFill = mk("Frame", {
        Parent = sliderBack,
        BackgroundColor3 = C.Accent,
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
    })
    corner(sliderFill, 3)
    
    local handle = mk("Frame", {
        Parent = sliderFill,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.Text,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
    })
    corner(handle, 6)
    stroke(handle, C.Accent, 0.5, 2)
    
    local function update(input)
        local pos = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        value = (precision > 0) and tonumber(string.format("%." .. precision .. "f", min + (max - min) * pos)) or math.floor(min + (max - min) * pos + 0.5)
        
        tw(sliderFill, 0.1, {Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}):Play()
        valLabel.Text = tostring(value)
        safe(callback, value)
    end
    
    local sliding = false
    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            update(input)
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    
    return {
        Set = function(_, v) 
            value = math.clamp(v, min, max)
            tw(sliderFill, 0.2, {Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}):Play()
            valLabel.Text = tostring(value)
            safe(callback, value)
        end,
        Get = function() return value end
    }
end

function Section:AddDropdown(data, b, c, d)
    local title, options, multi, default, callback
    if typeof(data) == "table" then
        title = data.Title or data.Name or data.Text or "Dropdown"
        options = data.Options or data.Values or {}
        multi = data.Multi or data.MultipleOptions == true
        default = data.Default or data.CurrentOption
        callback = data.Callback
    else
        title = tostring(data or "Dropdown")
        options = b or {}
        multi = false
        default = c
        callback = d
    end
    
    local selected = multi and {} or nil
    if not multi then
        selected = default or options[1]
    else
        if typeof(default) == "table" then
            for _, v in ipairs(default) do selected[v] = true end
        end
    end
    
    local container = mk("Frame", {
        Parent = self.Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    
    local btn = mk("TextButton", {
        Parent = container,
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        AutoButtonColor = false,
        Font = FONT,
        Text = "",
    })
    corner(btn, 6)
    stroke(btn, C.StrokeLight, 0.8)
    
    local label = mk("TextLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = FONT,
        Text = title .. ": " .. (multi and "..." or tostring(selected or "None")),
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local icon = mk("ImageLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -25, 0.5, -8),
        Size = UDim2.fromOffset(16, 16),
        Image = "rbxassetid://6034818372",
        ImageColor3 = C.SubText,
    })
    
    local list = mk("Frame", {
        Parent = container,
        BackgroundColor3 = C.Sidebar,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 10,
    })
    corner(list, 6)
    stroke(list, C.Stroke, 0.5)
    
    local listLayout = mk("UIListLayout", {
        Parent = list,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })
    mk("UIPadding", {
        Parent = list,
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
    })
    
    local open = false
    local function refresh()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        for _, opt in ipairs(options) do
            local isSel = multi and selected[opt] or (selected == opt)
            local optBtn = mk("TextButton", {
                Parent = list,
                BackgroundColor3 = isSel and C.Accent or C.Control,
                BackgroundTransparency = isSel and 0.8 or 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 26),
                Font = FONT,
                Text = tostring(opt),
                TextColor3 = isSel and C.Accent or C.SubText,
                TextSize = 12,
                AutoButtonColor = false,
                ZIndex = 11,
            })
            corner(optBtn, 4)
            
            optBtn.MouseButton1Click:Connect(function()
                if multi then
                    selected[opt] = not selected[opt]
                    local res = {}
                    for k, v in pairs(selected) do if v then table.insert(res, k) end end
                    label.Text = title .. ": (" .. #res .. ")"
                    safe(callback, res)
                else
                    selected = opt
                    label.Text = title .. ": " .. tostring(opt)
                    open = false
                    tw(list, 0.3, {Size = UDim2.new(1, 0, 0, 0)}):Play()
                    task.delay(0.3, function() if not open then list.Visible = false end end)
                    safe(callback, opt)
                end
                refresh()
            end)
        end
        
        local targetSize = math.min(#options * 28 + 8, 200)
        if open then
            list.Visible = true
            tw(list, 0.3, {Size = UDim2.new(1, 0, 0, targetSize)}):Play()
        end
    end
    
    btn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            refresh()
        else
            tw(list, 0.3, {Size = UDim2.new(1, 0, 0, 0)}):Play()
            task.delay(0.3, function() if not open then list.Visible = false end end)
        end
    end)
    
    return {
        Set = function(_, v) selected = v refresh() label.Text = title .. ": " .. (multi and "..." or tostring(selected)) end,
        Refresh = function(_, newOpts) options = newOpts refresh() end
    }
end

function Section:AddTextbox(data, b, c)
    local title, default, placeholder, clear, callback
    if typeof(data) == "table" then
        title = data.Title or data.Name or data.Text or "Textbox"
        default = data.Default or data.CurrentValue or ""
        placeholder = data.Placeholder or data.PlaceholderText or "Type here..."
        clear = data.ClearOnFocus or data.RemoveTextAfterFocusLost == true
        callback = data.Callback
    else
        title = tostring(data or "Textbox")
        default = tostring(c or "")
        placeholder = "Type here..."
        clear = false
        callback = b
    end
    
    local btn = mk("Frame", {
        Parent = self.Container,
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
    })
    corner(btn, 6)
    stroke(btn, C.StrokeLight, 0.8)
    
    local label = mk("TextLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0, 80, 1, 0),
        Font = FONT,
        Text = title,
        TextColor3 = C.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local box = mk("TextBox", {
        Parent = btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 90, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
        Font = FONT,
        Text = default,
        PlaceholderText = placeholder,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        ClearTextOnFocus = clear,
    })
    
    box.FocusLost:Connect(function(enter)
        safe(callback, box.Text, enter)
    end)
    
    return {
        Set = function(_, v) box.Text = v safe(callback, v, false) end,
        Get = function() return box.Text end
    }
end

function Section:AddKeybind(data, b, c)
    local title, default, callback
    if typeof(data) == "table" then
        title = data.Title or data.Name or data.Text or "Keybind"
        default = data.Default or data.CurrentValue or Enum.KeyCode.F
        callback = data.Callback
    else
        title = tostring(data or "Keybind")
        default = b or Enum.KeyCode.F
        callback = c
    end
    
    local binding = false
    local key = default
    
    local btn = mk("TextButton", {
        Parent = self.Container,
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        AutoButtonColor = false,
        Font = FONT,
        Text = "",
    })
    corner(btn, 6)
    stroke(btn, C.StrokeLight, 0.8)
    
    local label = mk("TextLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = FONT,
        Text = title,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local keyLabel = mk("TextLabel", {
        Parent = btn,
        BackgroundColor3 = C.Main,
        Position = UDim2.new(1, -50, 0.5, -9),
        Size = UDim2.fromOffset(40, 18),
        Font = FONT,
        Text = key.Name,
        TextColor3 = C.Accent,
        TextSize = 11,
    })
    corner(keyLabel, 4)
    stroke(keyLabel, C.Stroke, 0.5)
    
    btn.MouseButton1Click:Connect(function()
        binding = true
        keyLabel.Text = "..."
    end)
    
    UIS.InputBegan:Connect(function(input)
        if binding and input.UserInputType == Enum.UserInputType.Keyboard then
            key = input.KeyCode
            binding = false
            keyLabel.Text = key.Name
            safe(callback, key)
        end
    end)
    
    return {
        Set = function(_, k) key = k keyLabel.Text = k.Name safe(callback, k) end,
        Get = function() return key end
    }
end

function Section:AddLabel(text)
    local label = mk("TextLabel", {
        Parent = self.Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = FONT,
        Text = text,
        TextColor3 = C.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    return {
        Set = function(_, t) label.Text = t end
    }
end

function Section:AddParagraph(data, b)
    local title, content
    if typeof(data) == "table" then
        title = data.Title or data.Name or data.Text or "Paragraph"
        content = data.Content or data.Description or ""
    else
        title = tostring(data or "Paragraph")
        content = tostring(b or "")
    end
    
    local container = mk("Frame", {
        Parent = self.Container,
        BackgroundColor3 = C.Control,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 40),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    corner(container, 6)
    mk("UIPadding", {
        Parent = container,
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
    })
    
    local tLabel = mk("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = FONT_BOLD,
        Text = title,
        TextColor3 = C.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local cLabel = mk("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = FONT,
        Text = content,
        TextColor3 = C.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    })
    
    return {
        SetTitle = function(_, s) tLabel.Text = s end,
        SetContent = function(_, s) cLabel.Text = s end
    }
end

function Section:AddDivider()
    local div = mk("Frame", {
        Parent = self.Container,
        BackgroundColor3 = C.Stroke,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundTransparency = 0.5,
    })
    return div
end

-- Notification System
function UILibrary:Notify(data)
    local title = data.Title or "Notification"
    local content = data.Content or ""
    local duration = data.Duration or 3
    
    local host = self._toastHost
    if not host then
        host = mk("Frame", {
            Name = "Toasts",
            Parent = self._window.ScreenGui,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -280, 1, -20),
            Size = UDim2.new(0, 260, 1, -40),
        })
        mk("UIListLayout", {
            Parent = host,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 10),
        })
        self._toastHost = host
    end
    
    local toast = mk("Frame", {
        Parent = host,
        BackgroundColor3 = C.Main,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
    })
    corner(toast, 8)
    stroke(toast, C.Accent, 0.6)
    
    local pad = mk("UIPadding", {
        Parent = toast,
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
    })
    
    local tLabel = mk("TextLabel", {
        Parent = toast,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = FONT_BOLD,
        Text = title,
        TextColor3 = C.Accent,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local cLabel = mk("TextLabel", {
        Parent = toast,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = FONT,
        Text = content,
        TextColor3 = C.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    })
    
    toast.GroupTransparency = 1
    tw(toast, 0.4, {GroupTransparency = 0}):Play()
    
    task.delay(duration, function()
        tw(toast, 0.4, {GroupTransparency = 1}):Play()
        task.wait(0.4)
        toast:Destroy()
    end)
end

-- Compatibility Aliases
function UILibrary:SetSelectedPlayer(p) self._selectedPlayer = p end
function UILibrary:GetSelectedPlayer() return self._selectedPlayer end
function UILibrary:SuspendFlingProtect(s) self._suspendFlingProtectUntil = os.clock() + s end

return UILibrary
