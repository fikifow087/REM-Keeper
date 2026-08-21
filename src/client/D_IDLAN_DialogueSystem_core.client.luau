local UserInputService = game:GetService("UserInputService")
local Dgui = script.Parent
local Shop = Dgui.Parent:FindFirstChild("shop")
local Shopframe = Shop:WaitForChild("Frame")
local frame = Dgui:WaitForChild("Frame")
local frame2 = Dgui:WaitForChild("Frame2")
local frame3 = Dgui:WaitForChild("Frame3") -- VARIABEL BARU UNTUK FRAME3

local Textlabel = frame:WaitForChild("TextLabel")
local Textlabel2 = frame2:WaitForChild("TextLabel2")
local sound = Dgui:WaitForChild("dialod sound")
local player = game.Players.LocalPlayer

-- MENDAPATKAN TOMBOL DI DALAM FRAME3
local buttonA = frame3:WaitForChild("ButtonA")
local buttonB = frame3:WaitForChild("ButtonB")

local shopGui = Dgui.Parent:FindFirstChild("ShopGui")

local Jesterdialog =
	game.Workspace:WaitForChild("Jester"):WaitForChild("HumanoidRootPart"):WaitForChild("ProximityPrompt")
local angeldialog =
	game.Workspace:WaitForChild("angel"):WaitForChild("HumanoidRootPart"):WaitForChild("ProximityPrompt")

local talking = false
local canAdvance = false
local skipRequested = false
local choiceSelected = nil

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if talking then
			-- Jika Frame3 (Tombol Pilihan) sedang muncul, klik layar biasa tidak boleh men-skip/lanjut
			if frame3.Visible then
				return
			end

			if not canAdvance then
				skipRequested = true
			else
				canAdvance = false
			end
		end
	end
end)

buttonA.MouseButton1Click:Connect(function()
	choiceSelected = "A"
end)

buttonB.MouseButton1Click:Connect(function()
	choiceSelected = "B"
end)

-- 1. FUNGSI DIALOG BIASA
local function FirstDialog(text, currentHum)
	if currentHum then
		currentHum.WalkSpeed = 0
		currentHum.JumpPower = 0
	end

	Dgui.Enabled = true
	Textlabel.Visible = true
	Textlabel2.Visible = true
	frame3.Visible = false -- Pastikan Frame3 sembunyi saat dialog biasa

	Textlabel.Text = ""
	skipRequested = false
	canAdvance = false

	for i = 1, #text do
		if skipRequested then
			Textlabel.Text = text
			break
		end
		Textlabel.Text = string.sub(text, 1, i)
		if i % 2 == 0 then
			sound.TimePosition = 0
			sound:Play()
		end
		task.wait(0.03)
	end

	canAdvance = true
	repeat
		task.wait(0.1)
	until not canAdvance or not talking
end

-- 2. FUNGSI DIALOG PILIHAN (Sekarang Bisa Di-skip & Mengetik Perlahan)
local function ChoiceDialog(question, textOptionA, textOptionB, currentHum)
	if currentHum then
		currentHum.WalkSpeed = 0
		currentHum.JumpPower = 0
	end

	Dgui.Enabled = true
	Textlabel.Visible = true
	Textlabel2.Visible = true
	frame3.Visible = false -- Sembunyikan tombol dulu saat pertanyaan sedang diketik

	Textlabel.Text = ""
	skipRequested = false -- Reset status skip sebelum mengetik
	canAdvance = false

	-- Efek Mengetik dengan Fitur Skip yang Diaktifkan
	for i = 1, #question do
		if skipRequested then
			-- Jika pemain mengklik layar saat teks berjalan, langsung munculkan semua teks pertanyaan
			Textlabel.Text = question
			break
		end

		Textlabel.Text = string.sub(question, 1, i)

		if i % 2 == 0 then
			sound.TimePosition = 0
			sound:Play()
		end

		task.wait(0.03)
	end

	-- SETELAH teks selesai penuh (baik karena diketik atau di-skip), munculkan tombol di Frame3
	buttonA.Text = textOptionA
	buttonB.Text = textOptionB
	frame3.Visible = true

	choiceSelected = nil

	-- Menunggu pemain mengklik salah satu tombol pilihan
	repeat
		task.wait(0.1)
	until choiceSelected ~= nil or not talking

	frame3.Visible = false -- Sembunyikan kembali Frame3 setelah diklik

	return choiceSelected
end

local function enddialog(currentHum)
	if currentHum then
		currentHum.WalkSpeed = 16
		currentHum.JumpPower = 50
	end
	Dgui.Enabled = false
	Textlabel.Visible = false
	Textlabel2.Visible = false
	frame3.Visible = false -- Sembunyikan Frame3 saat dialog selesai
	Textlabel.Text = ""
end

-- ==========================================
-- SISA SKRIP NPC DI BAWAH SAMA SEPERTI SEBELUMNYA
-- ==========================================

Jesterdialog.Triggered:Connect(function()
	if talking == false then
		talking = true
		Jesterdialog.Enabled = false
		local currentCharacter = player.Character or player.CharacterAdded:Wait()
		local currentHum = currentCharacter:WaitForChild("Humanoid")
		Textlabel2.Text = "Jester"

		FirstDialog("Hello, welcome to my test zone!", currentHum)

		local hasil = ChoiceDialog("Apakah kamu menyukai game buatan ku ini?", "Ya, Bagus!", "Gak, Jelek.", currentHum)

		if hasil == "A" then
			FirstDialog("Wah, terima kasih banyak! Dukunganmu sangat berarti.", currentHum)
			FirstDialog("Aku akan terus belajar membuat game ini lebih seru.", currentHum)
		elseif hasil == "B" then
			FirstDialog("Oh... maaf ya jika masih banyak kekurangan.", currentHum)
			FirstDialog("Aku akan berusaha memperbaikinya lagi nanti.", currentHum)
		end

		enddialog(currentHum)
		Jesterdialog.Enabled = true
		talking = false
	end
end)

angeldialog.Triggered:Connect(function()
	if talking == false then
		talking = true
		angeldialog.Enabled = false
		local currentCharacter = player.Character or player.CharacterAdded:Wait()
		local currentHum = currentCharacter:WaitForChild("Humanoid")
		Textlabel2.Text = "Angel"

		FirstDialog("Halo anak muda, ada yang bisa kubantu?", currentHum)

		local hasil =
			ChoiceDialog("Apakah kamu ingin melihat barang daganganku?", "Buka Toko", "Tidak, Terima Kasih", currentHum)

		if hasil == "A" then
			FirstDialog("Silakan pilih barang yang kamu butuhkan.", currentHum)
			if shopGui then
				shopGui.Enabled = true
			else
				Shop.Enabled = true
				Shopframe.Visible = true
			end
		elseif hasil == "B" then
			FirstDialog("Baiklah, beritahu aku jika kamu berubah pikiran.", currentHum)
		end

		enddialog(currentHum)
		angeldialog.Enabled = true
		talking = false
	end
end)
