-- // IMPORTS // --
local UILibrary = (function()
    local UILibrary = {}
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local function CreateElement(class, properties)
        local element = Instance.new(class)
        for prop, value in pairs(properties) do
            element[prop] = value
        end
        return element
    end
    function UILibrary:CreateWindow(title)
        local window = {}
        local tabs = {}
        window.connections = {}
        window.cleanupFunctions = {}
        local FPSCleanup = nil
        local Minimized = false
        local ScreenGui = CreateElement("ScreenGui", {
            Name = "UILibWindow",
            Parent = game:GetService("CoreGui"),
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false,
            IgnoreGuiInset = true
        })
        local MainFrame = CreateElement("Frame", {
            Name = "MainFrame",
            Parent = ScreenGui,
            BackgroundColor3 = Color3.fromRGB(10, 10, 10),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 600, 0, 450),
            ClipsDescendants = true,
            Visible = true
        })
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = MainFrame})
        CreateElement("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1, Transparency = 0, Parent = MainFrame})
        
        local TopBar = CreateElement("Frame", {
            Name = "TopBar",
            Parent = MainFrame,
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 40)
        })
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = TopBar})
        -- Patch to square off bottom corners of TopBar
        CreateElement("Frame", {
            Parent = TopBar,
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -10),
            Size = UDim2.new(1, 0, 0, 10)
        })
        
        CreateElement("TextLabel", {
            Parent = TopBar,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 15, 0, 0),
            Size = UDim2.new(0.5, 0, 1, 0),
            Font = Enum.Font.GothamBlack,
            Text = title or "UI Library",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        local CloseButton = CreateElement("TextButton", {
            Parent = TopBar,
            BackgroundColor3 = Color3.fromRGB(200, 50, 50),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.new(0, 24, 0, 24),
            Font = Enum.Font.GothamBold,
            Text = "X",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14
        })
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = CloseButton})
        
        local MinimizeButton = CreateElement("TextButton", {
            Parent = TopBar,
            BackgroundColor3 = Color3.fromRGB(200, 150, 50),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -40, 0.5, 0),
            Size = UDim2.new(0, 24, 0, 24),
            Font = Enum.Font.GothamBold,
            Text = "-",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14
        })
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = MinimizeButton})
        
        local CollapseKeybindButton = CreateElement("TextButton", {
            Parent = TopBar,
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -70, 0.5, 0),
            Size = UDim2.new(0, 30, 0, 24),
            Font = Enum.Font.GothamBold,
            Text = "Ins",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12
        })
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = CollapseKeybindButton})
        
        local SettingsButton = CreateElement("TextButton", {
            Parent = TopBar,
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -105, 0.5, 0),
            Size = UDim2.new(0, 24, 0, 24),
            Font = Enum.Font.GothamBold,
            Text = "⚙",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14
        })
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = SettingsButton})

        local TabContainer = CreateElement("Frame", {
            Name = "TabContainer",
            Parent = MainFrame,
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 40),
            Size = UDim2.new(0, 150, 1, -40)
        })
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 10), Parent = TabContainer})
        -- Patch to square off top corners of TabContainer
        CreateElement("Frame", {
            Parent = TabContainer,
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 10)
        })
        -- Patch to square off right corners of TabContainer
        CreateElement("Frame", {
            Parent = TabContainer,
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BorderSizePixel = 0,
            Position = UDim2.new(1, -10, 0, 0),
            Size = UDim2.new(0, 10, 1, 0)
        })
        
        local TabHolder = CreateElement("ScrollingFrame", {
            Name = "TabHolder",
            Parent = TabContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 0,
            BorderSizePixel = 0,
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        })
        
        CreateElement("UIListLayout", {
            Parent = TabHolder,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        })
        CreateElement("UIPadding", {Parent = TabHolder, PaddingTop = UDim.new(0, 10)})

        -- Separator Line (Moved to MainFrame to avoid UIListLayout issues)
        CreateElement("Frame", {
            Parent = MainFrame,
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 150, 0, 40),
            Size = UDim2.new(0, 1, 1, -40),
            ZIndex = 5
        })

        local ContentFrame = CreateElement("Frame", {
            Name = "ContentFrame",
            Parent = MainFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 160, 0, 50),
            Size = UDim2.new(1, -170, 1, -60)
        })

        -- // Settings Menu // --
        local SettingsOverlay = CreateElement("Frame", {
            Name = "SettingsOverlay",
            Parent = MainFrame,
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ZIndex = 20
        })

        local SettingsFrame = CreateElement("Frame", {
            Name = "SettingsFrame",
            Parent = SettingsOverlay,
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 10),
            Size = UDim2.new(0, 500, 0, 350),
            ClipsDescendants = true
        })
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 14), Parent = SettingsFrame})
        CreateElement("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1, Parent = SettingsFrame})
        
        local SettingsHeader = CreateElement("Frame", {
            Parent = SettingsFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40)
        })

        CreateElement("TextLabel", {
            Parent = SettingsHeader,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 20, 0, 0),
            Size = UDim2.new(1, -50, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = "Settings",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local CloseSettingsButton = CreateElement("TextButton", {Parent = SettingsHeader, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), Size = UDim2.new(0, 24, 0, 24), Font = Enum.Font.GothamBold, Text = "X", TextColor3 = Color3.fromRGB(200, 200, 200), TextSize = 16})

        local SettingsBody = CreateElement("Frame", {
            Parent = SettingsFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 40),
            Size = UDim2.new(1, 0, 1, -40),
        })

        local SettingsSidebar = CreateElement("ScrollingFrame", {
            Parent = SettingsBody,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 140, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 0
        })
        CreateElement("UIListLayout", {Parent = SettingsSidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
        CreateElement("UIPadding", {Parent = SettingsSidebar, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10)})

        local SettingsSeparator = CreateElement("Frame", {
            Parent = SettingsBody,
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 140, 0, 10),
            Size = UDim2.new(0, 1, 1, -20)
        })

        local SettingsContent = CreateElement("Frame", {
            Parent = SettingsBody,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 150, 0, 0),
            Size = UDim2.new(1, -150, 1, 0)
        })

        local SettingsTabs = {}
        local CurrentSettingsPage = nil

        local function SwitchSettingsTab(name)
            for n, tab in pairs(SettingsTabs) do
                tab.Page.Visible = (n == name)
                if n == name then
                    TweenService:Create(tab.Button, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9}):Play()
                else
                    TweenService:Create(tab.Button, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundTransparency = 1}):Play()
                end
            end
        end

        local function CreateSettingsSection(text)
            if SettingsTabs[text] then
                CurrentSettingsPage = SettingsTabs[text].Page
                return
            end

            local tabBtn = CreateElement("TextButton", {
                Parent = SettingsSidebar,
                BackgroundTransparency = 1,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Size = UDim2.new(1, -10, 0, 30),
                Text = text,
                Font = Enum.Font.GothamBold,
                TextColor3 = Color3.fromRGB(150, 150, 150),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false
            })
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = tabBtn})
            CreateElement("UIPadding", {Parent = tabBtn, PaddingLeft = UDim.new(0, 10)})

            local page = CreateElement("ScrollingFrame", {
                Parent = SettingsContent,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Visible = false,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 2,
                AutomaticCanvasSize = Enum.AutomaticSize.Y
            })
            CreateElement("UIListLayout", {Parent = page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
            CreateElement("UIPadding", {Parent = page, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})

            SettingsTabs[text] = {Button = tabBtn, Page = page}
            CurrentSettingsPage = page

            tabBtn.MouseButton1Click:Connect(function()
                SwitchSettingsTab(text)
            end)

            -- Select first tab automatically
            if not next(SettingsTabs, next(SettingsTabs)) then
                SwitchSettingsTab(text)
            end
        end

        local function CreateSettingsButton(text, callback)
            local button = CreateElement("TextButton", {
                Parent = CurrentSettingsPage,
                BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40),
                AutoButtonColor = false,
                Text = ""
            })
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = button})
            local stroke = CreateElement("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1, Parent = button})
            
            CreateElement("TextLabel", {
                Parent = button,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 0),
                Size = UDim2.new(1, -15, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = text,
                TextColor3 = Color3.fromRGB(230, 230, 230),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            button.MouseEnter:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
            end)
            button.MouseLeave:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
            end)
            button.MouseButton1Click:Connect(function()
                pcall(callback)
                TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(1, -2, 0, 38)}):Play()
                task.wait(0.1)
                TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 40)}):Play()
            end)
        end

        local function CreateSettingsToggle(text, callback)
            local toggleButton = CreateElement("TextButton", {
                Parent = CurrentSettingsPage,
                BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 45),
                AutoButtonColor = false,
                Text = ""
            })
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = toggleButton})
            local stroke = CreateElement("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1, Parent = toggleButton})
            
            CreateElement("TextLabel", {
                Parent = toggleButton,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 0),
                Size = UDim2.new(0.7, 0, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = text,
                TextColor3 = Color3.fromRGB(230, 230, 230),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local switchBg = CreateElement("Frame", {
                Parent = toggleButton,
                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -15, 0.5, 0),
                Size = UDim2.new(0, 44, 0, 22)
            })
            CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = switchBg})
            
            local switchCircle = CreateElement("Frame", {
                Parent = switchBg,
                BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 2, 0.5, 0),
                Size = UDim2.new(0, 18, 0, 18)
            })
            CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = switchCircle})
            
            local toggled = false
            
            local function UpdateToggle()
                toggled = not toggled
                if toggled then
                    TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 40, 40)}):Play()
                    TweenService:Create(switchCircle, TweenInfo.new(0.2), {Position = UDim2.new(1, -20, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                    TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(220, 40, 40)}):Play()
                else
                    TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
                    TweenService:Create(switchCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}):Play()
                    TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(60, 60, 60)}):Play()
                end
                pcall(callback, toggled)
            end
            
            toggleButton.MouseButton1Click:Connect(UpdateToggle)
            
            toggleButton.MouseEnter:Connect(function()
                TweenService:Create(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
            end)
            toggleButton.MouseLeave:Connect(function()
                TweenService:Create(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
            end)
        end

        local function CreateSettingsDropdown(text, options, default, callback)
            local dropdownFrame = CreateElement("Frame", {
                Parent = CurrentSettingsPage,
                BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 45),
                ClipsDescendants = true
            })
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 8), Parent = dropdownFrame})
            local stroke = CreateElement("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1, Parent = dropdownFrame})
            
            CreateElement("TextLabel", {
                Parent = dropdownFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 0),
                Size = UDim2.new(0.5, 0, 0, 45),
                Font = Enum.Font.GothamBold,
                Text = text,
                TextColor3 = Color3.fromRGB(230, 230, 230),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local dropdownButton = CreateElement("TextButton", {
                Parent = dropdownFrame,
                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -15, 0, 8),
                Size = UDim2.new(0, 120, 0, 28),
                Font = Enum.Font.GothamBold,
                Text = default or options[1] or "None",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 12,
                AutoButtonColor = false
            })
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = dropdownButton})
            
            local isOpen = false
            local optionContainer
            
            dropdownButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    if optionContainer then optionContainer:Destroy() end
                    
                    optionContainer = CreateElement("Frame", {
                        Parent = dropdownFrame,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 45),
                        Size = UDim2.new(1, 0, 0, #options * 30)
                    })
                    
                    for i, opt in ipairs(options) do
                        local optBtn = CreateElement("TextButton", {
                            Parent = optionContainer,
                            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 10, 0, (i-1)*30),
                            Size = UDim2.new(1, -20, 0, 28),
                            Font = Enum.Font.Gotham,
                            Text = opt,
                            TextColor3 = Color3.fromRGB(200, 200, 200),
                            TextSize = 12,
                            AutoButtonColor = false
                        })
                        CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = optBtn})
                        
                        optBtn.MouseEnter:Connect(function()
                            TweenService:Create(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
                        end)
                        optBtn.MouseLeave:Connect(function()
                            TweenService:Create(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                        end)
                        
                        optBtn.MouseButton1Click:Connect(function()
                            dropdownButton.Text = opt
                            isOpen = false
                            TweenService:Create(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45)}):Play()
                            task.delay(0.2, function() if optionContainer then optionContainer:Destroy() end end)
                            pcall(callback, opt)
                        end)
                    end
                    
                    TweenService:Create(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45 + (#options * 30) + 10)}):Play()
                else
                    TweenService:Create(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45)}):Play()
                    task.delay(0.2, function() if optionContainer then optionContainer:Destroy() end end)
                end
            end)
        end

        CreateSettingsSection("General")
        CreateSettingsToggle("Performance Mode (FPS Boost)", function(state)
            if state then
                local Lighting = game:GetService("Lighting")
                local StoredAtmosphere = Lighting:FindFirstChild("Atmosphere")
                if StoredAtmosphere then StoredAtmosphere.Parent = nil end
                
                Lighting.GlobalShadows = false
                
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then
                        v.Material = Enum.Material.SmoothPlastic
                        v.CastShadow = false
                    elseif v:IsA("Texture") or v:IsA("Decal") then
                        v.Transparency = 1
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                        v.Enabled = false
                    end
                end

                FPSCleanup = function()
                    Lighting.GlobalShadows = true
                    if StoredAtmosphere then StoredAtmosphere.Parent = Lighting end
                    
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then
                            v.Material = Enum.Material.Plastic
                            v.CastShadow = true
                        elseif v:IsA("Texture") or v:IsA("Decal") then
                            v.Transparency = 0
                        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                            v.Enabled = true
                        end
                    end
                end
            else
                if FPSCleanup then FPSCleanup() FPSCleanup = nil end
            end
        end)

        CreateSettingsSection("Themes")
        CreateSettingsDropdown("Interface Theme", {"Default", "Dark", "Light", "Discord"}, "Default", function(val)
            -- Theme logic placeholder
        end)

        CreateSettingsSection("Developer")
        CreateSettingsButton("Load Remotespy", function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-RemoteSpy-for-Xeno-and-Solara-32578"))()
        end)

        CreateSettingsButton("Load DevEx", function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Dex-with-tags-78265"))()
        end)

        local function ToggleSettings()
            if SettingsOverlay.Visible then
                TweenService:Create(SettingsOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                TweenService:Create(SettingsFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 0.5, 10), BackgroundTransparency = 1}):Play()
                task.delay(0.2, function() SettingsOverlay.Visible = false end)
            else
                SettingsOverlay.Visible = true
                SettingsOverlay.BackgroundTransparency = 1
                SettingsFrame.Position = UDim2.new(0.5, 0, 0.5, 10)
                SettingsFrame.BackgroundTransparency = 1
                
                TweenService:Create(SettingsOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
                TweenService:Create(SettingsFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0}):Play()
            end
        end

        SettingsButton.MouseButton1Click:Connect(ToggleSettings)
        CloseSettingsButton.MouseButton1Click:Connect(ToggleSettings)
        
        -- Close settings when clicking outside frame
        SettingsOverlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local pos = input.Position
                local framePos = SettingsFrame.AbsolutePosition
                local frameSize = SettingsFrame.AbsoluteSize
                if pos.X < framePos.X or pos.X > framePos.X + frameSize.X or pos.Y < framePos.Y or pos.Y > framePos.Y + frameSize.Y then
                    ToggleSettings()
                end
            end
        end)

        local dragging, dragStart, startPos
        TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
                local connection
                connection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        connection:Disconnect()
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        CloseButton.MouseEnter:Connect(function() TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}):Play() end)
        CloseButton.MouseLeave:Connect(function() TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}):Play() end)
        
        local toggleConnection

        CloseButton.MouseButton1Click:Connect(function()
            if FPSCleanup then FPSCleanup() end
            for _, conn in ipairs(window.connections) do
                conn:Disconnect()
            end
            for _, func in ipairs(window.cleanupFunctions) do
                pcall(func)
            end
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
            task.wait(0.3)
            ScreenGui:Destroy()
        end)
        MinimizeButton.MouseEnter:Connect(function() TweenService:Create(MinimizeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 220, 100)}):Play() end)
        MinimizeButton.MouseLeave:Connect(function() TweenService:Create(MinimizeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 200, 80)}):Play() end)
        
        local function MinimizeUI()
            Minimized = not Minimized
            TabContainer.Visible = not Minimized
            ContentFrame.Visible = not Minimized
            if Minimized then
                TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 600, 0, 40)}):Play()
            else
                TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 600, 0, 450)}):Play()
            end
        end
        MinimizeButton.MouseButton1Click:Connect(MinimizeUI)

        local UIVisible = true
        local function ToggleUI()
            UIVisible = not UIVisible
            if UIVisible then
                MainFrame.Visible = true
                TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 600, 0, 450)}):Play()
            else
                TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
                task.delay(0.3, function()
                    if not UIVisible then MainFrame.Visible = false end
                end)
            end
        end

        local collapseKey = Enum.KeyCode.Insert
        local waitingForCollapseKey = false

        CollapseKeybindButton.MouseButton1Click:Connect(function()
            if waitingForCollapseKey then return end
            waitingForCollapseKey = true
            CollapseKeybindButton.Text = "..."
            local connection
            connection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    collapseKey = input.KeyCode
                    local keyName = input.KeyCode.Name
                    if #keyName > 5 then keyName = keyName:sub(1, 4) end
                    CollapseKeybindButton.Text = keyName
                    waitingForCollapseKey = false
                    connection:Disconnect()
                end
            end)
        end)

        toggleConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == collapseKey then
                ToggleUI()
            end
        end)
        table.insert(window.connections, toggleConnection)

        function window:SwitchToTab(tabToSelect)
            for _, tab in pairs(tabs) do
                tab.Page.Visible = false
                TweenService:Create(tab.Button, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                    TextColor3 = Color3.fromRGB(150, 150, 150)
                }):Play()
            end
            tabToSelect.Page.Visible = true
            TweenService:Create(tabToSelect.Button, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(220, 40, 40),
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        end
        function window:CreateTab(name)
            local tab = {}
            local tabButton = CreateElement("TextButton", {
                Name = name .. "Tab",
                Parent = TabHolder,
                BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -20, 0, 35),
                Font = Enum.Font.GothamBold,
                Text = name,
                TextColor3 = Color3.fromRGB(150, 150, 150),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = tabButton})
            CreateElement("UIPadding", {Parent = tabButton, PaddingLeft = UDim.new(0, 10)})
            
            local page = CreateElement("ScrollingFrame", {
                Name = name .. "Page",
                Parent = ContentFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60),
                Visible = false
            })
            CreateElement("UIListLayout", {Parent = page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
            CreateElement("UIPadding", {Parent = page, PaddingRight = UDim.new(0, 10), PaddingLeft = UDim.new(0, 5), PaddingTop = UDim.new(0, 5)})
            
            tab.Button = tabButton
            tab.Page = page
            table.insert(tabs, tab)
            tabButton.MouseEnter:Connect(function()
                if not page.Visible then TweenService:Create(tabButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play() end
            end)
            tabButton.MouseLeave:Connect(function()
                if not page.Visible then TweenService:Create(tabButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play() end
            end)
            tabButton.MouseButton1Click:Connect(function() window:SwitchToTab(tab) end)
            if #tabs == 1 then window:SwitchToTab(tab) end
            function tab:CreateButton(text, callback)
                local button = CreateElement("TextButton", {
                    Parent = page,
                    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 35),
                    Font = Enum.Font.GothamBold,
                    Text = text,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 14,
                    LayoutOrder = #page:GetChildren()
                })
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = button})
                local buttonStroke = CreateElement("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1, Transparency = 0, Parent = button})
                
                button.MouseEnter:Connect(function()
                    TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
                    TweenService:Create(buttonStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(220, 40, 40)}):Play()
                end)
                button.MouseLeave:Connect(function()
                    TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 25)}):Play()
                    TweenService:Create(buttonStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(50, 50, 50)}):Play()
                end)
                button.MouseButton1Click:Connect(function()
                    pcall(callback)
                    TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(1, -4, 0, 31)}):Play()
                    task.wait(0.1)
                    TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 35)}):Play()
                end)
                return button
            end
            function tab:CreateToggle(text, callback)
                local toggleFrame = CreateElement("Frame", {
                    Parent = page,
                    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 35),
                    LayoutOrder = #page:GetChildren()
                })
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = toggleFrame})
                CreateElement("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1, Transparency = 0, Parent = toggleFrame})
                
                CreateElement("TextLabel", {
                    Parent = toggleFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.7, 0, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = text,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local toggleButton = CreateElement("TextButton", {
                    Parent = toggleFrame,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.new(0, 40, 0, 20),
                    Text = ""
                })
                CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleButton}) -- Pill shape
                local toggleIndicator = CreateElement("Frame", {
                    Parent = toggleButton,
                    BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 2, 0.5, 0),
                    Size = UDim2.new(0, 16, 0, 16)
                })
                CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleIndicator})
                local toggled = false
                toggleButton.MouseButton1Click:Connect(function()
                    toggled = not toggled
                    if toggled then
                        TweenService:Create(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 40, 40)}):Play()
                        TweenService:Create(toggleIndicator, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                    else
                        TweenService:Create(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                        TweenService:Create(toggleIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}):Play()
                    end
                    pcall(callback, toggled)
                end)
                return toggleFrame
            end
            function tab:CreateKeybind(text, callback)
                local keybindFrame = CreateElement("Frame", {
                    Parent = page,
                    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 35),
                    LayoutOrder = #page:GetChildren()
                })
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = keybindFrame})
                CreateElement("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1, Transparency = 0, Parent = keybindFrame})
                
                CreateElement("TextLabel", {
                    Parent = keybindFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = text,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local keybindButton = CreateElement("TextButton", {
                    Parent = keybindFrame,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.new(0, 80, 0, 22),
                    Font = Enum.Font.GothamBold,
                    Text = "None",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 12
                })
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = keybindButton})
                local keybindStroke = CreateElement("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1, Transparency = 0, Parent = keybindButton})
                
                local currentKey = nil
                local waiting = false
                keybindButton.MouseButton1Click:Connect(function()
                    if waiting then return end
                    waiting = true
                    keybindButton.Text = "..."
                    TweenService:Create(keybindStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(220, 40, 40)}):Play()
                    local connection
                    connection = UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            currentKey = input.KeyCode
                            keybindButton.Text = currentKey.Name
                            task.delay(0.2, function() waiting = false end)
                            TweenService:Create(keybindStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(60, 60, 60)}):Play()
                            connection:Disconnect()
                        end
                    end)
                end)
                local lastInput = 0
                local keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if not gameProcessed and currentKey and not waiting and input.KeyCode == currentKey then
                        if os.clock() - lastInput < 0.3 then return end
                        lastInput = os.clock()
                        pcall(callback, currentKey)
                    end
                end)
                table.insert(window.connections, keybindConnection)
                return keybindFrame
            end
            function tab:CreateSlider(text, min, max, default, callback)
                local sliderFrame = CreateElement("Frame", {
                    Parent = page,
                    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 50),
                    LayoutOrder = #page:GetChildren()
                })
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = sliderFrame})
                CreateElement("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1, Transparency = 0, Parent = sliderFrame})
                
                CreateElement("TextLabel", {
                    Parent = sliderFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 5),
                    Size = UDim2.new(0.5, 0, 0.4, 0),
                    Font = Enum.Font.GothamBold,
                    Text = text,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local valueLabel = CreateElement("TextLabel", {
                    Parent = sliderFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, 0, 0, 5),
                    Size = UDim2.new(0.5, -10, 0.4, 0),
                    Font = Enum.Font.Gotham,
                    Text = tostring(default),
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right
                })
                local sliderBar = CreateElement("TextButton", {
                    Parent = sliderFrame,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0.025, 0, 0.65, 0),
                    Size = UDim2.new(0.95, 0, 0.15, 0),
                    Text = ""
                })
                CreateElement("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderBar})
                
                local fill = CreateElement("Frame", {
                    Parent = sliderBar,
                    BackgroundColor3 = Color3.fromRGB(220, 40, 40),
                    BorderSizePixel = 0,
                    Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                })
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
                        isDragging = true
                        updateSlider(input.Position)
                        local conn
                        conn = input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                isDragging = false
                                conn:Disconnect()
                            end
                        end)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSlider(input.Position)
                    end
                end)
                return sliderFrame
            end
            function tab:CreateCycleButton(text, values, default, callback)
                local cycleFrame = CreateElement("Frame", {
                    Parent = page,
                    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 35),
                    LayoutOrder = #page:GetChildren()
                })
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = cycleFrame})
                CreateElement("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1, Transparency = 0, Parent = cycleFrame})
                
                CreateElement("TextLabel", {
                    Parent = cycleFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = text,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local cycleButton = CreateElement("TextButton", {
                    Parent = cycleFrame,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.new(0, 100, 0, 22),
                    Font = Enum.Font.GothamBold,
                    Text = tostring(default or values[1] or "None"),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 12
                })
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 4), Parent = cycleButton})
                CreateElement("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1, Transparency = 0, Parent = cycleButton})
                local idx = 1
                for i, v in ipairs(values) do
                    if v == default then idx = i break end
                end
                local function update()
                    local val = values[idx]
                    cycleButton.Text = tostring(val)
                    pcall(callback, val)
                end
                cycleButton.MouseButton1Click:Connect(function()
                    if #values == 0 then return end
                    idx = idx + 1
                    if idx > #values then idx = 1 end
                    update()
                    TweenService:Create(cycleButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 90, 0, 18)}):Play()
                    task.wait(0.1)
                    TweenService:Create(cycleButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 100, 0, 22)}):Play()
                end)
                return {
                    Frame = cycleFrame,
                    SetValues = function(self, newValues)
                        values = newValues
                        idx = 1
                        if #values > 0 then
                            cycleButton.Text = tostring(values[1])
                        else
                            cycleButton.Text = "None"
                        end
                    end,
                    SetValue = function(self, val)
                        for i, v in ipairs(values) do
                            if v == val then
                                idx = i
                                cycleButton.Text = tostring(val)
                                break
                            end
                        end
                    end
                }
            end
            function tab:CreateDropdown(text, options, default, callback)
                local dropdownFrame = CreateElement("Frame", {
                    Parent = page,
                    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 45),
                    ClipsDescendants = true,
                    LayoutOrder = #page:GetChildren()
                })
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = dropdownFrame})
                CreateElement("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1, Transparency = 0, Parent = dropdownFrame})
                
                CreateElement("TextLabel", {
                    Parent = dropdownFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.5, 0, 0, 45),
                    Font = Enum.Font.GothamBold,
                    Text = text,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local dropdownButton = CreateElement("TextButton", {
                    Parent = dropdownFrame,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 120, 0, 30),
                    Font = Enum.Font.GothamBold,
                    Text = default or options[1] or "None",
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextSize = 12,
                    AutoButtonColor = false
                })
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = dropdownButton})
                CreateElement("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1, Transparency = 0, Parent = dropdownButton})
                
                local isOpen = false
                local optionContainer
                
                dropdownButton.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        if optionContainer then optionContainer:Destroy() end
                        
                        optionContainer = CreateElement("Frame", {
                            Parent = dropdownFrame,
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 0, 0, 45),
                            Size = UDim2.new(1, 0, 0, #options * 30)
                        })
                        
                        for i, opt in ipairs(options) do
                            local optBtn = CreateElement("TextButton", {
                                Parent = optionContainer,
                                BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                                BorderSizePixel = 0,
                                Position = UDim2.new(0, 10, 0, (i-1)*30),
                                Size = UDim2.new(1, -20, 0, 28),
                                Font = Enum.Font.Gotham,
                                Text = opt,
                                TextColor3 = Color3.fromRGB(200, 200, 200),
                                TextSize = 12,
                                AutoButtonColor = false
                            })
                            CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = optBtn})
                            
                            optBtn.MouseEnter:Connect(function()
                                TweenService:Create(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
                            end)
                            optBtn.MouseLeave:Connect(function()
                                TweenService:Create(optBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
                            end)
                            
                            optBtn.MouseButton1Click:Connect(function()
                                dropdownButton.Text = opt
                                isOpen = false
                                TweenService:Create(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45)}):Play()
                                task.delay(0.2, function() if optionContainer then optionContainer:Destroy() end end)
                                pcall(callback, opt)
                            end)
                        end
                        
                        TweenService:Create(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45 + (#options * 30) + 10)}):Play()
                    else
                        TweenService:Create(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45)}):Play()
                        task.delay(0.2, function() if optionContainer then optionContainer:Destroy() end end)
                    end
                end)
                return dropdownFrame
            end
            function tab:CreateParagraph(title, content)
                local paragraphFrame = CreateElement("Frame", {
                    Parent = page,
                    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = #page:GetChildren()
                })
                CreateElement("UICorner", {CornerRadius = UDim.new(0, 6), Parent = paragraphFrame})
                CreateElement("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1, Transparency = 0, Parent = paragraphFrame})
                
                CreateElement("TextLabel", {
                    Parent = paragraphFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 10),
                    Size = UDim2.new(1, -20, 0, 15),
                    Font = Enum.Font.GothamBold,
                    Text = title,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                CreateElement("TextLabel", {
                    Parent = paragraphFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 30),
                    Size = UDim2.new(1, -20, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Font = Enum.Font.Gotham,
                    Text = content,
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true
                })
                
                CreateElement("UIPadding", {Parent = paragraphFrame, PaddingBottom = UDim.new(0, 10)})
                
                return paragraphFrame
            end
            return tab
        end

        function window:OnClose(callback)
            table.insert(window.cleanupFunctions, callback)
        end
        
        function UILibrary:Notify(args)
            local notificationGui = game:GetService("CoreGui"):FindFirstChild("CustomNotificationGui")
            if not notificationGui then
                notificationGui = Instance.new("ScreenGui")
                notificationGui.Name = "CustomNotificationGui"
                notificationGui.Parent = game:GetService("CoreGui")
                notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                notificationGui.ResetOnSpawn = false
                
                local container = Instance.new("Frame")
                container.Name = "Container"
                container.Parent = notificationGui
                container.BackgroundTransparency = 1
                container.AnchorPoint = Vector2.new(1, 0)
                container.Position = UDim2.new(1, -20, 0, 80)
                container.Size = UDim2.new(0, 280, 0.5, 0)
                
                local layout = Instance.new("UIListLayout")
                layout.Parent = container
                layout.SortOrder = Enum.SortOrder.LayoutOrder
                layout.Padding = UDim.new(0, 10)
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            end
            
            local container = notificationGui:FindFirstChild("Container")
            local title = args.Title or "Notification"
            local content = args.Content or ""
            local duration = args.Duration or 5
            
            local frame = Instance.new("TextButton")
            frame.Name = "Notification"
            frame.Parent = container
            frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            frame.BorderSizePixel = 0
            frame.Size = UDim2.new(1, 0, 0, 60)
            frame.AutoButtonColor = false
            frame.Text = ""
            
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
            local stroke = Instance.new("UIStroke", frame)
            stroke.Color = Color3.fromRGB(220, 40, 40)
            stroke.Thickness = 1.5
            stroke.Transparency = 0.2
            
            local titleLabel = Instance.new("TextLabel", frame)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Position = UDim2.new(0, 10, 0, 5)
            titleLabel.Size = UDim2.new(1, -20, 0, 20)
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.Text = title
            titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            titleLabel.TextSize = 16
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local contentLabel = Instance.new("TextLabel", frame)
            contentLabel.BackgroundTransparency = 1
            contentLabel.Position = UDim2.new(0, 10, 0, 25)
            contentLabel.Size = UDim2.new(1, -20, 1, -30)
            contentLabel.Font = Enum.Font.Gotham
            contentLabel.Text = content
            contentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            contentLabel.TextSize = 14
            contentLabel.TextXAlignment = Enum.TextXAlignment.Left
            contentLabel.TextWrapped = true
            
            TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
            
            local function close()
                if not frame.Parent then return end
                local tween = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1.2, 0, 0, 0)})
                tween.Completed:Connect(function() frame:Destroy() end)
                tween:Play()
            end
            
            frame.MouseButton1Click:Connect(close)
            task.delay(duration, close)
        end
        
        return window
    end
    return UILibrary
end)()

return UILibrary
