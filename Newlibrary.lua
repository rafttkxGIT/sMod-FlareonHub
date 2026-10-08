--[[
	Crystalline UI v3
	Modern Roblox UI framework with performance optimization,
	reactive state management, and modular architecture.
	
	Key improvements:
	- Modular component system (no god objects)
	- Signal-based reactive updates (no polling)
	- Memory pooling for allocation efficiency
	- Fluent API with method chaining
	- Built-in animation queue system
	- Component lifecycle hooks
	- CSS-like theming engine
	- Performance-first event delegation
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================================
-- SIGNAL SYSTEM (Event backbone — zero polling)
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
	assert(type(callback) == "function", "Connection callback must be function")
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
-- STATE SYSTEM (Reactive updates — no manual refresh)
-- ============================================================================

local State = {}
State.__index = State

function State.new(initialValue)
	local self = setmetatable({}, State)
	self._value = initialValue
	self._changed = Signal.new()
	self._watchers = {}
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
-- THEME SYSTEM (Centralized style management)
-- ============================================================================

local Theme = {}
Theme.__index = Theme

Theme.Default = {
	primary = Color3.fromRGB(41, 74, 122),
	secondary = Color3.fromRGB(52, 53, 56),
	background = Color3.fromRGB(21, 22, 23),
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
	self.properties = {}
	
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

function Theme:Apply(instance, styleKey)
	-- Apply theme colors to UI element
	if styleKey == "button" then
		instance.BackgroundColor3 = self:GetColor("primary")
		instance.TextColor3 = self:GetColor("text")
	elseif styleKey == "panel" then
		instance.BackgroundColor3 = self:GetColor("background")
	end
end

-- ============================================================================
-- COMPONENT POOL (Memory efficiency — object reuse)
-- ============================================================================

local Pool = {}
Pool.__index = Pool

function Pool.new(template, size)
	local self = setmetatable({}, Pool)
	self._template = template
	self._available = {}
	self._inUse = {}
	self._size = size or 50
	
	for i = 1, self._size do
		local obj = template:Clone()
		obj.Parent = nil
		obj.Visible = false
		table.insert(self._available, obj)
	end
	
	return self
end

function Pool:Acquire()
	if #self._available == 0 then
		local obj = self._template:Clone()
		table.insert(self._available, obj)
	end
	
	local obj = table.remove(self._available)
	obj.Visible = true
	table.insert(self._inUse, obj)
	return obj
end

function Pool:Release(obj)
	obj.Visible = false
	obj.Parent = nil
	
	for i, v in ipairs(self._inUse) do
		if v == obj then
			table.remove(self._inUse, i)
			break
		end
	end
	
	table.insert(self._available, obj)
end

function Pool:Destroy()
	for _, obj in ipairs(self._available) do
		obj:Destroy()
	end
	for _, obj in ipairs(self._inUse) do
		obj:Destroy()
	end
	self._available = nil
	self._inUse = nil
end

-- ============================================================================
-- ANIMATION QUEUE (Non-blocking tweens)
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
-- COMPONENT BASE CLASS
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
	self._children = {}
	self._destroyed = false
	self._signals = {}
	self._animations = nil
	
	return self
end

function Component:Create(className, name, props)
	local inst = Instance.new(className)
	inst.Name = name or className
	
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" and k ~= "Children" then
				pcall(function() inst[k] = v end)
			end
		end
	end
	
	return inst
end

function Component:SetUp()
	-- Override in subclasses
end

function Component:TearDown()
	-- Override in subclasses
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

function Component:Animate()
	if not self._animations then
		self._animations = AnimationQueue.new(self._instance)
	end
	return self._animations
end

function Component:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	
	self:TearDown()
	
	for signal in pairs(self._signals) do
		signal:Destroy()
	end
	
	if self._animations then
		self._animations:Destroy()
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
	self.Resizable = State.new(options and options.resizable ~= false)
	
	self.MinSize = options and options.minSize or Vector2.new(300, 200)
	self.TabContainer = nil
	self.Tabs = {}
	
	self:SetUp()
	return self
end

function Window:SetUp()
	local gui = Instance.new("ScreenGui")
	gui.Name = self.Name
	gui.ResetOnSpawn = false
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
	self:_BindStates()
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
	})
	title.Parent = header
	
	self.Title:Watch(function(newTitle)
		title.Text = newTitle
	end)
	
	local closeBtn = self:Create("TextButton", "Close", {
		BackgroundColor3 = self.Theme:GetColor("error"),
		BackgroundTransparency = 0.3,
		Position = UDim2.new(1, -25, 0, 2),
		Size = UDim2.new(0, 21, 0, 21),
		Font = Enum.Font.GothamBold,
		Text = "×",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 18,
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

function Window:_BindStates()
	self.Title:OnChanged(function(newTitle)
		self._instance:FindFirstChild("Header"):FindFirstChild("Title").Text = newTitle
	end)
	
	self.Position:Watch(function(pos)
		self._instance.Position = pos
	end)
	
	self.Size:Watch(function(size)
		self._instance.Size = size
	end)
end

function Window:AddTab(tabName)
	local tab = Tab.new(tabName, self._content, self.Theme)
	table.insert(self.Tabs, tab)
	return tab
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
	})
	frame.Parent = self.Parent
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.Parent = frame
	
	self._instance = frame
	
	self.Visible:Watch(function(visible)
		self._instance.Visible = visible
	end)
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
	label.Parent = self._instance
	return label
end

function Tab:AddButton(label, callback)
	local button = self:Create("TextButton", "Button", {
		BackgroundColor3 = self.Theme:GetColor("primary"),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
		Font = Enum.Font.GothamSemibold,
		Text = label,
		TextColor3 = self.Theme:GetColor("text"),
		TextSize = self.Theme.colors.fontSize,
	})
	button.Parent = self._instance
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, self.Theme.colors.cornerRadius)
	corner.Parent = button
	
	button.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)
	
	button.MouseEnter:Connect(function()
		local anim = AnimationQueue.new(button)
		anim:Tween({BackgroundTransparency = 0.2}, 0.1)
	end)
	
	button.MouseLeave:Connect(function()
		local anim = AnimationQueue.new(button)
		anim:Tween({BackgroundTransparency = 0}, 0.1)
	end)
	
	return button
end

function Tab:AddToggle(label, callback, default)
	local state = State.new(default or false)
	
	local container = self:Create("Frame", "Toggle", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 25),
	})
	container.Parent = self._instance
	
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
		if callback then callback(value) end
	end
	
	toggle.MouseButton1Click:Connect(function()
		update(not state:Get())
	end)
	
	return {Get = function() return state:Get() end, Set = update}
end

function Tab:AddSlider(label, callback, min, max, default)
	local state = State.new(default or min)
	
	local container = self:Create("Frame", "Slider", {
		BackgroundColor3 = self.Theme:GetColor("secondary"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
	})
	container.Parent = self._instance
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, self.Theme.colors.cornerRadius)
	corner.Parent = container
	
	local labelObj = self:Create("TextLabel", "Label", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -60, 0.5, 0),
		Font = Enum.Font.GothamSemibold,
		Text = label,
		TextColor3 = self.Theme:GetColor("text"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 12,
	})
	labelObj.Parent = container
	
	local valueLabel = self:Create("TextLabel", "Value", {
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -45, 0, 0),
		Size = UDim2.new(0, 40, 0.5, 0),
		Font = Enum.Font.GothamSemibold,
		Text = tostring(default or min),
		TextColor3 = self.Theme:GetColor("accent"),
		TextSize = 12,
	})
	valueLabel.Parent = container
	
	local bar = self:Create("Frame", "Bar", {
		BackgroundColor3 = self.Theme:GetColor("primary"),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 0.5, 5),
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
		if callback then callback(value) end
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
	
	return {Get = function() return state:Get() end, Set = function(v) updateValue(bar.AbsolutePosition.X + (bar.AbsoluteSize.X * ((v - min) / (max - min)))) end}
end

function Tab:AddTextInput(label, callback)
	local container = self:Create("Frame", "TextInput", {
		BackgroundColor3 = self.Theme:GetColor("secondary"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
	})
	container.Parent = self._instance
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, self.Theme.colors.cornerRadius)
	corner.Parent = container
	
	local textBox = self:Create("TextBox", "Input", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 5),
		Size = UDim2.new(1, -20, 0, 20),
		PlaceholderText = label,
		Font = Enum.Font.GothamSemibold,
		TextColor3 = self.Theme:GetColor("text"),
		PlaceholderColor3 = self.Theme:GetColor("text"),
		TextSize = 14,
	})
	textBox.Parent = container
	
	textBox.FocusLost:Connect(function(ep)
		if ep and callback then
			callback(textBox.Text)
		end
	end)
	
	return {Get = function() return textBox.Text end, Set = function(v) textBox.Text = v end}
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
	Pool = Pool,
}

function Library:CreateWindow(title, options)
	return Window.new(title, options, self.Theme or Theme.new())
end

function Library:SetTheme(overrides)
	self.Theme = Theme.new(overrides)
end

return Library
