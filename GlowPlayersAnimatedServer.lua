-- ServerScripts/GlowPlayersAnimatedServer.lua
-- 配置場所: ServerScriptService に Script として置いてください。
-- 概要: 各プレイヤーのキャラクターに Highlight を追加し、
--        サーバー側でアニメーション（pulse / blink / color / all）を実行します。
-- 注意: サーバー側でアニメーションを行うと全クライアントに伝播します。負荷に注意。

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- 設定
local HIGHLIGHT_NAME = "PlayerGlowAnimated"
local MODE = "all" -- "pulse" | "blink" | "color" | "all"
local SERVER_UPDATE_INTERVAL = 0.08 -- 更新間隔（秒）。短くすると滑らかだが負荷増

-- Pulse（明るさの変化）
local PULSE = {
	speed = 1.2,            -- 速さ（高いほど早く往復）
	minTransparency = 0.2,  -- 最小FillTransparency（0 = 不透明）
	maxTransparency = 0.8,  -- 最大FillTransparency（1 = 透明）
}

-- Blink（オン/オフ）
local BLINK = {
	period = 1.0,          -- 1サイクルの秒数（オン→オフ→オン）
	onTransparency = 0.2,  -- 点灯時の透明度
	offTransparency = 1.0, -- 消灯時の透明度
}

-- Color cycle（色変化）
local COLOR = {
	speed = 0.15,          -- 色相が1周する速さ（1 が 1秒で一周）
	saturation = 0.9,
	value = 0.95,
}

-- 基本色（色変化を使わない場合のベース）
local BASE_COLOR = Color3.fromRGB(0, 170, 255)
local OUTLINE_OFFSET = 0.08 -- アウトラインは若干異なる透明度にする

-- アニメーション管理テーブル
local animators = {} -- highlight -> bindable (stop flag)

local function createHighlightForCharacter(character)
	if not character or not character:IsA("Model") then return nil end

	-- 既存を消す（重複防止）
	local existing = character:FindFirstChild(HIGHLIGHT_NAME)
	if existing then
		existing:Destroy()
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = HIGHLIGHT_NAME
	highlight.Adornee = character
	highlight.Parent = character
	highlight.FillColor = BASE_COLOR
	highlight.OutlineColor = BASE_COLOR
	highlight.FillTransparency = 0.6
	highlight.OutlineTransparency = 0.7
	highlight.Enabled = true

	return highlight
end

local function startAnimationLoop(highlight)
	if not highlight then return end
	-- 既にあるなら停止フラグを立てる
	if animators[highlight] then
		animators[highlight].running = false
	end

	local binder = { running = true }
	animators[highlight] = binder

	-- アニメーションループ（サーバー側は少し低頻度で回す）
	spawn(function()
		local startTick = tick()
		while binder.running and highlight.Parent do
			local t = tick() - startTick

			-- PULSE（滑らかな明滅）
			if MODE == "pulse" or MODE == "all" then
				local s = PULSE.speed
				local v = (math.sin(t * s * math.pi * 2) + 1) / 2 -- 0..1
				local ft = PULSE.minTransparency + v * (PULSE.maxTransparency - PULSE.minTransparency)
				highlight.FillTransparency = ft
				highlight.OutlineTransparency = math.clamp(ft + OUTLINE_OFFSET, 0, 1)
			end

			-- BLINK（明確に点滅）
			if MODE == "blink" or MODE == "all" then
				local phase = (t % BLINK.period) / BLINK.period
				-- 単純に半周期On/Offにする（カスタム可）
				if phase < 0.5 then
					highlight.FillTransparency = BLINK.onTransparency
					highlight.OutlineTransparency = math.clamp(BLINK.onTransparency + OUTLINE_OFFSET, 0, 1)
				else
					highlight.FillTransparency = BLINK.offTransparency
					highlight.OutlineTransparency = math.clamp(BLINK.offTransparency + OUTLINE_OFFSET, 0, 1)
				end
			end

			-- COLOR（色相を変える）
			if MODE == "color" or MODE == "all" then
				local hue = (t * COLOR.speed) % 1
				local c = Color3.fromHSV(hue, COLOR.saturation, COLOR.value)
				highlight.FillColor = c
				highlight.OutlineColor = c
			end

			wait(SERVER_UPDATE_INTERVAL)
		end
		-- 終了時のクリーンアップ
		if animators[highlight] == binder then
			animators[highlight] = nil
		end
	end)
end

local function onCharacterAdded(character)
	local highlight = createHighlightForCharacter(character)
	if highlight then
		startAnimationLoop(highlight)
		-- キャラ破壊時にストップ
		character.AncestryChanged:Connect(function(_, parent)
			if not parent and highlight and animators[highlight] then
				animators[highlight].running = false
			end
		end)
	end
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

-- スクリプト停止時はアニメータを停止
script.Destroying:Connect(function()
	for h, b in pairs(animators) do
		if b then b.running = false end
	end
end)