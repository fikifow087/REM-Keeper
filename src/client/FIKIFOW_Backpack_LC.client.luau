local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local CursorLocking = require(script.Parent:WaitForChild("FIKIFOW_CursorLocking"))

local player = Players.LocalPlayer

-- ==========================================
-- CONFIGURATION
-- ==========================================
local MAX_SLOTS = 3 -- Jumlah slot hotbar (1-3)

-- "Backpack" = Mode Produksi (Membaca isi tas bawaan player)
-- "StarterPack" = Mode Testing (Membaca dari folder StarterPack & Auto-Clone saat di-equip)
local ITEM_LOCATION_MODE = "StarterPack"

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

-- 2. AMBIL UI DARI PLAYERGUI
local playerGui = player:WaitForChild("PlayerGui")
local backpackGui = playerGui:WaitForChild("FIKIFOW_Backpack_GUI", 10)
local inventoryGui = playerGui:WaitForChild("FIKIFOW_Inventory_GUI", 10)

if not backpackGui or not inventoryGui then
	warn(" [ERROR] ScreenGui Backpack atau Inventory tidak ditemukan!")
	return
end

inventoryGui.Enabled = false

local hotbarFrame = backpackGui:WaitForChild("HotbarFrame", 10)
local inventoryFrame = inventoryGui:WaitForChild("InventoryFrame", 10)

local searchBar = inventoryFrame:WaitForChild("SearchBar_TXTbox", 5) or inventoryFrame:FindFirstChild("SearchBar", true)
local itemContainer = inventoryFrame:WaitForChild("Container", 5)

-- Setup Infinite Scrolling secara dinamis
if itemContainer then
	itemContainer.ClipsDescendants = true
	if itemContainer:IsA("ScrollingFrame") then
		itemContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
		itemContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
		itemContainer.ScrollBarThickness = 6
	end
end

local equipSlot
local updateAllUI
local orderedTools = {}
local savedCursorState = nil

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
	local currentTools = {}

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

	-- Logika Switch Mode Folder
	if ITEM_LOCATION_MODE == "StarterPack" then
		registerTools(game:GetService("StarterPack"))
	else
		registerTools(player:FindFirstChild("Backpack"))
		registerTools(player.Character)
	end

	for index = #orderedTools, 1, -1 do
		if not currentTools[orderedTools[index]] then
			table.remove(orderedTools, index)
		end
	end

	return orderedTools
end

-- RENDER HOTBAR SLOT (1 - 3)
local function updateHotbarUI(tools, equippedTool)
	for _, child in ipairs(hotbarFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for i = 1, MAX_SLOTS do
		local tool = tools[i]

		local slotButton = Instance.new("TextButton")
		slotButton.Name = "Slot_" .. i
		slotButton.Size = UDim2.fromScale(1, 1)
		slotButton.AutoButtonColor = true
		slotButton.Text = ""
		slotButton.Parent = hotbarFrame

		local numLabel = Instance.new("TextLabel")
		numLabel.Name = "NumLabel"
		numLabel.Size = UDim2.fromOffset(20, 20)
		numLabel.Position = UDim2.fromOffset(4, 2)
		numLabel.BackgroundTransparency = 1
		numLabel.Text = "[" .. i .. "]"
		numLabel.TextColor3 = Color3.fromRGB(55, 65, 81)
		numLabel.TextSize = 12
		numLabel.Font = Enum.Font.SourceSansBold
		numLabel.ZIndex = 3
		numLabel.Parent = slotButton

		if tool then
			if tool == equippedTool then
				slotButton.BackgroundColor3 = Color3.fromRGB(219, 234, 254)
				slotButton.BorderSizePixel = 2
				slotButton.BorderColor3 = Color3.fromRGB(37, 99, 235)
			else
				slotButton.BackgroundColor3 = Color3.fromRGB(248, 250, 252)
				slotButton.BorderSizePixel = 1
				slotButton.BorderColor3 = Color3.fromRGB(203, 213, 225)
			end

			if tool.TextureId and tool.TextureId ~= "" then
				local iconImage = Instance.new("ImageLabel")
				iconImage.Name = "Icon"
				iconImage.Size = UDim2.fromOffset(40, 40)
				iconImage.Position = UDim2.new(0.5, -20, 0.5, -20)
				iconImage.BackgroundTransparency = 1
				iconImage.Image = tool.TextureId
				iconImage.ZIndex = 2
				iconImage.Parent = slotButton
			else
				local nameLabel = Instance.new("TextLabel")
				nameLabel.Name = "ItemName"
				nameLabel.Size = UDim2.new(1, -8, 1, -8)
				nameLabel.Position = UDim2.fromOffset(4, 4)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Text = tool.Name
				nameLabel.TextColor3 = Color3.fromRGB(31, 41, 55)
				nameLabel.TextSize = 12
				nameLabel.TextWrapped = true
				nameLabel.ZIndex = 2
				nameLabel.Parent = slotButton
			end

			slotButton.MouseButton1Click:Connect(function()
				equipSlot(i)
			end)
		else
			slotButton.BackgroundColor3 = Color3.fromRGB(226, 232, 240)
			slotButton.BackgroundTransparency = 0.15
			slotButton.BorderSizePixel = 1
			slotButton.BorderColor3 = Color3.fromRGB(203, 213, 225)
		end
	end
end

-- RENDER FULL INVENTORY + SEARCH FILTER
local function updateInventoryUI(tools, equippedTool)
	if not itemContainer then
		return
	end

	-- Garansi keberadaan UIGridLayout agar item tidak menumpuk
	local gridLayout = itemContainer:FindFirstChildOfClass("UIGridLayout")
	if not gridLayout then
		gridLayout = Instance.new("UIGridLayout")
		gridLayout.CellSize = UDim2.new(0, 65, 0, 65)
		gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
		gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
		gridLayout.Parent = itemContainer
	end

	for _, child in ipairs(itemContainer:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	-- Membersihkan spasi berlebih pada kotak pencarian
	local searchText = ""
	if searchBar and searchBar:IsA("TextBox") then
		searchText = searchBar.Text:lower():match("^%s*(.-)%s*$") or ""
	end

	for index, tool in ipairs(tools) do
		if searchText == "" or string.find(tool.Name:lower(), searchText, 1, true) then
			local isHotbar = index <= MAX_SLOTS
			local isEquipped = (tool == equippedTool)

			local itemButton = Instance.new("TextButton")
			itemButton.Name = "Item_" .. tool.Name
			itemButton.LayoutOrder = index
			itemButton.Size = UDim2.fromOffset(65, 65)
			itemButton.AutoButtonColor = true
			itemButton.Text = ""
			itemButton.Parent = itemContainer

			if isEquipped then
				itemButton.BackgroundColor3 = Color3.fromRGB(187, 247, 208)
				itemButton.BorderSizePixel = 2
				itemButton.BorderColor3 = Color3.fromRGB(34, 197, 94)
			elseif isHotbar then
				itemButton.BackgroundColor3 = Color3.fromRGB(219, 234, 254)
				itemButton.BorderSizePixel = 2
				itemButton.BorderColor3 = Color3.fromRGB(37, 99, 235)
			else
				itemButton.BackgroundColor3 = Color3.fromRGB(248, 250, 252)
				itemButton.BorderSizePixel = 1
				itemButton.BorderColor3 = Color3.fromRGB(203, 213, 225)
			end

			local tagLabel = Instance.new("TextLabel")
			tagLabel.Name = "Tag"
			tagLabel.Size = UDim2.new(1, -4, 0, 14)
			tagLabel.Position = UDim2.new(0, 2, 0, 2)
			tagLabel.BackgroundTransparency = 1
			tagLabel.TextSize = 10
			tagLabel.Font = Enum.Font.SourceSansBold
			tagLabel.ZIndex = 3
			tagLabel.Parent = itemButton

			if isHotbar then
				tagLabel.Text = "[" .. index .. "]"
				tagLabel.TextColor3 = Color3.fromRGB(37, 99, 235)
			else
				tagLabel.Text = ""
			end

			if tool.TextureId and tool.TextureId ~= "" then
				local iconImage = Instance.new("ImageLabel")
				iconImage.Name = "Icon"
				iconImage.Size = UDim2.fromOffset(36, 36)
				iconImage.Position = UDim2.new(0.5, -18, 0.5, -14)
				iconImage.BackgroundTransparency = 1
				iconImage.Image = tool.TextureId
				iconImage.ZIndex = 2
				iconImage.Parent = itemButton
			else
				local nameLabel = Instance.new("TextLabel")
				nameLabel.Name = "ItemName"
				nameLabel.Size = UDim2.new(1, -8, 1, -16)
				nameLabel.Position = UDim2.fromOffset(4, 14)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Text = tool.Name
				nameLabel.TextColor3 = Color3.fromRGB(31, 41, 55)
				nameLabel.TextSize = 11
				nameLabel.TextWrapped = true
				nameLabel.ZIndex = 2
				nameLabel.Parent = itemButton
			end

			itemButton.MouseButton1Click:Connect(function()
				equipSlot(index)
			end)
		end
	end
end

updateAllUI = function()
	local tools = getAllTools()
	local character = player.Character
	local equippedTool = character and character:FindFirstChildOfClass("Tool")

	updateHotbarUI(tools, equippedTool)
	updateInventoryUI(tools, equippedTool)
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
		-- Logic khusus agar testing StarterPack bisa di-equip dengan aman
		if ITEM_LOCATION_MODE == "StarterPack" and targetTool.Parent == game:GetService("StarterPack") then
			local newTool = targetTool:Clone()
			newTool.Parent = player:FindFirstChild("Backpack")
			humanoid:EquipTool(newTool)
		elseif targetTool.Parent == character then
			humanoid:UnequipTools()
		else
			humanoid:EquipTool(targetTool)
		end
	end
end

-- LISTENER LIVE SEARCH
if searchBar and searchBar:IsA("TextBox") then
	searchBar:GetPropertyChangedSignal("Text"):Connect(updateAllUI)
end

-- DETEKSI SHORTCUT KEYBOARD
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Backquote then
		if inventoryGui then
			inventoryGui.Enabled = not inventoryGui.Enabled

			if inventoryGui.Enabled then
				savedCursorState = CursorLocking.DisableAndRemember()
			else
				if savedCursorState then
					CursorLocking.Restore(savedCursorState)
					savedCursorState = nil
				else
					CursorLocking.Lock()
				end
			end
		end
		return
	end

	local slotIndex = KEY_MAP[input.KeyCode]
	if slotIndex and slotIndex <= MAX_SLOTS then
		equipSlot(slotIndex)
	end
end)

-- LISTENER INVENTORY
local function bindCharacterListeners(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			updateAllUI()
		end
	end)
	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			updateAllUI()
		end
	end)
	updateAllUI()
end

local function setupInventoryListeners()
	local backpack = player:WaitForChild("Backpack", 10)
	if backpack then
		backpack.ChildAdded:Connect(updateAllUI)
		backpack.ChildRemoved:Connect(updateAllUI)
	end

	player.CharacterAdded:Connect(bindCharacterListeners)
	if player.Character then
		bindCharacterListeners(player.Character)
	end

	-- Listener tambahan untuk StarterPack Mode
	if ITEM_LOCATION_MODE == "StarterPack" then
		game:GetService("StarterPack").ChildAdded:Connect(updateAllUI)
		game:GetService("StarterPack").ChildRemoved:Connect(updateAllUI)
	end

	updateAllUI()
end

setupInventoryListeners()
