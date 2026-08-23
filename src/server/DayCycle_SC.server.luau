local lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Mengambil folder ZombiesAlive dari Workspace
local EnemyFolder = game.Workspace:WaitForChild("ZombiesAlive")
local CurrentDay = ReplicatedStorage:WaitForChild("CurrentDay")

local fullCycleLength = 480 -- Ubah kembali ke waktu normal game kamu (misal 480)
local updateInterval = 0.1
local minutesPerDay = 24 * 60

local currentHour = 6
local minutesAfterMidnight = currentHour * 60

local isTimeFrozen = false

-- Mengambil nilai pembeku global agar bisa dibaca oleh skrip Event kasur
local TimeFrozenValue = ReplicatedStorage:FindFirstChild("IsTimeFrozen")
if not TimeFrozenValue then
	TimeFrozenValue = Instance.new("BoolValue", ReplicatedStorage)
	TimeFrozenValue.Name = "IsTimeFrozen"
end
TimeFrozenValue.Value = false

while true do
	-- Membaca status pembeku dari ReplicatedStorage secara real-time
	isTimeFrozen = TimeFrozenValue.Value

	if not isTimeFrozen then
		local minutesPerUpdate = (updateInterval / fullCycleLength) * minutesPerDay
		minutesAfterMidnight = (minutesAfterMidnight + minutesPerUpdate) % minutesPerDay

		lighting.ClockTime = minutesAfterMidnight / 60

		-- DETEKSI JAM 22.00 MALAM
		if minutesAfterMidnight >= (22 * 60) and minutesAfterMidnight < (23 * 60) then
			TimeFrozenValue.Value = true -- Bekukan waktu global
			lighting.ClockTime = 22
			print("[SISTEM] Jam 22.00! Silakan tidur untuk mengacak event esok hari.")
		end
	end

	task.wait(updateInterval)
end
