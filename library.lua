-- // IMPORTS // --
local UILibrary = (function()
    local UILibrary = {}
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    -- // TWEEN POOLING // --
    local TweenPool = {}

    local function PlayTween(instance, info, props)
        local key = instance:GetDebugId() .. tostring(props)

        if TweenPool[key] then
            TweenPool[key]:Cancel()
        end

        local tween = TweenService:Create(instance, info, props)
        TweenPool[key] = tween
        tween:Play()

        tween.Completed:Connect(function()
            TweenPool[key] = nil
        end)

        return tween
    end

    
    -- // CONFIGURATION & THEMES // --
    local Options = {
        Theme = "Default",
        ToggleStyle = "Switch", -- "Switch" or "Checkbox"
        CornerStyle = "Rounded", -- "Rounded", "Slight", "Blocky"
        Font = "Gotham", -- "Gotham", "Ubuntu", "Code", "Jura"
        MenuStyle = "Sidebar" -- "Sidebar" (V1) or "Dropdown" (V2)
    }

    local Themes = {
        Default = { MainBg = Color3.fromRGB(10, 10, 10), SecBg = Color3.fromRGB(20, 20, 20), TerBg = Color3.fromRGB(25, 25, 25), QuarBg = Color3.fromRGB(40, 40, 40), Hover = Color3.fromRGB(35, 35, 35), Accent = Color3.fromRGB(220, 40, 40), Text = Color3.fromRGB(255, 255, 255), SubText = Color3.fromRGB(150, 150, 150), Stroke = Color3.fromRGB(50, 50, 50) },
        Dark = { MainBg = Color3.fromRGB(15, 15, 15), SecBg = Color3.fromRGB(22, 22, 22), TerBg = Color3.fromRGB(30, 30, 30), QuarBg = Color3.fromRGB(45, 45, 45), Hover = Color3.fromRGB(50, 50, 50), Accent = Color3.fromRGB(150, 80, 255), Text = Color3.fromRGB(240, 240, 240), SubText = Color3.fromRGB(170, 170, 170), Stroke = Color3.fromRGB(70, 70, 70) },
        Light = { MainBg = Color3.fromRGB(245, 245, 245), SecBg = Color3.fromRGB(230, 230, 230), TerBg = Color3.fromRGB(215, 215, 215), QuarBg = Color3.fromRGB(200, 200, 200), Hover = Color3.fromRGB(180, 180, 180), Accent = Color3.fromRGB(50, 130, 255), Text = Color3.fromRGB(20, 20, 20), SubText = Color3.fromRGB(100, 100, 100), Stroke = Color3.fromRGB(180, 180, 180) },
        Discord = { MainBg = Color3.fromRGB(54, 57, 63), SecBg = Color3.fromRGB(47, 49, 54), TerBg = Color3.fromRGB(64, 68, 75), QuarBg = Color3.fromRGB(79, 84, 92), Hover = Color3.fromRGB(114, 118, 125), Accent = Color3.fromRGB(88, 101, 242), Text = Color3.fromRGB(255, 255, 255), SubText = Color3.fromRGB(185, 187, 190), Stroke = Color3.fromRGB(32, 34, 37) }
    }

    local FontMap = {
        Gotham = { Regular = Enum.Font.Gotham, Bold = Enum.Font.GothamBold, Black = Enum.Font.GothamBlack },
        Ubuntu = { Regular = Enum.Font.Ubuntu, Bold = Enum.Font.Ubuntu, Black = Enum.Font.Ubuntu },
        Code = { Regular = Enum.Font.Code, Bold = Enum.Font.Code, Black = Enum.Font.Code },
        Jura = { Regular = Enum.Font.Jura, Bold = Enum.Font.Jura, Black = Enum.Font.Jura }
    }

    -- // REGISTRIES (SPLIT BY TYPE) // --
    local Registries = {
        Theme = {},
        Font = {},
        Corner = {},
        Toggle = {},
        MenuLayout = {},
        Tooltips = {},
        Favorites = {},
        Dependencies = {},
        Elements = setmetatable({}, {__mode = "v"}) -- weak refs
    }


    -- Cleans out destroyed elements to prevent memory leaks
    local function CleanRegistries()
        for _, registry in pairs(Registries) do
            if typeof(registry) == "table" then
                for i = #registry, 1, -1 do
                    local item = registry[i]
                    if typeof(item) == "table" and item.Instance then
                        if not item.Instance.Parent then
                            table.remove(registry, i)
                        end
                    end
                end
            end
        end
    end



    local function CreateElement(class, properties, themeData)
        local element = Instance.new(class)
        
        if properties.Font then
            local weight = "Regular"
            if properties.Font == Enum.Font.GothamBold then weight = "Bold"
            elseif properties.Font == Enum.Font.GothamBlack then weight = "Black" end
            table.insert(Registries.Font, {Instance = element, Weight = weight})
            properties.Font = FontMap[Options.Font][weight] or FontMap[Options.Font].Regular
        end

        if class == "UICorner" then
            local origRadius = properties.CornerRadius or UDim.new(0, 8)
            table.insert(Registries.Corner, {Instance = element, Original = origRadius})
            if Options.CornerStyle == "Blocky" then properties.CornerRadius = UDim.new(0, 0)
            elseif Options.CornerStyle == "Slight" then
                if origRadius.Scale ~= 1 then properties.CornerRadius = UDim.new(0, math.floor(origRadius.Offset / 2)) end
            end
        end

        for prop, value in pairs(properties) do element[prop] = value end
        
        if themeData then
            for prop, role in pairs(themeData) do
                table.insert(Registries.Theme, {Instance = element, Property = prop, Role = role})
                element[prop] = Themes[Options.Theme][role]
            end
        end
        return element
    end

    local function UpdateTheme(themeName)
        if not Themes[themeName] then return end
        Options.Theme = themeName; CleanRegistries()
        local themeColors = Themes[themeName]
        for _, item in ipairs(Registries.Theme) do
            if item.Instance and item.Instance.Parent then PlayTween(item.Instance, TweenInfo.new(0.3), {[item.Property] = themeColors[item.Role]}):Play() end
        end
        for _, syncFunc in ipairs(Registries.Toggle) do syncFunc(true) end
    end

    local function UpdateToggleStyles(styleName) Options.ToggleStyle = styleName; for _, syncFunc in ipairs(Registries.Toggle) do syncFunc() end end
    local function UpdateMenuStyle(styleName) Options.MenuStyle = styleName; for _, syncFunc in ipairs(Registries.MenuLayout) do syncFunc(styleName) end end

    local function UpdateFont(fontName)
        if not FontMap[fontName] then return end
        Options.Font = fontName; CleanRegistries()
        for _, item in ipairs(Registries.Font) do
            if item.Instance and item.Instance.Parent then item.Instance.Font = FontMap[fontName][item.Weight] or FontMap[fontName].Regular end
        end
    end

    local function UpdateCornerStyle(styleName)
        Options.CornerStyle = styleName; CleanRegistries()
        for _, item in ipairs(Registries.Corner) do
            if item.Instance and item.Instance.Parent then
                local newRadius = item.Original
                if styleName == "Blocky" then newRadius = UDim.new(0, 0)
                elseif styleName == "Slight" then if item.Original.Scale ~= 1 then newRadius = UDim.new(0, math.floor(item.Original.Offset / 2)) end end
                PlayTween(item.Instance, TweenInfo.new(0.3), {CornerRadius = newRadius}):Play()
            end
        end
    end

    function UILibrary:CreateWindow(title)
        local window = {}
        local tabs = {}
        window.connections = {}
        window.cleanupFunctions = {}
        local FPSCleanup = nil
        local Minimized = false
        
        local ScreenGui = CreateElement("ScreenGui", { Name = "UILibWindow", Parent = game:GetService("CoreGui"), ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false, IgnoreGuiInset = true })
        
        local MainFrame = CreateElement("Frame", { Name = "MainFrame", Parent = ScreenGui, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 600, 0, 450), ClipsDescendants = true, Visible = true }, {BackgroundColor3 = "MainBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = MainFrame})
        CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = MainFrame}, {Color = "Stroke"})
        
        local TopBar = CreateElement("Frame", { Name = "TopBar", Parent = MainFrame, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 40) }, {BackgroundColor3 = "SecBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = TopBar})
        CreateElement("Frame", { Parent = TopBar, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 10) }, {BackgroundColor3 = "SecBg"})
        
        CreateElement("TextLabel", { Parent = TopBar, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0.5, 0, 1, 0), Font = Enum.Font.GothamBlack, Text = title or "UI Library", TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, }, {TextColor3 = "Text"})
        
        local CloseButton = CreateElement("TextButton", { Parent = TopBar, BackgroundColor3 = Color3.fromRGB(200, 50, 50), BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 24, 0, 24), Font = Enum.Font.GothamBold, Text = "X", TextSize = 14 }, {TextColor3 = "Text"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = CloseButton})
        local MinimizeButton = CreateElement("TextButton", { Parent = TopBar, BackgroundColor3 = Color3.fromRGB(200, 150, 50), BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -40, 0.5, 0), Size = UDim2.new(0, 24, 0, 24), Font = Enum.Font.GothamBold, Text = "-", TextSize = 14 }, {TextColor3 = "Text"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = MinimizeButton})
        local CollapseKeybindButton = CreateElement("TextButton", { Parent = TopBar, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -70, 0.5, 0), Size = UDim2.new(0, 30, 0, 24), Font = Enum.Font.GothamBold, Text = "Ins", TextSize = 12 }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = CollapseKeybindButton})
        local SettingsButton = CreateElement("TextButton", { Parent = TopBar, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -105, 0.5, 0), Size = UDim2.new(0, 24, 0, 24), Font = Enum.Font.GothamBold, Text = "⚙", TextSize = 14 }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = SettingsButton})

        -- Sidebar Navigation Components
        local TabContainer = CreateElement("Frame", { Name = "TabContainer", Parent = MainFrame, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(0, 150, 1, -40) }, {BackgroundColor3 = "SecBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = TabContainer})
        CreateElement("Frame", { Parent = TabContainer, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 10) }, {BackgroundColor3 = "SecBg"})
        CreateElement("Frame", { Parent = TabContainer, BorderSizePixel = 0, Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0, 10, 1, 0) }, {BackgroundColor3 = "SecBg"})

        -- // SEARCH SYSTEM // --
        local SearchBox = CreateElement("TextBox",{
            Parent = TabContainer,
            PlaceholderText = "Search...",
            Size = UDim2.new(1,-20,0,30),
            Position = UDim2.new(0,10,0,10),
            Text = "",
            Font = Enum.Font.Gotham,
            TextSize = 13
        },{BackgroundColor3="TerBg",TextColor3="Text"})

        CreateElement("UICorner",{CornerRadius=UDim.new(0,6),Parent=SearchBox})

        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local query = string.lower(SearchBox.Text)

            for _,tab in pairs(tabs) do
                local match = string.find(string.lower(tab.Name),query)
                tab.Button.Visible = match ~= nil or query == ""
            end
        end)


        local TabHolder = CreateElement("ScrollingFrame", { Name = "TabHolder", Parent = TabContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 0, BorderSizePixel = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y })
        CreateElement("UIListLayout", { Parent = TabHolder, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top })
        CreateElement("UIPadding", {Parent = TabHolder, PaddingTop = UDim.new(0, 10)})
        
        local Separator = CreateElement("Frame", { Parent = MainFrame, BorderSizePixel = 0, Position = UDim2.new(0, 150, 0, 40), Size = UDim2.new(0, 1, 1, -40), ZIndex = 5 }, {BackgroundColor3 = "Stroke"})
        local ContentFrame = CreateElement("Frame", { Name = "ContentFrame", Parent = MainFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 160, 0, 50), Size = UDim2.new(1, -170, 1, -60) })

        -- Dropdown Navigation Components (V2)
        local NavDropdownFrame = CreateElement("Frame", { Parent = MainFrame, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, 50), Size = UDim2.new(1, -20, 0, 35), ClipsDescendants = true, Visible = false, ZIndex = 10 }, {BackgroundColor3 = "TerBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = NavDropdownFrame})
        CreateElement("UIStroke", {Thickness = 1, Parent = NavDropdownFrame}, {Color = "Stroke"})

        local NavDropdownBtn = CreateElement("TextButton", { Parent = NavDropdownFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35), Font = Enum.Font.GothamBold, Text = "Select Tab", TextSize = 14, ZIndex = 11 }, {TextColor3 = "Text"})
        local NavDropdownIcon = CreateElement("TextLabel", { Parent = NavDropdownBtn, BackgroundTransparency = 1, Position = UDim2.new(1, -25, 0, 0), Size = UDim2.new(0, 20, 1, 0), Font = Enum.Font.GothamBold, Text = "▼", TextSize = 12, ZIndex = 11 }, {TextColor3 = "SubText"})

        local NavIsOpen = false
        local NavOptionContainer = nil

        NavDropdownBtn.MouseButton1Click:Connect(function()
            NavIsOpen = not NavIsOpen
            if NavIsOpen then
                if NavOptionContainer then NavOptionContainer:Destroy() end
                NavOptionContainer = CreateElement("Frame", { Parent = NavDropdownFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 35), Size = UDim2.new(1, 0, 0, #tabs * 30), ZIndex = 10 })
                for i, tab in ipairs(tabs) do
                    local optBtn = CreateElement("TextButton", { Parent = NavOptionContainer, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, (i-1)*30), Size = UDim2.new(1, -20, 0, 28), Font = Enum.Font.Gotham, Text = tab.Name, TextSize = 12, AutoButtonColor = false, ZIndex = 11 }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
                    CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = optBtn})

                    optBtn.MouseEnter:Connect(function() PlayTween(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play() end)
                    optBtn.MouseLeave:Connect(function() PlayTween(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].QuarBg}):Play() end)

                    optBtn.MouseButton1Click:Connect(function()
                        window:SwitchToTab(tab)
                        NavIsOpen = false
                        PlayTween(NavDropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, 35)}):Play()
                        PlayTween(NavDropdownIcon, TweenInfo.new(0.2), {Rotation = 0}):Play()
                        task.delay(0.2, function() if NavOptionContainer then NavOptionContainer:Destroy() end end)
                    end)
                end
                PlayTween(NavDropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, 35 + (#tabs * 30) + 10)}):Play()
                PlayTween(NavDropdownIcon, TweenInfo.new(0.2), {Rotation = 180}):Play()
            else
                PlayTween(NavDropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, 35)}):Play()
                PlayTween(NavDropdownIcon, TweenInfo.new(0.2), {Rotation = 0}):Play()
                task.delay(0.2, function() if NavOptionContainer then NavOptionContainer:Destroy() end end)
            end
        end)

        -- Handle Layout Switching
        table.insert(Registries.MenuLayout, function(style)
            if style == "Sidebar" then
                TabContainer.Visible = true; Separator.Visible = true; NavDropdownFrame.Visible = false
                PlayTween(ContentFrame, TweenInfo.new(0.3), {Position = UDim2.new(0, 160, 0, 50), Size = UDim2.new(1, -170, 1, -60)}):Play()
            elseif style == "Dropdown" then
                TabContainer.Visible = false; Separator.Visible = false; NavDropdownFrame.Visible = true
                PlayTween(ContentFrame, TweenInfo.new(0.3), {Position = UDim2.new(0, 10, 0, 95), Size = UDim2.new(1, -20, 1, -105)}):Play()
            end
            if NavIsOpen then -- Auto-collapse dropdown if open during style switch
                NavIsOpen = false
                PlayTween(NavDropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, 35)}):Play()
                PlayTween(NavDropdownIcon, TweenInfo.new(0.2), {Rotation = 0}):Play()
                if NavOptionContainer then NavOptionContainer:Destroy() end
            end
        end)

        -- // Settings Menu // --
        local SettingsOverlay = CreateElement("Frame", { Name = "SettingsOverlay", Parent = MainFrame, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, ZIndex = 20 })

        local SettingsFrame = CreateElement("Frame", { Name = "SettingsFrame", Parent = SettingsOverlay, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10), Size = UDim2.new(0, 500, 0, 350), ClipsDescendants = true }, {BackgroundColor3 = "SecBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 14), Parent = SettingsFrame})
        CreateElement("UIStroke", {Thickness = 1, Parent = SettingsFrame}, {Color = "Stroke"})
        
        local SettingsHeader = CreateElement("Frame", { Parent = SettingsFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40) })
        CreateElement("TextLabel", { Parent = SettingsHeader, BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(1, -50, 1, 0), Font = Enum.Font.GothamBold, Text = "Settings", TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
        local CloseSettingsButton = CreateElement("TextButton", {Parent = SettingsHeader, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.new(0, 24, 0, 24), Font = Enum.Font.GothamBold, Text = "X", TextSize = 16}, {TextColor3 = "SubText"})

        local SettingsBody = CreateElement("Frame", { Parent = SettingsFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 1, -40) })
        local SettingsSidebar = CreateElement("ScrollingFrame", { Parent = SettingsBody, BackgroundTransparency = 1, Size = UDim2.new(0, 140, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 0 })
        CreateElement("UIListLayout", {Parent = SettingsSidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
        CreateElement("UIPadding", {Parent = SettingsSidebar, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10)})
        CreateElement("Frame", { Parent = SettingsBody, BorderSizePixel = 0, Position = UDim2.new(0, 140, 0, 10), Size = UDim2.new(0, 1, 1, -20) }, {BackgroundColor3 = "Stroke"})

        local SettingsContent = CreateElement("Frame", { Parent = SettingsBody, BackgroundTransparency = 1, Position = UDim2.new(0, 150, 0, 0), Size = UDim2.new(1, -150, 1, 0) })

        local SettingsTabs = {}
        local CurrentSettingsPage = nil

        local function SwitchSettingsTab(name)
            for n, tab in pairs(SettingsTabs) do
                tab.Page.Visible = (n == name)
                if n == name then PlayTween(tab.Button, TweenInfo.new(0.2), {TextColor3 = Themes[Options.Theme].Text, BackgroundTransparency = 0.9}):Play()
                else PlayTween(tab.Button, TweenInfo.new(0.2), {TextColor3 = Themes[Options.Theme].SubText, BackgroundTransparency = 1}):Play() end
            end
        end

        local function CreateSettingsSection(text)
            if SettingsTabs[text] then return end
            local tabBtn = CreateElement("TextButton", { Parent = SettingsSidebar, BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(1, -10, 0, 30), Text = text, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, {TextColor3 = "SubText"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = tabBtn})
            CreateElement("UIPadding", {Parent = tabBtn, PaddingLeft = UDim.new(0, 10)})
            local page = CreateElement("ScrollingFrame", { Parent = SettingsContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y })
            CreateElement("UIListLayout", {Parent = page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
            CreateElement("UIPadding", {Parent = page, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})
            SettingsTabs[text] = {Button = tabBtn, Page = page}; CurrentSettingsPage = page
            tabBtn.MouseButton1Click:Connect(function() SwitchSettingsTab(text) end)
            if not next(SettingsTabs, next(SettingsTabs)) then SwitchSettingsTab(text) end
        end

        local function CreateSettingsButton(text, callback)
            local button = CreateElement("TextButton", { Parent = CurrentSettingsPage, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 40), AutoButtonColor = false, Text = "" }, {BackgroundColor3 = "TerBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = button})
            CreateElement("UIStroke", {Thickness = 1, Parent = button}, {Color = "Stroke"})
            CreateElement("TextLabel", { Parent = button, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(1, -15, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
            button.MouseEnter:Connect(function() PlayTween(button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play() end)
            button.MouseLeave:Connect(function() PlayTween(button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play() end)
            button.MouseButton1Click:Connect(function() pcall(callback); PlayTween(button, TweenInfo.new(0.1), {Size = UDim2.new(1, -2, 0, 38)}):Play(); task.wait(0.1); PlayTween(button, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 40)}):Play() end)
        end

        local function CreateSettingsDropdown(text, options, default, callback)
            local dropdownFrame = CreateElement("Frame", { Parent = CurrentSettingsPage, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 45), ClipsDescendants = true }, {BackgroundColor3 = "TerBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = dropdownFrame})
            CreateElement("UIStroke", {Thickness = 1, Parent = dropdownFrame}, {Color = "Stroke"})
            CreateElement("TextLabel", { Parent = dropdownFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0.5, 0, 0, 45), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})

            local dropdownButton = CreateElement("TextButton", { Parent = dropdownFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -15, 0, 8), Size = UDim2.new(0, 120, 0, 28), Font = Enum.Font.GothamBold, Text = default or options[1] or "None", TextSize = 12, AutoButtonColor = false }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = dropdownButton})
            
            local isOpen = false; local optionContainer
            dropdownButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    if optionContainer then optionContainer:Destroy() end
                    optionContainer = CreateElement("Frame", { Parent = dropdownFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(1, 0, 0, #options * 30) })
                    for i, opt in ipairs(options) do
                        local optBtn = CreateElement("TextButton", { Parent = optionContainer, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, (i-1)*30), Size = UDim2.new(1, -20, 0, 28), Font = Enum.Font.Gotham, Text = opt, TextSize = 12, AutoButtonColor = false }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
                        CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = optBtn})
                        optBtn.MouseEnter:Connect(function() PlayTween(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play() end)
                        optBtn.MouseLeave:Connect(function() PlayTween(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].QuarBg}):Play() end)
                        optBtn.MouseButton1Click:Connect(function() dropdownButton.Text = opt; isOpen = false; PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45)}):Play(); task.delay(0.2, function() if optionContainer then optionContainer:Destroy() end end); pcall(callback, opt) end)
                    end
                    PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45 + (#options * 30) + 10)}):Play()
                else
                    PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45)}):Play(); task.delay(0.2, function() if optionContainer then optionContainer:Destroy() end end)
                end
            end)
        end

        -- // Initialize Global Settings Options //
        CreateSettingsSection("Appearance")
        CreateSettingsDropdown("Menu Style", {"Sidebar", "Dropdown"}, Options.MenuStyle, function(val) UpdateMenuStyle(val) end)
        CreateSettingsDropdown("Interface Theme", {"Default", "Dark", "Light", "Discord"}, Options.Theme, function(val) UpdateTheme(val) end)
        CreateSettingsDropdown("Toggle Style", {"Switch", "Checkbox"}, Options.ToggleStyle, function(val) UpdateToggleStyles(val) end)
        CreateSettingsDropdown("Corner Style", {"Rounded", "Slight", "Blocky"}, Options.CornerStyle, function(val) UpdateCornerStyle(val) end)
        CreateSettingsDropdown("Global Font", {"Gotham", "Ubuntu", "Code", "Jura"}, Options.Font, function(val) UpdateFont(val) end)

        CreateSettingsSection("General")
        local function CreateSettingsToggle(text, callback)
            local toggleButton = CreateElement("TextButton", { Parent = CurrentSettingsPage, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 45), AutoButtonColor = false, Text = "" }, {BackgroundColor3 = "TerBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = toggleButton})
            local stroke = CreateElement("UIStroke", {Thickness = 1, Parent = toggleButton}, {Color = "Stroke"})
            CreateElement("TextLabel", { Parent = toggleButton, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0.7, 0, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
            
            local toggleContainer = CreateElement("Frame", { Parent = toggleButton, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.new(0, 44, 0, 22) })
            
            local switchBg = CreateElement("Frame", { Parent = toggleContainer, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0) }, {BackgroundColor3 = "QuarBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = switchBg})
            local switchCircle = CreateElement("Frame", { Parent = switchBg, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.new(0, 18, 0, 18) }, {BackgroundColor3 = "SubText"})
            CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = switchCircle})
            
            local checkBg = CreateElement("Frame", { Parent = toggleContainer, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 22, 0, 22), Visible = false }, {BackgroundColor3 = "QuarBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = checkBg})
            local checkInner = CreateElement("Frame", { Parent = checkBg, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0) }, {BackgroundColor3 = "Accent"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 3), Parent = checkInner})
            
            local toggled = false
            local function syncVisuals(themeUpdate)
                local duration = themeUpdate and 0 or 0.2
                if Options.ToggleStyle == "Switch" then
                    switchBg.Visible = true; checkBg.Visible = false
                    PlayTween(switchBg, TweenInfo.new(duration), {BackgroundColor3 = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].QuarBg}):Play()
                    PlayTween(switchCircle, TweenInfo.new(duration), {Position = toggled and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = toggled and Themes[Options.Theme].Text or Themes[Options.Theme].SubText}):Play()
                else
                    switchBg.Visible = false; checkBg.Visible = true
                    PlayTween(checkBg, TweenInfo.new(duration), {BackgroundColor3 = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].QuarBg}):Play()
                    PlayTween(checkInner, TweenInfo.new(duration), {Size = toggled and UDim2.new(1, -6, 1, -6) or UDim2.new(0, 0, 0, 0)}):Play()
                end
                if not themeUpdate then PlayTween(stroke, TweenInfo.new(duration), {Color = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].Stroke}):Play() else stroke.Color = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].Stroke end
            end
            table.insert(Registries.Toggle, syncVisuals)
            toggleButton.MouseButton1Click:Connect(function() toggled = not toggled; syncVisuals(); pcall(callback, toggled) end)
            toggleButton.MouseEnter:Connect(function() PlayTween(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play() end)
            toggleButton.MouseLeave:Connect(function() PlayTween(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play() end)
            syncVisuals(true)
        end

        CreateSettingsToggle("Performance Mode (FPS Boost)", function(state)
            if state then
                local Lighting = game:GetService("Lighting")
                local StoredAtmosphere = Lighting:FindFirstChild("Atmosphere")
                if StoredAtmosphere then StoredAtmosphere.Parent = nil end
                Lighting.GlobalShadows = false
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then v.Material = Enum.Material.SmoothPlastic; v.CastShadow = false
                    elseif v:IsA("Texture") or v:IsA("Decal") then v.Transparency = 1
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled = false end
                end
                FPSCleanup = function()
                    Lighting.GlobalShadows = true
                    if StoredAtmosphere then StoredAtmosphere.Parent = Lighting end
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then v.Material = Enum.Material.Plastic; v.CastShadow = true
                        elseif v:IsA("Texture") or v:IsA("Decal") then v.Transparency = 0
                        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled = true end
                    end
                end
            else
                if FPSCleanup then FPSCleanup() FPSCleanup = nil end
            end
        end)

        CreateSettingsSection("Developer")
        CreateSettingsButton("Load Remotespy", function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-RemoteSpy-for-Xeno-and-Solara-32578"))() end)
        CreateSettingsButton("Load DevEx", function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Dex-with-tags-78265"))() end)

        local function ToggleSettings()
            if SettingsOverlay.Visible then
                PlayTween(SettingsOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                PlayTween(SettingsFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 0.5, 10), BackgroundTransparency = 1}):Play()
                task.delay(0.2, function() SettingsOverlay.Visible = false end)
            else
                SettingsOverlay.Visible = true; SettingsOverlay.BackgroundTransparency = 1; SettingsFrame.Position = UDim2.new(0.5, 0, 0.5, 10); SettingsFrame.BackgroundTransparency = 1
                PlayTween(SettingsOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
                PlayTween(SettingsFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0}):Play()
            end
        end

        SettingsButton.MouseButton1Click:Connect(ToggleSettings)
        CloseSettingsButton.MouseButton1Click:Connect(ToggleSettings)
        SettingsOverlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local pos = input.Position; local framePos = SettingsFrame.AbsolutePosition; local frameSize = SettingsFrame.AbsoluteSize
                if pos.X < framePos.X or pos.X > framePos.X + frameSize.X or pos.Y < framePos.Y or pos.Y > framePos.Y + frameSize.Y then ToggleSettings() end
            end
        end)

        local dragging, dragStart, startPos
        TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; dragStart = input.Position; startPos = MainFrame.Position
                local connection; connection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false; connection:Disconnect() end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        CloseButton.MouseEnter:Connect(function() PlayTween(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}):Play() end)
        CloseButton.MouseLeave:Connect(function() PlayTween(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}):Play() end)
        
        local toggleConnection
        CloseButton.MouseButton1Click:Connect(function()
            if FPSCleanup then FPSCleanup() end
            for _, conn in ipairs(window.connections) do conn:Disconnect() end
            for _, func in ipairs(window.cleanupFunctions) do pcall(func) end
            PlayTween(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
            task.wait(0.3); ScreenGui:Destroy()
        end)

        local function MinimizeUI()
            Minimized = not Minimized
            
            -- Preserve Layout specific visibility
            if Minimized then
                TabContainer.Visible = false; ContentFrame.Visible = false; NavDropdownFrame.Visible = false
            else
                ContentFrame.Visible = true
                if Options.MenuStyle == "Sidebar" then TabContainer.Visible = true
                elseif Options.MenuStyle == "Dropdown" then NavDropdownFrame.Visible = true end
            end
            
            PlayTween(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = Minimized and UDim2.new(0, 600, 0, 40) or UDim2.new(0, 600, 0, 450)}):Play()
        end
        MinimizeButton.MouseButton1Click:Connect(MinimizeUI)

        local UIVisible = true
        local function ToggleUI()
            UIVisible = not UIVisible
            if UIVisible then MainFrame.Visible = true; PlayTween(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 600, 0, 450)}):Play()
            else PlayTween(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play(); task.delay(0.3, function() if not UIVisible then MainFrame.Visible = false end end) end
        end

        local collapseKey = Enum.KeyCode.Insert
        local waitingForCollapseKey = false

        CollapseKeybindButton.MouseButton1Click:Connect(function()
            if waitingForCollapseKey then return end
            waitingForCollapseKey = true; CollapseKeybindButton.Text = "..."
            local connection; connection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    collapseKey = input.KeyCode; local keyName = input.KeyCode.Name; if #keyName > 5 then keyName = keyName:sub(1, 4) end
                    CollapseKeybindButton.Text = keyName; waitingForCollapseKey = false; connection:Disconnect()
                end
            end)
        end)

        toggleConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == collapseKey then ToggleUI() end
        end)
        table.insert(window.connections, toggleConnection)

        function window:SwitchToTab(tabToSelect)
            NavDropdownBtn.Text = tabToSelect.Name
            for _, tab in pairs(tabs) do
                tab.Page.Visible = false
                PlayTween(tab.Button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].SecBg, TextColor3 = Themes[Options.Theme].SubText}):Play()
            end
            tabToSelect.Page.Visible = true
            PlayTween(tabToSelect.Button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Accent, TextColor3 = Themes[Options.Theme].Text}):Play()
        end

        function window:CreateTab(name)
            local tab = { Name = name }
            local tabButton = CreateElement("TextButton", { Name = name .. "Tab", Parent = TabHolder, BackgroundTransparency = 0, BorderSizePixel = 0, Size = UDim2.new(1, -20, 0, 35), Font = Enum.Font.GothamBold, Text = name, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {BackgroundColor3 = "SecBg", TextColor3 = "SubText"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = tabButton})
            CreateElement("UIPadding", {Parent = tabButton, PaddingLeft = UDim.new(0, 10)})
            
            local page = CreateElement("ScrollingFrame", { Name = name .. "Page", Parent = ContentFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ScrollBarThickness = 2, Visible = false }, {ScrollBarImageColor3 = "Stroke"})
            CreateElement("UIListLayout", {Parent = page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
            CreateElement("UIPadding", {Parent = page, PaddingRight = UDim.new(0, 10), PaddingLeft = UDim.new(0, 5), PaddingTop = UDim.new(0, 5)})
            
            tab.Button = tabButton; tab.Page = page; table.insert(tabs, tab)
            tabButton.MouseEnter:Connect(function() if not page.Visible then PlayTween(tabButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play() end end)
            tabButton.MouseLeave:Connect(function() if not page.Visible then PlayTween(tabButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].SecBg}):Play() end end)
            tabButton.MouseButton1Click:Connect(function() window:SwitchToTab(tab) end)
            if #tabs == 1 then window:SwitchToTab(tab) end

            function tab:CreateButton(text, callback)
                local button = CreateElement("TextButton", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 35), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg", TextColor3 = "Text"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = button})
                local buttonStroke = CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = button}, {Color = "Stroke"})
                
                button.MouseEnter:Connect(function() PlayTween(button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play(); PlayTween(buttonStroke, TweenInfo.new(0.2), {Color = Themes[Options.Theme].Accent}):Play() end)
                button.MouseLeave:Connect(function() PlayTween(button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play(); PlayTween(buttonStroke, TweenInfo.new(0.2), {Color = Themes[Options.Theme].Stroke}):Play() end)
                button.MouseButton1Click:Connect(function() pcall(callback); PlayTween(button, TweenInfo.new(0.1), {Size = UDim2.new(1, -4, 0, 31)}):Play(); task.wait(0.1); PlayTween(button, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 35)}):Play() end)
                return button
            end

            function tab:CreateToggle(text, callback)
                local toggleFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 35), LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = toggleFrame})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = toggleFrame}, {Color = "Stroke"})
                
                CreateElement("TextLabel", { Parent = toggleFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.7, 0, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                local toggleButton = CreateElement("TextButton", { Parent = toggleFrame, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 40, 0, 20), Text = "" })
                
                local switchBg = CreateElement("Frame", { Parent = toggleButton, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0) }, {BackgroundColor3 = "QuarBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = switchBg})
                local switchIndicator = CreateElement("Frame", { Parent = switchBg, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.new(0, 16, 0, 16) }, {BackgroundColor3 = "SubText"})
                CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = switchIndicator})
                
                local checkBg = CreateElement("Frame", { Parent = toggleButton, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 20, 0, 20), Visible = false }, {BackgroundColor3 = "QuarBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = checkBg})
                local checkInner = CreateElement("Frame", { Parent = checkBg, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0) }, {BackgroundColor3 = "Accent"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 3), Parent = checkInner})

                local toggled = false
                local function syncVisuals(themeUpdate)
                    local duration = themeUpdate and 0 or 0.2
                    if Options.ToggleStyle == "Switch" then
                        switchBg.Visible = true; checkBg.Visible = false
                        PlayTween(switchBg, TweenInfo.new(duration), {BackgroundColor3 = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].QuarBg}):Play()
                        PlayTween(switchIndicator, TweenInfo.new(duration), {Position = toggled and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = toggled and Themes[Options.Theme].Text or Themes[Options.Theme].SubText}):Play()
                    else
                        switchBg.Visible = false; checkBg.Visible = true
                        PlayTween(checkBg, TweenInfo.new(duration), {BackgroundColor3 = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].QuarBg}):Play()
                        PlayTween(checkInner, TweenInfo.new(duration), {Size = toggled and UDim2.new(1, -6, 1, -6) or UDim2.new(0, 0, 0, 0)}):Play()
                    end
                end
                
                table.insert(Registries.Toggle, syncVisuals)
                toggleButton.MouseButton1Click:Connect(function() toggled = not toggled; syncVisuals(); pcall(callback, toggled) end)
                syncVisuals(true)
                return toggleFrame
            end

            function tab:CreateKeybind(text, callback)
                local keybindFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 35), LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = keybindFrame})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = keybindFrame}, {Color = "Stroke"})
                
                CreateElement("TextLabel", { Parent = keybindFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                local keybindButton = CreateElement("TextButton", { Parent = keybindFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 80, 0, 22), Font = Enum.Font.GothamBold, Text = "None", TextSize = 12 }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = keybindButton})
                local keybindStroke = CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = keybindButton}, {Color = "Stroke"})
                
                local currentKey = nil; local waiting = false
                keybindButton.MouseButton1Click:Connect(function()
                    if waiting then return end
                    waiting = true; keybindButton.Text = "..."; PlayTween(keybindStroke, TweenInfo.new(0.2), {Color = Themes[Options.Theme].Accent}):Play()
                    local connection; connection = UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            currentKey = input.KeyCode; keybindButton.Text = currentKey.Name; task.delay(0.2, function() waiting = false end)
                            PlayTween(keybindStroke, TweenInfo.new(0.2), {Color = Themes[Options.Theme].Stroke}):Play(); connection:Disconnect()
                        end
                    end)
                end)
                local lastInput = 0
                local keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if not gameProcessed and currentKey and not waiting and input.KeyCode == currentKey then
                        if os.clock() - lastInput < 0.3 then return end
                        lastInput = os.clock(); pcall(callback, currentKey)
                    end
                end)
                table.insert(window.connections, keybindConnection)
                return keybindFrame
            end

            function tab:CreateSlider(text, min, max, default, callback)
                local sliderFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 50), LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = sliderFrame})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = sliderFrame}, {Color = "Stroke"})
                
                CreateElement("TextLabel", { Parent = sliderFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(0.5, 0, 0.4, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                local valueLabel = CreateElement("TextLabel", { Parent = sliderFrame, BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 5), Size = UDim2.new(0.5, -10, 0.4, 0), Font = Enum.Font.Gotham, Text = tostring(default), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right }, {TextColor3 = "SubText"})
                local sliderBar = CreateElement("TextButton", { Parent = sliderFrame, BorderSizePixel = 0, Position = UDim2.new(0.025, 0, 0.65, 0), Size = UDim2.new(0.95, 0, 0.15, 0), Text = "" }, {BackgroundColor3 = "QuarBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderBar})
                
                local fill = CreateElement("Frame", { Parent = sliderBar, BorderSizePixel = 0, Size = UDim2.new((default - min) / (max - min), 0, 1, 0) }, {BackgroundColor3 = "Accent"})
                CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = fill})
                
                local isDragging = false
                local function updateSlider(inputPos)
                    local relativeX = inputPos.X - sliderBar.AbsolutePosition.X
                    local ratio = math.clamp(relativeX / sliderBar.AbsoluteSize.X, 0, 1)
                    local value = math.floor(min + ratio * (max - min) + 0.5)
                    fill.Size = UDim2.new(ratio, 0, 1, 0)
                    valueLabel.Text = tostring(value)
                    pcall(callback, value)
                end
                sliderBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isDragging = true; updateSlider(input.Position)
                        local conn; conn = input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then isDragging = false; conn:Disconnect() end
                        end)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input) if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input.Position) end end)
                return sliderFrame
            end

            function tab:CreateCycleButton(text, values, default, callback)
                local cycleFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 35), LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = cycleFrame})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = cycleFrame}, {Color = "Stroke"})
                
                CreateElement("TextLabel", { Parent = cycleFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                local cycleButton = CreateElement("TextButton", { Parent = cycleFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 100, 0, 22), Font = Enum.Font.GothamBold, Text = tostring(default or values[1] or "None"), TextSize = 12 }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = cycleButton})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = cycleButton}, {Color = "Stroke"})
                
                local idx = 1
                for i, v in ipairs(values) do if v == default then idx = i break end end
                local function update() local val = values[idx]; cycleButton.Text = tostring(val); pcall(callback, val) end
                
                cycleButton.MouseButton1Click:Connect(function()
                    if #values == 0 then return end
                    idx = idx + 1; if idx > #values then idx = 1 end
                    update()
                    PlayTween(cycleButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 90, 0, 18)}):Play()
                    task.wait(0.1); PlayTween(cycleButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 100, 0, 22)}):Play()
                end)
                return { Frame = cycleFrame, SetValues = function(self, newValues) values = newValues; idx = 1; if #values > 0 then cycleButton.Text = tostring(values[1]) else cycleButton.Text = "None" end end, SetValue = function(self, val) for i, v in ipairs(values) do if v == val then idx = i; cycleButton.Text = tostring(val); break end end end }
            end

            function tab:CreateDropdown(text, options, default, callback)
                local dropdownFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 45), ClipsDescendants = true, LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = dropdownFrame})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = dropdownFrame}, {Color = "Stroke"})
                CreateElement("TextLabel", { Parent = dropdownFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.5, 0, 0, 45), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})

                local dropdownButton = CreateElement("TextButton", { Parent = dropdownFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 120, 0, 30), Font = Enum.Font.GothamBold, Text = default or options[1] or "None", TextSize = 12, AutoButtonColor = false }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = dropdownButton})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = dropdownButton}, {Color = "Stroke"})
                
                local isOpen = false; local optionContainer
                dropdownButton.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        if optionContainer then optionContainer:Destroy() end
                        optionContainer = CreateElement("Frame", { Parent = dropdownFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(1, 0, 0, #options * 30) })
                        for i, opt in ipairs(options) do
                            local optBtn = CreateElement("TextButton", { Parent = optionContainer, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, (i-1)*30), Size = UDim2.new(1, -20, 0, 28), Font = Enum.Font.Gotham, Text = opt, TextSize = 12, AutoButtonColor = false }, {BackgroundColor3 = "TerBg", TextColor3 = "SubText"})
                            CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = optBtn})
                            optBtn.MouseEnter:Connect(function() PlayTween(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play() end)
                            optBtn.MouseLeave:Connect(function() PlayTween(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play() end)
                            optBtn.MouseButton1Click:Connect(function() dropdownButton.Text = opt; isOpen = false; PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45)}):Play(); task.delay(0.2, function() if optionContainer then optionContainer:Destroy() end end); pcall(callback, opt) end)
                        end
                        PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45 + (#options * 30) + 10)}):Play()
                    else
                        PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45)}):Play(); task.delay(0.2, function() if optionContainer then optionContainer:Destroy() end end)
                    end
                end)
                return dropdownFrame
            end

            function tab:CreateParagraph(title, content)
                local paragraphFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = paragraphFrame})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = paragraphFrame}, {Color = "Stroke"})
                CreateElement("TextLabel", { Parent = paragraphFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(1, -20, 0, 15), Font = Enum.Font.GothamBold, Text = title, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                CreateElement("TextLabel", { Parent = paragraphFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 30), Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Gotham, Text = content, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true }, {TextColor3 = "SubText"})
                CreateElement("UIPadding", {Parent = paragraphFrame, PaddingBottom = UDim.new(0, 10)})
                return paragraphFrame
            end

            return tab
        end

        function window:OnClose(callback) table.insert(window.cleanupFunctions, callback) end
        
        function UILibrary:Notify(args)
            local notificationGui = game:GetService("CoreGui"):FindFirstChild("CustomNotificationGui")
            if not notificationGui then
                notificationGui = Instance.new("ScreenGui"); notificationGui.Name = "CustomNotificationGui"; notificationGui.Parent = game:GetService("CoreGui"); notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; notificationGui.ResetOnSpawn = false
                local container = Instance.new("Frame"); container.Name = "Container"; container.Parent = notificationGui; container.BackgroundTransparency = 1; container.AnchorPoint = Vector2.new(1, 0); container.Position = UDim2.new(1, -20, 0, 80); container.Size = UDim2.new(0, 280, 0.5, 0)
                local layout = Instance.new("UIListLayout"); layout.Parent = container; layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 10); layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            end
            
            local container = notificationGui:FindFirstChild("Container")
            local title, content, duration = args.Title or "Notification", args.Content or "", args.Duration or 5
            
            local frame = CreateElement("TextButton", { Name = "Notification", Parent = container, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 60), AutoButtonColor = false, Text = "" }, {BackgroundColor3 = "SecBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = frame})
            local stroke = CreateElement("UIStroke", {Thickness = 1.5, Transparency = 0.2, Parent = frame}, {Color = "Accent"})
            
            CreateElement("TextLabel", { Parent = frame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(1, -20, 0, 20), Font = Enum.Font.GothamBold, Text = title, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
            CreateElement("TextLabel", { Parent = frame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 25), Size = UDim2.new(1, -20, 1, -30), Font = Enum.Font.Gotham, Text = content, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true }, {TextColor3 = "SubText"})
            
            PlayTween(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
            local function close()
                if not frame.Parent then return end
                local tween = PlayTween(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1.2, 0, 0, 0)})
                tween.Completed:Connect(function() frame:Destroy() end); tween:Play()
            end
            frame.MouseButton1Click:Connect(close); task.delay(duration, close)
        end
        
        -- Initialize the correct layout immediately on startup
        for _, func in ipairs(Registries.MenuLayout) do func(Options.MenuStyle) end
        
        return window
    end
    return UILibrary
end)()

return UILibrary
