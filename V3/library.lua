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
}

-- // STATE // --
local State = {
    Visible = false,
    History = {},
    CurrentMenu = nil,
    SliderHoldingLeft = false,
    SliderHoldingRight = false,
    LastSlideTime = 0,
}

local function createMenuData(title, subtitle)
    return {
        Title = title,
        Subtitle = subtitle,
        Options = {},
        SystemOptions = {}, -- Built-ins go here
        SelectedIndex = 1
    }
end

-- // CREATE SCREEN GUI // --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GTANativeMenu"
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
PulseLine.Parent = Banner

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
LogoImage.Image = "rbxassetid://90406832214310"
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

-- // INTERNAL FUNCTIONS // --
local function getCombinedOptions(menu)
    local combined = {}
    for _, v in ipairs(menu.Options) do table.insert(combined, v) end
    for _, v in ipairs(menu.SystemOptions) do table.insert(combined, v) end
    return combined
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
            TweenService:Create(frame, TweenInfo.new(0.1), {
                BackgroundColor3 = isSelected and Config.Theme.Selected or Color3.fromRGB(0,0,0),
                BackgroundTransparency = isSelected and 0 or 1
            }):Play()

            optData.UI.Label.TextColor3 = isSelected and Config.Theme.TextSelected or Config.Theme.Text
            optData.UI.ValueLabel.TextColor3 = isSelected and Config.Theme.TextSelected or Config.Theme.Text
            optData.UI.Arrow.TextColor3 = isSelected and Config.Theme.TextSelected or Color3.fromRGB(150, 150, 150)
            
            if optData.UI.Checkbox then
                if isSelected then
                    optData.UI.Checkbox.BackgroundColor3 = optData.Value and Color3.new(0,0,0) or Color3.fromRGB(40, 40, 40)
                else
                    optData.UI.Checkbox.BackgroundColor3 = optData.Value and Config.Theme.Accent or Color3.fromRGB(40, 40, 40)
                end
            end
            
            if isSelected then
                DescText.Text = optData.Description or ""
            end
        end
    end

    ItemCount.Text = menu.SelectedIndex .. " / " .. count
    updateMainFrameSize()
end

local function openInputPopup(optData)
    InputPopup.Visible = true
    InputPlaceholder.Text = optData.Placeholder or "Enter Value"
    InputBox.Text = tostring(optData.Value or "")
    InputBox:CaptureFocus()
    
    local connection
    connection = InputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            optData.Value = InputBox.Text
            optData.UI.ValueLabel.Text = optData.Value
            optData.Callback(optData.Value)
        end
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
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = optData.Name
        label.TextColor3 = Config.Theme.Text
        label.TextSize = Config.TextSize
        label.Font = Config.Font
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

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
            Checkbox = checkbox
        }
    end

    BannerTitle.Text = menu.Title:upper()
    SubTitle.Text = menu.Subtitle
    updateSelection()
end

local function openMenu(menu)
    if State.CurrentMenu then
        table.insert(State.History, State.CurrentMenu)
    end
    State.CurrentMenu = menu
    renderMenu(menu)
end

local function goBack()
    if #State.History > 0 then
        State.CurrentMenu = table.remove(State.History)
        renderMenu(State.CurrentMenu)
    end
end

-- // INPUT HANDLING WITH CONTEXT ACTION SERVICE // --

local function handleMenuInput(name, state, input)
    if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
        State.Visible = not State.Visible
        MainFrame.Visible = State.Visible
        
        if State.Visible then
            if hum then
                oldws = hum.WalkSpeed
                hum.WalkSpeed = 0
            end
        else
            if hum then
                hum.WalkSpeed = oldws or 16
            end
        end
        return Enum.ContextActionResult.Sink
    end
    
    if not State.Visible then return Enum.ContextActionResult.Pass end
    
    local menu = State.CurrentMenu
    if not menu then return Enum.ContextActionResult.Pass end
    
    local combined = getCombinedOptions(menu)

    if input.KeyCode == Enum.KeyCode.Up then
        menu.SelectedIndex = menu.SelectedIndex - 1
        if menu.SelectedIndex < 1 then menu.SelectedIndex = #combined end
        updateSelection()
        return Enum.ContextActionResult.Sink
    elseif input.KeyCode == Enum.KeyCode.Down then
        menu.SelectedIndex = menu.SelectedIndex + 1
        if menu.SelectedIndex > #combined then menu.SelectedIndex = 1 end
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

-- // CONTINUOUS SLIDER INPUT // --
RunService.Heartbeat:Connect(function()
    if not State.Visible or not State.CurrentMenu then return end
    
    if State.SliderHoldingLeft or State.SliderHoldingRight then
        if tick() > State.LastSlideTime then
            State.LastSlideTime = tick() + 0.05 -- Repeat interval
            local menu = State.CurrentMenu
            local combined = getCombinedOptions(menu)
            local opt = combined[menu.SelectedIndex]
            
            if opt and opt.Type == "slider" then
                local dir = State.SliderHoldingLeft and -1 or 1
                opt.Value = math.clamp(opt.Value + (dir * opt.Increment), opt.Min, opt.Max)
                opt.UI.ValueLabel.Text = "< " .. tostring(opt.Value) .. " >"
                opt.Callback(opt.Value)
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

function UILibrary:CreateWindow(title, subtitle)
    State.CurrentMenu = createMenuData(title, subtitle)
    
    -- Add Built-in Settings Menu to SystemOptions (Always at bottom)
    local Settings = self:AddMenu("Settings", "Menu configuration and exit", true)
    local Developer = Settings:AddMenu("Developer", "Universal developer tools")
    Settings:AddButton("Unload", "Completely remove the menu and clean up", function()
        self:Unload()
    end)

    Developer:AddButton("DarkDex", "Load darkdex explorer", function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Dex-with-tags-78265"))()
    end)

    Developer:AddButton("RemoteSpy", "Load remotespy to see remotes firing", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"))()
    end)
    
    renderMenu(State.CurrentMenu)
    return self
end

function UILibrary:AddButton(name, desc, callback)
    table.insert(State.CurrentMenu.Options, {
        Name = name,
        Description = desc,
        Type = "button",
        Callback = callback
    })
    renderMenu(State.CurrentMenu)
end

function UILibrary:AddToggle(name, desc, default, callback)
    table.insert(State.CurrentMenu.Options, {
        Name = name,
        Description = desc,
        Type = "toggle",
        Value = default or false,
        ValueText = (default or false) and "[ON]" or "[OFF]",
        Callback = callback
    })
    renderMenu(State.CurrentMenu)
end

function UILibrary:AddMenu(name, desc, isSystem)
    local subMenu = createMenuData(State.CurrentMenu.Title, name)
    local targetTable = isSystem and State.CurrentMenu.SystemOptions or State.CurrentMenu.Options
    
    table.insert(targetTable, {
        Name = name,
        Description = desc,
        Type = "menu",
        SubMenu = subMenu
    })
    
    renderMenu(State.CurrentMenu)
    return UILibrary._wrapMenu(subMenu)
end

function UILibrary:AddSlider(name, desc, min, max, default, increment, callback)
    table.insert(State.CurrentMenu.Options, {
        Name = name,
        Description = desc,
        Type = "slider",
        Min = min or 0,
        Max = max or 100,
        Value = default or min or 0,
        Increment = increment or 1,
        Callback = callback
    })
    renderMenu(State.CurrentMenu)
end

function UILibrary:AddInput(name, desc, placeholder, callback)
    table.insert(State.CurrentMenu.Options, {
        Name = name,
        Description = desc,
        Type = "input",
        Placeholder = placeholder or "Enter Value",
        Value = "",
        Callback = callback
    })
    renderMenu(State.CurrentMenu)
end

-- Helper to wrap menu data into an API object
function UILibrary._wrapMenu(menuData)
    local api = {}
    function api:AddButton(name, desc, callback)
        table.insert(menuData.Options, {Name = name, Description = desc, Type = "button", Callback = callback})
        if State.CurrentMenu == menuData then renderMenu(menuData) end
    end
    function api:AddToggle(name, desc, default, callback)
        table.insert(menuData.Options, {Name = name, Description = desc, Type = "toggle", Value = default, ValueText = default and "[ON]" or "[OFF]", Callback = callback})
        if State.CurrentMenu == menuData then renderMenu(menuData) end
    end
    function api:AddSlider(name, desc, min, max, default, increment, callback)
        table.insert(menuData.Options, {
            Name = name,
            Description = desc,
            Type = "slider",
            Min = min or 0,
            Max = max or 100,
            Value = default or min or 0,
            Increment = increment or 1,
            Callback = callback
        })
        if State.CurrentMenu == menuData then renderMenu(menuData) end
    end
    function api:AddInput(name, desc, placeholder, callback)
        table.insert(menuData.Options, {
            Name = name,
            Description = desc,
            Type = "input",
            Placeholder = placeholder or "Enter Value",
            Value = "",
            Callback = callback
        })
        if State.CurrentMenu == menuData then renderMenu(menuData) end
    end
    function api:AddMenu(name, desc)
        local sub = createMenuData(menuData.Title, name)
        table.insert(menuData.Options, {Name = name, Description = desc, Type = "menu", SubMenu = sub})
        if State.CurrentMenu == menuData then renderMenu(menuData) end
        return UILibrary._wrapMenu(sub)
    end
    return api
end

function UILibrary:Notify(title, text, duration)
    local duration = duration or 5
    
    local NotifyFrame = Instance.new("Frame")
    NotifyFrame.Size = UDim2.new(1, 0, 0, 60)
    NotifyFrame.BackgroundColor3 = Config.Theme.Background
    NotifyFrame.BorderSizePixel = 0
    NotifyFrame.Position = UDim2.new(1.5, 0, 0, 0)
    NotifyFrame.ClipsDescendants = true
    NotifyFrame.Parent = NotifyContainer
    
    local NotifyCorner = Instance.new("UICorner")
    NotifyCorner.CornerRadius = Config.CornerRadius
    NotifyCorner.Parent = NotifyFrame
    
    local NotifyStroke = Instance.new("UIStroke")
    NotifyStroke.Thickness = 1.5
    NotifyStroke.Color = Config.Theme.Accent
    NotifyStroke.Transparency = 0.5
    NotifyStroke.Parent = NotifyFrame
    
    local NotifyTitle = Instance.new("TextLabel")
    NotifyTitle.Size = UDim2.new(1, -15, 0, 25)
    NotifyTitle.Position = UDim2.new(0, 10, 0, 5)
    NotifyTitle.BackgroundTransparency = 1
    NotifyTitle.Text = title:upper()
    NotifyTitle.TextColor3 = Config.Theme.Accent
    NotifyTitle.TextSize = 14
    NotifyTitle.Font = Config.TitleFont
    NotifyTitle.TextXAlignment = Enum.TextXAlignment.Left
    NotifyTitle.Parent = NotifyFrame
    
    local NotifyBody = Instance.new("TextLabel")
    NotifyBody.Size = UDim2.new(1, -15, 1, -30)
    NotifyBody.Position = UDim2.new(0, 10, 0, 25)
    NotifyBody.BackgroundTransparency = 1
    NotifyBody.Text = text
    NotifyBody.TextColor3 = Color3.fromRGB(200, 200, 200)
    NotifyBody.TextSize = 14
    NotifyBody.Font = Config.Font
    NotifyBody.TextXAlignment = Enum.TextXAlignment.Left
    NotifyBody.TextYAlignment = Enum.TextYAlignment.Top
    NotifyBody.TextWrapped = true
    NotifyBody.Parent = NotifyFrame

    local TimerBar = Instance.new("Frame")
    TimerBar.Name = "TimerBar"
    TimerBar.Size = UDim2.new(1, 0, 0, 2)
    TimerBar.Position = UDim2.new(0, 0, 1, -2)
    TimerBar.BackgroundColor3 = Config.Theme.Accent
    TimerBar.BorderSizePixel = 0
    TimerBar.Parent = NotifyFrame
    
    local TimerCorner = Instance.new("UICorner")
    TimerCorner.CornerRadius = UDim.new(0, 2)
    TimerCorner.Parent = TimerBar
    
    -- Animations
    TweenService:Create(NotifyFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    TweenService:Create(TimerBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    }):Play()
    
    task.delay(duration, function()
        local out = TweenService:Create(NotifyFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(1.5, 0, 0, 0),
            BackgroundTransparency = 1
        })
        out:Play()
        out.Completed:Connect(function()
            NotifyFrame:Destroy()
        end)
    end)
end

return UILibrary
