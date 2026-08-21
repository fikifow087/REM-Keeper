local lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ambil ProximityPrompt dari kasur Anda
local bed = game.Workspace:WaitForChild("bed")
local bedproxyprompt = bed:WaitForChild("ProximityPrompt")

-- Matikan prompt kasur di awal permainan (baru aktif saat malam tiba)
bedproxyprompt.Enabled = false

-- Mengambil folder ZombiesAlive yang sudah Anda buat secara manual di Explorer
local EnemyFolder = game.Workspace:WaitForChild("ZombiesAlive")

local CurrentDay = ReplicatedStorage:WaitForChild("CurrentDay")

local fullCycleLength = 500
local updateInterval = 0.1
local minutesPerDay = 24 * 60

-- WAKTU BERHENTI (Jam 22.00 malam)
local TIME_TO_FREEZE = 22 * 60

local currentHour = 6
local minutesAfterMidnight = currentHour * 60

local isTimeFrozen = false

-- =======================================================================
-- 🛏️ EVENT INTERAKSI KASUR (TIDUR BERGANTI HARI)
-- =======================================================================
bedproxyprompt.Triggered:Connect(function(player)
	if isTimeFrozen then
		-- HITUNG SISA ZOMBIE YANG MASIH HIDUP DI FOLDER MANUAL
		local sisaZombie = #EnemyFolder:GetChildren()

		if sisaZombie > 0 then
			-- JIKA MASIH ADA ZOMBIE: Tolak perintah tidur
			print("[SISTEM] Kamu tidak bisa tidur! Masih ada " .. sisaZombie .. " zombie di sekitar rumah!")

			local teksAsli = bedproxyprompt.ObjectText
			bedproxyprompt.ObjectText = "Kalahkan semua zombie dulu! (" .. sisaZombie .. " tersisa)"
			task.delay(3, function()
				bedproxyprompt.ObjectText = teksAsli
			end)

			return -- Batalkan proses ganti hari
		end

		-- JIKA ZOMBIE SUDAH 0: Berhasil Tidur
		bedproxyprompt.Enabled = false
		CurrentDay.Value = CurrentDay.Value + 1
		print("--- HARI BARU TELAH DIMULAI: HARI " .. CurrentDay.Value .. " ---")

		minutesAfterMidnight = 6 * 60
		lighting.ClockTime = 6
		isTimeFrozen = false
	end
end)
-- =======================================================================

while true do
	if not isTimeFrozen then
		local minutesPerUpdate = (updateInterval / fullCycleLength) * minutesPerDay
		minutesAfterMidnight = (minutesAfterMidnight + minutesPerUpdate) % minutesPerDay

		lighting.ClockTime = minutesAfterMidnight / 60

		-- DETEKSI JAM 22.00 MALAM
		if minutesAfterMidnight >= TIME_TO_FREEZE and minutesAfterMidnight < (23 * 60) then
			isTimeFrozen = true
			lighting.ClockTime = 22

			bedproxyprompt.Enabled = true
			print("[SISTEM] Jam 22.00! Amankan rumah dari sisa zombie untuk bisa tidur!")
		end
	end

	task.wait(updateInterval)
end
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
