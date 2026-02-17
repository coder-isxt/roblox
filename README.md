# UILibrary API Documentation

This documentation is generated from `copy/library.lua` and covers every user-facing function currently exposed.

## Load the library
```lua
local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/coder-isxt/roblox/refs/heads/main/library.lua"))()
```

## Top-Level API

### `UILibrary:SetConfigStorage(folderName, fileName)`
Sets the persistence folder/file used by library settings and registered values.

Parameters:
- `folderName` (`string`): Folder name.
- `fileName` (`string`): JSON file name.

Returns:
- `UILibrary` (self)

Example:
```lua
UILibrary:SetConfigStorage("FabledLegacyFarm", "settings.json")
```

### `UILibrary:RegisterValue(key, defaultValue, onLoad)`
Registers a persistent value.

Parameters:
- `key` (`string`): Unique save key.
- `defaultValue` (`any`): Value used when no save exists.
- `onLoad` (`function(value, hadSaved)` | optional): Called after load.

Returns:
- `handle` table with:
  - `handle:Get()`
  - `handle:Set(newValue)`
  - `handle:Reset()`
  - `handle:Save()`

Example:
```lua
local AutoFarm = UILibrary:RegisterValue("AutoFarm", false)
print(AutoFarm:Get())
AutoFarm:Set(true)
```

### `UILibrary:GetValue(key, fallback)`
Reads current runtime value for a registered key.

Parameters:
- `key` (`string`)
- `fallback` (`any`)

Returns:
- Current value or `fallback`.

### `UILibrary:AddTooltip(instance, text)`
Adds a hover tooltip to a UI instance.

Parameters:
- `instance` (`Instance`)
- `text` (`string`)

### `UILibrary:CreateWindow(title)`
Creates the main UI window.

Parameters:
- `title` (`string` | optional)

Returns:
- `window` object

### `UILibrary:Notify(args)`
Shows a toast/notification.

Parameters:
- `args.Title` (`string` | optional)
- `args.Content` (`string` | optional)
- `args.Duration` (`number` | optional, seconds)

Example:
```lua
UILibrary:Notify({
  Title = "Loaded",
  Content = "Script ready",
  Duration = 3
})
```

---

## Window API

### `window:CreateTab(name)`
Creates a tab in the window.

Parameters:
- `name` (`string`)

Returns:
- `tab` object

### `window:SwitchToTab(tabToSelect)`
Switches active tab.

Parameters:
- `tabToSelect` (tab object returned by `CreateTab`)

### `window:OnClose(callback)`
Registers cleanup callback called when window closes.

Parameters:
- `callback` (`function`)

---

## Tab API

### `tab:CreateButton(text, callback)`
Creates a button.

Parameters:
- `text` (`string`)
- `callback` (`function`)

Returns:
- `TextButton` frame

### `tab:CreateToggle(text, callback, defaultState, saveKey)`
Creates a toggle.

Parameters:
- `text` (`string`)
- `callback` (`function(state: boolean)`)
- `defaultState` (`boolean` | optional)
- `saveKey` (`string` | optional)

Returns:
- `Frame`

### `tab:CreateKeybind(text, callback, defaultKey, saveKey)`
Creates a keybind picker and listener.

Parameters:
- `text` (`string`)
- `callback` (`function(keyCode: Enum.KeyCode)`)
- `defaultKey` (`Enum.KeyCode` | optional)
- `saveKey` (`string` | optional)

Returns:
- `Frame`

### `tab:CreateSlider(text, min, max, default, callback, saveKey)`
Creates a number slider.

Parameters:
- `text` (`string`)
- `min` (`number`)
- `max` (`number`)
- `default` (`number`)
- `callback` (`function(value: number)`)
- `saveKey` (`string` | optional)

Returns:
- `Frame`

### `tab:CreateCycleButton(text, values, default, callback, saveKey)`
Creates a cycle button (next value on click).

Parameters:
- `text` (`string`)
- `values` (`table`)
- `default` (`any`)
- `callback` (`function(value)`)
- `saveKey` (`string` | optional)

Returns:
- controller table:
  - `controller.Frame`
  - `controller:SetValues(newValues)`
  - `controller:SetValue(value)`

### `tab:CreateDropdown(text, options, default, callback, saveKey)`
Creates a dropdown selector.

Parameters:
- `text` (`string`)
- `options` (`table<string>`)
- `default` (`string` | optional)
- `callback` (`function(value: string)`)
- `saveKey` (`string` | optional)

Returns:
- `Frame`

### `tab:CreateParagraph(title, content)`
Creates static paragraph/information block.

Parameters:
- `title` (`string`)
- `content` (`string`)

Returns:
- `Frame`

---

## Persistence Notes

- Library automatically saves/loads these global options:
  - `Theme`, `ToggleStyle`, `CornerStyle`, `Font`, `MenuStyle`
- Config schema supports migration (`SchemaVersion = 2`).
- `RegisterValue` supports primitive values, tables, `Color3`, and `EnumItem` serialization.
- If executor file APIs are unavailable (`writefile/readfile/isfile/makefolder`), library runs without persistence.

---

## Practical Example

```lua
local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/coder-isxt/roblox/refs/heads/main/library.lua"))()
UILibrary:SetConfigStorage("MyScript", "config.json")

local Window = UILibrary:CreateWindow("My UI")
local Main = Window:CreateTab("Main")

local AutoFarm = UILibrary:RegisterValue("auto_farm", false)

Main:CreateToggle("Auto Farm", function(v)
  AutoFarm:Set(v)
end, AutoFarm:Get(), "main.auto_farm")

Main:CreateSlider("Range", 1, 100, 20, function(v)
  print("Range:", v)
end, "main.range")

Main:CreateKeybind("Toggle UI", function(key)
  print("Pressed:", key)
end, Enum.KeyCode.Insert, "main.toggle_ui_key")

Window:OnClose(function()
  print("Closed")
end)
```
