local lighting = game:GetService("Lighting")
local players = game:GetService("Players")

local player = players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = playerGui:WaitForChild("DayCycle_GUI")
local clockLabel = screenGui:WaitForChild("AM_PM_Clock")

local function updateClockText()
	local totalMinutes = math.floor(lighting.ClockTime * 60 + 0.5) % (24 * 60)
	local hour24 = math.floor(totalMinutes / 60)
	local minute = totalMinutes % 60
	local period = if hour24 < 12 then "AM" else "PM"
	local hour12 = hour24 % 12

	if hour12 == 0 then
		hour12 = 12
	end

	clockLabel.Text = string.format("%d:%02d %s", hour12, minute, period)
end

lighting:GetPropertyChangedSignal("ClockTime"):Connect(updateClockText)
updateClockText()
