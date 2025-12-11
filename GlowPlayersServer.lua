-- ServerScripts/GlowPlayersServer.lua
-- 配置場所: ServerScriptService に Script として置いてください。
-- 概要: 各プレイヤーのキャラクターに Highlight を追加して、常に全員が光って見えるようにします。
-- カスタマイズ: GLOW_COLOR, FILL_TRANSPARENCY, OUTLINE_TRANSPARENCY を変更してください。

local Players = game:GetService("Players")

-- 設定
local GLOW_COLOR = Color3.fromRGB(0, 170, 255) -- 光らせる色
local FILL_TRANSPARENCY = 0.6  -- 0 が不透明、1 が完全透明（Fill の透明度）
local OUTLINE_TRANSPARENCY = 0.7 -- アウトラインの透明度
local HIGHLIGHT_NAME = "PlayerGlowHighlight" -- ハイライトのインスタンス名

local function applyHighlightToCharacter(character)
	if not character or not character:IsA("Model") then return end

	-- 既にあるなら破棄（リロード時の重複防止）
	local existing = character:FindFirstChild(HIGHLIGHT_NAME)
	if existing then
		existing:Destroy()
	end

	-- Highlight を作成してキャラクターにアタッチ
	local highlight = Instance.new("Highlight")
	highlight.Name = HIGHLIGHT_NAME
	highlight.Adornee = character
	highlight.Parent = character
	highlight.FillColor = GLOW_COLOR
	highlight.OutlineColor = GLOW_COLOR
	highlight.FillTransparency = FILL_TRANSPARENCY
	highlight.OutlineTransparency = OUTLINE_TRANSPARENCY
	highlight.Enabled = true
	-- DepthMode を変更すると、壁越し（常に手前）などの見え方が変わります。必要に応じて変更してください。
	-- highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function onCharacterAdded(character)
	applyHighlightToCharacter(character)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		applyHighlightToCharacter(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end