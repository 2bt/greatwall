require "greatwall"

function wall.load()
	return "bender", 1350
end


local graphics = love.graphics
local sin = math.sin
local cos = math.cos
local time = 0

local function get(b, x, y)
	if x < 1 or x > 24 or y < 1 or y > 24 then
		return 0
	end
	return b[y * 24 + x] or 0
end

local function set(b, x, y, v)
	b[y * 24 + x] = v
end

local buffer1 = { set = set, get = get }
local buffer2 = { set = set, get = get }


function wall.tick()

	flip = not flip
	if flip then return end


	if math.random(50) == 1 then
		buffer1:set(math.random(24), math.random(24),
			math.random(256) - 128)
	end

	buffer1, buffer2 = buffer2, buffer1

	for y = 1, 24 do
		for x = 1, 24 do

			local v = 	buffer1:get(x - 1, y) +
						buffer1:get(x + 1, y) +
						buffer1:get(x, y + 1) +
						buffer1:get(x, y - 1)

			v = math.floor(v / 2) - buffer2:get(x, y)

			buffer2:set(x, y, v * 0.9)

		end
	end


	for y = 1, 24 do
		for x = 1, 24 do

			local dx = buffer1:get(x, y) - buffer1:get(x + 1, y)
			local dy = buffer1:get(x, y) - buffer1:get(x, y + 1)

			local u = x + dx * 0.5 - 0.5
			local v = y + dy * 0.5 - 0.5

			local c = (math.floor(u / 6) + math.floor(v / 6)) % 2 == 0
						and 100 or 140

			c = c + dx * 2

			wall.pixel(x - 1, y - 1, c, c, c)

		end
	end
end

