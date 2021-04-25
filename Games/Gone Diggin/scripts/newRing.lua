local M = {}

-- Localised math (and other) functions.
local pi = math.pi
local cos = math.cos
local sin = math.sin
local min = math.min
local deg = math.deg
local rad = math.rad
local random = math.random
local round = math.round

local newRect = display.newRect

local toRGB = 1/255

-- Calculates the coordinates for n points around a radius.
local function getCoordinates( n, r )
	-- Offsetting the starting point by -90 degrees (-pi/2),
	-- in order to place the starting segment to center top.
	local v, a, theta, dtheta = {}, {}, -pi/2, pi*2/n
	
	for i = 1, n*2, 2 do
		v[i] = r * cos(theta)
		v[i+1] = r * sin(theta)
		a[#a+1] = deg(theta)
		theta = theta + dtheta
	end

	return v, a
end

function M.create( params, startingLayer )
	local groupBack = params.groupBack
	local groupFront = params.groupFront
	local radius = params.radius
	local ringCount = params.ringCount
	local thickness = params.thickness
	local surfaceLayers = params.surfaceLayers
	local segmentsPerRing = params.segmentsPerRing
	
	local ring, ringScales = {}, {}
	
	-- Calculate the size of a single segment and extend each vertex by 1 pixel
	-- to each direction in order to prevent visual issues during transitions.
	-- NB! Remember that Solar2D's coordinate system has y-axis flipped.
	local a = rad(360/segmentsPerRing*0.5)
	local innerY = round(-cos(a)*(radius-thickness)+1)
	local outerY = round(-cos(a)*(radius)-1)
	local innerX = round(sin(a)*(radius-thickness))+1
	local outerX = round(sin(a)*(radius))+1
	local width = outerX*2+2
	local height = innerY-outerY+2
	local offsetX2 = outerX-innerX
	local offsetX3 = innerX-outerX
	
	print( width, height )
	
	local xy, angle = getCoordinates( segmentsPerRing, radius-thickness*0.5, true )
	
	for i = 1, ringCount do
		ring[i] = display.newGroup()
		groupFront:insert(ring[i])
		ring[i].back = display.newGroup()
		groupBack:insert(ring[i].back)
		
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
			ring[i].back.xScale, ring[i].back.yScale = scale, scale
			ringScales[i] = scale
		end

		local n = 1
		ring[i].overlay = {} -- All gameplay information is stored in overlay.
		ring[i].backdrop = {}
		for segment = 1, #xy, 2 do
			-- Then create a rectangle based on the bounds, but manipulate the path to
			-- achieve quadrilateral distortion and segments to use to create the ring.
			local t1 = newRect( ring[i], xy[segment], xy[segment+1], width, height )
			t1.rotation = angle[n]+90
			t1.path.x2 = offsetX2
			t1.path.x3 = offsetX3
			ring[i].overlay[n] = t1
			-- Creating two separate tables because Lua copies tables by reference.
			local t2 = newRect( ring[i].back, xy[segment], xy[segment+1], width, height )
			t2.rotation = angle[n]+90
			t2.path.x2 = offsetX2
			t2.path.x3 = offsetX3
			ring[i].backdrop[n] = t2
			n = n+1
		end
		
		
		-- Set the visual style and state for every segment of a ring.
		ring[i].reset = function( self, difficulty )
			-- The way how the difficulty is implemented makes the game unwinnable.
			local cap = 200
			local difficulty = min( difficulty, cap )
			for i = 1, #self.backdrop do
				local t = self.backdrop[i]
				t:setFillColor( 0.5, 0.4, 0.25 )
				t.fill = { 0.5, 0.4, 0.25 }
			end
			for i = 1, #self.overlay do
				local r = random(1,cap)
				local t = self.overlay[i]
				t.isVisible = true
				t.isVisited = false
				t.isGold = false
				
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
			ring[i].back.isVisible = false
			for segment = 1, segmentsPerRing do
				ring[i].overlay[segment].isPassable = true
			end
		elseif i <= startingLayer+surfaceLayers then
			-- All "surface level" segments are guaranteed to be passable.
			for segment = 1, segmentsPerRing do
				ring[i].backdrop[segment]:setFillColor( 0.6, 0.8, 0.2 )
				ring[i].overlay[segment]:setFillColor( 0.6, 0.8, 0.2 )
				-- ring[i].overlay[segment]:setFillColor( random(175,205)*toRGB, random(200,225)*toRGB, random(20,75)*toRGB )
				ring[i].overlay[segment].isPassable = true
			end
		else
			ring[i]:reset( i-startingLayer-surfaceLayers )
		end
	end
	
	return ring, ringScales
end

return M