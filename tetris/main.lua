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
	self.old_input = {}

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

old_dx = 0
old_dr = 0
dr_tick = 0
dx_tick = 0

function Grid:update()

	local dr = bool[self.input.a] - bool[self.input.b]
	local dx = bool[self.input.right] - bool[self.input.left]

	if dr ~= old_dr then
		dr_tick = 0
		old_dr = dr
	else
		dr_tick = dr_tick + 1
		if dr_tick > 10 then
			dr_tick = 0
		else
			dr = 0
		end
	end


	if dx ~= old_dx then
		dx_tick = 0
		old_dx = dx
	else
		dx_tick = dx_tick + 1
		if dx_tick > 4 then
			dx_tick = 0
		else
			dx = 0
		end
	end


	-- rotation
	if dr ~= 0 then
		local i = self.rot
		if dr > 0 then
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
--	self.x = self.x + bool[self.input.right] - bool[self.input.left]
	self.x = self.x + dx
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

			-- check for complete lines
			for y, row in ipairs(self.matrix) do
				local complete = true
				for x, cell in ipairs(row) do
					if not cell then
						complete = false
						break
					end
				end
				if complete then

					-- increase level
					self.lines = self.lines + 1
					self.level_progress = self.level_progress + 1
					if self.level_progress == 10 then
						self.level_progress = 0
						self.ticks_per_drop = self.ticks_per_drop - 1
						if self.ticks_per_drop < 1 then
							self.ticks_per_drop = 1
						end
					end

					-- drop
					for i = y, 1, -1 do
						for x = 1, self.WIDTH do
							self.matrix[i][x] = i > 1 and self.matrix[i - 1][x]
								or false
						end
					end

				end
			end

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
	local BACKGROUND = { 5, 5, 5 }

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
--	players[2]:update()

	players[1]:draw()
--	players[2]:draw()

end

