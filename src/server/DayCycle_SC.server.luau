local lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyFolder = game.Workspace:WaitForChild("ZombiesAlive")
local CurrentDay = ReplicatedStorage:WaitForChild("CurrentDay")

local fullCycleLength = 100 -- Atur durasi 1 hari sesuka Anda (misal 480 detik)
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

-- SISTEM SINKRONISASI AKTIF: Begitu dicairkan dari kasur, reset memori menit ke Jam 6 Pagi
TimeFrozenValue.Changed:Connect(function(isFrozen)
	if not isFrozen then
		minutesAfterMidnight = 6 * 60 -- Sinkronisasikan memori menit internal ke Jam 06.00 Pagi
		lighting.ClockTime = 6
		print("[SISTEM] Waktu dicairkan! Jam internal di-reset ke Pagi Hari.")
	end
end)

while true do
	if not TimeFrozenValue.Value then
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
