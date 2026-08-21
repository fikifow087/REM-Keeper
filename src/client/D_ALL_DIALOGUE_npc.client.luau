local Players = game:GetService("Players")
local DialogueCore = require(script.Parent:WaitForChild("D_IDLAN_DialogueSystem_core"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local dialogueGui = playerGui:WaitForChild("Dgui")
local dialogue = DialogueCore.Get(dialogueGui)

local function getHumanoid()
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("Humanoid")
end

local function openShop()
	local shopGui = playerGui:FindFirstChild("ShopGui")
	if shopGui then
		shopGui.Enabled = true
		return
	end

	local shop = playerGui:FindFirstChild("shop")
	if shop then
		shop.Enabled = true
		local frame = shop:FindFirstChild("Frame")
		if frame then
			frame.Visible = true
		end
	end
end

local jesterConversation = {
	Start = "greeting",
	Nodes = {
		greeting = {
			speaker = "Jester",
			text = "Hello, welcome to my test zone!",
			next = "question",
		},
		question = {
			speaker = "Jester",
			text = "Apakah kamu menyukai game buatan ku ini?",
			options = {
				{ text = "Ya, Bagus!", next = "yes" },
				{ text = "Gak, Jelek.", next = "no" },
			},
		},
		yes = {
			speaker = "Jester",
			text = "Wah, terima kasih banyak! Dukunganmu sangat berarti.",
			next = "learn",
		},
		learn = {
			speaker = "Jester",
			text = "Aku akan terus belajar membuat game ini lebih seru.",
		},
		no = {
			speaker = "Jester",
			text = "Oh... maaf ya jika masih banyak kekurangan.",
			next = "improve",
		},
		improve = {
			speaker = "Jester",
			text = "Aku akan berusaha memperbaikinya lagi nanti.",
		},
	},
}

local angelConversation = {
	Start = "greeting",
	Nodes = {
		greeting = {
			speaker = "Angel",
			text = "Halo anak muda, ada yang bisa kubantu?",
			next = "question",
		},
		question = {
			speaker = "Angel",
			text = "Apakah kamu ingin melihat barang daganganku?",
			options = {
				{ text = "Buka Toko", next = "shop" },
				{ text = "Tidak, Terima Kasih", next = "decline" },
			},
		},
		shop = {
			speaker = "Angel",
			text = "Silakan pilih barang yang kamu butuhkan.",
			onEnter = openShop,
		},
		decline = {
			speaker = "Angel",
			text = "Baiklah, beritahu aku jika kamu berubah pikiran.",
		},
	},
}

local function bindPrompt(npcName, conversation)
	local prompt = workspace:WaitForChild(npcName):WaitForChild("HumanoidRootPart"):WaitForChild("ProximityPrompt")
	prompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer ~= player or dialogue:IsPlaying() then
			return
		end
		prompt.Enabled = false
		dialogue:Play(conversation, getHumanoid())
		prompt.Enabled = true
	end)
end

bindPrompt("Jester", jesterConversation)
bindPrompt("angel", angelConversation)
