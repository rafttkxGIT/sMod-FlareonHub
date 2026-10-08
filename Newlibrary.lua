--[[
	Crystalline UI v3 — Solara Edition
	Standalone UI library. No external loads. No HTTP.
	Pure Lua, exploit-environment safe.
	
	Drop this in directly. Works in Solara, Arceus, etc.
	Zero dependencies beyond Roblox services.
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================================
-- SIGNAL SYSTEM
-- ============================================================================

local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({}, Signal)
	self._bindings = {}
	self._firing = false
	return self
end

function Signal:Connect(callback)
	assert(type(callback) == "function", "Callback must be function")
	local connection = {
		Connected = true,
		_callback = callback,
		_signal = self,
	}
	
	function connection:Disconnect()
		if self.Connected then
			self.Connected = false
			self._signal._bindings[self] = nil
		end
	end
	
	self._bindings[connection] = true
	return connection
end

function Signal:Fire(...)
	if self._firing then return end
	self._firing = true
	
	for connection in pairs(self._bindings) do
		if connection.Connected then
			task.spawn(connection._callback, ...)
		end
	end
	
	self._firing = false
end

function Signal:Wait()
	local thread = coroutine.running()
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.resume(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:Destroy()
	for connection in pairs(self._bindings) do
		connection:Disconnect()
	end
	self._bindings = nil
end

-- ============================================================================
-- STATE SYSTEM
-- ============================================================================

local State = {}
State.__index = State

function State.new(initialValue)
	local self = setmetatable({}, State)
	self._value = initialValue
	self._changed = Signal.new()
	return self
end

function State:Get()
	return self._value
end

function State:Set(newValue)
	if self._value == newValue then return end
	local oldValue = self._value
	self._value = newValue
	self._changed:Fire(newValue, oldValue)
end

function State:OnChanged(callback)
	return self._changed:Connect(callback)
end

function State:Watch(callback)
	callback(self._value)
	return self:OnChanged(callback)
end

function State:Destroy()
	self._changed:Destroy()
	self._changed = nil
end

-- ============================================================================
-- THEME SYSTEM
-- ============================================================================

local Theme = {}
Theme.__index = Theme

Theme.Default = {
	primary = Color3.fromRGB(41, 74, 122),
	secondary = Color3.fromRGB(52, 53, 56),
	background = Color3.fromRGB(21, 22, 23),
	surface = Color3.fromRGB(35, 35, 40),
	text = Color3.fromRGB(200, 200, 200),
	accent = Color3.fromRGB(76, 175, 80),
	error = Color3.fromRGB(244, 67, 54),
	
	cornerRadius = 4,
	padding = 5,
	fontSize = 14,
	transitionSpeed = 0.15,
}

function Theme.new(overrides)
	local self = setmetatable({}, Theme)
	self.colors = {}
	
	for k, v in pairs(Theme.Default) do
		self.colors[k] = v
	end
	
	if overrides then
		for k, v in pairs(overrides) do
			self.colors[k] = v
		end
	end
	
	return self
end

function Theme:GetColor(colorName)
	return self.colors[colorName] or Color3.new(1, 1, 1)
end

-- ============================================================================
-- ANIMATION QUEUE
-- ============================================================================

local AnimationQueue = {}
AnimationQueue.__index = AnimationQueue

function AnimationQueue.new(instance)
	local self = setmetatable({}, AnimationQueue)
	self._instance = instance
	self._queue = {}
	self._playing = false
	return self
end

function AnimationQueue:Tween(props, duration, easing, direction)
	easing = easing or Enum.EasingStyle.Quad
	direction = direction or Enum.EasingDirection.Out
	
	table.insert(self._queue, {
		props = props,
		duration = duration,
		easing = easing,
		direction = direction,
	})
	
	if not self._playing then
		self:_Process()
	end
end

function AnimationQueue:_Process()
	if #self._queue == 0 then
		self._playing = false
		return
	end
	
	self._playing = true
	local anim = table.remove(self._queue, 1)
	
	local tweenInfo = TweenInfo.new(
		anim.duration,
		anim.easing,
		anim.direction
	)
	
	local tween = TweenService:Create(self._instance, tweenInfo, anim.props)
	tween.Completed:Connect(function()
		tween:Destroy()
		self:_Process()
	end)
	
	tween:Play()
end

function AnimationQueue:Destroy()
	self._queue = nil
end

-- ============================================================================
-- COMPONENT BASE
-- ============================================================================

local Component = {}
Component.__index = Component

function Component.new(name, parent, theme)
	local self = setmetatable({}, Component)
	
	self.Name = name
	self.Parent = parent or game.CoreGui
	self.Theme = theme or Theme.new()
	self.Visible = State.new(true)
	self.Enabled = State.new(true)
	
	self._instance = nil
	self._destroyed = false
	self._signals = {}
	
	return self
end

function Component:Create(className, name, props)
	local inst = Instance.new(className)
	inst.Name = name or className
	
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				pcall(function() inst[k] = v end)
			end
		end
	end
	
	return inst
end

function Component:Show()
	if self._instance then
		self._instance.Visible = true
	end
	self.Visible:Set(true)
end

function Component:Hide()
	if self._instance then
		self._instance.Visible = false
	end
	self.Visible:Set(false)
end

function Component:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	
	for signal in pairs(self._signals) do
		pcall(function() signal:Destroy() end)
	end
	
	if self._instance then
		self._instance:Destroy()
	end
	
	self.Visible:Destroy()
	self.Enabled:Destroy()
end

-- ============================================================================
-- WINDOW COMPONENT
-- ============================================================================

local Window = setmetatable({}, Component)
Window.__index = Window

function Window.new(title, options, theme)
	local self = Component.new("Window", game.CoreGui, theme)
	setmetatable(self, Window)
	
	self.Title = State.new(title or "Window")
	self.Position = State.new(UDim2.new(0, 20, 0, 20))
	self.Size = State.new(UDim2.new(0, 400, 0, 300))
	self.Draggable = State.new(true)
	
	self.Tabs = {}
	self.CurrentTab = nil
	
	self:SetUp()
	return self
end

function Window:SetUp()
	local gui = self:Create("ScreenGui", "WindowGui", {
		ResetOnSpawn = false,
	})
	gui.Parent = self.Parent
	
	local window = self:Create("ImageLabel", "Window", {
		BackgroundTransparency = 1,
		Image = "rbxassetid://2851926732",
		ImageColor3 = self.Theme:GetColor("background"),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(12, 12, 12, 12),
		Active = true,
		Draggable = true,
		ClipsDescendants = true,
	})
	window.Parent = gui
	self._instance = window
	
	self:_BuildHeader()
	self:_BuildContent()
end

function Window:_BuildHeader()
	local header = self:Create("ImageLabel", "Header", {
		BackgroundColor3 = self.Theme:GetColor("primary"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 25),
		Image = "rbxassetid://2851926732",
		ImageColor3 = self.Theme:GetColor("primary"),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(12, 12, 12, 12),
		ZIndex = 2,
	})
	header.Parent = self._instance
	
	local title = self:Create("TextLabel", "Title", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Font = Enum.Font.GothamBold,
		TextColor3 = self.Theme:GetColor("text"),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	})
	title.Parent = header
	title.Text = self.Title:Get()
	
	self.Title:OnChanged(function(newTitle)
		title.Text = newTitle
	end)
	
	local closeBtn = self:Create("TextButton", "Close", {
		BackgroundColor3 = self.Theme:GetColor("error"),
		Position = UDim2.new(1, -25, 0, 2),
		Size = UDim2.new(0, 21, 0, 21),
		Font = Enum.Font.GothamBold,
		Text = "×",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 18,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	closeBtn.Parent = header
	closeBtn.MouseButton1Click:Connect(function()
		self:Hide()
	end)
end

function Window:_BuildContent()
	local content = self:Create("Frame", "Content", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 30),
		Size = UDim2.new(1, 0, 1, -30),
		ClipsDescendants = true,
		ZIndex = 1,
	})
	content.Parent = self._instance
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, self.Theme.colors.padding)
	layout.Parent = content
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, self.Theme.colors.padding)
	padding.PaddingRight = UDim.new(0, self.Theme.colors.padding)
	padding.PaddingTop = UDim.new(0, self.Theme.colors.padding)
	padding.Parent = content
	
	self._content = content
end

function Window:AddTab(tabName)
	local tab = Tab.new(tabName, self._content, self.Theme)
	table.insert(self.Tabs, tab)
	
	if not self.CurrentTab then
		self.CurrentTab = tab
		tab:Show()
	end
	
	return tab
end

function Window:SetTitle(newTitle)
	self.Title:Set(newTitle)
end

-- ============================================================================
-- TAB COMPONENT
-- ============================================================================

local Tab = setmetatable({}, Component)
Tab.__index = Tab

function Tab.new(name, parent, theme)
	local self = Component.new("Tab", parent, theme)
	setmetatable(self, Tab)
	
	self.Name = name
	self.Visible = State.new(false)
	
	self:SetUp()
	return self
end

function Tab:SetUp()
	local frame = self:Create("Frame", self.Name, {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		ClipsDescendants = true,
	})
	frame.Parent = self.Parent
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.Parent = frame
	
	local scrolling = Instance.new("ScrollingFrame")
	scrolling.BackgroundTransparency = 1
	scrolling.ScrollBarThickness = 8
	scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrolling.Size = UDim2.new(1, 0, 1, 0)
	scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrolling.Parent = frame
	
	local innerLayout = Instance.new("UIListLayout")
	innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	innerLayout.Padding = UDim.new(0, 5)
	innerLayout.Parent = scrolling
	
	self._instance = frame
	self._content = scrolling
	
	self.Visible:Watch(function(visible)
		self._instance.Visible = visible
	end)
end

function Tab:Show()
	self.Visible:Set(true)
end

function Tab:Hide()
	self.Visible:Set(false)
end

function Tab:AddLabel(text)
	local label = self:Create("TextLabel", "Label", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Font = Enum.Font.GothamSemibold,
		Text = text,
		TextColor3 = self.Theme:GetColor("text"),
		TextSize = self.Theme.colors.fontSize,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
	})
	label.Parent = self._content
	return label
end

function Tab:AddButton(label, callback)
	local button = self:Create("TextButton", "Button", {
		BackgroundColor3 = self.Theme:GetColor("primary"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
		Font = Enum.Font.GothamSemibold,
		Text = label,
		TextColor3 = self.Theme:GetColor("text"),
		TextSize = self.Theme.colors.fontSize,
	})
	button.Parent = self._content
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, self.Theme.colors.cornerRadius)
	corner.Parent = button
	
	button.MouseButton1Click:Connect(function()
		if callback then pcall(callback) end
	end)
	
	return button
end

function Tab:AddSwitch(label, callback, default)
	local state = State.new(default or false)
	
	local container = self:Create("Frame", "Toggle", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 25),
	})
	container.Parent = self._content
	
	local labelObj = self:Create("TextLabel", "Label", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -35, 1, 0),
		Font = Enum.Font.GothamSemibold,
		Text = label,
		TextColor3 = self.Theme:GetColor("text"),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	labelObj.Parent = container
	
	local toggle = self:Create("TextButton", "Switch", {
		BackgroundColor3 = self.Theme:GetColor("secondary"),
		Position = UDim2.new(1, -30, 0.5, -12),
		Size = UDim2.new(0, 24, 0, 24),
		Text = "",
		BorderSizePixel = 0,
	})
	toggle.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = toggle
	
	local function update(value)
		state:Set(value)
		toggle.BackgroundColor3 = value and self.Theme:GetColor("accent") or self.Theme:GetColor("secondary")
		if callback then pcall(callback, value) end
	end
	
	toggle.MouseButton1Click:Connect(function()
		update(not state:Get())
	end)
	
	if default then
		update(default)
	end
	
	return {
		Get = function() return state:Get() end,
		Set = function(v) update(v) end,
		_state = state,
	}
end

function Tab:AddTextBox(placeholder, callback)
	local container = self:Create("Frame", "TextInput", {
		BackgroundColor3 = self.Theme:GetColor("secondary"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
	})
	container.Parent = self._content
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, self.Theme.colors.cornerRadius)
	corner.Parent = container
	
	local textBox = self:Create("TextBox", "Input", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 5),
		Size = UDim2.new(1, -20, 0, 20),
		PlaceholderText = placeholder,
		Font = Enum.Font.GothamSemibold,
		TextColor3 = self.Theme:GetColor("text"),
		PlaceholderColor3 = self.Theme:GetColor("text"),
		TextSize = 14,
	})
	textBox.Parent = container
	
	textBox.FocusLost:Connect(function(ep)
		if ep and callback then
			pcall(callback, textBox.Text)
		end
	end)
	
	return {
		Get = function() return textBox.Text end,
		Set = function(v) textBox.Text = v end,
	}
end

function Tab:AddSlider(label, callback, min, max, default)
	default = default or min
	local state = State.new(default)
	
	local container = self:Create("Frame", "Slider", {
		BackgroundColor3 = self.Theme:GetColor("secondary"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 50),
	})
	container.Parent = self._content
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, self.Theme.colors.cornerRadius)
	corner.Parent = container
	
	local labelObj = self:Create("TextLabel", "Label", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 2),
		Size = UDim2.new(1, -60, 0, 20),
		Font = Enum.Font.GothamSemibold,
		Text = label,
		TextColor3 = self.Theme:GetColor("text"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 12,
	})
	labelObj.Parent = container
	
	local valueLabel = self:Create("TextLabel", "Value", {
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -45, 0, 2),
		Size = UDim2.new(0, 40, 0, 20),
		Font = Enum.Font.GothamSemibold,
		Text = tostring(default),
		TextColor3 = self.Theme:GetColor("accent"),
		TextSize = 12,
	})
	valueLabel.Parent = container
	
	local bar = self:Create("Frame", "Bar", {
		BackgroundColor3 = self.Theme:GetColor("primary"),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 0, 28),
		Size = UDim2.new(1, -20, 0, 4),
	})
	bar.Parent = container
	
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0.5, 0)
	barCorner.Parent = bar
	
	local drag = false
	
	local function updateValue(x)
		local barPos = bar.AbsolutePosition.X
		local barSize = bar.AbsoluteSize.X
		local relX = math.max(0, math.min(x - barPos, barSize))
		local percent = relX / barSize
		local value = math.floor(min + (max - min) * percent)
		
		state:Set(value)
		valueLabel.Text = tostring(value)
		if callback then pcall(callback, value) end
	end
	
	UserInputService.InputBegan:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			drag = true
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			drag = false
		end
	end)
	
	RunService.Heartbeat:Connect(function()
		if drag then
			updateValue(Mouse.X)
		end
	end)
	
	return {
		Get = function() return state:Get() end,
		Set = function(v) 
			updateValue(bar.AbsolutePosition.X + (bar.AbsoluteSize.X * ((math.clamp(v, min, max) - min) / (max - min))))
		end,
	}
end

-- ============================================================================
-- LIBRARY EXPORT
-- ============================================================================

local Library = {
	Window = Window,
	Tab = Tab,
	Theme = Theme,
	Signal = Signal,
	State = State,
}

function Library:CreateWindow(title, options)
	options = options or {}
	
	local theme = Theme.new({
		primary = options.main_color or Color3.fromRGB(41, 74, 122),
	})
	
	local window = Window.new(title, options, theme)
	
	if options.min_size then
		window.Size:Set(UDim2.new(0, options.min_size.X, 0, options.min_size.Y))
	end
	
	if options.can_resize ~= false then
		-- Add resize capability if needed
	end
	
	return window
end

function Library:AddWindow(title, options)
	return self:CreateWindow(title, options)
end

return Library
