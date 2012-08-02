require "greatwall"
require "helper"

local function isBitSet(n, b)
	return (n / b) % 2 >= 1
end

local function pickColor()
	local angle = math.random(9) * 40
	local min = 40
	local max = 180

	local color = {}
	for i = 1, 3 do
		angle = (angle + 120) % 360
		if angle < 60 then
			color[i] = min + angle / 60 * (max - min)
		elseif angle < 180 then
			color[i] = max
		elseif angle < 240 then
			color[i] = max - (angle - 180) / 60 * (max - min)
		else
			color[i] = min
		end
	end
	return color
end

local Grid = Object:new {
	WIDTH = 10,
	HEIGHT = 20,
	STONES = {
		{ 0, 0, 0, 0, 0,15,15, 0, 0,15,15, 0, 0, 0, 0, 0 }, -- 2x2
		{ 0, 0,10, 0, 5, 5,15, 5, 0, 0,10, 0, 0, 0,10, 0 }, -- 1x4
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
	-- input helper
	self.dr_old = 0
	self.dx_tick = 0

	self:newStone()
	self:newStone()

	self.ticks_per_drop = 30
	self.level_progress = 0
	self.lines = 0

	self.matrix = {}
	self.complete = {}
	for i = 1, self.HEIGHT do
		local row = {}
		for j = 1, self.WIDTH do row[j] = false end
		self.matrix[i] = row
		self.complete[i] = false
	end

	self.state = "normal"
	self.delay = 0

end
function Grid:newStone()
	self.tick = 0
	self.x = math.floor(self.WIDTH / 2) - 1
	self.y = -2

	self.rot = self.next_rot
	self.stone = self.next_stone
	self.color = self.next_color

	self.next_rot = 2 ^ math.random(0, 3)
--	self.next_stone = self.STONES[math.random(#self.STONES)]
	self.next_stone = self.STONES[2]
	self.next_color = pickColor()
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
	if self.state == "normal" then

		-- rotation
		local dr = bool[self.input.a] - bool[self.input.b]
		if dr ~= 0 and self.dr_old == 0 then
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
		self.dr_old = dr


		-- horizontal movement
		local dx = bool[self.input.right] - bool[self.input.left]
		if dx == 0 then
			self.dx_tick = 8
		else
			if self.dx_tick <= 0 then
				self.dx_tick = 2
			elseif self.dx_tick < 7 then
				dx = 0
			end
		end
		self.dx_tick = self.dx_tick - 1
		local i = self.x
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
					self.state = "over"
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
				self.state = "delay"
				self.delay = 20

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
						self.complete[y] = true
						self.state = "lineblink"
						self.delay = 20
					end
				end
				return
--[[
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
								self.matrix[i][x] =
									i > 1 and self.matrix[i - 1][x] or false
							end
						end

					end
				end
				self:newStone()
--]]
			end
		end

	elseif self.state == "lineblink" then
		self.delay = self.delay - 1
		if self.delay <= 0 then
			for y, complete in ipairs(self.complete) do
				if complete then
					for x = 1, self.WIDTH do
						self.matrix[y][x] = false
					end
				end
			end
			self.state = "linedrop"
			self.delay = 2
		end

	elseif self.state == "linedrop" then
		self.delay = self.delay - 1
		if self.delay <= 0 then
			self.delay = 2

			local any = false
			for y = self.HEIGHT, 1, -1 do
				if self.complete[y] then
					any = true
					for i = y, 1, -1 do
						for x = 1, self.WIDTH do
							self.matrix[i][x] =
								i > 1 and self.matrix[i - 1][x] or false
						end
						self.complete[i] = self.complete[i - 1] or false
					end
					return
				end
			end
			if not any then
				self.state = "delay"
				self.delay = 20
			end
		end

	elseif self.state == "delay" then
		self.delay = self.delay - 1
		if self.delay <= 0 then
			self:newStone()
			self.state = "normal"
		end
	end



end
function Grid:draw()

	local ox = (self.player_nr - 1) * 12
	local oy = 3
	local BACKGROUND = { 5, 5, 5 }

	for y, row in ipairs(self.matrix) do
		for x, cell in ipairs(row) do
			local color = cell or BACKGROUND
			if	self.state == "normal" and
				x >= self.x and x < self.x + 4 and
				y >= self.y and y < self.y + 4 and
				isBitSet(self.stone[(x - self.x) * 4 + y - self.y + 1], self.rot)
			then
				color = self.color
			end
			if self.state == "lineblink" and self.complete[y] and self.delay % 5 < 2 then
				color = { 255, 255, 255 }
			end


			wall.pixel(x + ox, y + oy, unpack(color)) -- background
		end
	end
end



function wall.load()
	players = { Grid(1), Grid(2) }
	return "seb.exse.net", 1338
end


function wall.tick()
	players[1]:update()
	players[2]:update()

	players[1]:draw()
	players[2]:draw()

end

