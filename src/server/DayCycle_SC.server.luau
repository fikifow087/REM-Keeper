local lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Membuat nilai Hari global di ReplicatedStorage agar bisa dibaca skrip Spawner
local CurrentDay = ReplicatedStorage:FindFirstChild("CurrentDay")
if not CurrentDay then
	CurrentDay = Instance.new("IntValue")
	CurrentDay.Name = "CurrentDay"
	CurrentDay.Value = 1 -- Mulai dari Hari 1
	CurrentDay.Parent = ReplicatedStorage
end

local fullCycleLength = 500
local updateInterval = 0.1
local minutesPerDay = 24 * 60
local debugStartHour = 12
local cycleStartedAt = os.clock() - (debugStartHour / 24) * fullCycleLength

-- Variabel bantuan untuk mendeteksi kapan waktu melewati tengah malam
local lastMinutes = (os.clock() - cycleStartedAt) % fullCycleLength / fullCycleLength * minutesPerDay

while true do
	local elapsed = (os.clock() - cycleStartedAt) % fullCycleLength
	local minutesAfterMidnight = elapsed / fullCycleLength * minutesPerDay

	lighting.ClockTime = minutesAfterMidnight / 60

	-- LOGIKA PENDETEKSI HARI BARU:
	-- Jika menit saat ini lebih kecil dari menit sebelumnya, artinya waktu baru saja reset melewati jam 00:00 (Tengah Malam)
	if minutesAfterMidnight < lastMinutes then
		CurrentDay.Value = CurrentDay.Value + 1
		print("--- HARI BARU TERAH DIMULAI: HARI " .. CurrentDay.Value .. " ---")
	end

	lastMinutes = minutesAfterMidnight
	task.wait(updateInterval)
end
