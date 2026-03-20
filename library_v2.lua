
local UILibrary = {}

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local FONT = Enum.Font.Gotham
local GUI_NAME = "XenoUILibraryV2"
local OPEN_DROPDOWNS = {}

local C = {
    Main = Color3.fromRGB(9, 13, 20),
    Top = Color3.fromRGB(12, 17, 27),
    Sidebar = Color3.fromRGB(10, 14, 22),
    SidebarActive = Color3.fromRGB(18, 27, 41),
    Panel = Color3.fromRGB(13, 19, 29),
    PanelInset = Color3.fromRGB(16, 24, 37),
    Control = Color3.fromRGB(20, 31, 48),
    ControlHover = Color3.fromRGB(28, 42, 64),
    ControlPress = Color3.fromRGB(35, 53, 78),
    Stroke = Color3.fromRGB(37, 52, 76),
    Accent = Color3.fromRGB(91, 180, 255),
    Text = Color3.fromRGB(224, 233, 248),
    SubText = Color3.fromRGB(145, 163, 192),
}

local function mk(className, props)
    local x = Instance.new(className)
    for k, v in pairs(props or {}) do
        x[k] = v
    end
    return x
end

local function corner(x, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = x
    return c
end

local function stroke(x, color, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or C.Stroke
    s.Thickness = 1
    s.Transparency = trans or 0.35
    s.Parent = x
    return s
end

local function tw(x, t, p)
    return TweenService:Create(x, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p)
end

local function safe(cb, ...)
    if typeof(cb) ~= "function" then
        return
    end
    local ok, err = pcall(cb, ...)
    if not ok then
        warn("[library_v2] callback error:", err)
    end
end

local function clamp(v, a, b)
    return math.max(a, math.min(b, v))
end

local function roundStep(v, s)
    if s <= 0 then
        return v
    end
    return math.floor((v / s) + 0.5) * s
end

local function closeDropdowns(except)
    for d in pairs(OPEN_DROPDOWNS) do
        if d ~= except and d.SetOpen then
            d:SetOpen(false)
        end
    end
end

local function keycode(v)
    if typeof(v) == "EnumItem" and v.EnumType == Enum.KeyCode then
        return v
    end
    return nil
end

local function guiParent()
    if typeof(gethui) == "function" then
        local ok, v = pcall(gethui)
        if ok and typeof(v) == "Instance" then
            return v
        end
    end
    local ok, cg = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and cg then
        return cg
    end
    local lp = Players.LocalPlayer
    if lp then
        return lp:FindFirstChildOfClass("PlayerGui")
    end
    return nil
end

local function protect(sg)
    if syn and typeof(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, sg)
    elseif typeof(protectgui) == "function" then
        pcall(protectgui, sg)
    end
end

local function track(conns, c)
    table.insert(conns, c)
    return c
end

local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

function Window:IsVisible()
    return self.Main.Visible
end

function Window:SetVisible(v)
    self.Main.Visible = v == true
end

function Window:Toggle()
    self:SetVisible(not self:IsVisible())
end

function Window:SetTitle(s)
    self.TitleLabel.Text = tostring(s or "")
end

function Window:OnClose(cb)
    if typeof(cb) == "function" then
        table.insert(self.CloseCallbacks, cb)
    end
    return self
end

function Window:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    closeDropdowns(nil)
    for _, c in ipairs(self.Connections) do
        if c and c.Disconnect then
            pcall(function()
                c:Disconnect()
            end)
        end
    end
    table.clear(self.Connections)
    for _, cb in ipairs(self.CloseCallbacks) do
        safe(cb)
    end
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    if UILibrary._window == self then
        UILibrary._window = nil
        UILibrary._toastHost = nil
    end
end

function Window:SelectTab(tabOrName)
    local picked = nil
    if typeof(tabOrName) == "table" then
        picked = tabOrName
    else
        for _, t in ipairs(self.Tabs) do
            if t.Name == tostring(tabOrName) then
                picked = t
                break
            end
        end
    end
    if not picked then
        return nil
    end
    closeDropdowns(nil)
    self.ActiveTab = picked
    for _, t in ipairs(self.Tabs) do
        local active = t == picked
        t.Page.Visible = active
        t.Indicator.BackgroundTransparency = active and 0 or 1
        t.ButtonBack.BackgroundTransparency = active and 0 or 1
        t.Label.TextColor3 = active and C.Text or C.SubText
    end
    return picked
end

function Window:SwitchToTab(t)
    return self:SelectTab(t)
end

function Window:GetTabs()
    return self.Tabs
end

local function controlShell(section, h)
    return mk("Frame", {
        Parent = section.Content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, h),
    })
end

local function controlBack(parent, h)
    local b = mk("Frame", {
        Parent = parent,
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, h),
    })
    corner(b, 6)
    stroke(b, C.Stroke, 0.35)
    return b
end

local function asOptions(list)
    local out = {}
    for _, v in ipairs(list or {}) do
        table.insert(out, tostring(v))
    end
    return out
end

function Section:CreateButton(a, b)
    local text, cb
    if typeof(a) == "table" then
        text = tostring(a.Name or a.Text or "Button")
        cb = a.Callback or b
    else
        text = tostring(a or "Button")
        cb = b
    end

    local shell = controlShell(self, 34)
    local btn = mk("TextButton", {
        Parent = shell,
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        AutoButtonColor = false,
        Font = FONT,
        TextSize = 13,
        TextColor3 = C.Text,
        Text = text,
    })
    corner(btn, 6)
    stroke(btn, C.Stroke, 0.35)

    track(self.Window.Connections, btn.MouseEnter:Connect(function()
        tw(btn, 0.1, { BackgroundColor3 = C.ControlHover }):Play()
    end))
    track(self.Window.Connections, btn.MouseLeave:Connect(function()
        tw(btn, 0.1, { BackgroundColor3 = C.Control }):Play()
    end))
    track(self.Window.Connections, btn.MouseButton1Down:Connect(function()
        tw(btn, 0.05, { BackgroundColor3 = C.ControlPress }):Play()
    end))
    track(self.Window.Connections, btn.MouseButton1Click:Connect(function()
        safe(cb)
    end))

    return {
        Frame = shell,
        Button = btn,
        SetText = function(_, t)
            btn.Text = tostring(t or "")
        end,
        Fire = function()
            safe(cb)
        end,
    }
end

function Section:CreateToggle(a, b, c)
    local text, default, cb
    if typeof(a) == "table" then
        text = tostring(a.Name or a.Text or "Toggle")
        default = a.CurrentValue == true or a.Default == true
        cb = a.Callback or b
    else
        text = tostring(a or "Toggle")
        default = c == true
        cb = b
    end

    local value = default
    local shell = controlShell(self, 34)
    local back = controlBack(shell, 34)

    local box = mk("Frame", {
        Parent = back,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 9, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(9, 14, 22),
        BorderSizePixel = 0,
    })
    corner(box, 4)
    stroke(box, C.Stroke, 0.2)

    mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -38, 1, 0),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = text,
    })

    local hit = mk("TextButton", {
        Parent = back,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
    })

    local controller = { Frame = shell }
    function controller:Set(v, skip)
        value = v == true
        tw(box, 0.1, { BackgroundColor3 = value and C.Accent or Color3.fromRGB(9, 14, 22) }):Play()
        if not skip then
            safe(cb, value)
        end
    end
    function controller:Get()
        return value
    end

    track(self.Window.Connections, hit.MouseButton1Click:Connect(function()
        controller:Set(not value)
    end))
    track(self.Window.Connections, back.MouseEnter:Connect(function()
        tw(back, 0.1, { BackgroundColor3 = C.ControlHover }):Play()
    end))
    track(self.Window.Connections, back.MouseLeave:Connect(function()
        tw(back, 0.1, { BackgroundColor3 = C.Control }):Play()
    end))

    controller:Set(value, true)
    return controller
end
function Section:CreateSlider(a, b, c, d, e)
    local name, minV, maxV, defV, step, suf, cb
    if typeof(a) == "table" then
        name = tostring(a.Name or a.Text or "Slider")
        if typeof(a.Range) == "table" then
            minV = tonumber(a.Range[1]) or 0
            maxV = tonumber(a.Range[2]) or 100
        else
            minV = tonumber(a.Min) or 0
            maxV = tonumber(a.Max) or 100
        end
        defV = tonumber(a.CurrentValue) or tonumber(a.Default) or minV
        step = tonumber(a.Increment) or 1
        suf = tostring(a.Suffix or "")
        cb = a.Callback or e
    else
        name = tostring(a or "Slider")
        minV = tonumber(b) or 0
        maxV = tonumber(c) or 100
        defV = tonumber(d) or minV
        step = 1
        suf = ""
        cb = e
    end
    if minV > maxV then
        minV, maxV = maxV, minV
    end
    local value = roundStep(clamp(defV, minV, maxV), step)

    local shell = controlShell(self, 52)
    local back = controlBack(shell, 52)
    mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 4),
        Size = UDim2.new(1, -70, 0, 16),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = name,
    })
    local val = mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -64, 0, 4),
        Size = UDim2.new(0, 58, 0, 16),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = C.SubText,
        Text = "",
    })
    local bar = mk("Frame", {
        Parent = back,
        BackgroundColor3 = Color3.fromRGB(8, 12, 20),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 1, -14),
        Size = UDim2.new(1, -20, 0, 6),
    })
    corner(bar, 99)
    local fill = mk("Frame", {
        Parent = bar,
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
    })
    corner(fill, 99)
    local knob = mk("Frame", {
        Parent = bar,
        BackgroundColor3 = Color3.fromRGB(235, 243, 255),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 10, 0, 10),
    })
    corner(knob, 99)

    local drag = false
    local controller = { Frame = shell }
    local function draw()
        local alpha = (maxV == minV) and 0 or ((value - minV) / (maxV - minV))
        alpha = clamp(alpha, 0, 1)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        val.Text = tostring(value) .. suf
    end
    function controller:Set(v, skip)
        value = roundStep(clamp(tonumber(v) or minV, minV, maxV), step)
        draw()
        if not skip then
            safe(cb, value)
        end
    end
    function controller:Get()
        return value
    end
    local function at(x)
        local a = clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        controller:Set(minV + ((maxV - minV) * a))
    end
    track(self.Window.Connections, bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            at(i.Position.X)
        end
    end))
    track(self.Window.Connections, UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            at(i.Position.X)
        end
    end))
    track(self.Window.Connections, UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = false
        end
    end))
    draw()
    return controller
end

function Section:CreateDropdown(a, b, c, d)
    local name, opts, cur, multi, cb
    if typeof(a) == "table" then
        name = tostring(a.Name or a.Text or "Dropdown")
        opts = asOptions(a.Options or a.Values or {})
        cur = a.CurrentOption
        multi = a.MultipleOptions == true
        cb = a.Callback or d
    else
        name = tostring(a or "Dropdown")
        opts = asOptions(b or {})
        cur = c
        multi = false
        cb = d
    end

    local chosen = nil
    local map = {}
    local shell = controlShell(self, 34)
    shell.ClipsDescendants = true
    local back = controlBack(shell, 34)

    mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -36, 1, 0),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = name,
    })
    local valueLbl = mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -36, 1, 0),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = C.SubText,
        Text = "",
    })
    local arrow = mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -18, 0, 0),
        Size = UDim2.new(0, 12, 1, 0),
        Font = FONT,
        TextSize = 13,
        TextColor3 = C.SubText,
        Text = "v",
    })
    local hit = mk("TextButton", {
        Parent = back,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
    })
    local menu = mk("Frame", {
        Parent = shell,
        BackgroundColor3 = Color3.fromRGB(12, 18, 28),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
    })
    corner(menu, 6)
    stroke(menu, C.Stroke, 0.35)
    mk("UIPadding", {
        Parent = menu,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
    })
    mk("UIListLayout", {
        Parent = menu,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })

    local controller = { Frame = shell, Open = false }
    local function multiList()
        local t = {}
        for _, o in ipairs(opts) do
            if map[o] then
                table.insert(t, o)
            end
        end
        return t
    end
    local function showText()
        if multi then
            local t = multiList()
            if #t == 0 then
                valueLbl.Text = "None"
            elseif #t <= 2 then
                valueLbl.Text = table.concat(t, ", ")
            else
                valueLbl.Text = tostring(#t) .. " selected"
            end
        else
            valueLbl.Text = chosen or "None"
        end
    end
    local function rebuild()
        for _, ch in ipairs(menu:GetChildren()) do
            if ch:IsA("TextButton") then
                ch:Destroy()
            end
        end
        for i, o in ipairs(opts) do
            local btt = mk("TextButton", {
                Parent = menu,
                BackgroundColor3 = C.Control,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 24),
                AutoButtonColor = false,
                Font = FONT,
                TextSize = 12,
                TextColor3 = C.Text,
                Text = o,
                LayoutOrder = i,
            })
            corner(btt, 5)
            stroke(btt, C.Stroke, 0.45)
            local function paint()
                local on = multi and map[o] or (chosen == o)
                btt.BackgroundColor3 = on and C.ControlPress or C.Control
            end
            paint()
            track(self.Window.Connections, btt.MouseButton1Click:Connect(function()
                if multi then
                    map[o] = not map[o]
                    paint()
                    showText()
                    safe(cb, multiList())
                else
                    chosen = o
                    showText()
                    safe(cb, chosen)
                    controller:SetOpen(false)
                    rebuild()
                end
            end))
        end
    end
    function controller:SetOpen(v)
        local open = v == true
        if self.Open == open then
            return
        end
        self.Open = open
        if open then
            closeDropdowns(self)
            OPEN_DROPDOWNS[self] = true
            menu.Visible = true
            arrow.Text = "^"
            local h = (#opts * 28) + 10
            tw(shell, 0.12, { Size = UDim2.new(1, 0, 0, 34 + 6 + h) }):Play()
            tw(menu, 0.12, { Size = UDim2.new(1, 0, 0, h) }):Play()
        else
            OPEN_DROPDOWNS[self] = nil
            arrow.Text = "v"
            tw(shell, 0.12, { Size = UDim2.new(1, 0, 0, 34) }):Play()
            tw(menu, 0.1, { Size = UDim2.new(1, 0, 0, 0) }):Play()
            task.delay(0.1, function()
                if not self.Open and menu.Parent then
                    menu.Visible = false
                end
            end)
        end
    end
    function controller:SetValues(v)
        opts = asOptions(v)
        if not multi then
            local ok = false
            for _, o in ipairs(opts) do
                if o == chosen then
                    ok = true
                    break
                end
            end
            if not ok then
                chosen = opts[1]
            end
        else
            local keep = {}
            for _, o in ipairs(opts) do
                if map[o] then
                    keep[o] = true
                end
            end
            map = keep
        end
        showText()
        rebuild()
    end
    function controller:SetValue(v, skip)
        if multi then
            if typeof(v) == "table" then
                table.clear(map)
                for _, o in ipairs(v) do
                    map[tostring(o)] = true
                end
                showText()
                rebuild()
                if not skip then
                    safe(cb, multiList())
                end
            end
        else
            local target = tostring(v or "")
            local found = false
            for _, o in ipairs(opts) do
                if o == target then
                    found = true
                    break
                end
            end
            chosen = found and target or opts[1]
            showText()
            rebuild()
            if not skip then
                safe(cb, chosen)
            end
        end
    end
    function controller:GetValue()
        return multi and multiList() or chosen
    end
    controller.Set = controller.SetValue
    controller.Refresh = controller.SetValues

    track(self.Window.Connections, hit.MouseButton1Click:Connect(function()
        controller:SetOpen(not controller.Open)
    end))

    rebuild()
    if multi then
        if typeof(cur) == "table" then
            controller:SetValue(cur, true)
        else
            showText()
        end
    else
        if cur ~= nil then
            controller:SetValue(cur, true)
        elseif #opts > 0 then
            controller:SetValue(opts[1], true)
        else
            showText()
        end
    end
    return controller
end
function Section:CreateInput(a, b, c)
    local name, ph, def, cb, clear
    if typeof(a) == "table" then
        name = tostring(a.Name or a.Text or "Input")
        ph = tostring(a.PlaceholderText or "")
        def = tostring(a.CurrentValue or a.Default or "")
        cb = a.Callback or b
        clear = a.RemoveTextAfterFocusLost == true
    else
        name = tostring(a or "Input")
        ph = ""
        def = tostring(c or "")
        cb = b
        clear = false
    end

    local shell = controlShell(self, 34)
    local back = controlBack(shell, 34)
    mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.46, 0, 1, 0),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = name,
    })
    local inBack = mk("Frame", {
        Parent = back,
        BackgroundColor3 = Color3.fromRGB(8, 12, 20),
        BorderSizePixel = 0,
        Position = UDim2.new(0.48, 0, 0.5, -11),
        Size = UDim2.new(0.52, -10, 0, 22),
    })
    corner(inBack, 5)
    stroke(inBack, C.Stroke, 0.45)
    local box = mk("TextBox", {
        Parent = inBack,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        PlaceholderColor3 = C.SubText,
        PlaceholderText = ph,
        Text = def,
        ClearTextOnFocus = false,
    })
    local controller = { Frame = shell }
    function controller:SetValue(v, skip)
        box.Text = tostring(v or "")
        if not skip then
            safe(cb, box.Text)
        end
    end
    function controller:GetValue()
        return box.Text
    end
    controller.Set = controller.SetValue
    controller.Get = controller.GetValue
    track(self.Window.Connections, box.FocusLost:Connect(function(enter)
        safe(cb, box.Text, enter)
        if clear then
            box.Text = ""
        end
    end))
    return controller
end

function Section:CreateTextbox(...)
    return self:CreateInput(...)
end

function Section:CreateKeybind(a, b, c)
    local name, cb, def
    if typeof(a) == "table" then
        name = tostring(a.Name or a.Text or "Keybind")
        cb = a.Callback or b
        def = keycode(a.CurrentKeybind or a.Default or a.Key)
    else
        name = tostring(a or "Keybind")
        cb = b
        def = keycode(c)
    end
    local bound = def or Enum.KeyCode.Unknown
    local listening = false

    local shell = controlShell(self, 34)
    local back = controlBack(shell, 34)
    mk("TextLabel", {
        Parent = back,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.55, 0, 1, 0),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = name,
    })
    local btn = mk("TextButton", {
        Parent = back,
        BackgroundColor3 = Color3.fromRGB(8, 12, 20),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -124, 0.5, -11),
        Size = UDim2.new(0, 114, 0, 22),
        AutoButtonColor = false,
        Font = FONT,
        TextSize = 12,
        TextColor3 = C.SubText,
        Text = "",
    })
    corner(btn, 5)
    stroke(btn, C.Stroke, 0.45)

    local function keyText(k)
        return (k == Enum.KeyCode.Unknown) and "None" or k.Name
    end

    local controller = { Frame = shell }
    function controller:SetValue(v, skip)
        local k = keycode(v)
        if not k then
            return
        end
        bound = k
        btn.Text = keyText(k)
        if not skip then
            safe(cb, bound, true)
        end
    end
    function controller:GetValue()
        return bound
    end
    controller.Set = controller.SetValue
    controller.Get = controller.GetValue
    controller:SetValue(bound, true)

    track(self.Window.Connections, btn.MouseButton1Click:Connect(function()
        listening = true
        btn.Text = "..."
    end))
    track(self.Window.Connections, UIS.InputBegan:Connect(function(i, gpe)
        if gpe or i.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if listening then
            listening = false
            controller:SetValue(i.KeyCode, false)
            return
        end
        if bound ~= Enum.KeyCode.Unknown and i.KeyCode == bound then
            safe(cb, bound, false)
        end
    end))
    return controller
end

function Section:CreateLabel(text)
    local shell = controlShell(self, 24)
    local lbl = mk("TextLabel", {
        Parent = shell,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = FONT,
        TextSize = 13,
        TextColor3 = C.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(text or ""),
    })
    return {
        Frame = shell,
        Label = lbl,
        Set = function(_, v)
            lbl.Text = tostring(v or "")
        end,
    }
end

function Section:CreateParagraph(a, b)
    local title, content
    if typeof(a) == "table" then
        title = tostring(a.Title or "Paragraph")
        content = tostring(a.Content or "")
    else
        title = tostring(a or "Paragraph")
        content = tostring(b or "")
    end

    local shell = mk("Frame", {
        Parent = self.Content,
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    corner(shell, 6)
    stroke(shell, C.Stroke, 0.35)
    mk("UIPadding", {
        Parent = shell,
        PaddingTop = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    })
    local t = mk("TextLabel", {
        Parent = shell,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = title,
    })
    local cLbl = mk("TextLabel", {
        Parent = shell,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = FONT,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = C.SubText,
        Text = content,
    })
    return {
        Frame = shell,
        Set = function(_, nt, nc)
            t.Text = tostring(nt or t.Text)
            cLbl.Text = tostring(nc or cLbl.Text)
        end,
    }
end

function Tab:_column(side)
    local s = string.lower(tostring(side or "left"))
    return (s == "right" or s == "r") and self.Right or self.Left
end

function Tab:CreateSection(a, b)
    local name, side
    if typeof(a) == "table" then
        name = tostring(a.Name or a.Title or "Section")
        side = tostring(a.Side or "Left")
    else
        name = tostring(a or "Section")
        side = tostring(b or "Left")
    end

    local frame = mk("Frame", {
        Name = name .. "_Section",
        Parent = self:_column(side),
        BackgroundColor3 = C.PanelInset,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    corner(frame, 7)
    stroke(frame, C.Stroke, 0.25)
    mk("UIPadding", {
        Parent = frame,
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    })
    mk("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.SubText,
        Text = name,
    })
    local content = mk("Frame", {
        Parent = frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    mk("UIListLayout", {
        Parent = content,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })
    local sec = setmetatable({
        Name = name,
        Window = self.Window,
        Tab = self,
        Frame = frame,
        Content = content,
    }, Section)
    table.insert(self.Sections, sec)
    return sec
end

function Tab:_def()
    if not self.DefaultSection then
        self.DefaultSection = self:CreateSection("General", "Left")
    end
    return self.DefaultSection
end

function Tab:CreateButton(...)
    return self:_def():CreateButton(...)
end
function Tab:CreateToggle(...)
    return self:_def():CreateToggle(...)
end
function Tab:CreateSlider(...)
    return self:_def():CreateSlider(...)
end
function Tab:CreateDropdown(...)
    return self:_def():CreateDropdown(...)
end
function Tab:CreateInput(...)
    return self:_def():CreateInput(...)
end
function Tab:CreateTextbox(...)
    return self:_def():CreateTextbox(...)
end
function Tab:CreateLabel(...)
    return self:_def():CreateLabel(...)
end
function Tab:CreateParagraph(...)
    return self:_def():CreateParagraph(...)
end
function Tab:CreateKeybind(...)
    return self:_def():CreateKeybind(...)
end
function Window:CreateTab(a, iconMaybe)
    local name, icon = "Tab", nil
    if typeof(a) == "table" then
        name = tostring(a.Name or a.Title or "Tab")
        icon = a.Icon
    else
        name = tostring(a or "Tab")
        icon = iconMaybe
    end

    local btn = mk("TextButton", {
        Parent = self.TabList,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 28),
        Text = "",
        AutoButtonColor = false,
    })
    local back = mk("Frame", {
        Parent = btn,
        BackgroundColor3 = C.SidebarActive,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
    })
    corner(back, 5)
    local ind = mk("Frame", {
        Parent = btn,
        BackgroundColor3 = C.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, -6),
        Position = UDim2.new(0, 0, 0, 3),
    })
    corner(ind, 99)

    local iconHolder = mk("Frame", {
        Parent = btn,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 10, 0.5, -7),
    })
    local iconImage
    if typeof(icon) == "number" then
        iconImage = "rbxassetid://" .. tostring(icon)
    elseif typeof(icon) == "string" then
        if string.find(icon, "rbxassetid://", 1, true) then
            iconImage = icon
        elseif tonumber(icon) then
            iconImage = "rbxassetid://" .. tostring(icon)
        end
    end
    if iconImage then
        mk("ImageLabel", {
            Parent = iconHolder,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ImageColor3 = C.SubText,
            Image = iconImage,
        })
    else
        local dot = mk("Frame", {
            Parent = iconHolder,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 6, 0, 6),
            BackgroundColor3 = C.SubText,
            BorderSizePixel = 0,
        })
        corner(dot, 99)
    end

    local lbl = mk("TextLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 28, 0, 0),
        Size = UDim2.new(1, -32, 1, 0),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.SubText,
        Text = name,
    })

    local page = mk("Frame", {
        Parent = self.PageHolder,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    })
    local left = mk("ScrollingFrame", {
        Parent = page,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0.5, -4, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Stroke,
    })
    mk("UIListLayout", {
        Parent = left,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    })
    local right = mk("ScrollingFrame", {
        Parent = page,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 4, 0, 0),
        Size = UDim2.new(0.5, -4, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Stroke,
    })
    mk("UIListLayout", {
        Parent = right,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    })

    local tab = setmetatable({
        Name = name,
        Window = self,
        Button = btn,
        ButtonBack = back,
        Indicator = ind,
        Label = lbl,
        Page = page,
        Left = left,
        Right = right,
        Sections = {},
        DefaultSection = nil,
    }, Tab)

    table.insert(self.Tabs, tab)
    track(self.Connections, btn.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end))
    track(self.Connections, btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tw(back, 0.1, { BackgroundTransparency = 0.62 }):Play()
        end
    end))
    track(self.Connections, btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tw(back, 0.1, { BackgroundTransparency = 1 }):Play()
        end
    end))

    if not self.ActiveTab then
        self:SelectTab(tab)
    end
    return tab
end

function UILibrary:CreateWindow(arg)
    if self._window and self._window.Destroy then
        self._window:Destroy()
    end

    local o = typeof(arg) == "table" and arg or { Title = arg }
    local title = tostring(o.Title or o.Name or "UI Library")
    local subtitle = tostring(o.Subtitle or o.SubTitle or "")
    local size = (typeof(o.Size) == "UDim2") and o.Size or UDim2.fromOffset(780, 440)
    local toggleKey = keycode(o.ToggleKey) or Enum.KeyCode.RightShift
    local parent = (typeof(o.Parent) == "Instance") and o.Parent or guiParent()
    if not parent then
        error("[library_v2] no ScreenGui parent")
    end

    local old = parent:FindFirstChild(GUI_NAME)
    if old then
        old:Destroy()
    end

    local sg = mk("ScreenGui", {
        Name = GUI_NAME,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = nil,
    })
    protect(sg)
    sg.Parent = parent

    local main = mk("Frame", {
        Parent = sg,
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = size,
        BackgroundColor3 = C.Main,
        BorderSizePixel = 0,
        Active = true,
    })
    corner(main, 8)
    stroke(main, C.Stroke, 0.2)
    mk("UISizeConstraint", {
        Parent = main,
        MinSize = Vector2.new(610, 360),
    })

    local top = mk("Frame", {
        Parent = main,
        BackgroundColor3 = C.Top,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
    })
    corner(top, 8)
    mk("Frame", {
        Parent = top,
        BackgroundColor3 = C.Top,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0.5, 0),
    })

    local titleLbl = mk("TextLabel", {
        Parent = top,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -90, 1, 0),
        Font = FONT,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = subtitle ~= "" and (title .. "  |  " .. subtitle) or title,
    })
    local hide = mk("TextButton", {
        Parent = top,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -38, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Font = FONT,
        TextSize = 14,
        TextColor3 = C.SubText,
        Text = "-",
        AutoButtonColor = false,
    })
    corner(hide, 5)
    local close = mk("TextButton", {
        Parent = top,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = C.Control,
        BorderSizePixel = 0,
        Font = FONT,
        TextSize = 14,
        TextColor3 = C.SubText,
        Text = "x",
        AutoButtonColor = false,
    })
    corner(close, 5)

    local body = mk("Frame", {
        Parent = main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 34),
        Size = UDim2.new(1, 0, 1, -34),
    })
    local side = mk("Frame", {
        Parent = body,
        BackgroundColor3 = C.Sidebar,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 150, 1, 0),
    })
    mk("UIPadding", {
        Parent = side,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    })
    local tabList = mk("Frame", {
        Parent = side,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
    })
    mk("UIListLayout", {
        Parent = tabList,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    })

    local content = mk("Frame", {
        Parent = body,
        BackgroundColor3 = C.Panel,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 150, 0, 0),
        Size = UDim2.new(1, -150, 1, 0),
    })
    mk("UIPadding", {
        Parent = content,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    })
    local pageHolder = mk("Frame", {
        Parent = content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
    })

    local toastHost = mk("Frame", {
        Parent = sg,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 10),
        Size = UDim2.new(0, 320, 1, -20),
    })
    mk("UIListLayout", {
        Parent = toastHost,
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    })

    local w = setmetatable({
        ScreenGui = sg,
        Main = main,
        TitleLabel = titleLbl,
        TabList = tabList,
        PageHolder = pageHolder,
        Tabs = {},
        ActiveTab = nil,
        Connections = {},
        CloseCallbacks = {},
        ToggleKey = toggleKey,
        Destroyed = false,
    }, Window)

    UILibrary._window = w
    UILibrary._toastHost = toastHost

    local dragging = false
    local dragFrom = Vector2.new(0, 0)
    local startPos = UDim2.new()
    track(w.Connections, top.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragFrom = i.Position
            startPos = main.Position
        end
    end))
    track(w.Connections, UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragFrom
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    track(w.Connections, UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    track(w.Connections, hide.MouseButton1Click:Connect(function()
        w:SetVisible(false)
    end))
    track(w.Connections, close.MouseButton1Click:Connect(function()
        w:Destroy()
    end))
    track(w.Connections, UIS.InputBegan:Connect(function(i, gpe)
        if gpe then
            return
        end
        if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == w.ToggleKey then
            w:Toggle()
        end
    end))

    return w
end

function UILibrary:SetVisibility(v)
    if self._window then
        self._window:SetVisible(v == true)
    end
end

function UILibrary:IsVisible()
    return self._window and self._window:IsVisible() or false
end

function UILibrary:Destroy()
    if self._window then
        self._window:Destroy()
    end
end

function UILibrary:Notify(args)
    args = args or {}
    local title = tostring(args.Title or "Notification")
    local content = tostring(args.Content or "")
    local duration = tonumber(args.Duration) or 3

    local host = self._toastHost
    if not host or not host.Parent then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = title,
                Text = content,
                Duration = duration,
            })
        end)
        return
    end

    local toast = mk("Frame", {
        Parent = host,
        BackgroundColor3 = C.Top,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = -os.clock(),
    })
    corner(toast, 6)
    stroke(toast, C.Stroke, 0.25)
    mk("UIPadding", {
        Parent = toast,
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    })
    local t = mk("TextLabel", {
        Parent = toast,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.Text,
        Text = title,
    })
    local c = mk("TextLabel", {
        Parent = toast,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 17),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = FONT,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = C.SubText,
        Text = content,
    })
    toast.BackgroundTransparency = 1
    t.TextTransparency = 1
    c.TextTransparency = 1
    tw(toast, 0.15, { BackgroundTransparency = 0 }):Play()
    tw(t, 0.15, { TextTransparency = 0 }):Play()
    tw(c, 0.15, { TextTransparency = 0 }):Play()
    task.delay(duration, function()
        if not toast.Parent then
            return
        end
        tw(toast, 0.15, { BackgroundTransparency = 1 }):Play()
        tw(t, 0.15, { TextTransparency = 1 }):Play()
        tw(c, 0.15, { TextTransparency = 1 }):Play()
        task.delay(0.16, function()
            if toast.Parent then
                toast:Destroy()
            end
        end)
    end)
end

function UILibrary:NotifyInfo(args)
    return self:Notify(args)
end

function UILibrary:NotifyWarning(args)
    args = args or {}
    args.Title = args.Title or "Warning"
    return self:Notify(args)
end

function UILibrary:NotifyError(args)
    args = args or {}
    args.Title = args.Title or "Error"
    return self:Notify(args)
end

return UILibrary
