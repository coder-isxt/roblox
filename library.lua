-- // IMPORTS // --
local UILibrary = (function()
    local UILibrary = {}
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")

    -- // TWEEN POOLING // --
    local TweenPool = {}

    local function BuildTweenKey(instance, props)
        local propertyNames = {}
        for propertyName in pairs(props or {}) do
            table.insert(propertyNames, tostring(propertyName))
        end
        table.sort(propertyNames)
        return instance:GetDebugId() .. "|" .. table.concat(propertyNames, ",")
    end

    local function PlayTween(instance, info, props)
        local key = BuildTweenKey(instance, props)

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
        Theme = "Clean",
        ToggleStyle = "Switch", -- "Switch", "Checkbox", "Pill", "Dot"
        CornerStyle = "Rounded", -- "Rounded", "Slight", "Blocky"
        StrokeStyle = "Outline", -- "None", "Outline", "Glow", "TwoCornerFade", "SoftFade"
        SliderStyle = "Line", -- "Line", "Pill", "Block"
        ComboStyle = "Classic", -- "Classic", "Compact", "Soft"
        Font = "Gotham", -- FontMap keys
        MenuStyle = "Sidebar", -- fixed for now
        AutoScale = true,
        UserScale = 1
    }

    local MenuStyleSet = {
        Sidebar = true,
        TopBar = true,
        Dropdown = true,
        Tablet = true
    }

    local Themes = {
        Clean = {
            MainBg = Color3.fromRGB(14, 17, 23),
            SecBg = Color3.fromRGB(20, 24, 33),
            TerBg = Color3.fromRGB(26, 31, 42),
            QuarBg = Color3.fromRGB(34, 40, 54),
            Hover = Color3.fromRGB(43, 51, 69),
            Accent = Color3.fromRGB(108, 182, 255),
            Text = Color3.fromRGB(236, 242, 252),
            SubText = Color3.fromRGB(159, 173, 196),
            Stroke = Color3.fromRGB(70, 83, 106)
        }
    }

    local ThemeAliases = {
        Default = "Clean",
        Dark = "Clean",
        Light = "Clean",
        Discord = "Clean",
        Midnight = "Clean",
        Mint = "Clean",
        Rose = "Clean",
        Ocean = "Clean",
        Forest = "Clean",
        Ember = "Clean",
        Amoled = "Clean",
        Nord = "Clean",
        TokyoNight = "Clean",
        Dracula = "Clean",
        Cyberpunk = "Clean",
        Sapphire = "Clean",
        Sunset = "Clean",
        Slate = "Clean",
        Obsidian = "Clean",
        GlassBlue = "Clean",
        Graphite = "Clean",
        Nebula = "Clean",
        EmeraldNight = "Clean",
        Monochrome = "Clean",
        Cobalt = "Clean",
        Carbon = "Clean",
        Arctic = "Clean",
        Aether = "Clean",
        Aurora = "Clean",
        Emerald = "Clean",
        Rosewood = "Clean",
        Orchid = "Clean",
        Solar = "Clean",
        Ice = "Clean",
        Pearl = "Clean",
        Cyber = "Clean",
        Noir = "Clean",
        Sandstone = "Clean"
    }

    local function BlendThemeColor(baseColor, targetColor, alpha)
        alpha = math.clamp(alpha or 0, 0, 1)
        return Color3.new(
            baseColor.R + ((targetColor.R - baseColor.R) * alpha),
            baseColor.G + ((targetColor.G - baseColor.G) * alpha),
            baseColor.B + ((targetColor.B - baseColor.B) * alpha)
        )
    end

    local function ResolveThemeName(themeName)
        if type(themeName) ~= "string" or themeName == "" then
            return nil
        end
        if Themes[themeName] then
            return themeName
        end
        local alias = ThemeAliases[themeName]
        if alias and Themes[alias] then
            return alias
        end
        return nil
    end

    local function NormalizeThemePalette(theme)
        local mainBg = theme.MainBg or Color3.fromRGB(18, 20, 25)
        local isLightTheme = ((mainBg.R + mainBg.G + mainBg.B) / 3) > 0.5
        local white = Color3.fromRGB(255, 255, 255)
        local black = Color3.fromRGB(0, 0, 0)
        local contrastTarget = isLightTheme and black or white

        local secBg = theme.SecBg or BlendThemeColor(mainBg, contrastTarget, isLightTheme and 0.028 or 0.062)
        local terBg = theme.TerBg or BlendThemeColor(secBg, contrastTarget, isLightTheme and 0.032 or 0.068)
        local quarBg = theme.QuarBg or BlendThemeColor(terBg, contrastTarget, isLightTheme and 0.038 or 0.078)
        local accent = theme.Accent or (isLightTheme and Color3.fromRGB(76, 138, 234) or Color3.fromRGB(98, 182, 255))
        local text = theme.Text or (isLightTheme and Color3.fromRGB(30, 40, 56) or Color3.fromRGB(236, 242, 252))
        local subText = theme.SubText or BlendThemeColor(text, secBg, isLightTheme and 0.52 or 0.4)
        local stroke = theme.Stroke or BlendThemeColor(quarBg, text, isLightTheme and 0.2 or 0.16)
        local hover = theme.Hover or BlendThemeColor(quarBg, accent, isLightTheme and 0.12 or 0.2)

        return {
            MainBg = mainBg,
            SecBg = secBg,
            TerBg = terBg,
            QuarBg = quarBg,
            Hover = hover,
            Accent = accent,
            Text = text,
            SubText = subText,
            Stroke = stroke
        }
    end

    for themeName, palette in pairs(Themes) do
        Themes[themeName] = NormalizeThemePalette(palette)
    end

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
    local VisualTokens = {
        WindowCorner = 14,
        SurfaceCorner = 10,
        ControlCorner = 8,
        TopBarHeight = 46,
        SidebarWidth = 168,
        SearchWidth = 210,
        SearchHeight = 32,
        ControlHeight = 40,
        SectionGap = 8,
        CardStroke = 1
    }

    local PersistConfig = {
        SchemaVersion = 3,
        DefaultProfile = "Default",
        ProfileNameMaxLength = 36,
        WriteDebounce = 0.18,
        WriteQueued = false,
        Folder = "XenoUILibrary",
        FileName = "settings.json",
        Data = {
            Meta = {
                Version = 3,
                ActiveProfile = "Default"
            },
            Profiles = {},
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

    local function CloneTable(source)
        if typeof(source) ~= "table" then
            return source
        end
        local cloned = {}
        for key, value in pairs(source) do
            cloned[key] = CloneTable(value)
        end
        return cloned
    end

    local function NormalizeProfileName(name)
        if type(name) ~= "string" then
            return nil
        end
        local cleaned = name:gsub("^%s+", ""):gsub("%s+$", "")
        cleaned = cleaned:gsub("[^%w_%-%s]", "")
        cleaned = cleaned:gsub("%s+", "_")
        cleaned = cleaned:gsub("_+", "_")
        if cleaned == "" then
            return nil
        end
        if #cleaned > PersistConfig.ProfileNameMaxLength then
            cleaned = cleaned:sub(1, PersistConfig.ProfileNameMaxLength)
        end
        return cleaned
    end

    local function EnsureProfilesTable()
        if type(PersistConfig.Data.Profiles) ~= "table" then
            PersistConfig.Data.Profiles = {}
        end
    end

    local function EnsureProfile(profileName)
        local resolvedName = NormalizeProfileName(profileName) or PersistConfig.DefaultProfile
        EnsureProfilesTable()
        local existing = PersistConfig.Data.Profiles[resolvedName]
        if type(existing) ~= "table" then
            existing = {}
            PersistConfig.Data.Profiles[resolvedName] = existing
        end
        if type(existing.LibraryOptions) ~= "table" then
            existing.LibraryOptions = {}
        end
        if type(existing.Values) ~= "table" then
            existing.Values = {}
        end
        return resolvedName, existing
    end

    local function GetActiveProfileName()
        local meta = PersistConfig.Data.Meta
        if type(meta) ~= "table" then
            PersistConfig.Data.Meta = {}
            meta = PersistConfig.Data.Meta
        end
        local resolvedName = NormalizeProfileName(meta.ActiveProfile) or PersistConfig.DefaultProfile
        meta.ActiveProfile = resolvedName
        return resolvedName
    end

    local function SnapshotActiveProfile()
        local profileName, profile = EnsureProfile(GetActiveProfileName())
        profile.LibraryOptions = CloneTable(PersistConfig.Data.LibraryOptions or {})
        profile.Values = CloneTable(PersistConfig.Data.Values or {})
        PersistConfig.Data.Meta.ActiveProfile = profileName
    end

    local function HydrateFromProfile(profileName)
        local resolvedName, profile = EnsureProfile(profileName)
        PersistConfig.Data.Meta.ActiveProfile = resolvedName
        PersistConfig.Data.LibraryOptions = CloneTable(profile.LibraryOptions or {})
        PersistConfig.Data.Values = CloneTable(profile.Values or {})
        return resolvedName
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

    local function SavePersistConfigNow()
        if not CanPersist() then return false end

        EnsureConfigFolder()
        SnapshotActiveProfile()
        PersistConfig.Data.Meta = PersistConfig.Data.Meta or {}
        PersistConfig.Data.Meta.Version = PersistConfig.SchemaVersion
        PersistConfig.Data.Meta.ActiveProfile = GetActiveProfileName()
        PersistConfig.Data.Meta.LastSaved = os.time()

        local ok, encoded = pcall(function()
            return HttpService:JSONEncode(PersistConfig.Data)
        end)
        if not ok then return false end

        local path = PersistConfig.Folder .. "/" .. PersistConfig.FileName
        local writeOk = pcall(writefile, path, encoded)
        return writeOk
    end

    local function SavePersistConfig(immediate)
        if immediate then
            PersistConfig.WriteQueued = false
            return SavePersistConfigNow()
        end

        if not CanPersist() then
            return false
        end
        if PersistConfig.WriteQueued then
            return true
        end

        PersistConfig.WriteQueued = true
        task.delay(PersistConfig.WriteDebounce, function()
            PersistConfig.WriteQueued = false
            SavePersistConfigNow()
        end)
        return true
    end

    local function LoadPersistConfig()
        if not CanPersist() then return end

        PersistConfig.Data = {
            Meta = {
                Version = PersistConfig.SchemaVersion,
                ActiveProfile = PersistConfig.DefaultProfile
            },
            Profiles = {},
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

        if type(migrated.LibraryOptions) ~= "table" then
            migrated.LibraryOptions = {}
        end
        if type(migrated.Values) ~= "table" then
            migrated.Values = {}
        end
        if type(migrated.Profiles) ~= "table" then
            migrated.Profiles = {}
        end

        if version < 3 then
            migrated.Profiles = {
                [PersistConfig.DefaultProfile] = {
                    LibraryOptions = CloneTable(migrated.LibraryOptions),
                    Values = CloneTable(migrated.Values)
                }
            }
            migrated.Meta.ActiveProfile = PersistConfig.DefaultProfile
            migrated.Meta.Version = 3
        else
            local sanitizedProfiles = {}
            for profileName, profileData in pairs(migrated.Profiles) do
                local cleanName = NormalizeProfileName(profileName)
                if cleanName and type(profileData) == "table" then
                    sanitizedProfiles[cleanName] = {
                        LibraryOptions = type(profileData.LibraryOptions) == "table" and CloneTable(profileData.LibraryOptions) or {},
                        Values = type(profileData.Values) == "table" and CloneTable(profileData.Values) or {}
                    }
                end
            end
            migrated.Profiles = sanitizedProfiles
        end

        PersistConfig.Data.Meta = migrated.Meta
        PersistConfig.Data.Profiles = migrated.Profiles
        PersistConfig.Data.LibraryOptions = CloneTable(migrated.LibraryOptions)
        PersistConfig.Data.Values = CloneTable(migrated.Values)

        local activeProfileName = NormalizeProfileName(PersistConfig.Data.Meta.ActiveProfile) or PersistConfig.DefaultProfile
        if not PersistConfig.Data.Profiles[activeProfileName] then
            activeProfileName = PersistConfig.DefaultProfile
        end
        if not PersistConfig.Data.Profiles[activeProfileName] then
            PersistConfig.Data.Profiles[activeProfileName] = {
                LibraryOptions = CloneTable(PersistConfig.Data.LibraryOptions),
                Values = CloneTable(PersistConfig.Data.Values)
            }
        end
        HydrateFromProfile(activeProfileName)

        if version < PersistConfig.SchemaVersion then
            SavePersistConfig(true)
        end
    end

    local function ApplyLoadedLibraryOptions()
        local savedOptions = PersistConfig.Data.LibraryOptions
        if type(savedOptions) ~= "table" then return end

        local resolvedTheme = ResolveThemeName(savedOptions.Theme)
        if resolvedTheme then
            Options.Theme = resolvedTheme
        end
        Options.ToggleStyle = "Switch"
        Options.CornerStyle = "Rounded"
        Options.StrokeStyle = "Outline"
        Options.SliderStyle = "Line"
        Options.ComboStyle = "Classic"
        Options.Font = "Gotham"
        Options.MenuStyle = "Sidebar"
        if type(savedOptions.AutoScale) == "boolean" then
            Options.AutoScale = savedOptions.AutoScale
        end
        if type(savedOptions.UserScale) == "number" then
            Options.UserScale = math.clamp(savedOptions.UserScale, 0.78, 1.18)
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
            MenuStyle = Options.MenuStyle,
            AutoScale = Options.AutoScale,
            UserScale = Options.UserScale
        }
        SavePersistConfig(false)
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
        SavePersistConfig(true)
        return self
    end

    function UILibrary:GetActiveProfile()
        return GetActiveProfileName()
    end

    function UILibrary:GetProfiles()
        EnsureProfilesTable()
        local names = {}
        for profileName, _ in pairs(PersistConfig.Data.Profiles) do
            table.insert(names, profileName)
        end
        if #names == 0 then
            table.insert(names, PersistConfig.DefaultProfile)
        end
        table.sort(names, function(a, b)
            return string.lower(a) < string.lower(b)
        end)
        return names
    end

    function UILibrary:SaveProfile(profileName)
        local resolvedName = NormalizeProfileName(profileName) or GetActiveProfileName()
        local _, profile = EnsureProfile(resolvedName)
        profile.LibraryOptions = CloneTable(PersistConfig.Data.LibraryOptions or {})
        profile.Values = CloneTable(PersistConfig.Data.Values or {})
        PersistConfig.Data.Meta.ActiveProfile = resolvedName
        SavePersistConfig(true)
        return resolvedName
    end

    function UILibrary:LoadProfile(profileName)
        local resolvedName = NormalizeProfileName(profileName)
        if not resolvedName then
            return false
        end
        EnsureProfilesTable()
        if type(PersistConfig.Data.Profiles[resolvedName]) ~= "table" then
            return false
        end

        HydrateFromProfile(resolvedName)
        PersistConfig.RuntimeValues = {}
        for key, encoded in pairs(PersistConfig.Data.Values or {}) do
            PersistConfig.RuntimeValues[key] = DecodePersistValue(encoded)
        end
        SavePersistConfig(true)
        return true
    end

    function UILibrary:DeleteProfile(profileName)
        local resolvedName = NormalizeProfileName(profileName)
        if not resolvedName then
            return false
        end
        EnsureProfilesTable()
        if resolvedName == PersistConfig.DefaultProfile then
            return false
        end
        if type(PersistConfig.Data.Profiles[resolvedName]) ~= "table" then
            return false
        end

        PersistConfig.Data.Profiles[resolvedName] = nil
        if GetActiveProfileName() == resolvedName then
            HydrateFromProfile(PersistConfig.DefaultProfile)
        end
        SavePersistConfig(true)
        return true
    end

    function UILibrary:ExportConfig(profileName)
        local resolvedName = NormalizeProfileName(profileName) or GetActiveProfileName()
        EnsureProfilesTable()
        local profile = PersistConfig.Data.Profiles[resolvedName]
        if type(profile) ~= "table" then
            return nil
        end

        local payload = {
            Meta = {
                ExportVersion = 1,
                Profile = resolvedName,
                Timestamp = os.time()
            },
            LibraryOptions = CloneTable(profile.LibraryOptions or {}),
            Values = CloneTable(profile.Values or {})
        }
        local ok, encoded = pcall(function()
            return HttpService:JSONEncode(payload)
        end)
        if not ok then
            return nil
        end
        return encoded
    end

    function UILibrary:ImportConfig(raw, profileName, activate)
        if type(raw) ~= "string" or raw == "" then
            return false
        end
        local decodeOk, decoded = pcall(function()
            return HttpService:JSONDecode(raw)
        end)
        if not decodeOk or type(decoded) ~= "table" then
            return false
        end

        local importOptions = type(decoded.LibraryOptions) == "table" and CloneTable(decoded.LibraryOptions) or {}
        local importValues = type(decoded.Values) == "table" and CloneTable(decoded.Values) or {}
        local preferredName = NormalizeProfileName(profileName)
            or NormalizeProfileName((type(decoded.Meta) == "table" and decoded.Meta.Profile) or nil)
            or ("Imported_" .. os.date("%Y%m%d_%H%M%S"))
        local resolvedName = EnsureProfile(preferredName)
        PersistConfig.Data.Profiles[resolvedName] = {
            LibraryOptions = importOptions,
            Values = importValues
        }

        if activate then
            HydrateFromProfile(resolvedName)
            PersistConfig.RuntimeValues = {}
            for key, encoded in pairs(PersistConfig.Data.Values or {}) do
                PersistConfig.RuntimeValues[key] = DecodePersistValue(encoded)
            end
        end
        SavePersistConfig(true)
        return true, resolvedName
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
            SavePersistConfig(false)
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
            SavePersistConfig(false)
            return newValue
        end

        function handle:Reset()
            return self:Set(defaultValue)
        end

        function handle:Save()
            PersistConfig.Data.Values[key] = EncodePersistValue(PersistConfig.RuntimeValues[key])
            SavePersistConfig(true)
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
    local ThemeSyncCallbacks = {}


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

    local function BlendColor(baseColor, targetColor, alpha)
        alpha = math.clamp(alpha or 0, 0, 1)
        return Color3.new(
            baseColor.R + ((targetColor.R - baseColor.R) * alpha),
            baseColor.G + ((targetColor.G - baseColor.G) * alpha),
            baseColor.B + ((targetColor.B - baseColor.B) * alpha)
        )
    end

    local function RegisterThemeSync(callback)
        if type(callback) ~= "function" then
            return function() end
        end
        table.insert(ThemeSyncCallbacks, callback)
        pcall(callback, Themes[Options.Theme])
        return function()
            for i, registered in ipairs(ThemeSyncCallbacks) do
                if registered == callback then
                    table.remove(ThemeSyncCallbacks, i)
                    break
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
        local resolvedTheme = ResolveThemeName(themeName)
        if not resolvedTheme then
            return
        end
        Options.Theme = resolvedTheme; CleanRegistries()
        local themeColors = Themes[resolvedTheme]
        for _, item in ipairs(Registries.Theme) do
            if item.Instance and item.Instance.Parent then PlayTween(item.Instance, TweenInfo.new(0.3), {[item.Property] = themeColors[item.Role]}):Play() end
        end
        for _, callback in ipairs(ThemeSyncCallbacks) do
            pcall(callback, themeColors)
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

    local function ApplyRuntimeLibraryOptions()
        UpdateTheme(Options.Theme)
        UpdateToggleStyles(Options.ToggleStyle)
        UpdateCornerStyle(Options.CornerStyle)
        UpdateStrokeStyle(Options.StrokeStyle)
        UpdateSliderStyle(Options.SliderStyle)
        UpdateComboStyle(Options.ComboStyle)
        UpdateFont(Options.Font)
        UpdateMenuStyle(Options.MenuStyle)
    end

    -- // TOOLTIPS // --
    local TooltipGui = Instance.new("ScreenGui",game.CoreGui)
    TooltipGui.Name = "UILibTooltips"
    TooltipGui.IgnoreGuiInset = true
    TooltipGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    TooltipGui.DisplayOrder = 10000

    local TooltipLabel = Instance.new("TextLabel",TooltipGui)
    TooltipLabel.Visible = false
    TooltipLabel.BackgroundColor3 = Themes[Options.Theme].TerBg
    TooltipLabel.TextColor3 = Themes[Options.Theme].Text
    TooltipLabel.Size = UDim2.new(0,210,0,28)
    TooltipLabel.ZIndex = 10001
    TooltipLabel.BorderSizePixel = 0
    TooltipLabel.TextXAlignment = Enum.TextXAlignment.Left
    TooltipLabel.Font = Enum.Font.Gotham
    TooltipLabel.TextSize = 11
    local TooltipPadding = Instance.new("UIPadding", TooltipLabel)
    TooltipPadding.PaddingLeft = UDim.new(0, 8)
    TooltipPadding.PaddingRight = UDim.new(0, 8)
    local TooltipCorner = Instance.new("UICorner", TooltipLabel)
    TooltipCorner.CornerRadius = UDim.new(0, 8)
    local TooltipStroke = Instance.new("UIStroke", TooltipLabel)
    TooltipStroke.Thickness = 1
    TooltipStroke.Color = Themes[Options.Theme].Stroke
    table.insert(Registries.Theme, {Instance = TooltipLabel, Property = "BackgroundColor3", Role = "TerBg"})
    table.insert(Registries.Theme, {Instance = TooltipLabel, Property = "TextColor3", Role = "Text"})
    table.insert(Registries.Theme, {Instance = TooltipStroke, Property = "Color", Role = "Stroke"})

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


    function UILibrary:CreateWindow(titleOrOptions)
        local window = {}
        local tabs = {}
        local CurrentTab = nil
        local windowTitle = "UI Library"
        local includeCustomization = true

        if type(titleOrOptions) == "table" then
            if type(titleOrOptions.Title) == "string" and titleOrOptions.Title ~= "" then
                windowTitle = titleOrOptions.Title
            elseif type(titleOrOptions.title) == "string" and titleOrOptions.title ~= "" then
                windowTitle = titleOrOptions.title
            end
            if type(titleOrOptions.IncludeCustomization) == "boolean" then
                includeCustomization = titleOrOptions.IncludeCustomization
            elseif type(titleOrOptions.ShowCustomization) == "boolean" then
                includeCustomization = titleOrOptions.ShowCustomization
            end
        elseif type(titleOrOptions) == "string" and titleOrOptions ~= "" then
            windowTitle = titleOrOptions
        end

        window.connections = {}
        window.cleanupFunctions = {}
        table.insert(window.cleanupFunctions, function()
            SavePersistConfig(true)
        end)
        local FPSCleanup = nil
        local Minimized = false
        local PlayersService = game:GetService("Players")
        local localPlayer = PlayersService.LocalPlayer
        
        local ScreenGui = CreateElement("ScreenGui", { Name = "UILibWindow", Parent = game:GetService("CoreGui"), ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false, IgnoreGuiInset = true })

        local MainFrame = CreateElement("Frame", { Name = "MainFrame", Parent = ScreenGui, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 590, 0, 440), ClipsDescendants = true, Visible = false }, {BackgroundColor3 = "MainBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.WindowCorner), Parent = MainFrame})
        CreateElement("UIStroke", {Thickness = 1.35, Transparency = 0.06, Parent = MainFrame}, {Color = "Stroke"})
        local MainGlassLayer = CreateElement("Frame", {
            Name = "MainGlassLayer",
            Parent = MainFrame,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 0
        })
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.WindowCorner), Parent = MainGlassLayer})
        local MainGlassGradient = Instance.new("UIGradient")
        MainGlassGradient.Name = "__UILibGlassGradient"
        MainGlassGradient.Rotation = 120
        MainGlassGradient.Parent = MainGlassLayer
        local mainScale = Instance.new("UIScale")
        mainScale.Scale = 1
        mainScale.Parent = MainFrame

        local topBarHeight = VisualTokens.TopBarHeight
        local expandedWidth, expandedHeight = 590, 440
        local function ComputeInterfaceScale(viewport)
            local vp = viewport or Vector2.new(1920, 1080)
            local shortestEdge = math.max(math.min(vp.X, vp.Y), 1)
            local adaptiveScale = math.clamp((shortestEdge / 1080) * 1.03, 0.84, 1.06)
            local userScale = math.clamp(tonumber(Options.UserScale) or 1, 0.78, 1.18)
            return math.clamp((Options.AutoScale and adaptiveScale or 1) * userScale, 0.72, 1.22)
        end
        local function ComputeWindowSize()
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
            local width = math.clamp(math.floor(viewport.X * 0.45), 500, 780)
            local height = math.clamp(math.floor(viewport.Y * 0.58), 380, 610)
            return width, height, viewport
        end
        local function GetWindowTargetState()
            local viewport
            expandedWidth, expandedHeight, viewport = ComputeWindowSize()
            local targetSize = Minimized and UDim2.new(0, expandedWidth, 0, topBarHeight) or UDim2.new(0, expandedWidth, 0, expandedHeight)
            local targetScale = ComputeInterfaceScale(viewport)
            return targetSize, targetScale
        end
        local function UpdateWindowSize(animate)
            local targetSize, targetScale = GetWindowTargetState()
            if animate then
                PlayTween(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
                PlayTween(mainScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = targetScale}):Play()
            else
                MainFrame.Size = targetSize
                mainScale.Scale = targetScale
            end
        end
        UpdateWindowSize(false)

        local PlayLoadedAnimation
        local OpenAnimationPlayed = false
        local function PlayOpenAnimation()
            if OpenAnimationPlayed then
                return
            end
            OpenAnimationPlayed = true

            local targetSize, targetScale = GetWindowTargetState()
            MainFrame.Visible = true

            MainFrame.Position = UDim2.new(0.5, 0, 0.5, 14)
            MainFrame.Size = UDim2.new(0, 0, 0, 0)
            mainScale.Scale = targetScale * 0.95
            PlayTween(MainFrame, TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = targetSize
            }):Play()
            PlayTween(mainScale, TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Scale = targetScale
            }):Play()
            task.delay(0.08, PlayLoadedAnimation)
        end
        
        local TopBar = CreateElement("Frame", { Name = "TopBar", Parent = MainFrame, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, topBarHeight) }, {BackgroundColor3 = "SecBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.WindowCorner), Parent = TopBar})
        CreateElement("Frame", { Parent = TopBar, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 10) }, {BackgroundColor3 = "SecBg"})
        local LoadingBarTrack = CreateElement("Frame", {
            Name = "LoadingBarTrack",
            Parent = TopBar,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 10, 1, -3),
            Size = UDim2.new(1, -20, 0, 2),
            BackgroundTransparency = 0.6
        }, {BackgroundColor3 = "QuarBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = LoadingBarTrack})
        local LoadingBarFill = CreateElement("Frame", {
            Name = "LoadingBarFill",
            Parent = LoadingBarTrack,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 0
        }, {BackgroundColor3 = "Accent"})
        CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = LoadingBarFill})

        local MainFrameGradient = Instance.new("UIGradient")
        MainFrameGradient.Name = "__UILibMainGradient"
        MainFrameGradient.Rotation = 132
        MainFrameGradient.Parent = MainFrame

        local TopBarGradient = Instance.new("UIGradient")
        TopBarGradient.Name = "__UILibTopBarGradient"
        TopBarGradient.Rotation = 90
        TopBarGradient.Parent = TopBar

        local TopAccentLine = CreateElement("Frame", {
            Parent = TopBar,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 12, 1, -2),
            Size = UDim2.new(1, -24, 0, 2),
            ZIndex = 4
        }, {
            BackgroundColor3 = "Accent"
        })
        CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = TopAccentLine})

        local TopAccentGradient = Instance.new("UIGradient")
        TopAccentGradient.Name = "__UILibTopAccentGradient"
        TopAccentGradient.Parent = TopAccentLine
        TopAccentGradient.Rotation = 0

        PlayLoadedAnimation = function()
            LoadingBarTrack.Visible = true
            LoadingBarTrack.BackgroundTransparency = 0.6
            LoadingBarFill.Size = UDim2.new(0, 0, 1, 0)
            LoadingBarFill.BackgroundTransparency = 0

            PlayTween(LoadingBarFill, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 1, 0)
            }):Play()

            task.delay(0.45, function()
                if LoadingBarTrack.Parent then
                    PlayTween(LoadingBarTrack, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 1
                    }):Play()
                    PlayTween(LoadingBarFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 1
                    }):Play()
                    task.delay(0.22, function()
                        if LoadingBarTrack.Parent then
                            LoadingBarTrack.Visible = false
                        end
                    end)
                end
            end)
        end

        local detachWindowThemeSync = RegisterThemeSync(function(colors)
            MainFrameGradient.Enabled = false
            MainGlassGradient.Enabled = false
            TopBarGradient.Enabled = false
            TopAccentGradient.Enabled = false
            TopAccentLine.Visible = false
            MainFrame.BackgroundTransparency = 0
            TopBar.BackgroundTransparency = 0
        end)
        table.insert(window.cleanupFunctions, detachWindowThemeSync)

        local TitleDot = CreateElement("Frame", {
            Parent = TopBar,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 16, 0.5, 0),
            Size = UDim2.new(0, 8, 0, 8),
            BorderSizePixel = 0
        }, {
            BackgroundColor3 = "Accent"
        })
        CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = TitleDot})

        local TitleLabel = CreateElement("TextLabel", { Parent = TopBar, BackgroundTransparency = 1, Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(0.28, 0, 1, 0), Font = Enum.Font.GothamBlack, Text = windowTitle, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, }, {TextColor3 = "Text"})
        local TabletBackButton = CreateElement("TextButton", { Parent = TopBar, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0.5, -12), Size = UDim2.new(0, 32, 0, 24), Font = Enum.Font.GothamBold, Text = "<", TextSize = 15, Visible = false, ZIndex = 4 }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = TabletBackButton})
        
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
            PlaceholderText = "Search controls...",
            Text = "",
            ClearTextOnFocus = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, VisualTokens.SearchWidth, 0, VisualTokens.SearchHeight),
            Font = Enum.Font.Gotham,
            TextSize = 11
        }, {
            BackgroundColor3 = "TerBg",
            TextColor3 = "Text",
            PlaceholderColor3 = "SubText"
        })

        CreateElement("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = SearchBox
        })

        CreateElement("UIStroke", {
            Parent = SearchBox,
            Thickness = 1
        }, {
            Color = "Stroke"
        })
        CreateElement("UIPadding", {Parent = SearchBox, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})

        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            ApplySearch(SearchBox.Text)
        end)



        local CloseButton = CreateElement("TextButton", { Parent = TopBar, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 28, 0, 28), Font = Enum.Font.GothamBold, Text = "X", TextSize = 12 }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = CloseButton})
        local MinimizeButton = CreateElement("TextButton", { Parent = TopBar, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -48, 0.5, 0), Size = UDim2.new(0, 28, 0, 28), Font = Enum.Font.GothamBold, Text = "-", TextSize = 15 }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = MinimizeButton})
        local SettingsButton = CreateElement("TextButton", { Parent = TopBar, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -82, 0.5, 0), Size = UDim2.new(0, 28, 0, 28), Font = Enum.Font.GothamBold, Text = "S", TextSize = 13 }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = SettingsButton})

        -- Sidebar Navigation Components
        local sidebarWidth = VisualTokens.SidebarWidth
        local TabContainer = CreateElement("Frame", { Name = "TabContainer", Parent = MainFrame, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, topBarHeight), Size = UDim2.new(0, sidebarWidth, 1, -topBarHeight) }, {BackgroundColor3 = "SecBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.WindowCorner - 1), Parent = TabContainer})
        CreateElement("UIStroke", {Thickness = 1.1, Parent = TabContainer}, {Color = "Stroke"})
        local TabContainerGradient = Instance.new("UIGradient")
        TabContainerGradient.Name = "__UILibSidebarGradient"
        TabContainerGradient.Rotation = 90
        TabContainerGradient.Parent = TabContainer

        local SidebarHeader = CreateElement("Frame", {
            Name = "SidebarHeader",
            Parent = TabContainer,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(1, -16, 0, 32)
        }, {
            BackgroundColor3 = "TerBg"
        })
        SidebarHeader.BackgroundTransparency = 0.14
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = SidebarHeader})
        CreateElement("TextLabel", {
            Parent = SidebarHeader,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -10, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = "SECTIONS",
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left
        }, {
            TextColor3 = "SubText"
        })

        local SidebarFooter = CreateElement("Frame", {
            Name = "SidebarFooter",
            Parent = TabContainer,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 8, 1, -8),
            Size = UDim2.new(1, -16, 0, 50)
        }, {
            BackgroundColor3 = "TerBg"
        })
        SidebarFooter.BackgroundTransparency = 0.14
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.SurfaceCorner), Parent = SidebarFooter})
        local FooterAvatar = CreateElement("Frame", {
            Parent = SidebarFooter,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.new(0, 26, 0, 26)
        }, {
            BackgroundColor3 = "QuarBg"
        })
        CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = FooterAvatar})
        local FooterAvatarImage = CreateElement("ImageLabel", {
            Parent = FooterAvatar,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
            ScaleType = Enum.ScaleType.Crop
        })
        CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = FooterAvatarImage})
        local FooterAvatarStroke = CreateElement("UIStroke", {
            Parent = FooterAvatarImage,
            Thickness = 1
        }, {
            Color = "Stroke"
        })
        if localPlayer then
            task.spawn(function()
                local ImageSize = Enum.ThumbnailSize.Size420x420
                local ImageType = Enum.ThumbnailType.HeadShot
                local ok, content = pcall(function()
                    return game:GetService("Players"):GetUserThumbnailAsync(
                        localPlayer.UserId,
                        ImageType,
                        ImageSize
                    )
                end)
                if ok and type(content) == "string" and FooterAvatarImage.Parent then
                    FooterAvatarImage.Image = content
                end
            end)
        end
        local FooterName = CreateElement("TextLabel", {
            Parent = SidebarFooter,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 42, 0, 6),
            Size = UDim2.new(1, -43, 0, 16),
            Font = Enum.Font.GothamBold,
            Text = (localPlayer and (localPlayer.DisplayName or localPlayer.Name)) or "Local Player",
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        }, {
            TextColor3 = "Text"
        })
        local FooterHandle = CreateElement("TextLabel", {
            Parent = SidebarFooter,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 42, 0, 24),
            Size = UDim2.new(1, -43, 0, 14),
            Font = Enum.Font.Gotham,
            Text = localPlayer and ("@" .. localPlayer.Name) or "@guest",
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left
        }, {
            TextColor3 = "SubText"
        })

        local detachSidebarThemeSync = RegisterThemeSync(function(colors)
            TabContainer.BackgroundTransparency = 0
            TabContainerGradient.Enabled = false
            SidebarHeader.BackgroundTransparency = 0.14
            SidebarFooter.BackgroundTransparency = 0.14
        end)
        table.insert(window.cleanupFunctions, detachSidebarThemeSync)

        local TabHolder = CreateElement("ScrollingFrame", { Name = "TabHolder", Parent = TabContainer, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 1, -92), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 0, BorderSizePixel = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y })
        local TabListLayout = CreateElement("UIListLayout", { Parent = TabHolder, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, FillDirection = Enum.FillDirection.Vertical })
        local TabPadding = CreateElement("UIPadding", {Parent = TabHolder, PaddingTop = UDim.new(0, 8)})

        local Separator = CreateElement("Frame", { Parent = MainFrame, BorderSizePixel = 0, Position = UDim2.new(0, sidebarWidth, 0, topBarHeight), Size = UDim2.new(0, 1, 1, -topBarHeight), ZIndex = 5 }, {BackgroundColor3 = "Stroke"})
        local ContentFrame = CreateElement("Frame", { Name = "ContentFrame", Parent = MainFrame, BorderSizePixel = 0, Position = UDim2.new(0, sidebarWidth + 10, 0, topBarHeight + 8), Size = UDim2.new(1, -(sidebarWidth + 22), 1, -(topBarHeight + 20)), ClipsDescendants = true }, {BackgroundColor3 = "SecBg"})
        ContentFrame.BackgroundTransparency = 0.04
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.SurfaceCorner + 2), Parent = ContentFrame})
        CreateElement("UIStroke", {Thickness = 1.2, Parent = ContentFrame}, {Color = "Stroke"})
        local TabletHomeFrame = CreateElement("ScrollingFrame", { Name = "TabletHomeFrame", Parent = ContentFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ScrollBarThickness = 2, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y }, {ScrollBarImageColor3 = "Stroke"})
        local TabletGridPadding = CreateElement("UIPadding", { Parent = TabletHomeFrame, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) })
        local TabletGridLayout = CreateElement("UIGridLayout", { Parent = TabletHomeFrame, CellPadding = UDim2.new(0, 8, 0, 8), CellSize = UDim2.new(0.5, -8, 0, 72), SortOrder = Enum.SortOrder.LayoutOrder, FillDirectionMaxCells = 2 })
        local BaseContentPos = ContentFrame.Position
        local BaseContentSize = ContentFrame.Size

        local EnablePlayerPanel = true
        local PlayerListCollapsed = false
        local PlayerListExpandedWidth = 236
        local PlayerListCollapsedWidth = 34
        local PlayerListGap = 8
        local PlayerAdminCallbacks = {}
        local SelectedAdminPlayer = nil
        local SpectateTargetPlayer = nil
        local SpectatePreviousSubject = nil
        local SpectateHeartbeatConnection = nil

        local function PlayerAdminNotify(title, content, duration)
            pcall(function()
                UILibrary:Notify({
                    Title = title,
                    Content = content,
                    Duration = duration or 2.4
                })
            end)
        end

        local function GetLocalRootPart()
            local character = localPlayer and localPlayer.Character
            return character and character:FindFirstChild("HumanoidRootPart")
        end

        local function GetTargetRootPart(targetPlayer)
            local character = targetPlayer and targetPlayer.Character
            return character and character:FindFirstChild("HumanoidRootPart")
        end

        local function StopSpectate()
            if SpectateHeartbeatConnection then
                SpectateHeartbeatConnection:Disconnect()
                SpectateHeartbeatConnection = nil
            end
            SpectateTargetPlayer = nil
            local currentCamera = workspace.CurrentCamera
            if currentCamera then
                if SpectatePreviousSubject then
                    currentCamera.CameraSubject = SpectatePreviousSubject
                elseif localPlayer and localPlayer.Character then
                    local localHumanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if localHumanoid then
                        currentCamera.CameraSubject = localHumanoid
                    end
                end
            end
            SpectatePreviousSubject = nil
        end

        local function StartSpectate(targetPlayer)
            if not targetPlayer then
                return false
            end
            local targetCharacter = targetPlayer.Character
            local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
            local currentCamera = workspace.CurrentCamera
            if not currentCamera or not targetHumanoid then
                return false
            end

            StopSpectate()
            SpectateTargetPlayer = targetPlayer
            SpectatePreviousSubject = currentCamera.CameraSubject
            currentCamera.CameraSubject = targetHumanoid

            SpectateHeartbeatConnection = RunService.Heartbeat:Connect(function()
                if not SpectateTargetPlayer then
                    return
                end
                local spectateCharacter = SpectateTargetPlayer.Character
                local spectateHumanoid = spectateCharacter and spectateCharacter:FindFirstChildOfClass("Humanoid")
                local camera = workspace.CurrentCamera
                if not spectateHumanoid or not camera then
                    StopSpectate()
                    return
                end
                if camera.CameraSubject ~= spectateHumanoid then
                    camera.CameraSubject = spectateHumanoid
                end
            end)

            return true
        end

        local function TeleportToPlayer(targetPlayer)
            local localRoot = GetLocalRootPart()
            local targetRoot = GetTargetRootPart(targetPlayer)
            if not localRoot or not targetRoot then
                return false
            end
            localRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
            return true
        end

        local function BringPlayer(targetPlayer)
            if type(PlayerAdminCallbacks.OnBringPlayer) == "function" then
                local ok, err = pcall(PlayerAdminCallbacks.OnBringPlayer, targetPlayer)
                if not ok then
                    PlayerAdminNotify("Bring", "Callback failed: " .. tostring(err), 3)
                end
                return ok
            end
            PlayerAdminNotify("Bring", "Unavailable in client-only mode.", 3)
            return false
        end

        local function AttemptUniversalBring(targetPlayer)
            local localCharacter = localPlayer and localPlayer.Character
            local targetCharacter = targetPlayer and targetPlayer.Character
            if not localCharacter or not targetCharacter then
                return false, "No character."
            end
            if not (localCharacter:IsDescendantOf(workspace) and targetCharacter:IsDescendantOf(workspace)) then
                return false, "Character not in workspace."
            end

            local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
            local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
            if not localRoot or not targetRoot then
                return false, "No HumanoidRootPart."
            end

            local from = targetRoot.CFrame
            local fromPosition = from.Position
            local to = localRoot.CFrame
            local toPosition = to.Position
            local distance = (fromPosition - toPosition).Magnitude - 3
            if distance <= 0 then
                return false, "Already close to target."
            end

            local lookVector = CFrame.new(fromPosition, toPosition).LookVector
            local velocity = 0
            local positionOffset = fromPosition - Vector3.new(0, 2, 0)
            toPosition = toPosition - Vector3.new(0, 2, 0)
            local tilt = CFrame.Angles(-math.pi / 2, 0, 0)
            local accel = 32
            local maxSpeed = 75
            local traveled = 0
            local reachedMaxAt = nil
            local now = os.clock()
            local last = now
            local timeoutAt = now + 4

            while localCharacter:IsDescendantOf(workspace) and targetCharacter:IsDescendantOf(workspace) and os.clock() < timeoutAt do
                now = os.clock()
                local dt = now - last
                last = now

                if reachedMaxAt then
                    if distance - traveled < reachedMaxAt then
                        velocity = velocity - (dt * accel)
                        if velocity < 0 then
                            break
                        end
                    end
                else
                    if traveled > (distance / 2) then
                        velocity = velocity - (dt * accel)
                        if velocity < 0 then
                            break
                        end
                    else
                        velocity = velocity + (dt * accel)
                        if velocity > maxSpeed then
                            reachedMaxAt = traveled
                            velocity = maxSpeed
                        end
                    end
                end

                traveled = traveled + (velocity * dt)

                local grounded = false
                local groundedOk, groundedResult = pcall(function()
                    return localRoot:IsGrounded()
                end)
                if groundedOk and groundedResult then
                    grounded = true
                end

                if not grounded then
                    localRoot.CFrame = CFrame.new(positionOffset + (lookVector * traveled), toPosition) * tilt
                    localRoot.AssemblyLinearVelocity = lookVector * (velocity + 1)
                    localRoot.AssemblyAngularVelocity = Vector3.zero
                end

                task.wait()
            end

            localRoot.CFrame = to
            localRoot.AssemblyLinearVelocity = Vector3.zero
            localRoot.AssemblyAngularVelocity = Vector3.zero
            return true
        end

        local function GetOtherPlayers()
            local list = {}
            for _, candidate in ipairs(PlayersService:GetPlayers()) do
                if candidate ~= localPlayer then
                    table.insert(list, candidate)
                end
            end
            table.sort(list, function(a, b)
                return string.lower(a.Name) < string.lower(b.Name)
            end)
            return list
        end

        local PlayerListFrame = CreateElement("Frame", {
            Name = "PlayerListFrame",
            Parent = ScreenGui,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(PlayerListExpandedWidth, 260),
            ClipsDescendants = true
        }, {BackgroundColor3 = "SecBg"})
        PlayerListFrame.BackgroundTransparency = 0.04
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.SurfaceCorner + 4), Parent = PlayerListFrame})
        local PlayerListStroke = CreateElement("UIStroke", {Thickness = 1.2, Parent = PlayerListFrame}, {Color = "Stroke"})
        local PlayerListScale = Instance.new("UIScale")
        PlayerListScale.Scale = 1
        PlayerListScale.Parent = PlayerListFrame

        local PlayerListHeader = CreateElement("Frame", {
            Parent = PlayerListFrame,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 34)
        }, {BackgroundColor3 = "TerBg"})
        PlayerListHeader.BackgroundTransparency = 0.08
        PlayerListHeader.ClipsDescendants = true
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.SurfaceCorner + 4), Parent = PlayerListHeader})
        CreateElement("TextLabel", {
            Parent = PlayerListHeader,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -36, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = "Players",
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        }, {TextColor3 = "Text"})
        local PlayerListToggleButton = CreateElement("TextButton", {
            Parent = PlayerListHeader,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -6, 0.5, 0),
            Size = UDim2.new(0, 22, 0, 22),
            Font = Enum.Font.GothamBold,
            Text = ">",
            TextSize = 12,
            AutoButtonColor = false
        }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner - 1), Parent = PlayerListToggleButton})
        CreateElement("Frame", { Parent = PlayerListHeader, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1) }, {BackgroundColor3 = "Stroke"})

        local PlayerListScroll = CreateElement("ScrollingFrame", {
            Name = "PlayerListScroll",
            Parent = PlayerListFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 34),
            Size = UDim2.new(1, 0, 1, -34),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 2,
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }, {ScrollBarImageColor3 = "Stroke"})
        local PlayerListLayout = CreateElement("UIListLayout", {
            Parent = PlayerListScroll,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6)
        })
        CreateElement("UIPadding", {
            Parent = PlayerListScroll,
            PaddingTop = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8)
        })

        local PlayerAdminOverlay = CreateElement("Frame", {
            Name = "PlayerAdminOverlay",
            Parent = MainFrame,
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ZIndex = 24
        })
        local PlayerAdminFrame = CreateElement("Frame", {
            Name = "PlayerAdminFrame",
            Parent = PlayerAdminOverlay,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 12),
            Size = UDim2.new(0, 520, 0, 372),
            ClipsDescendants = true,
            ZIndex = 25
        }, {BackgroundColor3 = "SecBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.WindowCorner - 1), Parent = PlayerAdminFrame})
        CreateElement("UIStroke", {Thickness = 1.15, Parent = PlayerAdminFrame}, {Color = "Stroke"})

        local PlayerAdminHeader = CreateElement("Frame", {
            Parent = PlayerAdminFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 56),
            ZIndex = 26
        })
        local PlayerAdminNameLabel = CreateElement("TextLabel", {
            Parent = PlayerAdminHeader,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 6),
            Size = UDim2.new(1, -54, 0, 24),
            Font = Enum.Font.GothamBold,
            Text = "Player",
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 26
        }, {TextColor3 = "Text"})
        local PlayerAdminUserLabel = CreateElement("TextLabel", {
            Parent = PlayerAdminHeader,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 29),
            Size = UDim2.new(1, -54, 0, 20),
            Font = Enum.Font.Gotham,
            Text = "@username",
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 26
        }, {TextColor3 = "SubText"})
        local PlayerAdminCloseButton = CreateElement("TextButton", {
            Parent = PlayerAdminHeader,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.new(0, 26, 0, 26),
            Font = Enum.Font.GothamBold,
            Text = "X",
            TextSize = 13,
            ZIndex = 26
        }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = PlayerAdminCloseButton})
        CreateElement("Frame", { Parent = PlayerAdminHeader, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), ZIndex = 26 }, {BackgroundColor3 = "Stroke"})

        local PlayerAdminActionScroll = CreateElement("ScrollingFrame", {
            Parent = PlayerAdminFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 56),
            Size = UDim2.new(1, 0, 1, -56),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 2,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 25
        }, {ScrollBarImageColor3 = "Stroke"})
        CreateElement("UIListLayout", {
            Parent = PlayerAdminActionScroll,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8)
        })
        CreateElement("UIPadding", {
            Parent = PlayerAdminActionScroll,
            PaddingTop = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10)
        })

        local function CreatePlayerActionButton(label, onClick)
            local button = CreateElement("TextButton", {
                Parent = PlayerAdminActionScroll,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40),
                Font = Enum.Font.GothamBold,
                Text = label,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                ZIndex = 25
            }, {BackgroundColor3 = "TerBg", TextColor3 = "Text"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = button})
            CreateElement("UIStroke", {Thickness = 1, Parent = button}, {Color = "Stroke"})
            CreateElement("UIPadding", {Parent = button, PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10)})
            button.MouseEnter:Connect(function()
                PlayTween(button, TweenInfo.new(0.15), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play()
            end)
            button.MouseLeave:Connect(function()
                PlayTween(button, TweenInfo.new(0.15), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play()
            end)
            button.MouseButton1Click:Connect(function()
                pcall(onClick)
            end)
            return button
        end

        local SpectateActionButton = nil

        local function RefreshSpectateButtonText()
            if not SpectateActionButton then
                return
            end
            local watchingSelected = SpectateTargetPlayer and SelectedAdminPlayer and (SpectateTargetPlayer == SelectedAdminPlayer)
            SpectateActionButton.Text = watchingSelected and "Stop Spectating" or "Spectate"
        end

        local function ClosePlayerAdminMenu()
            PlayTween(PlayerAdminOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            PlayTween(PlayerAdminFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 0.5, 12), BackgroundTransparency = 1}):Play()
            task.delay(0.2, function()
                if PlayerAdminOverlay.Parent then
                    PlayerAdminOverlay.Visible = false
                end
            end)
        end

        local function OpenPlayerAdminMenu(targetPlayer)
            if not targetPlayer then
                return
            end
            SelectedAdminPlayer = targetPlayer
            PlayerAdminNameLabel.Text = targetPlayer.DisplayName or targetPlayer.Name
            PlayerAdminUserLabel.Text = "@" .. targetPlayer.Name
            RefreshSpectateButtonText()
            PlayerAdminOverlay.Visible = true
            PlayerAdminOverlay.BackgroundTransparency = 1
            PlayerAdminFrame.Position = UDim2.new(0.5, 0, 0.5, 12)
            PlayerAdminFrame.BackgroundTransparency = 1
            PlayTween(PlayerAdminOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.44}):Play()
            PlayTween(PlayerAdminFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0}):Play()
        end

        SpectateActionButton = CreatePlayerActionButton("Spectate", function()
            if not SelectedAdminPlayer then
                return
            end
            if SpectateTargetPlayer == SelectedAdminPlayer then
                StopSpectate()
                RefreshSpectateButtonText()
                PlayerAdminNotify("Spectate", "Stopped spectating.")
                return
            end
            local ok = StartSpectate(SelectedAdminPlayer)
            RefreshSpectateButtonText()
            if ok then
                PlayerAdminNotify("Spectate", "Now watching " .. tostring(SelectedAdminPlayer.Name) .. ".")
            else
                PlayerAdminNotify("Spectate", "Target is not available.", 2.8)
            end
        end)
        CreatePlayerActionButton("Teleport To", function()
            if not SelectedAdminPlayer then
                return
            end
            local ok = TeleportToPlayer(SelectedAdminPlayer)
            if ok then
                PlayerAdminNotify("Teleport", "Teleported to " .. tostring(SelectedAdminPlayer.Name) .. ".")
            else
                PlayerAdminNotify("Teleport", "Unable to teleport right now.", 2.8)
            end
        end)
        CreatePlayerActionButton("Bring", function()
            if not SelectedAdminPlayer then
                return
            end
            local ok, err = AttemptUniversalBring(SelectedAdminPlayer)
            if ok then
                PlayerAdminNotify("Bring", "Attempted on " .. tostring(SelectedAdminPlayer.Name) .. ".")
            else
                PlayerAdminNotify("Bring", tostring(err or "Failed."), 2.8)
            end
        end)
        PlayerAdminCloseButton.MouseButton1Click:Connect(ClosePlayerAdminMenu)
        PlayerAdminOverlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local pos = input.Position
                local framePos = PlayerAdminFrame.AbsolutePosition
                local frameSize = PlayerAdminFrame.AbsoluteSize
                if pos.X < framePos.X or pos.X > framePos.X + frameSize.X or pos.Y < framePos.Y or pos.Y > framePos.Y + frameSize.Y then
                    ClosePlayerAdminMenu()
                end
            end
        end)

        local function RefreshPlayerListButtons()
            if not EnablePlayerPanel then
                return
            end
            for _, child in ipairs(PlayerListScroll:GetChildren()) do
                if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                    child:Destroy()
                end
            end

            local players = GetOtherPlayers()
            if #players == 0 then
                local emptyLabel = CreateElement("TextLabel", {
                    Parent = PlayerListScroll,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 26),
                    Font = Enum.Font.Gotham,
                    Text = "No players",
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left
                }, {TextColor3 = "SubText"})
                emptyLabel.LayoutOrder = 1
                return
            end

            for i, targetPlayer in ipairs(players) do
                local displayText = (targetPlayer.DisplayName or targetPlayer.Name) .. "  @" .. targetPlayer.Name
                local playerButton = CreateElement("TextButton", {
                    Parent = PlayerListScroll,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 32),
                    Font = Enum.Font.GothamBold,
                    Text = displayText,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false
                }, {BackgroundColor3 = "TerBg", TextColor3 = "Text"})
                playerButton.LayoutOrder = i
                playerButton.TextTruncate = Enum.TextTruncate.AtEnd
                CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner - 1), Parent = playerButton})
                CreateElement("UIPadding", {Parent = playerButton, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6)})
                CreateElement("UIStroke", {Thickness = 1, Parent = playerButton}, {Color = "Stroke"})
                playerButton.MouseEnter:Connect(function()
                    PlayTween(playerButton, TweenInfo.new(0.15), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play()
                end)
                playerButton.MouseLeave:Connect(function()
                    PlayTween(playerButton, TweenInfo.new(0.15), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play()
                end)
                playerButton.MouseButton1Click:Connect(function()
                    OpenPlayerAdminMenu(targetPlayer)
                end)
            end
        end

        local function GetPlayerListInsetOffset()
            return 0
        end

        local function ResolveFloatingPlayerListGeometry()
            local panelWidth = PlayerListCollapsed and PlayerListCollapsedWidth or PlayerListExpandedWidth
            local mainPos = MainFrame.AbsolutePosition
            local mainSize = MainFrame.AbsoluteSize
            local panelX = mainPos.X + mainSize.X + PlayerListGap
            local panelY = mainPos.Y + topBarHeight + 8
            local panelHeight = math.max(120, mainSize.Y - (topBarHeight + 20))
            return panelX, panelY, panelWidth, panelHeight
        end

        local function ApplyPlayerListVisual(animate)
            if not EnablePlayerPanel then
                PlayerListFrame.Visible = false
                return
            end
            local panelX, panelY, panelWidth, panelHeight = ResolveFloatingPlayerListGeometry()
            local panelPos = UDim2.fromOffset(panelX, panelY)
            local panelSize = UDim2.fromOffset(panelWidth, panelHeight)
            local titleVisible = not PlayerListCollapsed
            local listVisible = not PlayerListCollapsed
            PlayerListToggleButton.Text = PlayerListCollapsed and "<" or ">"
            if animate then
                PlayTween(PlayerListFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = panelPos,
                    Size = panelSize
                }):Play()
            else
                PlayerListFrame.Position = panelPos
                PlayerListFrame.Size = panelSize
            end
            PlayerListScroll.Visible = listVisible
            for _, child in ipairs(PlayerListHeader:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.Visible = titleVisible
                end
            end
        end

        local function AnimatePlayerListWithUI(show)
            if not EnablePlayerPanel then
                PlayerListFrame.Visible = false
                return
            end
            local panelX, panelY, panelWidth, panelHeight = ResolveFloatingPlayerListGeometry()
            local targetPos = UDim2.fromOffset(panelX, panelY)
            local hiddenPos = UDim2.fromOffset(panelX + 12, panelY + 4)
            local targetSize = UDim2.fromOffset(panelWidth, panelHeight)
            local titleVisible = not PlayerListCollapsed
            local listVisible = not PlayerListCollapsed
            PlayerListToggleButton.Text = PlayerListCollapsed and "<" or ">"
            PlayerListScroll.Visible = listVisible
            for _, child in ipairs(PlayerListHeader:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.Visible = titleVisible
                end
            end

            if show then
                PlayerListFrame.Visible = true
                PlayerListFrame.Size = targetSize
                PlayerListFrame.Position = hiddenPos
                PlayerListFrame.BackgroundTransparency = 1
                PlayerListStroke.Transparency = 1
                PlayerListScale.Scale = 0.96
                PlayTween(PlayerListFrame, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = targetPos,
                    BackgroundTransparency = 0.04
                }):Play()
                PlayTween(PlayerListStroke, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Transparency = 0
                }):Play()
                PlayTween(PlayerListScale, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Scale = 1
                }):Play()
            else
                if not PlayerListFrame.Visible then
                    return
                end
                PlayTween(PlayerListFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Position = hiddenPos,
                    BackgroundTransparency = 1
                }):Play()
                PlayTween(PlayerListStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Transparency = 1
                }):Play()
                PlayTween(PlayerListScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Scale = 0.96
                }):Play()
                task.delay(0.21, function()
                    if PlayerListFrame.Parent and (not show) then
                        PlayerListFrame.Visible = false
                    end
                end)
            end
        end

        local function ApplyContentFrameLayout(animate)
            local inset = GetPlayerListInsetOffset()
            local adjustedSize = UDim2.new(
                BaseContentSize.X.Scale,
                BaseContentSize.X.Offset - inset,
                BaseContentSize.Y.Scale,
                BaseContentSize.Y.Offset
            )
            if animate then
                PlayTween(ContentFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = BaseContentPos,
                    Size = adjustedSize
                }):Play()
            else
                ContentFrame.Position = BaseContentPos
                ContentFrame.Size = adjustedSize
            end
        end

        PlayerListToggleButton.MouseButton1Click:Connect(function()
            PlayerListCollapsed = not PlayerListCollapsed
            ApplyPlayerListVisual(true)
            ApplyContentFrameLayout(true)
        end)
        PlayerListToggleButton.MouseEnter:Connect(function()
            PlayTween(PlayerListToggleButton, TweenInfo.new(0.15), {BackgroundColor3 = Themes[Options.Theme].Hover, TextColor3 = Themes[Options.Theme].Text}):Play()
        end)
        PlayerListToggleButton.MouseLeave:Connect(function()
            PlayTween(PlayerListToggleButton, TweenInfo.new(0.15), {BackgroundColor3 = Themes[Options.Theme].QuarBg, TextColor3 = Themes[Options.Theme].SubText}):Play()
        end)

        if EnablePlayerPanel then
            RefreshPlayerListButtons()
            ApplyPlayerListVisual(false)
            ApplyContentFrameLayout(false)
        else
            PlayerListFrame.Visible = false
            ApplyContentFrameLayout(false)
        end

        table.insert(window.cleanupFunctions, function()
            StopSpectate()
        end)
        table.insert(window.cleanupFunctions, function()
            ClosePlayerAdminMenu()
        end)
        if EnablePlayerPanel then
            table.insert(window.connections, PlayersService.PlayerAdded:Connect(function()
                RefreshPlayerListButtons()
            end))
            table.insert(window.connections, PlayersService.PlayerRemoving:Connect(function(leavingPlayer)
                if SelectedAdminPlayer and leavingPlayer == SelectedAdminPlayer then
                    ClosePlayerAdminMenu()
                    SelectedAdminPlayer = nil
                end
                if SpectateTargetPlayer and leavingPlayer == SpectateTargetPlayer then
                    StopSpectate()
                    RefreshSpectateButtonText()
                end
                RefreshPlayerListButtons()
            end))
            table.insert(window.connections, MainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
                if MainFrame.Visible and not Minimized then
                    ApplyPlayerListVisual(false)
                end
            end))
            table.insert(window.connections, MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if MainFrame.Visible and not Minimized then
                    ApplyPlayerListVisual(false)
                end
            end))
        end

        -- Dropdown Navigation Components (V2)
        local NavDropdownFrame = CreateElement("Frame", { Parent = MainFrame, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, topBarHeight + 8), Size = UDim2.new(1, -20, 0, 38), ClipsDescendants = true, Visible = false, ZIndex = 10 }, {BackgroundColor3 = "TerBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.SurfaceCorner), Parent = NavDropdownFrame})
        CreateElement("UIStroke", {Thickness = 1.1, Parent = NavDropdownFrame}, {Color = "Stroke"})

        local NavDropdownBtn = CreateElement("TextButton", { Parent = NavDropdownFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35), Font = Enum.Font.GothamBold, Text = "Select Tab", TextSize = 14, ZIndex = 11 }, {TextColor3 = "Text"})
        local NavDropdownIcon = CreateElement("TextLabel", { Parent = NavDropdownBtn, BackgroundTransparency = 1, Position = UDim2.new(1, -25, 0, 0), Size = UDim2.new(0, 20, 1, 0), Font = Enum.Font.GothamBold, Text = "v", TextSize = 12, ZIndex = 11 }, {TextColor3 = "SubText"})

        local NavIsOpen = false
        local NavOptionContainer = nil
        local ActiveNavRowHeight = 28
        local ActiveNavFrameSize = UDim2.new(1, -24, 0, 38)
        local ActiveNavFramePos = UDim2.new(0, 12, 0, 60)
        local ActiveNavAnchor = Vector2.new(0, 0)
        local CurrentTabButtonMode = "Sidebar"
        local TopTabWidth = 124
        local TopTabHeight = 26
        local ActiveLayoutState = {
            ShowSidebar = true,
            ShowSeparator = true,
            ShowDropdown = false
        }
        local IsTabletHomeVisible = false

        local function SetTabletBackVisible(visible)
            TabletBackButton.Visible = visible
            TitleDot.Visible = not visible
            if visible then
                TitleLabel.Position = UDim2.new(0, 52, 0, 0)
                TitleLabel.Size = UDim2.new(0.24, 0, 1, 0)
            else
                TitleLabel.Position = UDim2.new(0, 32, 0, 0)
                TitleLabel.Size = UDim2.new(0.28, 0, 1, 0)
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
                return BlendColor(Themes[Options.Theme].TerBg, Themes[Options.Theme].MainBg, 0.15), BlendColor(Themes[Options.Theme].QuarBg, Themes[Options.Theme].Accent, 0.2)
            end
            return BlendColor(Themes[Options.Theme].SecBg, Themes[Options.Theme].MainBg, 0.2), BlendColor(Themes[Options.Theme].TerBg, Themes[Options.Theme].Accent, 0.24)
        end

        local function ApplyTabHolderMode(mode)
            CurrentTabButtonMode = mode or "Sidebar"
            if CurrentTabButtonMode == "Top" then
                SidebarHeader.Visible = false
                SidebarFooter.Visible = false
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
                SidebarHeader.Visible = true
                SidebarFooter.Visible = true
                TabHolder.Position = UDim2.new(0, 0, 0, 40)
                TabHolder.Size = UDim2.new(1, 0, 1, -92)
                TabHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
                TabHolder.ScrollingDirection = Enum.ScrollingDirection.Y
                TabHolder.ScrollBarThickness = 0
                TabListLayout.FillDirection = Enum.FillDirection.Vertical
                TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
                TabListLayout.Padding = UDim.new(0, 6)
                TabPadding.PaddingTop = UDim.new(0, 8)
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
                tabButton.TextSize = 13
                if buttonPadding then
                    buttonPadding.PaddingLeft = UDim.new(0, 0)
                    buttonPadding.PaddingRight = UDim.new(0, 0)
                end
                activeRail.AnchorPoint = Vector2.new(0, 0)
                activeRail.Position = UDim2.new(0, 10, 1, -4)
                activeRail.Size = UDim2.new(1, -20, 0, 2)
            else
                tabButton.Size = UDim2.new(1, -16, 0, 40)
                tabButton.TextXAlignment = Enum.TextXAlignment.Left
                tabButton.TextSize = 13
                if buttonPadding then
                    buttonPadding.PaddingLeft = UDim.new(0, 14)
                    buttonPadding.PaddingRight = UDim.new(0, 0)
                end
                activeRail.AnchorPoint = Vector2.new(1, 0.5)
                activeRail.Position = UDim2.new(1, -4, 0.5, 0)
                activeRail.Size = UDim2.new(0, 3, 0, 22)
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
            local sidebarDefault = sidebarWidth
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
                    NavSize = UDim2.new(1, -20, 0, 38),
                    NavAnchor = Vector2.new(0, 0),
                    NavRow = 26
                }
            elseif style == "TopBar" then
                preset = {
                    ShowSidebar = true,
                    ShowSeparator = false,
                    ShowDropdown = false,
                    TabMode = "Top",
                    TopTabWidth = 120,
                    TopTabHeight = 26,
                    SidebarSize = UDim2.new(1, -20, 0, 40),
                    SidebarPos = UDim2.new(0, 10, 0, topBarHeight + 6),
                    SeparatorPos = UDim2.new(0, sidebarDefault, 0, topBarHeight),
                    ContentPos = UDim2.new(0, 10, 0, topBarHeight + 54),
                    ContentSize = UDim2.new(1, -20, 1, -(topBarHeight + 66)),
                    NavPos = UDim2.new(0, 10, 0, contentTop),
                    NavSize = UDim2.new(1, -20, 0, 38),
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
                    NavSize = UDim2.new(1, -20, 0, 38),
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
                    NavSize = UDim2.new(1, -20, 0, 38),
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
                    NavSize = UDim2.new(1, -20, 0, 38),
                    NavAnchor = Vector2.new(0, 0),
                    NavRow = 26
                }
            end

            ActiveNavFramePos = preset.NavPos
            ActiveNavFrameSize = preset.NavSize
            ActiveNavAnchor = preset.NavAnchor
            ActiveNavRowHeight = preset.NavRow
            TopTabWidth = preset.TopTabWidth or 124
            TopTabHeight = preset.TopTabHeight or 26
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
            BaseContentPos = preset.ContentPos
            BaseContentSize = preset.ContentSize
            ApplyContentFrameLayout(true)
            ApplyPlayerListVisual(true)
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

        local SettingsFrame = CreateElement("Frame", { Name = "SettingsFrame", Parent = SettingsOverlay, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10), Size = UDim2.new(0, 680, 0, 462), ClipsDescendants = true }, {BackgroundColor3 = "SecBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.WindowCorner - 1), Parent = SettingsFrame})
        CreateElement("UIStroke", {Thickness = 1.15, Parent = SettingsFrame}, {Color = "Stroke"})
        
        local SettingsHeader = CreateElement("Frame", { Parent = SettingsFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56) })
        CreateElement("TextLabel", { Parent = SettingsHeader, BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 4), Size = UDim2.new(1, -64, 0, 24), Font = Enum.Font.GothamBold, Text = "Library Settings", TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
        CreateElement("TextLabel", { Parent = SettingsHeader, BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 28), Size = UDim2.new(1, -64, 0, 20), Font = Enum.Font.Gotham, Text = "Configure menu behavior, profiles and runtime tools.", TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "SubText"})
        CreateElement("Frame", { Parent = SettingsHeader, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1) }, {BackgroundColor3 = "Stroke"})
        local CloseSettingsButton = CreateElement("TextButton", {Parent = SettingsHeader, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 26, 0, 26), Font = Enum.Font.GothamBold, Text = "X", TextSize = 14}, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = CloseSettingsButton})

        local SettingsBody = CreateElement("Frame", { Parent = SettingsFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 56), Size = UDim2.new(1, 0, 1, -56) })
        local SettingsSidebarPanel = CreateElement("Frame", {
            Parent = SettingsBody,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 10, 0, 10),
            Size = UDim2.new(0, 200, 1, -20)
        }, {BackgroundColor3 = "TerBg"})
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.SurfaceCorner), Parent = SettingsSidebarPanel})
        CreateElement("UIStroke", {Thickness = 1, Parent = SettingsSidebarPanel}, {Color = "Stroke"})
        CreateElement("TextLabel", {
            Parent = SettingsSidebarPanel,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 8),
            Size = UDim2.new(1, -24, 0, 18),
            Font = Enum.Font.GothamBold,
            Text = "SECTIONS",
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left
        }, {TextColor3 = "SubText"})
        local SettingsSidebar = CreateElement("ScrollingFrame", {
            Parent = SettingsSidebarPanel,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 28),
            Size = UDim2.new(1, 0, 1, -34),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y
        }, {ScrollBarImageColor3 = "Stroke"})
        CreateElement("UIListLayout", {Parent = SettingsSidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        CreateElement("UIPadding", {Parent = SettingsSidebar, PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)})

        local SettingsContentPanel = CreateElement("Frame", {
            Parent = SettingsBody,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 220, 0, 10),
            Size = UDim2.new(1, -230, 1, -20)
        }, {BackgroundColor3 = "MainBg"})
        SettingsContentPanel.BackgroundTransparency = 0.12
        CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.SurfaceCorner), Parent = SettingsContentPanel})
        CreateElement("UIStroke", {Thickness = 1, Parent = SettingsContentPanel}, {Color = "Stroke"})
        local SettingsContent = CreateElement("Frame", { Parent = SettingsContentPanel, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(1, -16, 1, -16) })

        local SettingsTabs = {}
        local CurrentSettingsPage = nil
        local CurrentSettingsContainer = nil

        local function SwitchSettingsTab(name)
            for n, tab in pairs(SettingsTabs) do
                tab.Page.Visible = (n == name)
                if n == name then
                    PlayTween(tab.Button, TweenInfo.new(0.2), {TextColor3 = Themes[Options.Theme].Text, BackgroundTransparency = 0.56}):Play()
                    if tab.ActiveRail then
                        PlayTween(tab.ActiveRail, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
                    end
                else
                    PlayTween(tab.Button, TweenInfo.new(0.2), {TextColor3 = Themes[Options.Theme].SubText, BackgroundTransparency = 0.86}):Play()
                    if tab.ActiveRail then
                        PlayTween(tab.ActiveRail, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                    end
                end
            end
            CurrentSettingsContainer = nil
        end

        local function CreateSettingsSection(text, description)
            if SettingsTabs[text] then return end
            local tabBtn = CreateElement("TextButton", { Parent = SettingsSidebar, BackgroundTransparency = 0.86, Size = UDim2.new(1, 0, 0, 36), Text = text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, {BackgroundColor3 = "TerBg", TextColor3 = "SubText"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = tabBtn})
            CreateElement("UIStroke", {Thickness = 1, Parent = tabBtn}, {Color = "Stroke"})
            CreateElement("UIPadding", {Parent = tabBtn, PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 10)})
            local activeRail = CreateElement("Frame", {
                Parent = tabBtn,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, 3, 0, 20),
                BackgroundTransparency = 1
            }, {BackgroundColor3 = "Accent"})
            CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = activeRail})

            local page = CreateElement("ScrollingFrame", { Parent = SettingsContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y })
            CreateElement("UIListLayout", {Parent = page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 9)})
            CreateElement("UIPadding", {Parent = page, PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingBottom = UDim.new(0, 6)})

            local introCard = CreateElement("Frame", {
                Parent = page,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 58),
                LayoutOrder = 0
            }, {BackgroundColor3 = "TerBg"})
            introCard.BackgroundTransparency = 0.04
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.SurfaceCorner), Parent = introCard})
            CreateElement("UIStroke", {Thickness = 1, Parent = introCard}, {Color = "Stroke"})
            CreateElement("TextLabel", {
                Parent = introCard,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8),
                Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            }, {TextColor3 = "Text"})
            CreateElement("TextLabel", {
                Parent = introCard,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 28),
                Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.Gotham,
                Text = description or "Configure this section.",
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left
            }, {TextColor3 = "SubText"})

            SettingsTabs[text] = {Button = tabBtn, Page = page, ActiveRail = activeRail}
            CurrentSettingsPage = page
            CurrentSettingsContainer = nil
            tabBtn.MouseButton1Click:Connect(function() SwitchSettingsTab(text) end)
            tabBtn.MouseEnter:Connect(function()
                if not page.Visible then
                    PlayTween(tabBtn, TweenInfo.new(0.15), {TextColor3 = Themes[Options.Theme].Text, BackgroundTransparency = 0.72}):Play()
                end
            end)
            tabBtn.MouseLeave:Connect(function()
                if not page.Visible then
                    PlayTween(tabBtn, TweenInfo.new(0.15), {TextColor3 = Themes[Options.Theme].SubText, BackgroundTransparency = 0.86}):Play()
                end
            end)
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
            groupFrame.BackgroundTransparency = 0.06
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.SurfaceCorner), Parent = groupFrame})
            CreateElement("UIStroke", {Thickness = 1.05, Parent = groupFrame}, {Color = "Stroke"})

            local headerButton = CreateElement("TextButton", {
                Parent = groupFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 36),
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
                TextSize = 12,
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
                Position = UDim2.new(0, 0, 0, 36),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            CreateElement("UIListLayout", {Parent = content, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
            CreateElement("UIPadding", {Parent = content, PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})

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
            button.Size = UDim2.new(1, 0, 0, 42)
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = button})
            CreateElement("UIStroke", {Thickness = VisualTokens.CardStroke, Parent = button}, {Color = "Stroke"})
            CreateElement("TextLabel", { Parent = button, BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -15, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
            button.MouseEnter:Connect(function() PlayTween(button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play() end)
            button.MouseLeave:Connect(function() PlayTween(button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play() end)
            button.MouseButton1Click:Connect(function() pcall(callback); PlayTween(button, TweenInfo.new(0.1), {Size = UDim2.new(1, -2, 0, 40)}):Play(); task.wait(0.1); PlayTween(button, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 42)}):Play() end)
        end

        local function CreateSettingsCycle(text, values, defaultValue, callback)
            local cycleFrame = CreateElement("Frame", { Parent = ResolveSettingsParent(), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 46) }, {BackgroundColor3 = "TerBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = cycleFrame})
            CreateElement("UIStroke", {Thickness = VisualTokens.CardStroke, Parent = cycleFrame}, {Color = "Stroke"})
            CreateElement("TextLabel", { Parent = cycleFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.5, 0, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
            local cycleButton = CreateElement("TextButton", { Parent = cycleFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 164, 0, 30), Font = Enum.Font.GothamBold, Text = tostring(defaultValue or "None"), TextSize = 12, AutoButtonColor = false }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner - 1), Parent = cycleButton})
            CreateElement("UIStroke", {Thickness = 1, Parent = cycleButton}, {Color = "Stroke"})

            local options = values or {}
            local index = 1
            for i, value in ipairs(options) do
                if value == defaultValue then
                    index = i
                    break
                end
            end
            local function sync(skipCallback)
                local current = options[index]
                cycleButton.Text = tostring(current or "None")
                if not skipCallback then
                    pcall(callback, current)
                end
            end
            cycleButton.MouseButton1Click:Connect(function()
                if #options == 0 then
                    return
                end
                index = index + 1
                if index > #options then
                    index = 1
                end
                sync(false)
            end)
            sync(true)
            return {
                SetValues = function(_, newValues)
                    options = newValues or {}
                    if #options == 0 then
                        index = 1
                        cycleButton.Text = "None"
                        return
                    end
                    if index > #options then
                        index = 1
                    end
                    sync(true)
                end,
                SetValue = function(_, value)
                    for i, option in ipairs(options) do
                        if option == value then
                            index = i
                            sync(true)
                            break
                        end
                    end
                end,
                GetValue = function()
                    return options[index]
                end
            }
        end

        local function CreateSettingsDropdown(text, options, default, callback)
            local dropdownFrame = CreateElement("Frame", { Parent = ResolveSettingsParent(), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 46), ClipsDescendants = true }, {BackgroundColor3 = "TerBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = dropdownFrame})
            CreateElement("UIStroke", {Thickness = VisualTokens.CardStroke, Parent = dropdownFrame}, {Color = "Stroke"})
            local titleLabel = CreateElement("TextLabel", { Parent = dropdownFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.5, 0, 0, 46), Font = Enum.Font.GothamBold, Text = text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})

            local dropdownButton = CreateElement("TextButton", { Parent = dropdownFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.new(0, 128, 0, 30), Font = Enum.Font.GothamBold, Text = default or options[1] or "None", TextSize = 12, AutoButtonColor = false }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner - 1), Parent = dropdownButton})
            
            local isOpen = false; local optionContainer
            local headerHeight, rowHeight = 46, 30
            local function resolveComboMetrics()
                if Options.ComboStyle == "Compact" then
                    return 42, 26, 114, 24
                elseif Options.ComboStyle == "Soft" then
                    return 50, 32, 136, 32
                end
                return 46, 30, 128, 30
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

        local function CreateSettingsKeybind(text, defaultKey, callback)
            local keybindFrame = CreateElement("Frame", { Parent = ResolveSettingsParent(), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 46) }, {BackgroundColor3 = "TerBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = keybindFrame})
            CreateElement("UIStroke", {Thickness = VisualTokens.CardStroke, Parent = keybindFrame}, {Color = "Stroke"})
            CreateElement("TextLabel", { Parent = keybindFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.55, 0, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})

            local keybindButton = CreateElement("TextButton", { Parent = keybindFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 120, 0, 30), Font = Enum.Font.GothamBold, Text = "None", TextSize = 12, AutoButtonColor = false }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner - 1), Parent = keybindButton})
            local keybindStroke = CreateElement("UIStroke", {Thickness = 1, Parent = keybindButton}, {Color = "Stroke"})

            local currentKey = (typeof(defaultKey) == "EnumItem") and defaultKey or Enum.KeyCode.Insert
            keybindButton.Text = currentKey.Name
            local waiting = false

            local function setKeybind(newKey, skipCallback)
                if newKey ~= nil and typeof(newKey) ~= "EnumItem" then
                    return
                end
                currentKey = newKey
                keybindButton.Text = currentKey and currentKey.Name or "None"
                if not skipCallback then
                    pcall(callback, currentKey)
                end
            end

            keybindButton.MouseButton1Click:Connect(function()
                if waiting then
                    return
                end
                waiting = true
                keybindButton.Text = "..."
                PlayTween(keybindStroke, TweenInfo.new(0.2), {Color = Themes[Options.Theme].Accent}):Play()

                local connection
                connection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        setKeybind(input.KeyCode, false)
                        waiting = false
                        PlayTween(keybindStroke, TweenInfo.new(0.2), {Color = Themes[Options.Theme].Stroke}):Play()
                        if connection then
                            connection:Disconnect()
                        end
                    end
                end)
            end)

            return {
                SetValue = function(_, newKey)
                    setKeybind(newKey, true)
                end,
                GetValue = function()
                    return currentKey
                end
            }
        end

        local collapseKeyStore = UILibrary:RegisterValue("uilib_menu_toggle_key", Enum.KeyCode.Insert)
        local collapseKey = collapseKeyStore and collapseKeyStore:Get() or Enum.KeyCode.Insert
        if typeof(collapseKey) ~= "EnumItem" then
            collapseKey = Enum.KeyCode.Insert
        end

        local function SettingsNotify(title, content, duration)
            pcall(function()
                UILibrary:Notify({
                    Title = title,
                    Content = content,
                    Duration = duration or 2.5
                })
            end)
        end

        -- // Initialize Global Settings Options //
        if includeCustomization then
            CreateSettingsSection("Interface", "Window sizing and scale behavior.")
            CreateSettingsGroup("Scale", true)
            CreateSettingsDropdown("Scale Mode", {"Auto", "Manual"}, Options.AutoScale and "Auto" or "Manual", function(val)
                Options.AutoScale = (val == "Auto")
                SaveLibraryOptions()
                UpdateWindowSize(false)
            end)
            local scalePresets = {0.78, 0.84, 0.9, 0.96, 1, 1.06, 1.12, 1.18}
            local scaleLabels = {}
            local scaleLabelToValue = {}
            for _, value in ipairs(scalePresets) do
                local label = tostring(math.floor(value * 100 + 0.5)) .. "%"
                table.insert(scaleLabels, label)
                scaleLabelToValue[label] = value
            end
            local defaultScaleLabel = "100%"
            local bestDelta = math.huge
            for _, label in ipairs(scaleLabels) do
                local value = scaleLabelToValue[label]
                local delta = math.abs(value - (Options.UserScale or 1))
                if delta < bestDelta then
                    bestDelta = delta
                    defaultScaleLabel = label
                end
            end
            CreateSettingsDropdown("UI Scale", scaleLabels, defaultScaleLabel, function(label)
                local selectedScale = scaleLabelToValue[label]
                if type(selectedScale) == "number" then
                    Options.UserScale = selectedScale
                    SaveLibraryOptions()
                    UpdateWindowSize(false)
                end
            end)
        end

        local selectedProfileName = UILibrary:GetActiveProfile()
        local profilePicker = nil
        local function refreshProfilePicker(preferredProfile)
            local names = UILibrary:GetProfiles()
            if #names == 0 then
                names = {PersistConfig.DefaultProfile}
            end
            local target = preferredProfile or selectedProfileName
            local exists = false
            for _, profileName in ipairs(names) do
                if profileName == target then
                    exists = true
                    break
                end
            end
            if not exists then
                target = names[1]
            end
            selectedProfileName = target
            if profilePicker then
                profilePicker:SetValues(names)
                profilePicker:SetValue(selectedProfileName)
            end
        end

        local function generateProfileName()
            return "Profile_" .. os.date("%Y%m%d_%H%M%S")
        end

        CreateSettingsSection("Config", "Profiles, saving, loading and import/export.")
        CreateSettingsGroup("Profiles", true)
        profilePicker = CreateSettingsCycle("Active Profile", UILibrary:GetProfiles(), selectedProfileName, function(profileName)
            if type(profileName) == "string" and profileName ~= "" then
                selectedProfileName = profileName
            end
        end)
        refreshProfilePicker(selectedProfileName)
        CreateSettingsButton("Save Profile", function()
            local savedName = UILibrary:SaveProfile(selectedProfileName)
            refreshProfilePicker(savedName)
            SettingsNotify("Config", "Saved profile: " .. tostring(savedName))
        end)
        CreateSettingsButton("Save As New Profile", function()
            local newName = UILibrary:SaveProfile(generateProfileName())
            refreshProfilePicker(newName)
            SettingsNotify("Config", "Created profile: " .. tostring(newName))
        end)
        CreateSettingsButton("Load Selected Profile", function()
            local loaded = UILibrary:LoadProfile(selectedProfileName)
            if not loaded then
                SettingsNotify("Config", "Failed to load profile.", 3)
                return
            end
            ApplyLoadedLibraryOptions()
            ApplyRuntimeLibraryOptions()
            UpdateWindowSize(false)
            SettingsNotify("Config", "Loaded profile: " .. tostring(selectedProfileName), 3)
        end)
        CreateSettingsButton("Delete Selected Profile", function()
            local deleted = UILibrary:DeleteProfile(selectedProfileName)
            if deleted then
                refreshProfilePicker(UILibrary:GetActiveProfile())
                SettingsNotify("Config", "Deleted profile.", 3)
            else
                SettingsNotify("Config", "Cannot delete this profile.", 3)
            end
        end)
        CreateSettingsGroup("Import / Export", false)
        CreateSettingsButton("Copy Profile To Clipboard", function()
            local payload = UILibrary:ExportConfig(selectedProfileName)
            if type(payload) == "string" and type(setclipboard) == "function" then
                setclipboard(payload)
                SettingsNotify("Config", "Profile copied to clipboard.", 2.5)
            elseif type(payload) == "string" then
                SettingsNotify("Config", "Clipboard API unavailable.", 3)
            else
                SettingsNotify("Config", "Export failed.", 3)
            end
        end)
        CreateSettingsButton("Import Profile From Clipboard", function()
            local readClip = (type(getclipboard) == "function" and getclipboard)
                or (type(readclipboard) == "function" and readclipboard)
            if type(readClip) ~= "function" then
                SettingsNotify("Config", "Clipboard read API unavailable.", 3)
                return
            end
            local raw = readClip()
            local ok, importedName = UILibrary:ImportConfig(raw, nil, false)
            if ok then
                refreshProfilePicker(importedName)
                SettingsNotify("Config", "Imported profile: " .. tostring(importedName), 3)
            else
                SettingsNotify("Config", "Import failed. Invalid payload.", 3)
            end
        end)

        CreateSettingsSection("General", "Global runtime behavior for this library.")
        CreateSettingsGroup("Runtime", true)
        CreateSettingsKeybind("Menu Toggle Key", collapseKey, function(newKey)
            if typeof(newKey) ~= "EnumItem" then
                return
            end
            collapseKey = newKey
            if collapseKeyStore then
                collapseKeyStore:Set(collapseKey)
            end
        end)
        local function CreateSettingsToggle(text, callback)
            local toggleButton = CreateElement("TextButton", { Parent = ResolveSettingsParent(), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 46), AutoButtonColor = false, Text = "" }, {BackgroundColor3 = "TerBg"})
            toggleButton.BackgroundTransparency = 0.05
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = toggleButton})
            local stroke = CreateElement("UIStroke", {Thickness = VisualTokens.CardStroke, Parent = toggleButton}, {Color = "Stroke"})
            CreateElement("TextLabel", { Parent = toggleButton, BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.7, 0, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
            
            local toggleContainer = CreateElement("Frame", { Parent = toggleButton, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 44, 0, 22) })
            
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
        CreateSettingsSection("Performance", "Optional visual reductions and FPS helpers.")
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

        CreateSettingsSection("Developer", "External tools and debugging utilities.")
        CreateSettingsGroup("Tools", true)
        CreateSettingsButton("Load Remotespy", function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-RemoteSpy-for-Xeno-and-Solara-32578"))() end)
        CreateSettingsButton("Load DevEx", function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Dex-with-tags-78265"))() end)

        local function ToggleSettings()
            if SettingsOverlay.Visible then
                PlayTween(SettingsOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                PlayTween(SettingsFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 0.5, 12), BackgroundTransparency = 1}):Play()
                task.delay(0.2, function() SettingsOverlay.Visible = false end)
            else
                SettingsOverlay.Visible = true; SettingsOverlay.BackgroundTransparency = 1; SettingsFrame.Position = UDim2.new(0.5, 0, 0.5, 12); SettingsFrame.BackgroundTransparency = 1
                PlayTween(SettingsOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.42}):Play()
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
        CloseSettingsButton.MouseEnter:Connect(function() PlayTween(CloseSettingsButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover, TextColor3 = Themes[Options.Theme].Text}):Play() end)
        CloseSettingsButton.MouseLeave:Connect(function() PlayTween(CloseSettingsButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].QuarBg, TextColor3 = Themes[Options.Theme].SubText}):Play() end)
        PlayerAdminCloseButton.MouseEnter:Connect(function() PlayTween(PlayerAdminCloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover, TextColor3 = Themes[Options.Theme].Text}):Play() end)
        PlayerAdminCloseButton.MouseLeave:Connect(function() PlayTween(PlayerAdminCloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].QuarBg, TextColor3 = Themes[Options.Theme].SubText}):Play() end)
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
            AnimatePlayerListWithUI(false)
            PlayTween(mainScale, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Scale = mainScale.Scale * 0.95
            }):Play()
            PlayTween(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
            task.wait(0.3); ScreenGui:Destroy()
        end)

        local function MinimizeUI()
            Minimized = not Minimized
            
            -- Preserve Layout specific visibility
            if Minimized then
                TabContainer.Visible = false; ContentFrame.Visible = false; NavDropdownFrame.Visible = false
                AnimatePlayerListWithUI(false)
                PlayerAdminOverlay.Visible = false
            else
                ContentFrame.Visible = true
                PlayerListFrame.Visible = EnablePlayerPanel
                TabContainer.Visible = ActiveLayoutState.ShowSidebar
                Separator.Visible = ActiveLayoutState.ShowSeparator
                NavDropdownFrame.Visible = ActiveLayoutState.ShowDropdown
                ApplyPlayerListVisual(false)
                ApplyContentFrameLayout(false)
                AnimatePlayerListWithUI(true)
            end
            
            UpdateWindowSize(true)
        end
        MinimizeButton.MouseButton1Click:Connect(MinimizeUI)

        local UIVisible = true
        local function ToggleUI()
            UIVisible = not UIVisible
            if UIVisible then
                MainFrame.Visible = true
                PlayerListFrame.Visible = EnablePlayerPanel and (not Minimized)
                UpdateWindowSize(false)
                MainFrame.Size = UDim2.new(0, 0, 0, 0)
                mainScale.Scale = mainScale.Scale * 0.95
                PlayTween(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = Minimized and UDim2.new(0, expandedWidth, 0, topBarHeight) or UDim2.new(0, expandedWidth, 0, expandedHeight),
                    Position = UDim2.new(0.5, 0, 0.5, 0)
                }):Play()
                PlayTween(mainScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Scale = ComputeInterfaceScale(workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080))
                }):Play()
                if not Minimized then
                    AnimatePlayerListWithUI(true)
                end
            else
                PlayerAdminOverlay.Visible = false
                AnimatePlayerListWithUI(false)
                PlayTween(mainScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Scale = mainScale.Scale * 0.95
                }):Play()
                PlayTween(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, 0, 0, 0)
                }):Play()
                task.delay(0.3, function()
                    if not UIVisible then
                        MainFrame.Visible = false
                    end
                end)
            end
        end

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

        function window:SetPlayerAdminCallbacks(callbacks)
            if type(callbacks) == "table" then
                PlayerAdminCallbacks = callbacks
            else
                PlayerAdminCallbacks = {}
            end
            return self
        end

        function window:SetPlayerListCollapsed(state)
            PlayerListCollapsed = state and true or false
            ApplyPlayerListVisual(true)
            ApplyContentFrameLayout(true)
            return self
        end

        function window:RefreshPlayerList()
            RefreshPlayerListButtons()
            return self
        end

        function window:CreateTab(name)


            local tab = { Name = name, Elements = {} }
            local tabButton = CreateElement("TextButton", { Name = name .. "Tab", Parent = TabHolder, BackgroundTransparency = 0.1, BorderSizePixel = 0, AutoButtonColor = false, Size = UDim2.new(1, -16, 0, 42), Font = Enum.Font.GothamBold, Text = name, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, {BackgroundColor3 = "SecBg", TextColor3 = "SubText"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.SurfaceCorner), Parent = tabButton})
            CreateElement("UIPadding", {Parent = tabButton, PaddingLeft = UDim.new(0, 15)})
            local activeRail = CreateElement("Frame", { Parent = tabButton, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.new(0, 4, 0, 24), BackgroundTransparency = 1 }, {BackgroundColor3 = "Accent"})
            CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = activeRail})
            
            local page = CreateElement("ScrollingFrame", {
                Name = name .. "Page",
                Parent = ContentFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ScrollBarThickness = 3,
                Visible = false
            }, {ScrollBarImageColor3 = "Stroke"})
            CreateElement("UIListLayout", {Parent = page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, VisualTokens.SectionGap)})
            CreateElement("UIPadding", {
                Parent = page,
                PaddingRight = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 5),
                PaddingTop = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 8)
            })
            local tabletTile = CreateElement("TextButton", { Name = name .. "Tile", Parent = TabletHomeFrame, BorderSizePixel = 0, AutoButtonColor = false, Text = name, Font = Enum.Font.GothamBold, TextSize = 15 }, {BackgroundColor3 = "TerBg", TextColor3 = "Text"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.SurfaceCorner), Parent = tabletTile})
            CreateElement("UIStroke", {Parent = tabletTile, Thickness = 1.1}, {Color = "Stroke"})
            
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
                local button = CreateElement("TextButton", { Parent = page, BorderSizePixel = 0, AutoButtonColor = false, Size = UDim2.new(1, 0, 0, VisualTokens.ControlHeight), Font = Enum.Font.GothamBold, Text = text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg", TextColor3 = "Text"})
                button.BackgroundTransparency = 0.05
                CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = button})
                CreateElement("UIPadding", {Parent = button, PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})
                local buttonStroke = CreateElement("UIStroke", {Thickness = VisualTokens.CardStroke, Transparency = 0, Parent = button}, {Color = "Stroke"})
                
                button.MouseEnter:Connect(function() PlayTween(button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].Hover}):Play(); PlayTween(buttonStroke, TweenInfo.new(0.2), {Color = Themes[Options.Theme].Accent}):Play() end)
                button.MouseLeave:Connect(function() PlayTween(button, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Options.Theme].TerBg}):Play(); PlayTween(buttonStroke, TweenInfo.new(0.2), {Color = Themes[Options.Theme].Stroke}):Play() end)
                button.MouseButton1Click:Connect(function() pcall(callback); PlayTween(button, TweenInfo.new(0.1), {Size = UDim2.new(1, -4, 0, VisualTokens.ControlHeight - 4)}):Play(); task.wait(0.1); PlayTween(button, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, VisualTokens.ControlHeight)}):Play() end)
                table.insert(tab.Elements, button)
                return button
            end

            function tab:CreateToggle(text, callback, defaultState, saveKey)
                local toggleFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, VisualTokens.ControlHeight), LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                toggleFrame.BackgroundTransparency = 0.05
                CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = toggleFrame})
                CreateElement("UIStroke", {Thickness = VisualTokens.CardStroke, Transparency = 0, Parent = toggleFrame}, {Color = "Stroke"})
                
                CreateElement("TextLabel", { Parent = toggleFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.7, 0, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                local toggleButton = CreateElement("TextButton", { Parent = toggleFrame, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 40, 0, 20), Text = "" })
                
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
                table.insert(tab.Elements, toggleFrame)
                return toggleFrame
            end

            function tab:CreateKeybind(text, callback, defaultKey, saveKey)
                local keybindFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, VisualTokens.ControlHeight), LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                keybindFrame.BackgroundTransparency = 0.05
                CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = keybindFrame})
                CreateElement("UIStroke", {Thickness = VisualTokens.CardStroke, Transparency = 0, Parent = keybindFrame}, {Color = "Stroke"})
                
                CreateElement("TextLabel", { Parent = keybindFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                local keybindButton = CreateElement("TextButton", { Parent = keybindFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 84, 0, 22), Font = Enum.Font.GothamBold, Text = "None", TextSize = 12 }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
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
                local sliderFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 58), LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                sliderFrame.BackgroundTransparency = 0.05
                CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = sliderFrame})
                CreateElement("UIStroke", {Thickness = VisualTokens.CardStroke, Transparency = 0, Parent = sliderFrame}, {Color = "Stroke"})
                local fallbackValue = tonumber(default) or min
                fallbackValue = math.clamp(fallbackValue, min, max)
                local loadedValue, sliderStore = ResolvePersistedValue(saveKey, fallbackValue)
                local currentValue = tonumber(loadedValue) or fallbackValue
                currentValue = math.clamp(currentValue, min, max)

                CreateElement("TextLabel", { Parent = sliderFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(0.5, 0, 0.4, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                local valueLabel = CreateElement("TextLabel", { Parent = sliderFrame, BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.new(0.5, -12, 0.4, 0), Font = Enum.Font.Gotham, Text = tostring(currentValue), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right }, {TextColor3 = "SubText"})
                local sliderBar = CreateElement("TextButton", { Parent = sliderFrame, BorderSizePixel = 0, Position = UDim2.new(0.03, 0, 0.68, 0), Size = UDim2.new(0.94, 0, 0.14, 0), Text = "" }, {BackgroundColor3 = "QuarBg"})
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
                    applySliderValue(currentValue, true)
                end
                table.insert(tab.Elements, sliderFrame)
                return sliderFrame
            end

            function tab:CreateCycleButton(text, values, default, callback, saveKey)
                local cycleFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, VisualTokens.ControlHeight), LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                cycleFrame.BackgroundTransparency = 0.05
                CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = cycleFrame})
                CreateElement("UIStroke", {Thickness = VisualTokens.CardStroke, Transparency = 0, Parent = cycleFrame}, {Color = "Stroke"})
                local fallbackValue = default or values[1]
                local loadedValue, cycleStore = ResolvePersistedValue(saveKey, fallbackValue)

                CreateElement("TextLabel", { Parent = cycleFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                local cycleButton = CreateElement("TextButton", { Parent = cycleFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 104, 0, 22), Font = Enum.Font.GothamBold, Text = tostring(loadedValue or fallbackValue or "None"), TextSize = 12 }, {BackgroundColor3 = "QuarBg", TextColor3 = "Text"})
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
                    update(true)
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
                local dropdownFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 48), ClipsDescendants = true, LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                dropdownFrame.BackgroundTransparency = 0.05
                CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = dropdownFrame})
                CreateElement("UIStroke", {Thickness = VisualTokens.CardStroke, Transparency = 0, Parent = dropdownFrame}, {Color = "Stroke"})
                local titleLabel = CreateElement("TextLabel", { Parent = dropdownFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, 0, 0, 48), Font = Enum.Font.GothamBold, Text = text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})

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

                local dropdownButton = CreateElement("TextButton", { Parent = dropdownFrame, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 124, 0, 30), Font = Enum.Font.GothamBold, Text = currentValue or "None", TextSize = 12, AutoButtonColor = false }, {BackgroundColor3 = "QuarBg", TextColor3 = "SubText"})
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = dropdownButton})
                CreateElement("UIStroke", {Thickness = 1, Transparency = 0, Parent = dropdownButton}, {Color = "Stroke"})
                local headerHeight, rowHeight = 46, 30
                local function resolveComboMetrics()
                    if Options.ComboStyle == "Compact" then
                        return 42, 26, 116, 24
                    elseif Options.ComboStyle == "Soft" then
                        return 50, 32, 136, 32
                    end
                    return 46, 30, 126, 30
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
                local function optionExists(value)
                    for _, option in ipairs(options) do
                        if option == value then
                            return true
                        end
                    end
                    return false
                end

                local function rebuildOptionContainer()
                    if optionContainer then
                        optionContainer:Destroy()
                    end
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
                end

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
                        rebuildOptionContainer()
                        PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, headerHeight + (#options * rowHeight) + 10)}):Play()
                    else
                        PlayTween(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, headerHeight)}):Play(); task.delay(0.2, function() if optionContainer then optionContainer:Destroy() end end)
                    end
                end)
                applyComboStyle(true)
                if dropdownStore and currentValue ~= nil then
                    setDropdownValue(currentValue, true)
                end
                table.insert(tab.Elements, dropdownFrame)
                return {
                    Frame = dropdownFrame,
                    SetValues = function(_, newOptions)
                        options = {}
                        for _, option in ipairs(newOptions or {}) do
                            table.insert(options, option)
                        end
                        if #options == 0 then
                            table.insert(options, "None")
                        end
                        if not optionExists(currentValue) then
                            setDropdownValue(options[1], true)
                        else
                            setDropdownValue(currentValue, true)
                        end
                        if isOpen then
                            rebuildOptionContainer()
                        end
                        applyComboStyle(true)
                    end,
                    SetValue = function(_, value)
                        if optionExists(value) then
                            setDropdownValue(value, true)
                        elseif #options > 0 then
                            setDropdownValue(options[1], true)
                        end
                    end,
                    GetValue = function()
                        return currentValue
                    end
                }
            end

            function tab:CreateParagraph(title, content)
                local paragraphFrame = CreateElement("Frame", { Parent = page, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = #page:GetChildren() }, {BackgroundColor3 = "TerBg"})
                paragraphFrame.BackgroundTransparency = 0.04
                CreateElement("UICorner", {CornerRadius = UDim.new(0, VisualTokens.ControlCorner), Parent = paragraphFrame})
                CreateElement("UIStroke", {Thickness = VisualTokens.CardStroke, Transparency = 0, Parent = paragraphFrame}, {Color = "Stroke"})
                CreateElement("TextLabel", { Parent = paragraphFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 10), Size = UDim2.new(1, -24, 0, 15), Font = Enum.Font.GothamBold, Text = title, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, {TextColor3 = "Text"})
                CreateElement("TextLabel", { Parent = paragraphFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 30), Size = UDim2.new(1, -24, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Gotham, Text = content, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true }, {TextColor3 = "SubText"})
                CreateElement("UIPadding", {Parent = paragraphFrame, PaddingBottom = UDim.new(0, 12)})
                
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
                local container = Instance.new("Frame"); container.Name = "Container"; container.Parent = notificationGui; container.BackgroundTransparency = 1; container.AnchorPoint = Vector2.new(1, 0); container.Position = UDim2.new(1, -20, 0, 80); container.Size = UDim2.new(0, 320, 1, -100)
                local layout = Instance.new("UIListLayout"); layout.Parent = container; layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 10); layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            end
            
            local container = notificationGui:FindFirstChild("Container")
            local title, content, duration = args.Title or "Notification", args.Content or "", args.Duration or 5
            local kind = string.lower(tostring(args.Type or args.Kind or "info"))
            local notifPalette = {
                info = {
                    stroke = Themes[Options.Theme].Accent,
                    title = Themes[Options.Theme].Text,
                    content = Themes[Options.Theme].SubText,
                    icon = "i"
                },
                warning = {
                    stroke = Color3.fromRGB(255, 184, 77),
                    title = Color3.fromRGB(255, 223, 168),
                    content = Color3.fromRGB(232, 198, 140),
                    icon = "!"
                },
                error = {
                    stroke = Color3.fromRGB(255, 90, 90),
                    title = Color3.fromRGB(255, 205, 205),
                    content = Color3.fromRGB(239, 166, 166),
                    icon = "x"
                }
            }
            if kind == "warn" then
                kind = "warning"
            end
            local notifStyle = notifPalette[kind] or notifPalette.info
            local displayTitle = tostring(title)
            local frame = CreateElement("TextButton", { Name = "Notification", Parent = container, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 74), AutomaticSize = Enum.AutomaticSize.Y, AutoButtonColor = false, Text = "" }, {BackgroundColor3 = "SecBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = frame})
            local stroke = CreateElement("UIStroke", {Thickness = 1.2, Transparency = 0.2, Parent = frame})
            stroke.Color = notifStyle.stroke
            local minCard = Instance.new("UISizeConstraint")
            minCard.MinSize = Vector2.new(0, 74)
            minCard.Parent = frame

            local leftAccent = CreateElement("Frame", {
                Parent = frame,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 5, 1, 0)
            })
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = leftAccent})
            leftAccent.BackgroundColor3 = notifStyle.stroke

            local iconBg = CreateElement("Frame", {
                Parent = frame,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 12, 0, 10),
                Size = UDim2.new(0, 24, 0, 24)
            })
            iconBg.BackgroundColor3 = Color3.fromRGB(
                math.floor((notifStyle.stroke.R * 255 + Themes[Options.Theme].MainBg.R * 255) * 0.5),
                math.floor((notifStyle.stroke.G * 255 + Themes[Options.Theme].MainBg.G * 255) * 0.5),
                math.floor((notifStyle.stroke.B * 255 + Themes[Options.Theme].MainBg.B * 255) * 0.5)
            )
            CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = iconBg})
            local iconLabel = CreateElement("TextLabel", {
                Parent = iconBg,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = notifStyle.icon,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center
            })
            iconLabel.TextColor3 = notifStyle.title

            local closeButton = CreateElement("TextButton", {
                Parent = frame,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -28, 0, 8),
                Size = UDim2.new(0, 20, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = "X",
                TextSize = 13,
                AutoButtonColor = false
            })
            closeButton.TextColor3 = Themes[Options.Theme].SubText

            local titleLabel = CreateElement("TextLabel", { Parent = frame, BackgroundTransparency = 1, Position = UDim2.new(0, 44, 0, 7), Size = UDim2.new(1, -84, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.GothamBold, Text = displayTitle, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true })
            titleLabel.TextColor3 = notifStyle.title
            local contentLabel = CreateElement("TextLabel", { Parent = frame, BackgroundTransparency = 1, Position = UDim2.new(0, 44, 0, 30), Size = UDim2.new(1, -56, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Gotham, Text = tostring(content), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true })
            contentLabel.TextColor3 = notifStyle.content
            local function refreshCardLayout()
                contentLabel.Position = UDim2.new(0, 44, 0, 10 + titleLabel.AbsoluteSize.Y + 6)
                local bottomPad = 12
                local timerHeight = 3
                local topY = contentLabel.Position.Y.Offset
                local needed = topY + contentLabel.AbsoluteSize.Y + timerHeight + bottomPad
                if needed > 74 then
                    frame.Size = UDim2.new(1, 0, 0, needed)
                else
                    frame.Size = UDim2.new(1, 0, 0, 74)
                end
            end
            titleLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshCardLayout)
            contentLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshCardLayout)
            task.defer(refreshCardLayout)

            local timerTrack = CreateElement("Frame", {
                Parent = frame,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 10, 1, -8),
                Size = UDim2.new(1, -20, 0, 3)
            }, {BackgroundColor3 = "QuarBg"})
            CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = timerTrack})
            local timerFill = CreateElement("Frame", {
                Parent = timerTrack,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0)
            })
            timerFill.BackgroundColor3 = notifStyle.stroke
            CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = timerFill})

            local cardScale = Instance.new("UIScale")
            cardScale.Scale = 0.92
            cardScale.Parent = frame
            local iconScale = Instance.new("UIScale")
            iconScale.Scale = 0.78
            iconScale.Parent = iconBg

            frame.BackgroundTransparency = 1
            stroke.Transparency = 1
            leftAccent.BackgroundTransparency = 1
            iconBg.BackgroundTransparency = 1
            iconLabel.TextTransparency = 1
            closeButton.TextTransparency = 1
            titleLabel.TextTransparency = 1
            contentLabel.TextTransparency = 1
            timerTrack.BackgroundTransparency = 1
            timerFill.BackgroundTransparency = 1

            PlayTween(cardScale, TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
            PlayTween(iconScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
            PlayTween(frame, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
            PlayTween(stroke, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.2}):Play()
            PlayTween(leftAccent, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
            PlayTween(iconBg, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
            PlayTween(iconLabel, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
            PlayTween(closeButton, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
            PlayTween(titleLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
            PlayTween(contentLabel, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
            PlayTween(timerTrack, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
            PlayTween(timerFill, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
            PlayTween(timerFill, TweenInfo.new(math.max(0.05, duration), Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Size = UDim2.new(0, 0, 1, 0)}):Play()
            local closing = false
            local function close()
                if closing or (not frame.Parent) then return end
                closing = true
                PlayTween(cardScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.94}):Play()
                PlayTween(iconScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.7}):Play()
                PlayTween(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
                PlayTween(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
                PlayTween(leftAccent, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
                PlayTween(iconBg, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
                PlayTween(iconLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
                PlayTween(closeButton, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
                PlayTween(titleLabel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
                PlayTween(contentLabel, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
                PlayTween(timerTrack, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
                PlayTween(timerFill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
                task.delay(0.22, function()
                    if frame and frame.Parent then
                        frame:Destroy()
                    end
                end)
            end
            closeButton.MouseEnter:Connect(function()
                PlayTween(closeButton, TweenInfo.new(0.15), {TextColor3 = notifStyle.title}):Play()
            end)
            closeButton.MouseLeave:Connect(function()
                PlayTween(closeButton, TweenInfo.new(0.15), {TextColor3 = Themes[Options.Theme].SubText}):Play()
            end)
            frame.MouseButton1Click:Connect(close)
            closeButton.MouseButton1Click:Connect(close)
            task.delay(duration, close)
        end

        function UILibrary:NotifyInfo(args)
            args = args or {}
            args.Type = "info"
            return UILibrary:Notify(args)
        end

        function UILibrary:NotifyWarning(args)
            args = args or {}
            args.Type = "warning"
            return UILibrary:Notify(args)
        end

        function UILibrary:NotifyError(args)
            args = args or {}
            args.Type = "error"
            return UILibrary:Notify(args)
        end
        
        -- Initialize the correct layout immediately on startup
        for _, func in ipairs(Registries.MenuLayout) do func(Options.MenuStyle) end
        ApplyStrokeStyleVisuals(true)
        SaveLibraryOptions()
        task.defer(PlayOpenAnimation)
        
        return window
    end
    return UILibrary
end)()

return UILibrary


