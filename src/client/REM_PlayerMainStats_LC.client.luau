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

-- House Bar Elements
local barHPHouse = frame:WaitForChild("Bar_HP_House")
local barHPHouseBuffer = frame:WaitForChild("Bar_HP_House_Buffer")

local function getHealthBarSize(bar, ratio)
	local currentSize = bar.Size
	return UDim2.new(ratio, 0, currentSize.Y.Scale, currentSize.Y.Offset)
end

-- ==========================================
-- EFEK BUFFER & ANIMASI HEALTH BAR
-- ==========================================
local function createHealthBarController(mainBar, bufferBar)
	local controller = {
		mainBar = mainBar,
		bufferBar = bufferBar,
		lastHealth = nil,
		bufferThread = nil,
	}

	function controller:Update(health, maxHealth)
		local max = math.max(maxHealth, 1)
		local ratio = math.clamp(health / max, 0, 1)

		-- Animasi Bar Utama (Langsung merespon damage/heal)
		local mainInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(controller.mainBar, mainInfo, { Size = getHealthBarSize(controller.mainBar, ratio) }):Play()

		-- Inisialisasi awal saat pertama kali dimuat
		if controller.lastHealth == nil then
			controller.lastHealth = health
			controller.bufferBar.Size = getHealthBarSize(controller.bufferBar, ratio)
			return
		end

		-- Logika Efek Buffer
		if health < self.lastHealth then
			-- Terkena Damage: Batalkan delay buffer sebelumnya jika ada damage bertubi-tubi
			if controller.bufferThread then
				task.cancel(controller.bufferThread)
			end

			-- Tahan sebentar (0.3s), lalu susul penurunan darah dengan halus (0.5s)
			controller.bufferThread = task.delay(0.3, function()
				local bufferInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
				TweenService:Create(controller.bufferBar, bufferInfo, { Size = getHealthBarSize(controller.bufferBar, ratio) }):Play()
			end)
		else
			-- Bertambah Darah (Heal): Langsung samakan buffer bar tanpa delay
			if controller.bufferThread then
				task.cancel(controller.bufferThread)
			end
			local bufferInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(controller.bufferBar, bufferInfo, { Size = getHealthBarSize(controller.bufferBar, ratio) }):Play()
		end

		controller.lastHealth = health
	end

	return controller
end

-- Instance Controller untuk Player dan House
local playerBarController = createHealthBarController(barHPPlayer, barHPPlayerBuffer)
local houseBarController = createHealthBarController(barHPHouse, barHPHouseBuffer)

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
