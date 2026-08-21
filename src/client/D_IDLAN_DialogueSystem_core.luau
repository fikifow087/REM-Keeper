local UserInputService = game:GetService("UserInputService")
local CursorLocking = require(script.Parent:WaitForChild("FIKIFOW_CursorLocking"))

local DialogueCore = {}
DialogueCore.__index = DialogueCore

local instances = {}

function DialogueCore.WaitForGui(playerGui, guiName, timeout)
	local deadline = os.clock() + (timeout or 10)
	local dialogueGui = playerGui:FindFirstChild(guiName, true)
	while not dialogueGui and os.clock() < deadline do
		task.wait(0.1)
		dialogueGui = playerGui:FindFirstChild(guiName, true)
	end

	if not dialogueGui then
		local starterGui = game:GetService("StarterGui")
		local starterDialogueGui = starterGui:FindFirstChild(guiName, true)
		if starterDialogueGui and starterDialogueGui:IsA("ScreenGui") then
			dialogueGui = starterDialogueGui:Clone()
			dialogueGui.Parent = playerGui
		end
	end

	if not dialogueGui then
		warn("Dialogue GUI '" .. guiName .. "' tidak ditemukan di StarterGui atau PlayerGui")
	end
	return dialogueGui
end

local function sortButtons(left, right)
	if left.LayoutOrder == right.LayoutOrder then
		return left.Name < right.Name
	end
	return left.LayoutOrder < right.LayoutOrder
end

function DialogueCore.new(dialogueGui)
	local self = setmetatable({}, DialogueCore)
	self.Gui = dialogueGui
	self.TextLabel = dialogueGui:WaitForChild("InsertTXThere"):WaitForChild("D_DIALOGUE_InsertTXThere")
	self.SpeakerLabel = dialogueGui:WaitForChild("thisObjectName_FRAME"):WaitForChild("D_DIALOGUE_thisObjectName")
	self.OptionsFrame = dialogueGui:WaitForChild("Choosing_DIALOGUE_Options_FRAME")
	self.Sound = dialogueGui:WaitForChild("DialogBlips_CHAR1")
	self.Typing = false
	self.Advance = false
	self.Choice = nil
	self.GeneratedButtons = {}
	self.ButtonConnections = {}
	self.PreviousCursorState = nil

	local layout = self.OptionsFrame:FindFirstChildOfClass("UIListLayout")
	if not layout then
		layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = self.OptionsFrame
	end
	self.OptionsLayout = layout

	dialogueGui.Enabled = false
	self.TextLabel.Visible = false
	self.SpeakerLabel.Visible = false
	self.OptionsFrame.Visible = false

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not self.Typing then
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if self.OptionsFrame.Visible then
				return
			end

			if not self.Advance then
				self.SkipRequested = true
			else
				self.Advance = false
			end
		end
	end)

	return self
end

function DialogueCore.Get(dialogueGui)
	if not instances[dialogueGui] then
		instances[dialogueGui] = DialogueCore.new(dialogueGui)
	end
	return instances[dialogueGui]
end

function DialogueCore:IsPlaying()
	return self.Typing
end

function DialogueCore:_clearButtons()
	for _, connection in ipairs(self.ButtonConnections) do
		connection:Disconnect()
	end
	table.clear(self.ButtonConnections)

	for _, button in ipairs(self.GeneratedButtons) do
		button:Destroy()
	end
	table.clear(self.GeneratedButtons)
end

function DialogueCore:_getButtons(requiredCount)
	local buttons = {}
	for _, child in ipairs(self.OptionsFrame:GetChildren()) do
		if child:IsA("TextButton") then
			table.insert(buttons, child)
		end
	end
	table.sort(buttons, sortButtons)

	local template = buttons[1]
	if not template then
		template = Instance.new("TextButton")
		template.Name = "Seamless_Option_Button"
		template.Size = UDim2.new(1, 0, 0, 40)
		template.TextScaled = true
		template.Parent = self.OptionsFrame
		table.insert(buttons, template)
	end

	while #buttons < requiredCount do
		local button = template:Clone()
		button.Name = "Seamless_Option_Button"
		button.Parent = self.OptionsFrame
		table.insert(buttons, button)
		table.insert(self.GeneratedButtons, button)
	end

	for index, button in ipairs(buttons) do
		button.LayoutOrder = index
		button.Visible = index <= requiredCount
	end

	return buttons
end

function DialogueCore:_showOptions(options)
	self:_clearButtons()
	local buttons = self:_getButtons(#options)
	self.Choice = nil

	for index, option in ipairs(options) do
		local button = buttons[index]
		button.Text = option.text or option.Text or "Option " .. index
		button.Visible = true
		table.insert(
			self.ButtonConnections,
			button.Activated:Connect(function()
				self.Choice = option
			end)
		)
	end

	self.OptionsFrame.AutomaticSize = Enum.AutomaticSize.Y
	self.OptionsFrame.Visible = true
	self.Advance = false
	while not self.Choice and self.Typing do
		task.wait()
	end
	self.OptionsFrame.Visible = false
	self:_clearButtons()
	return self.Choice
end

function DialogueCore:_write(text)
	self.TextLabel.Text = ""
	self.SkipRequested = false
	self.Advance = false

	for index = 1, #text do
		if self.SkipRequested then
			self.TextLabel.Text = text
			break
		end
		self.TextLabel.Text = string.sub(text, 1, index)
		if index % 2 == 0 then
			self.Sound.TimePosition = 0
			self.Sound:Play()
		end
		task.wait(0.03)
	end

	self.Advance = true
	while self.Advance and self.Typing do
		task.wait(0.1)
	end
end

function DialogueCore:_finish(humanoid)
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
	end
	self.Gui.Enabled = false
	self.TextLabel.Visible = false
	self.SpeakerLabel.Visible = false
	self.OptionsFrame.Visible = false
	self.TextLabel.Text = ""
	self:_clearButtons()
	CursorLocking.Restore(self.PreviousCursorState)
	self.PreviousCursorState = nil
end

function DialogueCore:Play(conversation, humanoid)
	if self.Typing then
		return false
	end

	self.Typing = true
	self.PreviousCursorState = CursorLocking.DisableAndRemember()
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end
	self.Gui.Enabled = true
	self.TextLabel.Visible = true
	self.SpeakerLabel.Visible = true

	local currentId = conversation.Start
	while currentId and self.Typing do
		local node = conversation.Nodes[currentId]
		if not node then
			warn("Dialogue node not found: " .. tostring(currentId))
			break
		end

		self.SpeakerLabel.Text = node.speaker or conversation.Speaker or ""
		if node.onEnter then
			node.onEnter(self)
		end
		self:_write(node.text or "")

		if node.options then
			local selected = self:_showOptions(node.options)
			currentId = selected and (selected.next or selected.target)
		else
			currentId = node.next
		end
	end

	self.Typing = false
	self:_finish(humanoid)
	return true
end

return DialogueCore
