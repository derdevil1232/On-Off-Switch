local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local player = Players.LocalPlayer

-- 🔧 Enable NoClip continuously
RunService.Stepped:Connect(function()
	local char = player.Character
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
end)

-- 🛡️ Invincibility: disable .Touched connections on all parts
local function makeInvincible()
	local char = player.Character
	if not char then return end

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			local connections = getconnections(part.Touched)
			for _, conn in ipairs(connections) do
				conn:Disable()
			end
		end
	end
end

-- Apply invincibility on every respawn
Players.LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	makeInvincible()
end)

-- Initial invincibility
if player.Character then
	task.wait(0.5)
	makeInvincible()
end

-- 📍 Get character
local function getCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:WaitForChild("HumanoidRootPart").Parent
end

-- 🗺️ Get current MM2 map
local function getCurrentMap()
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:FindFirstChild("CoinContainer") then
			return obj
		end
	end
	return nil
end

-- 🪙 Find closest Coin_Server
local function getClosestCoin(hrp, coinContainer)
	local closest, shortest = nil, math.huge
	for _, coin in ipairs(coinContainer:GetChildren()) do
		if coin:IsA("Part") and coin.Name == "Coin_Server" then
			local dist = (hrp.Position - coin.Position).Magnitude
			if dist < shortest then
				shortest = dist
				closest = coin
			end
		end
	end
	return closest
end

-- 🧲 Smooth move to a position (SLOWER for undetectable movement)
local function moveToPosition(hrp, targetPos)
	local dist = (hrp.Position - targetPos).Magnitude
	local duration = math.clamp(dist / 12, 0.4, 1.2) -- slower
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local goal = {CFrame = CFrame.new(targetPos)}
	local tween = TweenService:Create(hrp, tweenInfo, goal)
	tween:Play()
	tween.Completed:Wait()
end

-- ♻️ Main loop
task.spawn(function()
	while true do
		local char = player.Character or player.CharacterAdded:Wait()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then task.wait(0.1) continue end

		local map = getCurrentMap()
		if map and map:FindFirstChild("CoinContainer") then
			local coin = getClosestCoin(hrp, map.CoinContainer)
			if coin and coin:IsDescendantOf(map.CoinContainer) then
				local targetPos = coin.Position + Vector3.new(5, 2, 0)
				moveToPosition(hrp, targetPos)
				moveToPosition(hrp, coin.Position + Vector3.new(0, 1, 0))

				-- Destroy coin after touching
				task.delay(0.2, function()
					if coin and coin:IsDescendantOf(game) then
						coin:Destroy()
					end
				end)
			end
		end

		task.wait(0.05)
	end
end)

-- 💀 Reset character if coin bag is full
task.spawn(function()
	local path = player:WaitForChild("PlayerGui"):WaitForChild("MainGUI"):WaitForChild("Lobby")
		:WaitForChild("Dock"):WaitForChild("CoinBags"):WaitForChild("Container")
		:WaitForChild("BeachBall"):WaitForChild("Full")

	while true do
		if path.Visible then
			local char = player.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid.Health = 0
			end
		end
		task.wait(0.1)
	end
end)