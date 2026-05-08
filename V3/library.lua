--[[
    library_v3.lua
    Modernized V3 UI Library
    Compatible API Layer for library_v2.lua

    Goal:
    - Keep the SAME external API as V2
    - Allow scripts to swap libraries with minimal/no changes
    - Modernized internals and cleaner architecture

    Example:

    local Library = loadstring(readfile("V3/library_v3.lua"))()

    local Window = Library:CreateWindow({
        Name = "V3 Demo"
    })

    local Tab = Window:CreateTab("Main")
    local Section = Tab:CreateSection("Combat")

    local Toggle = Section:CreateToggle({
        Name = "Kill Aura",
        CurrentValue = false,
        Callback = function(v)
            print(v)
        end
    })
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local UILibrary = {}
UILibrary.__index = UILibrary

local Utility = {}

--// =====================================================
--// Utility
--// =====================================================

function Utility:Create(class, props)
    local obj = Instance.new(class)

    for i,v in pairs(props or {}) do
        if i ~= "Parent" then
            obj[i] = v
        end
    end

    if props and props.Parent then
        obj.Parent = props.Parent
    end

    return obj
end

function Utility:Tween(obj, time, props)
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        props
    )

    tween:Play()
    return tween
end

function Utility:MakeDraggable(topbar, object)
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart

            object.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Utility:ResolveOptions(nameOrTable, callback)
    if typeof(nameOrTable) == "table" then
        return nameOrTable
    end

    return {
        Name = tostring(nameOrTable),
        Callback = callback
    }
end

--// =====================================================
--// Theme
--// =====================================================

local Theme = {
    Background = Color3.fromRGB(10,10,12),
    Surface = Color3.fromRGB(14,14,16),
    Sidebar = Color3.fromRGB(12,12,14),
    Accent = Color3.fromRGB(255,255,255),
    Text = Color3.fromRGB(245,245,245),
    SubText = Color3.fromRGB(180,180,180),
    Stroke = Color3.fromRGB(255,255,255),
    Divider = Color3.fromRGB(28,28,32)
}5),
    Divider = Color3.fromRGB(28,28,32)
}

--// =====================================================
--// Library Root
--// =====================================================

function UILibrary:CreateWindow(options)
    options = options or {}

    local Window = {}
    Window.__index = Window

    local ScreenGui = Utility:Create("ScreenGui", {
        Name = "V3_UI_" .. HttpService:GenerateGUID(false),
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        Parent = CoreGui
    })

    local Main = Utility:Create("FrSize = UDim2.fromOffset(920, 560),,
        Size = UDim2.fromOffset(920, 560),
        PositionBackgroundColor3 = Color3.fromRGB(16,16,18),        BackgroundColor3 = Color3.fromRGB(16,16,18),
        BorderSizePixel =CornerRadius = UDim.new(0, 0),UICorner", {
        CornerRadius = UDim.new(0, 0),
        Parent = Main
    })

    Utility:Create("Thickness = 1.2,       Color = Theme.Stroke,
        Thickness = 1.2,
        Parent = Main
    })

    local Topbar = Utility:Create("Frame", {
        Parent = Main,
        Size = UDim2.new(1,0,0,50),
        BackgroundTransparency = 1
    })

    local Title = Utility:Create("TextLabel", {
        Parent = Topbar,
        Size = UDim2.new(1,-20,1,0),
        Position = UDim2.fromOffset(20,0),
        BackgroundTransparency = 1,
        Text = options.Name or "library_v3",
        Font = Enum.Font.TextSize = 16,      TextColor3 = Theme.Text,
        TextSize = 16,
        Tlocal Sidebar = Utility:Create("Frame", {
        Parent = Main,
        Position = UDim2.fromOffset(0,50),
        Size = UDim2.new(0,185,1,-50),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0
    })

    Utility:Create("UIStroke", {
        Parent = Sidebar,
        Color = Theme.Divider,
        Thickness = 1
    })rent = Sidebar,
        Color = Theme.Divider,
        Thickness = 1
    })

    Utility:Create("UICorner", {
        CornerRadius = UDim.new(0,16),
        Parent = Sidebar
    })

    local TabList = Utility:Create("UIListLayout", {
        Parent = Sidebar,
        Padding = UDim.new(0,6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

  Position = UDim2.fromOffset(205,60),
        Size = UDim2.new(1,-220,1,-80),osition = UDim2.fromOffset(205,60),
        Size = UDim2.new(1,-220,1,-80),
        BackgroundTransparency = 1
    })

    Utility:MakeDraggable(Topbar, Main)

    Window.Tabs = {}
    Window.Gui = ScreenGui

    --// =========================================
    --// Tabs
    --// =========================================

    function Window:CreateTab(name)
        local Tab = {}
        Tab.__index = Tab

        local Button Size = UDim2.new(1,-10,0,30),, {
            Parent = Sidebar,
            Size = UDim2.new(1,-10,0,30),
            Position = UDim2.fromOffset(6,0),
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            Text = tostring(name),
            FoTextSize = 13,.GothamMedium,
            TextColor3 = Theme.Text,
            TextSize = 13,
            AutoButCornerRadius = UDim.new(0,6)        Utility:Create("UICorner", {
            CornerRadius = UDim.new(0,6),
            Parent = Button
        })

        local Page = Utility:Create("ScrollingFrame", {
            Parent = Content,
            Size = UDim2.fromScale(1,1),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 0,
            BackgroundTransparency = 1,
            Visible = false
        })

        local Layout = Utility:Create("UIListLayout", {
            Parent = Page,
            Padding = UDim.new(0,12),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        function Tab:Show()
            for _,v in pairs(Window.Tabs) do
                v.Page.Visible = false
                Utility:Tween(v.Button, 0.15, {
                    BackgroundColor3 = Theme.Surface
                })
            end

            Page.Visible = true

            Utility:Tween(Button, 0.15, {
                BackgroundColor3 = Theme.Accent
            })
        end

        Button.MouseButton1Click:Connect(function()
            Tab:Show()
        end)

        --// =====================================
        --// Sections
        --// =====================================

        function Tab:CreateSection(sectionName)
            local Section = {}
            Section.__index = Section

            local Holder = Utility:Create("Frame", {
                Parent = Page,
                Size = UDim2.new(1,-6,0,40),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Background,
                BorderSizePixel = 0
            })

            Utility:Create("UICorner", {
                CornerRadius = UDim.new(0,12),
                Parent = Holder
            })

            Utility:Create("UIStroke", {
                Parent = Holder,
                Color = Theme.Stroke,
                Thickness = 1
            })

            local Padding = Utility:Create("UIPadding", {
                Parent = Holder,
                PaddingTop = UDim.new(0,12),
                PaddingBottom = UDim.new(0,12),
                PaddingLeft = UDim.new(0,12),
                PaddingRight = UDim.new(0,12)
            })

            local SectionTitle = Utility:Create("TextLabel", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,20),
                BackgroundTransparency = 1,
                Text = tostring(sectionName),
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.Text,
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Container = Utility:Create("Frame", {
                Parent = Holder,
                Position = UDim2.fromOffset(0,30),
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1
            })

            local ContainerLayout = Utility:Create("UIListLayout", {
                Parent = Container,
                Padding = UDim.new(0,8),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            --// =================================
            --// Button
            --// =================================

            function Section:CreateButton(data, callback)
                data = Utility:ResolveOptions(data, callback)

                local ButtonObj = {}
                ButtonObj.__index = ButtonObj

                local Btn = Utility:Create("TextButton", {
                    Parent =BackgroundColor3 = Color3.fromRGB(16,16,18), = UDim2.new(1,0,0,36),
                    BackgroundColor3 = Color3.fromRGB(16,16,18),BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    Text = data.Name or "BTextSize = 13,              Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.Text,
                    TextSize = 13,,
                    AutoButtonColor = CornerRadius = UDim.new(0,6)             Utility:Create("UICorner", {
                    Parent = Btn,
                    CornerRadius = UDim.new(0,6)
                })

                Btn.MouseButton1Click:Connect(function()
                    if data.Callback then
                        data.Callback()
                    end
                end)

                function ButtonObj:SetText(text)
                    Btn.Text = text
                end

                function ButtonObj:SetVisible(state)
                    Btn.Visible = state
                end

                return ButtonObj
            end

            --// =================================
            --// Toggle
            --// =================================

            function Section:CreateToggle(data)
                data = data or {}

                local Toggle = {}
                Toggle.__index = Toggle

                Toggle.Value = data.CurrentValue or false

                local HolderFrame = Utility:Create(BackgroundColor3 = Color3.fromRGB(16,16,18),Parent = Container,
                    Size = UDimBackgroundColor3 = Color3.fromRGB(16,16,18),2.new(1,0,0,40),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    Text = "",
   CornerRadius = UDim.new(0,6)lor = false
                })

                Utility:Create("UICorner", {
                    Parent = HolderFrame,
                    CornerRadius = UDim.new(0,6)
                })

                local Label = Utility:Create("TextLabel", {
                    Parent = HolderFrame,
                    Position = UDim2.fromOffset(12,0),
                    Size = UDim2.new(1,-70,1,0),
                    BackgroundTransparency = 1,TextSize = 13,       Text = data.Name or "Toggle",
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.Text,
                   TextSize = 13,,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local Switch = Utility:Create("Frame", {
                    Parent = HolderFrame,
                    AnchorPoint = Vector2.new(1,0.5),
                    Position = UDim2.new(1,-12,0.5,0),
                    Size = UDim2.fromOffset(42,22),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0
                })

                Utility:Create("UICorner", {
                    Parent = Switch,
                    CornerRadius = UDim.new(1,0)
                })

                local Knob = Utility:Create("Frame", {
                    Parent = Switch,
                    Position = UDim2.fromOffset(2,2),
                    Size = UDim2.fromOffset(18,18),
                    BackgroundColor3 = Color3.new(1,1,1),
                    BorderSizePixel = 0
                })

                Utility:Create("UICorner", {
                    Parent = Knob,
                    CornerRadius = UDim.new(1,0)
                })

                function Toggle:Set(state)
                    Toggle.Value = state

                    Utility:Tween(Knob, 0.18, {
                        Position = state and UDim2.fromOffset(22,2) or UDim2.fromOffset(2,2)
                    })

                    Utility:Tween(Switch, 0.18, {
                        BackgroundColor3 = state and Theme.Accent or Theme.Surface
                    })

                    if data.Callback then
                        task.spawn(function()
                            data.Callback(state)
                        end)
                    end
                end

                function Toggle:Get()
                    return Toggle.Value
                end

                function Toggle:SetVisible(state)
                    HolderFrame.Visible = state
                end

                HolderFrame.MouseButton1Click:Connect(function()
                    Toggle:Set(not Toggle.Value)
                end)

                Toggle:Set(Toggle.Value)

                return Toggle
            end

            --// =================================
            --// Slider
            --// =================================

            function Section:CreateSlider(data)
                data = data or {}

                local Slider = {}
                Slider.__index = Slider

                Slider.Value = data.CurrentValue or data.Min or 0

BackgroundColor3 = Color3.fromRGB(16,16,18),Utility:Create("Frame", {
                    Parent = ContaiBackgroundColor3 = Color3.fromRGB(16,16,18),ner,
                    Size = UDim2.new(1,0,0,60),
          CornerRadius = UDim.new(0,6)Theme.Background,
                    BorderSizePixel = 0
                })

                Utility:Create("UICorner", {
                    Parent = HolderFrame,
                    CornerRadius = UDim.new(0,6)
                })

                local Label = Utility:Create("TextLabel", {
                    Parent = HolderFrame,
                    Position = UDim2.fromOffset(12,6),
                    Size = UDim2.new(1,-24,0,20),
                    BackgroundTransparTextSize = 13,                Text = (data.Name or "Slider") .. " : " .. tostring(Slider.Value),
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.Text,
                   TextSize = 13,,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local Bar = Utility:Create("Frame", {
                    Parent = HolderFrame,
                    Position = UDim2.fromOffset(12,36),
                    Size = UDim2.new(1,-24,0,8),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0
                })

                Utility:Create("UICorner", {
                    Parent = Bar,
                    CornerRadius = UDim.new(1,0)
                })

                local Fill = Utility:Create("Frame", {
                    Parent = Bar,
                    Size = UDim2.new(0,0,1,0),
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0
                })

                Utility:Create("UICorner", {
                    Parent = Fill,
                    CornerRadius = UDim.new(1,0)
                })

                function Slider:Set(value)
                    local min = data.Min or 0
                    local max = data.Max or 100

                    value = math.clamp(value, min, max)
                    Slider.Value = value

                    local percent = (value - min) / (max - min)

                    Fill.Size = UDim2.new(percent,0,1,0)
                    Label.Text = (data.Name or "Slider") .. " : " .. tostring(value)

                    if data.Callback then
                        data.Callback(value)
                    end
                end

                function Slider:Get()
                    return Slider.Value
                end

                Slider:Set(Slider.Value)

                return Slider
            end

            --// =================================
            --// Label
            --// =================================

            function Section:CreateLabel(text)
                local LabelObj = {}

                local Label = Utility:Create("TextLabel", {
                    Parent = Container,
                    Size = UDim2.newTextSize = 13,                  BackgroundTransparency = 1,
                    Text = tostring(text),
                    Font = Enum.Font.Gotham,
                    TextColor3 = Theme.SubText,
                   TextSize = 13,,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                function LabelObj:Set(text2)
                    Label.Text = text2
                end

                return LabelObj
            end

            --// =================================
            --// Textbox
            --// =================================

            function Section:CreateTextbox(data)
                data =BackgroundColor3 = Color3.fromRGB(16,16,18),extboxObj = {}

                local Box = Utility:Create("TextBox", {
                    Parent = Container,
                    Size = UDim2.new(1,0,0,36),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    PlaceholderTTextSize = 13,ceholderText or data.Name or "Textbox",
                    Text = data.CurrentValue or "",
                    Font = Enum.Font.Gotham,
                    TextColoCornerRadius = UDim.new(0,6)       TextSize = 13,,
                    ClearTextOnFocus = false
                })

                Utility:Create("UICorner", {
                    Parent = Box,
                    CornerRadius = UDim.new(0,6)
                })

                Box.FocusLost:Connect(function()
                    if data.Callback then
                        data.Callback(Box.Text)
                    end
                end)

                function TextboxObj:Set(text)
                    Box.Text = text
                end

                function TextboxObj:Get()
                    return Box.Text
                end

                return TextboxObj
            end

            --// =================================
            --// Dropdown (basic)
            --// =================================

            function Section:CreateDropdown(data)
                data = data or {}

                local Dropdown = {}
               BackgroundColor3 = Color3.fromRGB(16,16,18), or nil

                local Button = Utility:Create("TextButton", {
                    Parent = Container,
                    Size = UDim2.new(1,0,0,36),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    Text = data.Name or "Dropdown",
                    Font = EnumCornerRadius = UDim.new(0,6)     TextColor3 = Theme.Text,
                    TextSize = 14
                })

                Utility:Create("UICorner", {
                    Parent = Button,
                    CornerRadius = UDim.new(0,6)
                })

                function Dropdown:Set(option)
                    Dropdown.Value = option
                    Button.Text = tostring(option)

                    if data.Callback then
                        data.Callback(option)
                    end
                end

                function Dropdown:Get()
                    return Dropdown.Value
                end

                return Dropdown
            end

            --// =================================
            --// Keybind (basic)
            --// =================================

            function Section:CreateKeybind(data)
                data = data or {}

                local Keybind = {}
                Keybind.Value = data.CurrentKeybind or Enum.KeyCode.RightShBackgroundColor3 = Color3.fromRGB(16,16,18), false

                local Button = Utility:Create("TextButton", {
                    Parent = Container,
                    Size = UDim2.new(1,0,0,36),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    Text = (data.Name or "Keybind") .. " : " .. Keybind.Value.Name,
                    Font = Enum.CornerRadius = UDim.new(0,6)    TextColor3 = Theme.Text,
                    TextSize = 14
                })

                Utility:Create("UICorner", {
                    Parent = Button,
                    CornerRadius = UDim.new(0,6)
                })

                Button.MouseButton1Click:Connect(function()
                    Waiting = true
                    Button.Text = "Press any key..."
                end)

                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then
                        return
                    end

                    if Waiting then
                        Waiting = false

                        Keybind.Value = input.KeyCode
                        Button.Text = (data.Name or "Keybind") .. " : " .. input.KeyCode.Name
                        return
                    end

                    if input.KeyCode == Keybind.Value then
                        if data.Callback then
                            data.Callback()
                        end
                    end
                end)

                function Keybind:Set(key)
                    Keybind.Value = key
                end

                function Keybind:Get()
                    return Keybind.Value
                end

                return Keybind
            end

            return Section
        end

        --// Compatibility
        function Tab:CreateSubTab(name)
            return Tab
        end

        Tab.Button = Button
        Tab.Page = Page

        table.insert(Window.Tabs, Tab)

        if #Window.Tabs == 1 then
            Tab:Show()
        end

        return Tab
    end

    --// =========================================
    --// Notifications
    --// =========================================

    function Window:Notify(data)
        data = data or {}

        local Notification = Utility:Create("Frame", {
            Parent = ScreenGui,
            AnchorPoint = Vector2.new(1,1),
            Position = UDim2.new(1,-20,1,-20),
            Size = UDim2.fromOffset(260,80),
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0
        })

        Utility:Create("UICorner", {
            Parent = Notification,
            CornerRadius = UDim.new(0,12)
        })

        local Text = Utility:Create("TextLabel", {
            Parent = Notification,
            Size = UDim2.new(1,-20,1,-20),
            Position = UDim2.fromOffset(10,10),
            BackgroundTransparency = 1,
            Text = data.Content or data.Text or "Notification",
            Font = Enum.Font.Gotham,
            TextColor3 = Theme.Text,
            TextWrapped = true,
            TextSize = 14
        })

        Notification.BackgroundTransparency = 1
        Text.TextTransparency = 1

        Utility:Tween(Notification, 0.2, {
            BackgroundTransparency = 0
        })

        Utility:Tween(Text, 0.2, {
            TextTransparency = 0
        })

        task.delay(data.Duration or 3, function()
            Utility:Tween(Notification, 0.2, {
                BackgroundTransparency = 1
            })

            Utility:Tween(Text, 0.2, {
                TextTransparency = 1
            })

            task.wait(0.25)
            Notification:Destroy()
        end)
    end

    function Window:Destroy()
        ScreenGui:Destroy()
    end

    return Window
end

return setmetatable({}, UILibrary)
