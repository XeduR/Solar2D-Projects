local M = {}

-- Localised math (and other) functions.
local pi = math.pi
local cos = math.cos
local sin = math.sin
local min = math.min
local max = math.max
local deg = math.deg
local atan2 = math.atan2
local random = math.random
local unpack = unpack
local newPolygon = display.newPolygon

local toRGB = 1/255

-- Calculates the coordinates for n points around a radius.
local function getCoordinates( n, r )
	local v, theta, dtheta = {}, 0, pi*2/n

	for i = 1, n*2, 2 do
		v[i] = r * cos(theta)
		v[i+1] = r * sin(theta)
		theta = theta + dtheta
	end

	return v
end

function M.create( params, startingLayer )
	local parent = params.parent
	local radius = params.radius
	local ringCount = params.ringCount
	local thickness = params.thickness
	local surfaceLayers = params.surfaceLayers
	local segmentsPerRing = params.segmentsPerRing
	local debugInfo = params.debugInfo
	
	local ring, ringScales = {}, {}
	local debugNum = 1
	
	for i = 1, ringCount do
		ring[i] = display.newGroup()
		parent:insert(ring[i])
		-- "difficulty" determines how likely impassable tiles are on the ring segments.
		ring[i].difficulty = i
		-- "layer" property specifies the current position of the layer in the world.
		ring[i].layer = i
		
		ringScales[i] = 1
		if i > 1 then
			local scalingFactor = -1
			for x = 1, i do
				scalingFactor = scalingFactor + ring[x].xScale
			end			
			local scale = (radius-thickness*scalingFactor)/radius
			ring[i].xScale, ring[i].yScale = scale, scale
			ringScales[i] = scale
		end

		local side, xy = {}, {}
		local outer = getCoordinates( segmentsPerRing, radius )
	    local inner = getCoordinates( segmentsPerRing, radius-thickness )
	    for i = 1, segmentsPerRing do
	        side[i] = { inner[i*2-1], inner[i*2], inner[i*2+1] or inner[1], inner[i*2+2] or inner[2], outer[i*2+1] or outer[1], outer[i*2+2] or outer[2], outer[i*2-1], outer[i*2] }
	        xy[i] = {
	            (min(inner[i*2-1], inner[i*2+1] or inner[1], outer[i*2+1] or outer[1], outer[i*2-1]) + max(inner[i*2-1], inner[i*2+1] or inner[1], outer[i*2+1] or outer[1], outer[i*2-1]))*0.5,
	            (min(inner[i*2], inner[i*2+2] or inner[2], outer[i*2+2] or outer[2], outer[i*2]) + max(inner[i*2], inner[i*2+2] or inner[2], outer[i*2+2] or outer[2], outer[i*2]))*0.5
	        }
	    end
		
		ring[i].segment = {}
		for segment = 1, segmentsPerRing do
			ring[i].segment[segment] = newPolygon( ring[i], xy[segment][1], xy[segment][2], { unpack( side[segment] ) } )
		end
		
		-- Set the visual style and state for every segment of the ring.
		ring[i].reset = function( self, difficulty )
			self.difficulty = difficulty
			-- The way how the difficulty is implemented makes the game unwinnable.
			local cap = 200
			local difficulty = min( self.difficulty, cap )
			for i = 1, #self.segment do
				local r = random(1,cap)
				local t = self.segment[i]
				t.isGold = false
				
				-- Hardcoded probability of impassable segment.
				if r < difficulty then
					t:setFillColor( 0.1, 0.15, 0.25 )
					-- t:setFillColor( random(30,45)*toRGB, random(40,55)*toRGB, random(50,75)*toRGB )
					t.isPassable = false
				else
					-- Hardcoded probability of gold segment.
					if random() < 0.15 then
						t:setFillColor( 1, 1, 0 )
						t.isPassable = true
						t.isGold = true
					else
						t:setFillColor( 0.5, 0.4, 0.25 )
						-- t:setFillColor( random(100,160)*toRGB, random(70,120)*toRGB, random(55,75)*toRGB )
						t.isPassable = true
					end
				end
			end
		end
		
		-- Make rings before the starting layer invisible and passable.
		if i <= startingLayer then
	        ring[i].isVisible = false
			for segment = 1, segmentsPerRing do
				ring[i].segment[segment].isPassable = true
			end
		elseif i <= startingLayer+surfaceLayers then
			-- All "surface level" segments are guaranteed to be passable.
			for segment = 1, segmentsPerRing do
				ring[i].segment[segment]:setFillColor( 0.6, 0.8, 0.2 )
				-- ring[i].segment[segment]:setFillColor( random(175,205)*toRGB, random(200,225)*toRGB, random(20,75)*toRGB )
				ring[i].segment[segment].isPassable = true
			end
		else
			ring[i]:reset( i-startingLayer-surfaceLayers )
		end
	end
	
	return ring, ringScales
end

return M