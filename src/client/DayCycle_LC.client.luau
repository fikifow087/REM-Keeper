local lighting = game:GetService("Lighting")
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local player = players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = playerGui:WaitForChild("DayCycle_GUI", 10)

if not screenGui then
	warn("[DayCycle] DayCycle_GUI tidak ditemukan di PlayerGui")
	return
end

local clockLabel = screenGui:FindFirstChild("AM_PM_Clock", true)
local dayLabel = screenGui:FindFirstChild("Day_Clock", true)

if not clockLabel or not clockLabel:IsA("TextLabel") then
	warn("[DayCycle] TextLabel AM_PM_Clock tidak ditemukan di dalam DayCycle_GUI")
	return
end

if not dayLabel or not dayLabel:IsA("TextLabel") then
	warn("[DayCycle] TextLabel Day_Clock tidak ditemukan di dalam DayCycle_GUI")
	return
end

local currentDay = replicatedStorage:WaitForChild("CurrentDay")

clockLabel.AutomaticSize = Enum.AutomaticSize.None
clockLabel.TextScaled = false
clockLabel.TextWrapped = false
-- clockLabel.Size = UDim2.fromOffset(220, 60)
clockLabel.TextSize = 93
-- clockLabel.TextXAlignment = Enum.TextXAlignment.Center

local function updateClockText()
	local totalMinutes = math.floor(lighting.ClockTime * 60 + 0.5) % (24 * 60)
	local hour24 = math.floor(totalMinutes / 60)
	local minute = totalMinutes % 60
	local period = if hour24 < 12 then "AM" else "PM"
	local hour12 = hour24 % 12

	if hour12 == 0 then
		hour12 = 12
	end

	clockLabel.Text = string.format("%02d:%02d %s", hour12, minute, period)
end

local function updateDayText()
	dayLabel.Text = "DAY " .. tostring(currentDay.Value)
end

lighting:GetPropertyChangedSignal("ClockTime"):Connect(updateClockText)
currentDay:GetPropertyChangedSignal("Value"):Connect(updateDayText)
updateClockText()
updateDayText()
