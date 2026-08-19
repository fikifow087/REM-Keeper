local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ==========================================
-- CONFIGURATION
-- ==========================================
local MAX_SLOTS = 4 -- Mengatur batas maksimal slot hotbar (misal: 4)

-- 1. PAKSA MATIKAN HOTBAR DEFAULT
task.spawn(function()
	local success = false
	repeat
		success = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		task.wait(0.2)
	until success
end)

-- 2. AKSI MENGAMBIL UI DARI PLAYERGUI (Sesuai struktur Explorer)
local playerGui = player:WaitForChild("PlayerGui")
local backpackGui = playerGui:WaitForChild("FIKIFOW_Backpack_GUI", 10)

if not backpackGui then
	warn(" [ERROR] FIKIFOW_Backpack_GUI tidak ditemukan di PlayerGui!")
	return
end

local hotbarFrame = backpackGui:WaitForChild("HotbarFrame", 10)

if not hotbarFrame then
	warn(" [ERROR] HotbarFrame tidak ditemukan di dalam FIKIFOW_Backpack_GUI!")
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

local orderedTools = {}

local function getAllTools()
	local currentTools = {}
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character

	local function registerTools(container)
		if not container then
			return
		end

		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool") then
				currentTools[item] = true

				if not table.find(orderedTools, item) then
					table.insert(orderedTools, item)
				end
			end
		end
	end

	registerTools(backpack)
	registerTools(character)

	for index = #orderedTools, 1, -1 do
		if not currentTools[orderedTools[index]] then
			table.remove(orderedTools, index)
		end
	end

	return orderedTools
end

local function updateHotbarUI()
	-- Hapus slot UI lama
	for _, child in ipairs(hotbarFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local tools = getAllTools()
	local character = player.Character
	local equippedTool = character and character:FindFirstChildOfClass("Tool")

	-- Render UI Slot sesuai batas MAX_SLOTS
	for i = 1, MAX_SLOTS do
		local tool = tools[i]

		-- Slot Tombol
		local slotButton = Instance.new("TextButton")
		slotButton.Name = "Slot_" .. i
		slotButton.Size = UDim2.new(1, 0, 1, 0) -- Ukuran slot vertikal
		slotButton.AutoButtonColor = true
		slotButton.Text = "" -- Teks tombol dikosongkan agar diisi label/ikon
		slotButton.Parent = hotbarFrame

		-- Text Label Nomor Slot [1], [2], dst.
		local numLabel = Instance.new("TextLabel")
		numLabel.Name = "NumLabel"
		numLabel.Size = UDim2.new(0, 20, 0, 20)
		numLabel.Position = UDim2.new(0, 4, 0, 2)
		numLabel.BackgroundTransparency = 1
		numLabel.Text = "[" .. i .. "]"
		numLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		numLabel.TextSize = 12
		numLabel.Font = Enum.Font.SourceSansBold
		numLabel.ZIndex = 3
		numLabel.Parent = slotButton

		if tool then
			-- Style Slot Terisi
			if tool == equippedTool then
				slotButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255) -- Warna Aktif
				slotButton.BorderSizePixel = 2
				slotButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
			else
				slotButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				slotButton.BorderSizePixel = 1
				slotButton.BorderColor3 = Color3.fromRGB(100, 100, 100)
			end

			-- CEK IKON ITEM (Tool.TextureId)
			if tool.TextureId and tool.TextureId ~= "" then
				local iconImage = Instance.new("ImageLabel")
				iconImage.Name = "Icon"
				iconImage.Size = UDim2.new(0, 40, 0, 40)
				iconImage.Position = UDim2.new(0.5, -20, 0.5, -20)
				iconImage.BackgroundTransparency = 1
				iconImage.Image = tool.TextureId
				iconImage.ZIndex = 2
				iconImage.Parent = slotButton
			else
				-- Jika tidak ada gambar TextureId, tampilkan Nama Item
				local nameLabel = Instance.new("TextLabel")
				nameLabel.Name = "ItemName"
				nameLabel.Size = UDim2.new(1, -8, 1, -8)
				nameLabel.Position = UDim2.new(0, 4, 0, 4)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Text = tool.Name
				nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				nameLabel.TextSize = 12
				nameLabel.TextWrapped = true
				nameLabel.ZIndex = 2
				nameLabel.Parent = slotButton
			end

			slotButton.MouseButton1Click:Connect(function()
				equipSlot(i)
			end)
		else
			-- Style Slot Kosong
			slotButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			slotButton.BackgroundTransparency = 0.6
			slotButton.BorderSizePixel = 1
			slotButton.BorderColor3 = Color3.fromRGB(60, 60, 60)
		end
	end
end

equipSlot = function(slotIndex)
	-- Hanya jalankan jika slot yang ditekan <= MAX_SLOTS
	if slotIndex > MAX_SLOTS then
		return
	end

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

-- 3. DETEKSI SHORTCUT KEYBOARD (Dibatasi MAX_SLOTS)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local slotIndex = KEY_MAP[input.KeyCode]
	if slotIndex and slotIndex <= MAX_SLOTS then
		equipSlot(slotIndex)
	end
end)

-- 4. LISTENER INVENTORY
local function bindCharacterListeners(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			updateHotbarUI()
		end
	end)
	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			updateHotbarUI()
		end
	end)
	updateHotbarUI()
end

local function setupInventoryListeners()
	local backpack = player:WaitForChild("Backpack", 10)
	if backpack then
		backpack.ChildAdded:Connect(updateHotbarUI)
		backpack.ChildRemoved:Connect(updateHotbarUI)
	end

	player.CharacterAdded:Connect(bindCharacterListeners)
	if player.Character then
		bindCharacterListeners(player.Character)
	end

	updateHotbarUI()
end

setupInventoryListeners()
