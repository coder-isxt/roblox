-- // IMPORTS // --
local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/coder-isxt/roblox/refs/heads/main/library_v2.lua"))()

-- // SERVICES // --
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- // GLOBAL VARIABLES // --
local Window
local Tabs

-- // UI CREATION // --
Window = UILibrary:CreateWindow({
    Title = "Example v2",
    Subtitle = "library_v2",
})

Tabs = {
    Main = Window:CreateTab("Main"),
    Settings = Window:CreateTab("Settings"),
}

-- // NOTIFICATIONS // --
UILibrary:Notify({
    Title = "Welcome " .. (Player and Player.DisplayName or "Player"),
    Content = "Script Loaded!",
    Duration = 5,
})

-- // BUTTONS // --
Tabs.Main:CreateButton("Example Button", function()
    UILibrary:Notify({
        Title = "Action",
        Content = "Button Pressed",
        Duration = 2,
    })
end)

