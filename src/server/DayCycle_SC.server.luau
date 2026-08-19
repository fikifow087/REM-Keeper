local lighting = game:GetService("Lighting")

local fullCycleLength = 480
local updateInterval = 0.1
local minutesPerDay = 24 * 60
local debugStartHour = 12
-- local debugStartHour = 23.5
local cycleStartedAt = os.clock() - (debugStartHour / 24) * fullCycleLength

while true do
	local elapsed = (os.clock() - cycleStartedAt) % fullCycleLength
	local minutesAfterMidnight = elapsed / fullCycleLength * minutesPerDay

	lighting.ClockTime = minutesAfterMidnight / 60
	task.wait(updateInterval)
end
