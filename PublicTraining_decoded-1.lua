local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Environment = type(getgenv) == "function" and getgenv() or _G
local AUTO_BOSS_BUILD = "autoboss-2026.10.11-halloween-theme"

local TargetOptions = {
	{ id = "Beach", label = "Boss de playa" },
	{ id = "GrimReaper", label = "Grim Reaper" },
	{ id = "FrankenBrute", label = "Frankenbrute" },
	{ id = "ScarecrowColossus", label = "Scarecrow Colossus" },
	{ id = "PumpkinTitan", label = "Pumpkin Titan" },
}
local TargetOptionById = {}
for index, option in ipairs(TargetOptions) do
	TargetOptionById[option.id] = option
	option.index = index
end
local initialTargetMode = TargetOptionById[Environment.Young0xAutoBossTargetMode]
	and Environment.Young0xAutoBossTargetMode or "Beach"
local initialHalloweenTarget = initialTargetMode ~= "Beach" and initialTargetMode or "GrimReaper"
local BEACH_HEIGHT = 388
local HALLOWEEN_EXTRA_HEIGHT = 50
local COPY_EXTRA_HEIGHT = 22

local DiscordIconData = "iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAACXBIWXMAAAsTAAALEwEAmpwYAAAGYklEQVR4nO2dfcxXYxjHj15VPEwvE5bWUsIf3h4V8jJ52SwbNlboZdLWY5iXZbM1Yiyv8Z/+UEtGzFDYlJrxVIQp60VJQkUZSVT09rFLF549+/3Oue9z7nN+5+e5Ptvzz9PvOdf3/l3n3G/nur9FkWEYhmEYhmEYhmEYhmEYhmFkAjgMOAW4CXgUeAtYBfwGbAVG5BBzBPC9xlilMSX2aOBU0RS1JYCTgDv1i/iZeH4EOgaM3RHYlhBzO/A2cBcwMPo/ApwMTAW+xI8DwMUBdVwE7PfU8BXwuDzJUT0DdALGAYs9Gr8NeEnvzguAI3PQdQQwTJ/SFx2emJZ8CNwCdI7qBe0WpD/e4PgEfKpPz/lAuxpplrHjXuBdYJ+D7q36+cOjMgOMAr5xaNAmYApwYlQygD6qTTQm8R1wQ1Q2gOOAdxyehrnAlUB7j2v3Ai4EJgBPAnOAD4B1wGYdhPfrz3b93Tr9jHz2Cf1buUZPj7jtVetc1R7HfPkOojKgDY3rh6UxLwOnOVyrHTBYx5BX9A4Mzbd6bYlxjks3Kdq1DXGJke/gvKiWqNCdMSKXAI0Og+y1wEzPATYUEnMGcA3QLUFrI7A05lq/yLQ+quHgvTxG3JS4RRZwFjA9IaFFI1qeBc5MWMw+mHATOnfJwQBujRG1q9KCTrukUTqzKjufACMrdWl6M0obqzG6sESooK66/VCNP4Hurf7m8oQnqqx8JtpbtaU7sDfmbzbKOqzIhExyaMh7uriTmcoi6p+FwGXapmaHz99WVDIaHPagDP5ePHYtIiG317qldcT4IhIiW9aGGyvyTsYljkKM/xiaZ0JebRHIcGN2nvtVcVM9ozJ/+Oyh+STk7ioBjWSa8kjIMofARmXez+MdwcEqwYxkZJf4+KJX5kY8d4RMSD1sBpadpaGS0c+6qyDId9gnREJsqyQcE0Mk5M2Agto6r4WorZKSSyMMv2aqxNRKPyMs6QshgIcDizHggSwJ+bggkbu15qpRX4A1aInOU8CeOowTfvoLHONQIBYCeb/SL0ZHf2B1HcVJQgr6jk6TkCsKEPc10MNBSw8tHCh7HFcuTZOQyWUa4DhUXFD2OK7clyYh83IWtSCFpoUljpPveiSh7ioEY1NournEcXzY7CvoBPLHuwYWGFDiOL709hF0dQGCvGuWgG4ljuPLVT6CHilAUGyleSXkiFuJ4/jykI+gNwoQlKYrGVjiOPkN7MDKAgSNS/FFjS9xnHyK6PT8w+8FCEozHV1U4ji+7HQVcyzFMczz6FzZ4/jSy0XQuQUK2ui4pdHT8XRvreP4MsQlIeI7UiSyodc/YU3wRR3F8SH5SDVwP8UjW9/T9ATuUfozBHg68LZ4UXFcmeySEDkNaxTDcy4JESccoxjmuSTko4LEGLDEJSHra62yDbHWJSG1cFNoq/zgkpAdGQKItdHzalVRi1lLkYdwZmpbXeycqrHdJSFSmZGWfx0MgEF1ahSQxPKW7nLAGNKzyyUhvhZ4LWnt3tBZPU+yJLks7Na2dK7g6pCW/S4JcXGCq8bIKtfsq9Z9RZQVheaAWgH2rdI28UNJywaXhIjZV1p2xRmv6HuGmXVyeHSvah0Q054xCSY0SUxw3X7PWnXxepzDmhzvUs/CNZSPNaotSX/Wl3gLnD2C1VZPisuyILO1JqBDQqx/SjlXUjtWqobBCVo7aJukij0LG7yPSqvjdIg1yVrgOkcrvd662zxL/XLzOLl1UBe/szRWYvWH+nxdr23Jinyng7yS0WrqKqaSIRAT5Yk+VSAcKjaQ9zNjpSgAeEG708+BLWp62dKRbqf+Tv5thXYLs9UBTq4x1McLWH3BmlIYQFdjU2a3bO0vxbYuFDt0QTW8rD7rHLIffAb4KWC7FwdzLtWTVI9lXKNU60unaXI6BRGbvn3D9b1Ilml/JfapUXT49ukALF6EeTA9uGD3dokZZx6I+8XZeYuXafGNgaesMoA35Co8vk0NqiEUq9Xss7guWRMzXE/pHsz4SCe/7M8ZuZPVvDPrODGi5mOjGipPTXmXTYpKAuksRNZr2xOdu2sCcIZOM5sd7rgFtfofEWLWG6Ipaeu9WTcaT4/qCaCLHq2+R9+RLNM1wh4170+slSoaPdY2XzVuUc0ztA1SRNelcFGGYRiGYRiGYRiGYRiGYRiGYRiGYURtg78AMLqLjkX9nPAAAAAASUVORK5CYII="

local function resolveDiscordIcon()
	local decoder = Environment.base64_decode or Environment.base64decode
	local customAsset = Environment.getcustomasset or Environment.getsynasset
	local writer = Environment.writefile
	local folderExists = Environment.isfolder
	local makeFolder = Environment.makefolder
	if type(customAsset) == "function" and type(writer) == "function" and type(decoder) == "function" then
		pcall(function()
			if type(folderExists) == "function" and type(makeFolder) == "function" and not folderExists("FlareonHub") then
				makeFolder("FlareonHub")
			end
			writer("FlareonHub/discord-white.png", decoder(DiscordIconData))
		end)
		local ok, asset = pcall(customAsset, "FlareonHub/discord-white.png")
		if ok and type(asset) == "string" and asset ~= "" then
			return asset
		end
	end
	return "rbxthumb://type=Asset&id=16584754901&w=420&h=420"
end

if type(Environment.Young0xAutoBoss) == "table"
	and type(Environment.Young0xAutoBoss.Destroy) == "function" then
	pcall(Environment.Young0xAutoBoss.Destroy, Environment.Young0xAutoBoss)
end

local CONFIG = {
	PlaceId = 3623096087,
	BackgroundAsset = "rbxassetid://93236131139308",
	Discord = "https://discord.gg/5rVh2EWQbX",
	YouTube = "https://www.youtube.com/@NoticeManMyMan",
	Colors = {
		background = Color3.fromRGB(9, 5, 8),
		surface = Color3.fromRGB(18, 9, 13),
		surface2 = Color3.fromRGB(38, 17, 23),
		border = Color3.fromRGB(255, 132, 35),
		purple = Color3.fromRGB(177, 93, 255),
		pink = Color3.fromRGB(235, 71, 190),
		cyan = Color3.fromRGB(255, 166, 50),
		halloweenOrange = Color3.fromRGB(255, 112, 28),
		halloweenAmber = Color3.fromRGB(255, 192, 59),
		halloweenGreen = Color3.fromRGB(119, 220, 90),
		halloweenViolet = Color3.fromRGB(177, 93, 255),
		red = Color3.fromRGB(255, 48, 91),
		green = Color3.fromRGB(91, 224, 113),
		white = Color3.fromRGB(255, 246, 232),
		dim = Color3.fromRGB(196, 156, 142),
	},
}

local TargetAccentById = {
	GrimReaper = CONFIG.Colors.halloweenViolet,
	FrankenBrute = CONFIG.Colors.halloweenGreen,
	ScarecrowColossus = CONFIG.Colors.halloweenAmber,
	PumpkinTitan = CONFIG.Colors.halloweenOrange,
}

local HalloweenContactHeights = {
	GrimReaper = { 40, 20, 30, 50, 0 },
	FrankenBrute = { 30, 20, 50, 0, 40 },
	ScarecrowColossus = { 40, 50, 20, 30, 0 },
	PumpkinTitan = { 30, 40, 20, 50, 0 },
}

local Controller = {}
local connections = {}
local State = {
	running = true,
	active = false,
	generation = 0,
	minimized = false,
	status = "",
	nextBossTime = 0,
	engagedBoss = nil,
	hits = 0,
	damage = 0,
	sequence = nil,
	lastAttackAt = 0,
	lastConfirmedAttackAt = 0,
	hitInterval = 0.31,
	contactReadyAt = 0,
	currentContactHeight = nil,
	originalCharacter = nil,
	originalPivot = nil,
	originalSize = nil,
	originalRoot = nil,
	originalRootAnchored = nil,
	originalPunch = nil,
	originalPunchParent = nil,
	lastKeepAliveAt = 0,
	restoreToken = 0,
	sessionOriginMap = nil,
	sessionOriginPivot = nil,
	sessionRestoreToken = 0,
	transitionRoot = nil,
	transitionOriginalAnchored = nil,
	transitionFloatPosition = nil,
	lastRuntimeError = nil,
	targetMode = initialTargetMode,
	lastHalloweenTarget = initialHalloweenTarget,
}

local function track(connection)
	connections[#connections + 1] = connection
	return connection
end

local function keepAlive()
	local ok = pcall(function()
		VirtualUser:CaptureController()
		local camera = workspace.CurrentCamera
		local cameraCFrame = camera and camera.CFrame or CFrame.new()
		VirtualUser:Button2Down(Vector2.new(0, 0), cameraCFrame)
		task.wait(0.05)
		VirtualUser:Button2Up(Vector2.new(0, 0), cameraCFrame)
	end)
	if ok then
		State.lastKeepAliveAt = os.clock()
	end
	return ok
end

track(LocalPlayer.Idled:Connect(keepAlive))

task.spawn(function()
	while State.running do
		task.wait(45)
		if State.running then
			keepAlive()
		end
	end
end)

local function formatNumber(value)
	local number = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
	local text = tostring(number)
	while true do
		local formatted, count = text:gsub("^(%-?%d+)(%d%d%d)", "%1.%2")
		text = formatted
		if count == 0 then
			break
		end
	end
	return text
end

local function getCharacter()
	return LocalPlayer.Character
end

local function getRoot()
	local character = getCharacter()
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
	local character = getCharacter()
	return character and character:FindFirstChildWhichIsA("Humanoid")
end

local function readCharacterSize()
	local humanoid = getHumanoid()
	local height = humanoid and humanoid:FindFirstChild("BodyHeightScale")
	return math.clamp(math.floor(((height and height.Value) or 1) + 0.5), 1, 100)
end

local function setCharacterSize(size)
	local events = ReplicatedStorage:FindFirstChild("rEvents")
	local remote = events and events:FindFirstChild("changeSpeedSizeRemote")
	size = math.clamp(math.floor((tonumber(size) or 1) + 0.5), 1, 100)
	if not remote then
		return false
	end
	if remote:IsA("RemoteFunction") then
		-- Some executors can leave InvokeServer suspended indefinitely. The size
		-- change is best-effort and must never block the toggle or combat worker.
		task.spawn(function()
			pcall(remote.InvokeServer, remote, "changeSize", size)
		end)
		return true
	elseif remote:IsA("RemoteEvent") then
		return pcall(remote.FireServer, remote, "changeSize", size)
	end
	return false
end

local function equipPunch()
	local character = getCharacter()
	local humanoid = getHumanoid()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not character or not humanoid then
		return nil
	end
	local punch = character:FindFirstChild("Punch") or (backpack and backpack:FindFirstChild("Punch"))
	if not punch then
		return nil
	end
	if not State.originalPunch then
		State.originalPunch = punch
		State.originalPunchParent = punch.Parent
	end
	if punch.Parent ~= character then
		pcall(humanoid.EquipTool, humanoid, punch)
		RunService.Heartbeat:Wait()
	end
	local attackTime = punch:FindFirstChild("attackTime")
	if attackTime and attackTime:IsA("ValueBase") then
		pcall(function()
			attackTime.Value = 0
		end)
	end
	return punch
end

local function firePunchRemotes()
	local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
		or ReplicatedStorage:FindFirstChild("muscleEvent")
	if not muscleEvent or not muscleEvent:IsA("RemoteEvent") then
		return false
	end
	local rightOk = pcall(muscleEvent.FireServer, muscleEvent, "punch", "rightHand")
	local leftOk = pcall(muscleEvent.FireServer, muscleEvent, "punch", "leftHand")
	return rightOk or leftOk
end

local BossProfiles = {
	Boss1 = { index = 1, maxHealth = 63250, maxHitDistance = 90, dodgeLead = 0.75, contactHeight = 45, contactHeights = { 45, -20, 30, 65 }, stompHeight = 100 },
	Boss2 = { index = 2, maxHealth = 77000, maxHitDistance = 97.5, dodgeLead = 0.80, contactHeight = 50, contactHeights = { 50, -22, 35, 72 }, stompHeight = 110 },
	Boss3 = { index = 3, maxHealth = 88000, maxHitDistance = 120, dodgeLead = 0.85, contactHeight = -25, contactHeights = { -25, 42, 60, 82 }, stompHeight = 130 },
	Boss4 = { index = 4, maxHealth = 115500, maxHitDistance = 135, dodgeLead = 0.48, contactHeight = 48, contactHeights = { 48, 68, -28, 92 }, stompHeight = 140 },
	Boss5 = { index = 5, maxHealth = 126500, maxHitDistance = 150, dodgeLead = 1.00, contactHeight = 75, contactHeights = { 75, -30, 55, 102 }, stompHeight = 150 },
	BossRainbow = { index = 6, maxHealth = 101750, maxHitDistance = 127.5, dodgeLead = 0.90, contactHeight = 65, contactHeights = { 65, -30, 45, 85 }, stompHeight = 135 },
}

local HalloweenBossConfig

local function isHalloweenBoss(boss)
	return boss ~= nil and (CollectionService:HasTag(boss, "HalloweenBoss")
		or (typeof(boss:GetAttribute("BossId")) == "string"
			and boss:GetAttribute("Health") ~= nil
			and boss:GetAttribute("MaxHealth") ~= nil))
end

local function getBossHealth(boss)
	if isHalloweenBoss(boss) then
		return math.max(0, tonumber(boss:GetAttribute("Health")) or 0)
	end
	return math.max(0, tonumber(workspace:GetAttribute("BossHealth")) or 0)
end

local function getBossMaximum(boss)
	if isHalloweenBoss(boss) then
		return math.max(getBossHealth(boss), tonumber(boss:GetAttribute("MaxHealth")) or 0)
	end
	local profile = boss and BossProfiles[boss.Name]
	return math.max(getBossHealth(boss), tonumber(workspace:GetAttribute("BossMaxHealth"))
		or (profile and profile.maxHealth) or 0)
end

local function getBossDisplayName(boss)
	if isHalloweenBoss(boss) then
		local option = TargetOptionById[boss:GetAttribute("BossId")]
		return tostring((option and option.label) or boss.Name or "Boss")
	end
	return tostring(workspace:GetAttribute("BossDisplayName") or (boss and boss.Name) or "Boss")
end

local function isBossAvailable(boss)
	if not boss or not boss.Parent or boss:GetAttribute("BossEmerging") == true then
		return false
	end
	if isHalloweenBoss(boss) then
		local health = tonumber(boss:GetAttribute("Health"))
		return health == nil or health > 0
	end
	return workspace:GetAttribute("BossActive") == true and getBossHealth(boss) > 0
end

local function getEffectiveTargetMode()
	return State.targetMode
end

local function isHalloweenTargetMode(mode)
	return mode ~= "Beach"
end

local function getCurrentMapValue()
	local value = LocalPlayer:FindFirstChild("currentMap")
	return value and value:IsA("StringValue") and value or nil
end

local function getTargetMapName(targetMode)
	return isHalloweenTargetMode(targetMode) and "Hallowed Gym" or "Beach"
end

local function setCurrentMap(targetMode)
	local value = getCurrentMapValue()
	local requiredMap = getTargetMapName(targetMode)
	if value and value.Value ~= requiredMap then
		value.Value = requiredMap
		return true
	end
	return false
end

local function bossMatchesTargetMode(boss, mode)
	if isHalloweenTargetMode(mode) then
		if not isHalloweenBoss(boss) then
			return false
		end
		return boss:GetAttribute("BossId") == mode
	end
	return not isHalloweenBoss(boss)
end

local function getBossParts(boss)
	if not isBossAvailable(boss) then
		return nil, nil
	end
	local hitbox = boss:FindFirstChild("BossDamageHitbox", true)
		or boss.PrimaryPart
		or boss:FindFirstChildWhichIsA("BasePart", true)
	if not hitbox or not hitbox:IsA("BasePart") then
		return nil, nil
	end
	local target = boss:FindFirstChild("Boss")
		or boss:FindFirstChild("Head", true)
		or boss.PrimaryPart
	if not target or not target:IsA("BasePart") or target == hitbox then
		local largestVolume = -1
		for _, object in ipairs(boss:GetDescendants()) do
			if object:IsA("BasePart") and object ~= hitbox and object.Transparency < 1 then
				local size = object.Size
				local volume = size.X * size.Y * size.Z
				if volume > largestVolume then
					target = object
					largestVolume = volume
				end
			end
		end
	end
	target = target or hitbox
	if target and target:IsA("BasePart") then
		return hitbox, target
	end
	return nil, nil
end

local function findBoss(preferred)
	local targetMode = getEffectiveTargetMode()
	if preferred and bossMatchesTargetMode(preferred, targetMode) then
		local hitbox, target = getBossParts(preferred)
		if hitbox and target then
			return preferred, hitbox, target
		end
	end
	if isHalloweenTargetMode(targetMode) then
		local halloween = {}
		for _, boss in ipairs(CollectionService:GetTagged("HalloweenBoss")) do
			if isBossAvailable(boss) and bossMatchesTargetMode(boss, targetMode) then
				halloween[#halloween + 1] = boss
			end
		end
		table.sort(halloween, function(left, right)
			local leftMaximum = getBossMaximum(left)
			local rightMaximum = getBossMaximum(right)
			local leftRatio = leftMaximum > 0 and getBossHealth(left) / leftMaximum or 1
			local rightRatio = rightMaximum > 0 and getBossHealth(right) / rightMaximum or 1
			if math.abs(leftRatio - rightRatio) > 0.0001 then
				return leftRatio < rightRatio
			end
			return (tonumber(left:GetAttribute("ID")) or math.huge)
				< (tonumber(right:GetAttribute("ID")) or math.huge)
		end)
		for _, boss in ipairs(halloween) do
			local hitbox, target = getBossParts(boss)
			if hitbox and target then
				return boss, hitbox, target
			end
		end
		return nil, nil, nil
	end
	local candidates = CollectionService:GetTagged("BossEventBoss")
	if #candidates == 0 then
		local events = workspace:FindFirstChild("Events")
		local arena = events and events:FindFirstChild("BossArena")
		if arena then
			for _, object in ipairs(arena:GetChildren()) do
				if object:IsA("Model") and (object:FindFirstChild("BossDamageHitbox", true)
					or typeof(object:GetAttribute("BossRarityIndex")) == "number") then
					candidates[#candidates + 1] = object
				end
			end
		end
	end
	for _, boss in ipairs(candidates) do
		local hitbox, target = getBossParts(boss)
		if hitbox and target then
			return boss, hitbox, target
		end
	end
	return nil, nil, nil
end

local function getBossProfile(boss)
	if isHalloweenBoss(boss) then
		local maximum = getBossMaximum(boss)
		local contactHeights = HalloweenContactHeights[boss:GetAttribute("BossId")]
			or { 20, 40, 30, 50, 0 }
		return {
			index = tonumber(boss:GetAttribute("ID")) or 1,
			maxHealth = maximum,
			maxHitDistance = 110,
			dodgeLead = 0.42,
			contactHeight = contactHeights[1],
			contactHeights = contactHeights,
			stompHeight = 125,
		}
	end
	local profile = boss and BossProfiles[boss.Name]
	if profile then
		return profile
	end
	local rarityIndex = boss and boss:GetAttribute("BossRarityIndex")
	if typeof(rarityIndex) == "number" then
		for _, candidate in pairs(BossProfiles) do
			if candidate.index == rarityIndex then
				return candidate
			end
		end
	end
	return BossProfiles.Boss5
end

local function loadBossConfig()
	local config = ReplicatedStorage:FindFirstChild("shared")
	config = config and config:FindFirstChild("config")
	local bossEventConfig = config and config:FindFirstChild("BossEventConfig")
	local halloweenModule = config and config:FindFirstChild("HalloweenBossConfig")
	-- Never require game ModuleScripts from the UI callback. In Solara that
	-- request can yield forever, leaving the toggle visually on and preventing
	-- both the combat worker and the next click from running.
	return bossEventConfig ~= nil
		or halloweenModule ~= nil
		or workspace:GetAttribute("BossActive") ~= nil
		or #CollectionService:GetTagged("BossEventBoss") > 0
		or #CollectionService:GetTagged("HalloweenBoss") > 0
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlareonHubAutoBossUI"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 2147483000
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui:SetAttribute("FlareonHubBuild", AUTO_BOSS_BUILD)
ScreenGui:SetAttribute("Theme", "Halloween")

local parent = CoreGui
if type(gethui) == "function" then
	local ok, result = pcall(gethui)
	if ok and result then
		parent = result
	end
end
if type(syn) == "table" and type(syn.protect_gui) == "function" then
	pcall(syn.protect_gui, ScreenGui)
end
ScreenGui.Parent = parent

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.Size = UDim2.fromOffset(360, BEACH_HEIGHT + (initialTargetMode ~= "Beach" and HALLOWEEN_EXTRA_HEIGHT or 0))
Main.BackgroundColor3 = CONFIG.Colors.background
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 3, 5)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(24, 7, 14)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(31, 10, 26)),
})
mainGradient.Rotation = 135
mainGradient.Parent = Main

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 26)
mainCorner.Parent = Main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = CONFIG.Colors.border
mainStroke.Thickness = 1.2
mainStroke.Transparency = 0.2
mainStroke.Parent = Main

local Scale = Instance.new("UIScale")
Scale.Parent = Main

local function calculateScale(viewport)
	local expectedHeight = BEACH_HEIGHT + (State.targetMode ~= "Beach" and HALLOWEEN_EXTRA_HEIGHT or 0) + 60
	local fit = math.min(viewport.X / 400, viewport.Y / expectedHeight)
	local maximum = 1
	if UserInputService.TouchEnabled then
		if viewport.X > viewport.Y then
			maximum = viewport.Y < 450 and 0.78 or 0.86
		else
			maximum = viewport.X < 450 and 0.82 or 0.9
		end
	end
	return math.clamp(math.min(fit, maximum), 0.58, 1)
end

local function refreshScale()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	Scale.Scale = calculateScale(viewport)
end
refreshScale()

local Background = Instance.new("ImageLabel")
Background.Name = "Skulls"
Background.Size = UDim2.fromScale(1, 1)
Background.BackgroundTransparency = 1
Background.Image = CONFIG.BackgroundAsset
Background.ImageColor3 = Color3.fromRGB(255, 116, 34)
Background.ImageTransparency = 0.68
Background.ScaleType = Enum.ScaleType.Crop
Background.ZIndex = 0
Background.Parent = Main
Instance.new("UICorner", Background).CornerRadius = UDim.new(0, 26)

local Shade = Instance.new("Frame")
Shade.Size = UDim2.fromScale(1, 1)
Shade.BackgroundColor3 = Color3.fromRGB(12, 4, 8)
Shade.BackgroundTransparency = 0.3
Shade.BorderSizePixel = 0
Shade.ZIndex = 1
Shade.Parent = Main
Instance.new("UICorner", Shade).CornerRadius = UDim.new(0, 26)

local Header = Instance.new("TextButton")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 56)
Header.BackgroundTransparency = 1
Header.BorderSizePixel = 0
Header.AutoButtonColor = false
Header.Text = ""
Header.Font = Enum.Font.Garamond
Header.Active = true
Header.ZIndex = 3
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(24, 0)
Title.Size = UDim2.new(1, -48, 0, 30)
Title.Font = Enum.Font.Garamond
Title.Text = "🎃 Flareon Hub 🎃"
Title.TextColor3 = CONFIG.Colors.white
Title.TextSize = 23
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.ZIndex = 5
Title.Parent = Header

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, CONFIG.Colors.halloweenOrange),
	ColorSequenceKeypoint.new(0.33, CONFIG.Colors.white),
	ColorSequenceKeypoint.new(0.7, CONFIG.Colors.halloweenViolet),
	ColorSequenceKeypoint.new(1, CONFIG.Colors.halloweenAmber),
})
titleGradient.Offset = Vector2.new(-0.3, 0)
titleGradient.Parent = Title

local Subtitle = Instance.new("TextLabel")
Subtitle.Name = "Subtitle"
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.fromOffset(24, 29)
Subtitle.Size = UDim2.new(1, -48, 0, 19)
Subtitle.Font = Enum.Font.Garamond
Subtitle.Text = "🎃 Auto Boss 🎃"
Subtitle.TextColor3 = CONFIG.Colors.white
Subtitle.TextSize = 15
Subtitle.TextXAlignment = Enum.TextXAlignment.Center
Subtitle.ZIndex = 5
Subtitle.Parent = Header

local subtitleGradient = Instance.new("UIGradient")
subtitleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, CONFIG.Colors.halloweenViolet),
	ColorSequenceKeypoint.new(0.5, CONFIG.Colors.white),
	ColorSequenceKeypoint.new(1, CONFIG.Colors.halloweenOrange),
})
subtitleGradient.Offset = Vector2.new(0.3, 0)
subtitleGradient.Parent = Subtitle

local colorTweenInfo = TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local titleColorTween = TweenService:Create(titleGradient, colorTweenInfo, { Offset = Vector2.new(0.3, 0) })
local subtitleColorTween = TweenService:Create(subtitleGradient, colorTweenInfo, { Offset = Vector2.new(-0.3, 0) })
titleColorTween:Play()
subtitleColorTween:Play()

local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Position = UDim2.fromOffset(0, 56)
Body.Size = UDim2.new(1, 0, 1, -56)
Body.BackgroundTransparency = 1
Body.ZIndex = 3
Body.Parent = Main

local function makeCard(name, position, size)
	local card = Instance.new("Frame")
	card.Name = name
	card.Position = position
	card.Size = size
	card.BackgroundColor3 = CONFIG.Colors.surface
	card.BackgroundTransparency = 0.27
	card.BorderSizePixel = 0
	card.ZIndex = 4
	card.Parent = Body
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 19)
	local stroke = Instance.new("UIStroke", card)
	stroke.Color = CONFIG.Colors.border
	stroke.Transparency = 0.55
	stroke.Thickness = 1
	local gradient = Instance.new("UIGradient", card)
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 10, 15)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(12, 7, 11)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 13, 24)),
	})
	gradient.Rotation = 12
	return card, stroke
end

local ToggleCard, ToggleCardStroke = makeCard("AutoBoss", UDim2.fromOffset(18, 6), UDim2.new(1, -36, 0, 56))

local ToggleTitle = Instance.new("TextLabel")
ToggleTitle.BackgroundTransparency = 1
ToggleTitle.Position = UDim2.fromOffset(18, 0)
ToggleTitle.Size = UDim2.new(1, -102, 1, 0)
ToggleTitle.Font = Enum.Font.Garamond
ToggleTitle.Text = "Auto Boss"
ToggleTitle.TextColor3 = CONFIG.Colors.white
ToggleTitle.TextSize = 20
ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
ToggleTitle.ZIndex = 6
ToggleTitle.Parent = ToggleCard

local ToggleButton = Instance.new("TextButton")
ToggleButton.AnchorPoint = Vector2.new(1, 0.5)
ToggleButton.Position = UDim2.new(1, -15, 0.5, 0)
ToggleButton.Size = UDim2.fromOffset(56, 30)
ToggleButton.BackgroundColor3 = Color3.fromRGB(68, 39, 37)
ToggleButton.BorderSizePixel = 0
ToggleButton.AutoButtonColor = false
ToggleButton.Text = ""
ToggleButton.Font = Enum.Font.Garamond
ToggleButton.ZIndex = 7
ToggleButton.Parent = ToggleCard
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

local ToggleKnob = Instance.new("Frame")
ToggleKnob.AnchorPoint = Vector2.new(0.5, 0.5)
ToggleKnob.Position = UDim2.new(0, 15, 0.5, 0)
ToggleKnob.Size = UDim2.fromOffset(22, 22)
ToggleKnob.BackgroundColor3 = Color3.fromRGB(245, 225, 207)
ToggleKnob.BorderSizePixel = 0
ToggleKnob.ZIndex = 8
ToggleKnob.Parent = ToggleButton
Instance.new("UICorner", ToggleKnob).CornerRadius = UDim.new(1, 0)

local ToggleHitbox = Instance.new("TextButton")
ToggleHitbox.Name = "ToggleArea"
ToggleHitbox.Size = UDim2.fromScale(1, 1)
ToggleHitbox.BackgroundTransparency = 1
ToggleHitbox.BorderSizePixel = 0
ToggleHitbox.AutoButtonColor = false
ToggleHitbox.Text = ""
ToggleHitbox.Font = Enum.Font.Garamond
ToggleHitbox.ZIndex = 9
ToggleHitbox.Parent = ToggleCard

local TargetCard, TargetCardStroke = makeCard("BossType", UDim2.fromOffset(18, 72), UDim2.new(1, -36, 0, 42))
local HalloweenCard, HalloweenCardStroke = makeCard("HalloweenBosses", UDim2.fromOffset(18, 122), UDim2.new(1, -36, 0, 42))
TargetCard.BackgroundTransparency = 1
TargetCardStroke.Enabled = false
HalloweenCard.BackgroundTransparency = 1
HalloweenCardStroke.Enabled = false
HalloweenCard.Visible = initialTargetMode ~= "Beach"
local ModeButtons = {}
local TargetButtons = {}

local function makeTargetButton(parent, collection, id, text, position, size, maximumTextSize)
	local button = Instance.new("TextButton")
	button.Name = id
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = CONFIG.Colors.surface2
	button.BackgroundTransparency = 0.38
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.Garamond
	button.Text = text
	button.TextColor3 = CONFIG.Colors.white
	button.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	button.TextStrokeTransparency = 0.42
	button.TextScaled = true
	button.ZIndex = 7
	button.Parent = parent
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 11)
	local stroke = Instance.new("UIStroke", button)
	stroke.Color = CONFIG.Colors.border
	stroke.Transparency = 0.72
	stroke.Thickness = 1
	local constraint = Instance.new("UITextSizeConstraint", button)
	constraint.MinTextSize = 10
	constraint.MaxTextSize = maximumTextSize or 15
	collection[id] = { button = button, stroke = stroke }
end

makeTargetButton(TargetCard, ModeButtons, "Beach", "Playa", UDim2.fromOffset(6, 5), UDim2.fromOffset(153, 32), 16)
makeTargetButton(TargetCard, ModeButtons, "Halloween", "Halloween", UDim2.fromOffset(165, 5), UDim2.fromOffset(153, 32), 16)
makeTargetButton(HalloweenCard, TargetButtons, "GrimReaper", "Grim", UDim2.fromOffset(6, 5), UDim2.fromOffset(75, 32), 14)
makeTargetButton(HalloweenCard, TargetButtons, "FrankenBrute", "Franken", UDim2.fromOffset(85, 5), UDim2.fromOffset(75, 32), 14)
makeTargetButton(HalloweenCard, TargetButtons, "ScarecrowColossus", "Scarecrow", UDim2.fromOffset(164, 5), UDim2.fromOffset(75, 32), 14)
makeTargetButton(HalloweenCard, TargetButtons, "PumpkinTitan", "Pumpkin", UDim2.fromOffset(243, 5), UDim2.fromOffset(75, 32), 14)

local initialTargetOffset = initialTargetMode ~= "Beach" and HALLOWEEN_EXTRA_HEIGHT or 0
local HealthCard, HealthStroke = makeCard("BossHealth", UDim2.fromOffset(18, 122 + initialTargetOffset), UDim2.new(1, -36, 0, 120))

local StatusText = Instance.new("TextLabel")
StatusText.BackgroundTransparency = 1
StatusText.Position = UDim2.fromOffset(16, 9)
StatusText.Size = UDim2.new(1, -32, 0, 24)
StatusText.Font = Enum.Font.Garamond
StatusText.Text = ""
StatusText.TextColor3 = CONFIG.Colors.cyan
StatusText.TextSize = 17
StatusText.TextXAlignment = Enum.TextXAlignment.Center
StatusText.ZIndex = 6
StatusText.Visible = false
StatusText.Parent = HealthCard

local HealthText = Instance.new("TextLabel")
HealthText.BackgroundTransparency = 1
HealthText.Position = UDim2.fromOffset(16, 38)
HealthText.Size = UDim2.new(1, -32, 0, 25)
HealthText.Font = Enum.Font.Garamond
HealthText.Text = "Vida del Boss: 0"
HealthText.TextColor3 = CONFIG.Colors.white
HealthText.TextSize = 18
HealthText.TextXAlignment = Enum.TextXAlignment.Center
HealthText.ZIndex = 6
HealthText.Parent = HealthCard

local HitsValue = Instance.new("TextLabel")
HitsValue.BackgroundTransparency = 1
HitsValue.Position = UDim2.fromOffset(16, 64)
HitsValue.Size = UDim2.new(1, -32, 0, 23)
HitsValue.Font = Enum.Font.Garamond
HitsValue.Text = "Golpes: 0"
HitsValue.TextColor3 = CONFIG.Colors.cyan
HitsValue.TextSize = 17
HitsValue.TextXAlignment = Enum.TextXAlignment.Center
HitsValue.ZIndex = 6
HitsValue.Parent = HealthCard

local HealthBar = Instance.new("Frame")
HealthBar.Position = UDim2.new(0, 18, 1, -20)
HealthBar.Size = UDim2.new(1, -36, 0, 6)
HealthBar.BackgroundColor3 = Color3.fromRGB(57, 25, 28)
HealthBar.BorderSizePixel = 0
HealthBar.ClipsDescendants = true
HealthBar.ZIndex = 6
HealthBar.Parent = HealthCard
Instance.new("UICorner", HealthBar).CornerRadius = UDim.new(1, 0)

local HealthFill = Instance.new("Frame")
HealthFill.Size = UDim2.fromScale(0, 1)
HealthFill.BackgroundColor3 = CONFIG.Colors.purple
HealthFill.BorderSizePixel = 0
HealthFill.ZIndex = 7
HealthFill.Parent = HealthBar
Instance.new("UICorner", HealthFill).CornerRadius = UDim.new(1, 0)
local healthGradient = Instance.new("UIGradient", HealthFill)
healthGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, CONFIG.Colors.halloweenViolet),
	ColorSequenceKeypoint.new(0.55, CONFIG.Colors.halloweenOrange),
	ColorSequenceKeypoint.new(1, CONFIG.Colors.halloweenAmber),
})

local function makeSocialButton(name, image, position)
	local button = Instance.new("ImageButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(0.5, 0)
	button.Position = position
	button.Size = UDim2.fromOffset(40, 40)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Image = image
	button.ImageColor3 = CONFIG.Colors.white
	button.ScaleType = Enum.ScaleType.Fit
	button.ZIndex = 6
	button.Parent = Body
	local scale = Instance.new("UIScale", button)
	return button, scale
end

local DiscordButton, DiscordScale = makeSocialButton(
	"Discord",
	resolveDiscordIcon(),
	UDim2.new(0.5, -34, 0, 246 + initialTargetOffset)
)
local YouTubeButton, YouTubeScale = makeSocialButton(
	"YouTube",
	"rbxthumb://type=Asset&id=85469926655680&w=420&h=420",
	UDim2.new(0.5, 34, 0, 246 + initialTargetOffset)
)

local CopyStatus = Instance.new("TextLabel")
CopyStatus.Position = UDim2.fromOffset(18, 288 + initialTargetOffset)
CopyStatus.Size = UDim2.new(1, -36, 0, 20)
CopyStatus.BackgroundTransparency = 1
CopyStatus.Font = Enum.Font.Garamond
CopyStatus.Text = ""
CopyStatus.TextColor3 = CONFIG.Colors.cyan
CopyStatus.TextSize = 13
CopyStatus.TextXAlignment = Enum.TextXAlignment.Center
CopyStatus.Visible = false
CopyStatus.ZIndex = 6
CopyStatus.Parent = Body

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseScript"
CloseButton.AnchorPoint = Vector2.new(0.5, 0)
CloseButton.Position = UDim2.new(0.5, 0, 0, 290 + initialTargetOffset)
CloseButton.Size = UDim2.fromOffset(154, 34)
CloseButton.BackgroundTransparency = 1
CloseButton.BorderSizePixel = 0
CloseButton.AutoButtonColor = false
CloseButton.Font = Enum.Font.Garamond
CloseButton.Text = "Cerrar Script"
CloseButton.TextColor3 = CONFIG.Colors.dim
CloseButton.TextSize = 14
CloseButton.ZIndex = 6
CloseButton.Parent = Body
local CloseScale = Instance.new("UIScale", CloseButton)

local function setStatus(text, color)
	State.status = tostring(text or "")
	if not isBossAvailable(State.engagedBoss) then
		StatusText.Text = State.status
		StatusText.TextColor3 = color or CONFIG.Colors.cyan
	end
end

local function setToggleVisual(enabled)
	local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ToggleButton, info, {
		BackgroundColor3 = enabled and CONFIG.Colors.halloweenOrange or Color3.fromRGB(68, 39, 37),
	}):Play()
	TweenService:Create(ToggleKnob, info, {
		Position = enabled and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 15, 0.5, 0),
		BackgroundColor3 = enabled and CONFIG.Colors.white or Color3.fromRGB(245, 225, 207),
	}):Play()
	ToggleCardStroke.Color = enabled and CONFIG.Colors.halloweenOrange or CONFIG.Colors.border
	ToggleCardStroke.Transparency = enabled and 0.18 or 0.55
end

local function setTargetVisual()
	local halloween = isHalloweenTargetMode(State.targetMode)
	for id, entry in pairs(ModeButtons) do
		local selected = (id == "Beach" and not halloween) or (id == "Halloween" and halloween)
		local accent = id == "Beach" and CONFIG.Colors.halloweenViolet or CONFIG.Colors.halloweenOrange
		entry.button.BackgroundColor3 = selected and accent or CONFIG.Colors.surface2
		entry.button.BackgroundTransparency = selected and 0.08 or 1
		entry.button.TextColor3 = selected and CONFIG.Colors.white or accent
		entry.button.TextStrokeTransparency = selected and 0.55 or 0.32
		entry.stroke.Color = selected and accent or CONFIG.Colors.border
		entry.stroke.Transparency = selected and 0.04 or 1
	end
	for id, entry in pairs(TargetButtons) do
		local selected = id == State.targetMode
		local accent = TargetAccentById[id] or CONFIG.Colors.halloweenOrange
		entry.button.BackgroundColor3 = selected and accent or CONFIG.Colors.surface2
		entry.button.BackgroundTransparency = selected and 0.08 or 1
		entry.button.TextColor3 = selected and CONFIG.Colors.white or accent
		entry.button.TextStrokeTransparency = selected and 0.55 or 0.32
		entry.stroke.Color = selected and accent or CONFIG.Colors.border
		entry.stroke.Transparency = selected and 0.04 or 1
	end
end

setTargetVisual()

local function refreshBossStats()
	if not State.running then
		return
	end
	setTargetVisual()
	HitsValue.Text = "Golpes: " .. formatNumber(State.hits)
	local boss = State.engagedBoss
	if not isBossAvailable(boss) then
		boss = findBoss()
	end
	local activeBoss = boss ~= nil
	StatusText.Visible = true
	HealthText.Position = UDim2.fromOffset(16, 38)
	HitsValue.Position = UDim2.fromOffset(16, 64)
	if activeBoss then
		local health = getBossHealth(boss)
		local maximum = getBossMaximum(boss)
		HealthText.Text = "Vida del Boss: " .. formatNumber(health) .. " / " .. formatNumber(maximum)
		StatusText.Text = getBossDisplayName(boss) .. " Activo"
		StatusText.TextColor3 = CONFIG.Colors.green
		local ratio = maximum > 0 and math.clamp(health / maximum, 0, 1) or 0
		TweenService:Create(HealthFill, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
			Size = UDim2.fromScale(ratio, 1),
		}):Play()
		HealthStroke.Color = isHalloweenBoss(boss)
			and (TargetAccentById[State.targetMode] or CONFIG.Colors.halloweenOrange)
			or CONFIG.Colors.halloweenViolet
		HealthStroke.Transparency = 0.16
	else
		HealthText.Text = "Vida del Boss: 0"
		local targetMode = getEffectiveTargetMode()
		if isHalloweenTargetMode(targetMode) then
			local option = TargetOptionById[targetMode]
			StatusText.Text = "Esperando: " .. tostring(option and option.label or "boss de Halloween")
		else
			local serverNow = workspace:GetServerTimeNow()
			local nextSpawnAttribute = tonumber(workspace:GetAttribute("BossSpawnNextTime"))
			if nextSpawnAttribute and nextSpawnAttribute > 0 then
				State.nextBossTime = nextSpawnAttribute
			end
			local nextSpawn = State.nextBossTime
			local remaining = math.max(0, math.ceil(nextSpawn - serverNow))
			local hours = math.floor(remaining / 3600)
			local minutes = math.floor((remaining % 3600) / 60)
			local seconds = remaining % 60
			if hours > 0 then
				StatusText.Text = "Próximo boss: " .. hours .. " h " .. minutes .. " min " .. seconds .. " seg"
			else
				StatusText.Text = "Próximo boss: " .. minutes .. " min " .. seconds .. " seg"
			end
		end
		StatusText.TextColor3 = CONFIG.Colors.cyan
		TweenService:Create(HealthFill, TweenInfo.new(0.18), { Size = UDim2.fromScale(0, 1) }):Play()
		HealthStroke.Color = CONFIG.Colors.border
		HealthStroke.Transparency = 0.55
	end
end

local function getArenaFloorY(boss, root)
	if isHalloweenBoss(boss) then
		local bossId = boss:GetAttribute("BossId")
		for _, spawn in ipairs(CollectionService:GetTagged("HalloweenBossSpawn")) do
			if spawn:IsA("BasePart") and spawn:GetAttribute("BossId") == bossId then
				return spawn.Position.Y
			end
		end
	end
	local events = workspace:FindFirstChild("Events")
	local arena = events and events:FindFirstChild("BossArena")
	local spawn = arena and arena:FindFirstChild("BossSpawn", true)
	if spawn and spawn:IsA("BasePart") then
		return spawn.Position.Y
	end
	return root and root.Position.Y or 0
end

local function getBossDodgePosition(boss, part, target, root, forceVertical)
	local profile = getBossProfile(boss)
	local attackKind = boss:GetAttribute("BossAttackKind")
	local attackCFrame = boss:GetAttribute("BossAttackCFrame")
	if typeof(attackCFrame) ~= "CFrame" then
		attackCFrame = CFrame.new(part.Position) * part.CFrame.Rotation
	end
	local rootHalfHeight = root.Size.Y * 0.5
	local safeRootY = getArenaFloorY(boss, root) + rootHalfHeight + 1.5
	local look = Vector3.new(attackCFrame.LookVector.X, 0, attackCFrame.LookVector.Z)
	if look.Magnitude < 0.01 then
		look = Vector3.new(part.CFrame.LookVector.X, 0, part.CFrame.LookVector.Z)
	end
	look = look.Magnitude >= 0.01 and look.Unit or Vector3.zAxis
	local attackOrigin = Vector3.new(attackCFrame.Position.X, safeRootY, attackCFrame.Position.Z)
	if attackKind == "Punch" and not forceVertical then
		local behindDistance = math.min(profile.maxHitDistance * 0.38, math.max(12, target.Size.Z * 0.38))
		return attackOrigin - look * behindDistance
	end
	local verticalY = math.max(
		attackOrigin.Y + profile.stompHeight + rootHalfHeight + 24,
		part.Position.Y + part.Size.Y * 0.5 + rootHalfHeight + 35
	)
	return Vector3.new(part.Position.X, verticalY, part.Position.Z)
end

local function restoreBattle(restorePositionEnabled)
	local originalPivot = State.originalPivot
	local originalSize = State.originalSize
	local originalRoot = State.originalRoot
	local originalRootAnchored = State.originalRootAnchored
	local originalPunch = State.originalPunch
	local originalPunchParent = State.originalPunchParent
	local transitionRoot = State.transitionRoot
	local transitionOriginalAnchored = State.transitionOriginalAnchored
	local transitionFloatPosition = State.transitionFloatPosition
	State.transitionRoot = nil
	State.transitionOriginalAnchored = nil
	State.transitionFloatPosition = nil
	if transitionFloatPosition then
		transitionFloatPosition:Destroy()
	end
	if transitionRoot and transitionRoot.Parent and transitionOriginalAnchored ~= nil then
		transitionRoot.Anchored = transitionOriginalAnchored
	end
	if not originalPivot and not originalSize and not originalRoot and not originalPunch then
		State.engagedBoss = nil
		State.contactReadyAt = 0
		State.currentContactHeight = nil
		return
	end
	State.restoreToken += 1
	local restoreToken = State.restoreToken
	if originalRoot and originalRoot.Parent and originalRootAnchored ~= nil then
		originalRoot.Anchored = originalRootAnchored
	end
	if originalSize then
		setCharacterSize(originalSize)
	end
	if originalPunch and originalPunch.Parent and originalPunchParent
		and originalPunchParent.Parent then
		pcall(function()
			originalPunch.Parent = originalPunchParent
		end)
	end
	State.originalCharacter = nil
	State.originalPivot = nil
	State.originalSize = nil
	State.originalRoot = nil
	State.originalRootAnchored = nil
	State.originalPunch = nil
	State.originalPunchParent = nil
	State.engagedBoss = nil
	State.contactReadyAt = 0
	State.currentContactHeight = nil
	local function restorePosition()
		if restorePositionEnabled == false then
			return
		end
		if State.restoreToken ~= restoreToken or State.engagedBoss ~= nil or not originalPivot then
			return
		end
		local character = getCharacter()
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if character and root then
			pcall(character.PivotTo, character, originalPivot)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end
	restorePosition()
	for _, delayTime in ipairs({ 0.12, 0.35, 0.8 }) do
		task.delay(delayTime, restorePosition)
	end
end

local function lockTransitionRoot(originalAnchored)
	local root = getRoot()
	if not root then
		return nil
	end
	if State.transitionRoot ~= root then
		State.transitionRoot = root
		State.transitionOriginalAnchored = originalAnchored ~= nil and originalAnchored or root.Anchored
	end
	if not State.transitionFloatPosition or State.transitionFloatPosition.Parent ~= root then
		if State.transitionFloatPosition then
			State.transitionFloatPosition:Destroy()
		end
		local floatPosition = Instance.new("BodyPosition")
		floatPosition.Name = "Young0xBossTransitionLock"
		floatPosition.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		floatPosition.P = 1e9
		floatPosition.D = 1e7
		floatPosition.Position = root.Position
		floatPosition.Parent = root
		State.transitionFloatPosition = floatPosition
	end
	root.Anchored = true
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	return root
end

local function captureSessionOrigin()
	if State.sessionOriginPivot then
		return
	end
	local character = getCharacter()
	local mapValue = getCurrentMapValue()
	if character then
		State.sessionOriginPivot = character:GetPivot()
	end
	State.sessionOriginMap = mapValue and mapValue.Value or nil
end

local function restoreSessionOrigin()
	local originPivot = State.sessionOriginPivot
	local originMap = State.sessionOriginMap
	State.sessionOriginPivot = nil
	State.sessionOriginMap = nil
	State.sessionRestoreToken += 1
	local restoreToken = State.sessionRestoreToken
	local mapValue = getCurrentMapValue()
	if mapValue and originMap and mapValue.Value ~= originMap then
		mapValue.Value = originMap
	end
	restoreBattle()
	if not originPivot then
		return
	end
	local function restorePosition()
		if State.sessionRestoreToken ~= restoreToken or State.active then
			return
		end
		local character = getCharacter()
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if character and root then
			pcall(character.PivotTo, character, originPivot)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end
	restorePosition()
	for _, delayTime in ipairs({ 0.25, 0.5, 1 }) do
		task.delay(delayTime, restorePosition)
	end
end

local function prepareTargetMap(generation)
	lockTransitionRoot()
	local changed = setCurrentMap(getEffectiveTargetMode())
	if changed then
		setStatus("Cambiando de zona...", CONFIG.Colors.purple)
	end
	local boss, part = findBoss()
	local character = getCharacter()
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if boss and part and character and root then
		local rootHalfHeight = root.Size.Y * 0.5
		local destinationY = math.max(
			part.Position.Y + 30,
			getArenaFloorY(boss, root) + rootHalfHeight + 6
		)
		character:PivotTo(CFrame.new(part.Position.X, destinationY, part.Position.Z))
		if State.transitionFloatPosition and State.transitionFloatPosition.Parent == root then
			State.transitionFloatPosition.Position = root.Position
		end
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	task.wait(changed and 0.18 or 0.05)
	return State.running and State.active and State.generation == generation
end

local function waitForReadyCharacter(timeout)
	local deadline = os.clock() + (tonumber(timeout) or 8)
	local stableCharacter
	local stableRoot
	local stableAt
	while State.running and State.active and os.clock() < deadline do
		local character = getCharacter()
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		local machine = LocalPlayer:FindFirstChild("machineInUse")
		local rebirthing = character and (character:GetAttribute("IsRebirthing") == true
			or character:GetAttribute("LastMapCFrame") ~= nil)
		local mounted = (machine and machine.Value ~= nil) or (humanoid and humanoid.SeatPart ~= nil)
		if character and root and humanoid and humanoid.Health > 0 and not rebirthing and not mounted then
			if character ~= stableCharacter or root ~= stableRoot then
				stableCharacter = character
				stableRoot = root
				stableAt = os.clock()
			elseif os.clock() - stableAt >= 0.18 then
				return character, root, humanoid
			end
		else
			stableCharacter = nil
			stableRoot = nil
			stableAt = nil
		end
		task.wait(0.05)
	end
	return nil, nil, nil
end

local function beginBattle(boss)
	if State.engagedBoss == boss then
		return true
	end
	local character, root = waitForReadyCharacter(8)
	if not character or not root or not isBossAvailable(boss) then
		return false
	end
	State.restoreToken += 1
	State.originalCharacter = character
	State.originalPivot = character:GetPivot()
	State.originalSize = readCharacterSize()
	State.originalRoot = root
	if State.transitionRoot == root and State.transitionOriginalAnchored ~= nil then
		State.originalRootAnchored = State.transitionOriginalAnchored
	else
		State.originalRootAnchored = root.Anchored
	end
	State.transitionRoot = nil
	State.transitionOriginalAnchored = nil
	State.engagedBoss = boss
	State.contactReadyAt = os.clock() + 0.55
	State.currentContactHeight = nil
	local halloweenBoss = isHalloweenBoss(boss)
	local setupLockConnection
	root.Anchored = true
	if halloweenBoss then
		setupLockConnection = RunService.PostSimulation:Connect(function()
			if State.running and State.active and State.engagedBoss == boss and root.Parent then
				root.Anchored = true
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
		end)
	end
	setCharacterSize(1)
	task.wait(0.55)
	if setupLockConnection then
		setupLockConnection:Disconnect()
	end
	if not halloweenBoss then
		if State.transitionFloatPosition then
			State.transitionFloatPosition:Destroy()
			State.transitionFloatPosition = nil
		end
		if root.Parent then
			root.Anchored = State.originalRootAnchored == true
		end
	end
	return State.running and State.active and boss.Parent ~= nil
end

local function collectChest(timeout)
	local deadline = os.clock() + (tonumber(timeout) or 12)
	local lastAttempt = 0
	while State.running and State.active and os.clock() < deadline do
		local prompt
		for _, chest in ipairs(CollectionService:GetTagged("BossEventChest")) do
			prompt = chest:FindFirstChild("bossChestPrompt", true)
			if prompt then
				break
			end
		end
		if not prompt then
			local events = workspace:FindFirstChild("Events")
			prompt = events and events:FindFirstChild("bossChestPrompt", true)
		end
		local eligible = LocalPlayer:GetAttribute("BossChestEligible") == true
		local pending = LocalPlayer:GetAttribute("BossChestPending") == true
		if prompt and prompt:IsA("ProximityPrompt") and eligible and pending
			and os.clock() - lastAttempt >= 0.45 then
			lastAttempt = os.clock()
			local character = getCharacter()
			local root = getRoot()
			local promptPart = prompt.Parent
			if character and root and promptPart and promptPart:IsA("BasePart") then
				character:PivotTo(promptPart.CFrame * CFrame.new(0, math.max(4, promptPart.Size.Y * 0.5 + 3), 0))
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				task.wait(0.12)
			end
			if type(fireproximityprompt) == "function" then
				pcall(fireproximityprompt, prompt)
			end
		elseif not pending then
			return true
		end
		task.wait(0.1)
	end
	return false
end

local function ensureBossSequence(boss)
	local sequence
	if isHalloweenBoss(boss) then
		sequence = boss
	else
		sequence = "BossEvent:" .. tostring(math.floor(tonumber(workspace:GetAttribute("BossSpawnSequence")) or 0))
	end
	if State.sequence ~= sequence then
		State.sequence = sequence
		State.hits = 0
		State.damage = 0
		State.lastConfirmedAttackAt = 0
	end
end

local function fightBoss(boss)
	ensureBossSequence(boss)
	local battleGeneration = State.generation
	if not beginBattle(boss) then
		return
	end
	setStatus("Entrando al combate...", CONFIG.Colors.cyan)
	local lastAttack = 0
	local lastPlayerHealth
	local emergencyUntil = 0
	local contactCandidates
	local contactIndex = 1
	local contactMisses = 0
	local contactChangedAt = 0
	local observedHits = State.hits
	local unsafeContacts = {}
	local safeAttackPosition
	local floatLockConnection
	local floatPosition
	if isHalloweenBoss(boss) then
		local root = getRoot()
		if root then
			floatPosition = Instance.new("BodyPosition")
			floatPosition.Name = "Young0xBossFloatLock"
			floatPosition.MaxForce = Vector3.new(1e9, 1e9, 1e9)
			floatPosition.P = 1e9
			floatPosition.D = 1e7
			floatPosition.Position = root.Position
			floatPosition.Parent = root
			if State.transitionFloatPosition then
				State.transitionFloatPosition:Destroy()
				State.transitionFloatPosition = nil
			end
			root.Anchored = false
		end
		floatLockConnection = RunService.PostSimulation:Connect(function()
			local root = getRoot()
			if State.running and State.active and State.generation == battleGeneration
				and State.engagedBoss == boss and root then
				root.Anchored = false
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
		end)
	end

	local function buildContacts(profile, part, target)
		local result = {}
		local seen = {}
		local function add(value)
			value = math.floor((tonumber(value) or 0) * 10 + 0.5) / 10
			if not seen[value] then
				seen[value] = true
				result[#result + 1] = value
			end
		end
		for _, value in ipairs(type(profile.contactHeights) == "table" and profile.contactHeights or {}) do
			add(value)
		end
		if #result == 0 then
			add(profile.contactHeight)
			add(math.clamp(part.Size.Y * 0.35, 35, profile.maxHitDistance * 0.55))
			add(-math.clamp(part.Size.Y * 0.16, 18, 40))
			add(math.clamp(target.Size.Y * 0.30, 30, profile.maxHitDistance * 0.50))
		end
		return result
	end

	local function nextContact(now)
		if not contactCandidates or #contactCandidates <= 1 then
			return
		end
		for _ = 1, #contactCandidates do
			contactIndex = contactIndex % #contactCandidates + 1
			if (unsafeContacts[contactCandidates[contactIndex]] or 0) <= now then
				break
			end
		end
		contactMisses = 0
		contactChangedAt = now
		safeAttackPosition = nil
	end

	while State.running and State.active and State.generation == battleGeneration and isBossAvailable(boss) do
		local currentBoss, part, target = findBoss(boss)
		if currentBoss ~= boss or not part or not target then
			break
		end
		local character = getCharacter()
		local root = getRoot()
		local humanoid = getHumanoid()
		local punch = equipPunch()
		if not character or not root or not humanoid or humanoid.Health <= 0 or not punch then
			setStatus("Esperando personaje o Punch...", CONFIG.Colors.pink)
			task.wait(0.25)
		else
			local now = os.clock()
			if lastPlayerHealth and humanoid.Health < lastPlayerHealth then
				emergencyUntil = now + 2.4
				if contactCandidates then
					unsafeContacts[contactCandidates[contactIndex]] = now + 10
					nextContact(now)
				end
			end
			lastPlayerHealth = humanoid.Health
			local profile = getBossProfile(boss)
			if not contactCandidates then
				contactCandidates = buildContacts(profile, part, target)
				contactChangedAt = now
				observedHits = State.hits
			end
			if State.hits > observedHits then
				observedHits = State.hits
				contactMisses = 0
			elseif contactMisses >= 12 and now - contactChangedAt >= 3.5 then
				nextContact(now)
			end

			local attackKind = boss:GetAttribute("BossAttackKind")
			local impactTime = boss:GetAttribute("BossAttackImpactTime")
			local serverNow = workspace:GetServerTimeNow()
			local networkLead = 0
			pcall(function()
				networkLead = math.clamp(LocalPlayer:GetNetworkPing() * 0.9, 0, 0.35)
			end)
			local telegraphedDodge = (attackKind == "Punch" or attackKind == "Stomp")
				and typeof(impactTime) == "number"
				and serverNow >= impactTime - (profile.dodgeLead + networkLead)
				and serverNow <= impactTime + 0.4
			local halloweenBoss = isHalloweenBoss(boss)
			local impactImminent = halloweenBoss and telegraphedDodge
			local canAttack = now >= emergencyUntil and now >= State.contactReadyAt
				and now - lastAttack >= State.hitInterval
				and (halloweenBoss and not impactImminent or not halloweenBoss and not telegraphedDodge)
			local rootHalfHeight = root.Size.Y * 0.5
			local safeRootY = getArenaFloorY(boss, root) + rootHalfHeight + 1.5
			local attackPosition
			if now < emergencyUntil or halloweenBoss and not canAttack
				or not halloweenBoss and telegraphedDodge then
				attackPosition = getBossDodgePosition(boss, part, target, root,
					now < emergencyUntil or attackKind ~= "Punch" or isHalloweenBoss(boss))
				safeAttackPosition = nil
			else
				local contactHeight = contactCandidates[contactIndex]
				State.currentContactHeight = contactHeight
				local desired = part.Position + Vector3.yAxis * contactHeight
				desired = Vector3.new(desired.X, math.max(desired.Y, safeRootY), desired.Z)
				if not safeAttackPosition or (desired - safeAttackPosition).Magnitude > 45 then
					safeAttackPosition = desired
				else
					safeAttackPosition = safeAttackPosition:Lerp(desired, isHalloweenBoss(boss) and 0.55 or 0.16)
				end
				attackPosition = safeAttackPosition
			end
			attackPosition = Vector3.new(attackPosition.X, math.max(attackPosition.Y, safeRootY), attackPosition.Z)
			if not State.active or State.generation ~= battleGeneration then
				break
			end
			character:PivotTo(CFrame.lookAt(attackPosition, part.Position))
			if floatPosition and floatPosition.Parent == root then
				floatPosition.Position = root.Position
			end
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			if canAttack then
				lastAttack = now
				State.lastAttackAt = now
				pcall(punch.Deactivate, punch)
				pcall(punch.Activate, punch)
				firePunchRemotes()
				contactMisses += 1
			end
			setStatus("Atacando " .. getBossDisplayName(boss), CONFIG.Colors.green)
			refreshBossStats()
			task.wait(0.04)
		end
	end
	if floatLockConnection then
		floatLockConnection:Disconnect()
	end
	if floatPosition then
		floatPosition:Destroy()
	end

	local defeated = not isBossAvailable(boss) or getBossHealth(boss) <= 0
	if defeated and State.running and State.active then
		if isHalloweenBoss(boss) then
			setStatus("Boss derrotado · recompensa automática", CONFIG.Colors.green)
		else
			setStatus("Boss derrotado · reclamando cofre", CONFIG.Colors.green)
			collectChest(12)
		end
	end
	if State.generation == battleGeneration then
		local halloweenBoss = isHalloweenBoss(boss)
		local originalAnchored = State.originalRootAnchored
		restoreBattle(not halloweenBoss)
		if halloweenBoss and State.active then
			lockTransitionRoot(originalAnchored)
		end
	end
end

local function setActive(enabled)
	State.generation += 1
	local generation = State.generation
	State.active = enabled == true
	State.lastRuntimeError = nil
	setToggleVisual(State.active)
	if not State.active then
		setStatus("", CONFIG.Colors.cyan)
		restoreSessionOrigin()
		refreshBossStats()
		return true
	end
	if game.PlaceId ~= CONFIG.PlaceId then
		State.active = false
		setToggleVisual(false)
		setStatus("Este script es para Muscle Legends", CONFIG.Colors.red)
		return false
	end
	if not loadBossConfig() then
		State.active = false
		setToggleVisual(false)
		setStatus("El evento del boss no está disponible", CONFIG.Colors.red)
		return false
	end
	captureSessionOrigin()
	State.sessionRestoreToken += 1
	refreshBossStats()
	task.spawn(function()
		local ok, runtimeError = pcall(function()
			if not prepareTargetMap(generation) then
				return
			end
			while State.running and State.active and State.generation == generation do
				if LocalPlayer:GetAttribute("BossChestPending") == true then
					setStatus("Reclamando cofre pendiente...", CONFIG.Colors.cyan)
					collectChest(12)
				else
					local boss = findBoss()
					if boss then
						ensureBossSequence(boss)
						fightBoss(boss)
					else
						setStatus("Esperando boss...", CONFIG.Colors.cyan)
						task.wait(0.4)
					end
				end
			end
		end)
		if not ok and State.running and State.generation == generation then
			State.lastRuntimeError = tostring(runtimeError)
			State.active = false
			State.generation += 1
			setToggleVisual(false)
			setStatus("Error de compatibilidad", CONFIG.Colors.red)
			restoreSessionOrigin()
			refreshBossStats()
		elseif State.generation == generation then
			restoreBattle()
		end
	end)
	return true
end

local applyTargetLayout

local function setTargetMode(targetMode)
	if not TargetOptionById[targetMode] or State.targetMode == targetMode then
		return false
	end
	local wasActive = State.active
	if wasActive then
		local originalAnchored = State.originalRootAnchored
		State.active = false
		State.generation += 1
		restoreBattle(false)
		lockTransitionRoot(originalAnchored)
	end
	State.targetMode = targetMode
	if targetMode ~= "Beach" then
		State.lastHalloweenTarget = targetMode
	end
	State.sequence = nil
	State.hits = 0
	State.damage = 0
	Environment.Young0xAutoBossTargetMode = targetMode
	setTargetVisual()
	if applyTargetLayout then
		applyTargetLayout()
	end
	refreshBossStats()
	if wasActive and State.running then
		setActive(true)
	end
	return true
end

local damageEvents = ReplicatedStorage:FindFirstChild("rEvents")
local damageRemote = damageEvents and damageEvents:FindFirstChild("guiDamageEvent")
if damageRemote and damageRemote:IsA("RemoteEvent") then
	track(damageRemote.OnClientEvent:Connect(function(kind, boss, amount, hitPosition)
		if kind ~= "bossDamageShow" or typeof(amount) ~= "number" or not State.engagedBoss then
			return
		end
		if typeof(boss) == "Instance" and boss ~= State.engagedBoss then
			return
		end
		if os.clock() - State.lastAttackAt > 0.55 then
			return
		end
		State.damage += math.max(0, amount)
		State.hits += 1
		refreshBossStats()
	end))
end

track(ToggleHitbox.Activated:Connect(function()
	setActive(not State.active)
end))

for id, entry in pairs(ModeButtons) do
	local targetType = id
	track(entry.button.Activated:Connect(function()
		setTargetMode(targetType == "Beach" and "Beach" or State.lastHalloweenTarget)
	end))
	track(entry.button.MouseEnter:Connect(function()
		local selected = (targetType == "Beach" and State.targetMode == "Beach")
			or (targetType == "Halloween" and State.targetMode ~= "Beach")
		if not selected then
			TweenService:Create(entry.button, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
				TextColor3 = targetType == "Beach" and CONFIG.Colors.halloweenViolet or CONFIG.Colors.halloweenOrange,
			}):Play()
		end
	end))
	track(entry.button.MouseLeave:Connect(setTargetVisual))
end

for id, entry in pairs(TargetButtons) do
	local targetMode = id
	track(entry.button.Activated:Connect(function()
		setTargetMode(targetMode)
	end))
	track(entry.button.MouseEnter:Connect(function()
		if State.targetMode ~= targetMode then
			TweenService:Create(entry.button, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
				TextColor3 = TargetAccentById[targetMode] or CONFIG.Colors.halloweenOrange,
			}):Play()
		end
	end))
	track(entry.button.MouseLeave:Connect(setTargetVisual))
end

local MINIMIZED_HEIGHT = 56
local copyStatusSerial = 0
local copyStatusShown = false
local desiredPosition = Main.Position
local minimizeTween
local layoutTweening = false

local function currentBaseHeight()
	return BEACH_HEIGHT + (State.targetMode ~= "Beach" and HALLOWEEN_EXTRA_HEIGHT or 0)
end

local function currentExpandedHeight()
	return currentBaseHeight() + (copyStatusShown and COPY_EXTRA_HEIGHT or 0)
end

local function clampMainPosition(position, height)
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local canvasPosition = ScreenGui.AbsolutePosition
	local canvasSize = ScreenGui.AbsoluteSize
	local scale = math.max(0.01, Scale.Scale)
	local width = 360 * scale
	local scaledHeight = (height or Main.Size.Y.Offset) * scale
	local margin = UserInputService.TouchEnabled and 12 or 8
	local minX = margin + width * 0.5
	local maxX = viewport.X - margin - width * 0.5
	local minY = margin + scaledHeight * 0.5
	local maxY = viewport.Y - margin - scaledHeight * 0.5
	local centerX = canvasPosition.X + canvasSize.X * position.X.Scale + position.X.Offset
	local centerY = canvasPosition.Y + canvasSize.Y * position.Y.Scale + position.Y.Offset
	if minX > maxX then
		centerX = viewport.X * 0.5
	else
		centerX = math.clamp(centerX, minX, maxX)
	end
	if minY > maxY then
		centerY = viewport.Y * 0.5
	else
		centerY = math.clamp(centerY, minY, maxY)
	end
	return UDim2.new(
		position.X.Scale,
		centerX - canvasPosition.X - canvasSize.X * position.X.Scale,
		position.Y.Scale,
		centerY - canvasPosition.Y - canvasSize.Y * position.Y.Scale
	)
end

local function tweenMainHeight(targetHeight)
	if minimizeTween then
		minimizeTween:Cancel()
	end
	local currentHeight = Main.Size.Y.Offset
	local currentPosition = Main.Position
	desiredPosition = UDim2.new(
		currentPosition.X.Scale,
		currentPosition.X.Offset,
		currentPosition.Y.Scale,
		currentPosition.Y.Offset + (targetHeight - currentHeight) * 0.5
	)
	desiredPosition = clampMainPosition(desiredPosition, targetHeight)
	layoutTweening = true
	minimizeTween = TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(360, targetHeight),
		Position = desiredPosition,
	})
	minimizeTween:Play()
	minimizeTween.Completed:Connect(function()
		layoutTweening = false
	end)
end

applyTargetLayout = function()
	local halloween = State.targetMode ~= "Beach"
	local offset = halloween and HALLOWEEN_EXTRA_HEIGHT or 0
	HalloweenCard.Visible = halloween
	local info = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(HealthCard, info, { Position = UDim2.fromOffset(18, 122 + offset) }):Play()
	TweenService:Create(DiscordButton, info, { Position = UDim2.new(0.5, -34, 0, 246 + offset) }):Play()
	TweenService:Create(YouTubeButton, info, { Position = UDim2.new(0.5, 34, 0, 246 + offset) }):Play()
	TweenService:Create(CopyStatus, info, { Position = UDim2.fromOffset(18, 288 + offset) }):Play()
	TweenService:Create(CloseButton, info, {
		Position = UDim2.new(0.5, 0, 0, 290 + offset + (copyStatusShown and COPY_EXTRA_HEIGHT or 0)),
	}):Play()
	if not State.minimized then
		tweenMainHeight(currentExpandedHeight())
	end
	refreshScale()
end

local function copyLink(button, url)
	local copier = Environment.setclipboard or Environment.toclipboard or setclipboard or toclipboard
	local ok = false
	if type(copier) == "function" then
		ok = pcall(copier, url)
	end
	copyStatusSerial += 1
	local serial = copyStatusSerial
	CopyStatus.Text = ok and "Link Copiado" or "No se pudo copiar"
	CopyStatus.TextColor3 = ok and CONFIG.Colors.green or CONFIG.Colors.pink
	CopyStatus.TextTransparency = 1
	CopyStatus.Visible = true
	copyStatusShown = true
	TweenService:Create(CopyStatus, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()
	TweenService:Create(CloseButton, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 290
			+ (State.targetMode ~= "Beach" and HALLOWEEN_EXTRA_HEIGHT or 0)
			+ COPY_EXTRA_HEIGHT),
	}):Play()
	if not State.minimized then
		tweenMainHeight(currentExpandedHeight())
	end
	task.delay(2, function()
		if State.running and button.Parent and copyStatusSerial == serial then
			TweenService:Create(CopyStatus, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				TextTransparency = 1,
			}):Play()
			task.delay(0.14, function()
				if State.running and CopyStatus.Parent and copyStatusSerial == serial then
					copyStatusShown = false
					CopyStatus.Visible = false
					TweenService:Create(CloseButton, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Position = UDim2.new(0.5, 0, 0, 290
							+ (State.targetMode ~= "Beach" and HALLOWEEN_EXTRA_HEIGHT or 0)),
					}):Play()
					if not State.minimized then
						tweenMainHeight(currentBaseHeight())
					end
				end
			end)
		end
	end)
end

track(DiscordButton.MouseButton1Click:Connect(function()
	copyLink(DiscordButton, CONFIG.Discord)
end))
track(YouTubeButton.MouseButton1Click:Connect(function()
	copyLink(YouTubeButton, CONFIG.YouTube)
end))

for _, entry in ipairs({
	{ button = DiscordButton, scale = DiscordScale },
	{ button = YouTubeButton, scale = YouTubeScale },
}) do
	track(entry.button.MouseEnter:Connect(function()
		TweenService:Create(entry.scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = 1.12 }):Play()
	end))
	track(entry.button.MouseLeave:Connect(function()
		TweenService:Create(entry.scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
	end))
end

track(CloseButton.MouseEnter:Connect(function()
	TweenService:Create(CloseScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { Scale = 1.1 }):Play()
	TweenService:Create(CloseButton, TweenInfo.new(0.14), { TextColor3 = CONFIG.Colors.red }):Play()
end))

track(CloseButton.MouseLeave:Connect(function()
	TweenService:Create(CloseScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
	TweenService:Create(CloseButton, TweenInfo.new(0.14), { TextColor3 = CONFIG.Colors.dim }):Play()
end))

track(CloseButton.MouseButton1Click:Connect(function()
	Controller:Destroy()
end))

local function setMinimized(value)
	if State.minimized == value then
		return
	end
	State.minimized = value
	if not value then
		Body.Visible = true
	end
	local targetHeight = value and MINIMIZED_HEIGHT or currentExpandedHeight()
	tweenMainHeight(targetHeight)
	if value then
		task.delay(0.16, function()
			if State.running and State.minimized then
				Body.Visible = false
			end
		end)
	end
end

local dragging = false
local dragInput
local dragStart
local frameStart
local dragDistance = 0

track(Header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		frameStart = Main.Position
		dragDistance = 0
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end))

track(Header.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end))

track(UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput and dragStart and frameStart then
		local delta = input.Position - dragStart
		dragDistance = delta.Magnitude
		desiredPosition = clampMainPosition(UDim2.new(
			frameStart.X.Scale,
			frameStart.X.Offset + delta.X,
			frameStart.Y.Scale,
			frameStart.Y.Offset + delta.Y
		))
	end
end))

track(Header.Activated:Connect(function()
	if dragDistance < 8 then
		setMinimized(not State.minimized)
	end
end))

track(RunService.RenderStepped:Connect(function(deltaTime)
	if not layoutTweening then
		desiredPosition = clampMainPosition(desiredPosition)
		local alpha = 1 - math.exp(-math.max(0, deltaTime) * 18)
		Main.Position = Main.Position:Lerp(desiredPosition, alpha)
	end
	Main.Position = clampMainPosition(Main.Position)
end))

local viewportConnection
local function refreshViewport()
	refreshScale()
	desiredPosition = clampMainPosition(desiredPosition)
	if not layoutTweening then
		Main.Position = clampMainPosition(Main.Position)
	end
end

local function bindCamera()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = track(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			refreshViewport()
		end))
	end
	refreshViewport()
end

track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	bindCamera()
end))
bindCamera()

task.spawn(function()
	while State.running do
		refreshBossStats()
		task.wait(0.25)
	end
end)

function Controller:SetEnabled(enabled)
	return setActive(enabled)
end

function Controller:IsEnabled()
	return State.active
end

function Controller:SetTargetMode(targetMode)
	return setTargetMode(targetMode)
end

function Controller:GetTargetMode()
	return State.targetMode, getEffectiveTargetMode()
end

function Controller:GetLastError()
	return State.lastRuntimeError
end

function Controller:Destroy()
	if not State.running then
		return
	end
	State.running = false
	State.active = false
	State.generation += 1
	restoreSessionOrigin()
	titleColorTween:Cancel()
	subtitleColorTween:Cancel()
	for index = #connections, 1, -1 do
		pcall(function()
			connections[index]:Disconnect()
		end)
		connections[index] = nil
	end
	if ScreenGui then
		ScreenGui:Destroy()
	end
	if Environment.Young0xAutoBoss == self then
		Environment.Young0xAutoBoss = nil
	end
end

Controller.State = State
Environment.Young0xAutoBoss = Controller

setToggleVisual(false)
refreshBossStats()
