-- StarterPlayerScripts/GlowAnimatedNearbyClient.lua
-- 配置場所: StarterPlayer > StarterPlayerScripts に LocalScript として置いてください。
-- 概要: 自分のクライアント上に見えている（または距離内の）プレイヤーに対して
--        スムーズなアニメーション（pulse / blink / color / all）を適用します。
-- 利点: アニメーションをクライアント側で処理するためサーバー負荷/帯域を節約できます。

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 設定
local HIGHLIGHT_NAME = "LocalAnimatedGlow"
local MODE = "all" -- "pulse" | "blink" | "color" | "all"
local MAX_DISTANCE = 60 -- 何スタッド以内のプレイヤーに対して有効にするか（視認範囲）
local CLIENT_UPDATE_STEP = RunService.Heartbeat -- Heartbeat で毎フレーム更新

-- Pulse
local PULSE = { speed = 2.2, minTransparency = 0.15, maxTransparency = 0.85 }

-- Blink
local BLINK = { period = 1.0, onTransparency = 0.15, offTransparency = 1.0 }

-- Color
local COLOR = { speed = 0.25, saturation = 0.9, value = 0.95 }

local BASE_COLOR = Color3.fromRGB(255, 170, 50)
local OUTLINE_OFFSET = 0.06

local highlights = {} -- player -> { highlight = Instance, createdAt = tick() }

local function ensureHighlight(character)
	if not character or not character:IsA("Model") then return nil end
	local existing = character:FindFirstChild(HIGHLIGHT_NAME)
	if existing and existing:IsA("Highlight") then
		return existing
	end
	local h = Instance.new("Highlight")
	h.Name = HIGHLIGHT_NAME
	h.Adornee = character
	h.Parent = character
	h.FillColor = BASE_COLOR
	h.OutlineColor = BASE_COLOR
	h.FillTransparency = 0.6
	h.OutlineTransparency = 0.7
	h.Enabled = false -- 距離で切り替え
	return h
end

local function setupPlayer(player)
	if player == LocalPlayer then return end
	local function onChar(char)
		local h = ensureHighlight(char)
		if h then
			highlights[player] = { highlight = h, createdAt = tick() }
			-- クリーンアップ
			char.AncestryChanged:Connect(function(_, parent)
				if not parent and highlights[player] then
					highlights[player] = nil
				end
			end)
		end
	end
	if player.Character then onChar(player.Character) end
	player.CharacterAdded:Connect(onChar)
end

for _, pl in ipairs(Players:GetPlayers()) do
	setupPlayer(pl)
end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(pl) highlights[pl] = nil end)

-- メイン更新ループ（フレーム同期で滑らかに）
local startTick = tick()
CLIENT_UPDATE_STEP:Connect(function(dt)
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		-- 自キャラがない場合は全Highlightを非表示
		for _, v in pairs(highlights) do
			if v.highlight and v.highlight.Enabled then v.highlight.Enabled = false end
		end
		return
	end

	local now = tick()
	for player, data in pairs(highlights) do
		local h = data.highlight
		if not h or not h.Parent then
			highlights[player] = nil
		else
			local char = player.Character
			local otherRoot = char and char:FindFirstChild("HumanoidRootPart")
			local enabled = false
			if otherRoot then
				local dist = (otherRoot.Position - myRoot.Position).Magnitude
				enabled = dist <= MAX_DISTANCE
			end

			h.Enabled = enabled
			if not enabled then
				-- 非表示時は処理をスキップ
				goto continue
			end

			local t = now - startTick

			-- PULSE
			if MODE == "pulse" or MODE == "all" then
				local s = PULSE.speed
				local v = (math.sin(t * s * math.pi * 2) + 1) / 2
				local ft = PULSE.minTransparency + v * (PULSE.maxTransparency - PULSE.minTransparency)
				h.FillTransparency = ft
				h.OutlineTransparency = math.clamp(ft + OUTLINE_OFFSET, 0, 1)
			end

			-- BLINK
			if MODE == "blink" or MODE == "all" then
				local phase = (t % BLINK.period) / BLINK.period
				if phase < 0.5 then
					h.FillTransparency = BLINK.onTransparency
					h.OutlineTransparency = math.clamp(BLINK.onTransparency + OUTLINE_OFFSET, 0, 1)
				else
					h.FillTransparency = BLINK.offTransparency
					h.OutlineTransparency = math.clamp(BLINK.offTransparency + OUTLINE_OFFSET, 0, 1)
				end
			end

			-- COLOR
			if MODE == "color" or MODE == "all" then
				local hue = (t * COLOR.speed) % 1
				local c = Color3.fromHSV(hue, COLOR.saturation, COLOR.value)
				h.FillColor = c
				h.OutlineColor = c
			end
		end
		::continue::
	end
end)