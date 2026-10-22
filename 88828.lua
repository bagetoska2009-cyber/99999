-- BAGGET SCRIPTS v19.2 [ADMIN & TROLLING SUITE]
-- Fixed: Spinbot (AutoRotate & elseif conflict fixed)
-- Removed: Broken Sandbox-only part manipulators
-- Added: Interactive Player/Bot Selector List with instant TP & Search

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local Camera = workspace.CurrentCamera

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local Mouse = LP:GetMouse()

-- Безопасная очистка предыдущей сессии при перезапуске
if _G.BaggetCleanup then
	pcall(_G.BaggetCleanup)
end

local Connections = {}
local SpawnedParts = {}

local function bindConnection(signal, callback)
	local conn = signal:Connect(callback)
	table.insert(Connections, conn)
	return conn
end

local function trackPart(p)
	table.insert(SpawnedParts, p)
	return p
end

-- Сохранение стандартных настроек мира
local OrigWorld = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient,
	Gravity = workspace.Gravity,
	FOV = Camera.FieldOfView,
	MaxZoom = LP.CameraMaxZoomDistance
}

-- Палитра Кибер-Стиля
local GREEN = Color3.fromRGB(0, 255, 115)
local DARK_GREEN = Color3.fromRGB(0, 105, 48)
local BLACK = Color3.fromRGB(6, 6, 9)
local PANEL_BG = Color3.fromRGB(10, 12, 16)
local CAT_BG = Color3.fromRGB(14, 24, 19)
local ELEM_BG = Color3.fromRGB(18, 20, 27)
local TXT = Color3.fromRGB(220, 235, 225)
local RED = Color3.fromRGB(235, 55, 55)

-- Конфигурация параметров
local CFG = {
	Speed = 16,
	Jump = 50,
	FlySpeed = 65,
	FreecamSpeed = 50,
	SpinSpeed = 35,
	DashPower = 95,
	SpiderSpeed = 35,
	JetpackPower = 45,
	Gravity = math.floor(workspace.Gravity),
	HitboxSize = 6,
	HeadScale = 4,
	CameraFOV = 70,
	WorldTime = 14,
	XRayAlpha = 0.5,
	
	OrbitRadius = 8,
	OrbitSpeed = 4,
	FlingPower = 8500,
	
	TargetPlayers = true,
	TargetBots = true,
	
	ESP_MaxDist = 1500,
	Tracer_MaxDist = 1500,
	Aim_MaxDist = 1500,
	Skeleton_MaxDist = 1500,
	RadarRange = 250,
	
	ESP_WallCheck = false,
	Tracer_WallCheck = false,
	Aim_WallCheck = false,
	Skeleton_WallCheck = false,
	
	ESP_TeamCheck = false,
	TracerTeamCheck = false,
	AimTeamCheck = false,
	SkeletonTeamCheck = false,
	
	AimPart = "Head",
	AimSmoothness = 4,
	AimFOV = 150,
	ShowFOV = false,
	AimPrediction = true,
	PredictionFactor = 0.12,
	
	AuraRate = 30,
	TrailLength = 0.6,
	
	Color_PlayerVisible = Color3.fromRGB(0, 255, 115),
	Color_PlayerHidden = Color3.fromRGB(0, 90, 35),
	Color_BotVisible = Color3.fromRGB(255, 165, 0),
	Color_BotHidden = Color3.fromRGB(120, 60, 0),
}

-- Состояния модулей
local S = {
	TelemetryHUD = true,
	RadarHUD = false,
	PartInspector = false,
	
	SpeedLock = false,
	AutoBhop = false,
	InfiniteJump = false,
	Jetpack = false,
	SpiderClimb = false,
	FreezeChar = false,
	Noclip = false,
	AntiFling = false,
	AntiVoid = true,
	Fly = false,
	Freecam = false,
	AirWalk = false,
	Spinbot = false,
	CtrlClickTP = false,
	
	-- Троллинг
	FlingTouch = false,
	OrbitTarget = false,
	HeadSit = false,
	MimicTarget = false,
	SpectateTarget = false,
	FakeLag = false,
	headlessVisual = false,
	
	-- Визуал и ESP
	ESP = false,
	BoxESP = false,
	HealthESP = false,
	NameESP = false,
	LookLaserESP = false,
	Tracers = false,
	Skeleton = false,
	
	-- Боевые
	Aimbot = false,
	TriggerIndicator = false,
	TargetHUD = true,
	HitboxExpander = false,
	BigHeads = false,
	
	-- Локальные эффекты (Client FX)
	Pulse = false,
	Aura = false,
	Halo = false,
	ChinaHat = false,
	OrbitOrbs = false,
	CyberShield = false,
	CyberWings = false,
	GyroRings = false,
	LightningFX = false,
	GhostTrail = false,
	StepWaves = false,
	Trail = false,
	
	-- Камера и Мир
	Crosshair = false,
	InfiniteZoom = false,
	CustomFOV = false,
	Fullbright = false,
	XRay = false,
	TimeChanger = false,
	RainbowMode = false
}

local Keybinds = {}
local bindingFeatureName = nil
local currentThemeColor = GREEN
_G.BaggetBinds = {}

-- Вспомогательные функции персонажа
local function getChar() return LP.Character end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot()
	local c = getChar()
	return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c.PrimaryPart)
end

local function isTeammate(p)
	if not p or not p:IsA("Player") then return false end
	if p == LP then return true end
	if LP.Team and p.Team and LP.Team == p.Team then return true end
	return false
end

local function checkDistance(targetRoot, maxDist)
	local root = getRoot()
	if not root or not targetRoot then return false end
	return (root.Position - targetRoot.Position).Magnitude <= maxDist
end

local function getGroundOffset()
	local h = getHum()
	local r = getRoot()
	if not h or not r then return 3.2 end
	if h.RigType == Enum.HumanoidRigType.R6 then
		return 3.05
	else
		return (h.HipHeight > 0 and h.HipHeight or 2) + (r.Size.Y * 0.5) + 0.15
	end
end

-- ==========================================
-- КЭШ ТЕХНОЛОГИЯ NPC И ЦЕЛЕЙ
-- ==========================================
local trackedBots = {}
local cachedTargetsList = {}
local lastTargetUpdate = 0

local function registerBotModel(model)
	if model and model:IsA("Model") and model ~= getChar() and not Players:GetPlayerFromCharacter(model) then
		local hum = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model.PrimaryPart
		if hum and root then
			trackedBots[model] = {Model = model, Humanoid = hum, RootPart = root}
		end
	end
end

task.spawn(function()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Humanoid") and obj.Parent then
			registerBotModel(obj.Parent)
		end
	end
end)

bindConnection(workspace.DescendantAdded, function(obj)
	if obj:IsA("Humanoid") then
		task.wait(0.1)
		if obj.Parent then registerBotModel(obj.Parent) end
	end
end)

bindConnection(workspace.DescendantRemoving, function(obj)
	if obj:IsA("Model") and trackedBots[obj] then
		trackedBots[obj] = nil
	end
end)

local function getValidTargets(checkTeamForMode)
	local now = tick()
	if now - lastTargetUpdate > 0.1 then
		lastTargetUpdate = now
		table.clear(cachedTargetsList)
		if CFG.TargetPlayers then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LP then
					local c = p.Character
					if c then
						local hum = c:FindFirstChildOfClass("Humanoid")
						local root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c.PrimaryPart
						if hum and root and hum.Health > 0 then
							table.insert(cachedTargetsList, {
								Model = c,
								Player = p,
								IsPlayer = true,
								Humanoid = hum,
								RootPart = root,
								Name = p.DisplayName ~= p.Name and (p.DisplayName .. " (@" .. p.Name .. ")") or p.Name,
								ShortName = p.DisplayName or p.Name
							})
						end
					end
				end
			end
		end
		if CFG.TargetBots then
			for model, data in pairs(trackedBots) do
				if model and model.Parent and data.Humanoid and data.Humanoid.Health > 0 and data.RootPart then
					if model ~= getChar() then
						table.insert(cachedTargetsList, {
							Model = model,
							Player = nil,
							IsPlayer = false,
							Humanoid = data.Humanoid,
							RootPart = data.RootPart,
							Name = "[BOT] " .. model.Name,
							ShortName = model.Name
						})
					end
				else
					trackedBots[model] = nil
				end
			end
		end
	end

	if not checkTeamForMode then
		return cachedTargetsList
	end

	local filtered = {}
	for _, t in ipairs(cachedTargetsList) do
		if not (t.IsPlayer and isTeammate(t.Player)) then
			table.insert(filtered, t)
		end
	end
	return filtered
end

-- Оптимизированный Raycast Cache
local visibilityCache = {}
local lastCachePurge = tick()
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

local function isVisible(targetPart)
	if not targetPart or not targetPart.Parent then return false end
	local now = tick()
	if now - lastCachePurge > 15 then
		table.clear(visibilityCache)
		lastCachePurge = now
	end
	
	local cached = visibilityCache[targetPart]
	if cached and (now - cached.time < 0.15) then return cached.status end

	local char = getChar()
	if not char then return false end
	
	raycastParams.FilterDescendantsInstances = {char, Camera}
	local origin = Camera.CFrame.Position
	local direction = (targetPart.Position - origin)
	
	local result = workspace:Raycast(origin, direction, raycastParams)
	local visible = true
	if result and not result.Instance:IsDescendantOf(targetPart.Parent) then
		visible = false
	end
	
	visibilityCache[targetPart] = {status = visible, time = now}
	return visible
end

-- ==========================================
-- ИНТЕРФЕЙС И UI СЛОИ
-- ==========================================
local old = PG:FindFirstChild("BaggetUI")
if old then old:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "BaggetUI"
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.DisplayOrder = 99999
SG.Parent = PG

local DrawLayer = Instance.new("Frame")
DrawLayer.Name = "DrawLayer"
DrawLayer.Size = UDim2.new(1, 0, 1, 0)
DrawLayer.BackgroundTransparency = 1
DrawLayer.Active = false
DrawLayer.Parent = SG

-- Live Telemetry HUD
local TelemetryBar = Instance.new("Frame")
TelemetryBar.Size = UDim2.new(0, 560, 0, 26)
TelemetryBar.AnchorPoint = Vector2.new(0.5, 0)
TelemetryBar.Position = UDim2.new(0.5, 0, 0, 8)
TelemetryBar.BackgroundColor3 = PANEL_BG
TelemetryBar.BackgroundTransparency = 0.15
TelemetryBar.BorderSizePixel = 1
TelemetryBar.BorderColor3 = GREEN
TelemetryBar.Parent = DrawLayer
Instance.new("UICorner", TelemetryBar).CornerRadius = UDim.new(0, 5)

local TelemetryText = Instance.new("TextLabel", TelemetryBar)
TelemetryText.Size = UDim2.new(1, -12, 1, 0)
TelemetryText.Position = UDim2.new(0, 6, 0, 0)
TelemetryText.BackgroundTransparency = 1
TelemetryText.Text = "FPS: 60 | SPD: 0 | POS: (0, 0, 0) | ENTITIES: 0"
TelemetryText.TextColor3 = GREEN
TelemetryText.Font = Enum.Font.Code
TelemetryText.TextSize = 11

-- Инспектор деталей (Part Inspector HUD)
local InspectorFrame = Instance.new("Frame")
InspectorFrame.Size = UDim2.new(0, 260, 0, 68)
InspectorFrame.Position = UDim2.new(1, -275, 0, 45)
InspectorFrame.BackgroundColor3 = PANEL_BG
InspectorFrame.BackgroundTransparency = 0.15
InspectorFrame.BorderSizePixel = 1
InspectorFrame.BorderColor3 = GREEN
InspectorFrame.Visible = false
InspectorFrame.Parent = DrawLayer
Instance.new("UICorner", InspectorFrame).CornerRadius = UDim.new(0, 5)

local InspectorText = Instance.new("TextLabel", InspectorFrame)
InspectorText.Size = UDim2.new(1, -12, 1, -8)
InspectorText.Position = UDim2.new(0, 6, 0, 4)
InspectorText.BackgroundTransparency = 1
InspectorText.TextColor3 = TXT
InspectorText.Font = Enum.Font.Code
InspectorText.TextSize = 10
InspectorText.TextXAlignment = Enum.TextXAlignment.Left
InspectorText.TextYAlignment = Enum.TextYAlignment.Top
InspectorText.Text = "PART INSPECTOR:\nHover over any object..."

-- 360 Radar HUD
local RadarFrame = Instance.new("Frame")
RadarFrame.Size = UDim2.new(0, 150, 0, 150)
RadarFrame.Position = UDim2.new(0, 18, 0, 45)
RadarFrame.BackgroundColor3 = PANEL_BG
RadarFrame.BackgroundTransparency = 0.2
RadarFrame.BorderSizePixel = 1
RadarFrame.BorderColor3 = GREEN
RadarFrame.Visible = false
RadarFrame.ClipsDescendants = true
RadarFrame.Parent = DrawLayer
Instance.new("UICorner", RadarFrame).CornerRadius = UDim.new(1, 0)
local radarStroke = Instance.new("UIStroke", RadarFrame)
radarStroke.Color = GREEN
radarStroke.Thickness = 1.5

local radarCrossX = Instance.new("Frame", RadarFrame)
radarCrossX.Size = UDim2.new(1, 0, 0, 1)
radarCrossX.Position = UDim2.new(0, 0, 0.5, 0)
radarCrossX.BackgroundColor3 = DARK_GREEN
radarCrossX.BorderSizePixel = 0

local radarCrossY = Instance.new("Frame", RadarFrame)
radarCrossY.Size = UDim2.new(0, 1, 1, 0)
radarCrossY.Position = UDim2.new(0.5, 0, 0, 0)
radarCrossY.BackgroundColor3 = DARK_GREEN
radarCrossY.BorderSizePixel = 0

local radarCenter = Instance.new("Frame", RadarFrame)
radarCenter.Size = UDim2.new(0, 5, 0, 5)
radarCenter.AnchorPoint = Vector2.new(0.5, 0.5)
radarCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
radarCenter.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", radarCenter).CornerRadius = UDim.new(1, 0)

local radarDotsPool = {}

-- FOV Круг
local FOVFrame = Instance.new("Frame")
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Visible = false
FOVFrame.Parent = DrawLayer
Instance.new("UICorner", FOVFrame).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", FOVFrame)
fovStroke.Color = GREEN
fovStroke.Thickness = 1.3
fovStroke.Transparency = 0.25

-- Кастомный вращающийся кибер-прицел
local CustomCrosshair = Instance.new("Frame")
CustomCrosshair.Name = "CustomCrosshair"
CustomCrosshair.Size = UDim2.new(0, 24, 0, 24)
CustomCrosshair.AnchorPoint = Vector2.new(0.5, 0.5)
CustomCrosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
CustomCrosshair.BackgroundTransparency = 1
CustomCrosshair.Visible = false
CustomCrosshair.Parent = DrawLayer

local chDot = Instance.new("Frame", CustomCrosshair)
chDot.Size = UDim2.new(0, 4, 0, 4)
chDot.AnchorPoint = Vector2.new(0.5, 0.5)
chDot.Position = UDim2.new(0.5, 0, 0.5, 0)
chDot.BackgroundColor3 = GREEN
chDot.BorderSizePixel = 0
Instance.new("UICorner", chDot).CornerRadius = UDim.new(1, 0)

local chLines = {}
local lineOffsets = {
	{UDim2.new(0, 2, 0, 7), UDim2.new(0.5, 0, 0, 2)},
	{UDim2.new(0, 2, 0, 7), UDim2.new(0.5, 0, 1, -2)},
	{UDim2.new(0, 7, 0, 2), UDim2.new(0, 2, 0.5, 0)},
	{UDim2.new(0, 7, 0, 2), UDim2.new(1, -2, 0.5, 0)},
}
for _, data in ipairs(lineOffsets) do
	local l = Instance.new("Frame", CustomCrosshair)
	l.Size = data[1]
	l.Position = data[2]
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.BackgroundColor3 = GREEN
	l.BorderSizePixel = 0
	table.insert(chLines, l)
end

-- Target HUD
local TargetHUDFrame = Instance.new("Frame")
TargetHUDFrame.Size = UDim2.new(0, 220, 0, 56)
TargetHUDFrame.AnchorPoint = Vector2.new(0.5, 0)
TargetHUDFrame.Position = UDim2.new(0.5, 0, 0.5, 45)
TargetHUDFrame.BackgroundColor3 = PANEL_BG
TargetHUDFrame.BackgroundTransparency = 0.15
TargetHUDFrame.BorderSizePixel = 1
TargetHUDFrame.BorderColor3 = GREEN
TargetHUDFrame.Visible = false
TargetHUDFrame.Parent = DrawLayer
Instance.new("UICorner", TargetHUDFrame).CornerRadius = UDim.new(0, 6)

local thudTitle = Instance.new("TextLabel", TargetHUDFrame)
thudTitle.Size = UDim2.new(1, -16, 0, 18)
thudTitle.Position = UDim2.new(0, 8, 0, 4)
thudTitle.BackgroundTransparency = 1
thudTitle.Text = "TARGET: NONE"
thudTitle.TextColor3 = GREEN
thudTitle.Font = Enum.Font.Code
thudTitle.TextSize = 12
thudTitle.TextXAlignment = Enum.TextXAlignment.Left
thudTitle.TextTruncate = Enum.TextTruncate.AtEnd

local thudSub = Instance.new("TextLabel", TargetHUDFrame)
thudSub.Size = UDim2.new(1, -16, 0, 14)
thudSub.Position = UDim2.new(0, 8, 0, 21)
thudSub.BackgroundTransparency = 1
thudSub.Text = "HP: 100/100 | DIST: 0m"
thudSub.TextColor3 = TXT
thudSub.Font = Enum.Font.Code
thudSub.TextSize = 10
thudSub.TextXAlignment = Enum.TextXAlignment.Left

local thudBarBG = Instance.new("Frame", TargetHUDFrame)
thudBarBG.Size = UDim2.new(1, -16, 0, 8)
thudBarBG.Position = UDim2.new(0, 8, 0, 40)
thudBarBG.BackgroundColor3 = BLACK
thudBarBG.BorderSizePixel = 0
Instance.new("UICorner", thudBarBG).CornerRadius = UDim.new(0, 3)

local thudBarFill = Instance.new("Frame", thudBarBG)
thudBarFill.Size = UDim2.new(1, 0, 1, 0)
thudBarFill.BackgroundColor3 = GREEN
thudBarFill.BorderSizePixel = 0
Instance.new("UICorner", thudBarFill).CornerRadius = UDim.new(0, 3)

-- ==========================================
-- ПЛАВАЮЩИЙ КИБЕР-ЗНАЧОК МЕНЮ
-- ==========================================
local ToggleBadge = Instance.new("Frame")
ToggleBadge.Name = "BaggetCyberBadge"
ToggleBadge.Size = UDim2.new(0, 54, 0, 54)
ToggleBadge.Position = UDim2.new(0, 20, 0.5, -27)
ToggleBadge.BackgroundColor3 = BLACK
ToggleBadge.BackgroundTransparency = 0.1
ToggleBadge.Active = true
ToggleBadge.Parent = SG
Instance.new("UICorner", ToggleBadge).CornerRadius = UDim.new(0, 12)

local badgeOuterStroke = Instance.new("UIStroke", ToggleBadge)
badgeOuterStroke.Color = GREEN
badgeOuterStroke.Thickness = 2

local badgeRotor = Instance.new("Frame", ToggleBadge)
badgeRotor.Size = UDim2.new(0, 34, 0, 34)
badgeRotor.AnchorPoint = Vector2.new(0.5, 0.5)
badgeRotor.Position = UDim2.new(0.5, 0, 0.5, -3)
badgeRotor.BackgroundTransparency = 1
badgeRotor.Rotation = 45
local rotorStroke = Instance.new("UIStroke", badgeRotor)
rotorStroke.Color = DARK_GREEN
rotorStroke.Thickness = 1.5
Instance.new("UICorner", badgeRotor).CornerRadius = UDim.new(0, 4)

local badgeGlow = Instance.new("Frame", ToggleBadge)
badgeGlow.Size = UDim2.new(0, 22, 0, 22)
badgeGlow.AnchorPoint = Vector2.new(0.5, 0.5)
badgeGlow.Position = UDim2.new(0.5, 0, 0.5, -3)
badgeGlow.BackgroundColor3 = GREEN
badgeGlow.BackgroundTransparency = 0.78
Instance.new("UICorner", badgeGlow).CornerRadius = UDim.new(1, 0)

local badgeIcon = Instance.new("TextLabel", ToggleBadge)
badgeIcon.Size = UDim2.new(1, 0, 0, 28)
badgeIcon.Position = UDim2.new(0, 0, 0, 6)
badgeIcon.BackgroundTransparency = 1
badgeIcon.Text = "[B]"
badgeIcon.TextColor3 = GREEN
badgeIcon.Font = Enum.Font.Code
badgeIcon.TextSize = 16

local badgeSub = Instance.new("TextLabel", ToggleBadge)
badgeSub.Size = UDim2.new(1, 0, 0, 12)
badgeSub.Position = UDim2.new(0, 0, 1, -14)
badgeSub.BackgroundTransparency = 1
badgeSub.Text = "v19.2"
badgeSub.TextColor3 = TXT
badgeSub.Font = Enum.Font.Code
badgeSub.TextSize = 9

local badgeBtn = Instance.new("TextButton", ToggleBadge)
badgeBtn.Size = UDim2.new(1, 0, 1, 0)
badgeBtn.BackgroundTransparency = 1
badgeBtn.Text = ""

-- Главное окно меню
local P = Instance.new("Frame")
P.Size = UDim2.new(0, 365, 0, 580)
P.Position = UDim2.new(0.5, -182, 0.5, -290)
P.BackgroundColor3 = PANEL_BG
P.BackgroundTransparency = 0.08
P.BorderSizePixel = 2
P.BorderColor3 = GREEN
P.Active = true
P.ClipsDescendants = true
P.Parent = SG
Instance.new("UICorner", P).CornerRadius = UDim.new(0, 6)

-- Фоновый ASCII-арт
local ASCII_ART_TEXT = [[
                                                                   .
                             :==                                  *#+.
                            -##%:                                 -###:
                           -####:                                 :####+
                          -#####-                                :*#####*
                        :*######+                                .*#######+
                       =#########=                               =#########-
                      +##########+                        ...    .#%####*#%#:
                     .##########-  .-++***+=-.      .-+*#####*=: .+####:.=*+
                     :##########++*###########*=-:-+############*==*####+:
                     .#######+*#######################################**##*-
                     .######: +#############################################.
                     :#####+ -#######################****#############++###*
                     +#####  *########################################: *##**=
                    .#####= =########################################*  -###%+
                     *####. ########################################*    *##=
                     :####.=#######################################+     *#+
                      +##*:*########*#############################-      *%+
                       *%*=#####*##*:-*#########################=         ..
                        -.+#########*-.-*####################*-
                         .############*=:-+################*-     =++-
                         =%#####..-+##%##=:.=############*-       =#**
                        :######*  . .:=+#%#==##*#######*=  :-=+*+  ***.
                        *#######   +*++=:-*#####*  ....   :***=-..=**#.
                       =########+. :++++: .#####*:         --===+#***-
                       ###########+=-:::--=*#*####+-     +*+****++-
                      =################%############*+-
                     *################**#**********###*=:  =#+
                     ################==****##########**##+:.*%*.
                    :###############-.##*#*----::::.::::+##= +%#.
                    :##############+ -####:       =+++*-+%*  *%+
                     +%############: :####:      -#-**+: .   .##.
                      -*#%%########  :#####+=:    .*           -#*
                        .=++#######*   #########+-  =:
                       .**+-:-+####*-  *##########+ *%#-
                       :#*##*=..=*###*++*#*########-=###*:
                        .--=+*#+=--+###*+##########:=%###%*=.              :*
                          :-: .:::  .-+###*+=-:.::   :::::-+#*.            -#+
                         #%*+.          ::::..:=*=           ...=.         *+
                         :+.      ..  -***###%%##+-...     +###:  .**:
                                :**+=  -##-  .:-=++****=     :*#.   #-
                                 -=    .**.                   :+
]]

local AsciiBG = Instance.new("TextLabel")
AsciiBG.Name = "AsciiArtBackground"
AsciiBG.Size = UDim2.new(1, -10, 1, -42)
AsciiBG.Position = UDim2.new(0, 5, 0, 36)
AsciiBG.BackgroundTransparency = 1
AsciiBG.Text = ASCII_ART_TEXT
AsciiBG.TextColor3 = GREEN
AsciiBG.TextTransparency = 0.76
AsciiBG.Font = Enum.Font.Code
AsciiBG.TextScaled = true
AsciiBG.TextXAlignment = Enum.TextXAlignment.Center
AsciiBG.TextYAlignment = Enum.TextYAlignment.Center
AsciiBG.ZIndex = 1
AsciiBG.Parent = P

-- Фоновая матрица символов
local EmojiBG = Instance.new("Folder", P)
EmojiBG.Name = "EmojiBackground"
local smiles = {"(^_^)", "[^v^]", ">_<", "0x19", "(•_•)", "[~_~]", "1010", "SYS"}
task.spawn(function()
	while SG and SG.Parent do
		if P.Visible and EmojiBG.Parent then
			local em = Instance.new("TextLabel")
			em.Size = UDim2.new(0, 60, 0, 20)
			local startX = math.random(10, 285)
			em.Position = UDim2.new(0, startX, 0, 35)
			em.BackgroundTransparency = 1
			em.Text = smiles[math.random(1, #smiles)]
			em.TextColor3 = currentThemeColor
			em.TextTransparency = 0.82
			em.TextSize = 11
			em.Font = Enum.Font.Code
			em.ZIndex = 1
			em.Parent = EmojiBG
			
			task.spawn(function()
				local posY = 35
				while em and em.Parent and posY < 550 do
					posY = posY + 4
					em.Position = UDim2.new(0, startX, 0, posY)
					task.wait(0.06)
				end
				if em then em:Destroy() end
			end)
		end
		task.wait(1.8)
	end
end)

-- Верхняя панель (TopBar)
local TB = Instance.new("Frame")
TB.Size = UDim2.new(1, 0, 0, 32)
TB.BackgroundColor3 = BLACK
TB.BackgroundTransparency = 0.1
TB.BorderSizePixel = 1
TB.BorderColor3 = GREEN
TB.Active = true
TB.ZIndex = 3
TB.Parent = P

local HeaderBadge = Instance.new("Frame", TB)
HeaderBadge.Size = UDim2.new(0, 20, 0, 20)
HeaderBadge.Position = UDim2.new(0, 7, 0, 6)
HeaderBadge.BackgroundColor3 = CAT_BG
HeaderBadge.BorderSizePixel = 1
HeaderBadge.BorderColor3 = GREEN
HeaderBadge.ZIndex = 4
Instance.new("UICorner", HeaderBadge).CornerRadius = UDim.new(0, 4)

local HeaderBadgeTxt = Instance.new("TextLabel", HeaderBadge)
HeaderBadgeTxt.Size = UDim2.new(1, 0, 1, 0)
HeaderBadgeTxt.BackgroundTransparency = 1
HeaderBadgeTxt.Text = "B"
HeaderBadgeTxt.TextColor3 = GREEN
HeaderBadgeTxt.Font = Enum.Font.Code
HeaderBadgeTxt.TextSize = 12
HeaderBadgeTxt.ZIndex = 4

local TL = Instance.new("TextLabel")
TL.Size = UDim2.new(1, -90, 1, 0)
TL.Position = UDim2.new(0, 33, 0, 0)
TL.BackgroundTransparency = 1
TL.Text = "BAGGET SCRIPTS [v19.2]"
TL.TextColor3 = GREEN
TL.TextSize = 12
TL.Font = Enum.Font.Code
TL.TextXAlignment = Enum.TextXAlignment.Left
TL.ZIndex = 4
TL.Parent = TB

local CB = Instance.new("TextButton")
CB.Size = UDim2.new(0, 22, 0, 22)
CB.Position = UDim2.new(1, -26, 0, 5)
CB.BackgroundColor3 = RED
CB.Text = "X"
CB.TextColor3 = Color3.fromRGB(255, 255, 255)
CB.TextSize = 11
CB.Font = Enum.Font.SourceSansBold
CB.ZIndex = 4
CB.Parent = TB
Instance.new("UICorner", CB).CornerRadius = UDim.new(0, 3)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 22, 0, 22)
MinBtn.Position = UDim2.new(1, -52, 0, 5)
MinBtn.BackgroundColor3 = DARK_GREEN
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 11
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.ZIndex = 4
MinBtn.Parent = TB
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 3)

local SF = Instance.new("ScrollingFrame")
SF.Size = UDim2.new(1, -12, 1, -40)
SF.Position = UDim2.new(0, 6, 0, 36)
SF.BackgroundTransparency = 1
SF.BorderSizePixel = 0
SF.ScrollBarThickness = 3
SF.ScrollBarImageColor3 = GREEN
SF.CanvasSize = UDim2.new(0, 0, 0, 0)
SF.AutomaticCanvasSize = Enum.AutomaticSize.Y
SF.ZIndex = 2
SF.Parent = P

local LL = Instance.new("UIListLayout")
LL.Padding = UDim.new(0, 6)
LL.SortOrder = Enum.SortOrder.LayoutOrder
LL.Parent = SF

local orderCount = 0
local function nextOrder() orderCount = orderCount + 1 return orderCount end
local activeSliderUpdate = nil

local function makeCategory(title, defaultOpen)
	local catWrapper = Instance.new("Frame")
	catWrapper.Size = UDim2.new(1, 0, 0, 0)
	catWrapper.AutomaticSize = Enum.AutomaticSize.Y
	catWrapper.BackgroundTransparency = 1
	catWrapper.LayoutOrder = nextOrder()
	catWrapper.ZIndex = 2
	catWrapper.Parent = SF

	local catLayout = Instance.new("UIListLayout")
	catLayout.SortOrder = Enum.SortOrder.LayoutOrder
	catLayout.Padding = UDim.new(0, 4)
	catLayout.Parent = catWrapper

	local headerBtn = Instance.new("TextButton")
	headerBtn.Size = UDim2.new(1, 0, 0, 28)
	headerBtn.BackgroundColor3 = CAT_BG
	headerBtn.BackgroundTransparency = 0.15
	headerBtn.BorderSizePixel = 1
	headerBtn.BorderColor3 = GREEN
	headerBtn.Text = (defaultOpen and "  [▼] " or "  [►] ") .. title
	headerBtn.TextColor3 = GREEN
	headerBtn.Font = Enum.Font.Code
	headerBtn.TextSize = 11
	headerBtn.TextXAlignment = Enum.TextXAlignment.Left
	headerBtn.LayoutOrder = 1
	headerBtn.ZIndex = 2
	headerBtn.Parent = catWrapper
	Instance.new("UICorner", headerBtn).CornerRadius = UDim.new(0, 4)

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, 0, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.Visible = defaultOpen or false
	content.LayoutOrder = 2
	content.ZIndex = 2
	content.Parent = catWrapper

	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingLeft = UDim.new(0, 6)
	contentPad.PaddingRight = UDim.new(0, 2)
	contentPad.Parent = content

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 4)
	contentLayout.Parent = content

	local isOpen = defaultOpen or false
	headerBtn.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		content.Visible = isOpen
		headerBtn.Text = (isOpen and "  [▼] " or "  [►] ") .. title
	end)

	return content
end

local function makeToggle(parent, name, def, cb)
	local r = Instance.new("Frame")
	r.Size = UDim2.new(1, 0, 0, 28)
	r.BackgroundColor3 = ELEM_BG
	r.BackgroundTransparency = 0.25
	r.BorderSizePixel = 1
	r.BorderColor3 = DARK_GREEN
	r.LayoutOrder = nextOrder()
	r.ZIndex = 2
	r.Parent = parent
	Instance.new("UICorner", r).CornerRadius = UDim.new(0, 4)
	
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -96, 1, 0)
	l.Position = UDim2.new(0, 8, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = (def and "[ON] " or "[OFF] ") .. name
	l.TextColor3 = def and GREEN or TXT
	l.TextSize = 11
	l.Font = Enum.Font.Code
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.ZIndex = 2
	l.Parent = r

	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -88, 1, 0)
	b.BackgroundTransparency = 1
	b.Text = ""
	b.ZIndex = 2
	b.Parent = r
	
	local bindBtn = Instance.new("TextButton")
	bindBtn.Size = UDim2.new(0, 76, 0, 20)
	bindBtn.Position = UDim2.new(1, -80, 0, 4)
	bindBtn.BackgroundColor3 = BLACK
	bindBtn.BorderSizePixel = 1
	bindBtn.BorderColor3 = DARK_GREEN
	bindBtn.Text = Keybinds[name] and ("[" .. Keybinds[name].Name .. "]") or "[NONE]"
	bindBtn.TextColor3 = TXT
	bindBtn.TextSize = 10
	bindBtn.Font = Enum.Font.Code
	bindBtn.ZIndex = 2
	bindBtn.Parent = r
	Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 3)

	local st = def
	local function setState(newState)
		st = newState
		l.Text = (st and "[ON] " or "[OFF] ") .. name
		l.TextColor3 = st and currentThemeColor or TXT
		pcall(cb, st)
	end

	b.MouseButton1Click:Connect(function() setState(not st) end)
	bindBtn.MouseButton1Click:Connect(function()
		bindBtn.Text = "[...]"
		bindingFeatureName = name
	end)

	_G.BaggetBinds[name] = {
		trigger = function() setState(not st) end,
		setState = setState,
		updateBtn = function(key)
			bindBtn.Text = key and ("[" .. key.Name .. "]") or "[NONE]"
		end
	}
	return setState
end

local function makeButton(parent, text, bgCol, cb)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 26)
	btn.BackgroundColor3 = bgCol or DARK_GREEN
	btn.BackgroundTransparency = 0.15
	btn.BorderSizePixel = 1
	btn.BorderColor3 = GREEN
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 11
	btn.Font = Enum.Font.Code
	btn.LayoutOrder = nextOrder()
	btn.ZIndex = 2
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
	btn.MouseButton1Click:Connect(function() pcall(cb) end)
	return btn
end

local function makeSlider(parent, name, minV, maxV, def, cb)
	local r = Instance.new("Frame")
	r.Size = UDim2.new(1, 0, 0, 42)
	r.BackgroundColor3 = ELEM_BG
	r.BackgroundTransparency = 0.25
	r.BorderSizePixel = 1
	r.BorderColor3 = DARK_GREEN
	r.LayoutOrder = nextOrder()
	r.ZIndex = 2
	r.Parent = parent
	Instance.new("UICorner", r).CornerRadius = UDim.new(0, 4)

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -55, 0, 16)
	l.Position = UDim2.new(0, 8, 0, 2)
	l.BackgroundTransparency = 1
	l.Text = name
	l.TextColor3 = TXT
	l.TextSize = 11
	l.Font = Enum.Font.Code
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = 2
	l.Parent = r

	local vl = Instance.new("TextLabel")
	vl.Size = UDim2.new(0, 45, 0, 16)
	vl.Position = UDim2.new(1, -53, 0, 2)
	vl.BackgroundTransparency = 1
	vl.Text = tostring(def)
	vl.TextColor3 = GREEN
	vl.TextSize = 11
	l.Font = Enum.Font.Code
	vl.TextXAlignment = Enum.TextXAlignment.Right
	vl.ZIndex = 2
	vl.Parent = r
	
	local ha = Instance.new("TextButton")
	ha.Size = UDim2.new(1, -16, 0, 18)
	ha.Position = UDim2.new(0, 8, 0, 20)
	ha.BackgroundTransparency = 1
	ha.Text = ""
	ha.ZIndex = 2
	ha.Parent = r

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 0, 4)
	bg.Position = UDim2.new(0, 0, 0.5, -2)
	bg.BackgroundColor3 = BLACK
	bg.BorderSizePixel = 1
	bg.BorderColor3 = DARK_GREEN
	bg.ZIndex = 2
	bg.Parent = ha
	
	local ia = math.clamp((def - minV) / (maxV - minV), 0, 1)
	local fl = Instance.new("Frame")
	fl.Size = UDim2.new(ia, 0, 1, 0)
	fl.BackgroundColor3 = GREEN
	fl.BorderSizePixel = 0
	fl.ZIndex = 2
	fl.Parent = bg

	local kn = Instance.new("Frame")
	kn.Size = UDim2.new(0, 8, 0, 10)
	kn.Position = UDim2.new(ia, -4, 0.5, -5)
	kn.BackgroundColor3 = GREEN
	kn.BorderSizePixel = 1
	kn.BorderColor3 = BLACK
	kn.ZIndex = 2
	kn.Parent = bg
	
	local function update(inputPos)
		local a = math.clamp((inputPos.X - bg.AbsolutePosition.X) / math.max(1, bg.AbsoluteSize.X), 0, 1)
		local v = math.floor(minV + a * (maxV - minV) + 0.5)
		fl.Size = UDim2.new(a, 0, 1, 0)
		kn.Position = UDim2.new(a, -4, 0.5, -5)
		vl.Text = tostring(v)
		pcall(cb, v)
	end

	ha.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			activeSliderUpdate = update
			update(i.Position)
		end
	end)
end

local function makeColorPicker(parent, name, defaultColor, cb)
	local r = Instance.new("Frame")
	r.Size = UDim2.new(1, 0, 0, 30)
	r.BackgroundColor3 = ELEM_BG
	r.BackgroundTransparency = 0.25
	r.BorderSizePixel = 1
	r.BorderColor3 = DARK_GREEN
	r.LayoutOrder = nextOrder()
	r.ZIndex = 2
	r.Parent = parent
	Instance.new("UICorner", r).CornerRadius = UDim.new(0, 4)
	
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -55, 1, 0)
	l.Position = UDim2.new(0, 8, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = name
	l.TextColor3 = TXT
	l.TextSize = 11
	l.Font = Enum.Font.Code
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = 2
	l.Parent = r
	
	local colorBtn = Instance.new("TextButton")
	colorBtn.Size = UDim2.new(0, 36, 0, 20)
	colorBtn.Position = UDim2.new(1, -42, 0, 5)
	colorBtn.BackgroundColor3 = defaultColor
	colorBtn.Text = ""
	colorBtn.BorderSizePixel = 1
	colorBtn.BorderColor3 = BLACK
	colorBtn.ZIndex = 2
	colorBtn.Parent = r
	Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 3)
	
	local presets = {
		Color3.fromRGB(0, 255, 115),
		Color3.fromRGB(0, 90, 35),
		Color3.fromRGB(255, 50, 50),
		Color3.fromRGB(130, 20, 20),
		Color3.fromRGB(0, 170, 255),
		Color3.fromRGB(255, 255, 0),
		Color3.fromRGB(255, 80, 255),
		Color3.fromRGB(255, 165, 0),
		Color3.fromRGB(120, 60, 0),
		Color3.fromRGB(255, 255, 255)
	}
	local currentIndex = 1
	for i, col in ipairs(presets) do
		if col == defaultColor then currentIndex = i break end
	end
	
	colorBtn.MouseButton1Click:Connect(function()
		currentIndex = currentIndex + 1
		if currentIndex > #presets then currentIndex = 1 end
		local newCol = presets[currentIndex]
		colorBtn.BackgroundColor3 = newCol
		pcall(cb, newCol)
	end)
end

-- ==========================================
-- МОДУЛИ ДВИЖЕНИЯ И ТРОЛЛИНГА
-- ==========================================
local noclipConn, originalCollide = nil, {}

local function enableNoclip()
	if noclipConn then noclipConn:Disconnect() end
	noclipConn = RunService.Stepped:Connect(function()
		local c = getChar()
		if c then
			for _, part in ipairs(c:GetDescendants()) do
				if part:IsA("BasePart") then
					if originalCollide[part] == nil then originalCollide[part] = part.CanCollide end
					part.CanCollide = false
				end
			end
		end
	end)
end

local function disableNoclip()
	if noclipConn then noclipConn:Disconnect() noclipConn = nil end
	for part, canCol in pairs(originalCollide) do
		if part and part.Parent then part.CanCollide = canCol end
	end
	table.clear(originalCollide)
end

local flyObj, flyAtt = nil, nil
local function stopFly()
	if flyObj then flyObj:Destroy() flyObj = nil end
	if flyAtt then flyAtt:Destroy() flyAtt = nil end
	local h = getHum()
	if h then h.PlatformStand = false end
end

local function startFly()
	stopFly()
	local r = getRoot()
	if not r then return end
	flyAtt = Instance.new("Attachment", r)
	flyObj = Instance.new("LinearVelocity", r)
	flyObj.Attachment0 = flyAtt
	flyObj.MaxForce = math.huge
	flyObj.VectorVelocity = Vector3.zero
	flyObj.RelativeTo = Enum.ActuatorRelativeTo.World
end

local function performDash()
	local r = getRoot()
	if r then
		r.AssemblyLinearVelocity = Camera.CFrame.LookVector * CFG.DashPower + Vector3.new(0, 18, 0)
	end
end

-- Спавн платформы под ногами
local function spawnNeonPad()
	local r = getRoot()
	if not r then return end
	local pad = trackPart(Instance.new("Part", workspace))
	pad.Name = "BaggetPad"
	pad.Size = Vector3.new(10, 0.6, 10)
	pad.Anchored = true
	pad.CanCollide = true
	pad.Material = Enum.Material.Neon
	pad.Color = currentThemeColor
	pad.Transparency = 0.25
	pad.CFrame = CFrame.new(r.Position - Vector3.new(0, getGroundOffset() + 0.3, 0))
	Debris:AddItem(pad, 15)
end

-- X-Ray стен
local xrayParts = {}
local function toggleXRay(on)
	if on then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") and not obj:IsDescendantOf(getChar() or SG) and obj.Transparency < 0.3 then
				local hum = obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid")
				if not hum then
					xrayParts[obj] = obj.LocalTransparencyModifier
					obj.LocalTransparencyModifier = CFG.XRayAlpha
				end
			end
		end
	else
		for obj, orig in pairs(xrayParts) do
			if obj and obj.Parent then obj.LocalTransparencyModifier = orig end
		end
		table.clear(xrayParts)
	end
end

-- AirWalk
local airWalkPart = nil
local airWalkY = 0
local function toggleAirWalk(on)
	if airWalkPart then airWalkPart:Destroy() airWalkPart = nil end
	if on then
		local r = getRoot()
		if not r then return end
		local offset = getGroundOffset()
		airWalkY = r.Position.Y - offset - 0.25
		airWalkPart = Instance.new("Part", workspace)
		airWalkPart.Name = "BaggetAirWalk"
		airWalkPart.Size = Vector3.new(14, 0.5, 14)
		airWalkPart.Anchored = true
		airWalkPart.CanCollide = true
		airWalkPart.Color = currentThemeColor
		airWalkPart.Material = Enum.Material.Neon
		airWalkPart.Transparency = 0.55
		airWalkPart.Position = Vector3.new(r.Position.X, airWalkY, r.Position.Z)
	end
end

-- Anti-Fling восстановление
local antiFlingOrig = {}
local function restoreAntiFling()
	for part, origCollide in pairs(antiFlingOrig) do
		if part and part.Parent then
			part.CanCollide = origCollide
		end
	end
	table.clear(antiFlingOrig)
end

-- Fling Touch (Силовой импульс вращением)
local flingAngular = nil
local flingAtt = nil
local function toggleFlingTouch(on)
	if flingAngular then flingAngular:Destroy() flingAngular = nil end
	if flingAtt then flingAtt:Destroy() flingAtt = nil end
	local r = getRoot()
	if on and r then
		enableNoclip()
		flingAtt = Instance.new("Attachment", r)
		flingAngular = Instance.new("AngularVelocity", r)
		flingAngular.Attachment0 = flingAtt
		flingAngular.MaxTorque = math.huge
		flingAngular.AngularVelocity = Vector3.new(CFG.FlingPower, CFG.FlingPower, CFG.FlingPower)
		flingAngular.RelativeTo = Enum.ActuatorRelativeTo.World
	else
		if not S.Noclip then disableNoclip() end
		if r then r.AssemblyAngularVelocity = Vector3.zero end
	end
end

-- ИСПРАВЛЕННЫЙ СПИНБОТ
local function toggleSpinbot(on)
	local h = getHum()
	if h then
		h.AutoRotate = not on
	end
end

-- Визуальный Headless
local savedHeadTrans = 0
local function toggleHeadless(on)
	local c = getChar()
	local head = c and c:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		if on then
			savedHeadTrans = head.Transparency
			head.Transparency = 1
			local face = head:FindFirstChildOfClass("Decal")
			if face then face.Transparency = 1 end
		else
			head.Transparency = savedHeadTrans
			local face = head:FindFirstChildOfClass("Decal")
			if face then face.Transparency = 0 end
		end
	end
end

-- Freecam
local freecamCF = CFrame.new()
local freecamAngles = Vector2.zero
local function toggleFreecam(on)
	local r = getRoot()
	if on then
		freecamCF = Camera.CFrame
		local rx, ry, _ = freecamCF:ToEulerAnglesYXZ()
		freecamAngles = Vector2.new(rx, ry)
		Camera.CameraType = Enum.CameraType.Scriptable
		if r then r.Anchored = true end
	else
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		Camera.CameraType = Enum.CameraType.Custom
		local h = getHum()
		if h then Camera.CameraSubject = h end
		if r then r.Anchored = S.FreezeChar end
	end
end

-- ==========================================
-- УДОБНАЯ СИСТЕМА ТЕЛЕПОРТА И ВЫБОРА ЦЕЛЕЙ
-- ==========================================
local currentSelectedTarget = nil
local targetLabelUI = nil
local targetSearchFilter = ""
local targetListFrame = nil

local function setSelectedTarget(targetData)
	currentSelectedTarget = targetData
	if targetLabelUI then
		if targetData and targetData.Model and targetData.Model.Parent then
			targetLabelUI.Text = "Цель: " .. tostring(targetData.ShortName or targetData.Name)
			targetLabelUI.TextColor3 = GREEN
		else
			targetLabelUI.Text = "Цель: [НЕ ВЫБРАНА]"
			targetLabelUI.TextColor3 = TXT
		end
	end
	if S.SpectateTarget then
		if currentSelectedTarget and currentSelectedTarget.Humanoid then
			Camera.CameraSubject = currentSelectedTarget.Humanoid
		else
			local h = getHum()
			if h then Camera.CameraSubject = h end
		end
	end
end

local function teleportToTarget(targetData)
	if not targetData or not targetData.RootPart or not targetData.RootPart.Parent then return end
	local r = getRoot()
	if r then
		r.CFrame = targetData.RootPart.CFrame * CFrame.new(0, 0, 3.2)
		r.AssemblyLinearVelocity = Vector3.zero
	end
end

local function refreshTargetListUI()
	if not targetListFrame then return end
	for _, child in ipairs(targetListFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local list = getValidTargets(false)
	local myRoot = getRoot()
	local filterLower = string.lower(targetSearchFilter or "")

	-- Сортировка: сначала игроки, потом боты, внутри — по дистанции
	table.sort(list, function(a, b)
		if a.IsPlayer ~= b.IsPlayer then
			return a.IsPlayer
		end
		if myRoot and a.RootPart and b.RootPart then
			return (a.RootPart.Position - myRoot.Position).Magnitude < (b.RootPart.Position - myRoot.Position).Magnitude
		end
		return tostring(a.Name) < tostring(b.Name)
	end)

	local shownCount = 0
	for _, t in ipairs(list) do
		local nameLower = string.lower(t.Name)
		if filterLower == "" or string.find(nameLower, filterLower, 1, true) then
			shownCount = shownCount + 1
			local dist = (myRoot and t.RootPart) and math.floor((t.RootPart.Position - myRoot.Position).Magnitude) or 0
			local isSel = (currentSelectedTarget and currentSelectedTarget.Model == t.Model)

			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -4, 0, 26)
			row.BackgroundColor3 = isSel and CAT_BG or ELEM_BG
			row.BackgroundTransparency = 0.15
			row.BorderSizePixel = 1
			row.BorderColor3 = isSel and GREEN or DARK_GREEN
			row.ZIndex = 2
			row.Parent = targetListFrame
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

			local nameBtn = Instance.new("TextButton")
			nameBtn.Size = UDim2.new(1, -92, 1, 0)
			nameBtn.Position = UDim2.new(0, 6, 0, 0)
			nameBtn.BackgroundTransparency = 1
			nameBtn.Text = string.format("%s [%dm]", t.Name, dist)
			nameBtn.TextColor3 = t.IsPlayer and GREEN or Color3.fromRGB(255, 180, 50)
			nameBtn.Font = Enum.Font.Code
			nameBtn.TextSize = 10
			nameBtn.TextXAlignment = Enum.TextXAlignment.Left
			nameBtn.TextTruncate = Enum.TextTruncate.AtEnd
			nameBtn.ZIndex = 2
			nameBtn.Parent = row

			local selBtn = Instance.new("TextButton")
			selBtn.Size = UDim2.new(0, 40, 0, 20)
			selBtn.Position = UDim2.new(1, -84, 0, 3)
			selBtn.BackgroundColor3 = isSel and GREEN or BLACK
			selBtn.BorderSizePixel = 1
			selBtn.BorderColor3 = GREEN
			selBtn.Text = isSel and "SEL" or "AIM"
			selBtn.TextColor3 = isSel and BLACK or TXT
			selBtn.Font = Enum.Font.Code
			selBtn.TextSize = 10
			selBtn.ZIndex = 2
			selBtn.Parent = row
			Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 3)

			local tpBtn = Instance.new("TextButton")
			tpBtn.Size = UDim2.new(0, 38, 0, 20)
			tpBtn.Position = UDim2.new(1, -41, 0, 3)
			tpBtn.BackgroundColor3 = DARK_GREEN
			tpBtn.BorderSizePixel = 1
			tpBtn.BorderColor3 = GREEN
			tpBtn.Text = "TP"
			tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			tpBtn.Font = Enum.Font.Code
			tpBtn.TextSize = 10
			tpBtn.ZIndex = 2
			tpBtn.Parent = row
			Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 3)

			local function selectThis()
				setSelectedTarget(t)
				refreshTargetListUI()
			end

			nameBtn.MouseButton1Click:Connect(selectThis)
			selBtn.MouseButton1Click:Connect(selectThis)
			tpBtn.MouseButton1Click:Connect(function()
				setSelectedTarget(t)
				teleportToTarget(t)
				refreshTargetListUI()
			end)
		end
	end
end

-- Хитбоксы и Головы
local origHitboxes = {}
local origHeads = {}

local function resetHitboxes()
	for part, data in pairs(origHitboxes) do
		if part and part.Parent then
			part.Size = data.Size
			part.Transparency = data.Transparency
			part.CanCollide = data.CanCollide
		end
	end
	table.clear(origHitboxes)
end

local function resetBigHeads()
	for head, data in pairs(origHeads) do
		if head and head.Parent then
			head.Size = data.Size
			head.CanCollide = data.CanCollide
		end
	end
	table.clear(origHeads)
end

local orbitAngle = 0
local lastStepWave = 0
local lastGhostClone = 0
local lastLightningTick = 0
local lastFakeLagTick = 0
local lastSafePosition = nil

-- ==========================================
-- FX ЭФФЕКТЫ ПЕРСОНАЖА (CLIENT-SIDE VISUALS)
-- ==========================================
local myPulse, myAuraParts, myHalo, myChinaHat, myCyberShield, myTrail, myTrailAtts = nil, {}, nil, nil, nil, nil, {}
local myOrbs = {}
local myWings = {}
local myGyroRings = {}

local function togglePulse(on)
	if myPulse then myPulse:Destroy() myPulse = nil end
	if on then
		local c = getChar() if not c then return end
		myPulse = Instance.new("Highlight", SG)
		myPulse.FillColor = Color3.fromRGB(0, 45, 20)
		myPulse.FillTransparency = 0.45
		myPulse.OutlineColor = currentThemeColor
		myPulse.Adornee = c
	end
end

local function toggleAura(on)
	for _, p in ipairs(myAuraParts) do p:Destroy() end table.clear(myAuraParts)
	if on then
		local c = getChar() if not c then return end
		for _, part in ipairs(c:GetChildren()) do
			if part:IsA("BasePart") then
				local att = Instance.new("Attachment", part)
				local emit = Instance.new("ParticleEmitter", att)
				emit.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				emit.Color = ColorSequence.new(currentThemeColor)
				emit.Rate = CFG.AuraRate
				emit.Speed = NumberRange.new(1, 3)
				emit.Size = NumberSequence.new(0.3, 0)
				emit.LightEmission = 1
				table.insert(myAuraParts, att)
			end
		end
	end
end

local function toggleHalo(on)
	if myHalo then myHalo:Destroy() myHalo = nil end
	if on then
		myHalo = Instance.new("Part", workspace)
		myHalo.Name = "BaggetHalo"
		myHalo.Size = Vector3.new(2.2, 0.12, 2.2)
		myHalo.Color = currentThemeColor
		myHalo.Material = Enum.Material.Neon
		myHalo.Anchored = true
		myHalo.CanCollide = false
		myHalo.CastShadow = false
		Instance.new("CylinderMesh", myHalo)
	end
end

local function toggleChinaHat(on)
	if myChinaHat then myChinaHat:Destroy() myChinaHat = nil end
	if on then
		myChinaHat = Instance.new("Part", workspace)
		myChinaHat.Name = "BaggetChinaHat"
		myChinaHat.Size = Vector3.new(3.2, 1.1, 3.2)
		myChinaHat.Color = currentThemeColor
		myChinaHat.Material = Enum.Material.Neon
		myChinaHat.Transparency = 0.35
		myChinaHat.Anchored = true
		myChinaHat.CanCollide = false
		myChinaHat.CastShadow = false
		
		local mesh = Instance.new("SpecialMesh", myChinaHat)
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "rbxassetid://1033714"
		mesh.Scale = Vector3.new(1.7, 0.65, 1.7)
	end
end

local function toggleCyberShield(on)
	if myCyberShield then myCyberShield:Destroy() myCyberShield = nil end
	if on then
		myCyberShield = Instance.new("Part", workspace)
		myCyberShield.Name = "BaggetShield"
		myCyberShield.Shape = Enum.PartType.Ball
		myCyberShield.Size = Vector3.new(7.5, 7.5, 7.5)
		myCyberShield.Color = currentThemeColor
		myCyberShield.Material = Enum.Material.ForceField
		myCyberShield.Transparency = 0.25
		myCyberShield.Anchored = true
		myCyberShield.CanCollide = false
		myCyberShield.CastShadow = false
	end
end

local function toggleCyberWings(on)
	for _, w in ipairs(myWings) do
		if w.Part then w.Part:Destroy() end
	end
	table.clear(myWings)
	if on then
		for side = -1, 1, 2 do
			for feather = 1, 4 do
				local p = Instance.new("Part", workspace)
				p.Name = "BaggetWing"
				p.Size = Vector3.new(0.15, 0.45 + (5 - feather) * 0.35, 1.4 + (5 - feather) * 0.4)
				p.Color = currentThemeColor
				p.Material = Enum.Material.Neon
				p.Transparency = 0.2
				p.Anchored = true
				p.CanCollide = false
				p.CastShadow = false
				table.insert(myWings, {Part = p, Side = side, Index = feather})
			end
		end
	end
end

local function toggleGyroRings(on)
	for _, ring in ipairs(myGyroRings) do
		if ring then ring:Destroy() end
	end
	table.clear(myGyroRings)
	if on then
		for i = 1, 2 do
			local p = Instance.new("Part", workspace)
			p.Name = "BaggetGyroRing"
			p.Size = Vector3.new(6.5 + i * 1.2, 0.12, 6.5 + i * 1.2)
			p.Color = currentThemeColor
			p.Material = Enum.Material.Neon
			p.Transparency = 0.35
			p.Anchored = true
			p.CanCollide = false
			p.CastShadow = false
			local m = Instance.new("CylinderMesh", p)
			m.Scale = Vector3.new(1, 0.5, 1)
			table.insert(myGyroRings, p)
		end
	end
end

local function toggleOrbitOrbs(on)
	for _, orb in ipairs(myOrbs) do
		if orb.Part then orb.Part:Destroy() end
	end
	table.clear(myOrbs)
	if on then
		for i = 1, 3 do
			local p = Instance.new("Part", workspace)
			p.Name = "BaggetOrb"
			p.Shape = Enum.PartType.Ball
			p.Size = Vector3.new(0.65, 0.65, 0.65)
			p.Color = currentThemeColor
			p.Material = Enum.Material.Neon
			p.Anchored = true
			p.CanCollide = false
			p.CastShadow = false
			
			local a0 = Instance.new("Attachment", p) a0.Position = Vector3.new(0, 0.25, 0)
			local a1 = Instance.new("Attachment", p) a1.Position = Vector3.new(0, -0.25, 0)
			local tr = Instance.new("Trail", p)
			tr.Attachment0 = a0
			tr.Attachment1 = a1
			tr.Lifetime = 0.35
			tr.Color = ColorSequence.new(currentThemeColor)
			tr.LightEmission = 1
			tr.WidthScale = NumberSequence.new(1, 0)
			
			table.insert(myOrbs, {Part = p, Trail = tr, Offset = (i - 1) * ((math.pi * 2) / 3)})
		end
	end
end

local function toggleTrail(on)
	if myTrail then myTrail:Destroy() myTrail = nil end
	for _, a in pairs(myTrailAtts) do a:Destroy() end table.clear(myTrailAtts)
	if on then
		local r = getRoot() if not r then return end
		local a0 = Instance.new("Attachment", r) a0.Position = Vector3.new(0, 1, 0)
		local a1 = Instance.new("Attachment", r) a1.Position = Vector3.new(0, -1, 0)
		table.insert(myTrailAtts, a0) table.insert(myTrailAtts, a1)
		myTrail = Instance.new("Trail", r)
		myTrail.Attachment0 = a0 myTrail.Attachment1 = a1
		myTrail.Lifetime = CFG.TrailLength
		myTrail.Color = ColorSequence.new(currentThemeColor)
		myTrail.LightEmission = 1
	end
end

-- ==========================================
-- HEARTBEAT ЦИКЛ ФИЗИКИ И ИНТЕРАКЦИЙ
-- ==========================================
bindConnection(RunService.Heartbeat, function(dt)
	local h = getHum()
	local r = getRoot()
	local myChar = getChar()

	if h and r then
		-- Полет (Fly Mode)
		if S.Fly and flyObj and flyObj.Parent then
			local moveVec = Vector3.zero
			if not UIS:GetFocusedTextBox() then
				if UIS:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + Camera.CFrame.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - Camera.CFrame.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + Camera.CFrame.RightVector end
				if UIS:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - Camera.CFrame.RightVector end
				if UIS:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0, 1, 0) end
				if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec = moveVec - Vector3.new(0, 1, 0) end
			end
			if moveVec.Magnitude > 0.01 then
				flyObj.VectorVelocity = moveVec.Unit * CFG.FlySpeed
			else
				flyObj.VectorVelocity = Vector3.zero
			end
		end

		-- Jetpack
		if S.Jetpack and not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.Space) then
			r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, CFG.JetpackPower, r.AssemblyLinearVelocity.Z)
		end

		-- Fake Lag (Имитация пинга)
		if S.FakeLag then
			if tick() - lastFakeLagTick > 0.28 then
				lastFakeLagTick = tick()
				r.Anchored = false
			elseif tick() - lastFakeLagTick > 0.06 then
				r.Anchored = true
			end
		end

		-- Anti-Void защита
		if h.FloorMaterial ~= Enum.Material.Air and r.Position.Y > -50 then
			lastSafePosition = r.CFrame
		end
		if S.AntiVoid and r.Position.Y < -120 then
			if lastSafePosition then
				r.CFrame = lastSafePosition + Vector3.new(0, 5, 0)
			else
				r.CFrame = CFrame.new(0, 50, 0)
			end
			r.AssemblyLinearVelocity = Vector3.zero
		end

		if S.SpeedLock then
			h.WalkSpeed = CFG.Speed
			h.UseJumpPower = true
			h.JumpPower = CFG.Jump
		end
		if S.AutoBhop and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then
			h:ChangeState(Enum.HumanoidStateType.Jumping)
		end

		-- Spider Climb
		if S.SpiderClimb and h.MoveDirection.Magnitude > 0.05 then
			raycastParams.FilterDescendantsInstances = {myChar, Camera, airWalkPart}
			local checkDir = h.MoveDirection.Unit * 2.8
			local wallHit = workspace:Raycast(r.Position, checkDir, raycastParams) or workspace:Raycast(r.Position - Vector3.new(0, 1.2, 0), checkDir, raycastParams)
			if wallHit then
				r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, CFG.SpiderSpeed, r.AssemblyLinearVelocity.Z)
			end
		end
	end

	-- AirWalk обновление
	if S.AirWalk and airWalkPart and r then
		if not UIS:GetFocusedTextBox() then
			if UIS:IsKeyDown(Enum.KeyCode.E) then airWalkY = airWalkY + (22 * dt) end
			if UIS:IsKeyDown(Enum.KeyCode.Q) then airWalkY = airWalkY - (22 * dt) end
		end
		airWalkPart.Position = Vector3.new(r.Position.X, airWalkY, r.Position.Z)
		if S.RainbowMode then airWalkPart.Color = currentThemeColor end
	end

	-- Anti-Fling
	if S.AntiFling then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then
				for _, part in ipairs(p.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						if antiFlingOrig[part] == nil then antiFlingOrig[part] = part.CanCollide end
						part.CanCollide = false
					end
				end
			end
		end
	end

	-- Интеракции с выбранной целью (Orbit / HeadSit / Mimic)
	local lockedToTarget = false
	if (S.OrbitTarget or S.HeadSit or S.MimicTarget) and currentSelectedTarget and currentSelectedTarget.RootPart and currentSelectedTarget.RootPart.Parent and r and h then
		local tRoot = currentSelectedTarget.RootPart
		lockedToTarget = true
		if S.OrbitTarget then
			orbitAngle = orbitAngle + dt * CFG.OrbitSpeed
			local tPos = tRoot.Position
			local offset = Vector3.new(math.cos(orbitAngle) * CFG.OrbitRadius, 1.5, math.sin(orbitAngle) * CFG.OrbitRadius)
			r.CFrame = CFrame.new(tPos + offset, tPos)
			r.AssemblyLinearVelocity = Vector3.zero
		elseif S.HeadSit then
			h.Sit = true
			r.CFrame = tRoot.CFrame * CFrame.new(0, 3.4, 0)
			r.AssemblyLinearVelocity = Vector3.zero
		elseif S.MimicTarget then
			r.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4.5)
			r.AssemblyLinearVelocity = Vector3.zero
		end
	end

	-- ИСПРАВЛЕННЫЙ СПИНБОТ: работает независимо от выбранной цели!
	if S.Spinbot and r and h and not lockedToTarget then
		h.AutoRotate = false
		r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(CFG.SpinSpeed), 0)
	end

	-- Footstep Shockwaves
	if S.StepWaves and h and r and h.MoveDirection.Magnitude > 0.1 and h.FloorMaterial ~= Enum.Material.Air then
		if tick() - lastStepWave > 0.35 then
			lastStepWave = tick()
			local wave = Instance.new("Part", workspace)
			wave.Name = "BaggetWave"
			wave.Anchored = true
			wave.CanCollide = false
			wave.CastShadow = false
			wave.Material = Enum.Material.Neon
			wave.Color = currentThemeColor
			wave.Size = Vector3.new(1, 0.08, 1)
			wave.CFrame = CFrame.new(r.Position - Vector3.new(0, getGroundOffset() - 0.1, 0))
			Instance.new("CylinderMesh", wave)
			
			task.spawn(function()
				for i = 1, 14 do
					if not wave or not wave.Parent then break end
					local sz = 1 + (i * 0.65)
					wave.Size = Vector3.new(sz, 0.08, sz)
					wave.Transparency = i / 14
					task.wait(0.025)
				end
				if wave then wave:Destroy() end
			end)
		end
	end

	-- Ghost Clone Trail
	if S.GhostTrail and r and myChar and r.AssemblyLinearVelocity.Magnitude > 8 then
		if tick() - lastGhostClone > 0.18 then
			lastGhostClone = tick()
			for _, part in ipairs(myChar:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					local ghost = Instance.new("Part", workspace)
					ghost.Name = "BaggetGhost"
					ghost.Anchored = true
					ghost.CanCollide = false
					ghost.CastShadow = false
					ghost.Material = Enum.Material.Neon
					ghost.Color = currentThemeColor
					ghost.Size = part.Size
					ghost.CFrame = part.CFrame
					ghost.Transparency = 0.65
					Debris:AddItem(ghost, 0.35)
				end
			end
		end
	end

	-- Lightning Storm FX
	if S.LightningFX and r and tick() - lastLightningTick > 0.12 then
		lastLightningTick = tick()
		local p1 = r.Position + Vector3.new(math.random(-35, 35)/10, math.random(-25, 35)/10, math.random(-35, 35)/10)
		local p2 = p1 + Vector3.new(math.random(-25, 25)/10, math.random(-25, 25)/10, math.random(-25, 25)/10)
		local dist = (p2 - p1).Magnitude
		local bolt = Instance.new("Part", workspace)
		bolt.Name = "BaggetBolt"
		bolt.Anchored = true
		bolt.CanCollide = false
		bolt.CastShadow = false
		bolt.Material = Enum.Material.Neon
		bolt.Color = currentThemeColor
		bolt.Size = Vector3.new(0.09, 0.09, dist)
		bolt.CFrame = CFrame.new((p1 + p2) * 0.5, p2)
		Debris:AddItem(bolt, 0.08)
	end

	-- Hitbox Expander & Big Heads
	if S.HitboxExpander or S.BigHeads then
		local targets = getValidTargets(CFG.AimTeamCheck)
		local activeParts = {}
		local activeHeads = {}
		for _, t in ipairs(targets) do
			if S.HitboxExpander then
				local hrp = t.RootPart
				if hrp and hrp ~= r then
					activeParts[hrp] = true
					if not origHitboxes[hrp] then
						origHitboxes[hrp] = {Size = hrp.Size, Transparency = hrp.Transparency, CanCollide = hrp.CanCollide}
					end
					hrp.Size = Vector3.new(CFG.HitboxSize, CFG.HitboxSize, CFG.HitboxSize)
					hrp.Transparency = 0.65
					hrp.Color = currentThemeColor
					hrp.Material = Enum.Material.Neon
					hrp.CanCollide = false
				end
			end
			if S.BigHeads then
				local head = t.Model:FindFirstChild("Head")
				if head and head:IsA("BasePart") then
					activeHeads[head] = true
					if not origHeads[head] then
						origHeads[head] = {Size = head.Size, CanCollide = head.CanCollide}
					end
					head.Size = Vector3.new(CFG.HeadScale, CFG.HeadScale, CFG.HeadScale)
					head.CanCollide = false
				end
			end
		end
		for part, data in pairs(origHitboxes) do
			if not activeParts[part] then
				if part and part.Parent then
					part.Size = data.Size
					part.Transparency = data.Transparency
					part.CanCollide = data.CanCollide
				end
				origHitboxes[part] = nil
			end
		end
		for head, data in pairs(origHeads) do
			if not activeHeads[head] then
				if head and head.Parent then
					head.Size = data.Size
					head.CanCollide = data.CanCollide
				end
				origHeads[head] = nil
			end
		end
	end
end)

-- ==========================================
-- МОДУЛИ ОТРИСОВКИ ESP И ЛАЗЕРОВ ВЗГЛЯДА
-- ==========================================
local function drawLineUI(lineFrame, fromPos, toPos, color, thickness)
	local diff = toPos - fromPos
	local dist = diff.Magnitude
	local center = (fromPos + toPos) / 2
	local angle = math.deg(math.atan2(diff.Y, diff.X))
	
	lineFrame.Position = UDim2.fromOffset(center.X, center.Y)
	lineFrame.Size = UDim2.fromOffset(dist, thickness or 1.5)
	lineFrame.Rotation = angle
	lineFrame.BackgroundColor3 = color
	lineFrame.Visible = true
end

local R15Bones = {
	{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
	{"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
	{"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}
local R6Bones = {
	{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local skeletonPool = {}

local function updateSkeletonForModel(model, color)
	local bones = model:FindFirstChild("UpperTorso") and R15Bones or (model:FindFirstChild("Torso") and R6Bones)
	if not bones then return end

	if not skeletonPool[model] then skeletonPool[model] = {} end
	local modelLines = skeletonPool[model]

	local lineIndex = 1
	for _, pair in ipairs(bones) do
		local p1 = model:FindFirstChild(pair[1])
		local p2 = model:FindFirstChild(pair[2])
		if p1 and p2 then
			local pos1, on1 = Camera:WorldToViewportPoint(p1.Position)
			local pos2, on2 = Camera:WorldToViewportPoint(p2.Position)
			if (on1 or on2) and pos1.Z > 0 and pos2.Z > 0 then
				local lineFrame = modelLines[lineIndex]
				if not lineFrame then
					lineFrame = Instance.new("Frame")
					lineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
					lineFrame.BorderSizePixel = 0
					lineFrame.Parent = DrawLayer
					modelLines[lineIndex] = lineFrame
				end
				drawLineUI(lineFrame, Vector2.new(pos1.X, pos1.Y), Vector2.new(pos2.X, pos2.Y), color, 1.5)
				lineIndex = lineIndex + 1
			end
		end
	end

	for i = lineIndex, #modelLines do
		if modelLines[i] then modelLines[i].Visible = false end
	end
end

local function clearSkeleton(model)
	if skeletonPool[model] then
		for _, lf in pairs(skeletonPool[model]) do
			if lf then lf:Destroy() end
		end
		skeletonPool[model] = nil
	end
end

local boxPool = {}

local function getOrCreateBoxData(model)
	if boxPool[model] then return boxPool[model] end
	
	local container = Instance.new("Frame", DrawLayer)
	container.BackgroundTransparency = 1
	container.Visible = false
	
	local boxFrame = Instance.new("Frame", container)
	boxFrame.Size = UDim2.new(1, 0, 1, 0)
	boxFrame.BackgroundTransparency = 1
	local stroke = Instance.new("UIStroke", boxFrame)
	stroke.Thickness = 1.4
	
	local hpBG = Instance.new("Frame", container)
	hpBG.Size = UDim2.new(0, 3, 1, 0)
	hpBG.Position = UDim2.new(0, -6, 0, 0)
	hpBG.BackgroundColor3 = BLACK
	hpBG.BorderSizePixel = 0
	
	local hpFill = Instance.new("Frame", hpBG)
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.AnchorPoint = Vector2.new(0, 1)
	hpFill.Position = UDim2.new(0, 0, 1, 0)
	hpFill.BorderSizePixel = 0
	
	local nameLbl = Instance.new("TextLabel", container)
	nameLbl.Size = UDim2.new(0, 200, 0, 16)
	nameLbl.AnchorPoint = Vector2.new(0.5, 1)
	nameLbl.Position = UDim2.new(0.5, 0, 0, -3)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.Code
	nameLbl.TextSize = 11
	nameLbl.TextStrokeTransparency = 0.2
	
	local data = {Container = container, Stroke = stroke, HpBG = hpBG, HpFill = hpFill, NameLbl = nameLbl}
	boxPool[model] = data
	return data
end

local function clearBoxData(model)
	if boxPool[model] then
		if boxPool[model].Container then boxPool[model].Container:Destroy() end
		boxPool[model] = nil
	end
end

local espHighlights = {}
local tracerFrames = {}
local lookLaserFrames = {}

-- ==========================================
-- ГЛАВНЫЙ ЦИКЛ РЕНДЕРИНГА (RENDERSTEPPED)
-- ==========================================
local fxAngle = 0
local fpsSmoothed = 60
local lastHUDTick = 0
local lastTargetListRefresh = 0

bindConnection(RunService.RenderStepped, function(dt)
	fxAngle = fxAngle + dt * 2.5
	fpsSmoothed = math.floor(fpsSmoothed * 0.9 + (1 / math.max(dt, 0.001)) * 0.1)

	-- Анимация плавающего Кибер-Значка
	badgeRotor.Rotation = (fxAngle * 35) % 360
	local pulseScale = 20 + math.sin(fxAngle * 3) * 4
	badgeGlow.Size = UDim2.fromOffset(pulseScale, pulseScale)

	-- Радужный режим (RGB Theme)
	if S.RainbowMode then
		currentThemeColor = Color3.fromHSV((tick() * 0.22) % 1, 0.85, 1)
	else
		currentThemeColor = GREEN
	end

	P.BorderColor3 = currentThemeColor
	TB.BorderColor3 = currentThemeColor
	TL.TextColor3 = currentThemeColor
	HeaderBadge.BorderColor3 = currentThemeColor
	HeaderBadgeTxt.TextColor3 = currentThemeColor
	AsciiBG.TextColor3 = currentThemeColor
	badgeOuterStroke.Color = currentThemeColor
	badgeIcon.TextColor3 = currentThemeColor
	badgeGlow.BackgroundColor3 = currentThemeColor
	TelemetryBar.BorderColor3 = currentThemeColor
	TelemetryText.TextColor3 = currentThemeColor
	radarStroke.Color = currentThemeColor
	fovStroke.Color = currentThemeColor
	TargetHUDFrame.BorderColor3 = currentThemeColor
	thudTitle.TextColor3 = currentThemeColor
	if not S.TriggerIndicator then
		chDot.BackgroundColor3 = currentThemeColor
		for _, l in ipairs(chLines) do l.BackgroundColor3 = currentThemeColor end
	end

	-- Автообновление списка целей раз в 1.2 секунды, когда меню открыто
	local now = tick()
	if P.Visible and now - lastTargetListRefresh > 1.2 then
		lastTargetListRefresh = now
		refreshTargetListUI()
	end

	-- Freecam обновление
	if S.Freecam then
		local moveVec = Vector3.zero
		if not UIS:GetFocusedTextBox() then
			if UIS:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + Vector3.new(0, 0, -1) end
			if UIS:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec + Vector3.new(0, 0, 1) end
			if UIS:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec + Vector3.new(-1, 0, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + Vector3.new(1, 0, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.E) or UIS:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0, 1, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.Q) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec = moveVec - Vector3.new(0, -1, 0) end
		end
		
		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			local delta = UIS:GetMouseDelta()
			freecamAngles = Vector2.new(
				math.clamp(freecamAngles.X - delta.Y * 0.005, -math.rad(89), math.rad(89)),
				freecamAngles.Y - delta.X * 0.005
			)
		else
			UIS.MouseBehavior = Enum.MouseBehavior.Default
		end
		
		local rotCF = CFrame.fromEulerAnglesYXZ(freecamAngles.X, freecamAngles.Y, 0)
		local newPos = freecamCF.Position + (rotCF:VectorToWorldSpace(moveVec) * CFG.FreecamSpeed * dt * 2)
		freecamCF = CFrame.new(newPos) * rotCF
		Camera.CFrame = freecamCF
	end

	if S.CustomFOV then Camera.FieldOfView = CFG.CameraFOV end
	if S.Fullbright then
		Lighting.Brightness = 2.5
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(185, 185, 185)
	end
	if S.TimeChanger then Lighting.ClockTime = CFG.WorldTime end

	local myChar = getChar()
	local myHead = myChar and myChar:FindFirstChild("Head")
	local myRoot = getRoot()
	local allTargets = getValidTargets(false)

	-- Троттлинг текстовых HUD (10 раз в секунду)
	if now - lastHUDTick > 0.1 then
		lastHUDTick = now
		TelemetryBar.Visible = S.TelemetryHUD
		if S.TelemetryHUD then
			local spd = myRoot and math.floor(myRoot.AssemblyLinearVelocity.Magnitude) or 0
			local posStr = myRoot and string.format("(%d, %d, %d)", math.floor(myRoot.Position.X), math.floor(myRoot.Position.Y), math.floor(myRoot.Position.Z)) or "(0, 0, 0)"
			TelemetryText.Text = string.format("FPS: %d | SPD: %d | POS: %s | ENTITIES: %d", fpsSmoothed, spd, posStr, #allTargets)
		end

		InspectorFrame.Visible = S.PartInspector
		if S.PartInspector then
			local t = Mouse.Target
			if t then
				InspectorText.Text = string.format(
					"PART INSPECTOR:\nName: %s\nClass: %s | Anchored: %s\nCollide: %s | Size: (%.1f, %.1f, %.1f)",
					t.Name, t.ClassName, tostring(t.Anchored), tostring(t.CanCollide), t.Size.X, t.Size.Y, t.Size.Z
				)
			else
				InspectorText.Text = "PART INSPECTOR:\nTarget: [Void / Sky]"
			end
		end
	end

	-- Обновление локальных визуальных FX
	if S.Pulse and myPulse then
		if myChar and myPulse.Adornee ~= myChar then myPulse.Adornee = myChar end
		myPulse.OutlineColor = currentThemeColor
	end
	if S.Halo and myHalo and myHead then
		myHalo.Color = currentThemeColor
		myHalo.CFrame = myHead.CFrame * CFrame.new(0, 1.4 + math.sin(fxAngle * 1.5) * 0.15, 0) * CFrame.Angles(0, fxAngle, 0)
	end
	if S.ChinaHat and myChinaHat and myHead then
		myChinaHat.Color = currentThemeColor
		myChinaHat.CFrame = myHead.CFrame * CFrame.new(0, 1.05, 0) * CFrame.Angles(0, fxAngle * 0.8, 0)
	end
	if S.CyberShield and myCyberShield and myRoot then
		myCyberShield.Color = currentThemeColor
		myCyberShield.CFrame = myRoot.CFrame * CFrame.Angles(fxAngle * 0.4, fxAngle * 0.6, 0)
	end
	if S.OrbitOrbs and myRoot then
		for _, orb in ipairs(myOrbs) do
			if orb.Part and orb.Part.Parent then
				local a = fxAngle * 1.6 + orb.Offset
				local offset = Vector3.new(math.cos(a) * 4.2, math.sin(fxAngle * 2.5 + orb.Offset) * 1.3, math.sin(a) * 4.2)
				orb.Part.Position = myRoot.Position + offset
				orb.Part.Color = currentThemeColor
				if orb.Trail then orb.Trail.Color = ColorSequence.new(currentThemeColor) end
			end
		end
	end
	if S.CyberWings and myRoot then
		local flap = math.sin(fxAngle * 2.2) * 0.35
		for _, w in ipairs(myWings) do
			if w.Part and w.Part.Parent then
				w.Part.Color = currentThemeColor
				local spreadAngle = (w.Index * 0.22 + flap) * w.Side
				local cf = myRoot.CFrame * CFrame.new(w.Side * (0.6 + w.Index * 0.55), 0.8 - w.Index * 0.22, 0.85)
				w.Part.CFrame = cf * CFrame.Angles(0, math.rad(w.Side * 25), spreadAngle)
			end
		end
	end
	if S.GyroRings and myRoot then
		for idx, ring in ipairs(myGyroRings) do
			if ring and ring.Parent then
				ring.Color = currentThemeColor
				if idx == 1 then
					ring.CFrame = CFrame.new(myRoot.Position) * CFrame.Angles(fxAngle * 1.1, fxAngle * 0.7, 0)
				else
					ring.CFrame = CFrame.new(myRoot.Position) * CFrame.Angles(-fxAngle * 0.8, 0, fxAngle * 1.3)
				end
			end
		end
	end

	-- Crosshair & Trigger Indicator
	CustomCrosshair.Visible = S.Crosshair
	if S.Crosshair then
		CustomCrosshair.Rotation = (fxAngle * 45) % 360
		if S.TriggerIndicator then
			local mTarget = Mouse.Target
			local onEnemy = false
			if mTarget and mTarget.Parent then
				local hum = mTarget.Parent:FindFirstChildOfClass("Humanoid") or (mTarget.Parent.Parent and mTarget.Parent.Parent:FindFirstChildOfClass("Humanoid"))
				if hum and hum.Health > 0 and not mTarget:IsDescendantOf(myChar) then
					onEnemy = true
				end
			end
			local col = onEnemy and RED or currentThemeColor
			chDot.BackgroundColor3 = col
			for _, l in ipairs(chLines) do l.BackgroundColor3 = col end
		end
	end

	-- FOV Circle
	FOVFrame.Visible = S.ShowFOV and S.Aimbot
	if FOVFrame.Visible then
		FOVFrame.Size = UDim2.fromOffset(CFG.AimFOV * 2, CFG.AimFOV * 2)
	end

	-- 360 Radar HUD
	RadarFrame.Visible = S.RadarHUD
	if S.RadarHUD and myRoot then
		local camLook = Camera.CFrame.LookVector
		local camYaw = math.atan2(-camLook.X, -camLook.Z)
		local dotIdx = 1
		for _, t in ipairs(allTargets) do
			if t.RootPart then
				local rel = t.RootPart.Position - myRoot.Position
				local dist2D = Vector2.new(rel.X, rel.Z).Magnitude
				if dist2D <= CFG.RadarRange then
					local angle = math.atan2(rel.X, rel.Z) - camYaw
					local normDist = (dist2D / CFG.RadarRange) * 68
					local px = 75 + math.sin(angle) * normDist
					local py = 75 + math.cos(angle) * normDist

					local dot = radarDotsPool[dotIdx]
					if not dot then
						dot = Instance.new("Frame", RadarFrame)
						dot.Size = UDim2.new(0, 5, 0, 5)
						dot.AnchorPoint = Vector2.new(0.5, 0.5)
						Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
						radarDotsPool[dotIdx] = dot
					end
					dot.Position = UDim2.fromOffset(px, py)
					dot.BackgroundColor3 = t.IsPlayer and CFG.Color_PlayerVisible or CFG.Color_BotVisible
					dot.Visible = true
					dotIdx = dotIdx + 1
				end
			end
		end
		for i = dotIdx, #radarDotsPool do
			if radarDotsPool[i] then radarDotsPool[i].Visible = false end
		end
	end

	-- ESP, Boxes, Tracers, Skeletons, LookLasers
	local activeModels = {}
	local screenCenterBottom = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y - 10)

	for _, t in ipairs(allTargets) do
		local model = t.Model
		local root = t.RootPart
		local hum = t.Humanoid
		if model and root and hum then
			activeModels[model] = true
			local vis = isVisible(root)
			local col = t.IsPlayer and (vis and CFG.Color_PlayerVisible or CFG.Color_PlayerHidden) or (vis and CFG.Color_BotVisible or CFG.Color_BotHidden)

			-- Highlight ESP
			local allowESP = S.ESP and checkDistance(root, CFG.ESP_MaxDist) and (not CFG.ESP_WallCheck or vis) and not (CFG.ESP_TeamCheck and t.IsPlayer and isTeammate(t.Player))
			if allowESP then
				local hl = espHighlights[model]
				if not hl then
					hl = Instance.new("Highlight", SG)
					hl.Adornee = model
					hl.FillTransparency = 0.65
					espHighlights[model] = hl
				end
				hl.FillColor = col
				hl.OutlineColor = col
				hl.Enabled = true
			elseif espHighlights[model] then
				espHighlights[model].Enabled = false
			end

			-- 2D Box, Health, Name ESP
			local allowBox = (S.BoxESP or S.HealthESP or S.NameESP) and checkDistance(root, CFG.ESP_MaxDist) and (not CFG.ESP_WallCheck or vis) and not (CFG.ESP_TeamCheck and t.IsPlayer and isTeammate(t.Player))
			if allowBox then
				local topPos, onTop = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.2, 0))
				local botPos, onBot = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
				if (onTop or onBot) and topPos.Z > 0 and botPos.Z > 0 then
					local bData = getOrCreateBoxData(model)
					local hSize = math.abs(botPos.Y - topPos.Y)
					local wSize = hSize * 0.62
					bData.Container.Position = UDim2.fromOffset(topPos.X - wSize * 0.5, topPos.Y)
					bData.Container.Size = UDim2.fromOffset(wSize, hSize)
					bData.Container.Visible = true
					
					bData.Stroke.Enabled = S.BoxESP
					bData.Stroke.Color = col
					
					bData.HpBG.Visible = S.HealthESP
					if S.HealthESP then
						local hpRatio = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
						bData.HpFill.Size = UDim2.new(1, 0, hpRatio, 0)
						bData.HpFill.BackgroundColor3 = Color3.fromHSV(hpRatio * 0.33, 0.9, 1)
					end
					
					bData.NameLbl.Visible = S.NameESP
					if S.NameESP then
						local distMeters = myRoot and math.floor((myRoot.Position - root.Position).Magnitude) or 0
						bData.NameLbl.Text = string.format("%s [%dm]", t.ShortName or t.Name, distMeters)
						bData.NameLbl.TextColor3 = col
					end
				elseif boxPool[model] then
					boxPool[model].Container.Visible = false
				end
			elseif boxPool[model] then
				boxPool[model].Container.Visible = false
			end

			-- Tracers
			local allowTracer = S.Tracers and checkDistance(root, CFG.Tracer_MaxDist) and (not CFG.Tracer_WallCheck or vis) and not (CFG.TracerTeamCheck and t.IsPlayer and isTeammate(t.Player))
			if allowTracer then
				local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
				if onScreen and screenPos.Z > 0 then
					local tf = tracerFrames[model]
					if not tf then
						tf = Instance.new("Frame", DrawLayer)
						tf.AnchorPoint = Vector2.new(0.5, 0.5)
						tf.BorderSizePixel = 0
						tracerFrames[model] = tf
					end
					drawLineUI(tf, screenCenterBottom, Vector2.new(screenPos.X, screenPos.Y), col, 1.4)
				elseif tracerFrames[model] then
					tracerFrames[model].Visible = false
				end
			elseif tracerFrames[model] then
				tracerFrames[model].Visible = false
			end

			-- Look Laser ESP
			if S.LookLaserESP and checkDistance(root, CFG.ESP_MaxDist) then
				local head = model:FindFirstChild("Head")
				if head then
					local p1, on1 = Camera:WorldToViewportPoint(head.Position)
					local p2, on2 = Camera:WorldToViewportPoint(head.Position + head.CFrame.LookVector * 9)
					if (on1 or on2) and p1.Z > 0 and p2.Z > 0 then
						local lf = lookLaserFrames[model]
						if not lf then
							lf = Instance.new("Frame", DrawLayer)
							lf.AnchorPoint = Vector2.new(0.5, 0.5)
							lf.BorderSizePixel = 0
							lookLaserFrames[model] = lf
						end
						drawLineUI(lf, Vector2.new(p1.X, p1.Y), Vector2.new(p2.X, p2.Y), Color3.fromRGB(255, 50, 50), 1.6)
					elseif lookLaserFrames[model] then
						lookLaserFrames[model].Visible = false
					end
				end
			elseif lookLaserFrames[model] then
				lookLaserFrames[model].Visible = false
			end

			-- Skeleton ESP
			local allowSkel = S.Skeleton and checkDistance(root, CFG.Skeleton_MaxDist) and (not CFG.Skeleton_WallCheck or vis) and not (CFG.SkeletonTeamCheck and t.IsPlayer and isTeammate(t.Player))
			if allowSkel then
				updateSkeletonForModel(model, col)
			else
				clearSkeleton(model)
			end
		end
	end

	-- Очистка пропавших моделей из ESP пулов
	for model, hl in pairs(espHighlights) do
		if not activeModels[model] then hl:Destroy() espHighlights[model] = nil end
	end
	for model, _ in pairs(boxPool) do
		if not activeModels[model] then clearBoxData(model) end
	end
	for model, tf in pairs(tracerFrames) do
		if not activeModels[model] then tf:Destroy() tracerFrames[model] = nil end
	end
	for model, lf in pairs(lookLaserFrames) do
		if not activeModels[model] then lf:Destroy() lookLaserFrames[model] = nil end
	end
	for model, _ in pairs(skeletonPool) do
		if not activeModels[model] then clearSkeleton(model) end
	end

	-- Aimbot & Target HUD
	local bestTarget = nil
	local bestDist = CFG.AimFOV
	local viewportCenter = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)

	if S.Aimbot or S.TargetHUD then
		local validForAim = getValidTargets(CFG.AimTeamCheck)
		for _, t in ipairs(validForAim) do
			local aimPart = t.Model:FindFirstChild(CFG.AimPart) or t.RootPart
			if aimPart and checkDistance(aimPart, CFG.Aim_MaxDist) then
				if not CFG.Aim_WallCheck or isVisible(aimPart) then
					local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
					if onScreen and screenPos.Z > 0 then
						local mag = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
						if mag < bestDist then
							bestDist = mag
							bestTarget = {Data = t, AimPart = aimPart}
						end
					end
				end
			end
		end
	end

	if S.TargetHUD and bestTarget then
		local tData = bestTarget.Data
		local distM = myRoot and math.floor((myRoot.Position - tData.RootPart.Position).Magnitude) or 0
		local hp = math.floor(tData.Humanoid.Health)
		local maxHp = math.floor(tData.Humanoid.MaxHealth)
		local ratio = math.clamp(hp / math.max(1, maxHp), 0, 1)
		
		TargetHUDFrame.Visible = true
		thudTitle.Text = "TARGET: " .. string.upper(tData.ShortName or tData.Name)
		thudSub.Text = string.format("HP: %d/%d | DIST: %dm", hp, maxHp, distM)
		thudBarFill.Size = UDim2.new(ratio, 0, 1, 0)
		thudBarFill.BackgroundColor3 = Color3.fromHSV(ratio * 0.33, 0.9, 1)
	else
		TargetHUDFrame.Visible = false
	end

	if S.Aimbot and bestTarget and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and not S.Freecam then
		local aimPart = bestTarget.AimPart
		local targetPos = aimPart.Position
		if CFG.AimPrediction then
			targetPos = targetPos + (aimPart.AssemblyLinearVelocity * CFG.PredictionFactor)
		end
		local goalCF = CFrame.new(Camera.CFrame.Position, targetPos)
		local alpha = math.clamp(1 / math.max(1, CFG.AimSmoothness), 0.05, 1)
		Camera.CFrame = Camera.CFrame:Lerp(goalCF, alpha)
	end
end)

-- ==========================================
-- НАПОЛНЕНИЕ КАТЕГОРИЙ И ФУНКЦИЙ МЕНЮ
-- ==========================================

-- 1. Быстрый телепорт и выбор игроков/ботов
local catTP = makeCategory("TELEPORT & TARGET SELECTOR", true)

targetLabelUI = Instance.new("TextLabel", catTP)
targetLabelUI.Size = UDim2.new(1, 0, 0, 24)
targetLabelUI.BackgroundColor3 = BLACK
targetLabelUI.BorderSizePixel = 1
targetLabelUI.BorderColor3 = GREEN
targetLabelUI.Text = "Цель: [НЕ ВЫБРАНА]"
targetLabelUI.TextColor3 = TXT
targetLabelUI.Font = Enum.Font.Code
targetLabelUI.TextSize = 11
targetLabelUI.ZIndex = 2
targetLabelUI.LayoutOrder = nextOrder()
Instance.new("UICorner", targetLabelUI).CornerRadius = UDim.new(0, 4)

-- Строка поиска цели
local searchBox = Instance.new("TextBox", catTP)
searchBox.Size = UDim2.new(1, 0, 0, 26)
searchBox.BackgroundColor3 = ELEM_BG
searchBox.BorderSizePixel = 1
searchBox.BorderColor3 = DARK_GREEN
searchBox.PlaceholderText = "Поиск игрока или бота по имени..."
searchBox.PlaceholderColor3 = Color3.fromRGB(130, 145, 135)
searchBox.Text = ""
searchBox.TextColor3 = GREEN
searchBox.Font = Enum.Font.Code
searchBox.TextSize = 11
searchBox.ClearTextOnFocus = false
searchBox.ZIndex = 2
searchBox.LayoutOrder = nextOrder()
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 4)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	targetSearchFilter = searchBox.Text
	refreshTargetListUI()
end)

-- Быстрые кнопки телепорта
local quickBtnsRow = Instance.new("Frame", catTP)
quickBtnsRow.Size = UDim2.new(1, 0, 0, 26)
quickBtnsRow.BackgroundTransparency = 1
quickBtnsRow.LayoutOrder = nextOrder()
quickBtnsRow.ZIndex = 2

local tpSelectedBtn = Instance.new("TextButton", quickBtnsRow)
tpSelectedBtn.Size = UDim2.new(0.49, 0, 1, 0)
tpSelectedBtn.Position = UDim2.new(0, 0, 0, 0)
tpSelectedBtn.BackgroundColor3 = DARK_GREEN
tpSelectedBtn.BorderSizePixel = 1
tpSelectedBtn.BorderColor3 = GREEN
tpSelectedBtn.Text = "TP к Выбранному"
tpSelectedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpSelectedBtn.Font = Enum.Font.Code
tpSelectedBtn.TextSize = 10
tpSelectedBtn.ZIndex = 2
Instance.new("UICorner", tpSelectedBtn).CornerRadius = UDim.new(0, 4)

local tpNearestBtn = Instance.new("TextButton", quickBtnsRow)
tpNearestBtn.Size = UDim2.new(0.49, 0, 1, 0)
tpNearestBtn.Position = UDim2.new(0.51, 0, 0, 0)
tpNearestBtn.BackgroundColor3 = DARK_GREEN
tpNearestBtn.BorderSizePixel = 1
tpNearestBtn.BorderColor3 = GREEN
tpNearestBtn.Text = "TP к Ближайшему"
tpNearestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpNearestBtn.Font = Enum.Font.Code
tpNearestBtn.TextSize = 10
tpNearestBtn.ZIndex = 2
Instance.new("UICorner", tpNearestBtn).CornerRadius = UDim.new(0, 4)

tpSelectedBtn.MouseButton1Click:Connect(function()
	if currentSelectedTarget then
		teleportToTarget(currentSelectedTarget)
	end
end)

tpNearestBtn.MouseButton1Click:Connect(function()
	local list = getValidTargets(false)
	local myRoot = getRoot()
	if not myRoot or #list == 0 then return end
	local best, minDist = nil, math.huge
	for _, t in ipairs(list) do
		if t.RootPart then
			local d = (t.RootPart.Position - myRoot.Position).Magnitude
			if d < minDist then
				minDist = d
				best = t
			end
		end
	end
	if best then
		setSelectedTarget(best)
		teleportToTarget(best)
		refreshTargetListUI()
	end
end)

-- Прокручиваемый список всех игроков и ботов
targetListFrame = Instance.new("ScrollingFrame", catTP)
targetListFrame.Size = UDim2.new(1, 0, 0, 145)
targetListFrame.BackgroundColor3 = BLACK
targetListFrame.BackgroundTransparency = 0.2
targetListFrame.BorderSizePixel = 1
targetListFrame.BorderColor3 = DARK_GREEN
targetListFrame.ScrollBarThickness = 3
targetListFrame.ScrollBarImageColor3 = GREEN
targetListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
targetListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
targetListFrame.ZIndex = 2
targetListFrame.LayoutOrder = nextOrder()
Instance.new("UICorner", targetListFrame).CornerRadius = UDim.new(0, 4)

local tListLayout = Instance.new("UIListLayout", targetListFrame)
tListLayout.Padding = UDim.new(0, 3)
tListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local tListPad = Instance.new("UIPadding", targetListFrame)
tListPad.PaddingTop = UDim.new(0, 4)
tListPad.PaddingBottom = UDim.new(0, 4)
tListPad.PaddingLeft = UDim.new(0, 4)

makeToggle(catTP, "Показывать Игроков в списке", true, function(v)
	CFG.TargetPlayers = v
	lastTargetUpdate = 0
	refreshTargetListUI()
end)
makeToggle(catTP, "Показывать Ботов (NPC) в списке", true, function(v)
	CFG.TargetBots = v
	lastTargetUpdate = 0
	refreshTargetListUI()
end)
makeToggle(catTP, "Ctrl + Click Телепорт по Курсору", false, function(v) S.CtrlClickTP = v end)

-- 2. Троллинг
local catTroll = makeCategory("TROLLING & TARGET ACTIONS", true)

makeToggle(catTroll, "Spinbot (Вращение Персонажа)", false, function(v)
	S.Spinbot = v
	toggleSpinbot(v)
end)
makeSlider(catTroll, "Скорость Spinbot", 5, 120, 35, function(v) CFG.SpinSpeed = v end)

makeToggle(catTroll, "Orbit Selected Target (Вращаться Вокруг)", false, function(v)
	S.OrbitTarget = v
end)
makeSlider(catTroll, "Радиус Орбиты", 3, 25, 8, function(v) CFG.OrbitRadius = v end)
makeSlider(catTroll, "Скорость Орбиты", 1, 15, 4, function(v) CFG.OrbitSpeed = v end)

makeToggle(catTroll, "Head Sit On Target (Сесть на Голову)", false, function(v)
	S.HeadSit = v
end)
makeToggle(catTroll, "Mimic Target (Копировать Движения Сзади)", false, function(v)
	S.MimicTarget = v
end)
makeToggle(catTroll, "Spectate Target (Следить Камерой)", false, function(v)
	S.SpectateTarget = v
	if v and currentSelectedTarget and currentSelectedTarget.Humanoid then
		Camera.CameraSubject = currentSelectedTarget.Humanoid
	else
		local h = getHum()
		if h then Camera.CameraSubject = h end
	end
end)
makeToggle(catTroll, "Fling Touch (Откидывать Игроков Касанием)", false, function(v)
	S.FlingTouch = v
	toggleFlingTouch(v)
end)
makeToggle(catTroll, "Fake Lag (Имитация Высокого Пинга)", false, function(v)
	S.FakeLag = v
	local r = getRoot()
	if not v and r then r.Anchored = S.FreezeChar end
end)
makeToggle(catTroll, "Anti-Fling Защита", false, function(v)
	S.AntiFling = v
	if not v then restoreAntiFling() end
end)

-- 3. Передвижение и Физика
local catMove = makeCategory("MOVEMENT & CHARACTER", true)
makeToggle(catMove, "Speed & Jump Lock", false, function(v)
	S.SpeedLock = v
	if not v then
		local h = getHum()
		if h then h.WalkSpeed = 16 h.JumpPower = 50 end
	end
end)
makeSlider(catMove, "WalkSpeed", 16, 250, 16, function(v) CFG.Speed = v end)
makeSlider(catMove, "JumpPower", 50, 350, 50, function(v) CFG.Jump = v end)
makeToggle(catMove, "Fly Mode (WASD + Space/Shift)", false, function(v)
	S.Fly = v
	if v then startFly() else stopFly() end
end)
makeSlider(catMove, "Fly Speed", 20, 300, 65, function(v) CFG.FlySpeed = v end)
makeToggle(catMove, "Jetpack (Hold Space)", false, function(v) S.Jetpack = v end)
makeToggle(catMove, "Infinite Jump", false, function(v) S.InfiniteJump = v end)
makeToggle(catMove, "Auto BunnyHop", false, function(v) S.AutoBhop = v end)
makeToggle(catMove, "Spider Climb (Лазать по Стенам)", false, function(v) S.SpiderClimb = v end)
makeToggle(catMove, "AirWalk Platform (E/Q Высота)", false, function(v)
	S.AirWalk = v
	toggleAirWalk(v)
end)
makeToggle(catMove, "Noclip (Проход Сквозь Стены)", false, function(v)
	S.Noclip = v
	if v then enableNoclip() else disableNoclip() end
end)
makeButton(catMove, "Dash Forward [Рывок Вперед]", DARK_GREEN, performDash)
makeButton(catMove, "Spawn Neon Platform [Клавиша: Z]", DARK_GREEN, spawnNeonPad)

-- 4. Локальный Визуал Персонажа (Client FX)
local catFX = makeCategory("CHARACTER VISUAL FX (CLIENT)", false)
makeToggle(catFX, "Cyber Neon Wings (Анимированные)", false, function(v) S.CyberWings = v toggleCyberWings(v) end)
makeToggle(catFX, "Gyroscopic Matrix Rings", false, function(v) S.GyroRings = v toggleGyroRings(v) end)
makeToggle(catFX, "Lightning Storm Aura", false, function(v) S.LightningFX = v end)
makeToggle(catFX, "Ghost Clone Trail", false, function(v) S.GhostTrail = v end)
makeToggle(catFX, "Orbiting Neon Orbs", false, function(v) S.OrbitOrbs = v toggleOrbitOrbs(v) end)
makeToggle(catFX, "China Hat (Неоновая Шляпа)", false, function(v) S.ChinaHat = v toggleChinaHat(v) end)
makeToggle(catFX, "Floating Halo Ring", false, function(v) S.Halo = v toggleHalo(v) end)
makeToggle(catFX, "Cyber ForceField Shield", false, function(v) S.CyberShield = v toggleCyberShield(v) end)
makeToggle(catFX, "Highlight Outline Pulse", false, function(v) S.Pulse = v togglePulse(v) end)
makeToggle(catFX, "Sparkle Particle Aura", false, function(v) S.Aura = v toggleAura(v) end)
makeToggle(catFX, "Footstep Shockwaves", false, function(v) S.StepWaves = v end)
makeToggle(catFX, "Motion Neon Trail", false, function(v) S.Trail = v toggleTrail(v) end)
makeToggle(catFX, "Headless Horseman (Визуал)", false, function(v) S.headlessVisual = v toggleHeadless(v) end)

-- 5. ESP и Визуальная разведка
local catESP = makeCategory("ESP & RADAR VISUALS", false)
makeToggle(catESP, "Chams Highlight ESP", false, function(v) S.ESP = v end)
makeToggle(catESP, "2D Box ESP", false, function(v) S.BoxESP = v end)
makeToggle(catESP, "Health Bar ESP", false, function(v) S.HealthESP = v end)
makeToggle(catESP, "Name & Distance ESP", false, function(v) S.NameESP = v end)
makeToggle(catESP, "Skeleton Bone ESP", false, function(v) S.Skeleton = v end)
makeToggle(catESP, "Snapline Tracers", false, function(v) S.Tracers = v end)
makeToggle(catESP, "Look Direction Lasers", false, function(v) S.LookLaserESP = v end)
makeToggle(catESP, "360 Mini-Radar HUD", false, function(v) S.RadarHUD = v end)
makeColorPicker(catESP, "Player Visible Color", CFG.Color_PlayerVisible, function(c) CFG.Color_PlayerVisible = c end)
makeColorPicker(catESP, "Bot Visible Color", CFG.Color_BotVisible, function(c) CFG.Color_BotVisible = c end)

-- 6. Боевой модуль и Хитбоксы
local catCombat = makeCategory("COMBAT & HITBOX SUITE", false)
makeToggle(catCombat, "Aimbot (Зажать Правую Кнопку Мыши)", false, function(v) S.Aimbot = v end)
makeToggle(catCombat, "Show Aimbot FOV Circle", false, function(v) S.ShowFOV = v end)
makeSlider(catCombat, "Aimbot FOV Radius", 30, 450, 150, function(v) CFG.AimFOV = v end)
makeSlider(catCombat, "Aimbot Smoothness", 1, 20, 4, function(v) CFG.AimSmoothness = v end)
makeToggle(catCombat, "Velocity Prediction", true, function(v) CFG.AimPrediction = v end)
makeToggle(catCombat, "Hitbox Expander (Neon Root)", false, function(v)
	S.HitboxExpander = v
	if not v then resetHitboxes() end
end)
makeSlider(catCombat, "Hitbox Size", 2, 25, 6, function(v) CFG.HitboxSize = v end)
makeToggle(catCombat, "Big Heads Mode", false, function(v)
	S.BigHeads = v
	if not v then resetBigHeads() end
end)
makeToggle(catCombat, "Rotating Cyber Crosshair", false, function(v) S.Crosshair = v end)
makeToggle(catCombat, "Trigger Crosshair Color Alert", false, function(v) S.TriggerIndicator = v end)

-- 7. Мир, Камера и Система
local catWorld = makeCategory("WORLD, CAMERA & HUD", false)
makeToggle(catWorld, "RGB Rainbow Theme", false, function(v) S.RainbowMode = v end)
makeToggle(catWorld, "Top Telemetry Bar", true, function(v) S.TelemetryHUD = v end)
makeToggle(catWorld, "Part Inspector HUD", false, function(v) S.PartInspector = v end)
makeToggle(catWorld, "Freecam (ПКМ для вращения)", false, function(v)
	S.Freecam = v
	toggleFreecam(v)
end)
makeToggle(catWorld, "X-Ray Walls", false, function(v)
	S.XRay = v
	toggleXRay(v)
end)
makeToggle(catWorld, "Fullbright Lighting", false, function(v)
	S.Fullbright = v
	if not v then
		Lighting.Brightness = OrigWorld.Brightness
		Lighting.FogEnd = OrigWorld.FogEnd
		Lighting.GlobalShadows = OrigWorld.GlobalShadows
		Lighting.Ambient = OrigWorld.Ambient
	end
end)
makeToggle(catWorld, "Custom Camera FOV", false, function(v)
	S.CustomFOV = v
	if not v then Camera.FieldOfView = OrigWorld.FOV end
end)
makeSlider(catWorld, "Camera FOV Value", 40, 120, 70, function(v) CFG.CameraFOV = v end)
makeSlider(catWorld, "World Gravity", 10, 400, CFG.Gravity, function(v)
	CFG.Gravity = v
	workspace.Gravity = v
end)
makeToggle(catWorld, "Infinite Camera Zoom", false, function(v)
	S.InfiniteZoom = v
	LP.CameraMaxZoomDistance = v and 100000 or OrigWorld.MaxZoom
end)

-- Первичная отрисовка списка целей
refreshTargetListUI()

-- ==========================================
-- ОБРАБОТКА ВВОДА, ПЕРЕТАСКИВАНИЯ И ХОТКЕЕВ
-- ==========================================
local draggingMenu = false
local dragStartPos, frameStartPos

local draggingBadge = false
local badgeMoved = false
local badgeDragStart, badgeStartPos

TB.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingMenu = true
		dragStartPos = input.Position
		frameStartPos = P.Position
	end
end)

badgeBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingBadge = true
		badgeMoved = false
		badgeDragStart = input.Position
		badgeStartPos = ToggleBadge.Position
	end
end)

badgeBtn.MouseButton1Click:Connect(function()
	if not badgeMoved then
		P.Visible = not P.Visible
		badgeSub.Text = P.Visible and "OPEN" or "HIDE"
		if P.Visible then refreshTargetListUI() end
	end
end)

bindConnection(UIS.InputChanged, function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if draggingMenu then
			local delta = input.Position - dragStartPos
			P.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X, frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y)
		elseif draggingBadge then
			local delta = input.Position - badgeDragStart
			if delta.Magnitude > 5 then
				badgeMoved = true
				ToggleBadge.Position = UDim2.new(badgeStartPos.X.Scale, badgeStartPos.X.Offset + delta.X, badgeStartPos.Y.Scale, badgeStartPos.Y.Offset + delta.Y)
			end
		elseif activeSliderUpdate then
			activeSliderUpdate(input.Position)
		end
	end
end)

bindConnection(UIS.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingMenu = false
		draggingBadge = false
		activeSliderUpdate = nil
	end
end)

bindConnection(UIS.JumpRequest, function()
	if S.InfiniteJump then
		local h = getHum()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

bindConnection(UIS.InputBegan, function(input, gpe)
	if bindingFeatureName and input.UserInputType == Enum.UserInputType.Keyboard then
		local key = (input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= Enum.KeyCode.Backspace) and input.KeyCode or nil
		Keybinds[bindingFeatureName] = key
		if _G.BaggetBinds[bindingFeatureName] then
			_G.BaggetBinds[bindingFeatureName].updateBtn(key)
		end
		bindingFeatureName = nil
		return
	end

	if gpe then return end

	if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
		P.Visible = not P.Visible
		badgeSub.Text = P.Visible and "OPEN" or "HIDE"
		if P.Visible then refreshTargetListUI() end
	elseif input.KeyCode == Enum.KeyCode.Z then
		spawnNeonPad()
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if S.CtrlClickTP and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
			local r = getRoot()
			if r and Mouse.Hit then
				r.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3.5, 0))
			end
		end
	end

	for featName, key in pairs(Keybinds) do
		if key and input.KeyCode == key and _G.BaggetBinds[featName] then
			_G.BaggetBinds[featName].trigger()
		end
	end
end)

-- Сворачивание и закрытие окна
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	SF.Visible = not minimized
	AsciiBG.Visible = not minimized
	EmojiBG.Parent = minimized and nil or P
	P.Size = minimized and UDim2.new(0, 365, 0, 32) or UDim2.new(0, 365, 0, 580)
end)

local function fullCleanup()
	stopFly()
	disableNoclip()
	toggleFlingTouch(false)
	toggleSpinbot(false)
	toggleAirWalk(false)
	toggleXRay(false)
	toggleFreecam(false)
	togglePulse(false)
	toggleAura(false)
	toggleHalo(false)
	toggleChinaHat(false)
	toggleCyberShield(false)
	toggleCyberWings(false)
	toggleGyroRings(false)
	toggleOrbitOrbs(false)
	toggleTrail(false)
	toggleHeadless(false)
	restoreAntiFling()
	resetHitboxes()
	resetBigHeads()

	local h = getHum()
	if h then Camera.CameraSubject = h end

	workspace.Gravity = OrigWorld.Gravity
	Camera.FieldOfView = OrigWorld.FOV
	LP.CameraMaxZoomDistance = OrigWorld.MaxZoom
	Lighting.Brightness = OrigWorld.Brightness
	Lighting.ClockTime = OrigWorld.ClockTime
	Lighting.FogEnd = OrigWorld.FogEnd
	Lighting.GlobalShadows = OrigWorld.GlobalShadows
	Lighting.Ambient = OrigWorld.Ambient

	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	for _, p in ipairs(SpawnedParts) do pcall(function() if p then p:Destroy() end end) end
	if SG then SG:Destroy() end
end

_G.BaggetCleanup = fullCleanup
CB.MouseButton1Click:Connect(fullCleanup)

-- Авто-перепривязка при респавне персонажа
bindConnection(LP.CharacterAdded, function()
	task.wait(0.4)
	if S.Fly then startFly() end
	if S.Noclip then enableNoclip() end
	if S.FlingTouch then toggleFlingTouch(true) end
	if S.Spinbot then toggleSpinbot(true) end
	if S.Pulse then togglePulse(true) end
	if S.Aura then toggleAura(true) end
	if S.Trail then toggleTrail(true) end
	if S.headlessVisual then toggleHeadless(true) end
end)
