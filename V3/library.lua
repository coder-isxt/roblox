-- // GTA 5 STYLE MODMENU UI LIBRARY // --
-- // Navigation: Arrow Keys | Select: Enter | Toggle: Insert // --

local UILibrary = {}
UILibrary.__index = UILibrary

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local oldws = 16

-- // CONFIGURATION // --
local Config = {
    Theme = {
        Banner = Color3.fromRGB(10, 10, 10),
        PulseColor = Color3.fromRGB(0, 245, 255),
        SubHeader = Color3.fromRGB(20, 20, 20),
        Background = Color3.fromRGB(15, 15, 15),
        Selected = Color3.fromRGB(0, 245, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextSelected = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(0, 245, 255),
    },
    Font = Enum.Font.SourceSansBold,
    TitleFont = Enum.Font.GothamBold,
    TextSize = 18,
    MenuWidth = 320,
    MaxItemsVisible = 12,
    CornerRadius = UDim.new(0, 8),
    Side = 1, -- 1: Left, 2: Right
    Icons = {
        ["eye"] = "rbxassetid://114275093157258",
        ["house"] = "rbxassetid://82102353211434",
        ["player"] = "rbxassetid://86951848379193",
        ["gear"] = "rbxassetid://106265837716775",
        ["globe"] = "rbxassetid://101268280882288",
        ["players"] = "rbxassetid://94079975328593",
        ["shield"] = "rbxassetid://82452497198733",
    }
}

-- // STATE // --
local State = {
    CurrentMenu = nil,
    History = {},
    Open = false,
    Side = Config.Side, -- 1: Left, 2: Right
    WatchingPlayer = nil,
    Binding = nil,
    Keybinds = {},
    AllMenus = {} -- Track all menus for config saving
}

local function createMenuData(title, subtitle)
    local menu = {
        Title = title,
        Subtitle = subtitle,
        Options = {},
        SystemOptions = {}, -- Use this for built-ins
        SelectedIndex = 1,
        IsSystem = false -- Track if this is a built-in menu
    }
    table.insert(State.AllMenus, menu)
    return menu
end

-- // SERIALIZATION HELPERS // --
local function serializeValue(val)
    if typeof(val) == "Color3" then
        return {Type = "Color3", r = val.R, g = val.G, b = val.B}
    elseif typeof(val) == "EnumItem" then
        return {Type = "Enum", EnumType = tostring(val.EnumType), Name = val.Name}
    end
    return val
end

local function deserializeValue(val)
    if type(val) == "table" and val.Type then
        if val.Type == "Color3" then
            return Color3.new(val.r, val.g, val.b)
        elseif val.Type == "Enum" then
            return Enum[val.EnumType][val.Name]
        end
    end
    return val
end

-- // CREATE SCREEN GUI // --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Fracture"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui") or Player:WaitForChild("PlayerGui")

-- // MAIN CONTAINER // --
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, Config.MenuWidth, 0, 500)
MainFrame.Position = UDim2.new(0, 50, 0, 50)
MainFrame.BackgroundColor3 = Config.Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Config.Theme.Accent
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = Config.CornerRadius
MainCorner.Parent = MainFrame

-- // HEADER (BANNER) // --
local Banner = Instance.new("Frame")
Banner.Name = "Banner"
Banner.Size = UDim2.new(1, 0, 0, 100)
Banner.BackgroundColor3 = Config.Theme.Banner
Banner.BorderSizePixel = 0
Banner.ClipsDescendants = true
Banner.Parent = MainFrame

local BannerCorner = Instance.new("UICorner")
BannerCorner.CornerRadius = Config.CornerRadius
BannerCorner.Parent = Banner

-- Pulse Line Decoration
local PulseLine = Instance.new("Frame")
PulseLine.Size = UDim2.new(1.5, 0, 0, 2)
PulseLine.Position = UDim2.new(-0.25, 0, 0.5, 0)
PulseLine.BackgroundColor3 = Config.Theme.PulseColor
PulseLine.BorderSizePixel = 0
PulseLine.Visible = false
PulseLine.Parent = Banner

local BannerTexture = Instance.new("ImageLabel")
BannerTexture.Name = "BannerTexture"
BannerTexture.Size = UDim2.new(1, 0, 1, 0)
BannerTexture.BackgroundTransparency = 1
BannerTexture.Image = "rbxassetid://81459253942868"
BannerTexture.ScaleType = Enum.ScaleType.Crop
BannerTexture.Parent = Banner

-- Track state for banner logic
State.Config = {
    SelectedPreset = "Default",
    Banner = {
        UseBanner = true,
        CurrentID = "81459253942868",
        DisableTitle = false,
        Scale = "Crop"
    },
    Binds = {
        Fly = Enum.KeyCode.Z,
        Sprint = Enum.KeyCode.C
    },
    Fly = { Master = false, Active = false, Speed = 100 },
    Sprint = { Master = false, Active = false, Speed = 50 },
    Protections = { AntiFling = false, AntiAFK = false },
    Movement = { Noclip = false, InfiniteJump = false, NoCameraCollision = false }
}



local PulseGradient = Instance.new("UIGradient")
PulseGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 1)
})
PulseGradient.Parent = PulseLine

local BannerTitle = Instance.new("TextLabel")
BannerTitle.Size = UDim2.new(1, 0, 1, 0)
BannerTitle.BackgroundTransparency = 1
BannerTitle.Text = "IMPULSE"
BannerTitle.TextColor3 = Config.Theme.PulseColor
BannerTitle.TextSize = 45
BannerTitle.Font = Config.TitleFont
BannerTitle.TextStrokeTransparency = 0.8
BannerTitle.Parent = Banner

-- // SUB-HEADER // --
local SubHeader = Instance.new("Frame")
SubHeader.Name = "SubHeader"
SubHeader.Size = UDim2.new(1, 0, 0, 30)
SubHeader.Position = UDim2.new(0, 0, 0, 100)
SubHeader.BackgroundColor3 = Config.Theme.SubHeader
SubHeader.BorderSizePixel = 0
SubHeader.Parent = MainFrame

local SubCorner = Instance.new("UICorner")
SubCorner.CornerRadius = Config.CornerRadius
SubCorner.Parent = SubHeader

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, 0, 1, 0)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Home"
SubTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
SubTitle.TextSize = 16
SubTitle.Font = Config.Font
SubTitle.TextXAlignment = Enum.TextXAlignment.Center
SubTitle.Parent = SubHeader

-- // LEFT SCROLLBAR // --
local ScrollbarFrame = Instance.new("Frame")
ScrollbarFrame.Name = "Scrollbar"
ScrollbarFrame.Size = UDim2.new(0, 8, 1, -165)
ScrollbarFrame.Position = UDim2.new(0, 2, 0, 135)
ScrollbarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ScrollbarFrame.BorderSizePixel = 0
ScrollbarFrame.Parent = MainFrame

local ScrollIndicator = Instance.new("Frame")
ScrollIndicator.Size = UDim2.new(1, 0, 0, 40)
ScrollIndicator.BackgroundColor3 = Config.Theme.Accent
ScrollIndicator.BorderSizePixel = 0
ScrollIndicator.Parent = ScrollbarFrame

-- // OPTIONS CONTAINER // --
local OptionsContainer = Instance.new("Frame")
OptionsContainer.Name = "Options"
OptionsContainer.Size = UDim2.new(1, -15, 0, 0)
OptionsContainer.Position = UDim2.new(0, 15, 0, 135)
OptionsContainer.BackgroundTransparency = 1
OptionsContainer.BorderSizePixel = 0
OptionsContainer.ClipsDescendants = true
OptionsContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = OptionsContainer

-- // FOOTER // --
local Footer = Instance.new("Frame")
Footer.Name = "Footer"
Footer.Size = UDim2.new(1, 0, 0, 35)
Footer.BackgroundColor3 = Config.Theme.SubHeader
Footer.BorderSizePixel = 0
Footer.Parent = MainFrame

local FooterCorner = Instance.new("UICorner")
FooterCorner.CornerRadius = Config.CornerRadius
FooterCorner.Parent = Footer

local ItemCount = Instance.new("TextLabel")
ItemCount.Size = UDim2.new(0.4, 0, 1, 0)
ItemCount.Position = UDim2.new(0, 10, 0, 0)
ItemCount.BackgroundTransparency = 1
ItemCount.Text = "1 / 1"
ItemCount.TextColor3 = Color3.fromRGB(200, 200, 200)
ItemCount.TextSize = 14
ItemCount.Font = Config.Font
ItemCount.TextXAlignment = Enum.TextXAlignment.Left
ItemCount.Parent = Footer

local LogoImage = Instance.new("ImageLabel")
LogoImage.Name = "Logo"
LogoImage.Size = UDim2.new(0, 30, 0, 30)
LogoImage.Position = UDim2.new(0.5, -15, 0.5, -15)
LogoImage.BackgroundTransparency = 1
LogoImage.Image = "rbxassetid://86045912751052" -- No background: 86045912751052, with background: 116835985349151
LogoImage.ZIndex = 25
LogoImage.Parent = Footer
LogoImage.ScaleType = Enum.ScaleType.Fit
LogoImage.Visible = true

-- // INPUT POPUP // --
local InputPopup = Instance.new("Frame")
InputPopup.Name = "InputPopup"
InputPopup.Size = UDim2.new(0, 300, 0, 100)
InputPopup.Position = UDim2.new(0.5, -150, 0.5, -50)
InputPopup.BackgroundColor3 = Config.Theme.Background
InputStroke = Instance.new("UIStroke")
InputStroke.Thickness = 2
InputStroke.Color = Config.Theme.Accent
InputStroke.Parent = InputPopup
InputPopup.Visible = false
InputPopup.Parent = ScreenGui

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = Config.CornerRadius
InputCorner.Parent = InputPopup

local InputPlaceholder = Instance.new("TextLabel")
InputPlaceholder.Size = UDim2.new(1, 0, 0, 30)
InputPlaceholder.Position = UDim2.new(0, 0, 0, 10)
InputPlaceholder.BackgroundTransparency = 1
InputPlaceholder.Text = "Enter Value"
InputPlaceholder.TextColor3 = Config.Theme.Accent
InputPlaceholder.TextSize = 16
InputPlaceholder.Font = Config.Font
InputPlaceholder.Parent = InputPopup

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(0.8, 0, 0, 35)
InputBox.Position = UDim2.new(0.1, 0, 0, 45)
InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
InputBox.BorderSizePixel = 0
InputBox.Text = ""
InputBox.PlaceholderText = "Type here..."
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.TextSize = 16
InputBox.Font = Config.Font
InputBox.Parent = InputPopup

-- // DESCRIPTION BOX // --
local DescFrame = Instance.new("Frame")
DescFrame.Name = "Description"
DescFrame.Size = UDim2.new(1, 0, 0, 40)
DescFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DescFrame.BackgroundTransparency = 0.4
DescFrame.BorderSizePixel = 0
DescFrame.Parent = MainFrame

local DescCorner = Instance.new("UICorner")
DescCorner.CornerRadius = Config.CornerRadius
DescCorner.Parent = DescFrame

local DescText = Instance.new("TextLabel")
DescText.Size = UDim2.new(1, -20, 1, 0)
DescText.Position = UDim2.new(0, 10, 0, 0)
DescText.BackgroundTransparency = 1
DescText.Text = ""
DescText.TextColor3 = Color3.fromRGB(255, 255, 255)
DescText.TextSize = 14
DescText.Font = Config.Font
DescText.TextWrapped = true
DescText.TextXAlignment = Enum.TextXAlignment.Left
DescText.Parent = DescFrame

-- // PLAYER STATS PANEL // --
local StatsPanel = Instance.new("Frame")
StatsPanel.Name = "StatsPanel"
StatsPanel.Size = UDim2.new(0, 200, 0, 320)
StatsPanel.BackgroundColor3 = Config.Theme.Background
StatsPanel.Visible = false
StatsPanel.Parent = ScreenGui

local StatsCorner = Instance.new("UICorner")
StatsCorner.CornerRadius = Config.CornerRadius
StatsCorner.Parent = StatsPanel

local StatsStroke = Instance.new("UIStroke")
StatsStroke.Thickness = 1.5
StatsStroke.Color = Config.Theme.Accent
StatsStroke.Transparency = 0.5
StatsStroke.Parent = StatsPanel

local StatsAvatar = Instance.new("ImageLabel")
StatsAvatar.Size = UDim2.new(0, 100, 0, 100)
StatsAvatar.Position = UDim2.new(0.5, -50, 0, 15)
StatsAvatar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
StatsAvatar.Image = ""
StatsAvatar.Parent = StatsPanel

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = StatsAvatar

local StatsInfo = Instance.new("TextLabel")
StatsInfo.Size = UDim2.new(1, -20, 1, -125)
StatsInfo.Position = UDim2.new(0, 10, 0, 120)
StatsInfo.BackgroundTransparency = 1
StatsInfo.Text = ""
StatsInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
StatsInfo.TextSize = 14
StatsInfo.Font = Config.Font
StatsInfo.TextXAlignment = Enum.TextXAlignment.Left
StatsInfo.TextYAlignment = Enum.TextYAlignment.Top
StatsInfo.RichText = true
StatsInfo.Parent = StatsPanel

-- // NOTIFICATION CONTAINER // --
local NotifyContainer = Instance.new("Frame")
NotifyContainer.Name = "Notifications"
NotifyContainer.Size = UDim2.new(0, 300, 1, -20)
NotifyContainer.Position = UDim2.new(1, -310, 0, 10)
NotifyContainer.BackgroundTransparency = 1
NotifyContainer.Parent = ScreenGui

local NotifyLayout = Instance.new("UIListLayout")
NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifyLayout.Padding = UDim.new(0, 10)
NotifyLayout.Parent = NotifyContainer



local function updateBannerUI()
    local b = State.Config.Banner
    if b.UseBanner and b.CurrentID ~= "" and b.CurrentID ~= "0" then
        BannerTexture.Image = "rbxassetid://" .. b.CurrentID
        BannerTexture.Visible = true
        PulseLine.Visible = false
    else
        BannerTexture.Visible = false
        PulseLine.Visible = true
    end
    
    BannerTitle.Visible = not b.DisableTitle
end

local function applyTheme(themeData)
    for k, v in pairs(themeData) do
        Config.Theme[k] = v
    end
    
    -- Update Static Elements
    MainFrame.BackgroundColor3 = Config.Theme.Background
    MainStroke.Color = Config.Theme.Accent
    Banner.BackgroundColor3 = Config.Theme.Banner
    PulseLine.BackgroundColor3 = Config.Theme.PulseColor
    
    -- Refresh current menu UI
    if State.CurrentMenu then
        renderMenu(State.CurrentMenu)
    end
end

-- // INTERNAL FUNCTIONS // --
local function getCombinedOptions(menu)
    if not menu then return {} end
    local combined = {}
    for _, opt in ipairs(menu.Options or {}) do
        table.insert(combined, opt)
    end
    for _, opt in ipairs(menu.SystemOptions or {}) do
        table.insert(combined, opt)
    end
    return combined
end

local function updateMenuPosition()
    local targetPos = (Config.Side == 1) 
        and UDim2.new(0, 50, 0, 50) 
        -- Right side calculation: Screen - Width - Padding
        or UDim2.new(1, -(Config.MenuWidth + 50), 0, 50)
    
    TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = targetPos
    }):Play()

    -- Update StatsPanel Position (Aligned to top of MainFrame)
    local statsTarget = (Config.Side == 1)
        and UDim2.new(0, Config.MenuWidth + 60, 0, 50)
        or UDim2.new(1, -(Config.MenuWidth + 260), 0, 50)
    
    StatsPanel.Position = statsTarget
end

local function updateMainFrameSize()
    local menu = State.CurrentMenu
    local combined = getCombinedOptions(menu)
    local optionsCount = #combined
    
    -- Fixed window size for scrolling
    local visibleCount = math.min(optionsCount, Config.MaxItemsVisible)
    local optionsHeight = math.max(visibleCount * 35, 40)
    
    -- Correct offsets to prevent overlap
    local optionsStart = 135
    local footerStart = optionsStart + optionsHeight + 5
    local descStart = footerStart + 35 + 5
    local totalHeight = descStart + 40 + 5
    
    MainFrame.Size = UDim2.new(0, Config.MenuWidth, 0, totalHeight)
    OptionsContainer.Size = UDim2.new(1, -15, 0, optionsHeight)
    
    Footer.Position = UDim2.new(0, 0, 0, footerStart)
    DescFrame.Position = UDim2.new(0, 0, 0, descStart)
    
    ScrollbarFrame.Visible = optionsCount > 0
    if optionsCount > 0 then
        ScrollbarFrame.Size = UDim2.new(0, 8, 0, optionsHeight)
        ScrollbarFrame.Position = UDim2.new(0, 2, 0, optionsStart)
        local progress = (menu.SelectedIndex - 1) / math.max(1, optionsCount - 1)
        local pos = progress * (optionsHeight - 40)
        ScrollIndicator.Position = UDim2.new(0, 0, 0, pos)
    end
end

local function updateSelection()
    local menu = State.CurrentMenu
    local combined = getCombinedOptions(menu)
    local count = #combined
    
    if count == 0 then
        menu.SelectedIndex = 1
        ItemCount.Text = "0 / 0"
        DescText.Text = "No options available in this menu."
        updateMainFrameSize()
        return
    end
    
    -- Ensure we aren't selecting a label (especially on menu open)
    if combined[menu.SelectedIndex] and combined[menu.SelectedIndex].Type == "label" then
        for i, opt in ipairs(combined) do
            if opt.Type ~= "label" then
                menu.SelectedIndex = i
                break
            end
        end
    end

    local start = 1
    if count > Config.MaxItemsVisible then
        start = math.clamp(menu.SelectedIndex - math.floor(Config.MaxItemsVisible / 2), 1, count - Config.MaxItemsVisible + 1)
    end
    local finish = math.min(count, start + Config.MaxItemsVisible - 1)

    for i, optData in ipairs(combined) do
        local isSelected = (i == menu.SelectedIndex)
        local isVisible = (i >= start and i <= finish)
        local frame = optData.UI.Frame
        
        frame.Visible = isVisible
        
        if isVisible then
            if optData.Type == "label" then
                -- Labels don't get selection highlights
                frame.BackgroundTransparency = 1
            else
                TweenService:Create(frame, TweenInfo.new(0.1), {
                    BackgroundColor3 = isSelected and Config.Theme.Selected or Color3.fromRGB(0,0,0),
                    BackgroundTransparency = isSelected and 0 or 1
                }):Play()
            end

            local textColor = (isSelected and optData.Type ~= "label") and Config.Theme.TextSelected or (optData.Type == "label" and Config.Theme.Accent or Config.Theme.Text)
            
            optData.UI.Label.TextColor3 = textColor
            optData.UI.ValueLabel.TextColor3 = textColor
            optData.UI.Arrow.TextColor3 = (isSelected and optData.Type ~= "label") and Config.Theme.TextSelected or Color3.fromRGB(150, 150, 150)
            
            if optData.UI.Icon then
                optData.UI.Icon.ImageColor3 = isSelected and Config.Theme.TextSelected or Config.Theme.Text
            end
            
            if optData.UI.Checkbox then
                if isSelected then
                    optData.UI.Checkbox.BackgroundColor3 = optData.Value and Color3.new(0,0,0) or Color3.fromRGB(40, 40, 40)
                else
                    optData.UI.Checkbox.BackgroundColor3 = optData.Value and Config.Theme.Accent or Color3.fromRGB(40, 40, 40)
                end
            end
            
            if isSelected then
                DescText.Text = optData.Description or ""
                
                -- Update Stats Panel
                if optData.PlayerObj then
                    StatsPanel.Visible = true
                    State.WatchingPlayer = optData.PlayerObj
                    StatsAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. optData.PlayerObj.UserId .. "&w=150&h=150"
                else
                    StatsPanel.Visible = false
                    State.WatchingPlayer = nil
                end
            end
        end
    end

    -- Calculate accurate item count (excluding labels)
    local totalSelectable = 0
    local selectableIndex = 0
    for i, opt in ipairs(combined) do
        if opt.Type ~= "label" then
            totalSelectable = totalSelectable + 1
            if i <= menu.SelectedIndex then
                selectableIndex = selectableIndex + 1
            end
        end
    end

    ItemCount.Text = selectableIndex .. " / " .. totalSelectable
    updateMainFrameSize()
end

local function openInputPopup(optData)
    InputPopup.Visible = true
    InputPlaceholder.Text = optData.Placeholder or "Enter Value"
    InputBox.Text = tostring(optData.Value or "")
    InputBox:CaptureFocus()
    
    local connection
    connection = InputBox.FocusLost:Connect(function(enterPressed)
        optData.Value = InputBox.Text
        optData.UI.ValueLabel.Text = optData.Value
        optData.Callback(optData.Value)
        
        InputPopup.Visible = false
        connection:Disconnect()
    end)
end

local function renderMenu(menu)
    -- Clear current UI
    for _, child in ipairs(OptionsContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local combined = getCombinedOptions(menu)

    -- Rebuild UI from data
    for i, optData in ipairs(combined) do
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 35)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Parent = OptionsContainer
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 4)
        frameCorner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, (optData.Type == "label" and 10 or (optData.Icon and 35 or 10)), 0, 0)
        label.BackgroundTransparency = 1
        label.Text = optData.Type == "label" and ("--- " .. optData.Name:upper() .. " ---") or optData.Name
        label.TextColor3 = (optData.Type == "label" and Config.Theme.Accent or Config.Theme.Text)
        label.TextSize = (optData.Type == "label" and 14 or Config.TextSize)
        label.Font = Config.Font
        label.TextXAlignment = (optData.Type == "label" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left)
        label.Parent = frame

        local iconImg = nil
        if optData.Icon then
            local iconAsset = Config.Icons[optData.Icon] or optData.Icon
            iconImg = Instance.new("ImageLabel")
            iconImg.Name = "Icon"
            iconImg.Size = UDim2.new(0, 20, 0, 20)
            iconImg.Position = UDim2.new(0, 7, 0.5, -10)
            iconImg.BackgroundTransparency = 1
            iconImg.Image = iconAsset
            iconImg.ImageColor3 = Config.Theme.Accent
            iconImg.Parent = frame
        end

        local arrow = Instance.new("TextLabel")
        arrow.Size = UDim2.new(0, 20, 1, 0)
        arrow.Position = UDim2.new(1, -25, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = (optData.Type == "menu" and ">" or "")
        arrow.TextColor3 = Color3.fromRGB(150, 150, 150)
        arrow.TextSize = 14
        arrow.Font = Enum.Font.SourceSansBold
        arrow.TextXAlignment = Enum.TextXAlignment.Right
        arrow.Parent = frame

        local checkbox = nil
        if optData.Type == "toggle" then
            checkbox = Instance.new("Frame")
            checkbox.Name = "Checkbox"
            checkbox.Size = UDim2.new(0, 16, 0, 16)
            checkbox.Position = UDim2.new(1, -30, 0.5, -8)
            checkbox.BackgroundColor3 = optData.Value and Config.Theme.Accent or Color3.fromRGB(40, 40, 40)
            checkbox.BorderSizePixel = 0
            checkbox.Parent = frame
            
            local checkStroke = Instance.new("UIStroke")
            checkStroke.Thickness = 1
            checkStroke.Color = Color3.fromRGB(80, 80, 80)
            checkStroke.Parent = checkbox
        end

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.4, 0, 1, 0)
        valueLabel.Position = UDim2.new(0.6, -30, 0, 0)
        valueLabel.BackgroundTransparency = 1
        
        if optData.Type == "slider" then
            valueLabel.Text = "< " .. tostring(optData.Value) .. " >"
        elseif optData.Type == "multichoice" then
            valueLabel.Text = "< " .. tostring(optData.Options[optData.Index] or "NONE") .. " >"
        elseif optData.Type == "keybind" then
            valueLabel.Text = (State.Binding == optData) and "[...]" or "[" .. (optData.Value and optData.Value.Name or "NONE") .. "]"
        elseif optData.Type == "input" then
            valueLabel.Text = tostring(optData.Value or "")
        else
            valueLabel.Text = optData.Type == "button" and (optData.ValueText or "") or ""
        end
        
        valueLabel.TextColor3 = Config.Theme.Text
        valueLabel.TextSize = Config.TextSize
        valueLabel.Font = Config.Font
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = frame

        optData.UI = {
            Frame = frame,
            Label = label,
            Arrow = arrow,
            ValueLabel = valueLabel,
            Checkbox = checkbox,
            Icon = iconImg
        }
    end

    BannerTitle.Text = menu.Title:upper()
    SubTitle.Text = menu.Subtitle
    updateSelection()
end

local function openMenu(menu, isBack)
    if not isBack and State.CurrentMenu then
        table.insert(State.History, State.CurrentMenu)
    end
    State.CurrentMenu = menu
    renderMenu(menu)
end

local function goBack()
    if #State.History > 0 then
        -- Trigger cleanup for the menu we are leaving
        if State.CurrentMenu.OnClose then
            State.CurrentMenu.OnClose()
        end
        
        local prev = table.remove(State.History)
        openMenu(prev, true)
    end
end

-- // INPUT HANDLING WITH CONTEXT ACTION SERVICE // --

local function handleMenuInput(name, state, input)
    if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        State.Visible = not State.Visible
        MainFrame.Visible = State.Visible
        
        -- If closing, trigger cleanup for the current menu
        if not State.Visible and State.CurrentMenu and State.CurrentMenu.OnClose then
            State.CurrentMenu.OnClose()
        end
        
        local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
        if State.Visible then
            if hum then
                oldws = hum.WalkSpeed
                hum.WalkSpeed = 0
            end
        else
            if hum then
                -- Check if any movement mods should be active
                if State.UpdateSprint then 
                    State.UpdateSprint() 
                else
                    hum.WalkSpeed = oldws or 16
                end
            end
        end
        return Enum.ContextActionResult.Sink
    end
    
    if not State.Visible then return Enum.ContextActionResult.Pass end
    
    local menu = State.CurrentMenu
    if not menu then return Enum.ContextActionResult.Pass end
    
    local combined = getCombinedOptions(menu)

    if input.KeyCode == Enum.KeyCode.Up then
        repeat
            menu.SelectedIndex = menu.SelectedIndex - 1
            if menu.SelectedIndex < 1 then menu.SelectedIndex = #combined end
        until combined[menu.SelectedIndex].Type ~= "label"
        
        updateSelection()
        return Enum.ContextActionResult.Sink
    elseif input.KeyCode == Enum.KeyCode.Down then
        repeat
            menu.SelectedIndex = menu.SelectedIndex + 1
            if menu.SelectedIndex > #combined then menu.SelectedIndex = 1 end
        until combined[menu.SelectedIndex].Type ~= "label"
        
        updateSelection()
        return Enum.ContextActionResult.Sink
    elseif input.KeyCode == Enum.KeyCode.Backspace then
        goBack()
        return Enum.ContextActionResult.Sink
    elseif input.KeyCode == Enum.KeyCode.Left then
        if state == Enum.UserInputState.Begin then
            local opt = combined[menu.SelectedIndex]
            if opt and opt.Type == "slider" then
                State.SliderHoldingLeft = true
                State.LastSlideTime = tick() + 0.3 -- Initial delay before repeat
                opt.Value = math.clamp(opt.Value - opt.Increment, opt.Min, opt.Max)
                opt.UI.ValueLabel.Text = "< " .. tostring(opt.Value) .. " >"
                opt.Callback(opt.Value)
            elseif opt and opt.Type == "multichoice" then
                opt.Index = opt.Index - 1
                if opt.Index < 1 then opt.Index = #opt.Options end
                opt.UI.ValueLabel.Text = "< " .. tostring(opt.Options[opt.Index]) .. " >"
                opt.Callback(opt.Options[opt.Index])
            end
        elseif state == Enum.UserInputState.End then
            State.SliderHoldingLeft = false
        end
        return Enum.ContextActionResult.Sink
    elseif input.KeyCode == Enum.KeyCode.Right then
        if state == Enum.UserInputState.Begin then
            local opt = combined[menu.SelectedIndex]
            if opt and opt.Type == "slider" then
                State.SliderHoldingRight = true
                State.LastSlideTime = tick() + 0.3
                opt.Value = math.clamp(opt.Value + opt.Increment, opt.Min, opt.Max)
                opt.UI.ValueLabel.Text = "< " .. tostring(opt.Value) .. " >"
                opt.Callback(opt.Value)
            elseif opt and opt.Type == "multichoice" then
                opt.Index = opt.Index + 1
                if opt.Index > #opt.Options then opt.Index = 1 end
                opt.UI.ValueLabel.Text = "< " .. tostring(opt.Options[opt.Index]) .. " >"
                opt.Callback(opt.Options[opt.Index])
            end
        elseif state == Enum.UserInputState.End then
            State.SliderHoldingRight = false
        end
        return Enum.ContextActionResult.Sink
    elseif input.KeyCode == Enum.KeyCode.Return then
        if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
        local opt = combined[menu.SelectedIndex]
        if opt.Type == "button" then
            opt.Callback()
        elseif opt.Type == "toggle" then
            opt.Value = not opt.Value
            if opt.UI.Checkbox then
                opt.UI.Checkbox.BackgroundColor3 = opt.Value and Config.Theme.Accent or Color3.fromRGB(40, 40, 40)
            end
            opt.Callback(opt.Value)
        elseif opt.Type == "menu" then
            openMenu(opt.SubMenu)
        elseif opt.Type == "input" then
            openInputPopup(opt)
        elseif opt.Type == "keybind" then
            State.Binding = opt
            opt.UI.ValueLabel.Text = "[...]"
        elseif opt.Type == "multichoice" then
            opt.Callback(opt.Options[opt.Index])
        end
        return Enum.ContextActionResult.Sink
    end
    
    return Enum.ContextActionResult.Pass
end

-- Bind menu controls
ContextActionService:BindAction("fracturecontrols", handleMenuInput, false, 
    Enum.KeyCode.Insert, 
    Enum.KeyCode.Up, 
    Enum.KeyCode.Down, 
    Enum.KeyCode.Left, 
    Enum.KeyCode.Right, 
    Enum.KeyCode.Return, 
    Enum.KeyCode.Backspace
)

-- // SAFETY RESET // --
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Right then
        State.SliderHoldingLeft = false
        State.SliderHoldingRight = false
    end
end)

-- // GLOBAL KEYBIND HANDLER // --
UserInputService.InputBegan:Connect(function(input, gpe)
    if State.Binding then
        -- Reserved keys that shouldn't be used as binds
        local reserved = {
            [Enum.KeyCode.Insert] = true,
            [Enum.KeyCode.Backspace] = true,
            [Enum.KeyCode.Return] = true,
            [Enum.KeyCode.Up] = true,
            [Enum.KeyCode.Down] = true,
            [Enum.KeyCode.Left] = true,
            [Enum.KeyCode.Right] = true,
        }
        
        if input.UserInputType == Enum.UserInputType.Keyboard and not reserved[input.KeyCode] then
            local opt = State.Binding
            opt.Value = input.KeyCode
            opt.UI.ValueLabel.Text = "[" .. input.KeyCode.Name .. "]"
            
            -- Sync to State.Config for built-ins
            if opt.Name == "Fly Keybind" then State.Config.Binds.Fly = input.KeyCode end
            if opt.Name == "Sprint Keybind" then State.Config.Binds.Sprint = input.KeyCode end
            
            State.Binding = nil
            UILibrary:Notify("Keybinds", "Bound " .. opt.Name .. " to " .. input.KeyCode.Name)
        end
        return
    end

    if gpe then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for _, bind in ipairs(State.Keybinds) do
            if bind.Value == input.KeyCode then
                bind.Callback()
            end
        end
    end
end)

-- // CONTINUOUS SLIDER INPUT & STATS // --
RunService.Heartbeat:Connect(function()
    if not State.Visible or not State.CurrentMenu then return end
    
    -- Update Stats Panel Live
    if StatsPanel.Visible and State.WatchingPlayer then
        local p = State.WatchingPlayer
        local char = p.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        local health = hum and math.floor(hum.Health) or 0
        local maxHealth = hum and math.floor(hum.MaxHealth) or 100
        local pos = root and root.Position or Vector3.zero
        local dist = root and (Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and math.floor((root.Position - Player.Character.HumanoidRootPart.Position).Magnitude) or 0) or 0
        
        local leaderstatsStr = ""
        local leaderstats = p:FindFirstChild("leaderstats")
        if leaderstats then
            for _, v in ipairs(leaderstats:GetChildren()) do
                if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") then
                    leaderstatsStr = leaderstatsStr .. string.format("\n<font color=\"#00f5ff\"><b>%s:</b></font> %s", v.Name:upper(), tostring(v.Value))
                end
            end
        end

        StatsInfo.Text = string.format([[
<font color="#00f5ff"><b>DISPLAY:</b></font> %s
<font color="#00f5ff"><b>USER:</b></font> @%s
<font color="#00f5ff"><b>HEALTH:</b></font> %d / %d
<font color="#00f5ff"><b>DISTANCE:</b></font> %d studs
<font color="#00f5ff"><b>POSITION:</b></font> %.1f, %.1f, %.1f%s]], 
            p.DisplayName, p.Name, health, maxHealth, dist, pos.X, pos.Y, pos.Z, leaderstatsStr)
    end
    
    if State.SliderHoldingLeft or State.SliderHoldingRight then
        if tick() > State.LastSlideTime then
            State.LastSlideTime = tick() + 0.05 -- Repeat interval
            local menu = State.CurrentMenu
            local combined = getCombinedOptions(menu)
            local opt = combined[menu.SelectedIndex]
            
            if opt and opt.Type == "slider" then
                local oldVal = opt.Value
                local dir = State.SliderHoldingLeft and -1 or 1
                opt.Value = math.clamp(opt.Value + (dir * opt.Increment), opt.Min, opt.Max)
                
                if opt.Value ~= oldVal then
                    opt.UI.ValueLabel.Text = "< " .. tostring(opt.Value) .. " >"
                    opt.Callback(opt.Value)
                end
            end
        end
    end
end)

-- // PUBLIC API // --

function UILibrary:Unload()
    local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = oldws or 16 end
    ContextActionService:UnbindAction("fracturecontrols")
    ScreenGui:Destroy()
end

function UILibrary:Notify(title, text, duration)
    local duration = duration or 5
    
    -- Outer frame for UIListLayout
    local NotifyFrame = Instance.new("Frame")
    NotifyFrame.Size = UDim2.new(1, 0, 0, 0)
    NotifyFrame.AutomaticSize = Enum.AutomaticSize.Y
    NotifyFrame.BackgroundTransparency = 1
    NotifyFrame.BorderSizePixel = 0
    NotifyFrame.Parent = NotifyContainer
    
    -- Inner frame for sliding animations
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(1, 0, 0, 0)
    Main.AutomaticSize = Enum.AutomaticSize.Y
    Main.Position = UDim2.new(1.2, 0, 0, 0)
    Main.BackgroundColor3 = Config.Theme.Background
    Main.BorderSizePixel = 0
    Main.Parent = NotifyFrame
    
    local NotifyPadding = Instance.new("UIPadding")
    NotifyPadding.PaddingBottom = UDim.new(0, 10)
    NotifyPadding.Parent = Main

    local NotifyCorner = Instance.new("UICorner")
    NotifyCorner.CornerRadius = Config.CornerRadius
    NotifyCorner.Parent = Main
    
    local NotifyStroke = Instance.new("UIStroke")
    NotifyStroke.Thickness = 1.5
    NotifyStroke.Color = Config.Theme.Accent
    NotifyStroke.Transparency = 0.5
    NotifyStroke.Parent = Main
    
    local NotifyTitle = Instance.new("TextLabel")
    NotifyTitle.Size = UDim2.new(1, -15, 0, 25)
    NotifyTitle.Position = UDim2.new(0, 10, 0, 5)
    NotifyTitle.BackgroundTransparency = 1
    NotifyTitle.Text = title:upper()
    NotifyTitle.TextColor3 = Config.Theme.Accent
    NotifyTitle.TextSize = 14
    NotifyTitle.Font = Config.TitleFont
    NotifyTitle.TextXAlignment = Enum.TextXAlignment.Left
    NotifyTitle.Parent = Main
    
    local NotifyBody = Instance.new("TextLabel")
    NotifyBody.Size = UDim2.new(1, -20, 0, 0)
    NotifyBody.Position = UDim2.new(0, 10, 0, 28)
    NotifyBody.AutomaticSize = Enum.AutomaticSize.Y
    NotifyBody.BackgroundTransparency = 1
    NotifyBody.Text = text
    NotifyBody.TextColor3 = Color3.fromRGB(200, 200, 200)
    NotifyBody.TextSize = 14
    NotifyBody.Font = Config.Font
    NotifyBody.TextXAlignment = Enum.TextXAlignment.Left
    NotifyBody.TextYAlignment = Enum.TextYAlignment.Top
    NotifyBody.TextWrapped = true
    NotifyBody.Parent = Main

    local TimerBar = Instance.new("Frame")
    TimerBar.Name = "TimerBar"
    TimerBar.Size = UDim2.new(1, 0, 0, 2)
    TimerBar.Position = UDim2.new(0, 0, 1, 8) -- Positioned relative to bottom after padding
    TimerBar.BackgroundColor3 = Config.Theme.Accent
    TimerBar.BorderSizePixel = 0
    TimerBar.Parent = Main
    
    local TimerCorner = Instance.new("UICorner")
    TimerCorner.CornerRadius = UDim.new(0, 2)
    TimerCorner.Parent = TimerBar
    
    -- Animations
    TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    TweenService:Create(TimerBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    }):Play()
    
    task.delay(duration, function()
        local out = TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(1.2, 0, 0, 0),
            BackgroundTransparency = 1
        })
        
        -- Fade out text and stroke too
        TweenService:Create(NotifyTitle, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(NotifyBody, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(NotifyStroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
        TweenService:Create(TimerBar, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        
        out:Play()
        out.Completed:Connect(function()
            NotifyFrame:Destroy()
        end)
    end)
end

-- // BUILT-IN FEATURES MODULES // --
local BuiltIn = {}

function BuiltIn.Local(lib)
    local LocalMenu = lib:AddMenu("Local", "Manage local player options", "player", true)
    
    -- Flight System
    LocalMenu:AddLabel("Flight")
    local fs = State.Config.Fly
    local FlyConnection
    
    local function stopFlight()
        fs.Active = false
        if FlyConnection then FlyConnection:Disconnect() end
        local char = Player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        end
    end
    
    local function startFlight()
        stopFlight()
        fs.Active = true
        FlyConnection = RunService.RenderStepped:Connect(function()
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local cam = workspace.CurrentCamera
            if not root or not fs.Master then stopFlight(); return end
            
            local moveDir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,1,0) end
            
            root.Velocity = Vector3.new(0,0,0)
            local targetRotation = CFrame.new(root.CFrame.Position, root.CFrame.Position + cam.CFrame.LookVector)
            if moveDir.Magnitude > 0 then
                root.CFrame = targetRotation + (moveDir.Unit * (fs.Speed / 10))
            else
                root.CFrame = targetRotation
            end
        end)
    end
    
    LocalMenu:AddToggle("Fly", "Master switch for flying", false, nil, function(v)
        fs.Master = v
        if not v then stopFlight() end
    end)
    
    LocalMenu:AddSlider("Fly Speed", "Adjust flight velocity", 20, 300, 100, 10, nil, function(v)
        fs.Speed = v
    end)
    
    LocalMenu:AddKeybind("Fly Keybind", "Toggle flight on/off", State.Config.Binds.Fly, nil, function()
        if not fs.Master then 
            UILibrary:Notify("Flight", "Turn on Flight Master first!")
            return 
        end
        if fs.Active then stopFlight(); UILibrary:Notify("Flight", "Flight Disabled")
        else startFlight(); UILibrary:Notify("Flight", "Flight Enabled") end
    end)

    -- Sprint System
    LocalMenu:AddLabel("Movement")
    local ss = State.Config.Sprint
    local function updateSprint()
        local char = Player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not hum then return end
        if ss.Master and ss.Active then hum.WalkSpeed = ss.Speed
        else hum.WalkSpeed = oldws or 16 end
    end
    
    LocalMenu:AddToggle("Sprint", "Master switch for sprinting", false, nil, function(v)
        ss.Master = v
        updateSprint()
    end)
    
    LocalMenu:AddSlider("Sprint Speed", "Adjust running velocity", 16, 200, 50, 2, nil, function(v)
        ss.Speed = v
        updateSprint()
    end)
    
    local SprintKeybind = LocalMenu:AddKeybind("Sprint Keybind", "Hold to sprint", State.Config.Binds.Sprint, nil, function() end)
    RunService.Heartbeat:Connect(function()
        if not ss.Master then return end
        local isPressed = UserInputService:IsKeyDown(SprintKeybind.Value or Enum.KeyCode.None)
        if isPressed ~= ss.Active then
            ss.Active = isPressed
            updateSprint()
        end
    end)
    
    State.UpdateSprint = updateSprint
    Player.CharacterAdded:Connect(function() task.wait(1); updateSprint() end)

    -- Extra Movement
    local ms = State.Config.Movement
    LocalMenu:AddToggle("Noclip", "Walk through walls", false, nil, function(v)
        ms.Noclip = v
        if v then
            _G.NoclipConn = RunService.Stepped:Connect(function()
                if Player.Character then
                    for _, p in ipairs(Player.Character:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
            UILibrary:Notify("Movement", "Noclip Enabled")
        else
            if _G.NoclipConn then _G.NoclipConn:Disconnect() end
            UILibrary:Notify("Movement", "Noclip Disabled")
        end
    end)
    
    LocalMenu:AddToggle("Infinite Jump", "Jump in mid-air", false, nil, function(v)
        ms.InfiniteJump = v
        if v then
            _G.InfJumpConn = UserInputService.JumpRequest:Connect(function()
                local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
            UILibrary:Notify("Movement", "Infinite Jump Enabled")
        else
            if _G.InfJumpConn then _G.InfJumpConn:Disconnect() end
            UILibrary:Notify("Movement", "Infinite Jump Disabled")
        end
    end)

    LocalMenu:AddLabel("Camera")
    LocalMenu:AddToggle("No Camera Collision", "Camera goes through walls", false, nil, function(v)
        ms.NoCameraCollision = v
        Player.DevCameraOcclusionMode = v and Enum.DevCameraOcclusionMode.Invisicam or Enum.DevCameraOcclusionMode.Zoom
        UILibrary:Notify("Movement", "Camera Collision " .. (v and "Disabled" or "Enabled"))
    end)
end

function BuiltIn.Players(lib)
    local PlayersMenu = lib:AddMenu("Players", "Manage players in the server", "players", true)
    
    local function refreshPlayers()
        for _, opt in ipairs(PlayersMenu._menuData.Options) do
            if opt.PlayerObj then table.remove(PlayersMenu._menuData.Options, table.find(PlayersMenu._menuData.Options, opt)) end
        end
        
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p == Player then continue end
            local pm = PlayersMenu:AddMenu(p.DisplayName .. " (@" .. p.Name .. ")", "View actions for " .. p.Name, nil)
            pm._menuData.PlayerObj = p
            
            pm:AddButton("Teleport", "Teleport to player", nil, function()
                local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                local target = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if root and target then root:PivotTo(target.CFrame * CFrame.new(0, 0, 3)) end
            end)
            
            pm:AddToggle("Spectate", "Watch this player", false, nil, function(v)
                local cam = workspace.CurrentCamera
                cam.CameraSubject = v and p.Character:FindFirstChild("Humanoid") or Player.Character:FindFirstChild("Humanoid")
            end)
        end
    end
    
    refreshPlayers()
    game.Players.PlayerAdded:Connect(refreshPlayers)
    game.Players.PlayerRemoving:Connect(refreshPlayers)
end

function BuiltIn.Protections(lib)
    local ProtectionsMenu = lib:AddMenu("Protections", "Security and anti-exploit", "shield", true)
    local ps = State.Config.Protections

    ProtectionsMenu:AddToggle("Anti-Fling", "Prevents flinging", false, nil, function(v)
        ps.AntiFling = v
        if v then
            _G.AntiFling = RunService.Stepped:Connect(function()
                if Player.Character then
                    for _, p in ipairs(Player.Character:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.CanTouch = false
                            if p.Velocity.Magnitude > 50 then p.Velocity = Vector3.new(0,0,0) end
                        end
                    end
                end
            end)
            UILibrary:Notify("Protections", "Anti-Fling Enabled")
        else
            if _G.AntiFling then _G.AntiFling:Disconnect() end
            UILibrary:Notify("Protections", "Anti-Fling Disabled")
        end
    end)
    
    ProtectionsMenu:AddToggle("Anti-AFK", "Prevents idle kick", false, nil, function(v)
        ps.AntiAFK = v
        if v then
            _G.AntiAFK = Player.Idled:Connect(function()
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
            end)
            UILibrary:Notify("Protections", "Anti-AFK Enabled")
        else
            if _G.AntiAFK then _G.AntiAFK:Disconnect() end
            UILibrary:Notify("Protections", "Anti-AFK Disabled")
        end
    end)
    
    ProtectionsMenu:AddLabel("Bypass")
    ProtectionsMenu:AddButton("Adonis Bypass", "Bypass Adonis Anti-Cheat", nil, function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/coder-isxt/roblox/refs/heads/main/V3/bypass.lua"))()
    end)
end

function BuiltIn.Settings(lib)
    local Settings = lib:AddMenu("Settings", "Menu configuration", "gear", true)
    local Developer = Settings:AddMenu("Developer", "Universal Developer tools", "globe")
    local Theme = Settings:AddMenu("Theme", "Customize the menu theme", nil)
    local ConfigSub = Settings:AddMenu("Config", "Save your settings", nil)

    -- Config Logic
    local SelectedConfigName = "default"
    ConfigSub:AddInput("Config Name", "Name of the file", "Config name...", nil, function(v)
        -- Sanitize filename: remove common illegal characters
        local sanitized = v:gsub('[\\/:*?"<>|]', "")
        sanitized = sanitized:gsub("%s+", "_") -- Replace spaces with underscores
        
        SelectedConfigName = sanitized ~= "" and sanitized or "default"
    end)
    
    ConfigSub:AddButton("Save Config", "Save your settings to file", nil, function()
        local http = game:GetService("HttpService")
        local success, err = pcall(function()
            if not isfolder("Fracture") then makefolder("Fracture") end
            if not isfolder("Fracture/Configs") then makefolder("Fracture/Configs") end
            
            -- Dynamic Menu State Gathering (System Only)
            local menuStates = {}
            for _, menu in ipairs(State.AllMenus) do
                if menu.IsSystem then
                    local menuKey = menu.Subtitle or menu.Title
                    local states = {}
                    for _, opt in ipairs(menu.Options) do
                        if opt.Type == "toggle" then
                            states[opt.Name] = opt.Value
                        elseif opt.Type == "slider" then
                            states[opt.Name] = opt.Value
                        elseif opt.Type == "keybind" then
                            states[opt.Name] = serializeValue(opt.Value)
                        elseif opt.Type == "multichoice" then
                            states[opt.Name] = opt.Index
                        end
                    end
                    if next(states) then
                        menuStates[menuKey] = states
                    end
                end
            end

            local saveTable = {
                State = State.Config,
                MenuSide = Config.Side,
                MenuStates = menuStates
            }
            
            writefile("Fracture/Configs/" .. SelectedConfigName .. ".json", http:JSONEncode(saveTable))
        end)
        
        if success then
            UILibrary:Notify("Config", "Saved config: " .. SelectedConfigName)
        else
            UILibrary:Notify("Config", "Failed to save: " .. tostring(err))
        end
    end)

    ConfigSub:AddLabel("Configs")
    
    local function refreshConfigs()
        local http = game:GetService("HttpService")
        -- Clear everything after the "Configs" label
        local labelIdx = 0
        for i, opt in ipairs(ConfigSub._menuData.Options) do
            if opt.Name == "Configs" and opt.Type == "label" then
                labelIdx = i
                break
            end
        end
        
        if labelIdx > 0 then
            for i = #ConfigSub._menuData.Options, labelIdx + 1, -1 do
                table.remove(ConfigSub._menuData.Options, i)
            end
        end

        if not isfolder("Fracture/Configs") then return end
        
        local autoLoadFile = ""
        if isfile("Fracture/autoload.json") then
            local success, content = pcall(readfile, "Fracture/autoload.json")
            if success then
                autoLoadFile = content:gsub('"', "")
            end
        end

        for _, file in ipairs(listfiles("Fracture/Configs")) do
            local name = file:match("([^/\\]+)%.json$")
            if not name then continue end
            
            local cfgSub = ConfigSub:AddMenu(name, "Manage " .. name .. " configuration")
            
            cfgSub:AddButton("Load", "Apply these settings now", nil, function()
                local data = http:JSONDecode(readfile(file))
                if data and data.State then
                    -- Deep merge state
                    for k, v in pairs(data.State) do
                        if type(v) == "table" then
                            for k2, v2 in pairs(v) do
                                State.Config[k][k2] = deserializeValue(v2)
                            end
                        else
                            State.Config[k] = v
                        end
                    end
                    
                    -- Apply Theme Preset
                    if State.Config.SelectedPreset then
                        for _, opt in ipairs(Theme._menuData.Options) do
                            if opt.Name == "Presets" then
                                for _, preset in ipairs(opt.SubMenu.Options) do
                                    if preset.Name == State.Config.SelectedPreset then
                                        preset.Callback()
                                    end
                                end
                            end
                        end
                    end
                    
                    updateBannerUI()
                    UILibrary:Notify("Config", "Loaded: " .. name)
                end
            end)
            
            cfgSub:AddInput("Rename", "Change filename", name, nil, function(new)
                local sanitized = new:gsub('[\\/:*?"<>|]', ""):gsub("%s+", "_")
                if sanitized ~= "" and sanitized ~= name then
                    writefile("Fracture/Configs/" .. sanitized .. ".json", readfile(file))
                    delfile(file)
                    if autoLoadFile == name then writefile("Fracture/autoload.json", http:JSONEncode(sanitized)) end
                    refreshConfigs()
                end
            end)
            
            cfgSub:AddButton("Remove", "Delete this file permanently", nil, function()
                delfile(file)
                if autoLoadFile == name then delfile("Fracture/autoload.json") end
                refreshConfigs()
                goBack()
            end)
            
            cfgSub:AddToggle("Load on Startup", "Automatically load this config", (name == autoLoadFile), nil, function(v)
                if v then
                    writefile("Fracture/autoload.json", http:JSONEncode(name))
                else
                    if isfile("Fracture/autoload.json") then
                        local current = readfile("Fracture/autoload.json"):gsub('"', "")
                        if current == name then delfile("Fracture/autoload.json") end
                    end
                end
                refreshConfigs() -- Refresh to update other toggles
            end)
        end
        
        -- If we are currently in the ConfigSub menu, we need to re-render it to show new configs
        if State.CurrentMenu == ConfigSub._menuData then
            renderMenu(ConfigSub._menuData)
        end
    end

    -- Initial load
    task.spawn(refreshConfigs)
    
    -- Update Save button to refresh list
    local originalSave = ConfigSub._menuData.Options[2].Callback
    ConfigSub._menuData.Options[2].Callback = function()
        originalSave()
        refreshConfigs()
    end



    local Presets = Theme:AddMenu("Presets", "Theme presets", nil)
    
    Presets:AddButton("Default", "Standard premium look", nil, function()
        State.Config.SelectedPreset = "Default"
        applyTheme({
            Banner = Color3.fromRGB(8, 8, 12),            -- deep dark purple-black
            PulseColor = Color3.fromRGB(166, 77, 255),    -- neon fracture purple
            SubHeader = Color3.fromRGB(18, 18, 26),       -- darker panel purple tint
            Background = Color3.fromRGB(12, 12, 18),      -- main background
            Selected = Color3.fromRGB(190, 120, 255),     -- bright selected glow
            Text = Color3.fromRGB(245, 245, 255),         -- soft white
            TextSelected = Color3.fromRGB(10, 10, 10),    -- dark text on purple
            Accent = Color3.fromRGB(140, 60, 255),        -- primary accent purple
        })
        State.Config.Banner.UseBanner = true
        State.Config.Banner.CurrentID = "81459253942868"
        State.Config.Banner.DisableTitle = true
        updateBannerUI()
        UILibrary:Notify("Presets", "Default theme applied")
    end)
    
    Presets:AddButton("Impulse", "Classic minimalist look", nil, function()
        State.Config.SelectedPreset = "Impulse"
        applyTheme({
            Banner = Color3.fromRGB(10, 10, 10),
            PulseColor = Color3.fromRGB(0, 245, 255),
            SubHeader = Color3.fromRGB(20, 20, 20),
            Background = Color3.fromRGB(15, 15, 15),
            Selected = Color3.fromRGB(0, 245, 255),
            Text = Color3.fromRGB(255, 255, 255),
            TextSelected = Color3.fromRGB(0, 0, 0),
            Accent = Color3.fromRGB(0, 245, 255),
        })
        State.Config.Banner.UseBanner = false
        State.Config.Banner.DisableTitle = false
        updateBannerUI()
        SubTitle.Visible = true
        UILibrary:Notify("Presets", "Impulse theme applied")
    end)
    
    Settings:AddSlider("Menu Side", "Dock side", 1, 2, Config.Side, 1, nil, function(v)
        Config.Side = v
        updateMenuPosition()
    end)
    
    Settings:AddToggle("FPS Boost", "Optimize graphics", false, nil, function(v)
        local l = game:GetService("Lighting")
        l.GlobalShadows = not v
        settings().Rendering.QualityLevel = v and 1 or 10
        UILibrary:Notify("Settings", "FPS Boost " .. (v and "Enabled" or "Disabled"))
    end)
    
    Settings:AddLabel("Other")
    Settings:AddButton("Unload", "Close menu", nil, function() lib:Unload() end)
    
    Theme:AddToggle("Use Banner", "Show the image in the header", true, nil, function(v)
        State.Config.Banner.UseBanner = v
        updateBannerUI()
    end)

    Theme:AddInput("Banner Image", "Paste a Roblox Image ID", "Texture id...", nil, function(v)
        State.Config.Banner.CurrentID = v:gsub("%D", "")
        updateBannerUI()
    end)

    Theme:AddMultiChoice("Banner Scale", "How the image fits the header", {"Crop", "Fit", "Stretch", "Tile"}, 1, nil, function(v)
        State.Config.Banner.Scale = v
        BannerTexture.ScaleType = Enum.ScaleType[v]
    end)

    Theme:AddToggle("Disable Title", "Hide the text in the banner", false, nil, function(v)
        State.Config.Banner.DisableTitle = v
        updateBannerUI()
    end)

    Developer:AddButton("DarkDex", "Load explorer", nil, function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Dex-with-tags-78265"))()
    end)
    
    Developer:AddButton("RemoteSpy", "Load remotespy to see remotes firing", nil, function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"))()
    end)
end

function UILibrary:CreateWindow(title, subtitle)
    State.CurrentMenu = createMenuData(title, subtitle)

    -- Load Built-ins
    BuiltIn.Local(self)
    BuiltIn.Players(self)
    BuiltIn.Protections(self)
    BuiltIn.Settings(self)

    -- Startup Auto-load
    task.spawn(function()
        if isfolder("Fracture/Configs") and isfile("Fracture/autoload.json") then
            local http = game:GetService("HttpService")
            local name = readfile("Fracture/autoload.json"):gsub('"', "")
            local path = "Fracture/Configs/" .. name .. ".json"
            
            if isfile(path) then
                local data = http:JSONDecode(readfile(path))
                if data and data.State then
                    -- Apply loaded state
                    for k, v in pairs(data.State) do
                        if type(v) == "table" then
                            for k2, v2 in pairs(v) do
                                State.Config[k][k2] = deserializeValue(v2)
                            end
                        else
                            State.Config[k] = v
                        end
                    end
                    -- Wait for UI to be ready then apply theme
                    task.wait(0.1)
                    updateBannerUI()
                    UILibrary:Notify("Fracture", "Auto-loaded config: " .. name)
                end
            end
        end
    end)

    renderMenu(State.CurrentMenu)
    updateMenuPosition()
    return self
end

function UILibrary:AddButton(name, desc, icon, callback)
    if type(icon) == "function" then callback = icon; icon = nil end
    table.insert(State.CurrentMenu.Options, {
        Name = name,
        Description = desc,
        Icon = icon,
        Type = "button",
        Callback = callback
    })
    renderMenu(State.CurrentMenu)
end

function UILibrary:AddToggle(name, desc, default, icon, callback)
    if type(icon) == "function" then callback = icon; icon = nil end
    table.insert(State.CurrentMenu.Options, {
        Name = name,
        Description = desc,
        Icon = icon,
        Type = "toggle",
        Value = default or false,
        ValueText = (default or false) and "[ON]" or "[OFF]",
        Callback = callback
    })
    renderMenu(State.CurrentMenu)
end

function UILibrary:AddMenu(name, desc, icon, isSystem)
    local subMenu = createMenuData(State.CurrentMenu.Title, name)
    local targetTable = isSystem and State.CurrentMenu.SystemOptions or State.CurrentMenu.Options
    
    table.insert(targetTable, {
        Name = name,
        Description = desc,
        Icon = icon,
        Type = "menu",
        SubMenu = subMenu
    })
    
    renderMenu(State.CurrentMenu)
    return UILibrary._wrapMenu(subMenu)
end

function UILibrary:AddSlider(name, desc, min, max, default, increment, icon, callback)
    if type(icon) == "function" then callback = icon; icon = nil end
    table.insert(State.CurrentMenu.Options, {
        Name = name,
        Description = desc,
        Icon = icon,
        Type = "slider",
        Min = min or 0,
        Max = max or 100,
        Value = default or min or 0,
        Increment = increment or 1,
        Callback = callback
    })
    renderMenu(State.CurrentMenu)
end

function UILibrary:AddInput(name, desc, placeholder, icon, callback)
    if type(icon) == "function" then callback = icon; icon = nil end
    table.insert(State.CurrentMenu.Options, {
        Name = name,
        Description = desc,
        Icon = icon,
        Type = "input",
        Placeholder = placeholder or "Enter Value",
        Value = "",
        Callback = callback
    })
    renderMenu(State.CurrentMenu)
end

function UILibrary:AddKeybind(name, desc, default, icon, callback)
    if type(icon) == "function" then callback = icon; icon = nil end
    local bind = {
        Name = name,
        Description = desc,
        Icon = icon,
        Type = "keybind",
        Value = default or Enum.KeyCode.None,
        Callback = callback
    }
    table.insert(State.CurrentMenu.Options, bind)
    table.insert(State.Keybinds, bind)
    renderMenu(State.CurrentMenu)
    return bind
end

-- Helper to wrap menu data into an API object
function UILibrary._wrapMenu(menuData)
    local api = {}
    function api:AddButton(name, desc, icon, callback)
        if type(icon) == "function" then callback = icon; icon = nil end
        table.insert(menuData.Options, {Name = name, Description = desc, Icon = icon, Type = "button", Callback = callback})
        if State.CurrentMenu == menuData then renderMenu(menuData) end
    end
    function api:AddToggle(name, desc, default, icon, callback)
        if type(icon) == "function" then callback = icon; icon = nil end
        table.insert(menuData.Options, {Name = name, Description = desc, Icon = icon, Type = "toggle", Value = default, ValueText = default and "[ON]" or "[OFF]", Callback = callback})
        if State.CurrentMenu == menuData then renderMenu(menuData) end
    end
    function api:AddSlider(name, desc, min, max, default, inc, icon, callback)
        if type(icon) == "function" then callback = icon; icon = nil end
        local slider = {
            Name = name,
            Description = desc,
            Icon = icon,
            Type = "slider",
            Min = min,
            Max = max,
            Value = default or min,
            Increment = inc or 1,
            Callback = callback
        }
        table.insert(menuData.Options, slider)
        if State.CurrentMenu == menuData then renderMenu(menuData) end
    end

    function api:AddMultiChoice(name, desc, options, defaultIndex, icon, callback)
        if type(icon) == "function" then callback = icon; icon = nil end
        local choice = {
            Name = name,
            Description = desc,
            Icon = icon,
            Type = "multichoice",
            Options = options,
            Index = defaultIndex or 1,
            Callback = callback
        }
        table.insert(menuData.Options, choice)
        if State.CurrentMenu == menuData then renderMenu(menuData) end
    end
    function api:AddInput(name, desc, placeholder, icon, callback)
        if type(icon) == "function" then callback = icon; icon = nil end
        table.insert(menuData.Options, {
            Name = name,
            Description = desc,
            Icon = icon,
            Type = "input",
            Placeholder = placeholder or "Enter Value",
            Value = "",
            Callback = callback
        })
        if State.CurrentMenu == menuData then renderMenu(menuData) end
    end
    function api:AddKeybind(name, desc, default, icon, callback)
        if type(icon) == "function" then callback = icon; icon = nil end
        local bind = {
            Name = name,
            Description = desc,
            Icon = icon,
            Type = "keybind",
            Value = default or Enum.KeyCode.None,
            Callback = callback
        }
        table.insert(menuData.Options, bind)
        table.insert(State.Keybinds, bind)
        if State.CurrentMenu == menuData then renderMenu(menuData) end
        return bind
    end
    function api:AddLabel(text)
        table.insert(menuData.Options, {Name = text, Type = "label"})
        if State.CurrentMenu == menuData then renderMenu(menuData) end
    end
    function api:AddMenu(name, desc, icon, isSystem)
        local sub = createMenuData(menuData.Title, name)
        sub.IsSystem = isSystem or menuData.IsSystem -- Inherit system status
        local opt = {Name = name, Description = desc, Icon = icon, Type = "menu", SubMenu = sub}
        
        if sub.IsSystem then
            table.insert(menuData.SystemOptions, opt)
        else
            table.insert(menuData.Options, opt)
        end
        
        if State.CurrentMenu == menuData then renderMenu(menuData) end
        return UILibrary._wrapMenu(sub)
    end
    -- Export the raw data so we can attach custom fields (like PlayerObj)
    api._menuData = menuData
    
    function api:Clear()
        table.clear(menuData.Options)
        if State.CurrentMenu == menuData then renderMenu(menuData) end
    end
    return api
end

return UILibrary
