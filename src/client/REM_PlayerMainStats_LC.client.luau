local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Variable penampung koneksi player agar tidak tumpang tindih saat respawn
local healthChangedConn = nil
local maxHealthChangedConn = nil

local function getHealthBarSize(bgBar, ratio)
	return UDim2.new(bgBar.Size.X.Scale * ratio, bgBar.Size.X.Offset * ratio, bgBar.Size.Y.Scale, bgBar.Size.Y.Offset)
end

-- Function mengambil/refresh referensi elemen UI
local function getGuiElements()
	local mainStatsGui = playerGui:WaitForChild("REM_PlayerMainStats_GUI", 10)
	if not mainStatsGui then
		return nil
	end

	mainStatsGui.ResetOnSpawn = false

	local frame = mainStatsGui:WaitForChild("Frame", 5)
	if not frame then
		return nil
	end

	return {
		playerMain = frame:WaitForChild("Bar_HP_Player"),
		playerBuffer = frame:WaitForChild("Bar_HP_Player_Buffer"),
		playerBG = frame:WaitForChild("Bar_HP_Player_BG"),
		houseMain = frame:WaitForChild("Bar_HP_House"),
		houseBuffer = frame:WaitForChild("Bar_HP_House_Buffer"),
		houseBG = frame:WaitForChild("Bar_HP_House_BG"),
	}
end

local elements = getGuiElements()
if not elements then
	warn("[ERROR] Gagal memuat elemen UI REM_PlayerMainStats_GUI!")
	return
end

-- Controller dengan Getter Dinamis (selalu menunjuk ke UI aktif)
local function createHealthBarController(getMainBar, getBufferBar, getBgBar)
	local controller = {
		lastHealth = nil,
		bufferThread = nil,
	}

	function controller:Update(health, maxHealth)
		local mainBar = getMainBar()
		local bufferBar = getBufferBar()
		local bgBar = getBgBar()

		if not (mainBar and bufferBar and bgBar) then
			return
		end

		local max = math.max(maxHealth, 1)
		local ratio = math.clamp(health / max, 0, 1)
		local targetSize = getHealthBarSize(bgBar, ratio)

		-- Animasi Bar Utama
		local mainInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(mainBar, mainInfo, { Size = targetSize }):Play()

		-- Inisialisasi awal
		if controller.lastHealth == nil then
			controller.lastHealth = health
			bufferBar.Size = targetSize
			return
		end

		-- Logika Efek Buffer
		if health < controller.lastHealth then
			if controller.bufferThread then
				task.cancel(controller.bufferThread)
			end

			controller.bufferThread = task.delay(0.3, function()
				local bufferInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
				TweenService:Create(bufferBar, bufferInfo, { Size = targetSize }):Play()
			end)
		else
			if controller.bufferThread then
				task.cancel(controller.bufferThread)
			end
			local bufferInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(bufferBar, bufferInfo, { Size = targetSize }):Play()
		end

		controller.lastHealth = health
	end

	function controller:Reset()
		if controller.bufferThread then
			task.cancel(controller.bufferThread)
			controller.bufferThread = nil
		end

		controller.lastHealth = nil
		local mainBar = getMainBar()
		local bufferBar = getBufferBar()
		local bgBar = getBgBar()

		if mainBar and bufferBar and bgBar then
			mainBar.Size = getHealthBarSize(bgBar, 1)
			bufferBar.Size = getHealthBarSize(bgBar, 1)
		end
	end

	return controller
end

-- Instance Controller
local playerBarController = createHealthBarController(function()
	return elements and elements.playerMain
end, function()
	return elements and elements.playerBuffer
end, function()
	return elements and elements.playerBG
end)

local houseBarController = createHealthBarController(function()
	return elements and elements.houseMain
end, function()
	return elements and elements.houseBuffer
end, function()
	return elements and elements.houseBG
end)

-- ==========================================
-- SYSTEM PLAYER HEALTH
-- ==========================================
local function setupPlayerHealth(character)
	-- Refresh referensi elemen UI saat respawn
	elements = getGuiElements()

	-- Putuskan koneksi event karakter lama
	if healthChangedConn then
		healthChangedConn:Disconnect()
		healthChangedConn = nil
	end
	if maxHealthChangedConn then
		maxHealthChangedConn:Disconnect()
		maxHealthChangedConn = nil
	end

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end

	playerBarController:Reset()

	local function updatePlayer()
		playerBarController:Update(humanoid.Health, humanoid.MaxHealth)
	end

	healthChangedConn = humanoid.HealthChanged:Connect(updatePlayer)
	maxHealthChangedConn = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updatePlayer)

	updatePlayer()
end

player.CharacterAdded:Connect(setupPlayerHealth)
if player.Character then
	setupPlayerHealth(player.Character)
end

-- ==========================================
-- SYSTEM HOUSE HEALTH (HouseCore -> HouseHumanoid)
-- ==========================================
local function setupHouseHealth()
	local houseCore = Workspace:WaitForChild("HouseCore", 15)
	if not houseCore then
		warn("[ERROR] HouseCore tidak ditemukan di Workspace!")
		return
	end

	local houseHumanoid = houseCore:WaitForChild("Humanoid", 10)
	if not houseHumanoid then
		warn("[ERROR REM BAR] HouseHumanoid tidak ditemukan di dalam HouseCore!")
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
