require "greatwall"
require "helper"

function wall.load()
	return "seb.exse.net", 1338
end


local Grid = Object:new {
	WIDTH = 10,
	HEIGHT = 20,
	STONES = {
		{ 0, 0, 0, 0, 0,15,15, 0, 0,15,15, 0, 0, 0, 0, 0 }, -- cube
		{ 0, 0,10, 0, 5, 5,15, 5, 0, 0,10, 0, 0, 0,10, 0 }, -- xxxx
		{ 0, 0, 5, 0, 0, 0,15,15, 0,10,10, 5, 0, 0, 0, 0 }, -- Z
		{ 0, 0, 0, 5, 0,10,15, 5, 0, 0,15,10, 0, 0, 0, 0 }, -- S
		{ 0, 4, 5, 8, 0,10,15,10, 0, 2, 5, 1, 0, 0, 0, 0 }, -- J
		{ 0, 8, 5, 1, 0,10,15,10, 0, 4, 5, 2, 0, 0, 0, 0 }, -- L
		{ 0, 0,11, 0, 0,13,15, 7, 0, 0,14, 0, 0, 0, 0, 0 }, -- T
	}
}
function Grid:init(player_nr)

	self.player_nr = player_nr
	self.input = wall.getInput(player_nr)

	self:newStone()
	self:newStone()

	self.ticks_per_drop = 30
	self.level_progress = 0
	self.lines = 0

	self.matrix = {}
	for i = 1, self.HEIGHT do
		local row = {}
		for j = 1, self.WIDTH do row[j] = false end
		self.matrix[i] = row
	end
end
function Grid:newStone()
	self.tick = 0
	self.x = math.floor(self.WIDTH / 2) - 1
	self.y = -2

	self.rot = self.next_rot
	self.stone = self.next_stone
	self.color = self.next_color

	self.next_rot = 2 ^ math.random(0, 3)
	self.next_stone = self.STONES[math.random(#self.STONES)]
	self.next_color = { math.random(255), math.random(255), math.random(255) }
end
function Grid:collision(check_top)
	for y = 0, 3 do
		for x = 0, 3 do
			if isBitSet(self.stone[x * 4 + y + 1], self.rot) then
				if check_top then
					if	x + self.x <= 0 or x + self.x > self.WIDTH or
						y + self.y <= 0 or y + self.y > self.HEIGHT or
						self.matrix[y + self.y][x + self.x]
					then
						return true
					end
				else
					if	x + self.x <= 0 or x + self.x > self.WIDTH or
						y + self.y > self.HEIGHT or
						y + self.y > 0 and self.matrix[y + self.y][x + self.x]
					then
						return true
					end
				end
			end
		end
	end
	return false
end
function Grid:update()

	-- rotation
	if self.input.a or self.input.b then
		local i = self.rot
		if self.input.a then
			self.rot = self.rot < 8 and self.rot * 2 or 1
		else
			self.rot = self.rot > 1 and self.rot / 2 or 8
		end
		if self:collision(false) then
			self.rot = i
		end
	end

	-- horizontal movement
	local i = self.x
	self.x = self.x + bool[self.input.right] - bool[self.input.left]
	if i ~= self.x and self:collision(false) then
		self.x = i
	end

	-- vertical movement
	self.tick = self.tick + 1
	if self.input.down or self.tick >= self.ticks_per_drop then
		self.tick = 0
		self.y = self.y + 1
		if self:collision(false) then
			self.y = self.y - 1

			-- game over
			if self:collision(true) then
				print("game over")
				love.event.push "q"
				return
			end

			-- copy stone to matrix
			for y = 0, 3 do
				for x = 0, 3 do
					if isBitSet(self.stone[x * 4 + y + 1], self.rot) then
						self.matrix[y + self.y][x + self.x] = self.color
					end
				end
			end

			-- TODO: check for complete lines


			self:newStone()
		end
	end
end

function isBitSet(n, b)
	return (n / b) % 2 >=1
end
function Grid:draw()

	local ox = (self.player_nr - 1) * 12
	local oy = 3
	local BACKGROUND = { 10, 10, 10 }

	for y, row in ipairs(self.matrix) do
		for x, cell in ipairs(row) do
			local color = cell or BACKGROUND
			if	x >= self.x and x < self.x + 4 and
				y >= self.y and y < self.y + 4 and
				isBitSet(self.stone[(x - self.x) * 4 + y - self.y + 1], self.rot)
			then
				color = self.color
			end

			wall.pixel(x + ox, y + oy, unpack(color)) -- background
		end
	end
end


players = { Grid(1), Grid(2) }

function wall.tick()
	players[1]:update()
	players[2]:update()

	players[1]:draw()
	players[2]:draw()

end

