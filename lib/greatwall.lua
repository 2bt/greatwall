require "socket"

wall = {}

local buffer = {}
local input = { {}, {} }
local height = 24
local width = 24

local host
local port
local priority
local pads

local sock = false
local ascii_buffer

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


function wall.getWidth() return width end
function wall.getHeight() return height end
function wall.getInput(nr) return input[nr] end

function love.load()
	if wall.load then
		 host, port, priority, pads = wall.load()
	end

	love.graphics.setMode(width * 20, height * 20)

	buffer = {}
	for i = 1, height * width do
		buffer[i] = { 0, 0, 0 }
	end

	-- button set-up
	for _, player in ipairs(input) do
		for button in pairs(input_masks) do
			player[button] = false
		end
	end

	if host then
		priority = priority or 3
		ascii_buffer = ""
		sock = socket.tcp()
		sock:connect(host, port)
		wall.setPriority(priority)

		if pads then
			sock:send("0901\r\n")
		end
	end
end

function love.keypressed(key)
	if key == "escape" then
		love.event.push("q")
	elseif key == "f" then
		love.graphics.toggleFullscreen()
	elseif key == "f1" then
		wall.record(true)
		print("recording...")
	elseif key == "f2" then
		wall.record(false)
		print("recording stopped")
	end
end


function wall.clear(r, g, b)
	r = r or 0
	g = g or 0
	b = b or 0

	for i = 1, height * width do
		buffer[i][1] = r
		buffer[i][2] = g
		buffer[i][3] = b
	end
end


function wall.setPriority(priority)
	if sock then
		sock:send(("04%02X\r\n"):format(priority))
	end
end

function wall.record(flag)
	if sock then
		local opcode = flag and "05" or "06"
		sock:send(opcode .. "\r\n")
	end
end

function wall.pixel(x, y, r, g, b, a)
	if 0 <= x and x < width and 0 <= y and y < height then

		local i = y * width + x + 1
		local n = (a or 255) / 255
		local m = 1 - n

		buffer[i][1] = buffer[i][1] * m + r * n
		buffer[i][2] = buffer[i][2] * m + g * n
		buffer[i][3] = buffer[i][3] * m + b * n
	end
end



local delta_time
function love.update(dt)
	delta_time = dt

	if pads then
		while true do
			local t = socket.select({ sock }, nil, 0)[1]
			if not t then
				break
			end
			
			local msg = sock:receive()
			local nr, bits
			if msg then
				nr, bits = msg:match "09(..)(..).."
			end

			if nr then
				-- convert from hex
				nr = tonumber("0x" .. nr)
				bits = tonumber("0x" .. bits)

				if nr >= 1 and nr <= 2 then
					local player = input[nr]
					for button, mask in pairs(input_masks) do
						player[button] = bits / mask % 2 >= 1
					end
				end
			end

		end
	else
		for nr, keys in ipairs(local_keys) do
			local player = input[nr]
			for button, key in pairs(keys) do
				player[button] = love.keyboard.isDown(key)
			end
		end

	end

end

function love.draw()
	if wall.tick then wall.tick(delta_time) end

	local w = love.graphics.getWidth() / width
	local h = love.graphics.getHeight() / height

	local trans = {}
	for i, color in ipairs(buffer) do
		trans[#trans + 1] = ("%02x%02x%02x"):format(color[1], color[2], color[3])
		local x = ((i - 1) % width) * w
		local y = math.floor((i - 1) / width) * h
		love.graphics.setColor(color[1], color[2], color[3])
		love.graphics.rectangle("fill", x, y, w, h)
	end

	if sock then
		local msg = table.concat(trans)
		if msg ~= ascii_buffer then
			ascii_buffer = msg
			sock:send("03" .. msg .. "\r\n")
		end
	end
end

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


