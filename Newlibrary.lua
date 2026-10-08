--[[ Flareon UI Library v3.1 - fixed build for Solara
     This file must contain ONLY this code. Last line: return Library
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local function make(class, props, parent)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            pcall(function() inst[k] = v end)
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function guiParent()
    local ok, ui = pcall(function()
        if type(gethui) == "function" then
            return gethui()
        end
        return nil
    end)
    if ok and ui then
        return ui
    end
    local okCore, core = pcall(function()
        return game:GetService("CoreGui")
    end)
    if okCore and core then
        return core
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function protect(gui)
    pcall(function()
        if syn and type(syn.protect_gui) == "function" then
            syn.protect_gui(gui)
        end
    end)
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local Theme = {
    main_color = Color3.fromRGB(100, 200, 255),
    background = Color3.fromRGB(24, 25, 30),
    sidebar = Color3.fromRGB(29, 31, 37),
    surface = Color3.fromRGB(38, 40, 48),
    hover = Color3.fromRGB(48, 51, 61),
    text = Color3.fromRGB(228, 230, 235),
    dim = Color3.fromRGB(148, 152, 163),
    accent = Color3.fromRGB(80, 255, 120),
    warning = Color3.fromRGB(255, 180, 70),
    error = Color3.fromRGB(244, 67, 54),
    corner = 8,
    font = Enum.Font.GothamMedium,
    font_bold = Enum.Font.GothamBold,
    text_size = 14,
}

local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab

local HEADER_H = 36
local SIDEBAR_W = 120

function Window.new(title, options, theme)
    local self = setmetatable({}, Window)
    options = options or {}
    self.Options = options
    self.Tabs = {}
    self.CurrentTab = nil
    self._theme = theme
    self._connections = {}

    local width, height = 460, 340
    if type(options.min_size) == "Vector2" then
        width = math.max(options.min_size.X, 240)
        height = math.max(options.min_size.Y, 180)
    end

    local gui = make("ScreenGui", {
        Name = "FlareonHub_UI",
        ResetOnSpawn = false,
        DisplayOrder = 100,
        Enabled = true,
    })
    protect(gui)
    gui.Parent = guiParent()
    self._gui = gui

    local main = make("Frame", {
        Active = true,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, -20),
        Size = UDim2.new(0, width, 0, height),
    }, gui)
    make("UICorner", {CornerRadius = UDim.new(0, theme.corner)}, main)
    make("UIStroke", {Color = theme.main_color, Thickness = 1, Transparency = 0.7}, main)
    self._main = main

    local header = make("Frame", {
        BackgroundColor3 = theme.main_color,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, HEADER_H),
    }, main)
    make("UICorner", {CornerRadius = UDim.new(0, theme.corner)}, header)
    make("Frame", {
        BackgroundColor3 = theme.main_color,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -theme.corner),
        Size = UDim2.new(1, 0, 0, theme.corner),
    }, header)

    self._title = make("TextLabel", {
        BackgroundTransparency = 1,
        Font = theme.font_bold,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -84, 1, 0),
        Text = tostring(title or "Window"),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, header)

    local function headerButton(txt, xOff, color)
        local b = make("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Font = theme.font_bold,
            Position = UDim2.new(1, xOff, 0.5, -10),
            Size = UDim2.new(0, 20, 0, 20),
            Text = txt,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
        }, header)
        make("UICorner", {CornerRadius = UDim.new(1, 0)}, b)
        return b
    end

    local closeBtn = headerButton("X", -26, theme.error)
    local minBtn = headerButton("-", -52, Color3.fromRGB(90, 94, 105))

    local function track(conn)
        self._connections[#self._connections + 1] = conn
        return conn
    end

    closeBtn.MouseButton1Click:Connect(function() self:Hide() end)
    minBtn.MouseButton1Click:Connect(function() self:Hide() end)

    do
        local dragging = false
        local dragStart, startPos
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
            end
        end)
        track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
    end

    local toggleKey = options.hide_key or Enum.KeyCode.RightShift
    track(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == toggleKey then
            gui.Enabled = not gui.Enabled
        end
    end))

    local sidebar = make("Frame", {
        BackgroundColor3 = theme.sidebar,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0, HEADER_H + 6),
        Size = UDim2.new(0, SIDEBAR_W, 1, -(HEADER_H + 12)),
    }, main)
    make("UICorner", {CornerRadius = UDim.new(0, theme.corner)}, sidebar)

    self._sideScroll = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.main_color,
    }, sidebar)
    make("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, self._sideScroll)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
    }, self._sideScroll)

    self._content = make("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, SIDEBAR_W + 14, 0, HEADER_H + 6),
        Size = UDim2.new(1, -(SIDEBAR_W + 22), 1, -(HEADER_H + 12)),
    }, main)

    return self
end

function Window:SetTitle(newTitle)
    self._title.Text = tostring(newTitle)
end

function Window:Show() self._gui.Enabled = true end
function Window:Hide() self._gui.Enabled = false end

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

function Tab.new(name, window)
    local self = setmetatable({}, Tab)
    self.Name = name
    self._window = window
    self._order = 0
    local theme = window._theme

    self._button = make("TextButton", {
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
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, self._button)
    make("UIPadding", {PaddingLeft = UDim.new(0, 8)}, self._button)

    self._frame = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    }, window._content)

    self._scroll = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.main_color,
    }, self._frame)
    make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, self._scroll)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 8),
    }, self._scroll)

    self._button.MouseButton1Click:Connect(function()
        self:Show()
    end)

    return self
end

function Tab:_next()
    self._order = self._order + 1
    return self._order
end

function Tab:_paint(active)
    local theme = self._window._theme
    self._button.BackgroundColor3 = active and theme.main_color or theme.surface
    self._button.TextColor3 = active and Color3.fromRGB(255, 255, 255) or theme.dim
end

function Tab:Show()
    for _, tab in ipairs(self._window.Tabs) do
        local active = (tab == self)
        tab._frame.Visible = active
        tab:_paint(active)
    end
    self._window.CurrentTab = self
end

function Tab:Hide()
    self._frame.Visible = false
    self:_paint(false)
end

function Tab:AddLabel(text)
    local theme = self._window._theme
    return make("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = theme.font,
        LayoutOrder = self:_next(),
        Size = UDim2.new(1, 0, 0, 18),
        Text = tostring(text),
        TextColor3 = theme.text,
        TextSize = theme.text_size,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self._scroll)
end

function Tab:AddDivider()
    local theme = self._window._theme
    local holder = make("Frame", {
        BackgroundTransparency = 1,
        LayoutOrder = self:_next(),
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
    local btn = make("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Font = theme.font,
        LayoutOrder = self:_next(),
        Size = UDim2.new(1, 0, 0, 30),
        Text = tostring(text),
        TextColor3 = theme.text,
        TextSize = theme.text_size,
    }, self._scroll)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = theme.hover
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = theme.surface
    end)
    btn.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)
    return btn
end

function Tab:AddSwitch(text, callback, default)
    local theme = self._window._theme
    local container = make("Frame", {
        BackgroundTransparency = 1,
        LayoutOrder = self:_next(),
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

    local trackBtn = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        AutoButtonColor = false,
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 38, 0, 20),
        Text = "",
    }, container)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, trackBtn)

    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.dim,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
    }, trackBtn)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

    local state = (default == true)

    local function paint(v)
        local info = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(knob, info, {
            Position = v and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0),
            BackgroundColor3 = v and Color3.fromRGB(255, 255, 255) or theme.dim,
        }):Play()
        TweenService:Create(trackBtn, info, {
            BackgroundColor3 = v and theme.main_color or theme.surface,
        }):Play()
    end

    local function set(v, fire)
        state = (v == true)
        paint(state)
        if fire and callback then
            pcall(callback, state)
        end
    end

    trackBtn.MouseButton1Click:Connect(function()
        set(not state, true)
    end)
    paint(state)

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
        LayoutOrder = self:_next(),
        Size = UDim2.new(1, 0, 0, 30),
    }, self._scroll)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, container)

    local box = make("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = not (options.clear == false),
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

function Tab:AddSlider(...)
    local args = {...}
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
    defaultValue = clamp(tonumber(defaultValue) or minValue, minValue, maxValue)

    local container = make("Frame", {
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        LayoutOrder = self:_next(),
        Size = UDim2.new(1, 0, 0, 46),
    }, self._scroll)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, container)

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
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, bar)

    local fill = make("Frame", {
        BackgroundColor3 = theme.main_color,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
    }, bar)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)

    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
        ZIndex = 3,
    }, bar)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

    local value = defaultValue
    local dragging = false

    local function render(v)
        value = clamp(v, minValue, maxValue)
        local alpha = (value - minValue) / (maxValue - minValue)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = tostring(math.floor(value * 100 + 0.5) / 100)
    end

    local function fromX(xAbs)
        local rel = clamp(xAbs - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
        local alpha = 0
        if bar.AbsoluteSize.X > 0 then
            alpha = rel / bar.AbsoluteSize.X
        end
        render(minValue + (maxValue - minValue) * alpha)
        if callback then pcall(callback, value) end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

function Tab:AddDropdown(title, optionList, callback, default)
    optionList = optionList or {}
    local theme = self._window._theme

    local container = make("Frame", {
        BackgroundTransparency = 1,
        LayoutOrder = self:_next(),
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
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, header)
    make("UIPadding", {PaddingLeft = UDim.new(0, 8)}, header)

    local listFrame = make("Frame", {
        BackgroundColor3 = theme.background,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ZIndex = 5,
    }, container)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, listFrame)
    make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, listFrame)

    local current = nil
    local count = 0

    local function set(entry, fire)
        current = entry
        header.Text = tostring(title) .. ": " .. tostring(entry)
        if fire and callback then pcall(callback, entry) end
    end

    local function setOpen(open)
        listFrame.Visible = open
        if open then
            container.Size = UDim2.new(1, 0, 0, 36 + count * 28)
        else
            container.Size = UDim2.new(1, 0, 0, 30)
        end
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
        make("UICorner", {CornerRadius = UDim.new(0, 4)}, optBtn)
        optBtn.MouseButton1Click:Connect(function()
            set(entry, true)
            setOpen(false)
        end)
    end

    header.MouseButton1Click:Connect(function()
        setOpen(not listFrame.Visible)
    end)

    if default ~= nil then set(default, false) end

    return {
        Get = function() return current end,
        Set = function(_, entry) set(entry, false) end,
    }
end

Tab.AddTextbox = Tab.AddTextBox
Tab.AddToggle = Tab.AddSwitch
Tab.AddTitle = Tab.AddLabel

local Library = {
    Theme = Theme,
    Windows = {},
}

local cleanedOnce = false

function Library:AddWindow(title, options)
    if not cleanedOnce then
        cleanedOnce = true
        pcall(function()
            for _, child in ipairs(guiParent():GetChildren()) do
                if child:IsA("ScreenGui") and child.Name == "FlareonHub_UI" then
                    child:Destroy()
                end
            end
        end)
    end

    local theme = {}
    for k, v in pairs(Theme) do
        theme[k] = v
    end
    options = options or {}
    if type(options.main_color) == "Color3" then
        theme.main_color = options.main_color
    end

    local win = Window.new(title, options, theme)
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
