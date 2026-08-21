local Players = game:GetService("Players")
local DialogueCore = require(script.Parent:WaitForChild("D_IDLAN_DialogueSystem_core"))

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local dialogueGui = playerGui:WaitForChild("Dgui")

DialogueCore.Get(dialogueGui)
