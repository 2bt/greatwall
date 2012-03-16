require "helper"
require "greatwall"

s = {
	palette = {
		A = tocolor "aaa",
		X = tocolor "ddd",
		x = tocolor "555",
		F = tocolor "a00",
		f = tocolor "500",
	},
	sprites = {
[[
 A
xXx
 F
]],[[
 A
xXx
 f
]]}
}


Player = Object:new()
Player.sprite = {
	{  0, -1, tocolor "aaa" },
	{  0,  0, tocolor "ddd" },
	{ -1,  0, tocolor "555" },
	{  1,  0, tocolor "555" },
}

function Player:init()
	self.x = 12
	self.y = 20
	self.input = wall.getInput(1)
end
function Player:update()
	self.x = self.x + bool[self.input.right] - bool[self.input.left]
	self.y = self.y + bool[self.input.down] - bool[self.input.up]
end
function Player:draw()
	for _, p in ipairs(self.sprite) do
		wall.pixel(self.x + p[1], self.y + p[2], p[3], p[4], p[5], p[6])
	end
end

function wall.load()
	player = Player()
--	return "seb.exse.net", 1338
end

function wall.tick()
	tick = not tick
	if tick then return end

	wall.clear()

	player:update()
	player:draw()

end


