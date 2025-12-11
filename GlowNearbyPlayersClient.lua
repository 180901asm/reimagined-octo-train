-- StarterPlayerScripts/GlowNearbyPlayersClient.lua
-- 配置場所: StarterPlayer > StarterPlayerScripts に LocalScript として置いてください。
-- 概要: 自分のクライアントに表示されるプレイヤーだけを、一定距離内で光らせます（クライアント側でのみ処理）。
-- 利点: サーバーの負荷を軽減し、距離による視認性制御が可能。
-- 注意: この LocalScript はクライアント専用のため、他のプレイヤー全員には影響しません（視覚効果は自分のクライアント上のみ）。

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- 設定
local GLOW_COLOR = Color3.fromRGB(255, 200, 0)
local FILL_TRANSPARENCY = 0.6
local OUTLINE_TRANSPARENCY = 0.7
local HIGHLIGHT_NAME = "LocalProximityGlow"
local MAX_DISTANCE = 50 -- 何スタッド以内のプレイヤーを光らせるか
local CHECK_INTERVAL = 0.2 -- 距離チェック間隔（秒）

local function ensureHighlight(character)
	if not character or not character:IsA("Model") then return nil end
	local h = character:FindFirstChild(HIGHLIGHT_NAME)
	if h and h:IsA("Highlight") then
		return h
	end
	h = Instance.new("Highlight")
	h.Name = HIGHLIGHT_NAME
	h.Adornee = character
	h.Parent = character
	h.FillColor = GLOW_COLOR
	h.OutlineColor = GLOW_COLOR
	h.FillTransparency = FILL_TRANSPARENCY
	h.OutlineTransparency = OUTLINE_TRANSPARENCY
	h.Enabled = false -- 距離に応じて有効化する
	return h
end

local function onCharacterAdded(character)
	-- キャラクターに必要な初期化（ハイライトの準備）
	ensureHighlight(character)
end

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- 各プレイヤーのキャラクターができたらハイライトインスタンスを作っておく
local function setupPlayer(player)
	local function handleChar(char)
		ensureHighlight(char)
	end
	if player.Character then
		handleChar(player.Character)
	end
	player.CharacterAdded:Connect(handleChar)
end

for _, pl in ipairs(Players:GetPlayers()) do
	if pl ~= LocalPlayer then
		setupPlayer(pl)
	end
end
Players.PlayerAdded:Connect(function(pl)
	if pl ~= LocalPlayer then
		setupPlayer(pl)
	end
end)

-- 距離チェックループ（最適化の余地あり）
spawn(function()
	while true do
		local myChar = LocalPlayer.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if myRoot then
			local myPos = myRoot.Position
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= LocalPlayer and pl.Character then
					local otherRoot = pl.Character:FindFirstChild("HumanoidRootPart")
					local highlight = pl.Character:FindFirstChild(HIGHLIGHT_NAME)
					if otherRoot and highlight then
						local dist = (otherRoot.Position - myPos).Magnitude
						highlight.Enabled = (dist <= MAX_DISTANCE)
					end
				end
			end
		else
			-- プレイヤーキャラがない場合は一時的に全オフ
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= LocalPlayer and pl.Character then
					local highlight = pl.Character:FindFirstChild(HIGHLIGHT_NAME)
					if highlight then highlight.Enabled = false end
				end
			end
		end
		wait(CHECK_INTERVAL)
	end
end)