require "greatwall"

function wall.load()
--	return "seb.exse.net", 1338
	return "172.22.101.124", 1338
end


local sin = math.sin
local cos = math.cos
local time = 0


function dist(ax, ay, bx, by)
	local x = ax - bx
	local y = ay - by
	return (x * x + y * y) ^ 0.5
end

-- change me if you wish
local gradient = {
	{ 255, 255, 0 },
	{ 0, 255, 0 },
	{ 0, 0, 255 },
	{ 255, 0, 0 },
	{ 255, 0, 255 },
}


function color(v)
	-- calculate color of simple linear gradient
	-- assume 0 <= v <= 1

	v = 1 + v * (#gradient - 1)

	local i = math.floor(v)
	local f2 = v - i
	local f1 = 1 - f2

	local c1 = gradient[i]
	local c2 = gradient[i + 1] or c1

	return 	c1[1] * f1 + c2[1] * f2,
			c1[2] * f1 + c2[2] * f2,
			c1[3] * f1 + c2[3] * f2
end

function wall.tick()

	time = time + 0.02

	-- FIXME: half the frame rate for present
	flip = not flip
	if flip then return end


	for y = 1, 24 do
		for x = 1, 24 do

			local value
				= 0
				+ sin(sin(time * 0.3) * 6 + x * 0.4)
				+ sin(cos(time * 0.4) * 6 + y * 0.4)
				+ cos(dist(x - 12.5, y - 12.5,	sin(time * 0.25) * 24,
												cos(time * 0.28) * 20) * 0.4)
				+ cos(dist(x - 12.5, y - 12.5,	cos(time * 0.21) * 20,
												sin(time * 0.22) * 24) * 0.4)

			wall.pixel(x - 1, y - 1, color(value / 8 + 0.5))
		end	
	end
end

