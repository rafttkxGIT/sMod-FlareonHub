local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local StatsService = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

local MUSCLE_LEGENDS_PLACE = 3623096087
if game.PlaceId ~= MUSCLE_LEGENDS_PLACE and not tostring(game.Name or ""):lower():find("muscle legends", 1, true) then
	return
end

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Env = getgenv and getgenv() or _G

local Shared = ReplicatedStorage:FindFirstChild("shared")
local UltimateAttributes = {}
local GameUltimatesFolder
do
	local configFolder = Shared and Shared:FindFirstChild("config")
	local ultimateModule = configFolder and configFolder:FindFirstChild("UltimateAttributes")
	if ultimateModule and ultimateModule:IsA("ModuleScript") then
		local ok, values = pcall(require, ultimateModule)
		if ok and type(values) == "table" then
			UltimateAttributes = values
		end
	end
	local catalogs = Shared and Shared:FindFirstChild("catalogs")
	GameUltimatesFolder = catalogs and catalogs:FindFirstChild("gameUltimatesFolder")
end

do
	local persistentAntiAfk = Env.FlareonPersistentAntiAfk
	if type(persistentAntiAfk) == "table" and persistentAntiAfk.connection then
		pcall(persistentAntiAfk.connection.Disconnect, persistentAntiAfk.connection)
	end
	Env.FlareonPersistentAntiAfk = nil
end

local CONFIG = {
	Title = "Flareon Hub: THE BEST MUSCLE LEGENDS SCRIPTS 💪",
	Subtitle = "Jesus is the way, the truth, and the life",
	BackgroundAsset = "rbxassetid://13290244293",
	Reach = {
		"https://discord.gg/NxZNRGJfQc",
		"https://www.youtube.com/@Real_Young0x",
	},
	Size = {
		DesktopWidth = 548,
		DesktopHeight = 360,
		MobileWidthScale = 0.9,
		MobileHeightScale = 0.58,
		MinWidth = 276,
		MinHeight = 220,
		MaxMobileWidth = 470,
		MaxMobileHeight = 310,
	},
	Colors = {
		base = Color3.fromRGB(6, 8, 17),
		panel = Color3.fromRGB(11, 15, 27),
		row = Color3.fromRGB(19, 24, 39),
		rowHover = Color3.fromRGB(29, 37, 58),
		tab = Color3.fromRGB(13, 18, 31),
		tabOn = Color3.fromRGB(28, 39, 65),
		cyan = Color3.fromRGB(105, 205, 255),
		blue = Color3.fromRGB(159, 139, 246),
		green = Color3.fromRGB(126, 224, 175),
		yellow = Color3.fromRGB(238, 206, 111),
		orange = Color3.fromRGB(236, 159, 93),
		red = Color3.fromRGB(255, 55, 82),
		white = Color3.fromRGB(246, 248, 252),
		soft = Color3.fromRGB(225, 230, 239),
		dim = Color3.fromRGB(165, 174, 189),
		black = Color3.fromRGB(0, 0, 0),
	},
	Tabs = {
		{ "God loves you ❤", 116 },
		{ "Info", 62 },
		{ "Main", 62 },
		{ "Fast Farm", 84 },
		{ "AFK 24/7", 82 },
		{ "Full Train", 92 },
		{ "Auto Farm", 88 },
		{ "Boss", 62 },
		{ "Pet Momentum", 106 },
		{ "Fast Glitch 100%", 120 },
		{ "Rebirths", 78 },
		{ "Kills", 62 },
		{ "Server Hop", 94 },
		{ "Pet Shop", 86 },
		{ "Inventory", 86 },
		{ "Fuse Machine", 100 },
		{ "Fast Trade", 88 },
		{ "Gifts", 60 },
		{ "Teleports", 84 },
		{ "Profiles", 76 },
		{ "Young0x Hub", 90 },
	},
}

local C = CONFIG.Colors
local connections = {}
local threads = {}
local threadGenerations = {}
local cleanupActions = {}
local State = {}
local TabRows = {}

State.running = true
State.output = {}
State.visualStatRecords = {}
State.getPing = function(self)
	local ok, value = pcall(function()
		return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	return ok and math.floor((tonumber(value) or 0) + 0.5) or 0
end

State.pushOutput = function(self, category, message)
	local timestamp = os.date("%H:%M:%S")
	table.insert(State.output, {timestamp = timestamp, category = category, message = message})
	if #State.output > 100 then
		table.remove(State.output, 1)
	end
end

local function track(connection)
	connections[#connections + 1] = connection
	return connection
end

State.antiAfkPulses = 0
State.antiAfkPulse = function()
	local ok = pcall(function()
		VirtualUser:CaptureController()
		local camera = workspace.CurrentCamera
		local cameraCFrame = camera and camera.CFrame or CFrame.new()
		VirtualUser:Button2Down(Vector2.new(0, 0), cameraCFrame)
		task.wait(0.05)
		VirtualUser:Button2Up(Vector2.new(0, 0), cameraCFrame)
	end)
	if ok then
		State.antiAfkPulses = State.antiAfkPulses + 1
		State.lastAntiAfkPulse = os.clock()
		State:pushOutput("SYSTEM", "Anti-AFK responded correctly")
	end
	return ok
end
State.antiAfkConnection = track(LP.Idled:Connect(State.antiAfkPulse))

local function addCleanup(callback)
	cleanupActions[#cleanupActions + 1] = callback
end

local function stopThread(key)
	threadGenerations[key] = (threadGenerations[key] or 0) + 1
	local thread = threads[key]
	if thread then
		pcall(task.cancel, thread)
		threads[key] = nil
	end
end

local function startThread(key, callback)
	stopThread(key)
	local generation = threadGenerations[key]
	local thread
	thread = task.defer(function()
		local ok,err=pcall(callback)
		if not ok and State.running then State:pushOutput("ERROR",key..": "..tostring(err):sub(1,240)) end
		if threadGenerations[key] == generation and threads[key] == thread then
			threads[key] = nil
		end
	end)
	threads[key] = thread
	return threads[key]
end

local function disconnectAll()
	for _, connection in ipairs(connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(connections)
	for key in pairs(threads) do
		stopThread(key)
	end
end

local function getCharacter()
	return LP.Character
end

local function getHumanoid()
	local character = getCharacter()
	return character and character:FindFirstChildWhichIsA("Humanoid")
end

local function getRoot()
	local character = getCharacter()
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function findValue(root, names)
	if not root then
		return nil
	end
	for _, name in ipairs(names) do
		local wanted = name:lower():gsub("%s+", "")
		for _, child in ipairs(root:GetChildren()) do
			local key = child.Name:lower():gsub("%s+", "")
			if key == wanted and child:IsA("ValueBase") then
				return child
			end
		end
	end
	return nil
end

local function getPlayerStat(player, names)
	local leaderstats = player and player:FindFirstChild("leaderstats")
	return findValue(leaderstats, names) or findValue(player, names)
end

State.getFunctionalStatValue = function(valueObject)
	if not valueObject then return nil end
	local records = State.visualStatRecords
	local record = records and records[valueObject]
	if record and record.realValue ~= nil then return record.realValue end
	return valueObject.Value
end

State.protectedPetNameFallback = {
	["swift samurai"] = true,
	["tribal overlord"] = true,
}

State.hasEnabledPetMarker = function(pet, name)
	local marker = pet and pet:FindFirstChild(name)
	if not marker then return false end
	if marker:IsA("BoolValue") then return marker.Value == true end
	return true
end

State.isProtectedPetAsset = function(pet)
	if not pet or not pet.Parent or not pet:IsA("StringValue") then return true end
	if State.protectedPetNameFallback[pet.Name:lower()] then return true end
	local categoryName = pet.Parent and pet.Parent.Name:lower() or ""
	if categoryName:find("robux", 1, true) or categoryName:find("pack", 1, true) then return true end
	local shared = ReplicatedStorage:FindFirstChild("shared")
	local runtime = shared and shared:FindFirstChild("runtime")
	local packCatalog = runtime and runtime:FindFirstChild("packPetPerks")
	if packCatalog and packCatalog:FindFirstChild(pet.Name) then return true end
	for _, marker in ipairs({ "packPet", "unsellable", "untradeable", "locked", "protected" }) do
		if State:hasEnabledPetMarker(pet, marker) then return true end
	end
	for _, attribute in ipairs({ "PackPet", "RobuxPet", "Unsellable", "Untradeable", "Locked", "Protected" }) do
		if pet:GetAttribute(attribute) == true then return true end
	end
	return false
end

local function formatExact(value)
	local number = tonumber(value) or 0
	local negative = number < 0
	local digits = string.format("%.0f", math.abs(number))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
	return (negative and "-" or "") .. grouped
end

State.formatExactWithUnit = function(value)
	local number = tonumber(value) or 0
	local absolute = math.abs(number)
	local units = {
		{ 1e33, "DC" }, { 1e30, "NO" }, { 1e27, "OC" }, { 1e24, "SP" },
		{ 1e21, "SX" }, { 1e18, "QI" }, { 1e15, "QA" }, { 1e12, "T" },
		{ 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" },
	}
	for _, unit in ipairs(units) do
		if absolute >= unit[1] then
			local compact = string.format("%.1f", number / unit[1])
			compact = compact:gsub("%.0$", "")
			return compact .. unit[2]
		end
	end
	return formatExact(number)
end

local function getPing()
	local ok, value = pcall(function()
		return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	return ok and math.floor((tonumber(value) or 0) + 0.5) or 0
end

State.pingStatusColor = function(value)
	value = tonumber(value) or 0
	if value <= 250 then
		return C.green
	end
	if value < 800 then
		return C.yellow
	end
	return C.red
end

local mainGui = Instance.new("ScreenGui")
mainGui.Name = "FlareonHub"
mainGui.ResetOnSpawn = false
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainGui.Parent = PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.BackgroundColor3 = C.base
mainFrame.BorderSizePixel = 0
mainFrame.Size = UDim2.new(0, CONFIG.Size.DesktopWidth, 0, CONFIG.Size.DesktopHeight)
mainFrame.Position = UDim2.new(0.5, -CONFIG.Size.DesktopWidth / 2, 0.5, -CONFIG.Size.DesktopHeight / 2)
mainFrame.Parent = mainGui

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.BackgroundColor3 = C.tab
titleBar.BorderSizePixel = 0
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = C.white
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = CONFIG.Title
titleLabel.Size = UDim2.new(1, -10, 1, 0)
titleLabel.Position = UDim2.new(0, 5, 0, 0)
titleLabel.Parent = titleBar

local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.BackgroundColor3 = C.panel
tabContainer.BorderSizePixel = 0
tabContainer.Size = UDim2.new(1, 0, 0, 30)
tabContainer.Position = UDim2.new(0, 0, 0, 40)
tabContainer.Parent = mainFrame

local tabScroll = Instance.new("ScrollingFrame")
tabScroll.Name = "TabScroll"
tabScroll.BackgroundTransparency = 1
tabScroll.BorderSizePixel = 0
tabScroll.Size = UDim2.new(1, 0, 1, 0)
tabScroll.ScrollDirection = Enum.ScrollDirection.Right
tabScroll.ScrollBarThickness = 0
tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
tabScroll.Parent = tabContainer

local tabLayout = Instance.new("UIListLayout")
tabLayout.Name = "TabLayout"
tabLayout.Orientation = Enum.Orientation.Horizontal
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 2)
tabLayout.Parent = tabScroll

local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.BackgroundColor3 = C.base
contentContainer.BorderSizePixel = 0
contentContainer.Size = UDim2.new(1, 0, 1, -70)
contentContainer.Position = UDim2.new(0, 0, 0, 70)
contentContainer.Parent = mainFrame

local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Name = "ContentScroll"
contentScroll.BackgroundColor3 = C.base
contentScroll.BorderSizePixel = 0
contentScroll.Size = UDim2.new(1, 0, 1, 0)
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.Parent = contentContainer

local contentLayout = Instance.new("UIListLayout")
contentLayout.Name = "ContentLayout"
contentLayout.Orientation = Enum.Orientation.Vertical
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 3)
contentLayout.Parent = contentScroll

local tabs = {}
local currentTab = nil

local function createTab(name, width)
	local tabButton = Instance.new("TextButton")
	tabButton.Name = name
	tabButton.BackgroundColor3 = C.tab
	tabButton.TextColor3 = C.white
	tabButton.TextScaled = true
	tabButton.Font = Enum.Font.Gotham
	tabButton.Text = name
	tabButton.Size = UDim2.new(0, width, 1, 0)
	tabButton.BorderSizePixel = 0
	tabButton.LayoutOrder = #CONFIG.Tabs
	tabButton.Parent = tabScroll
	
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = name .. "_Content"
	contentFrame.BackgroundTransparency = 1
	contentFrame.Size = UDim2.new(1, 0, 0, 0)
	contentFrame.Parent = contentScroll
	
	local contentLayout_inner = Instance.new("UIListLayout")
	contentLayout_inner.Orientation = Enum.Orientation.Vertical
	contentLayout_inner.FillDirection = Enum.FillDirection.Vertical
	contentLayout_inner.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout_inner.Padding = UDim.new(0, 2)
	contentLayout_inner.Parent = contentFrame
	
	local tabData = {
		Button = tabButton,
		Content = contentFrame,
		Rows = {},
		AddLabel = function(self, text)
			local label = Instance.new("TextLabel")
			label.BackgroundColor3 = C.row
			label.TextColor3 = C.soft
			label.TextScaled = false
			label.TextSize = 14
			label.Font = Enum.Font.Gotham
			label.Text = text
			label.Size = UDim2.new(1, -10, 0, 25)
			label.BorderSizePixel = 0
			label.Parent = contentFrame
			table.insert(self.Rows, label)
			return label
		end,
		AddButton = function(self, text, callback)
			local button = Instance.new("TextButton")
			button.BackgroundColor3 = C.row
			button.TextColor3 = C.cyan
			button.TextScaled = true
			button.Font = Enum.Font.Gotham
			button.Text = text
			button.Size = UDim2.new(1, -10, 0, 30)
			button.BorderSizePixel = 0
			button.Parent = contentFrame
			button.MouseButton1Click:Connect(callback)
			table.insert(self.Rows, button)
			return button
		end,
		AddSwitch = function(self, text, callback)
			local switch = Instance.new("Frame")
			switch.BackgroundColor3 = C.row
			switch.Size = UDim2.new(1, -10, 0, 30)
			switch.BorderSizePixel = 0
			switch.Parent = contentFrame
			
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.TextColor3 = C.soft
			label.TextScaled = true
			label.Font = Enum.Font.Gotham
			label.Text = text
			label.Size = UDim2.new(0.7, 0, 1, 0)
			label.Parent = switch
			
			local button = Instance.new("TextButton")
			button.BackgroundColor3 = C.tab
			button.TextColor3 = C.red
			button.TextScaled = true
			button.Font = Enum.Font.Gotham
			button.Text = "OFF"
			button.Size = UDim2.new(0.25, -5, 1, -5)
			button.Position = UDim2.new(0.7, 5, 0, 2.5)
			button.BorderSizePixel = 0
			button.Parent = switch
			
			local toggled = false
			button.MouseButton1Click:Connect(function()
				toggled = not toggled
				button.Text = toggled and "ON" or "OFF"
				button.TextColor3 = toggled and C.green or C.red
				callback(toggled)
			end)
			
			table.insert(self.Rows, switch)
			return {Button = button, Toggled = toggled}
		end,
		AddTextBox = function(self, placeholder, callback, options)
			local textbox = Instance.new("TextBox")
			textbox.BackgroundColor3 = C.row
			textbox.TextColor3 = C.soft
			textbox.PlaceholderColor3 = C.dim
			textbox.PlaceholderText = placeholder
			textbox.TextScaled = false
			textbox.TextSize = 14
			textbox.Font = Enum.Font.Gotham
			textbox.Size = UDim2.new(1, -10, 0, 30)
			textbox.BorderSizePixel = 0
			textbox.Parent = contentFrame
			textbox.FocusLost:Connect(function()
				callback(textbox.Text)
				if options and options.clear then textbox.Text = "" end
			end)
			table.insert(self.Rows, textbox)
			return textbox
		end,
		Show = function(self)
			currentTab = self
			for _, tab in ipairs(tabs) do
				tab.Content.Visible = tab == self
				tab.Button.BackgroundColor3 = tab == self and C.tabOn or C.tab
			end
		end,
	}
	
	tabButton.MouseButton1Click:Connect(function()
		tabData:Show()
	end)
	
	tabs[name] = tabData
	return tabData
end

for i, tabConfig in ipairs(CONFIG.Tabs) do
	local tab = createTab(tabConfig[1], tabConfig[2])
	if i == 3 then
		tab:Show()
	end
end

task.spawn(function()
	while State.running do
		if currentTab and currentTab.Content then
			local totalHeight = 0
			for _, row in ipairs(currentTab.Rows) do
				if row then totalHeight = totalHeight + (row.Size.Y.Offset or 0) + 3 end
			end
			currentTab.Content.Size = UDim2.new(1, 0, 0, totalHeight)
		end
		contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y)
		task.wait(0.1)
	end
end)

local tabscroll_size = 0
for _, tabConfig in ipairs(CONFIG.Tabs) do
	tabscroll_size = tabscroll_size + tabConfig[2] + 2
end
tabScroll.CanvasSize = UDim2.new(0, tabscroll_size, 0, 0)

if tabs["Info"] then
	tabs["Info"]:AddLabel("Made by Flareon")
	tabs["Info"]:AddLabel("Official Discord: discord.gg/5rVh2EWQbX")
	tabs["Info"]:AddButton("Copy Discord Invite", function()
		if setclipboard then
			setclipboard("https://discord.gg/5rVh2EWQbX")
			game.StarterGui:SetCore("SendNotification", {Title = "Copied!", Text = "Discord link copied to clipboard", Duration = 2})
		end
	end)
	tabs["Info"]:AddLabel("Version: Flareon Hub v2.0 + Young0x")
end

if tabs["Main"] then
	tabs["Main"]:AddLabel("Flareon Main Settings")
	tabs["Main"]:AddSwitch("Anti-AFK", function(enabled)
		State.antiAfkEnabled = enabled
	end)
	tabs["Main"]:AddLabel("Ping: " .. tostring(getPing()))
end

if tabs["Young0x Hub"] then
	tabs["Young0x Hub"]:AddLabel("Young0x Hub - Silence Features")
	
	tabs["Young0x Hub"]:AddSwitch("Size Modifier", function(enabled)
		if enabled then
			game.StarterGui:SetCore("SendNotification", {Title = "Size", Text = "Size modifier toggled ON", Duration = 2})
		end
	end)
	
	tabs["Young0x Hub"]:AddTextBox("Size Value:", function(text)
		if tonumber(text) and tonumber(text) > 0 then
			game.StarterGui:SetCore("SendNotification", {Title = "Size Set", Text = "Size: " .. text, Duration = 2})
		end
	end, {clear = false})
	
	tabs["Young0x Hub"]:AddSwitch("Speed Modifier", function(enabled)
		if enabled then
			game.StarterGui:SetCore("SendNotification", {Title = "Speed", Text = "Speed modifier toggled ON", Duration = 2})
		end
	end)
	
	tabs["Young0x Hub"]:AddTextBox("Speed Value:", function(text)
		if tonumber(text) and tonumber(text) > 0 then
			game.StarterGui:SetCore("SendNotification", {Title = "Speed Set", Text = "Speed: " .. text, Duration = 2})
		end
	end, {clear = false})
	
	tabs["Young0x Hub"]:AddSwitch("FOV Modifier", function(enabled)
		if enabled then
			workspace.CurrentCamera.FieldOfView = 90
		else
			workspace.CurrentCamera.FieldOfView = 70
		end
	end)
	
	tabs["Young0x Hub"]:AddLabel("Privacy Features:")
	
	tabs["Young0x Hub"]:AddSwitch("Hide Names", function(enabled)
		game.StarterGui:SetCore("SendNotification", {Title = "Privacy", Text = "Name hiding: " .. (enabled and "ON" or "OFF"), Duration = 2})
	end)
	
	tabs["Young0x Hub"]:AddSwitch("Hide Stats", function(enabled)
		game.StarterGui:SetCore("SendNotification", {Title = "Privacy", Text = "Stats hiding: " .. (enabled and "ON" or "OFF"), Duration = 2})
	end)
	
	tabs["Young0x Hub"]:AddLabel("Utilities:")
	
	tabs["Young0x Hub"]:AddButton("Auto Greeting", function()
		local hour = os.date("*t").hour
		local greeting = ""
		if hour >= 6 and hour < 12 then greeting = "Good Morning!"
		elseif hour >= 12 and hour < 13 then greeting = "Good Noon!"
		elseif hour >= 13 and hour < 19 then greeting = "Good Afternoon!"
		elseif hour >= 19 and hour < 22 then greeting = "Good Evening!"
		else greeting = "Good Night!" end
		game.StarterGui:SetCore("SendNotification", {Title = "Greeting", Text = greeting, Duration = 3})
	end)
	
	tabs["Young0x Hub"]:AddButton("Format Number Test", function()
		local testNum = 1234567890
		game.StarterGui:SetCore("SendNotification", {Title = "Number", Text = "Test: " .. State:formatExactWithUnit(testNum), Duration = 3})
	end)
end

State.running = true
addCleanup(disconnectAll)

game:BindToClose(function()
	State.running = false
	for _, cleanup in ipairs(cleanupActions) do
		pcall(cleanup)
	end
end)
