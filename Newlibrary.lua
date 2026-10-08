--[[
    Flareon UI Library — fixed build
    Drop-in replacement for Newlibrary.lua (Elerium-v2-style API)
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- forward declarations (fixes the fatal nil-Tab bug)
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab

-- ============ utils ============

local function safeSet(obj, prop, value)
    pcall(function() obj[prop] = value end)
end

local function protect(gui)
    if type(syn) == "table" and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    end
end

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if ok and coreGui then return coreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function make(className, props, parent)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            safeSet(inst, k, v)
        end
    end
    inst.Parent = parent
    return inst
end

-- wrapper: lets you do element.Text = x, element.TextColor3 = x, element:Remove()
local function wrap(instance, methods)
    local extra = methods or {}
    extra.Remove = extra.Remove or function() instance:Destroy() end
    extra.Object = instance
    return setmetatable({}, {
        __index = function(_, key)
            local v = extra[key]
            if v ~= nil then return v end
            local ok, res = pcall(function() return instance[key] end)
            if ok then return res end
            return nil
        end,
        __newindex = function(_, key, value)
            if extra[key] ~= nil then
                extra[key] = value
            else
                pcall(function() instance[key] = value end)
            end
        end,
    })
end

-- ============ theme ============

local Theme = {
    main_color = Color3.fromRGB(100, 200, 255),
    background = Color3.fromRGB(24, 25, 29),
    surface = Color3.fromRGB(35, 37, 43),
    surface_hover = Color3.fromRGB(46, 49, 58),
    text = Color3.fromRGB(225, 225, 230),
    dim = Color3.fromRGB(145, 148, 158),
    accent = Color3.fromRGB(80, 255, 120),
    error = Color3.fromRGB(244, 67, 54),
    corner = 6,
    font = Enum.Font.GothamMedium,
    font_bold = Enum.Font.GothamBold,
    text_size = 14,
}

local Library = {
    Windows = {},
    Theme = Theme,
    ToggleKey = Enum.KeyCode.RightShift,
}

-- ============ window ============

function Window.new(title, options)
    local self = setmetatable({}, Window)
    options = options or {}
    self.Options = options
    self.Tabs = {}
    self.CurrentTab = nil

    local theme = {}
    for k, v in pairs(Theme) do theme[k] = v end
    if typeof(options.main_color) == "Color3" then theme.main_color = options.main_color end
    if typeof(options.background_color) == "Color3" then theme.background = options.background_color end
    self._theme = theme

    -- min_size actually applied now
    local width, height = 480, 340
    if typeof(options.min_size) == "Vector2" then
        width = math.max(options.min_size.X, 220)
        height = math.max(options.min_size.Y, 160)
    end

    local gui = make("ScreenGui", {
        Name = "FlareonUI_" .. tostring(math.random(100000, 999999)),
        ResetOnSpawn = false,
        DisplayOrder = 9999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Enabled = true,
    })
    protect(gui)
    gui.Parent = getGuiParent()
    self._gui = gui

    local main = make("Frame", {
        Name = "Main",
        Active = true,
        BackgroundColor3 = theme.background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
        Size = UDim2.fromOffset(width, height),
    }, gui)
    make("UICorner", { CornerRadius = UDim.new(0, theme.corner) }, main)
    make("UIStroke", { Color = theme.main_color, Thickness = 1, Transparency = 0.65 }, main)
    self._main = main

    -- header
    local header = make("Frame", {
        Name = "Header",
        BackgroundColor3 = theme.main_color,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
    }, main)
    make("UICorner", { CornerRadius = UDim.new(0, theme.corner) }, header)
    make("Frame", { -- square off header's bottom corners
        BackgroundColor3 = theme.main_color,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -theme.corner),
        Size = UDim2.new(1, 0, 0, theme.corner),
    }, header)

    local titleLabel = make("TextLabel", {
        BackgroundTransparency = 1,
        Font = theme.font_bold,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Text = tostring(title or "Window"),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, header)
    self._titleLabel = titleLabel

    local function headerButton(text, xOffset, color)
        local btn = make("TextButton", {
            AutoButtonColor = true,
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Font = theme.font_bold,
            Position = UDim2.new(1, xOffset, 0.5, -10),
            Size = UDim2.fromOffset(20, 20),
            Text = text,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 13,
        }, header)
        make("UICorner", { CornerRadius = UDim.new(1, 0) }, btn)
        return btn
    end

    local closeBtn = headerButton("X", -26, theme.error)
    local minBtn = headerButton("-", -52, Color3.fromRGB(90, 90, 100))
    closeBtn.MouseButton1Click:Connect(function() self:Hide() end)
    minBtn.MouseButton1Click:Connect(function() self:Hide() end)

    -- connection tracking + custom drag (Draggable is deprecated)
    local connections = {}
    local function connect(signal, fn)
        local c = signal:Connect(fn)
        connections[#connections + 1] = c
        return c
    end

    do
        local dragging = false
        local dragStart, startPos
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
        connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    -- optional resize grip
    if options.can_resize then
        local grip = make("TextButton", {
            AnchorPoint = Vector2.new(1, 1),
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 0, 1, 0),
            Size = UDim2.fromOffset(16, 16),
            Text = "",
        }, main)
        local resizing = false
        local startSize, startPos
        grip.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                startSize = main.Size
                startPos = input.Position
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - startPos
                main.Size = UDim2.new(
                    0, math.max(220, startSize.X.Offset + delta.X),
                    0, math.max(160, startSize.Y.Offset + delta.Y)
                )
            end
        end)
        connect(UserInputService.InputEnded, function()
            resizing = false
        end)
    end

    -- toggle key so the X button isn't a one-way trip
    local toggleKey = options.hide_key or Library.ToggleKey
    connect(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == toggleKey then
            self:Toggle()
        end
    end)

    self._connections = connections

    -- tab bar (horizontal, scrollable)
    local tabBar = make("ScrollingFrame", {
        Name = "TabBar",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 36),
        Size = UDim2.new(1, -16, 0, 28),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.main_color,
    }, main)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, tabBar)

    local content = make("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 68),
        Size = UDim2.new(1, -16, 1, -76),
    }, main)
    self._content = content
    self._tabBar = tabBar

    return self
end

function Window:SetTitle(newTitle)
    self._titleLabel.Text = tostring(newTitle)
end

function Window:Show() self._gui.Enabled = true end
function Window:Hide() self._gui.Enabled = false end
function Window:Toggle() self._gui.Enabled = not self._gui.Enabled end

function Window:Destroy()
    for _, c in ipairs(self._connections or {}) do
        pcall(function() c:Disconnect() end)
    end
    self._gui:Destroy()
end

function Window:AddTab(name)
    local tab = Tab.new(tostring(name), self)
    self.Tabs[#self.Tabs + 1] = tab
    if not self.CurrentTab then
        tab:Show()
    end
    return tab
end

-- ============ tab ============

function Tab.new(name, window)
    local self = setmetatable({}, Tab)
    self.Name = name
    self._window = window
    local theme = window._theme

    local btn = make("TextButton", {
        Name = "TabBtn_" .. name,
        AutomaticSize = Enum.AutomaticSize.X,
        AutoButtonColor = false,
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Font = theme.font,
        Size = UDim2.new(0, 0, 1, 0),
        Text = name,
        TextColor3 = theme.dim,
        TextSize = 13,
    }, window._tabBar)
    make("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    }, btn)

    local frame = make("Frame", {
        Name = "TabFrame_" .. name,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
    }, window._content)

    local scroll = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.main_color,
        ScrollBarImageTransparency = 0.2,
    }, frame)
    make("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, scroll)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 2),
        PaddingTop = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 6),
    }, scroll)

    self._frame = frame
    self._scroll = scroll
    self._button = btn

    btn.MouseButton1Click:Connect(function()
        self:Show()
    end)

    return self
end

function Tab:_setActive(active)
    local theme = self._window._theme
    self._button.BackgroundColor3 = active and theme.main_color or theme.surface
    self._button.TextColor3 = active and Color3.fromRGB(255, 255, 255) or theme.dim
end

-- radio behaviour: showing one tab hides the others (your script relies on this)
function Tab:Show()
    local window = self._window
    for _, tab in ipairs(window.Tabs) do
        if tab ~= self then
            tab._frame.Visible = false
            tab:_setActive(false)
        end
    end
    self._frame.Visible = true
    self:_setActive(true)
    window.CurrentTab = self
end

function Tab:Hide()
    self._frame.Visible = false
    self:_setActive(false)
    if self._window.CurrentTab == self then
        self._window.CurrentTab = nil
    end
end

-- ============ elements ============

function Tab:AddLabel(text)
    local theme = self._window._theme
    local label = make("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = theme.font,
        Size = UDim2.new(1, 0, 0, 18),
        Text = tostring(text),
        TextColor3 = theme.text,
        TextSize = theme.text_size,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self._scroll)
    return wrap(label)
end

function Tab:AddDivider()
    local holder = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 10),
    }, self._scroll)
    make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self._window._theme.surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
    }, holder)
    return wrap(holder)
end

function Tab:AddButton(text, callback)
    local theme = self._window._theme
    local button = make("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Font = theme.font,
        Size = UDim2.new(1, 0, 0, 30),
        Text = tostring(text),
        TextColor3 = theme.text,
        TextSize = theme.text_size,
    }, self._scroll)
    make("UICorner", { CornerRadius = UDim.new(0, 4) }, button)

    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = theme.surface_hover
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = theme.surface
    end)
    button.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)

    return wrap(button, {
        SetText = function(_, newText) button.Text = tostring(newText) end,
    })
end

function Tab:AddSwitch(text, callback, default)
    local theme = self._window._theme
    local container = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 26),
    }, self._scroll)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Font = theme.font,
        Position = UDim2.new(0, 2, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Text = tostring(text),
        TextColor3 = theme.text,
        TextSize = theme.text_size,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)

    local toggle = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        AutoButtonColor = false,
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(20, 20),
        Text = "",
    }, container)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, toggle)
    make("UIStroke", { Color = theme.dim, Thickness = 1, Transparency = 0.5 }, toggle)

    local state = default == true

    local function set(v, fireCallback)
        state = v and true or false
        toggle.BackgroundColor3 = state and theme.main_color or theme.surface
        toggle.UIStroke.Transparency = state and 0 or 0.5
        if fireCallback and callback then
            pcall(callback, state)
        end
    end

    toggle.MouseButton1Click:Connect(function()
        set(not state, true)
    end)
    set(state, false)

    return wrap(container, {
        Set = function(_, v) set(v, true) end,
        SetSilent = function(_, v) set(v, false) end,
        Get = function() return state end,
        Toggle = function() set(not state, true) end,
    })
end

function Tab:AddTextBox(placeholder, callback, options)
    options = options or {}
    local theme = self._window._theme

    local container = make("Frame", {
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
    }, self._scroll)
    make("UICorner", { CornerRadius = UDim.new(0, 4) }, container)

    local box = make("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = options.clear == false and false or true,
        Font = theme.font,
        PlaceholderColor3 = theme.dim,
        PlaceholderText = tostring(placeholder or ""),
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Text = "",
        TextColor3 = theme.text,
        TextSize = theme.text_size,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)

    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local value = box.Text
            if callback then pcall(callback, value) end
            if options.clear ~= false then
                box.Text = ""
            end
        end
    end)

    return wrap(container, {
        Get = function() return box.Text end,
        Set = function(_, t) box.Text = tostring(t or "") end,
    })
end

-- accepts AddSlider(text, min, max, callback, default) OR AddSlider(text, callback, min, max, default)
function Tab:AddSlider(...)
    local args = { ... }
    local theme = self._window._theme
    local title, a, b, c, d = args[1], args[2], args[3], args[4], args[5]

    local minValue, maxValue, callback, defaultValue
    if type(a) == "number" then
        minValue, maxValue, callback, defaultValue = a, b, c, d
    else
        callback, minValue, maxValue, defaultValue = a, b, c, d
    end

    minValue = tonumber(minValue) or 0
    maxValue = tonumber(maxValue) or 100
    if maxValue <= minValue then maxValue = minValue + 1 end
    defaultValue = math.clamp(tonumber(defaultValue) or minValue, minValue, maxValue)

    local container = make("Frame", {
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44),
    }, self._scroll)
    make("UICorner", { CornerRadius = UDim.new(0, 4) }, container)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Font = theme.font,
        Position = UDim2.new(0, 8, 0, 2),
        Size = UDim2.new(1, -70, 0, 20),
        Text = tostring(title),
        TextColor3 = theme.text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)

    local valueLabel = make("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Font = theme.font_bold,
        Position = UDim2.new(1, -8, 0, 2),
        Size = UDim2.new(0, 60, 0, 20),
        Text = tostring(defaultValue),
        TextColor3 = theme.main_color,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, container)

    local bar = make("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.background,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 28),
        Size = UDim2.new(1, -20, 0, 6),
        Text = "",
    }, container)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)

    local fill = make("Frame", {
        BackgroundColor3 = theme.main_color,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
    }, bar)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        ZIndex = 3,
    }, bar)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local state = { value = defaultValue }
    local dragging = false

    local function render(value)
        value = math.clamp(value, minValue, maxValue)
        state.value = value
        local alpha = (value - minValue) / (maxValue - minValue)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = tostring(math.floor(value * 100 + 0.5) / 100)
    end

    local function setValueFromX(xAbs)
        local rel = math.clamp(xAbs - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
        local alpha = bar.AbsoluteSize.X > 0 and (rel / bar.AbsoluteSize.X) or 0
        render(minValue + (maxValue - minValue) * alpha)
        if callback then pcall(callback, state.value) end
    end

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setValueFromX(input.Position.X)
        end
    end

    bar.InputBegan:Connect(onInputBegan)
    knob.InputBegan:Connect(onInputBegan)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setValueFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    render(defaultValue)

    return wrap(container, {
        Get = function() return state.value end,
        Set = function(_, v)
            render(tonumber(v) or minValue)
            if callback then pcall(callback, state.value) end
        end,
    })
end

-- accepts AddDropdown(text, {options}, callback, default) OR AddDropdown(text, callback, {options}, default)
function Tab:AddDropdown(...)
    local args = { ... }
    local theme = self._window._theme
    local title, a, b, c = args[1], args[2], args[3], args[4]

    local optionList, callback, defaultValue
    if type(a) == "table" then
        optionList, callback, defaultValue = a, b, c
    else
        callback, optionList, defaultValue = a, b, c
    end
    optionList = optionList or {}

    local container = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        ZIndex = 20,
    }, self._scroll)

    local header = make("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Font = theme.font,
        Size = UDim2.new(1, 0, 0, 30),
        Text = tostring(title),
        TextColor3 = theme.text,
        TextSize = theme.text_size,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 20,
    }, container)
    make("UICorner", { CornerRadius = UDim.new(0, 4) }, header)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, header)

    local listFrame = make("Frame", {
        BackgroundColor3 = theme.background,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ZIndex = 21,
    }, container)
    make("UICorner", { CornerRadius = UDim.new(0, 4) }, listFrame)
    make("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, listFrame)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 2),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 2),
    }, listFrame)

    local current = nil
    local optionButtons = {}
    local open = false

    local function set(entry, fireCallback)
        current = entry
        header.Text = tostring(title) .. ": " .. tostring(entry)
        if fireCallback and callback then pcall(callback, entry) end
    end

    local function rebuild()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        optionButtons = {}
        local entries = {}
        for key, value in pairs(optionList) do
            if type(value) == "string" or type(value) == "number" then
                entries[#entries + 1] = tostring(value)
            elseif type(key) == "string" then
                entries[#entries + 1] = key
            end
        end
        table.sort(entries)
        for index, entry in ipairs(entries) do
            local optBtn = make("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = theme.surface,
                BorderSizePixel = 0,
                Font = theme.font,
                LayoutOrder = index,
                Size = UDim2.new(1, 0, 0, 26),
                Text = entry,
                TextColor3 = theme.text,
                TextSize = 13,
                ZIndex = 22,
            }, listFrame)
            make("UICorner", { CornerRadius = UDim.new(0, 4) }, optBtn)
            optionButtons[optBtn] = entry
            optBtn.MouseButton1Click:Connect(function()
                set(entry, true)
                setOpen(false)
            end)
        end
    end

    local function listHeight()
        local count = 0
        for _ in pairs(optionButtons) do count = count + 1 end
        if count == 0 then return 4 end
        return 4 + count * 26 + (count - 1) * 2
    end

    function setOpen(v)
        open = v and true or false
        listFrame.Visible = open
        if open then
            container.Size = UDim2.new(1, 0, 0, 32 + listHeight())
        else
            container.Size = UDim2.new(1, 0, 0, 30)
        end
    end

    header.MouseButton1Click:Connect(function()
        setOpen(not open)
    end)

    rebuild()
    if defaultValue ~= nil then set(defaultValue, false) end

    return wrap(container, {
        Get = function() return current end,
        Set = function(_, entry) set(entry, false) end,
        Refresh = function(_, newList)
            optionList = newList or optionList
            rebuild()
        end,
    })
end

-- aliases in case the rest of your script uses different names
Tab.AddTextbox = Tab.AddTextBox
Tab.AddToggle = Tab.AddSwitch
Tab.AddTitle = Tab.AddLabel

-- ============ export ============

local cleaned = false

function Library:AddWindow(title, options)
    if not cleaned then
        cleaned = true
        local parent = getGuiParent()
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("ScreenGui") and child.Name:sub(1, 9) == "FlareonUI" then
                pcall(function() child:Destroy() end)
            end
        end
    end
    local win = Window.new(title, options)
    self.Windows[#self.Windows + 1] = win
    return win
end

Library.CreateWindow = Library.AddWindow

function Library:Destroy()
    for _, win in ipairs(self.Windows) do
        pcall(function() win:Destroy() end)
    end
    self.Windows = {}
end

return Library
