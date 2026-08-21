local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local CursorLocking = {}

local enforcedState = nil
local enforceConnection = nil

function CursorLocking.Set(locked)
	enforcedState = nil
	if enforceConnection then
		enforceConnection:Disconnect()
		enforceConnection = nil
	end

	if locked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end

function CursorLocking.Lock()
	CursorLocking.Set(true)
end

function CursorLocking.Unlock()
	CursorLocking.Set(false)
end

function CursorLocking.DisableAndRemember()
	local previousState = {
		MouseBehavior = UserInputService.MouseBehavior,
		MouseIconEnabled = UserInputService.MouseIconEnabled,
		CameraMode = game.Players.LocalPlayer.CameraMode,
	}

	local player = game.Players.LocalPlayer
	if player.CameraMode == Enum.CameraMode.LockFirstPerson then
		player.CameraMode = Enum.CameraMode.Classic
	end

	enforcedState = {
		MouseBehavior = Enum.MouseBehavior.Default,
		MouseIconEnabled = true,
	}
	UserInputService.MouseBehavior = enforcedState.MouseBehavior
	UserInputService.MouseIconEnabled = enforcedState.MouseIconEnabled
	enforceConnection = RunService.RenderStepped:Connect(function()
		if enforcedState then
			UserInputService.MouseBehavior = enforcedState.MouseBehavior
			UserInputService.MouseIconEnabled = enforcedState.MouseIconEnabled
		end
	end)
	return previousState
end

function CursorLocking.Restore(previousState)
	enforcedState = nil
	if enforceConnection then
		enforceConnection:Disconnect()
		enforceConnection = nil
	end

	if not previousState then
		return
	end

	game.Players.LocalPlayer.CameraMode = previousState.CameraMode
	UserInputService.MouseBehavior = previousState.MouseBehavior
	UserInputService.MouseIconEnabled = previousState.MouseIconEnabled
end

return CursorLocking
