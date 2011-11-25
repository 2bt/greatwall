--require "bit"
require "socket"
require "helper"

-- helper function
function tocolor(s)
	local o = {}
	if #s == 3 or #s == 4 then
		for x in s:gmatch(".") do
			o[#o + 1] = tonumber("0x" .. x .. x)
		end
	elseif #s == 6 or #s == 8 then
		for x in s:gmatch("..") do
			o[#o + 1] = tonumber("0x" .. x)
		end
	end
	return unpack(o)
end

-- input bit mask
local input_masks = {
	up = 1,
	down = 2,
	left = 4,
	right = 8,
	select = 16,
	start = 32,
	a = 64,
	b = 128,
}

local local_keys = {
	{
		up = "up",
		down = "down",
		left = "left",
		right = "right",
		select = "rshift",
		start = "return",
		a = "o",
		b = "p",
	}, {
		up = "w",
		down = "s",
		left = "a",
		right = "d",
		select = "lshift",
		start = "lctrl",
		a = "1",
		b = "2",
	}
}

Wall = Object:new {
	WIDTH = 24,
	HEIGHT = 24
}

function Wall:init(host, port, priority, remote_pads)

	-- pimp love
	love.graphics.setMode(self.WIDTH * 20, self.HEIGHT * 20)
	love.keypressed = function(key) self:keypressed(key) end

	self.buffer = {}
	for i = 1, self.HEIGHT * self.WIDTH do
		self.buffer[i] = { 0, 0, 0 }
	end

	-- button set-up
	self.input = { {}, {} }
	for _, player in ipairs(self.input) do
		for button in pairs(input_masks) do
			player[button] = false
		end
	end

	if host then
		priority = priority or 3

		self.msg = ""
		self.socket = socket.tcp()
		self.socket:connect(host, port)
		self:priority(priority)

		self.remote_pads = remote_pads
		-- subscribe input
		if remote_pads then
			self.socket:send("0901\r\n")
		end
	end
end

function Wall:keypressed(key)
	if key == "escape" then
		love.event.push("q")
	elseif key == "f" then
		love.graphics.toggleFullscreen()
	elseif key == "f1" then
		self:record(true)
		print("recording...")
	elseif key == "f2" then
		self:record(false)
		print("recording stopped")
	end
end


function Wall:clear(r, g, b)
	r = r or 0
	g = g or 0
	b = b or 0

	for i = 1, self.HEIGHT * self.WIDTH do
		self.buffer[i][1] = r
		self.buffer[i][2] = g
		self.buffer[i][3] = b
	end
end


function Wall:priority(priority)
	if self.socket then
		self.socket:send("04%02X\r\n" % priority)
	end
end

function Wall:record(flag)
	if self.socket then
		local opcode = flag and "05" or "06"
		self.socket:send(opcode .. "\r\n")
	end
end

function Wall:pixel(x, y, r, g, b, a)
	if 0 <= x and x < self.WIDTH and 0 <= y and y < self.HEIGHT then
		local i = y * self.WIDTH + x + 1

		local n = (a or 255) / 255
		local m = 1 - n

		self.buffer[i][1] = self.buffer[i][1] * m + r * n
		self.buffer[i][2] = self.buffer[i][2] * m + g * n
		self.buffer[i][3] = self.buffer[i][3] * m + b * n
	end
end


function Wall:update_input()

	if self.remote_pads then
		while true do
			local t = socket.select({ self.socket }, nil, 0)[1]
			if not t then
				break
			end
			
			local msg = self.socket:receive()
			local nr, bits
			if msg then
				nr, bits = msg:match "09(..)(..).."
			end

			if nr then
				-- convert from hex
				nr = tonumber("0x" .. nr)
				bits = tonumber("0x" .. bits)

				if nr >= 1 and nr <= 2 then
					local player = self.input[nr]
					for button, mask in pairs(input_masks) do
						--player[button] = bit.band(mask, bits) > 0
						-- TODO: test this code
						-- then, remove bit dependency
						player[button] = bits / mask % 2 >= 1
					end
				end
			end

		end
	else

		for nr, keys in ipairs(local_keys) do
			local player = self.input[nr]
			for button, key in pairs(keys) do
				player[button] = love.keyboard.isDown(key)
			end
		end

	end

end

function Wall:draw()
	local w = love.graphics.getWidth() / self.WIDTH
	local h = love.graphics.getHeight() / self.HEIGHT

	local trans = {}
	for i, color in ipairs(self.buffer) do
		trans[#trans + 1] = ("%02x%02x%02x"):format(color[1], color[2], color[3])
		local x = ((i - 1) % self.WIDTH) * w
		local y = math.floor((i - 1) / self.WIDTH) * h
		love.graphics.setColor(color[1], color[2], color[3])
		love.graphics.rectangle("fill", x, y, w, h)
	end

	if self.socket then
		local msg = table.concat(trans)
		if msg ~= self.msg then
			self.msg = msg
			self.socket:send("03%s\r\n" % msg)
		end
	end
end


