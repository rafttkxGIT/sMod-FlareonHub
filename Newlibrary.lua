--[[
    Flareon UI Library — fixed & restyled (Elerium-v2 compatible API)
    Works on Solara / Arceus / etc. No image assets, pure frames + UICorner.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- helpers
-- ============================================================

local function make(class, props, parent)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            pcall(function() inst[k] = v end)
        end
    end
    if parent then inst.Parent = parent end
    return inst
end

local function getGuiParent()
    if typeof(gethui) == "function" then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    local ok, coregui = pcall(function() return game:GetService("CoreGui") end)
    if ok and coregui then return coregui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function protectGui(gui)
    if typeof(syn) == "table" and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    end
end

local function formatValue(v)
    return string.format("%g", math.floor(v * 100 + 0.5) / 100)
end

-- ============================================================
-- theme
-- ============================================================

local Theme = {
    main_color = Color3.fromRGB(100, 200, 255),
    background = Color3.fromRGB(24, 25, 30),
    sidebar = Color3.fromRGB(29, 31, 37),
    surface = Color3.fromRGB(38, 40, 48),
    surface_hover = Color3.fromRGB(48, 51, 61),
    text = Color3.fromRGB(228, 230, 235),
    dim = Color3.fromRGB(148, 152, 163),
    accent = Color3.fromRGB(80, 255, 120),
    warning = Color3.fromRGB(255, 180, 70),
    error = Color3.fromRGB(244, 67, 54),
    corner = 8,
    font = Enum.Font.GothamMedium,
    font_bold = Enum.Font.GothamBold,
    text_size = 14,
    tween = 0.18,
}

-- forward declarations (this order bug was crashing AddTab before)
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab

-- ============================================================
-- window
-- ============================================================

local HEADER_H = 36
local SIDEBAR_W = 118

function Window.new(title, options, theme)
    local self = setmetatable({}, Window)
    options = options or {}
    self.Options = options
    self.Tabs = {}
    self.CurrentTab = nil
    self._theme = theme
    self._connections = {}

    local width, height = 460, 340
    if typeof(options.min_size) == "Vector2" then
        width = math.max(options.min_size.X, 240)
        height = math.max(options.min_size.Y, 180)
    end

    local gui = make("ScreenGui", {
        Name = "FlareonHub_UI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        Enabled = true,
    })
    protectGui(gui)
    gui.Parent = getGuiParent()
    self._gui = gui

    local main = make("Frame", {
        Name = "Main",
        Active = true,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, -20),
        Size = UDim2.fromOffset(width, height),
    }, gui)
    make("UICorner", { CornerRadius = UDim.new(0, theme.corner) }, main)
    make("UIStroke", {
        Color = theme.main_color,
        Thickness = 1,
        Transparency = 0.7,
    }, main)
    self._main = main

    -- header
    local header = make("Frame", {
        Name = "Header",
        BackgroundColor3 = theme.main_color,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, HEADER_H),
    }, main)
    make("UICorner", { CornerRadius = UDim.new(0, theme.corner) }, header)
    make("Frame", { -- square off bottom corners of header
        BackgroundColor3 = theme.main_color,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -theme.corner),
        Size = UDim2.new(1, 0, 0, theme.corner),
    }, header)

    local titleLabel = make("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Font = theme.font_bold,
        Position = UDim2.new(0, 12, 0, 0),
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
            AutoButtonColor = false,
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Font = theme.font_bold,
            Position = UDim2.new(1, xOffset, 0.5, -10),
            Size = UDim2.fromOffset(20, 20),
            Text = text,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 12,
        }, header)
        make("UICorner", { CornerRadius = UDim.new(1, 0) }, btn)
        return btn
    end

    local closeBtn = headerButton("X", -26, theme.error)
    local minBtn = headerButton("—", -52, Color3.fromRGB(90, 94, 105))

    local function connect(signal, fn)
        local c = signal:Connect(fn)
        self._connections[#self._connections + 1] = c
        return c
    end

    closeBtn.MouseButton1Click:Connect(function() self:Hide() end)
    minBtn.MouseButton1Click:Connect(function() self:Hide() end)

    -- custom drag (Draggable property is deprecated/broken in most executors)
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

    -- toggle key so closing isn't permanent
    local toggleKey = options.hide_key or Enum.KeyCode.RightShift
    connect(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == toggleKey then
            gui.Enabled = not gui.Enabled
        end
    end)

    -- sidebar (tab buttons)
    local sidebar = make("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = theme.sidebar,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0, HEADER_H + 6),
        Size = UDim2.new(0, SIDEBAR_W, 1, -(HEADER_H + 12)),
    }, main)
    make("UICorner", { CornerRadius = UDim.new(0, theme.corner) }, sidebar)

    local sideScroll = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.main_color,
    }, sidebar)
    make("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, sideScroll)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
    }, sideScroll)

    -- content
    local content = make("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, SIDEBAR_W + 14, 0, HEADER_H + 6),
        Size = UDim2.new(1, -(SIDEBAR_W + 22), 1, -(HEADER_H + 12)),
    }, main)
    self._content = content
    self._sideScroll = sideScroll

    -- optional resize grip
    if options.can_resize then
        local grip = make("TextButton", {
            AnchorPoint = Vector2.new(1, 1),
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 0, 1, 0),
            Size = UDim2.fromOffset(18, 18),
            Text = "◢",
            TextColor3 = theme.dim,
            TextSize = 12,
        }, main)
        local resizing = false
        local startSize, startInput
        grip.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = true
                startSize = main.Size
                startInput = input.Position
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - startInput
                main.Size = UDim2.new(
                    0, math.max(240, startSize.X.Offset + delta.X),
                    0, math.max(180, startSize.Y.Offset + delta.Y)
                )
            end
        end)
        connect(UserInputService.InputEnded, function()
            resizing = false
        end)
    end

    return self
end

function Window:SetTitle(newTitle)
    self._titleLabel.Text = tostring(newTitle)
end

function Window:Show() self._gui.Enabled = true end
function Window:Hide() self._gui.Enabled = false end
function Window:Toggle() self._gui.Enabled = not self._gui.Enabled end

function Window:Destroy()
    for _, c in ipairs(self._connections) do
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

-- ============================================================
-- tab
-- ============================================================

function Tab.new(name, window)
    local self = setmetatable({}, Tab)
    self.Name = name
    self._window = window
    self._order = 0
    local theme = window._theme

    local btn = make("TextButton", {
        Name = "Tab_" .. name,
        AutoButtonColor = false,
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Font = theme.font,
        Size = UDim2.new(1, 0, 0, 30),
        Text = name,
        TextColor3 = theme.dim,
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = #window.Tabs + 1,
    }, window._sideScroll)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    make("UIPadding", { PaddingLeft = UDim.new(0, 8) }, btn)
    self._button = btn

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
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 8),
    }, scroll)

    self._frame = frame
    self._scroll = scroll

    btn.MouseButton1Click:Connect(function()
        self:Show()
    end)

    return self
end

function Tab:_nextOrder()
    self._order = self._order + 1
    return self._order
end

function Tab:_setActive(active)
    local theme = self._window._theme
    self._button.BackgroundColor3 = active and theme.main_color or theme.surface
    self._button.TextColor3 = active and Color3.fromRGB(255, 255, 255) or theme.dim
end

function Tab:Show()
    for _, tab in ipairs(self._window.Tabs) do
        local active = (tab == self)
        tab._frame.Visible = active
        tab:_setActive(active)
    end
    self._window.CurrentTab = self
end

function Tab:Hide()
    self._frame.Visible = false
    self:_setActive(false)
    if self._window.CurrentTab == self then
        self._window.CurrentTab = nil
    end
end

-- ============================================================
-- elements
-- ============================================================

function Tab:AddLabel(text)
    local theme = self._window._theme
    return make("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = theme.font,
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 18),
        Text = tostring(text),
        TextColor3 = theme.text,
        TextSize = theme.text_size,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self._scroll)
end

function Tab:AddParagraph(title, body)
    local theme = self._window._theme
    local container = make("Frame", {
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 34),
    }, self._scroll)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, container)
    make("TextLabel", {
        BackgroundTransparency = 1,
        Font = theme.font_bold,
        Position = UDim2.new(0, 8, 0, 4),
        Size = UDim2.new(1, -16, 0, 18),
        Text = tostring(title),
        TextColor3 = theme.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    make("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = theme.font,
        Position = UDim2.new(0, 8, 0, 22),
        Size = UDim2.new(1, -16, 0, 14),
        Text = tostring(body or ""),
        TextColor3 = theme.dim,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    return container
end

function Tab:AddDivider()
    local theme = self._window._theme
    local holder = make("Frame", {
        BackgroundTransparency = 1,
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 10),
    }, self._scroll)
    make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
    }, holder)
    return holder
end

function Tab:AddButton(text, callback)
    local theme = self._window._theme
    local button = make("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Font = theme.font,
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 30),
        Text = tostring(text),
        TextColor3 = theme.text,
        TextSize = theme.text_size,
    }, self._scroll)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, button)

    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = theme.surface_hover
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = theme.surface
    end)
    button.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)
    return button
end

function Tab:AddSwitch(text, callback, default)
    local theme = self._window._theme
    local container = make("Frame", {
        BackgroundTransparency = 1,
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 28),
    }, self._scroll)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Font = theme.font,
        Position = UDim2.new(0, 2, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Text = tostring(text),
        TextColor3 = theme.text,
        TextSize = theme.text_size,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)

    local track = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        AutoButtonColor = false,
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(38, 20),
        Text = "",
    }, container)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
    make("UIStroke", { Color = theme.dim, Thickness = 1, Transparency = 0.55 }, track)

    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.dim,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
    }, track)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local state = default == true

    local function render(v)
        local tweenInfo = TweenInfo.new(theme.tween, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(knob, tweenInfo, {
            Position = v and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0),
            BackgroundColor3 = v and Color3.fromRGB(255, 255, 255) or theme.dim,
        }):Play()
        TweenService:Create(track, tweenInfo, {
            BackgroundColor3 = v and theme.main_color or theme.surface,
        }):Play()
        track.UIStroke.Transparency = v and 0.3 or 0.55
    end

    local function set(v, fire)
        state = v and true or false
        render(state)
        if fire and callback then pcall(callback, state) end
    end

    track.MouseButton1Click:Connect(function()
        set(not state, true)
    end)
    set(state, false)

    return {
        Set = function(_, v) set(v, true) end,
        SetSilent = function(_, v) set(v, false) end,
        Get = function() return state end,
        Toggle = function() set(not state, true) end,
    }
end

function Tab:AddTextBox(placeholder, callback, options)
    options = options or {}
    local theme = self._window._theme

    local container = make("Frame", {
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 30),
    }, self._scroll)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, container)

    local box = make("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = options.clear ~= false,
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

    return {
        Get = function() return box.Text end,
        Set = function(_, t) box.Text = tostring(t or "") end,
        Object = box,
    }
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
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 46),
    }, self._scroll)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, container)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Font = theme.font,
        Position = UDim2.new(0, 8, 0, 3),
        Size = UDim2.new(1, -76, 0, 18),
        Text = tostring(title),
        TextColor3 = theme.text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)

    local valueLabel = make("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Font = theme.font_bold,
        Position = UDim2.new(1, -8, 0, 3),
        Size = UDim2.new(0, 64, 0, 18),
        Text = formatValue(defaultValue),
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

    local value = defaultValue
    local dragging = false

    local function render(v)
        value = math.clamp(v, minValue, maxValue)
        local alpha = (value - minValue) / (maxValue - minValue)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = formatValue(value)
    end

    local function fromX(xAbs)
        local rel = math.clamp(xAbs - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
        local alpha = bar.AbsoluteSize.X > 0 and (rel / bar.AbsoluteSize.X) or 0
        render(minValue + (maxValue - minValue) * alpha)
        if callback then pcall(callback, value) end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            fromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    render(defaultValue)

    return {
        Get = function() return value end,
        Set = function(_, v)
            render(tonumber(v) or minValue)
            if callback then pcall(callback, value) end
        end,
    }
end

-- accepts AddDropdown(text, {opts}, callback, default) OR AddDropdown(text, callback, {opts}, default)
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
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 30),
    }, self._scroll)

    local header = make("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Font = theme.font,
        Size = UDim2.new(1, 0, 0, 30),
        Text = tostring(title) .. ": ...",
        TextColor3 = theme.text,
        TextSize = theme.text_size,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, header)
    make("UIPadding", { PaddingLeft = UDim.new(0, 8) }, header)

    local listFrame = make("Frame", {
        BackgroundColor3 = theme.background,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ZIndex = 5,
    }, container)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, listFrame)
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
    local count = 0
    local open = false

    local function set(entry, fire)
        current = entry
        header.Text = tostring(title) .. ": " .. tostring(entry)
        if fire and callback then pcall(callback, entry) end
    end

    local function setOpen(v)
        open = v
        listFrame.Visible = open
        container.Size = open
            and UDim2.new(1, 0, 0, 32 + 4 + count * 26 + math.max(0, count - 1) * 2)
            or UDim2.new(1, 0, 0, 30)
    end

    for _, entry in ipairs(optionList) do
        count = count + 1
        local optBtn = make("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = theme.surface,
            BorderSizePixel = 0,
            Font = theme.font,
            LayoutOrder = count,
            Size = UDim2.new(1, 0, 0, 26),
            Text = tostring(entry),
            TextColor3 = theme.text,
            TextSize = 13,
            ZIndex = 6,
        }, listFrame)
        make("UICorner", { CornerRadius = UDim.new(0, 4) }, optBtn)
        optBtn.MouseButton1Click:Connect(function()
            set(entry, true)
            setOpen(false)
        end)
    end

    header.MouseButton1Click:Connect(function()
        setOpen(not open)
    end)

    if defaultValue ~= nil then set(defaultValue, false) end

    return {
        Get = function() return current end,
        Set = function(_, entry) set(entry, false) end,
    }
end

function Tab:AddKeyBind(title, callback, defaultKey)
    local theme = self._window._theme
    local container = make("Frame", {
        BackgroundTransparency = 1,
        LayoutOrder = self:_nextOrder(),
        Size = UDim2.new(1, 0, 0, 28),
    }, self._scroll)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Font = theme.font,
        Position = UDim2.new(0, 2, 0, 0),
        Size = UDim2.new(1, -90, 1, 0),
        Text = tostring(title),
        TextColor3 = theme.text,
        TextSize = theme.text_size,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)

    local key = defaultKey
    local waiting = false

    local btn = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        AutoButtonColor = false,
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Font = theme.font,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(70, 22),
        Text = key and key.Name or "...",
        TextColor3 = theme.dim,
        TextSize = 12,
    }, container)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)

    btn.MouseButton1Click:Connect(function()
        waiting = true
        btn.Text = "press a key..."
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if waiting then
            waiting = false
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                key = input.KeyCode
            end
            btn.Text = key and key.Name or "..."
        elseif key and not gameProcessed and input.KeyCode == key then
            if callback then pcall(callback) end
        end
    end)

    return {
        Get = function() return key end,
        Set = function(_, k)
            key = k
            btn.Text = key and key.Name or "..."
        end,
    }
end

-- aliases so any naming style in the rest of the script still works
Tab.AddTextbox = Tab.AddTextBox
Tab.AddToggle = Tab.AddSwitch
Tab.AddTitle = Tab.AddLabel
Tab.AddParagraph = Tab.AddParagraph

-- ============================================================
-- library export
-- ============================================================

local Library = {
    Theme = Theme,
    Windows = {},
}

local cleanedOnce = false

function Library:AddWindow(title, options)
    if not cleanedOnce then
        cleanedOnce = true
        pcall(function()
            for _, child in ipairs(getGuiParent():GetChildren()) do
                if child:IsA("ScreenGui") and child.Name == "FlareonHub_UI" then
                    child:Destroy()
                end
            end
        end)
    end

    local theme = {}
    for k, v in pairs(Theme) do theme[k] = v end
    options = options or {}
    if typeof(options.main_color) == "Color3" then
        theme.main_color = options.main_color
    end

    local win = Window.new(title, options, theme)
    self.Windows[#self.Windows + 1] = win
    return win
end

Library.CreateWindow = Library.AddWindow

function Library:Notify(text, duration)
    local theme = Theme
    local gui = make("ScreenGui", {
        Name = "FlareonHub_Notify",
        ResetOnSpawn = false,
        DisplayOrder = 200,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    protectGui(gui)
    gui.Parent = getGuiParent()

    local toast = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = theme.background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 1, 80),
        Size = UDim2.fromOffset(280, 40),
    }, gui)
    make("UICorner", { CornerRadius = UDim.new(0, 8) }, toast)
    make("UIStroke", { Color = theme.main_color, Thickness = 1, Transparency = 0.6 }, toast)
    make("TextLabel", {
        BackgroundTransparency = 1,
        Font = theme.font,
        PaddingLeft = UDim.new(0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Text = tostring(text),
        TextColor3 = theme.text,
        TextSize = 13,
        TextWrapped = true,
    }, toast)

    toast:TweenPosition(UDim2.new(0.5, 0, 1, -60), Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad, theme.tween, true)
    task.delay(duration or 3, function()
        toast:TweenPosition(UDim2.new(0.5, 0, 1, 80), Enum.EasingDirection.In,
            Enum.EasingStyle.Quad, theme.tween, true)
        task.wait(theme.tween + 0.05)
        gui:Destroy()
    end)
end

function Library:Destroy()
    for _, win in ipairs(self.Windows) do
        pcall(function() win:Destroy() end)
    end
    self.Windows = {}
end

return Library
