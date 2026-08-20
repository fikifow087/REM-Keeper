local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. MENGAMBIL ELEMEN UI
local mainStatsGui = playerGui:WaitForChild("REM_PlayerMainStats_GUI", 10)
if not mainStatsGui then
	warn("[ERROR] REM_PlayerMainStats_GUI tidak ditemukan!")
	return
end

local frame = mainStatsGui:WaitForChild("Frame")

-- Player Bar Elements
local barHPPlayer = frame:WaitForChild("Bar_HP_Player")
local barHPPlayerBuffer = frame:WaitForChild("Bar_HP_Player_Buffer")
local barHPPlayerBG = frame:WaitForChild("Bar_HP_Player_BG")

-- House Bar Elements
local barHPHouse = frame:WaitForChild("Bar_HP_House")
local barHPHouseBuffer = frame:WaitForChild("Bar_HP_House_Buffer")
local barHPHouseBG = frame:WaitForChild("Bar_HP_House_BG")

-- ==========================================
-- KALKULASI UKURAN BAR TERHADAP BACKGROUND
-- ==========================================
local function getHealthBarSize(bgBar, ratio)
	return UDim2.new(bgBar.Size.X.Scale * ratio, bgBar.Size.X.Offset * ratio, bgBar.Size.Y.Scale, bgBar.Size.Y.Offset)
end

-- ==========================================
-- EFEK BUFFER & ANIMASI HEALTH BAR
-- ==========================================
local function createHealthBarController(mainBar, bufferBar, backgroundBar)
	local controller = {
		mainBar = mainBar,
		bufferBar = bufferBar,
		backgroundBar = backgroundBar,
		lastHealth = nil,
		bufferThread = nil,
	}

	function controller:Update(health, maxHealth)
		local max = math.max(maxHealth, 1)
		local ratio = math.clamp(health / max, 0, 1)
		local targetSize = getHealthBarSize(controller.backgroundBar, ratio)

		-- Animasi Bar Utama
		local mainInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(controller.mainBar, mainInfo, { Size = targetSize }):Play()

		-- Inisialisasi awal
		if controller.lastHealth == nil then
			controller.lastHealth = health
			controller.bufferBar.Size = targetSize
			return
		end

		-- Logika Efek Buffer
		if health < controller.lastHealth then
			if controller.bufferThread then
				task.cancel(controller.bufferThread)
			end

			controller.bufferThread = task.delay(0.3, function()
				local bufferInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
				TweenService:Create(controller.bufferBar, bufferInfo, { Size = targetSize }):Play()
			end)
		else
			if controller.bufferThread then
				task.cancel(controller.bufferThread)
			end
			local bufferInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(controller.bufferBar, bufferInfo, { Size = targetSize }):Play()
		end

		controller.lastHealth = health
	end

	return controller
end

-- Instance Controller
local playerBarController = createHealthBarController(barHPPlayer, barHPPlayerBuffer, barHPPlayerBG)
local houseBarController = createHealthBarController(barHPHouse, barHPHouseBuffer, barHPHouseBG)

-- ==========================================
-- SYSTEM PLAYER HEALTH
-- ==========================================
local function setupPlayerHealth(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end

	local function updatePlayer()
		playerBarController:Update(humanoid.Health, humanoid.MaxHealth)
	end

	humanoid.HealthChanged:Connect(updatePlayer)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updatePlayer)
	updatePlayer()
end

player.CharacterAdded:Connect(setupPlayerHealth)
if player.Character then
	setupPlayerHealth(player.Character)
end

-- ==========================================
-- SYSTEM HOUSE HEALTH (HouseCore -> Humanoid)
-- ==========================================
local function setupHouseHealth()
	local houseCore = Workspace:WaitForChild("HouseCore", 15)
	if not houseCore then
		warn("[ERROR] HouseCore tidak ditemukan di Workspace!")
		return
	end

	local houseHumanoid = houseCore:WaitForChild("Humanoid", 10)
	if not houseHumanoid then
		warn("[ERROR] Humanoid tidak ditemukan di dalam HouseCore!")
		return
	end

	local function updateHouse()
		houseBarController:Update(houseHumanoid.Health, houseHumanoid.MaxHealth)
	end

	houseHumanoid.HealthChanged:Connect(updateHouse)
	houseHumanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHouse)
	updateHouse()
end

task.spawn(setupHouseHealth)
