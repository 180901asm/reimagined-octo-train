-- SwitchPerspective.local.lua
-- LocalScript: プレイヤーのチャットで "!1" -> 一人称、"!3" -> 三人称 に切り替える
-- 追加: モバイルでエラーが出た場合にシステムメッセージを表示するようにしました
-- 配置場所: StarterPlayer > StarterPlayerScripts に配置してください（LocalScript）。

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then return end

local camera = workspace:WaitForChild("CurrentCamera")

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function sendSystemMessage(text, color)
	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = text;
			Color = color or Color3.fromRGB(120, 200, 120);
		})
	end)
end

local function setFirstPerson()
	-- 一人称に切り替えを試み、失敗（モバイル等）したらシステムメッセージを表示する
	local ok, err = pcall(function()
		-- LockFirstPerson を試す
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		if camera then
			camera.CameraType = Enum.CameraType.Custom
		end
	end)

	if not ok then
		-- エラーが起きたときのメッセージ（モバイル等で失敗する可能性があります）
		sendSystemMessage("一人称に切り替えられませんでした（モバイルではサポートされていない場合があります）。", Color3.fromRGB(255, 120, 120))
	end
end

local function setThirdPerson()
	-- 三人称に戻す
	pcall(function()
		player.CameraMode = Enum.CameraMode.Classic
		if camera then
			camera.CameraType = Enum.CameraType.Custom
		end
	end)
end

-- オプション: 事前にタッチ端末かを判定して先に警告を出す（不要なら削除可）
local function isLikelyMobile()
	-- TouchEnabled が true ならモバイルの可能性が高い（ただしタブレット等も含む）
	return UserInputService.TouchEnabled
end

-- チャットを監視
player.Chatted:Connect(function(message)
	if not message then return end
	local msg = trim(message:lower())

	if msg == "!1" then
		-- 事前警告（任意）
		if isLikelyMobile() then
			-- 事前に通知してから切り替えを試みる
			sendSystemMessage("モバイル端末のため一人称固定がサポートされない場合があります。切替を試みます…", Color3.fromRGB(200, 200, 80))
		end

		setFirstPerson()
		sendSystemMessage("視点を一人称に切り替えました。")
	elseif msg == "!3" then
		setThirdPerson()
		sendSystemMessage("視点を三人称に切り替えました。")
	end
end)