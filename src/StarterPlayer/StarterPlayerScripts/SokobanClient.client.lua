--!strict
--[[ Sokoban: grid movement, push-only crates, win overlay. Single-player client. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local folder = ReplicatedStorage:WaitForChild("Sokoban")
local SokobanCore = require(folder:WaitForChild("SokobanCore"))
local Levels = require(folder:WaitForChild("Levels"))

type Grid = SokobanCore.Grid

local CELL = 4
local WALL_HEIGHT = CELL * 1.2
local BOX_HEIGHT = CELL * 0.85
local PLAYER_Y_OFFSET = 2

local COLORS = {
	Wall = Color3.fromRGB(55, 55, 72),
	Floor = Color3.fromRGB(42, 42, 52),
	Target = Color3.fromRGB(90, 140, 90),
	Box = Color3.fromRGB(180, 120, 70),
	BoxOnTarget = Color3.fromRGB(120, 180, 100),
}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local levelFolder: Folder? = nil
local boxParts: { BasePart } = {}
local currentGrid: Grid = {}
local levelIndex = 1
local moveCount = 0

local gui = Instance.new("ScreenGui")
gui.Name = "SokobanUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(280, 110)
frame.Position = UDim2.new(0, 16, 0, 16)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
frame.BackgroundTransparency = 0.25
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.Parent = frame

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 22)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(240, 240, 245)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(0, 26)
subtitle.Size = UDim2.new(1, 0, 0, 18)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextColor3 = Color3.fromRGB(190, 190, 200)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = frame

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Position = UDim2.fromOffset(0, 50)
hint.Size = UDim2.new(1, 0, 0, 44)
hint.Font = Enum.Font.Gotham
hint.TextSize = 12
hint.TextColor3 = Color3.fromRGB(160, 160, 175)
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextYAlignment = Enum.TextYAlignment.Top
hint.TextWrapped = true
hint.Text = "WASD / arrows — move   R — restart level   N — next level"
hint.Parent = frame

local winFrame = Instance.new("Frame")
winFrame.Name = "WinBanner"
winFrame.Size = UDim2.new(0, 320, 0, 80)
winFrame.Position = UDim2.new(0.5, -160, 0.35, 0)
winFrame.BackgroundColor3 = Color3.fromRGB(30, 80, 50)
winFrame.BackgroundTransparency = 0.1
winFrame.BorderSizePixel = 0
winFrame.Visible = false
winFrame.Parent = gui

local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 10)
winCorner.Parent = winFrame

local winLabel = Instance.new("TextLabel")
winLabel.BackgroundTransparency = 1
winLabel.Size = UDim2.fromScale(1, 1)
winLabel.Font = Enum.Font.GothamBold
winLabel.TextSize = 22
winLabel.TextColor3 = Color3.fromRGB(220, 255, 230)
winLabel.Text = "Level complete!"
winLabel.Parent = winFrame

local function gridToWorld(row: number, col: number, yLift: number): Vector3
	local rows, cols = SokobanCore.dimensions(currentGrid)
	local offsetX = -(cols - 1) * CELL / 2
	local offsetZ = -(rows - 1) * CELL / 2
	local x = offsetX + (col - 1) * CELL
	local z = offsetZ + (row - 1) * CELL
	return Vector3.new(x, yLift, z)
end

local function clearLevelVisuals()
	if levelFolder then
		levelFolder:Destroy()
		levelFolder = nil
	end
	table.clear(boxParts)
end

local function buildStaticLevel(grid: Grid)
	clearLevelVisuals()
	local folderInst = Instance.new("Folder")
	folderInst.Name = "SokobanLevel"
	folderInst.Parent = workspace
	levelFolder = folderInst

	local rows, cols = SokobanCore.dimensions(grid)
	for r = 1, rows do
		for c = 1, cols do
			local ch = grid[r][c]
			local pos = gridToWorld(r, c, 0)
			local floor = Instance.new("Part")
			floor.Name = "Floor"
			floor.Anchored = true
			floor.Size = Vector3.new(CELL - 0.15, 0.35, CELL - 0.15)
			floor.Position = pos + Vector3.new(0, -0.2, 0)
			floor.Color = COLORS.Floor
			floor.Material = Enum.Material.Slate
			floor.Parent = folderInst

			if ch == "#" then
				local wall = Instance.new("Part")
				wall.Name = "Wall"
				wall.Anchored = true
				wall.Size = Vector3.new(CELL - 0.05, WALL_HEIGHT, CELL - 0.05)
				wall.Position = pos + Vector3.new(0, WALL_HEIGHT / 2 - 0.1, 0)
				wall.Color = COLORS.Wall
				wall.Material = Enum.Material.Concrete
				wall.Parent = folderInst
			end

			if ch == "." or ch == "+" or ch == "*" then
				local disc = Instance.new("Part")
				disc.Name = "Target"
				disc.Anchored = true
				disc.CanCollide = false
				disc.Size = Vector3.new(CELL * 0.55, 0.08, CELL * 0.55)
				disc.Position = pos + Vector3.new(0, 0.12, 0)
				disc.Color = COLORS.Target
				disc.Material = Enum.Material.Neon
				disc.Transparency = 0.45
				disc.Parent = folderInst
			end
		end
	end
end

local function ensureBoxes(grid: Grid)
	local needed = 0
	for r = 1, #grid do
		for c = 1, #grid[r] do
			local ch = grid[r][c]
			if ch == "$" or ch == "*" then
				needed += 1
			end
		end
	end

	while #boxParts < needed do
		local p = Instance.new("Part")
		p.Name = "Box"
		p.Anchored = true
		p.Size = Vector3.new(CELL * 0.62, BOX_HEIGHT, CELL * 0.62)
		p.Material = Enum.Material.Wood
		p.Parent = levelFolder
		table.insert(boxParts, p)
	end
	while #boxParts > needed do
		local last = table.remove(boxParts)
		if last then
			last:Destroy()
		end
	end

	local idx = 1
	for r = 1, #grid do
		for c = 1, #grid[r] do
			local ch = grid[r][c]
			if ch == "$" or ch == "*" then
				local part = boxParts[idx]
				idx += 1
				local pos = gridToWorld(r, c, BOX_HEIGHT / 2)
				part.Position = pos
				part.Color = if ch == "*" then COLORS.BoxOnTarget else COLORS.Box
			end
		end
	end
end

local function placeCharacter(grid: Grid)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	hum.WalkSpeed = 0
	hum.JumpHeight = 0
	hum.AutoRotate = false

	local pr, pc = SokobanCore.findPlayer(grid)
	if pr and pc then
		local pos = gridToWorld(pr, pc, PLAYER_Y_OFFSET)
		hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0)
	end
end

local function pointCameraAtLevel()
	local rows, cols = SokobanCore.dimensions(currentGrid)
	local center = gridToWorld((rows + 1) / 2, (cols + 1) / 2, 0)
	local camPos = center + Vector3.new(0, math.max(rows, cols) * CELL * 0.85, math.max(rows, cols) * CELL * 0.75)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(camPos, center + Vector3.new(0, 1, 0))
	camera.FieldOfView = 55
end

local function updateHUD()
	local L = Levels[levelIndex]
	title.Text = L.name
	subtitle.Text = string.format("Level %d / %d  ·  Moves: %d", levelIndex, #Levels, moveCount)
end

local function loadLevel(index: number)
	levelIndex = math.clamp(index, 1, #Levels)
	local L = Levels[levelIndex]
	currentGrid = SokobanCore.parse(L.map)
	moveCount = 0
	buildStaticLevel(currentGrid)
	ensureBoxes(currentGrid)
	placeCharacter(currentGrid)
	pointCameraAtLevel()
	updateHUD()
	winFrame.Visible = false
end

local function tryStep(dRow: number, dCol: number)
	local nextGrid = SokobanCore.tryMove(currentGrid, dRow, dCol)
	if not nextGrid then
		return
	end
	currentGrid = nextGrid
	moveCount += 1
	ensureBoxes(currentGrid)
	placeCharacter(currentGrid)
	updateHUD()

	if SokobanCore.isWin(currentGrid) then
		winFrame.Visible = true
		task.delay(1.2, function()
			if SokobanCore.isWin(currentGrid) and levelIndex < #Levels then
				loadLevel(levelIndex + 1)
			end
		end)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		loadLevel(levelIndex)
		return
	end
	if input.KeyCode == Enum.KeyCode.N then
		loadLevel(levelIndex + 1 > #Levels and 1 or levelIndex + 1)
		return
	end

	local dr, dc = 0, 0
	if
		input.KeyCode == Enum.KeyCode.W
		or input.KeyCode == Enum.KeyCode.Up
	then
		dr = -1
	elseif
		input.KeyCode == Enum.KeyCode.S
		or input.KeyCode == Enum.KeyCode.Down
	then
		dr = 1
	elseif
		input.KeyCode == Enum.KeyCode.A
		or input.KeyCode == Enum.KeyCode.Left
	then
		dc = -1
	elseif
		input.KeyCode == Enum.KeyCode.D
		or input.KeyCode == Enum.Right
	then
		dc = 1
	end
	if dr ~= 0 or dc ~= 0 then
		tryStep(dr, dc)
	end
end)

player.CharacterAdded:Connect(function()
	task.defer(function()
		if #currentGrid > 0 then
			placeCharacter(currentGrid)
		end
	end)
end)

loadLevel(1)
