-- // GTA 5 STYLE MODMENU UI LIBRARY // --
-- // Arrow key navigation, Insert to toggle // --

local UILibrary = {}
UILibrary.__index = UILibrary

-- // SERVICES // --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- // CONFIGURATION // --
local Config = {
    Theme = {
        Background = Color3.fromRGB(20, 20, 20),
        Header = Color3.fromRGB(40, 40, 40),
        Option = Color3.fromRGB(30, 30, 30),
        OptionHover = Color3.fromRGB(50, 50, 50),
        Selected = Color3.fromRGB(65, 105, 225),
        Text = Color3.fromRGB(255, 255, 255),
        TextDisabled = Color3.fromRGB(128, 128, 128),
        ToggleOn = Color3.fromRGB(0, 255, 100),
        ToggleOff = Color3.fromRGB(255, 50, 50),
        Slider = Color3.fromRGB(65, 105, 225),
        Border = Color3.fromRGB(60, 60, 60),
    },
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    AnimationSpeed = 0.2,
}

-- // STATE // --
local State = {
    Visible = false,
    SelectedIndex = 1,
    Options = {},
    CurrentMenu = nil,
}

-- // CREATE SCREEN GUI // --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GTA5ModMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui") or Player:WaitForChild("PlayerGui")

-- // MAIN CONTAINER // --
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
MainFrame.BackgroundColor3 = Config.Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

-- // HEADER // --
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Config.Theme.Header
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Name = "Title"
HeaderTitle.Size = UDim2.new(1, 0, 1, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "MOD MENU"
HeaderTitle.TextColor3 = Config.Theme.Text
HeaderTitle.TextSize = 22
HeaderTitle.Font = Config.Font
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Center
HeaderTitle.Parent = Header

-- // OPTIONS CONTAINER // --
local OptionsContainer = Instance.new("ScrollingFrame")
OptionsContainer.Name = "OptionsContainer"
OptionsContainer.Size = UDim2.new(1, 0, 1, -50)
OptionsContainer.Position = UDim2.new(0, 0, 0, 50)
OptionsContainer.BackgroundTransparency = 1
OptionsContainer.BorderSizePixel = 0
OptionsContainer.ScrollBarThickness = 4
OptionsContainer.ScrollBarImageColor3 = Config.Theme.Selected
OptionsContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 2)
UIListLayout.Parent = OptionsContainer

-- // UI LAYOUT UPDATE // --
local function updateLayout()
    UIListLayout:CalculateLayout()
    OptionsContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end

-- // CREATE OPTION FRAME // --
local function createOptionFrame(name, type, index)
    local frame = Instance.new("Frame")
    frame.Name = "Option" .. index
    frame.Size = UDim2.new(1, -10, 0, 40)
    frame.Position = UDim2.new(0, 5, 0, 0)
    frame.BackgroundColor3 = Config.Theme.Option
    frame.BorderSizePixel = 0
    frame.Parent = OptionsContainer

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Config.Theme.Text
    label.TextSize = Config.TextSize
    label.Font = Config.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0.25, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = ""
    valueLabel.TextColor3 = Config.Theme.TextDisabled
    valueLabel.TextSize = Config.TextSize
    valueLabel.Font = Config.Font
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    local selection = Instance.new("Frame")
    selection.Name = "Selection"
    selection.Size = UDim2.new(0, 4, 1, 0)
    selection.BackgroundColor3 = Config.Theme.Selected
    selection.BorderSizePixel = 0
    selection.Visible = false
    selection.Parent = frame

    return frame, label, valueLabel, selection
end

-- // REFRESH MENU // --
local function refreshMenu()
    -- Clear existing options
    for _, child in ipairs(OptionsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- Create option frames
    for i, option in ipairs(State.Options) do
        local frame, label, valueLabel, selection = createOptionFrame(option.Name, option.Type, i)
        
        if option.Type == "toggle" then
            valueLabel.Text = option.Value and "ON" or "OFF"
            valueLabel.TextColor3 = option.Value and Config.Theme.ToggleOn or Config.Theme.ToggleOff
        elseif option.Type == "slider" then
            valueLabel.Text = tostring(option.Value)
            valueLabel.TextColor3 = Config.Theme.Slider
        elseif option.Type == "button" then
            valueLabel.Text = "[EXECUTE]"
            valueLabel.TextColor3 = Config.Theme.Selected
        elseif option.Type == "dropdown" then
            valueLabel.Text = option.Value
            valueLabel.TextColor3 = Config.Theme.Text
        end

        option.Frame = frame
        option.Label = label
        option.ValueLabel = valueLabel
        option.Selection = selection
    end

    updateLayout()
    updateSelection()
end

-- // UPDATE SELECTION // --
local function updateSelection()
    for i, option in ipairs(State.Options) do
        if option.Selection then
            option.Selection.Visible = (i == State.SelectedIndex)
            if i == State.SelectedIndex then
                option.Frame.BackgroundColor3 = Config.Theme.OptionHover
            else
                option.Frame.BackgroundColor3 = Config.Theme.Option
            end
        end
    end
    
    -- Scroll to selected
    if State.Options[State.SelectedIndex] and State.Options[State.SelectedIndex].Frame then
        local selectedFrame = State.Options[State.SelectedIndex].Frame
        local scrollPosition = selectedFrame.Position.Y.Offset
        OptionsContainer.CanvasPosition = Vector2.new(0, math.max(0, scrollPosition - 50))
    end
end

-- // INPUT HANDLING // --
local function handleInput(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        State.Visible = not State.Visible
        MainFrame.Visible = State.Visible
        return
    end

    if not State.Visible then return end
    if #State.Options == 0 then return end

    local selectedOption = State.Options[State.SelectedIndex]

    if input.KeyCode == Enum.KeyCode.Up then
        State.SelectedIndex = State.SelectedIndex - 1
        if State.SelectedIndex < 1 then
            State.SelectedIndex = #State.Options
        end
        updateSelection()
    elseif input.KeyCode == Enum.KeyCode.Down then
        State.SelectedIndex = State.SelectedIndex + 1
        if State.SelectedIndex > #State.Options then
            State.SelectedIndex = 1
        end
        updateSelection()
    elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Right then
        if selectedOption then
            if selectedOption.Type == "toggle" then
                selectedOption.Value = not selectedOption.Value
                if selectedOption.Callback then
                    selectedOption.Callback(selectedOption.Value)
                end
                selectedOption.ValueLabel.Text = selectedOption.Value and "ON" or "OFF"
                selectedOption.ValueLabel.TextColor3 = selectedOption.Value and Config.Theme.ToggleOn or Config.Theme.ToggleOff
            elseif selectedOption.Type == "button" then
                if selectedOption.Callback then
                    selectedOption.Callback()
                end
            elseif selectedOption.Type == "slider" then
                selectedOption.Value = selectedOption.Value + (selectedOption.Increment or 1)
                if selectedOption.Value > selectedOption.Max then
                    selectedOption.Value = selectedOption.Min
                end
                if selectedOption.Callback then
                    selectedOption.Callback(selectedOption.Value)
                end
                selectedOption.ValueLabel.Text = tostring(selectedOption.Value)
            elseif selectedOption.Type == "dropdown" then
                local currentIndex = table.find(selectedOption.Options, selectedOption.Value) or 1
                currentIndex = currentIndex + 1
                if currentIndex > #selectedOption.Options then
                    currentIndex = 1
                end
                selectedOption.Value = selectedOption.Options[currentIndex]
                if selectedOption.Callback then
                    selectedOption.Callback(selectedOption.Value)
                end
                selectedOption.ValueLabel.Text = selectedOption.Value
            end
        end
    elseif input.KeyCode == Enum.KeyCode.Left then
        if selectedOption and selectedOption.Type == "slider" then
            selectedOption.Value = selectedOption.Value - (selectedOption.Increment or 1)
            if selectedOption.Value < selectedOption.Min then
                selectedOption.Value = selectedOption.Max
            end
            if selectedOption.Callback then
                selectedOption.Callback(selectedOption.Value)
            end
            selectedOption.ValueLabel.Text = tostring(selectedOption.Value)
        elseif selectedOption and selectedOption.Type == "dropdown" then
            local currentIndex = table.find(selectedOption.Options, selectedOption.Value) or 1
            currentIndex = currentIndex - 1
            if currentIndex < 1 then
                currentIndex = #selectedOption.Options
            end
            selectedOption.Value = selectedOption.Options[currentIndex]
            if selectedOption.Callback then
                selectedOption.Callback(selectedOption.Value)
            end
            selectedOption.ValueLabel.Text = selectedOption.Value
        end
    end
end

-- // CONNECT INPUT // --
UserInputService.InputBegan:Connect(handleInput)

-- // LIBRARY FUNCTIONS // --

function UILibrary.new(title)
    local self = setmetatable({}, UILibrary)
    
    State.Options = {}
    State.SelectedIndex = 1
    State.Visible = false
    
    HeaderTitle.Text = title or "MOD MENU"
    MainFrame.Visible = false
    
    return self
end

function UILibrary:CreateWindow(config)
    local self = UILibrary.new(config.Title or "MOD MENU")
    return self
end

function UILibrary:AddToggle(options)
    local toggle = {
        Name = options.Name or "Toggle",
        Type = "toggle",
        Value = options.Default or false,
        Callback = options.Callback or function() end,
        Frame = nil,
        Label = nil,
        ValueLabel = nil,
        Selection = nil,
    }
    
    table.insert(State.Options, toggle)
    refreshMenu()
    
    return toggle
end

function UILibrary:AddButton(options)
    local button = {
        Name = options.Name or "Button",
        Type = "button",
        Callback = options.Callback or function() end,
        Frame = nil,
        Label = nil,
        ValueLabel = nil,
        Selection = nil,
    }
    
    table.insert(State.Options, button)
    refreshMenu()
    
    return button
end

function UILibrary:AddSlider(options)
    local slider = {
        Name = options.Name or "Slider",
        Type = "slider",
        Min = options.Min or 0,
        Max = options.Max or 100,
        Value = options.Default or options.Min,
        Increment = options.Increment or 1,
        Callback = options.Callback or function() end,
        Frame = nil,
        Label = nil,
        ValueLabel = nil,
        Selection = nil,
    }
    
    table.insert(State.Options, slider)
    refreshMenu()
    
    return slider
end

function UILibrary:AddDropdown(options)
    local dropdown = {
        Name = options.Name or "Dropdown",
        Type = "dropdown",
        Options = options.Options or {},
        Value = options.Default or options.Options[1],
        Callback = options.Callback or function() end,
        Frame = nil,
        Label = nil,
        ValueLabel = nil,
        Selection = nil,
    }
    
    table.insert(State.Options, dropdown)
    refreshMenu()
    
    return dropdown
end

function UILibrary:AddLabel(options)
    local label = {
        Name = options.Name or "Label",
        Type = "label",
        Value = options.Text or "",
        Frame = nil,
        Label = nil,
        ValueLabel = nil,
        Selection = nil,
    }
    
    table.insert(State.Options, label)
    refreshMenu()
    
    return label
end

function UILibrary:AddSeparator()
    local separator = {
        Name = "---",
        Type = "separator",
        Frame = nil,
        Label = nil,
        ValueLabel = nil,
        Selection = nil,
    }
    
    table.insert(State.Options, separator)
    refreshMenu()
    
    return separator
end

function UILibrary:SetTitle(title)
    HeaderTitle.Text = title or "MOD MENU"
end

function UILibrary:Toggle()
    State.Visible = not State.Visible
    MainFrame.Visible = State.Visible
end

function UILibrary:Show()
    State.Visible = true
    MainFrame.Visible = true
end

function UILibrary:Hide()
    State.Visible = false
    MainFrame.Visible = false
end

function UILibrary:IsVisible()
    return State.Visible
end

function UILibrary:Clear()
    State.Options = {}
    State.SelectedIndex = 1
    refreshMenu()
end

function UILibrary:SetTheme(theme)
    for key, value in pairs(theme) do
        if Config.Theme[key] then
            Config.Theme[key] = value
        end
    end
    -- Update existing UI
    MainFrame.BackgroundColor3 = Config.Theme.Background
    Header.BackgroundColor3 = Config.Theme.Header
    HeaderTitle.TextColor3 = Config.Theme.Text
    refreshMenu()
end

-- // RETURN LIBRARY // --
return UILibrary
