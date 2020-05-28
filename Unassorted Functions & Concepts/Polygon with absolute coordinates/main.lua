local _unpack = unpack
local _max = math.max
local _min = math.min

-- Find and return the absolute vertices for any given set of vertices.
local function getAbsoluteVertices( t )
	if type(t) == "table" then
		local n, l, x, y = 1, #t, {}, {}

		for i = 1, l, 2 do
			x[n] = t[i]
			y[n] = t[i+1]
			n = n+1
		end

		local xCentre = (_max(_unpack(x))+_min(_unpack(x)))*0.5
		local yCentre = (_max(_unpack(y))+_min(_unpack(y)))*0.5

		local v = {}
		for i = 1, l, 2 do
			v[i] = t[i] - xCentre
			v[i+1] = t[i+1] - yCentre
		end

		return v
	end
end

local vertices = { 0, 0, 40, 0, 40, 40, 0, 40 }
local newVertices = getAbsoluteVertices( vertices )

print( "" )
print( "old vertices:", table.concat( vertices, ", " ) )
print( "new vertices:", table.concat( newVertices, ", " ) )
