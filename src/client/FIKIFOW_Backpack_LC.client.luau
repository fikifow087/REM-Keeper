local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- 1. PAKSA MATIKAN HOTBAR DEFAULT (Retry dengan loop pcall agar tidak terabaikan saat game loading)
task.spawn(function()
	local success = false
	repeat
		success = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		task.wait(0.2)
	until success
end)

local gui = script.Parent
-- Menggunakan timeout 5 detik agar script tidak tersangkut diam selamanya jika nama Frame salah
local hotbarFrame = gui:WaitForChild("HotbarFrame", 5)

if not hotbarFrame then
	warn(" [ERROR] HotbarFrame tidak ditemukan! Pastikan nama Frame di Explorer persis 'HotbarFrame'")
	return
end

local equipSlot -- Forward declaration

local KEY_MAP = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9,
}

local function getAllTools()
	local tools = {}
	local character = player.Character
	local backpack = player:FindFirstChild("Backpack")

	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(tools, item)
			end
		end
	end

	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(tools, item)
			end
		end
	end

	return tools
end

local function updateHotbarUI()
	for _, child in ipairs(hotbarFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local tools = getAllTools()
	local character = player.Character
	local equippedTool = character and character:FindFirstChildOfClass("Tool")

	for i = 1, math.min(#tools, 9) do
		local tool = tools[i]

		local slotButton = Instance.new("TextButton")
		slotButton.Name = "Slot_" .. i
		slotButton.Size = UDim2.new(1, 0, 0, 50) -- Menyesuaikan lebar frame vertikal
		slotButton.Text = "[" .. i .. "] " .. tool.Name
		slotButton.TextSize = 14
		slotButton.Parent = hotbarFrame

		if tool == equippedTool then
			slotButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		else
			slotButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		end

		slotButton.MouseButton1Click:Connect(function()
			equipSlot(i)
		end)
	end
end

equipSlot = function(slotIndex)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local tools = getAllTools()
	local targetTool = tools[slotIndex]

	if targetTool then
		if targetTool.Parent == character then
			humanoid:UnequipTools()
		else
			humanoid:EquipTool(targetTool)
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local slotIndex = KEY_MAP[input.KeyCode]
	if slotIndex then
		equipSlot(slotIndex)
	end
end)

local function setupInventoryListeners()
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then
		return
	end

	backpack.ChildAdded:Connect(updateHotbarUI)
	backpack.ChildRemoved:Connect(updateHotbarUI)

	player.CharacterAdded:Connect(function(char)
		char.ChildAdded:Connect(updateHotbarUI)
		char.ChildRemoved:Connect(updateHotbarUI)
		updateHotbarUI()
	end)

	if player.Character then
		player.Character.ChildAdded:Connect(updateHotbarUI)
		player.Character.ChildRemoved:Connect(updateHotbarUI)
	end

	updateHotbarUI()
end

setupInventoryListeners()
