local Players = game:GetService("Players")
local DialogueCore = require(script.Parent:WaitForChild("D_IDLAN_DialogueSystem_core"))

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local dialogueGui = DialogueCore.WaitForGui(playerGui, "Dgui")
if not dialogueGui then
	return
end

DialogueCore.Get(dialogueGui)
