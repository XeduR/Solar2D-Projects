-- Persistent scores and volumes through loadsave.

local save = {}

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local loadsave = require( "classes.loadsave" )
local saveConfig = require( "data.save" )

--------------------------------------------------------------------------------------
-- Public functions

function save.load()
	local stored = loadsave.load( saveConfig.filename )
	local data = { scores = {}, volume = {} }

	if type( stored ) == "table" then
		local storedScores = stored.scores

		if type( storedScores ) == "table" then
			for i = 1, #storedScores do
				if type( storedScores[i] ) == "number" then
					data.scores[#data.scores + 1] = storedScores[i]
				end
			end
		end

		if type( stored.volume ) == "table" then
			for key in pairs( saveConfig.defaultVolume ) do
				data.volume[key] = stored.volume[key]
			end
		end
	end

	for key, value in pairs( saveConfig.defaultVolume ) do
		if type( data.volume[key] ) ~= "number" then
			data.volume[key] = value
		end
	end

	return data
end

function save.write( data )
	return loadsave.save( data, saveConfig.filename )
end

return save
