local lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyFolder = game.Workspace:WaitForChild("ZombiesAlive")
local CurrentDay = ReplicatedStorage:WaitForChild("CurrentDay")

local fullCycleLength = 10 -- Atur durasi testing atau normal game kamu
local updateInterval = 0.1
local minutesPerDay = 24 * 60

local currentHour = 6
local minutesAfterMidnight = currentHour * 60

local TimeFrozenValue = ReplicatedStorage:FindFirstChild("IsTimeFrozen")
if not TimeFrozenValue then
	TimeFrozenValue = Instance.new("BoolValue", ReplicatedStorage)
	TimeFrozenValue.Name = "IsTimeFrozen"
end
TimeFrozenValue.Value = false

-- SISTEM SINKRONISASI: Reset memori menit internal ke Jam 6 Pagi saat kasur dicairkan
TimeFrozenValue.Changed:Connect(function(isFrozen)
	if not isFrozen then
		minutesAfterMidnight = 6 * 60
		lighting.ClockTime = 6
		print("[SISTEM] Waktu dicairkan! Jam internal di-reset ke Pagi Hari.")
	end
end)

while true do
	if not TimeFrozenValue.Value then
		local minutesPerUpdate = (updateInterval / fullCycleLength) * minutesPerDay
		minutesAfterMidnight = (minutesAfterMidnight + minutesPerUpdate) % minutesPerDay

		lighting.ClockTime = minutesAfterMidnight / 60

		-- DETEKSI JAM 22.00 MALAM (WAKTU MEMBEKU)
		if minutesAfterMidnight >= (22 * 60) and minutesAfterMidnight < (23 * 60) then
			-- Cukup ubah nilai BoolValue ini menjadi true.
			-- Perubahan ini akan otomatis memicu skrip kasur untuk memulai countdown!
			TimeFrozenValue.Value = true
			lighting.ClockTime = 22
			print("[SISTEM] Jam 22.00! Waktu membeku.")
		end
	end

	task.wait(updateInterval)
end
