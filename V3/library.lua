-- // GTA 5 STYLE MODMENU UI LIBRARY // --
-- // Navigation: Arrow Keys | Select: Enter | Toggle: Insert // --

local UILibrary = {}
UILibrary.__index = UILibrary

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local Player = Players.LocalPlayer

-- // CONFIGURATION // --
local Config = {
    Theme = {
        Banner = Color3.fromRGB(22, 100, 180), -- Classic Blue Banner
        SubHeader = Color3.fromRGB(0, 0, 0),
        Background = Color3.fromRGB(0, 0, 0), -- Transparent Black
        Selected = Color3.fromRGB(255, 255, 255), -- White highlight
        Text = Color3.fromRGB(255, 255, 255),
        TextSelected = Color3.fromRGB(0, 0, 0), -- Inverted text
        Accent = Color3.fromRGB(22, 100, 180),
    },
    Font = Enum.Font.RobotoMono, -- Closest to GTA sans-serif
    TextSize = 18,
    MenuWidth = 300,
    MaxItemsVisible = 10,
}

-- // STATE // --
local State = {
    Visible = false,
    SelectedIndex = 1,
    Options = {},
}

-- // CREATE SCREEN GUI // --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GTANativeMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui") or Player:WaitForChild("PlayerGui")

-- // MAIN CONTAINER // --
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, Config.MenuWidth, 0, 0)
MainFrame.Position = UDim2.new(0, 50, 0, 50)
MainFrame.BackgroundTransparency = 1
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

-- // HEADER (BANNER) // --
local Banner = Instance.new("Frame")
Banner.Name = "Banner"
Banner.Size = UDim2.new(1, 0, 0, 80)
Banner.BackgroundColor3 = Config.Theme.Banner
Banner.BorderSizePixel = 0
Banner.Parent = MainFrame

local BannerTitle = Instance.new("TextLabel")
BannerTitle.Size = UDim2.new(1, 0, 1, 0)
BannerTitle.BackgroundTransparency = 1
BannerTitle.Text = "GTA V MENU"
BannerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
BannerTitle.TextSize = 35
BannerTitle.Font = Enum.Font.GothamBold
BannerTitle.Parent = Banner

-- // SUB-HEADER (ITEM COUNT) // --
local SubHeader = Instance.new("Frame")
SubHeader.Name = "SubHeader"
SubHeader.Size = UDim2.new(1, 0, 0, 30)
SubHeader.Position = UDim2.new(0, 0, 0, 80)
SubHeader.BackgroundColor3 = Config.Theme.SubHeader
SubHeader.BorderSizePixel = 0
SubHeader.Parent = MainFrame

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(0.6, 0, 1, 0)
SubTitle.Position = UDim2.new(0, 10, 0, 0)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "HOME"
SubTitle.TextColor3 = Config.Theme.Accent
SubTitle.TextSize = 16
SubTitle.Font = Config.Font
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = SubHeader

local ItemCount = Instance.new("TextLabel")
ItemCount.Size = UDim2.new(0.35, 0, 1, 0)
ItemCount.Position = UDim2.new(0.6, 0, 0, 0)
ItemCount.BackgroundTransparency = 1
ItemCount.Text = "0 / 0"
ItemCount.TextColor3 = Config.Theme.Accent
ItemCount.TextSize = 16
ItemCount.Font = Config.Font
ItemCount.TextXAlignment = Enum.TextXAlignment.Right
ItemCount.Parent = SubHeader

-- // OPTIONS CONTAINER // --
local OptionsContainer = Instance.new("Frame")
OptionsContainer.Name = "Options"
OptionsContainer.Size = UDim2.new(1, 0, 0, 0)
OptionsContainer.Position = UDim2.new(0, 0, 0, 110)
OptionsContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
OptionsContainer.BackgroundTransparency = 0.2
OptionsContainer.BorderSizePixel = 0
OptionsContainer.ClipsDescendants = true
OptionsContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = OptionsContainer

-- // DESCRIPTION BOX // --
local DescFrame = Instance.new("Frame")
DescFrame.Name = "Description"
DescFrame.Size = UDim2.new(1, 0, 0, 40)
DescFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DescFrame.BackgroundTransparency = 0.2
DescFrame.BorderSizePixel = 0
DescFrame.Parent = MainFrame

local DescText = Instance.new("TextLabel")
DescText.Size = UDim2.new(1, -20, 1, 0)
DescText.Position = UDim2.new(0, 10, 0, 0)
DescText.BackgroundTransparency = 1
DescText.Text = "Menu Description Here"
DescText.TextColor3 = Color3.fromRGB(255, 255, 255)
DescText.TextSize = 14
DescText.Font = Config.Font
DescText.TextWrapped = true
DescText.TextXAlignment = Enum.TextXAlignment.Left
DescText.Parent = DescFrame

-- // INTERNAL FUNCTIONS // --

local function updateMainFrameSize()
    local optionsHeight = #State.Options * 35
    local totalHeight = 80 + 30 + optionsHeight + 40 -- Banner + SubHeader + Options + Desc
    MainFrame.Size = UDim2.new(0, Config.MenuWidth, 0, totalHeight)
    OptionsContainer.Size = UDim2.new(1, 0, 0, optionsHeight)
    DescFrame.Position = UDim2.new(0, 0, 0, 110 + optionsHeight + 5)
end

local function updateSelection()
    for i, option in ipairs(State.Options) do
        local isSelected = (i == State.SelectedIndex)
        
        -- Smooth color transition
        TweenService:Create(option.Frame, TweenInfo.new(0.1), {
            BackgroundColor3 = isSelected and Config.Theme.Selected or Color3.fromRGB(0,0,0),
            BackgroundTransparency = isSelected and 0 or 1
        }):Play()

        option.Label.TextColor3 = isSelected and Config.Theme.TextSelected or Config.Theme.Text
        option.ValueLabel.TextColor3 = isSelected and Config.Theme.TextSelected or Config.Theme.Text
        
        if isSelected then
            DescText.Text = option.Description or ""
        end
    end

    ItemCount.Text = State.SelectedIndex .. " / " .. #State.Options
    updateMainFrameSize()
end

local function createOption(name, type, desc)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = OptionsContainer

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Config.Theme.Text
    label.TextSize = Config.TextSize
    label.Font = Config.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.35, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.6, -5, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = ""
    valueLabel.TextColor3 = Config.Theme.Text
    valueLabel.TextSize = Config.TextSize
    valueLabel.Font = Config.Font
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame
    
    return {
        Frame = frame,
        Label = label,
        ValueLabel = valueLabel,
        Type = type,
        Description = desc or "No description provided."
    }
end

-- // INPUT HANDLING WITH CONTEXT ACTION SERVICE // --

local function handleMenuInput(name, state, input)
    if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        local old = game.Players.LocalPlayer.Character.Humanoid.WalkSpeed
        if old == 0 then
            old = 16
        end
        State.Visible = not State.Visible
        MainFrame.Visible = State.Visible
        if State.Visible then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 0
        else
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = old
        end
        return Enum.ContextActionResult.Sink
    end
    
    if not State.Visible then return Enum.ContextActionResult.Pass end
    
    -- Consume navigation keys when menu is visible
    if input.KeyCode == Enum.KeyCode.Up then
        State.SelectedIndex = State.SelectedIndex - 1
        if State.SelectedIndex < 1 then State.SelectedIndex = #State.Options end
        updateSelection()
        return Enum.ContextActionResult.Sink
    elseif input.KeyCode == Enum.KeyCode.Down then
        State.SelectedIndex = State.SelectedIndex + 1
        if State.SelectedIndex > #State.Options then State.SelectedIndex = 1 end
        updateSelection()
        return Enum.ContextActionResult.Sink
    elseif input.KeyCode == Enum.KeyCode.Return then
        local opt = State.Options[State.SelectedIndex]
        if opt.Type == "button" then
            opt.Callback()
        elseif opt.Type == "toggle" then
            opt.Value = not opt.Value
            opt.ValueLabel.Text = opt.Value and "[ON]" or "[OFF]"
            opt.Callback(opt.Value)
        end
        return Enum.ContextActionResult.Sink
    end
    
    return Enum.ContextActionResult.Pass
end

-- Bind menu controls
ContextActionService:BindAction("GTAMenuControls", handleMenuInput, false, Enum.KeyCode.Insert, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Return)

-- // PUBLIC API // --

function UILibrary:CreateWindow(title, subtitle)
    BannerTitle.Text = title:upper()
    SubTitle.Text = subtitle:upper()
    return self
end

function UILibrary:AddButton(name, desc, callback)
    local opt = createOption(name, "button", desc)
    opt.Callback = callback
    table.insert(State.Options, opt)
    updateSelection()
end

function UILibrary:AddToggle(name, desc, default, callback)
    local opt = createOption(name, "toggle", desc)
    opt.Value = default or false
    opt.Callback = callback
    opt.ValueLabel.Text = opt.Value and "[ON]" or "[OFF]"
    table.insert(State.Options, opt)
    updateSelection()
end

return UILibrary
