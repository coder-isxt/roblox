-- // IMPORTS // --
local UILibrary = (function()
    local UILibrary = {}
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local HttpService = game:GetService("HttpService")

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
        ToggleStyle = "Switch", -- "Switch", "Checkbox", "Pill", "Dot"
        CornerStyle = "Rounded", -- "Rounded", "Slight", "Blocky"
        StrokeStyle = "Outline", -- "None", "Outline", "Glow", "TwoCornerFade", "SoftFade"
        SliderStyle = "Line", -- "Line", "Pill", "Block"
        ComboStyle = "Classic", -- "Classic", "Compact", "Soft"
        Font = "Gotham", -- FontMap keys
        MenuStyle = "Sidebar" -- "Sidebar", "TopBar", "Dropdown", "Tablet"
    }

    local MenuStyleSet = {
        Sidebar = true,
        TopBar = true,
        Dropdown = true,
        Tablet = true
    }

    local Themes = {
        Default = { MainBg = Color3.fromRGB(10, 10, 10), SecBg = Color3.fromRGB(20, 20, 20), TerBg = Color3.fromRGB(25, 25, 25), QuarBg = Color3.fromRGB(40, 40, 40), Hover = Color3.fromRGB(35, 35, 35), Accent = Color3.fromRGB(220, 40, 40), Text = Color3.fromRGB(255, 255, 255), SubText = Color3.fromRGB(150, 150, 150), Stroke = Color3.fromRGB(50, 50, 50) },
        Dark = { MainBg = Color3.fromRGB(15, 15, 15), SecBg = Color3.fromRGB(22, 22, 22), TerBg = Color3.fromRGB(30, 30, 30), QuarBg = Color3.fromRGB(45, 45, 45), Hover = Color3.fromRGB(50, 50, 50), Accent = Color3.fromRGB(150, 80, 255), Text = Color3.fromRGB(240, 240, 240), SubText = Color3.fromRGB(170, 170, 170), Stroke = Color3.fromRGB(70, 70, 70) },
        Light = { MainBg = Color3.fromRGB(245, 245, 245), SecBg = Color3.fromRGB(230, 230, 230), TerBg = Color3.fromRGB(215, 215, 215), QuarBg = Color3.fromRGB(200, 200, 200), Hover = Color3.fromRGB(180, 180, 180), Accent = Color3.fromRGB(50, 130, 255), Text = Color3.fromRGB(20, 20, 20), SubText = Color3.fromRGB(100, 100, 100), Stroke = Color3.fromRGB(180, 180, 180) },
        Discord = { MainBg = Color3.fromRGB(54, 57, 63), SecBg = Color3.fromRGB(47, 49, 54), TerBg = Color3.fromRGB(64, 68, 75), QuarBg = Color3.fromRGB(79, 84, 92), Hover = Color3.fromRGB(114, 118, 125), Accent = Color3.fromRGB(88, 101, 242), Text = Color3.fromRGB(255, 255, 255), SubText = Color3.fromRGB(185, 187, 190), Stroke = Color3.fromRGB(32, 34, 37) },
        Midnight = { MainBg = Color3.fromRGB(8, 12, 20), SecBg = Color3.fromRGB(14, 20, 32), TerBg = Color3.fromRGB(18, 27, 40), QuarBg = Color3.fromRGB(28, 39, 58), Hover = Color3.fromRGB(36, 49, 72), Accent = Color3.fromRGB(94, 150, 255), Text = Color3.fromRGB(234, 241, 255), SubText = Color3.fromRGB(145, 164, 198), Stroke = Color3.fromRGB(48, 65, 95) },
        Mint = { MainBg = Color3.fromRGB(14, 26, 24), SecBg = Color3.fromRGB(20, 35, 33), TerBg = Color3.fromRGB(25, 43, 40), QuarBg = Color3.fromRGB(34, 57, 53), Hover = Color3.fromRGB(43, 71, 67), Accent = Color3.fromRGB(59, 216, 170), Text = Color3.fromRGB(226, 255, 246), SubText = Color3.fromRGB(148, 196, 180), Stroke = Color3.fromRGB(57, 88, 80) },
        Rose = { MainBg = Color3.fromRGB(30, 16, 20), SecBg = Color3.fromRGB(39, 21, 26), TerBg = Color3.fromRGB(47, 25, 32), QuarBg = Color3.fromRGB(61, 33, 42), Hover = Color3.fromRGB(75, 43, 54), Accent = Color3.fromRGB(255, 103, 148), Text = Color3.fromRGB(255, 235, 242), SubText = Color3.fromRGB(201, 151, 169), Stroke = Color3.fromRGB(94, 56, 70) },
        Ocean = { MainBg = Color3.fromRGB(9, 20, 31), SecBg = Color3.fromRGB(13, 29, 44), TerBg = Color3.fromRGB(18, 38, 56), QuarBg = Color3.fromRGB(26, 52, 74), Hover = Color3.fromRGB(34, 67, 95), Accent = Color3.fromRGB(64, 188, 255), Text = Color3.fromRGB(231, 245, 255), SubText = Color3.fromRGB(145, 178, 201), Stroke = Color3.fromRGB(47, 81, 109) },
        Forest = { MainBg = Color3.fromRGB(15, 21, 14), SecBg = Color3.fromRGB(22, 31, 20), TerBg = Color3.fromRGB(28, 40, 26), QuarBg = Color3.fromRGB(38, 53, 35), Hover = Color3.fromRGB(48, 68, 45), Accent = Color3.fromRGB(124, 204, 96), Text = Color3.fromRGB(238, 248, 232), SubText = Color3.fromRGB(163, 191, 156), Stroke = Color3.fromRGB(61, 84, 57) },
        Ember = { MainBg = Color3.fromRGB(24, 12, 9), SecBg = Color3.fromRGB(33, 17, 13), TerBg = Color3.fromRGB(42, 22, 17), QuarBg = Color3.fromRGB(56, 30, 23), Hover = Color3.fromRGB(72, 38, 28), Accent = Color3.fromRGB(255, 124, 64), Text = Color3.fromRGB(255, 238, 226), SubText = Color3.fromRGB(207, 164, 141), Stroke = Color3.fromRGB(91, 53, 40) }
    }

    local FontMap = {
        Gotham = { Regular = Enum.Font.Gotham, Bold = Enum.Font.GothamBold, Black = Enum.Font.GothamBlack },
        Ubuntu = { Regular = Enum.Font.Ubuntu, Bold = Enum.Font.Ubuntu, Black = Enum.Font.Ubuntu },
        Code = { Regular = Enum.Font.Code, Bold = Enum.Font.Code, Black = Enum.Font.Code },
        Jura = { Regular = Enum.Font.Jura, Bold = Enum.Font.Jura, Black = Enum.Font.Jura },
        SciFi = { Regular = Enum.Font.SciFi, Bold = Enum.Font.SciFi, Black = Enum.Font.SciFi },
        Arcade = { Regular = Enum.Font.Arcade, Bold = Enum.Font.Arcade, Black = Enum.Font.Arcade },
        Highway = { Regular = Enum.Font.Highway, Bold = Enum.Font.Highway, Black = Enum.Font.Highway },
        Garamond = { Regular = Enum.Font.Garamond, Bold = Enum.Font.Garamond, Black = Enum.Font.Garamond },
        Fantasy = { Regular = Enum.Font.Fantasy, Bold = Enum.Font.Fantasy, Black = Enum.Font.Fantasy },
        Bodoni = { Regular = Enum.Font.Bodoni, Bold = Enum.Font.Bodoni, Black = Enum.Font.Bodoni },
        SourceSans = { Regular = Enum.Font.SourceSans, Bold = Enum.Font.SourceSansBold, Black = Enum.Font.SourceSansBold }
    }

    local ToggleStyleSet = { Switch = true, Checkbox = true, Pill = true, Dot = true }
    local CornerStyleSet = { Rounded = true, Slight = true, Blocky = true }
    local StrokeStyleSet = { None = true, Outline = true, Glow = true, TwoCornerFade = true, SoftFade = true }
    local SliderStyleSet = { Line = true, Pill = true, Block = true }
    local ComboStyleSet = { Classic = true, Compact = true, Soft = true }

    local PersistConfig = {
        SchemaVersion = 2,
        Folder = "XenoUILibrary",
        FileName = "settings.json",
        Data = {
            Meta = {
                Version = 2
            },
            LibraryOptions = {},
            Values = {}
        },
        RuntimeValues = {}
    }

    local function CanPersist()
        return typeof(writefile) == "function"
            and typeof(readfile) == "function"
            and typeof(isfile) == "function"
            and typeof(makefolder) == "function"
    end

    local function EnsureConfigFolder()
        if not CanPersist() then return end
        if typeof(isfolder) == "function" then
            if not isfolder(PersistConfig.Folder) then
                pcall(makefolder, PersistConfig.Folder)
            end
        else
            pcall(makefolder, PersistConfig.Folder)
        end
    end

    local function EncodePersistValue(value)
        local valueType = typeof(value)
        if valueType == "nil" or valueType == "number" or valueType == "string" or valueType == "boolean" then
            return value
        end

        if valueType == "Color3" then
            return {
                __type = "Color3",
                r = value.R,
                g = value.G,
                b = value.B
            }
        end

        if valueType == "EnumItem" then
            return {
                __type = "EnumItem",
                enumType = tostring(value.EnumType),
                name = value.Name
            }
        end

        if valueType == "table" then
            local encoded = {}
            for key, subValue in pairs(value) do
                encoded[key] = EncodePersistValue(subValue)
            end
            return encoded
        end

        return nil
    end

    local function DecodePersistValue(value)
        if typeof(value) ~= "table" then
            return value
        end

        if value.__type == "Color3" then
            return Color3.new(value.r or 0, value.g or 0, value.b or 0)
        end

        if value.__type == "EnumItem" then
            local enumName = string.match(value.enumType or "", "^Enum%.(.+)$")
            if enumName and Enum[enumName] and value.name then
                return Enum[enumName][value.name]
            end
            return nil
        end

        local decoded = {}
        for key, subValue in pairs(value) do
            decoded[key] = DecodePersistValue(subValue)
        end
        return decoded
    end

    local function SavePersistConfig()
        if not CanPersist() then return false end

        EnsureConfigFolder()
        PersistConfig.Data.Meta = PersistConfig.Data.Meta or {}
        PersistConfig.Data.Meta.Version = PersistConfig.SchemaVersion

        local ok, encoded = pcall(function()
            return HttpService:JSONEncode(PersistConfig.Data)
        end)
        if not ok then return false end

        local path = PersistConfig.Folder .. "/" .. PersistConfig.FileName
        local writeOk = pcall(writefile, path, encoded)
        return writeOk
    end

    local function LoadPersistConfig()
        if not CanPersist() then return end

        PersistConfig.Data = {
            Meta = {
                Version = PersistConfig.SchemaVersion
            },
            LibraryOptions = {},
            Values = {}
        }

        EnsureConfigFolder()
        local path = PersistConfig.Folder .. "/" .. PersistConfig.FileName
        if not isfile(path) then return end

        local readOk, rawData = pcall(readfile, path)
        if not readOk or type(rawData) ~= "string" or rawData == "" then return end

        local decodeOk, decoded = pcall(function()
            return HttpService:JSONDecode(rawData)
        end)
        if not decodeOk or type(decoded) ~= "table" then return end

        local migrated = decoded
        if migrated.Meta == nil and (type(migrated.LibraryOptions) == "table" or type(migrated.Values) == "table") then
            migrated = {
                Meta = {
                    Version = 1
                },
                LibraryOptions = migrated.LibraryOptions or {},
                Values = migrated.Values or {}
            }
        end

        if type(migrated.Meta) ~= "table" then
            migrated.Meta = { Version = 1 }
        end

        local version = tonumber(migrated.Meta.Version) or 1
        if version < 2 then
            migrated.Meta.Version = 2
        end

        if type(migrated.LibraryOptions) == "table" then
            PersistConfig.Data.LibraryOptions = migrated.LibraryOptions
        end
        if type(migrated.Values) == "table" then
            PersistConfig.Data.Values = migrated.Values
        end
        PersistConfig.Data.Meta = migrated.Meta

        if version < PersistConfig.SchemaVersion then
            SavePersistConfig()
        end
    end

    local function ApplyLoadedLibraryOptions()
        local savedOptions = PersistConfig.Data.LibraryOptions
        if type(savedOptions) ~= "table" then return end

        if Themes[savedOptions.Theme] then
            Options.Theme = savedOptions.Theme
        end
        if ToggleStyleSet[savedOptions.ToggleStyle] then
            Options.ToggleStyle = savedOptions.ToggleStyle
        end
        if savedOptions.CornerStyle == "Glow" then
            Options.StrokeStyle = "Glow"
        elseif CornerStyleSet[savedOptions.CornerStyle] then
            Options.CornerStyle = savedOptions.CornerStyle
        end
        if StrokeStyleSet[savedOptions.StrokeStyle] then
            Options.StrokeStyle = savedOptions.StrokeStyle
        end
        if SliderStyleSet[savedOptions.SliderStyle] then
            Options.SliderStyle = savedOptions.SliderStyle
        end
        if ComboStyleSet[savedOptions.ComboStyle] then
            Options.ComboStyle = savedOptions.ComboStyle
        end
        if FontMap[savedOptions.Font] then
            Options.Font = savedOptions.Font
        end
        local savedMenuStyle = savedOptions.MenuStyle
        if savedMenuStyle == "Topbar" then
            savedMenuStyle = "TopBar"
        elseif savedMenuStyle == "SidebarCompact" or savedMenuStyle == "SidebarMini" or savedMenuStyle == "Minimal" then
            savedMenuStyle = "Sidebar"
        elseif savedMenuStyle == "DropdownCompact" or savedMenuStyle == "FloatingDropdown" or savedMenuStyle == "FloatingLeft" or savedMenuStyle == "FloatingRight" then
            savedMenuStyle = "Dropdown"
        elseif savedMenuStyle == "Dashboard" then
            savedMenuStyle = "TopBar"
        end
        if MenuStyleSet[savedMenuStyle] then
            Options.MenuStyle = savedMenuStyle
        end
    end

    local function SaveLibraryOptions()
        PersistConfig.Data.LibraryOptions = {
            Theme = Options.Theme,
            ToggleStyle = Options.ToggleStyle,
            CornerStyle = Options.CornerStyle,
            StrokeStyle = Options.StrokeStyle,
            SliderStyle = Options.SliderStyle,
            ComboStyle = Options.ComboStyle,
            Font = Options.Font,
            MenuStyle = Options.MenuStyle
        }
        SavePersistConfig()
    end

    LoadPersistConfig()
    ApplyLoadedLibraryOptions()

    function UILibrary:SetConfigStorage(folderName, fileName)
        if type(folderName) == "string" and folderName ~= "" then
            PersistConfig.Folder = folderName
        end
        if type(fileName) == "string" and fileName ~= "" then
            PersistConfig.FileName = fileName
        end

        PersistConfig.RuntimeValues = {}
        LoadPersistConfig()
        ApplyLoadedLibraryOptions()
        SaveLibraryOptions()
        return self
    end

    function UILibrary:RegisterValue(key, defaultValue, onLoad)
        if type(key) ~= "string" or key == "" then
            error("RegisterValue key must be a non-empty string", 2)
        end

        local saved = PersistConfig.Data.Values[key]
        local hasSaved = saved ~= nil
        local decodedValue = hasSaved and DecodePersistValue(saved) or nil
        local resolvedValue = hasSaved and decodedValue
        if hasSaved and resolvedValue == nil and defaultValue ~= nil then
            resolvedValue = defaultValue
        end
        if not hasSaved then
            resolvedValue = defaultValue
        end
        PersistConfig.RuntimeValues[key] = resolvedValue

        if not hasSaved then
            PersistConfig.Data.Values[key] = EncodePersistValue(defaultValue)
            SavePersistConfig()
        end

        if type(onLoad) == "function" then
            pcall(onLoad, resolvedValue, hasSaved)
        end

        local handle = {}

        function handle:Get()
            return PersistConfig.RuntimeValues[key]
        end

        function handle:Set(newValue)
            PersistConfig.RuntimeValues[key] = newValue
            PersistConfig.Data.Values[key] = EncodePersistValue(newValue)
            SavePersistConfig()
            return newValue
        end

        function handle:Reset()
            return self:Set(defaultValue)
        end

        function handle:Save()
            PersistConfig.Data.Values[key] = EncodePersistValue(PersistConfig.RuntimeValues[key])
            SavePersistConfig()
        end

        return handle
    end

    function UILibrary:GetValue(key, fallback)
        local value = PersistConfig.RuntimeValues[key]
        if value == nil then
            return fallback
        end
        return value
    end

    -- // REGISTRIES (SPLIT BY TYPE) // --
    local Registries = {
        Theme = {},
        Font = {},
        Corner = {},
        Toggle = {},
        Slider = {},
        Combo = {},
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
        elseif class == "UIStroke" then
            pcall(function()
                element.LineJoinMode = Enum.LineJoinMode.Round
            end)
            pcall(function()
                element.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            end)
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

    local function ApplyStrokeStyleVisuals(themeUpdate)
        local styleName = Options.StrokeStyle
        local colors = Themes[Options.Theme]
        for _, item in ipairs(Registries.Theme) do
            if item.Instance and item.Instance.Parent and item.Instance:IsA("UIStroke") and item.Property == "Color" and item.Role == "Stroke" then
                pcall(function()
                    item.Instance.LineJoinMode = Enum.LineJoinMode.Round
                    item.Instance.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                end)
                local targetThickness = 1
                local targetColor = colors.Stroke
                local targetTransparency = 0
                local gradientTransparency = nil

                if styleName == "None" then
                    targetThickness = 0
                    targetTransparency = 1
                elseif styleName == "Glow" then
                    targetThickness = 1.8
                    targetColor = colors.Accent
                    targetTransparency = 0.12
                elseif styleName == "TwoCornerFade" then
                    gradientTransparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(0.18, 0.9),
                        NumberSequenceKeypoint.new(0.5, 1),
                        NumberSequenceKeypoint.new(0.82, 0.9),
                        NumberSequenceKeypoint.new(1, 0)
                    })
                elseif styleName == "SoftFade" then
                    targetTransparency = 0.15
                    gradientTransparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.2),
                        NumberSequenceKeypoint.new(0.5, 0.65),
                        NumberSequenceKeypoint.new(1, 0.2)
                    })
                end

                if themeUpdate then
                    item.Instance.Thickness = targetThickness
                    item.Instance.Color = targetColor
                    item.Instance.Transparency = targetTransparency
                    item.Instance.Enabled = styleName ~= "None"
                else
                    PlayTween(item.Instance, TweenInfo.new(0.25), {
                        Thickness = targetThickness,
                        Color = targetColor,
                        Transparency = targetTransparency
                    }):Play()
                    item.Instance.Enabled = styleName ~= "None"
                end

                local gradient = item.Instance:FindFirstChild("__UILibStrokeGradient")
                if gradientTransparency then
                    if not gradient then
                        gradient = Instance.new("UIGradient")
                        gradient.Name = "__UILibStrokeGradient"
                        gradient.Parent = item.Instance
                    end
                    gradient.Rotation = 45
                    gradient.Transparency = gradientTransparency
                    gradient.Enabled = true
                elseif gradient then
                    gradient:Destroy()
                end
            end
        end
    end

    local function UpdateTheme(themeName)
        if not Themes[themeName] then return end
        Options.Theme = themeName; CleanRegistries()
        local themeColors = Themes[themeName]
        for _, item in ipairs(Registries.Theme) do
            if item.Instance and item.Instance.Parent then PlayTween(item.Instance, TweenInfo.new(0.3), {[item.Property] = themeColors[item.Role]}):Play() end
        end
        ApplyStrokeStyleVisuals(true)
        for _, syncFunc in ipairs(Registries.Toggle) do syncFunc(true) end
        for _, syncFunc in ipairs(Registries.Slider) do syncFunc(true) end
        for _, syncFunc in ipairs(Registries.Combo) do syncFunc(true) end
        for _, syncFunc in ipairs(Registries.MenuLayout) do syncFunc(Options.MenuStyle) end
        SaveLibraryOptions()
    end

    local function UpdateToggleStyles(styleName)
        if not ToggleStyleSet[styleName] then return end
        Options.ToggleStyle = styleName
        for _, syncFunc in ipairs(Registries.Toggle) do syncFunc() end
        SaveLibraryOptions()
    end
    local function UpdateMenuStyle(styleName)
        if styleName == "Topbar" then
            styleName = "TopBar"
        end
        if not MenuStyleSet[styleName] then
            return
        end
        Options.MenuStyle = styleName
        for _, syncFunc in ipairs(Registries.MenuLayout) do syncFunc(styleName) end
        SaveLibraryOptions()
    end

    local function UpdateFont(fontName)
        if not FontMap[fontName] then return end
        Options.Font = fontName; CleanRegistries()
        for _, item in ipairs(Registries.Font) do
            if item.Instance and item.Instance.Parent then item.Instance.Font = FontMap[fontName][item.Weight] or FontMap[fontName].Regular end
        end
        SaveLibraryOptions()
    end

    local function UpdateCornerStyle(styleName)
        if not CornerStyleSet[styleName] then return end
        Options.CornerStyle = styleName; CleanRegistries()
        for _, item in ipairs(Registries.Corner) do
            if item.Instance and item.Instance.Parent then
                local newRadius = item.Original
                if styleName == "Blocky" then newRadius = UDim.new(0, 0)
                elseif styleName == "Slight" then
                    if item.Original.Scale ~= 1 then newRadius = UDim.new(0, math.floor(item.Original.Offset / 2)) end
                end
                PlayTween(item.Instance, TweenInfo.new(0.3), {CornerRadius = newRadius}):Play()
            end
        end
        SaveLibraryOptions()
    end

    local function UpdateStrokeStyle(styleName)
        if not StrokeStyleSet[styleName] then return end
        Options.StrokeStyle = styleName
        ApplyStrokeStyleVisuals(false)
        SaveLibraryOptions()
    end

    local function UpdateSliderStyle(styleName)
        if not SliderStyleSet[styleName] then return end
        Options.SliderStyle = styleName
        for _, syncFunc in ipairs(Registries.Slider) do syncFunc() end
        SaveLibraryOptions()
    end

    local function UpdateComboStyle(styleName)
        if not ComboStyleSet[styleName] then return end
        Options.ComboStyle = styleName
        for _, syncFunc in ipairs(Registries.Combo) do syncFunc() end
        SaveLibraryOptions()
    end

    -- // TOOLTIPS // --
    local TooltipGui = Instance.new("ScreenGui",game.CoreGui)
    TooltipGui.Name = "UILibTooltips"
    TooltipGui.IgnoreGuiInset = true
    TooltipGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    TooltipGui.DisplayOrder = 10000

    local TooltipLabel = Instance.new("TextLabel",TooltipGui)
    TooltipLabel.Visible = false
    TooltipLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
    TooltipLabel.TextColor3 = Color3.new(1,1,1)
    TooltipLabel.Size = UDim2.new(0,220,0,30)
    TooltipLabel.ZIndex = 10001
    TooltipLabel.BorderSizePixel = 0
    TooltipLabel.TextXAlignment = Enum.TextXAlignment.Left
    TooltipLabel.Font = Enum.Font.Gotham
    TooltipLabel.TextSize = 12
    local TooltipPadding = Instance.new("UIPadding", TooltipLabel)
    TooltipPadding.PaddingLeft = UDim.new(0, 8)
    TooltipPadding.PaddingRight = UDim.new(0, 8)
    local TooltipCorner = Instance.new("UICorner", TooltipLabel)
    TooltipCorner.CornerRadius = UDim.new(0, 6)
    local TooltipStroke = Instance.new("UIStroke", TooltipLabel)
    TooltipStroke.Thickness = 1
    TooltipStroke.Color = Color3.fromRGB(55, 55, 55)

    local TooltipInputConnection = nil
    if not TooltipInputConnection then
        TooltipInputConnection = UserInputService.InputChanged:Connect(function(input)
            if TooltipLabel.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
                TooltipLabel.Position = UDim2.fromOffset(input.Position.X + 14, input.Position.Y + 14)
            end
        end)
    end

    function UILibrary:AddTooltip(instance,text)
        instance.MouseEnter:Connect(function()
            TooltipLabel.Text = text
            TooltipLabel.Visible = true
        end)

        instance.MouseLeave:Connect(function()
            TooltipLabel.Visible = false
        end)
    end


    function UILibrary:CreateWindow(title)
        local window = {}
        local tabs = {}
        local CurrentTab = nil

        window.connections = {}
        window.cleanupFunctions = {}
        local FPSCleanup = nil
        local Minimized = false
        
        local ScreenGui = CreateElement("ScreenGui", { Name = "UILibWindow", Parent = game:GetService("CoreGui"), ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false, IgnoreGuiInset = true })
        
        local MainFrame = CreateElement("Frame", { Name = "MainFrame", Parent = ScreenGui, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 560, 0, 420), ClipsDescendants = true, Visible = true }, {BackgroundColor3 = "MainBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = MainFrame})
        CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = MainFrame}, {Color = "Stroke"})
        local topBarHeight = 42
        local expandedWidth, expandedHeight = 560, 420
        local function ComputeWindowSize()
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
            local width = math.clamp(math.floor(viewport.X * 0.48), 480, 780)
            local height = math.clamp(math.floor(viewport.Y * 0.60), 380, 620)
            return width, height
        end
        local function UpdateWindowSize(animate)
            expandedWidth, expandedHeight = ComputeWindowSize()
            local targetSize = Minimized and UDim2.new(0, expandedWidth, 0, topBarHeight) or UDim2.new(0, expandedWidth, 0, expandedHeight)
            if animate then
                PlayTween(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
            else
                MainFrame.Size = targetSize
            end
        end
        UpdateWindowSize(false)
        
        local TopBar = CreateElement("Frame", { Name = "TopBar", Parent = MainFrame, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, topBarHeight) }, {BackgroundColor3 = "SecBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = TopBar})
        CreateElement("Frame", { Parent = TopBar, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 10) }, {BackgroundColor3 = "SecBg"})
        
        local TitleLabel = CreateElement("TextLabel", { Parent = TopBar, BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.45, 0, 1, 0), Font = Enum.Font.GothamBlack, Text = title or "UI Library", TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, }, {TextColor3 = "Text"})
        local TabletBackButton = CreateElement("TextButton", { Parent = TopBar, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0.5, -13), Size = UDim2.new(0, 34, 0, 26), Font = Enum.Font.GothamBold, Text = "<", TextSize = 16, Visible = false, ZIndex = 4 }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 7), Parent = TabletBackButton})
        
        -- // SEARCH BAR (TOPBAR) // --

        local function ApplySearch(query)
            if not CurrentTab then return end
            
            query = string.lower(query)

            for _, element in ipairs(CurrentTab.Elements) do
                if not element or not element.Parent then continue end
                
                if query == "" then
                    element.Visible = true
                else
                    local text = ""
                    
                    if element:IsA("TextButton") then
                        text = element.Text or ""
                    else
                        local label = element:FindFirstChildWhichIsA("TextLabel", true)
                        if label then
                            text = label.Text or ""
                        end
                    end
                    
                    element.Visible = string.find(string.lower(text), query) ~= nil
                end
            end
        end


        local SearchBox = CreateElement("TextBox", {
            Parent = TopBar,
            PlaceholderText = "Search...",
            Text = "",
            ClearTextOnFocus = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 170, 0, 28),
            Font = Enum.Font.Gotham,
            TextSize = 13
        }, {
            BackgroundColor3 = "TerBg",
            TextColor3 = "Text",
            PlaceholderColor3 = "SubText"
        })

        CreateElement("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = SearchBox
        })

        CreateElement("UIStroke", {
            Parent = SearchBox,
            Thickness = 1
        }, {
            Color = "Stroke"
        })

        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            ApplySearch(SearchBox.Text)
        end)



        local CloseButton = CreateElement("TextButton", { Parent = TopBar, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 26, 0, 26), Font = Enum.Font.GothamBold, Text = "X", TextSize = 13 }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 7), Parent = CloseButton})
        local MinimizeButton = CreateElement("TextButton", { Parent = TopBar, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -44, 0.5, 0), Size = UDim2.new(0, 26, 0, 26), Font = Enum.Font.GothamBold, Text = "-", TextSize = 14 }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 7), Parent = MinimizeButton})
        local CollapseKeybindButton = CreateElement("TextButton", { Parent = TopBar, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -78, 0.5, 0), Size = UDim2.new(0, 36, 0, 26), Font = Enum.Font.GothamBold, Text = "INS", TextSize = 10 }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 7), Parent = CollapseKeybindButton})
        local SettingsButton = CreateElement("TextButton", { Parent = TopBar, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -120, 0.5, 0), Size = UDim2.new(0, 36, 0, 26), Font = Enum.Font.GothamBold, Text = "CFG", TextSize = 10 }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 7), Parent = SettingsButton})

        -- Sidebar Navigation Components
        local TabContainer = CreateElement("Frame", { Name = "TabContainer", Parent = MainFrame, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, topBarHeight), Size = UDim2.new(0, 150, 1, -topBarHeight) }, {BackgroundColor3 = "SecBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 12), Parent = TabContainer})
        CreateElement("Frame", { Parent = TabContainer, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 12) }, {BackgroundColor3 = "SecBg"})
        CreateElement("Frame", { Parent = TabContainer, BorderSizePixel = 0, Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0, 12, 1, 0) }, {BackgroundColor3 = "SecBg"})

        

        local TabHolder = CreateElement("ScrollingFrame", { Name = "TabHolder", Parent = TabContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 0, BorderSizePixel = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y })
        local TabListLayout = CreateElement("UIListLayout", { Parent = TabHolder, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, FillDirection = Enum.FillDirection.Vertical })
        local TabPadding = CreateElement("UIPadding", {Parent = TabHolder, PaddingTop = UDim.new(0, 12)})
        
        local Separator = CreateElement("Frame", { Parent = MainFrame, BorderSizePixel = 0, Position = UDim2.new(0, 150, 0, topBarHeight), Size = UDim2.new(0, 1, 1, -topBarHeight), ZIndex = 5 }, {BackgroundColor3 = "Stroke"})
        local ContentFrame = CreateElement("Frame", { Name = "ContentFrame", Parent = MainFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 160, 0, topBarHeight + 8), Size = UDim2.new(1, -172, 1, -(topBarHeight + 20)) })
        local TabletHomeFrame = CreateElement("ScrollingFrame", { Name = "TabletHomeFrame", Parent = ContentFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ScrollBarThickness = 2, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y }, {ScrollBarImageColor3 = "Stroke"})
        local TabletGridPadding = CreateElement("UIPadding", { Parent = TabletHomeFrame, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) })
        local TabletGridLayout = CreateElement("UIGridLayout", { Parent = TabletHomeFrame, CellPadding = UDim2.new(0, 8, 0, 8), CellSize = UDim2.new(0.5, -8, 0, 72), SortOrder = Enum.SortOrder.LayoutOrder, FillDirectionMaxCells = 2 })

        -- Dropdown Navigation Components (V2)
        local NavDropdownFrame = CreateElement("Frame", { Parent = MainFrame, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, topBarHeight + 8), Size = UDim2.new(1, -20, 0, 32), ClipsDescendants = true, Visible = false, ZIndex = 10 }, {BackgroundColor3 = "TerBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = NavDropdownFrame})
        CreateElement("UIStroke", {Thickness = 1, Parent = NavDropdownFrame}, {Color = "Stroke"})

        local NavDropdownBtn = CreateElement("TextButton", { Parent = NavDropdownFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35), Font = Enum.Font.GothamBold, Text = "Select Tab", TextSize = 14, ZIndex = 11 }, {TextColor3 = "Text"})
        local NavDropdownIcon = CreateElement("TextLabel", { Parent = NavDropdownBtn, BackgroundTransparency = 1, Position = UDim2.new(1, -25, 0, 0), Size = UDim2.new(0, 20, 1, 0), Font = Enum.Font.GothamBold, Text = "v", TextSize = 12, ZIndex = 11 }, {TextColor3 = "SubText"})

        local NavIsOpen = false
        local NavOptionContainer = nil
        local ActiveNavRowHeight = 30
        local ActiveNavFrameSize = UDim2.new(1, -24, 0, 35)
        local ActiveNavFramePos = UDim2.new(0, 12, 0, 60)
        local ActiveNavAnchor = Vector2.new(0, 0)
        local CurrentTabButtonMode = "Sidebar"
        local TopTabWidth = 132
        local TopTabHeight = 28
        local ActiveLayoutState = {
            ShowSidebar = true,
            ShowSeparator = true,
            ShowDropdown = false
        }
        local IsTabletHomeVisible = false

        local function SetTabletBackVisible(visible)
            TabletBackButton.Visible = visible
            if visible then
                TitleLabel.Position = UDim2.new(0, 52, 0, 0)
                TitleLabel.Size = UDim2.new(0.38, 0, 1, 0)
            else
                TitleLabel.Position = UDim2.new(0, 14, 0, 0)
                TitleLabel.Size = UDim2.new(0.45, 0, 1, 0)
            end
        end

        local function UpdateTabletGridSizing()
            local width = math.max(ContentFrame.AbsoluteSize.X - 8, 300)
            local cols = 2
            if width >= 880 then
                cols = 4
            elseif width >= 640 then
                cols = 3
            end
            local gap = 8
            local cellW = math.floor((width - (gap * (cols - 1))) / cols)
            TabletGridLayout.FillDirectionMaxCells = cols
            TabletGridLayout.CellSize = UDim2.new(0, cellW, 0, 72)
        end

        local function ShowTabletHome()
            if Options.MenuStyle ~= "Tablet" then
                return
            end
            IsTabletHomeVisible = true
            TabletHomeFrame.Visible = true
            SetTabletBackVisible(false)
            for _, tab in pairs(tabs) do
                tab.Page.Visible = false
            end
        end

        local function GetTabButtonColors()
            if CurrentTabButtonMode == "Top" then
                return Themes[Options.Theme].TerBg, Themes[Options.Theme].QuarBg
            end
            return Themes[Options.Theme].SecBg, Themes[Options.Theme].TerBg
        end

        local function ApplyTabHolderMode(mode)
            CurrentTabButtonMode = mode or "Sidebar"
            if CurrentTabButtonMode == "Top" then
                TabHolder.Position = UDim2.new(0, 10, 0, 0)
                TabHolder.Size = UDim2.new(1, -20, 1, 0)
                TabHolder.AutomaticCanvasSize = Enum.AutomaticSize.X
                TabHolder.ScrollingDirection = Enum.ScrollingDirection.X
                TabHolder.ScrollBarThickness = 2
                TabListLayout.FillDirection = Enum.FillDirection.Horizontal
                TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                TabListLayout.Padding = UDim.new(0, 8)
                TabPadding.PaddingTop = UDim.new(0, 6)
                TabPadding.PaddingBottom = UDim.new(0, 6)
                TabPadding.PaddingLeft = UDim.new(0, 0)
                TabPadding.PaddingRight = UDim.new(0, 0)
            else
                TabHolder.Position = UDim2.new(0, 0, 0, 0)
                TabHolder.Size = UDim2.new(1, 0, 1, 0)
                TabHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
                TabHolder.ScrollingDirection = Enum.ScrollingDirection.Y
                TabHolder.ScrollBarThickness = 0
                TabListLayout.FillDirection = Enum.FillDirection.Vertical
                TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
                TabListLayout.Padding = UDim.new(0, 5)
                TabPadding.PaddingTop = UDim.new(0, 12)
                TabPadding.PaddingBottom = UDim.new(0, 0)
                TabPadding.PaddingLeft = UDim.new(0, 0)
                TabPadding.PaddingRight = UDim.new(0, 0)
            end
        end

        local function ApplyTabButtonMode(tabEntry)
            if not tabEntry or not tabEntry.Button or not tabEntry.ActiveRail then
                return
            end

            local tabButton = tabEntry.Button
            local activeRail = tabEntry.ActiveRail
            local buttonPadding = tabButton:FindFirstChildOfClass("UIPadding")
            local idleColor = GetTabButtonColors()

            if CurrentTabButtonMode == "Top" then
                tabButton.Size = UDim2.new(0, TopTabWidth, 0, TopTabHeight)
                tabButton.TextXAlignment = Enum.TextXAlignment.Center
                if buttonPadding then
                    buttonPadding.PaddingLeft = UDim.new(0, 0)
                    buttonPadding.PaddingRight = UDim.new(0, 0)
                end
                activeRail.Position = UDim2.new(0, 10, 1, -4)
                activeRail.Size = UDim2.new(1, -20, 0, 2)
            else
                tabButton.Size = UDim2.new(1, -18, 0, 38)
                tabButton.TextXAlignment = Enum.TextXAlignment.Left
                if buttonPadding then
                    buttonPadding.PaddingLeft = UDim.new(0, 14)
                    buttonPadding.PaddingRight = UDim.new(0, 0)
                end
                activeRail.Position = UDim2.new(0, 0, 0, 8)
                activeRail.Size = UDim2.new(0, 3, 1, -16)
            end

            if CurrentTab ~= tabEntry then
                tabButton.BackgroundColor3 = idleColor
            end
        end

        local function GetNavOpenSize()
            return UDim2.new(
                ActiveNavFrameSize.X.Scale,
                ActiveNavFrameSize.X.Offset,
                0,
                ActiveNavFrameSize.Y.Offset + (#tabs * ActiveNavRowHeight) + 10
            )
        end

        NavDropdownBtn.MouseButton1Click:Connect(function()
            NavIsOpen = not NavIsOpen
            if NavIsOpen then
                if NavOptionContainer then NavOptionContainer:Destroy() end
                NavOptionContainer = CreateElement("Frame", { Parent = NavDropdownFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, ActiveNavFrameSize.Y.Offset), Size = UDim2.new(1, 0, 0, #tabs * ActiveNavRowHeight), ZIndex = 10 })
                for i, tab in ipairs(tabs) do
                    local optBtn = CreateElement("TextButton", { Parent = NavOptionContainer, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, (i-1)*ActiveNavRowHeight), Size = UDim2.new(1, -20, 0, ActiveNavRowHeight - 2), Font = Enum.Font.Gotham, Text = tab.Name, TextSize = 12, AutoButtonColor = false, ZIndex = 11 }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
                    CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = optBtn})

                    optBtn.MouseEnter:Connect(function() PlayTween(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play() end)
                    optBtn.MouseLeave:Connect(function() PlayTween(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].QuarBg}):Play() end)

                    optBtn.MouseButton1Click:Connect(function()
                        window:SwitchToTab(tab)
                        NavIsOpen = false
                        PlayTween(NavDropdownFrame, TweenInfo.new(0.2), {Size = ActiveNavFrameSize}):Play()
                        PlayTween(NavDropdownIcon, TweenInfo.new(0.2), {Rotation = 0}):Play()
                        task.delay(0.2, function() if NavOptionContainer then NavOptionContainer:Destroy() end end)
                    end)
                end
                PlayTween(NavDropdownFrame, TweenInfo.new(0.2), {Size = GetNavOpenSize()}):Play()
                PlayTween(NavDropdownIcon, TweenInfo.new(0.2), {Rotation = 180}):Play()
            else
                PlayTween(NavDropdownFrame, TweenInfo.new(0.2), {Size = ActiveNavFrameSize}):Play()
                PlayTween(NavDropdownIcon, TweenInfo.new(0.2), {Rotation = 0}):Play()
                task.delay(0.2, function() if NavOptionContainer then NavOptionContainer:Destroy() end end)
            end
        end)

        -- Handle Layout Switching
        table.insert(Registries.MenuLayout, function(style)
            local preset = nil
            local sidebarDefault = 150
            local contentTop = topBarHeight + 8
            if style == "Sidebar" then
                preset = {
                    ShowSidebar = true,
                    ShowSeparator = true,
                    ShowDropdown = false,
                    TabMode = "Sidebar",
                    SidebarSize = UDim2.new(0, sidebarDefault, 1, -topBarHeight),
                    SidebarPos = UDim2.new(0, 0, 0, topBarHeight),
                    SeparatorPos = UDim2.new(0, sidebarDefault, 0, topBarHeight),
                    ContentPos = UDim2.new(0, sidebarDefault + 10, 0, contentTop),
                    ContentSize = UDim2.new(1, -(sidebarDefault + 22), 1, -(contentTop + 12)),
                    NavPos = UDim2.new(0, 10, 0, contentTop),
                    NavSize = UDim2.new(1, -20, 0, 32),
                    NavAnchor = Vector2.new(0, 0),
                    NavRow = 26
                }
            elseif style == "TopBar" then
                preset = {
                    ShowSidebar = true,
                    ShowSeparator = false,
                    ShowDropdown = false,
                    TabMode = "Top",
                    TopTabWidth = 128,
                    TopTabHeight = 28,
                    SidebarSize = UDim2.new(1, -20, 0, 40),
                    SidebarPos = UDim2.new(0, 10, 0, topBarHeight + 6),
                    SeparatorPos = UDim2.new(0, sidebarDefault, 0, topBarHeight),
                    ContentPos = UDim2.new(0, 10, 0, topBarHeight + 54),
                    ContentSize = UDim2.new(1, -20, 1, -(topBarHeight + 66)),
                    NavPos = UDim2.new(0, 10, 0, contentTop),
                    NavSize = UDim2.new(1, -20, 0, 32),
                    NavAnchor = Vector2.new(0, 0),
                    NavRow = 26
                }
            elseif style == "Dropdown" then
                preset = {
                    ShowSidebar = false,
                    ShowSeparator = false,
                    ShowDropdown = true,
                    TabMode = "Sidebar",
                    SidebarSize = UDim2.new(0, sidebarDefault, 1, -topBarHeight),
                    SidebarPos = UDim2.new(0, 0, 0, topBarHeight),
                    SeparatorPos = UDim2.new(0, sidebarDefault, 0, topBarHeight),
                    ContentPos = UDim2.new(0, 10, 0, topBarHeight + 48),
                    ContentSize = UDim2.new(1, -20, 1, -(topBarHeight + 60)),
                    NavPos = UDim2.new(0, 10, 0, contentTop),
                    NavSize = UDim2.new(1, -20, 0, 32),
                    NavAnchor = Vector2.new(0, 0),
                    NavRow = 26
                }
            elseif style == "Tablet" then
                preset = {
                    ShowSidebar = false,
                    ShowSeparator = false,
                    ShowDropdown = false,
                    TabMode = "Sidebar",
                    SidebarSize = UDim2.new(0, sidebarDefault, 1, -topBarHeight),
                    SidebarPos = UDim2.new(0, 0, 0, topBarHeight),
                    SeparatorPos = UDim2.new(0, sidebarDefault, 0, topBarHeight),
                    ContentPos = UDim2.new(0, 10, 0, contentTop),
                    ContentSize = UDim2.new(1, -20, 1, -(contentTop + 12)),
                    NavPos = UDim2.new(0, 10, 0, contentTop),
                    NavSize = UDim2.new(1, -20, 0, 32),
                    NavAnchor = Vector2.new(0, 0),
                    NavRow = 26
                }
            else
                preset = {
                    ShowSidebar = true,
                    ShowSeparator = true,
                    ShowDropdown = false,
                    TabMode = "Sidebar",
                    SidebarSize = UDim2.new(0, sidebarDefault, 1, -topBarHeight),
                    SidebarPos = UDim2.new(0, 0, 0, topBarHeight),
                    SeparatorPos = UDim2.new(0, sidebarDefault, 0, topBarHeight),
                    ContentPos = UDim2.new(0, sidebarDefault + 10, 0, contentTop),
                    ContentSize = UDim2.new(1, -(sidebarDefault + 22), 1, -(contentTop + 12)),
                    NavPos = UDim2.new(0, 10, 0, contentTop),
                    NavSize = UDim2.new(1, -20, 0, 32),
                    NavAnchor = Vector2.new(0, 0),
                    NavRow = 26
                }
            end

            ActiveNavFramePos = preset.NavPos
            ActiveNavFrameSize = preset.NavSize
            ActiveNavAnchor = preset.NavAnchor
            ActiveNavRowHeight = preset.NavRow
            TopTabWidth = preset.TopTabWidth or 132
            TopTabHeight = preset.TopTabHeight or 28
            ActiveLayoutState.ShowSidebar = preset.ShowSidebar
            ActiveLayoutState.ShowSeparator = preset.ShowSeparator
            ActiveLayoutState.ShowDropdown = preset.ShowDropdown

            ApplyTabHolderMode(preset.TabMode)
            for _, tab in pairs(tabs) do
                ApplyTabButtonMode(tab)
            end

            TabContainer.AnchorPoint = Vector2.new(0, 0)
            TabContainer.Position = preset.SidebarPos
            PlayTween(TabContainer, TweenInfo.new(0.25), {Size = preset.SidebarSize}):Play()
            PlayTween(Separator, TweenInfo.new(0.25), {Position = preset.SeparatorPos}):Play()
            NavDropdownFrame.AnchorPoint = ActiveNavAnchor
            NavDropdownFrame.Position = ActiveNavFramePos
            NavDropdownFrame.Size = ActiveNavFrameSize

            TabContainer.Visible = preset.ShowSidebar
            Separator.Visible = preset.ShowSeparator
            NavDropdownFrame.Visible = preset.ShowDropdown
            PlayTween(ContentFrame, TweenInfo.new(0.3), {Position = preset.ContentPos, Size = preset.ContentSize}):Play()
            UpdateTabletGridSizing()
            if style == "Tablet" then
                if IsTabletHomeVisible or not CurrentTab then
                    ShowTabletHome()
                else
                    window:SwitchToTab(CurrentTab)
                end
            else
                IsTabletHomeVisible = false
                TabletHomeFrame.Visible = false
                SetTabletBackVisible(false)
                if CurrentTab then
                    window:SwitchToTab(CurrentTab)
                end
            end
            if NavIsOpen then -- Auto-collapse dropdown if open during style switch
                NavIsOpen = false
                PlayTween(NavDropdownFrame, TweenInfo.new(0.2), {Size = ActiveNavFrameSize}):Play()
                PlayTween(NavDropdownIcon, TweenInfo.new(0.2), {Rotation = 0}):Play()
                if NavOptionContainer then NavOptionContainer:Destroy() end
            end
        end)

        -- // Settings Menu // --
        local SettingsOverlay = CreateElement("Frame", { Name = "SettingsOverlay", Parent = MainFrame, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, ZIndex = 20 })

        local SettingsFrame = CreateElement("Frame", { Name = "SettingsFrame", Parent = SettingsOverlay, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10), Size = UDim2.new(0, 560, 0, 390), ClipsDescendants = true }, {BackgroundColor3 = "SecBg"})
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
        local CurrentSettingsContainer = nil

        local function SwitchSettingsTab(name)
            for n, tab in pairs(SettingsTabs) do
                tab.Page.Visible = (n == name)
                if n == name then PlayTween(tab.Button, TweenInfo.new(0.2), {TextColor3 = Themes[Options.Theme].Text, BackgroundTransparency = 0.9}):Play()
                else PlayTween(tab.Button, TweenInfo.new(0.2), {TextColor3 = Themes[Options.Theme].SubText, BackgroundTransparency = 1}):Play() end
            end
            CurrentSettingsContainer = nil
        end

        local function CreateSettingsSection(text)
            if SettingsTabs[text] then return end
            local tabBtn = CreateElement("TextButton", { Parent = SettingsSidebar, BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(1, -10, 0, 30), Text = text, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, {TextColor3 = "SubText"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = tabBtn})
            CreateElement("UIPadding", {Parent = tabBtn, PaddingLeft = UDim.new(0, 10)})
            local page = CreateElement("ScrollingFrame", { Parent = SettingsContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y })
            CreateElement("UIListLayout", {Parent = page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
            CreateElement("UIPadding", {Parent = page, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})
            SettingsTabs[text] = {Button = tabBtn, Page = page}; CurrentSettingsPage = page; CurrentSettingsContainer = nil
            tabBtn.MouseButton1Click:Connect(function() SwitchSettingsTab(text) end)
            if not next(SettingsTabs, next(SettingsTabs)) then SwitchSettingsTab(text) end
        end

        local function ResolveSettingsParent()
            return CurrentSettingsContainer or CurrentSettingsPage
        end

        local function CreateSettingsGroup(groupTitle, expandedByDefault)
            local groupFrame = CreateElement("Frame", {
                Parent = CurrentSettingsPage,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = true
            }, {BackgroundColor3 = "TerBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = groupFrame})
            CreateElement("UIStroke", {Thickness = 1, Parent = groupFrame}, {Color = "Stroke"})

            local headerButton = CreateElement("TextButton", {
                Parent = groupFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 34),
                BorderSizePixel = 0,
                Text = ""
            })
            CreateElement("TextLabel", {
                Parent = headerButton,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -34, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = groupTitle,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            }, {TextColor3 = "Text"})
            local arrow = CreateElement("TextLabel", {
                Parent = headerButton,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.new(0, 16, 0, 16),
                Font = Enum.Font.GothamBold,
                Text = ">",
                TextSize = 12
            }, {TextColor3 = "SubText"})

            local content = CreateElement("Frame", {
                Parent = groupFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 34),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            CreateElement("UIListLayout", {Parent = content, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
            CreateElement("UIPadding", {Parent = content, PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)})

            local expanded = expandedByDefault ~= false
            local function syncGroup(animate)
                arrow.Rotation = expanded and 90 or 0
                if expanded then
                    content.Visible = true
                    content.AutomaticSize = Enum.AutomaticSize.Y
                else
                    content.AutomaticSize = Enum.AutomaticSize.None
                    content.Size = UDim2.new(1, 0, 0, 0)
                    content.Visible = false
                end
                if animate then
                    PlayTween(groupFrame, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play()
                end
            end

            headerButton.MouseButton1Click:Connect(function()
                expanded = not expanded
                syncGroup(true)
            end)
            headerButton.MouseEnter:Connect(function()
                PlayTween(groupFrame, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play()
            end)
            headerButton.MouseLeave:Connect(function()
                PlayTween(groupFrame, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play()
            end)

            syncGroup(false)
            CurrentSettingsContainer = content
            return groupFrame
        end

        local function CreateSettingsButton(text, callback)
            local button = CreateElement("TextButton", { Parent = ResolveSettingsParent(), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 40), AutoButtonColor = false, Text = "" }, {BackgroundColor3 = "TerBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = button})
            CreateElement("UIStroke", {Thickness = 1, Parent = button}, {Color = "Stroke"})
            CreateElement("TextLabel", { Parent = button, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(1, -15, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
            button.MouseEnter:Connect(function() PlayTween(button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play() end)
            button.MouseLeave:Connect(function() PlayTween(button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play() end)
            button.MouseButton1Click:Connect(function() pcall(callback); PlayTween(button, TweenInfo.new(0.1), {Size = UDim2.new(1, -2, 0, 38)}):Play(); task.wait(0.1); PlayTween(button, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 40)}):Play() end)
        end

        local function CreateSettingsDropdown(text, options, default, callback)
            local dropdownFrame = CreateElement("Frame", { Parent = ResolveSettingsParent(), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 45), ClipsDescendants = true }, {BackgroundColor3 = "TerBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = dropdownFrame})
            CreateElement("UIStroke", {Thickness = 1, Parent = dropdownFrame}, {Color = "Stroke"})
            local titleLabel = CreateElement("TextLabel", { Parent = dropdownFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(0.5, 0, 0, 45), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})

            local dropdownButton = CreateElement("TextButton", { Parent = dropdownFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -15, 0, 8), Size = UDim2.new(0, 120, 0, 28), Font = Enum.Font.GothamBold, Text = default or options[1] or "None", TextSize = 12, AutoButtonColor = false }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = dropdownButton})
            
            local isOpen = false; local optionContainer
            local headerHeight, rowHeight = 45, 30
            local function resolveComboMetrics()
                if Options.ComboStyle == "Compact" then
                    return 40, 26, 108, 24
                elseif Options.ComboStyle == "Soft" then
                    return 48, 32, 130, 32
                end
                return 45, 30, 120, 28
            end
            local function applyComboStyle(themeUpdate)
                local _, _, btnW, btnH = resolveComboMetrics()
                headerHeight, rowHeight = resolveComboMetrics()
                dropdownFrame.Size = UDim2.new(1, 0, 0, isOpen and (headerHeight + (#options * rowHeight) + 10) or headerHeight)
                titleLabel.Size = UDim2.new(0.5, 0, 0, headerHeight)
                dropdownButton.Position = UDim2.new(1, -15, 0, math.floor((headerHeight - btnH) / 2))
                dropdownButton.Size = UDim2.new(0, btnW, 0, btnH)
                if optionContainer then
                    optionContainer.Position = UDim2.new(0, 0, 0, headerHeight)
                    optionContainer.Size = UDim2.new(1, 0, 0, #options * rowHeight)
                    for i, child in ipairs(optionContainer:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.Position = UDim2.new(0, 10, 0, (i - 1) * rowHeight)
                            child.Size = UDim2.new(1, -20, 0, rowHeight - 2)
                        end
                    end
                end
            end
            table.insert(Registries.Combo, applyComboStyle)

            dropdownButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    if optionContainer then optionContainer:Destroy() end
                    optionContainer = CreateElement("Frame", { Parent = dropdownFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, headerHeight), Size = UDim2.new(1, 0, 0, #options * rowHeight) })
                    for i, opt in ipairs(options) do
                        local optBtn = CreateElement("TextButton", { Parent = optionContainer, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, (i-1)*rowHeight), Size = UDim2.new(1, -20, 0, rowHeight - 2), Font = Enum.Font.Gotham, Text = opt, TextSize = 12, AutoButtonColor = false }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
                        CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = optBtn})
                        optBtn.MouseEnter:Connect(function() PlayTween(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play() end)
                        optBtn.MouseLeave:Connect(function() PlayTween(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].QuarBg}):Play() end)
                        optBtn.MouseButton1Click:Connect(function() dropdownButton.Text = opt; isOpen = false; PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, headerHeight)}):Play(); task.delay(0.2, function() if optionContainer then optionContainer:Destroy() end end); pcall(callback, opt) end)
                    end
                    PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, headerHeight + (#options * rowHeight) + 10)}):Play()
                else
                    PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, headerHeight)}):Play(); task.delay(0.2, function() if optionContainer then optionContainer:Destroy() end end)
                end
            end)
            applyComboStyle(true)
        end

        -- // Initialize Global Settings Options //
        CreateSettingsSection("Appearance")
        CreateSettingsGroup("Visual Style", true)
        local ThemeOptions = {}
        for themeName, _ in pairs(Themes) do
            table.insert(ThemeOptions, themeName)
        end
        table.sort(ThemeOptions)
        CreateSettingsDropdown("Menu Style", {"Sidebar", "TopBar", "Dropdown", "Tablet"}, Options.MenuStyle, function(val) UpdateMenuStyle(val) end)
        CreateSettingsDropdown("Interface Theme", ThemeOptions, Options.Theme, function(val) UpdateTheme(val) end)
        CreateSettingsDropdown("Toggle Style", {"Switch", "Checkbox", "Pill", "Dot"}, Options.ToggleStyle, function(val) UpdateToggleStyles(val) end)
        CreateSettingsDropdown("Corner Style", {"Rounded", "Slight", "Blocky"}, Options.CornerStyle, function(val) UpdateCornerStyle(val) end)
        CreateSettingsDropdown("Stroke Style", {"None", "Outline", "Glow", "TwoCornerFade", "SoftFade"}, Options.StrokeStyle, function(val) UpdateStrokeStyle(val) end)
        CreateSettingsDropdown("Slider Style", {"Line", "Pill", "Block"}, Options.SliderStyle, function(val) UpdateSliderStyle(val) end)
        CreateSettingsDropdown("Combo Style", {"Classic", "Compact", "Soft"}, Options.ComboStyle, function(val) UpdateComboStyle(val) end)
        CreateSettingsDropdown("Global Font", {"Gotham", "Ubuntu", "Code", "Jura", "SciFi", "Arcade", "Highway", "Garamond", "Fantasy", "Bodoni", "SourceSans"}, Options.Font, function(val) UpdateFont(val) end)

        CreateSettingsSection("General")
        CreateSettingsGroup("Runtime", true)
        local function CreateSettingsToggle(text, callback)
            local toggleButton = CreateElement("TextButton", { Parent = ResolveSettingsParent(), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 45), AutoButtonColor = false, Text = "" }, {BackgroundColor3 = "TerBg"})
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
            local dotBg = CreateElement("Frame", { Parent = toggleContainer, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 22, 0, 22), Visible = false }, {BackgroundColor3 = "QuarBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = dotBg})
            local dotInner = CreateElement("Frame", { Parent = dotBg, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0) }, {BackgroundColor3 = "Accent"})
            CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = dotInner})
            
            local toggled = false
            local function syncVisuals(themeUpdate)
                local duration = themeUpdate and 0 or 0.2
                if Options.ToggleStyle == "Switch" or Options.ToggleStyle == "Pill" then
                    switchBg.Visible = true; checkBg.Visible = false; dotBg.Visible = false
                    if Options.ToggleStyle == "Pill" then
                        toggleContainer.Size = UDim2.new(0, 50, 0, 24)
                        switchCircle.Size = UDim2.new(0, 20, 0, 20)
                    else
                        toggleContainer.Size = UDim2.new(0, 44, 0, 22)
                        switchCircle.Size = UDim2.new(0, 18, 0, 18)
                    end
                    PlayTween(switchBg, TweenInfo.new(duration), {BackgroundColor3 = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].QuarBg}):Play()
                    PlayTween(switchCircle, TweenInfo.new(duration), {
                        Position = toggled and UDim2.new(1, -(switchCircle.Size.X.Offset + 2), 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                        BackgroundColor3 = toggled and Themes[Options.Theme].Text or Themes[Options.Theme].SubText
                    }):Play()
                elseif Options.ToggleStyle == "Checkbox" then
                    switchBg.Visible = false; checkBg.Visible = true; dotBg.Visible = false
                    toggleContainer.Size = UDim2.new(0, 44, 0, 22)
                    PlayTween(checkBg, TweenInfo.new(duration), {BackgroundColor3 = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].QuarBg}):Play()
                    PlayTween(checkInner, TweenInfo.new(duration), {Size = toggled and UDim2.new(1, -6, 1, -6) or UDim2.new(0, 0, 0, 0)}):Play()
                else
                    switchBg.Visible = false; checkBg.Visible = false; dotBg.Visible = true
                    toggleContainer.Size = UDim2.new(0, 44, 0, 22)
                    PlayTween(dotBg, TweenInfo.new(duration), {BackgroundColor3 = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].QuarBg}):Play()
                    PlayTween(dotInner, TweenInfo.new(duration), {Size = toggled and UDim2.new(0, 10, 0, 10) or UDim2.new(0, 0, 0, 0)}):Play()
                end
                if not themeUpdate then PlayTween(stroke, TweenInfo.new(duration), {Color = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].Stroke}):Play() else stroke.Color = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].Stroke end
            end
            table.insert(Registries.Toggle, syncVisuals)
            toggleButton.MouseButton1Click:Connect(function() toggled = not toggled; syncVisuals(); pcall(callback, toggled) end)
            toggleButton.MouseEnter:Connect(function() PlayTween(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play() end)
            toggleButton.MouseLeave:Connect(function() PlayTween(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play() end)
            syncVisuals(true)
        end

        -- Performance tab and toggles
        CreateSettingsSection("Performance")
        CreateSettingsGroup("Optimization", true)

        CreateSettingsToggle("Performance Mode (FPS Boost)", function(state)
            local Lighting = game:GetService("Lighting")
            if state then
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
                    if Lighting:FindFirstChild("Atmosphere") == nil and StoredAtmosphere then StoredAtmosphere.Parent = Lighting end
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

        CreateSettingsToggle("Disable Particles & Effects", function(state)
            if state then
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                        v.Enabled = false
                    end
                end
                ParticleCleanup = function()
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                            v.Enabled = true
                        end
                    end
                end
            else
                if ParticleCleanup then ParticleCleanup() ParticleCleanup = nil end
            end
        end)

        CreateSettingsToggle("Hide Decals & Textures", function(state)
            if state then
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("Texture") or v:IsA("Decal") then v.Transparency = 1 end
                end
                DecalCleanup = function()
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("Texture") or v:IsA("Decal") then v.Transparency = 0 end
                    end
                end
            else
                if DecalCleanup then DecalCleanup() DecalCleanup = nil end
            end
        end)

        CreateSettingsToggle("Reduce Part Detail", function(state)
            if state then
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then v.Material = Enum.Material.SmoothPlastic; v.CastShadow = false end
                end
                PartDetailCleanup = function()
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then v.Material = Enum.Material.Plastic; v.CastShadow = true end
                    end
                end
            else
                if PartDetailCleanup then PartDetailCleanup() PartDetailCleanup = nil end
            end
        end)

        CreateSettingsSection("Developer")
        CreateSettingsGroup("Tools", true)
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
        CloseButton.MouseEnter:Connect(function() PlayTween(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Accent, TextColor3 = Themes[Options.Theme].Text}):Play() end)
        CloseButton.MouseLeave:Connect(function() PlayTween(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].QuarBg, TextColor3 = Themes[Options.Theme].SubText}):Play() end)
        MinimizeButton.MouseEnter:Connect(function() PlayTween(MinimizeButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover, TextColor3 = Themes[Options.Theme].Text}):Play() end)
        MinimizeButton.MouseLeave:Connect(function() PlayTween(MinimizeButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].QuarBg, TextColor3 = Themes[Options.Theme].SubText}):Play() end)
        SettingsButton.MouseEnter:Connect(function() PlayTween(SettingsButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover, TextColor3 = Themes[Options.Theme].Text}):Play() end)
        SettingsButton.MouseLeave:Connect(function() PlayTween(SettingsButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].QuarBg, TextColor3 = Themes[Options.Theme].SubText}):Play() end)
        CollapseKeybindButton.MouseEnter:Connect(function() PlayTween(CollapseKeybindButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover, TextColor3 = Themes[Options.Theme].Text}):Play() end)
        CollapseKeybindButton.MouseLeave:Connect(function() PlayTween(CollapseKeybindButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].QuarBg, TextColor3 = Themes[Options.Theme].SubText}):Play() end)
        TabletBackButton.MouseEnter:Connect(function() PlayTween(TabletBackButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover, TextColor3 = Themes[Options.Theme].Text}):Play() end)
        TabletBackButton.MouseLeave:Connect(function() PlayTween(TabletBackButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].QuarBg, TextColor3 = Themes[Options.Theme].SubText}):Play() end)
        TabletBackButton.MouseButton1Click:Connect(function()
            ShowTabletHome()
        end)
        
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
                TabContainer.Visible = ActiveLayoutState.ShowSidebar
                Separator.Visible = ActiveLayoutState.ShowSeparator
                NavDropdownFrame.Visible = ActiveLayoutState.ShowDropdown
            end
            
            UpdateWindowSize(true)
        end
        MinimizeButton.MouseButton1Click:Connect(MinimizeUI)

        local UIVisible = true
        local function ToggleUI()
            UIVisible = not UIVisible
            if UIVisible then
                MainFrame.Visible = true
                UpdateWindowSize(false)
                PlayTween(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = Minimized and UDim2.new(0, expandedWidth, 0, 48) or UDim2.new(0, expandedWidth, 0, expandedHeight)}):Play()
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
        local cameraViewportConnection = nil
        local function BindViewportListener()
            if cameraViewportConnection then
                cameraViewportConnection:Disconnect()
                cameraViewportConnection = nil
            end
            local camera = workspace.CurrentCamera
            if camera then
                cameraViewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                    if UIVisible then
                        UpdateWindowSize(false)
                    end
                end)
                table.insert(window.connections, cameraViewportConnection)
            end
        end
        BindViewportListener()
        local cameraSwapConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            BindViewportListener()
            if UIVisible then
                UpdateWindowSize(false)
            end
        end)
        table.insert(window.connections, cameraSwapConnection)
        local contentResizeConnection = ContentFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            UpdateTabletGridSizing()
        end)
        table.insert(window.connections, contentResizeConnection)

        function window:SwitchToTab(tabToSelect)
            CurrentTab = tabToSelect
            NavDropdownBtn.Text = tabToSelect.Name
            local idleColor, activeColor = GetTabButtonColors()
            for _, tab in pairs(tabs) do
                tab.Page.Visible = false
                PlayTween(tab.Button, TweenInfo.new(0.2), {BackgroundColor3 = idleColor, TextColor3 = Themes[Options.Theme].SubText}):Play()
                if tab.ActiveRail then
                    PlayTween(tab.ActiveRail, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                end
            end
            tabToSelect.Page.Visible = true
            PlayTween(tabToSelect.Button, TweenInfo.new(0.2), {BackgroundColor3 = activeColor, TextColor3 = Themes[Options.Theme].Text}):Play()
            if tabToSelect.ActiveRail then
                PlayTween(tabToSelect.ActiveRail, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            end

            if Options.MenuStyle == "Tablet" then
                IsTabletHomeVisible = false
                TabletHomeFrame.Visible = false
                SetTabletBackVisible(true)
            else
                SetTabletBackVisible(false)
            end
        end

        function window:CreateTab(name)


            local tab = { Name = name, Elements = {} }
            local tabButton = CreateElement("TextButton", { Name = name .. "Tab", Parent = TabHolder, BackgroundTransparency = 0, BorderSizePixel = 0, Size = UDim2.new(1, -18, 0, 38), Font = Enum.Font.GothamBold, Text = name, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {BackgroundColor3 = "SecBg", TextColor3 = "SubText"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = tabButton})
            CreateElement("UIPadding", {Parent = tabButton, PaddingLeft = UDim.new(0, 14)})
            local activeRail = CreateElement("Frame", { Parent = tabButton, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 8), Size = UDim2.new(0, 3, 1, -16), BackgroundTransparency = 1 }, {BackgroundColor3 = "Accent"})
            CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = activeRail})
            
            local page = CreateElement("ScrollingFrame", { Name = name .. "Page", Parent = ContentFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ScrollBarThickness = 2, Visible = false }, {ScrollBarImageColor3 = "Stroke"})
            CreateElement("UIListLayout", {Parent = page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
            CreateElement("UIPadding", {Parent = page, PaddingRight = UDim.new(0, 10), PaddingLeft = UDim.new(0, 5), PaddingTop = UDim.new(0, 5)})
            local tabletTile = CreateElement("TextButton", { Name = name .. "Tile", Parent = TabletHomeFrame, BorderSizePixel = 0, AutoButtonColor = false, Text = name, Font = Enum.Font.GothamBold, TextSize = 15 }, {BackgroundColor3 = "TerBg", TextColor3 = "Text"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = tabletTile})
            CreateElement("UIStroke", {Parent = tabletTile, Thickness = 1}, {Color = "Stroke"})
            
            tab.Button = tabButton; tab.Page = page; tab.ActiveRail = activeRail; tab.TabletTile = tabletTile; table.insert(tabs, tab)
            ApplyTabButtonMode(tab)
            tabButton.MouseEnter:Connect(function()
                if not page.Visible then
                    PlayTween(tabButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover, TextColor3 = Themes[Options.Theme].Text}):Play()
                end
            end)
            tabButton.MouseLeave:Connect(function()
                if not page.Visible then
                    local idleColor = GetTabButtonColors()
                    PlayTween(tabButton, TweenInfo.new(0.2), {BackgroundColor3 = idleColor, TextColor3 = Themes[Options.Theme].SubText}):Play()
                end
            end)
            tabButton.MouseButton1Click:Connect(function() window:SwitchToTab(tab) end)
            tabletTile.MouseEnter:Connect(function()
                PlayTween(tabletTile, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play()
            end)
            tabletTile.MouseLeave:Connect(function()
                PlayTween(tabletTile, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play()
            end)
            tabletTile.MouseButton1Click:Connect(function()
                window:SwitchToTab(tab)
            end)

            UpdateTabletGridSizing()
            if #tabs == 1 then
                if Options.MenuStyle == "Tablet" then
                    ShowTabletHome()
                else
                    window:SwitchToTab(tab)
                end
            end

            local function ResolvePersistedValue(saveKey, defaultValue)
                if type(saveKey) ~= "string" or saveKey == "" then
                    return defaultValue, nil
                end
                local store = UILibrary:RegisterValue(saveKey, defaultValue)
                return store:Get(), store
            end

            function tab:CreateButton(text, callback)
                local button = CreateElement("TextButton", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 35), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg", TextColor3 = "Text"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = button})
                local buttonStroke = CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = button}, {Color = "Stroke"})
                
                button.MouseEnter:Connect(function() PlayTween(button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play(); PlayTween(buttonStroke, TweenInfo.new(0.2), {Color = Themes[Options.Theme].Accent}):Play() end)
                button.MouseLeave:Connect(function() PlayTween(button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play(); PlayTween(buttonStroke, TweenInfo.new(0.2), {Color = Themes[Options.Theme].Stroke}):Play() end)
                button.MouseButton1Click:Connect(function() pcall(callback); PlayTween(button, TweenInfo.new(0.1), {Size = UDim2.new(1, -4, 0, 31)}):Play(); task.wait(0.1); PlayTween(button, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 35)}):Play() end)
                table.insert(tab.Elements, button)
                return button
            end

            function tab:CreateToggle(text, callback, defaultState, saveKey)
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
                local dotBg = CreateElement("Frame", { Parent = toggleButton, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 20, 0, 20), Visible = false }, {BackgroundColor3 = "QuarBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = dotBg})
                local dotIndicator = CreateElement("Frame", { Parent = dotBg, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0) }, {BackgroundColor3 = "Accent"})
                CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = dotIndicator})

                local fallbackState = (type(defaultState) == "boolean") and defaultState or false
                local loadedState, toggleStore = ResolvePersistedValue(saveKey, fallbackState)
                local toggled = (type(loadedState) == "boolean") and loadedState or fallbackState
                local function syncVisuals(themeUpdate)
                    local duration = themeUpdate and 0 or 0.2
                    if Options.ToggleStyle == "Switch" or Options.ToggleStyle == "Pill" then
                        switchBg.Visible = true; checkBg.Visible = false; dotBg.Visible = false
                        if Options.ToggleStyle == "Pill" then
                            toggleButton.Size = UDim2.new(0, 46, 0, 22)
                            switchIndicator.Size = UDim2.new(0, 18, 0, 18)
                        else
                            toggleButton.Size = UDim2.new(0, 40, 0, 20)
                            switchIndicator.Size = UDim2.new(0, 16, 0, 16)
                        end
                        PlayTween(switchBg, TweenInfo.new(duration), {BackgroundColor3 = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].QuarBg}):Play()
                        PlayTween(switchIndicator, TweenInfo.new(duration), {Position = toggled and UDim2.new(1, -(switchIndicator.Size.X.Offset + 2), 0.5, 0) or UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = toggled and Themes[Options.Theme].Text or Themes[Options.Theme].SubText}):Play()
                    elseif Options.ToggleStyle == "Checkbox" then
                        switchBg.Visible = false; checkBg.Visible = true; dotBg.Visible = false
                        toggleButton.Size = UDim2.new(0, 40, 0, 20)
                        PlayTween(checkBg, TweenInfo.new(duration), {BackgroundColor3 = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].QuarBg}):Play()
                        PlayTween(checkInner, TweenInfo.new(duration), {Size = toggled and UDim2.new(1, -6, 1, -6) or UDim2.new(0, 0, 0, 0)}):Play()
                    else
                        switchBg.Visible = false; checkBg.Visible = false; dotBg.Visible = true
                        toggleButton.Size = UDim2.new(0, 40, 0, 20)
                        PlayTween(dotBg, TweenInfo.new(duration), {BackgroundColor3 = toggled and Themes[Options.Theme].Accent or Themes[Options.Theme].QuarBg}):Play()
                        PlayTween(dotIndicator, TweenInfo.new(duration), {Size = toggled and UDim2.new(0, 10, 0, 10) or UDim2.new(0, 0, 0, 0)}):Play()
                    end
                end

                local function setToggleState(state, skipCallback)
                    toggled = state and true or false
                    syncVisuals()
                    if toggleStore then
                        toggleStore:Set(toggled)
                    end
                    if not skipCallback then
                        pcall(callback, toggled)
                    end
                end

                table.insert(Registries.Toggle, syncVisuals)
                toggleButton.MouseButton1Click:Connect(function()
                    setToggleState(not toggled, false)
                end)
                syncVisuals(true)
                if toggleStore then
                    pcall(callback, toggled)
                end
                table.insert(tab.Elements, toggleFrame)
                return toggleFrame
            end

            function tab:CreateKeybind(text, callback, defaultKey, saveKey)
                local keybindFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 35), LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = keybindFrame})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = keybindFrame}, {Color = "Stroke"})
                
                CreateElement("TextLabel", { Parent = keybindFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                local keybindButton = CreateElement("TextButton", { Parent = keybindFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 80, 0, 22), Font = Enum.Font.GothamBold, Text = "None", TextSize = 12 }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = keybindButton})
                local keybindStroke = CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = keybindButton}, {Color = "Stroke"})
                
                local validDefaultKey = (typeof(defaultKey) == "EnumItem") and defaultKey or nil
                local loadedKey, keyStore = ResolvePersistedValue(saveKey, validDefaultKey)
                local currentKey = (typeof(loadedKey) == "EnumItem") and loadedKey or validDefaultKey
                if typeof(currentKey) == "EnumItem" then
                    keybindButton.Text = currentKey.Name
                end
                local waiting = false

                local function setKeybind(newKey, skipCallback)
                    if newKey ~= nil and typeof(newKey) ~= "EnumItem" then
                        return
                    end
                    currentKey = newKey
                    keybindButton.Text = currentKey and currentKey.Name or "None"
                    if keyStore then
                        keyStore:Set(currentKey)
                    end
                    if not skipCallback then
                        pcall(callback, currentKey)
                    end
                end

                keybindButton.MouseButton1Click:Connect(function()
                    if waiting then return end
                    waiting = true; keybindButton.Text = "..."; PlayTween(keybindStroke, TweenInfo.new(0.2), {Color = Themes[Options.Theme].Accent}):Play()
                    local connection; connection = UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            setKeybind(input.KeyCode, true); task.delay(0.2, function() waiting = false end)
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
                table.insert(tab.Elements, keybindFrame)
                return keybindFrame
            end

            function tab:CreateSlider(text, min, max, default, callback, saveKey)
                local sliderFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 50), LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = sliderFrame})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = sliderFrame}, {Color = "Stroke"})
                local fallbackValue = tonumber(default) or min
                fallbackValue = math.clamp(fallbackValue, min, max)
                local loadedValue, sliderStore = ResolvePersistedValue(saveKey, fallbackValue)
                local currentValue = tonumber(loadedValue) or fallbackValue
                currentValue = math.clamp(currentValue, min, max)

                CreateElement("TextLabel", { Parent = sliderFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(0.5, 0, 0.4, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                local valueLabel = CreateElement("TextLabel", { Parent = sliderFrame, BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 5), Size = UDim2.new(0.5, -10, 0.4, 0), Font = Enum.Font.Gotham, Text = tostring(currentValue), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right }, {TextColor3 = "SubText"})
                local sliderBar = CreateElement("TextButton", { Parent = sliderFrame, BorderSizePixel = 0, Position = UDim2.new(0.025, 0, 0.65, 0), Size = UDim2.new(0.95, 0, 0.15, 0), Text = "" }, {BackgroundColor3 = "QuarBg"})
                local sliderBarCorner = CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderBar})

                local initialRatio = (max == min) and 0 or ((currentValue - min) / (max - min))
                local fill = CreateElement("Frame", { Parent = sliderBar, BorderSizePixel = 0, Size = UDim2.new(initialRatio, 0, 1, 0) }, {BackgroundColor3 = "Accent"})
                local fillCorner = CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = fill})
                local knob = CreateElement("Frame", { Parent = sliderBar, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(initialRatio, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0), Visible = false }, {BackgroundColor3 = "Text"})
                CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knob})

                local function applySliderStyle(themeUpdate)
                    local duration = themeUpdate and 0 or 0.2
                    local styleName = Options.SliderStyle
                    if styleName == "Pill" then
                        sliderBar.Position = UDim2.new(0.025, 0, 0.62, 0)
                        sliderBar.Size = UDim2.new(0.95, 0, 0.22, 0)
                        sliderBarCorner.CornerRadius = UDim.new(1, 0)
                        fillCorner.CornerRadius = UDim.new(1, 0)
                        knob.Visible = true
                        PlayTween(knob, TweenInfo.new(duration), {Size = UDim2.new(0, 14, 0, 14), BackgroundColor3 = Themes[Options.Theme].Text}):Play()
                    elseif styleName == "Block" then
                        sliderBar.Position = UDim2.new(0.025, 0, 0.62, 0)
                        sliderBar.Size = UDim2.new(0.95, 0, 0.20, 0)
                        sliderBarCorner.CornerRadius = UDim.new(0, 4)
                        fillCorner.CornerRadius = UDim.new(0, 4)
                        knob.Visible = true
                        PlayTween(knob, TweenInfo.new(duration), {Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = Themes[Options.Theme].Accent}):Play()
                    else
                        sliderBar.Position = UDim2.new(0.025, 0, 0.65, 0)
                        sliderBar.Size = UDim2.new(0.95, 0, 0.15, 0)
                        sliderBarCorner.CornerRadius = UDim.new(1, 0)
                        fillCorner.CornerRadius = UDim.new(1, 0)
                        PlayTween(knob, TweenInfo.new(duration), {Size = UDim2.new(0, 0, 0, 0)}):Play()
                        task.delay(duration, function()
                            if Options.SliderStyle == "Line" and knob.Parent then
                                knob.Visible = false
                            end
                        end)
                    end
                end
                
                local isDragging = false
                local function applySliderValue(value, skipCallback)
                    local clamped = math.clamp(math.floor((tonumber(value) or min) + 0.5), min, max)
                    local ratio = (max == min) and 0 or ((clamped - min) / (max - min))
                    fill.Size = UDim2.new(ratio, 0, 1, 0)
                    knob.Position = UDim2.new(ratio, 0, 0.5, 0)
                    valueLabel.Text = tostring(clamped)
                    currentValue = clamped
                    if sliderStore then
                        sliderStore:Set(clamped)
                    end
                    if not skipCallback then
                        pcall(callback, clamped)
                    end
                end

                local function updateSlider(inputPos)
                    local relativeX = inputPos.X - sliderBar.AbsolutePosition.X
                    local ratio = math.clamp(relativeX / sliderBar.AbsoluteSize.X, 0, 1)
                    local value = math.floor(min + ratio * (max - min) + 0.5)
                    applySliderValue(value, false)
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
                table.insert(Registries.Slider, applySliderStyle)
                applySliderStyle(true)
                if sliderStore then
                    applySliderValue(currentValue, false)
                end
                table.insert(tab.Elements, sliderFrame)
                return sliderFrame
            end

            function tab:CreateCycleButton(text, values, default, callback, saveKey)
                local cycleFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 35), LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = cycleFrame})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = cycleFrame}, {Color = "Stroke"})
                local fallbackValue = default or values[1]
                local loadedValue, cycleStore = ResolvePersistedValue(saveKey, fallbackValue)

                CreateElement("TextLabel", { Parent = cycleFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                local cycleButton = CreateElement("TextButton", { Parent = cycleFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 100, 0, 22), Font = Enum.Font.GothamBold, Text = tostring(loadedValue or fallbackValue or "None"), TextSize = 12 }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = cycleButton})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = cycleButton}, {Color = "Stroke"})
                
                local idx = 1
                for i, v in ipairs(values) do
                    if v == loadedValue then
                        idx = i
                        break
                    elseif v == fallbackValue and idx == 1 then
                        idx = i
                    end
                end
                local function update(skipCallback)
                    local val = values[idx]
                    cycleButton.Text = tostring(val)
                    if cycleStore then
                        cycleStore:Set(val)
                    end
                    if not skipCallback then
                        pcall(callback, val)
                    end
                end
                
                cycleButton.MouseButton1Click:Connect(function()
                    if #values == 0 then return end
                    idx = idx + 1; if idx > #values then idx = 1 end
                    update(false)
                    PlayTween(cycleButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 90, 0, 18)}):Play()
                    task.wait(0.1); PlayTween(cycleButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 100, 0, 22)}):Play()
                end)
                if cycleStore and #values > 0 then
                    update(false)
                end
                table.insert(tab.Elements, cycleFrame)
                return {
                    Frame = cycleFrame,
                    SetValues = function(self, newValues)
                        values = newValues
                        idx = 1
                        if #values > 0 then
                            update(true)
                        else
                            cycleButton.Text = "None"
                        end
                    end,
                    SetValue = function(self, val)
                        for i, v in ipairs(values) do
                            if v == val then
                                idx = i
                                update(true)
                                break
                            end
                        end
                    end
                }
            end

            function tab:CreateDropdown(text, options, default, callback, saveKey)
                local dropdownFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 45), ClipsDescendants = true, LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = dropdownFrame})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = dropdownFrame}, {Color = "Stroke"})
                local titleLabel = CreateElement("TextLabel", { Parent = dropdownFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.5, 0, 0, 45), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})

                local fallbackValue = default or options[1]
                local loadedValue, dropdownStore = ResolvePersistedValue(saveKey, fallbackValue)
                local currentValue = loadedValue
                local valueInOptions = false
                for _, option in ipairs(options) do
                    if option == currentValue then
                        valueInOptions = true
                        break
                    end
                end
                if not valueInOptions then
                    currentValue = fallbackValue
                end

                local dropdownButton = CreateElement("TextButton", { Parent = dropdownFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 120, 0, 30), Font = Enum.Font.GothamBold, Text = currentValue or "None", TextSize = 12, AutoButtonColor = false }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = dropdownButton})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = dropdownButton}, {Color = "Stroke"})
                local headerHeight, rowHeight = 45, 30
                local function resolveComboMetrics()
                    if Options.ComboStyle == "Compact" then
                        return 40, 26, 110, 24
                    elseif Options.ComboStyle == "Soft" then
                        return 48, 32, 132, 32
                    end
                    return 45, 30, 120, 30
                end
                
                local function setDropdownValue(value, skipCallback)
                    currentValue = value
                    dropdownButton.Text = value or "None"
                    if dropdownStore then
                        dropdownStore:Set(value)
                    end
                    if not skipCallback then
                        pcall(callback, value)
                    end
                end

                local isOpen = false; local optionContainer
                local function applyComboStyle(themeUpdate)
                    local _, _, btnW, btnH = resolveComboMetrics()
                    headerHeight, rowHeight = resolveComboMetrics()
                    dropdownFrame.Size = UDim2.new(1, 0, 0, isOpen and (headerHeight + (#options * rowHeight) + 10) or headerHeight)
                    titleLabel.Size = UDim2.new(0.5, 0, 0, headerHeight)
                    dropdownButton.Position = UDim2.new(1, -10, 0, math.floor((headerHeight - btnH) / 2))
                    dropdownButton.Size = UDim2.new(0, btnW, 0, btnH)
                    dropdownButton.AnchorPoint = Vector2.new(1, 0)
                    if optionContainer then
                        optionContainer.Position = UDim2.new(0, 0, 0, headerHeight)
                        optionContainer.Size = UDim2.new(1, 0, 0, #options * rowHeight)
                        for i, child in ipairs(optionContainer:GetChildren()) do
                            if child:IsA("TextButton") then
                                child.Position = UDim2.new(0, 10, 0, (i - 1) * rowHeight)
                                child.Size = UDim2.new(1, -20, 0, rowHeight - 2)
                            end
                        end
                    end
                end
                table.insert(Registries.Combo, applyComboStyle)

                dropdownButton.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        if optionContainer then optionContainer:Destroy() end
                        optionContainer = CreateElement("Frame", { Parent = dropdownFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, headerHeight), Size = UDim2.new(1, 0, 0, #options * rowHeight) })
                        for i, opt in ipairs(options) do
                            local optBtn = CreateElement("TextButton", { Parent = optionContainer, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, (i-1)*rowHeight), Size = UDim2.new(1, -20, 0, rowHeight - 2), Font = Enum.Font.Gotham, Text = opt, TextSize = 12, AutoButtonColor = false }, {BackgroundColor3 = "TerBg", TextColor3 = "SubText"})
                            CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = optBtn})
                            optBtn.MouseEnter:Connect(function() PlayTween(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play() end)
                            optBtn.MouseLeave:Connect(function() PlayTween(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play() end)
                            optBtn.MouseButton1Click:Connect(function()
                                setDropdownValue(opt, false)
                                isOpen = false
                                PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, headerHeight)}):Play()
                                task.delay(0.2, function() if optionContainer then optionContainer:Destroy() end end)
                            end)
                        end
                        PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, headerHeight + (#options * rowHeight) + 10)}):Play()
                    else
                        PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, headerHeight)}):Play(); task.delay(0.2, function() if optionContainer then optionContainer:Destroy() end end)
                    end
                end)
                applyComboStyle(true)
                if dropdownStore and currentValue ~= nil then
                    setDropdownValue(currentValue, false)
                end
                table.insert(tab.Elements, dropdownFrame)
                return dropdownFrame
            end

            function tab:CreateParagraph(title, content)
                local paragraphFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = paragraphFrame})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = paragraphFrame}, {Color = "Stroke"})
                CreateElement("TextLabel", { Parent = paragraphFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(1, -20, 0, 15), Font = Enum.Font.GothamBold, Text = title, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                CreateElement("TextLabel", { Parent = paragraphFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 30), Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Gotham, Text = content, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true }, {TextColor3 = "SubText"})
                CreateElement("UIPadding", {Parent = paragraphFrame, PaddingBottom = UDim.new(0, 10)})
                
                table.insert(tab.Elements, paragraphFrame)
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
        ApplyStrokeStyleVisuals(true)
        SaveLibraryOptions()
        
        return window
    end
    return UILibrary
end)()

return UILibrary

