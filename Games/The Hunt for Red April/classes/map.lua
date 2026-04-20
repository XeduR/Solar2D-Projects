local map = {}

local json = require( "json" )

--------------------------------------------------------------------------------------
-- Public functions

function map.pointInPolygon( px, py, vertices )
	local n = #vertices
	local inside = false
	local j = n
	for i = 1, n do
		local xi, yi = vertices[i].x, vertices[i].y
		local xj, yj = vertices[j].x, vertices[j].y
		if ( yi > py ) ~= ( yj > py ) and px < ( xj - xi ) * ( py - yi ) / ( yj - yi ) + xi then
			inside = not inside
		end
		j = i
	end
	return inside
end

function map.load( filename )
	local path = system.pathForFile( filename, system.ResourceDirectory )
	local file = io.open( path, "r" )
	local content = file:read( "*a" )
	file:close()

	local data = json.decode( content )

	local result = {
		worldWidth = data.width * data.tilewidth,
		worldHeight = data.height * data.tileheight,
		terrain = {},
		carrierRoutes = {},
		spawnPoints = {},
		shipSpawnPoints = {},
	}

	for i = 1, #data.layers do
		local layer = data.layers[i]

		if layer.name == "terrain" and layer.type == "objectgroup" then
			for j = 1, #layer.objects do
				local obj = layer.objects[j]
				if obj.polygon then
					local vertices = {}
					local minX, minY, maxX, maxY

					for k = 1, #obj.polygon do
						local vx = obj.x + obj.polygon[k].x
						local vy = obj.y + obj.polygon[k].y
						vertices[k] = { x = vx, y = vy }

						if k == 1 then
							minX, minY, maxX, maxY = vx, vy, vx, vy
						else
							if vx < minX then minX = vx end
							if vy < minY then minY = vy end
							if vx > maxX then maxX = vx end
							if vy > maxY then maxY = vy end
						end
					end

					-- Bounding box center for display.newPolygon positioning.
					local cx = ( minX + maxX ) * 0.5
					local cy = ( minY + maxY ) * 0.5

					-- Flat vertex array centered on bounding box center (for display.newPolygon).
					local flatVertices = {}
					for k = 1, #vertices do
						flatVertices[#flatVertices + 1] = vertices[k].x - cx
						flatVertices[#flatVertices + 1] = vertices[k].y - cy
					end

					result.terrain[#result.terrain + 1] = {
						vertices = vertices,
						centerX = cx,
						centerY = cy,
						flatVertices = flatVertices,
						width = maxX - minX,
						height = maxY - minY,
					}
				end
			end

		elseif layer.name == "carrier_route" and layer.type == "objectgroup" then
			for j = 1, #layer.objects do
				local obj = layer.objects[j]
				if obj.polygon then
					local waypoints = {}
					for k = 1, #obj.polygon do
						waypoints[k] = {
							x = obj.x + obj.polygon[k].x,
							y = obj.y + obj.polygon[k].y,
						}
					end
					result.carrierRoutes[#result.carrierRoutes + 1] = waypoints
				end
			end

		elseif layer.name == "spawn_ship" and layer.type == "objectgroup" then
			for j = 1, #layer.objects do
				local obj = layer.objects[j]
				if obj.point then
					result.shipSpawnPoints[#result.shipSpawnPoints + 1] = {
						x = obj.x,
						y = obj.y,
					}
				end
			end

		elseif layer.name == "spawn_player" and layer.type == "objectgroup" then
			for j = 1, #layer.objects do
				local obj = layer.objects[j]
				if obj.point then
					result.spawnPoints[#result.spawnPoints + 1] = {
						x = obj.x,
						y = obj.y,
					}
				end
			end
		end
	end

	-- Level's outer boundaries (just stops player movement).
	local ww = result.worldWidth
	local wh = result.worldHeight
	result.walls = {
		{ type = "levelBounds", x = ww * 0.5, y = 5, width = ww, height = 10 },
		{ type = "levelBounds", x = ww * 0.5, y = wh - 5, width = ww, height = 10 },
		{ type = "levelBounds", x = 5, y = wh * 0.5, width = 10, height = wh },
		{ type = "levelBounds", x = ww - 5, y = wh * 0.5, width = 10, height = wh },
	}

	-- Patrol waypoints (coverage pattern based on world dimensions).
	result.patrolWaypoints = {
		{ x = ww * 0.2, y = wh * 0.2 },
		{ x = ww * 0.5, y = wh * 0.15 },
		{ x = ww * 0.8, y = wh * 0.2 },
		{ x = ww * 0.85, y = wh * 0.5 },
		{ x = ww * 0.8, y = wh * 0.8 },
		{ x = ww * 0.5, y = wh * 0.85 },
		{ x = ww * 0.2, y = wh * 0.8 },
		{ x = ww * 0.15, y = wh * 0.5 },
	}

	return result
end

return map
