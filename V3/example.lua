local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/skatox/Zyntra/main/V3/library.lua"))() or require(script.Parent.library)

local Window = UILibrary:CreateWindow({
    Title = "Zyntra V3",
    Subtitle = "Premium Interface"
})

local MainTab = Window:AddTab("Home", "rbxassetid://6034509993")
local SettingsTab = Window:AddTab("Settings", "rbxassetid://6031289132")

-- Main Section
local MainSection = MainTab:AddSection("Overview")

MainSection:AddButton({
    Title = "Click Me",
    Callback = function()
        UILibrary:Notify({
            Title = "Button Clicked",
            Content = "You clicked the demo button!",
            Duration = 2
        })
    end
})

MainSection:AddToggle({
    Title = "Auto Farm",
    Default = false,
    Callback = function(v)
        print("Auto Farm:", v)
    end
})

MainSection:AddSlider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 100,
    Default = 16,
    Callback = function(v)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
})

MainSection:AddDropdown({
    Title = "Teleport",
    Options = {"Spawn", "Shop", "Safezone", "Arena"},
    Callback = function(v)
        print("Teleporting to:", v)
    end
})

-- Settings Section
local SettingsSection = SettingsTab:AddSection("Configurations")

SettingsSection:AddTextbox({
    Title = "Custom Speed",
    Placeholder = "Enter value...",
    Callback = function(v)
        print("Custom Speed set to:", v)
    end
})

SettingsSection:AddKeybind({
    Title = "Toggle UI",
    Default = Enum.KeyCode.RightControl,
    Callback = function()
        Window:Toggle()
    end
})

SettingsSection:AddLabel("This is a simple label.")

SettingsSection:AddParagraph({
    Title = "Disclaimer",
    Content = "This UI library is designed for premium user experiences. Please use responsibly."
})

SettingsSection:AddDivider()

SettingsSection:AddButton({
    Title = "Destroy UI",
    Callback = function()
        Window:Destroy()
    end
})

UILibrary:Notify({
    Title = "Loaded",
    Content = "Zyntra V3 has been successfully initialized.",
    Duration = 5
})
