--!strict
--[[
	Classic Sokoban grid rules.
	Tiles: # wall, space floor, . target, @ player, + player on target,
	       $ box, * box on target
]]

local SokobanCore = {}

export type Grid = { { string } }

local function cloneGrid(grid: Grid): Grid
	local copy: Grid = {}
	for r = 1, #grid do
		local row = grid[r]
		local newRow: { string } = {}
		for c = 1, #row do
			newRow[c] = row[c]
		end
		copy[r] = newRow
	end
	return copy
end

function SokobanCore.parse(levelText: string): Grid
	local grid: Grid = {}
	for line in string.gmatch(levelText, "([^\n]+)") do
		if string.match(line, "%S") then
			local row: { string } = {}
			for i = 1, #line do
				table.insert(row, string.sub(line, i, i))
			end
			table.insert(grid, row)
		end
	end
	local maxW = 0
	for _, row in grid do
		maxW = math.max(maxW, #row)
	end
	for _, row in grid do
		while #row < maxW do
			table.insert(row, " ")
		end
	end
	return grid
end

function SokobanCore.findPlayer(grid: Grid): (number?, number?)
	for r = 1, #grid do
		local row = grid[r]
		for c = 1, #row do
			local ch = row[c]
			if ch == "@" or ch == "+" then
				return r, c
			end
		end
	end
	return nil, nil
end

function SokobanCore.isWin(grid: Grid): boolean
	for r = 1, #grid do
		local row = grid[r]
		for c = 1, #row do
			local ch = row[c]
			if ch == "." or ch == "+" or ch == "$" then
				return false
			end
		end
	end
	return true
end

local function isBox(ch: string): boolean
	return ch == "$" or ch == "*"
end

function SokobanCore.tryMove(grid: Grid, deltaRow: number, deltaCol: number): Grid?
	local pr, pc = SokobanCore.findPlayer(grid)
	if not pr or not pc then
		return nil
	end

	local nr, nc = pr + deltaRow, pc + deltaCol
	if nr < 1 or nr > #grid then
		return nil
	end
	local nrow0 = grid[nr]
	if not nrow0 or nc < 1 or nc > #nrow0 then
		return nil
	end

	local dest = grid[nr][nc]
	if dest == "#" then
		return nil
	end

	local nextGrid = cloneGrid(grid)
	local prow = nextGrid[pr]
	local nrow = nextGrid[nr]

	local function playerLeavesCell()
		if prow[pc] == "@" then
			prow[pc] = " "
		elseif prow[pc] == "+" then
			prow[pc] = "."
		elseif prow[pc] == "A" then
			prow[pc] = "^"
		elseif prow[pc] == "V" then
			prow[pc] = "v"
		end
	end

	if not isBox(dest) then
		playerLeavesCell()
		if dest == " " then
			nrow[nc] = "@"
		elseif dest == "." then
			nrow[nc] = "+"
		elseif dest == "^" then
			nrow[nc] = "A"
		elseif dest == "v" then
			nrow[nc] = "V"
		end
		return nextGrid
	end

	local br, bc = nr + deltaRow, nc + deltaCol
	if br < 1 or br > #nextGrid then
		return nil
	end
	local brow = nextGrid[br]
	if not brow or bc < 1 or bc > #brow then
		return nil
	end
	local beyond = brow[bc]
	if beyond == "#" or isBox(beyond) then
		return nil
	end

	playerLeavesCell()

	if dest == "$" then
		nrow[nc] = "@"
	elseif dest == "*" then
		nrow[nc] = "+"
	end

	if beyond == " " then
		brow[bc] = "$"
	elseif beyond == "." then
		brow[bc] = "*"
	end

	return nextGrid
end

function SokobanCore.dimensions(grid: Grid): (number, number)
	if #grid == 0 then
		return 0, 0
	end
	return #grid, #grid[1]
end

return SokobanCore
