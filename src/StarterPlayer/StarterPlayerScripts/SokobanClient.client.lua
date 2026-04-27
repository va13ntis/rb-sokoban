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
local FLOOR_HEIGHT = CELL * 2.1

local COLORS = {
	Wall = Color3.fromRGB(55, 55, 72),
	Floor = Color3.fromRGB(42, 42, 52),
	Target = Color3.fromRGB(90, 140, 90),
	Box = Color3.fromRGB(180, 120, 70),
	BoxOnTarget = Color3.fromRGB(120, 180, 100),
	StairUp = Color3.fromRGB(80, 125, 210),
	StairDown = Color3.fromRGB(210, 125, 80),
	LadderUp = Color3.fromRGB(70, 190, 180),
	LadderDown = Color3.fromRGB(190, 95, 185),
}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local levelFolder: Folder? = nil
local boxParts: { BasePart } = {}
local currentFloors: { Grid } = {}
local currentGrid: Grid = {}
local levelIndex = 1
local moveCount = 0
local currentFacingYaw = math.rad(90)
local currentFloorIndex = 1

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
hint.Text = "WASD / arrows — move (stairs ^/v, ladders H/h)   R — restart level   N — next level"
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

local function gridToWorld(row: number, col: number, floorIndex: number, yLift: number): Vector3
	local rows, cols = SokobanCore.dimensions(currentFloors[1] or currentGrid)
	local offsetX = -(cols - 1) * CELL / 2
	local offsetZ = -(rows - 1) * CELL / 2
	local x = offsetX + (col - 1) * CELL
	local z = offsetZ + (row - 1) * CELL
	local floorY = (floorIndex - 1) * FLOOR_HEIGHT
	return Vector3.new(x, floorY + yLift, z)
end

local function clearLevelVisuals()
	if levelFolder then
		levelFolder:Destroy()
		levelFolder = nil
	end
	table.clear(boxParts)
end

local function baseFromCell(ch: string): string
	if ch == "+" or ch == "*" then
		return "."
	elseif ch == "A" or ch == "{" then
		return "^"
	elseif ch == "V" or ch == "}" then
		return "v"
	elseif ch == "K" or ch == "[" then
		return "H"
	elseif ch == "k" or ch == "]" then
		return "h"
	end
	return ch
end

local function isBoxCell(ch: string): boolean
	return ch == "$" or ch == "*" or ch == "{" or ch == "}" or ch == "[" or ch == "]"
end

local function boxForBaseCell(ch: string): string?
	if ch == " " then
		return "$"
	elseif ch == "." then
		return "*"
	elseif ch == "^" then
		return "{"
	elseif ch == "v" then
		return "}"
	elseif ch == "H" then
		return "["
	elseif ch == "h" then
		return "]"
	end
	return nil
end

local function isOpenForBox(ch: string): boolean
	return boxForBaseCell(ch) ~= nil
end

local function findConnector(grid: Grid, connector: string): (number?, number?)
	for r = 1, #grid do
		for c = 1, #grid[r] do
			if baseFromCell(grid[r][c]) == connector then
				return r, c
			end
		end
	end
	return nil, nil
end

local function buildStaticLevel()
	clearLevelVisuals()
	local folderInst = Instance.new("Folder")
	folderInst.Name = "SokobanLevel"
	folderInst.Parent = workspace
	levelFolder = folderInst

	for floorIndex, grid in currentFloors do
		local rows, cols = SokobanCore.dimensions(grid)
		for r = 1, rows do
			for c = 1, cols do
				local ch = baseFromCell(grid[r][c])
				local pos = gridToWorld(r, c, floorIndex, 0)
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

				if ch == "." then
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

				if ch == "^" or ch == "v" or ch == "H" or ch == "h" then
					local connector = Instance.new("Part")
					connector.Name = if ch == "^" or ch == "v" then "Stair" else "Ladder"
					connector.Anchored = true
					connector.CanCollide = false
					connector.Size = Vector3.new(CELL * 0.45, 0.1, CELL * 0.45)
					connector.Position = pos + Vector3.new(0, 0.16, 0)
					if ch == "^" then
						connector.Color = COLORS.StairUp
					elseif ch == "v" then
						connector.Color = COLORS.StairDown
					elseif ch == "H" then
						connector.Color = COLORS.LadderUp
					else
						connector.Color = COLORS.LadderDown
					end
					connector.Material = Enum.Material.Neon
					connector.Transparency = 0.15
					connector.Parent = folderInst
				end
			end
		end
	end
end

local function ensureBoxes()
	local needed = 0
	for _, grid in currentFloors do
		for r = 1, #grid do
			for c = 1, #grid[r] do
				if isBoxCell(grid[r][c]) then
					needed += 1
				end
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
	for floorIndex, grid in currentFloors do
		for r = 1, #grid do
			for c = 1, #grid[r] do
				local ch = grid[r][c]
				if isBoxCell(ch) then
					local part = boxParts[idx]
					idx += 1
					local pos = gridToWorld(r, c, floorIndex, BOX_HEIGHT / 2)
					part.Position = pos
					part.Color = if ch == "*" then COLORS.BoxOnTarget else COLORS.Box
				end
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
		local pos = gridToWorld(pr, pc, currentFloorIndex, PLAYER_Y_OFFSET)
		hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, currentFacingYaw, 0)
	end
end

local function pointCameraAtLevel()
	local rows, cols = SokobanCore.dimensions(currentFloors[1] or currentGrid)
	local center = gridToWorld((rows + 1) / 2, (cols + 1) / 2, math.max(1, math.ceil(#currentFloors / 2)), 0)
	local camPos = center
		+ Vector3.new(0, math.max(rows, cols) * CELL * 0.85 + (#currentFloors - 1) * FLOOR_HEIGHT * 0.5, math.max(rows, cols) * CELL * 0.8)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(camPos, center + Vector3.new(0, 1, 0))
	camera.FieldOfView = 55
end

local function updateHUD()
	local L = Levels[levelIndex]
	title.Text = L.name
	subtitle.Text = string.format(
		"Level %d / %d  ·  Floor %d / %d  ·  Moves: %d",
		levelIndex,
		#Levels,
		currentFloorIndex,
		#currentFloors,
		moveCount
	)
end

local function isOpenForPlayer(ch: string): boolean
	return ch == " " or ch == "." or ch == "^" or ch == "v" or ch == "H" or ch == "h"
end

local function leavePlayerCell(grid: Grid, row: number, col: number)
	local ch = grid[row][col]
	if ch == "@" then
		grid[row][col] = " "
	elseif ch == "+" then
		grid[row][col] = "."
	elseif ch == "A" then
		grid[row][col] = "^"
	elseif ch == "V" then
		grid[row][col] = "v"
	elseif ch == "K" then
		grid[row][col] = "H"
	elseif ch == "k" then
		grid[row][col] = "h"
	end
end

local function setPlayerCell(grid: Grid, row: number, col: number)
	local base = grid[row][col]
	if base == "." then
		grid[row][col] = "+"
	elseif base == "^" then
		grid[row][col] = "A"
	elseif base == "v" then
		grid[row][col] = "V"
	elseif base == "H" then
		grid[row][col] = "K"
	elseif base == "h" then
		grid[row][col] = "k"
	else
		grid[row][col] = "@"
	end
end

local function settleFallingBoxes()
	local moved = true
	while moved do
		moved = false
		for floorIndex = 2, #currentFloors do
			local upper = currentFloors[floorIndex]
			local lower = currentFloors[floorIndex - 1]
			for r = 1, #upper do
				for c = 1, #upper[r] do
					local ch = upper[r][c]
					local isDropPoint = ch == "}" or ch == "]"
					if isDropPoint then
						local tr, tc = r, c
						local landing = lower[tr] and lower[tr][tc] or nil
						if not landing or not isOpenForBox(landing) then
							local connector = if ch == "}" then "^" else "H"
							local sr, sc = findConnector(lower, connector)
							if sr and sc then
								tr, tc = sr, sc
								landing = lower[tr][tc]
							end
						end
						if landing and isOpenForBox(landing) then
							upper[r][c] = if ch == "}" then "v" else "h"
							local dropped = boxForBaseCell(landing)
							if dropped then
								lower[tr][tc] = dropped
								moved = true
							end
						end
					end
				end
			end
		end
	end
end

local function transitionFloorIfOnStairs()
	local pr, pc = SokobanCore.findPlayer(currentGrid)
	if not pr or not pc then
		return
	end
	local ch = currentGrid[pr][pc]
	local targetFloor = currentFloorIndex
	local targetConnector = ""
	if ch == "A" and currentFloorIndex < #currentFloors then
		targetFloor = currentFloorIndex + 1
		targetConnector = "v"
	elseif ch == "V" and currentFloorIndex > 1 then
		targetFloor = currentFloorIndex - 1
		targetConnector = "^"
	elseif ch == "K" and currentFloorIndex < #currentFloors then
		targetFloor = currentFloorIndex + 1
		targetConnector = "h"
	elseif ch == "k" and currentFloorIndex > 1 then
		targetFloor = currentFloorIndex - 1
		targetConnector = "H"
	else
		return
	end

	local fromGrid = currentGrid
	local toGrid = currentFloors[targetFloor]
	local tr, tc = pr, pc
	local inBounds = tr >= 1 and tr <= #toGrid and tc >= 1 and tc <= #toGrid[tr]
	if not inBounds or not isOpenForPlayer(toGrid[tr][tc]) then
		local sr, sc = findConnector(toGrid, targetConnector)
		if not sr or not sc then
			return
		end
		tr, tc = sr, sc
	end

	leavePlayerCell(fromGrid, pr, pc)
	setPlayerCell(toGrid, tr, tc)
	currentFloorIndex = targetFloor
	currentGrid = toGrid
end

local function isLevelWin(): boolean
	for _, floorGrid in currentFloors do
		if not SokobanCore.isWin(floorGrid) then
			return false
		end
	end
	return true
end

local function loadLevel(index: number)
	levelIndex = math.clamp(index, 1, #Levels)
	local L = Levels[levelIndex]
	currentFloors = {}
	if L.floors and #L.floors > 0 then
		for _, floorMap in L.floors do
			table.insert(currentFloors, SokobanCore.parse(floorMap))
		end
	elseif L.map then
		table.insert(currentFloors, SokobanCore.parse(L.map))
	end
	currentFloorIndex = 1
	currentGrid = currentFloors[currentFloorIndex]
	moveCount = 0
	currentFacingYaw = math.rad(90)
	buildStaticLevel()
	ensureBoxes()
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
	if dCol == 1 then
		currentFacingYaw = math.rad(90)
	elseif dCol == -1 then
		currentFacingYaw = math.rad(-90)
	elseif dRow == 1 then
		currentFacingYaw = math.rad(180)
	elseif dRow == -1 then
		currentFacingYaw = 0
	end
	currentGrid = nextGrid
	currentFloors[currentFloorIndex] = currentGrid
	settleFallingBoxes()
	transitionFloorIfOnStairs()
	currentFloors[currentFloorIndex] = currentGrid
	moveCount += 1
	buildStaticLevel()
	ensureBoxes()
	placeCharacter(currentGrid)
	updateHUD()

	if isLevelWin() then
		winFrame.Visible = true
		task.delay(1.2, function()
			if isLevelWin() and levelIndex < #Levels then
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
		or input.KeyCode == Enum.KeyCode.Right
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
