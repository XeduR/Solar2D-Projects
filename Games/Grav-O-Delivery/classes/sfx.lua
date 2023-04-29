-------------------------------------------------------------------------
--                                                                     --
--    ooooooo  ooooo                 .o8              ooooooooo.       --
--     `8888    d8'                 "888              `888   `Y88.     --
--       Y888..8P     .ooooo.   .oooo888  oooo  oooo   888   .d88'     --
--        `8888'     d88' `88b d88' `888  `888  `888   888ooo88P'      --
--       .8PY888.    888ooo888 888   888   888   888   888`88b.        --
--      d8'  `888b   888    .o 888   888   888   888   888  `88b.      --
--    o888o  o88888o `Y8bod8P' `Y8bod88P"  `V88V"V8P' o888o  o888o     --
--                                                                     --
--  © 2021-2022 Eetu Rantanen          Last Updated: 23 September 2022 --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------

-- A simple sfx module for Solar2D for quickly and easily loading and
-- handling all audio files via just using the filename (and path).

-- NB! This module overwrites many standard audio API and it handles the
-- API calls via filenames (strings) instead of using standard handles.

-- NB! If you are loading files from multiple directories, ensure that the
-- filepaths are different, even across directories. For example, loading
-- "audio/mySFX.mp3" from the ResourceDirectory reserves that handle, which
-- prevents loading a file with a similar filepath from other directories.

-- NB! If you are having trouble creating the sfxList.lua file, make sure
-- that your project is located in a folder with write access from the OS.

-------------------------------------------------------------------------

local sfx = {}

local lfs = require("lfs")
local lower = string.lower
local gsub = string.gsub
local sub = string.sub
local type = type

-- Localise audio functions.
local _dispose = audio.dispose
local _getDuration = audio.getDuration
local _loadSound = audio.loadSound
local _loadStream = audio.loadStream
local _play = audio.play
local _rewind = audio.rewind
local _seek = audio.seek

local isSimulator = (system.getInfo( "environment" ) == "simulator")

-------------------------------------------------------------------------

local audioHandle = {}
local audioCount = 0
local fileContents = ""

-- List of accepted audio formats.
local audioFormats = {
	[".wav"] = true,
	[".mp3"] = true,
	[".ogg"] = true,
	[".aac"] = true,
	[".caf"] = true,
	[".aif"] = true
}

-------------------------------------------------------------------------

local function loadFile( filePath, directory )
	-- Dynamically load files ending with "isStream" as streams.
	if not audioHandle[filePath] then
		if lower( sub( filePath, -12, -5 ) ) == "isstream" then
			audioHandle[filePath] = _loadStream( filePath, directory )
		else
			audioHandle[filePath] = _loadSound( filePath, directory )
		end
		audioCount = audioCount+1
	end
end

local function traverseFolder( folder, directory, audioFilesFound )
	folder = folder or ""
	local path = system.pathForFile( folder, directory )

	if not path then
		print( "WARNING: folder \"" .. folder .. "\" does not exist in the specified directory." )
	else
		audioFilesFound = audioFilesFound or false

		for file in lfs.dir( path ) do
			if file ~= "." and file ~= ".." then
				local filePath = folder .."/".. file
				if audioFormats[lower(sub(file,-4))] then
					fileContents = fileContents .. "\t\"" .. filePath .. "\",\n"
					loadFile( filePath, directory )
					audioFilesFound = true
				else
					-- Check if it's a subfolder and recursively check it for audio files.
					if lfs.attributes( path .. "/" .. file, "mode" ) == "directory" then
						traverseFolder( filePath, directory, audioFilesFound )
					end
				end
			end
		end

		return audioFilesFound
	end
end

-- Lists all audio handles created by the sfx module.
function audio.listAudioHandles()
	local noHandles = true
	print("\nList of audio handles:\n")
	for i, _ in pairs( audioHandle ) do
		print( "\t[\""..i.."\"]" )
		noHandles = false
	end
	print( noHandles and "\tNo audio handles found.\n" or "" )
end

-- Load a single audio file or all files in a folder and assign them a filePath based handle.
-- If filePath is a folder, then all of its subfolders are also be checked for audio files.
function audio.loadSFX( filePath, directory )
	directory = directory or system.ResourceDirectory
	local isDocumentsDir = directory == system.DocumentsDirectory

	-- Specific file is being loaded.
	if audioFormats[lower(sub(filePath,-4))] then
		loadFile( filePath, directory )

	else -- A folder is being loaded.
		if isSimulator or isDocumentsDir then
			-- On some platforms, like on Android, you can't traverse ResourceDirectory directly. For these
			-- platforms, while on simulator, create separate Lua files with lists of audio files to load.
			fileContents = "local sfx = {\n"
			local audioFilesFound = traverseFolder( filePath, directory )

			-- The contents of DocumentsDirectory may change at any time, for any number of reasons, so lists of its
			-- contents aren't reliable. For ResourceDirectory, however, the contents can only change between builds.
			if audioFilesFound and not isDocumentsDir then
				fileContents = fileContents .. "}\nreturn sfx"

				local path = system.pathForFile( filePath, directory )
				local file, errorString = io.open( path .. "/sfxList.lua", "w" )

				if not file then
					print( "ERROR: File error - " .. errorString )
				else
					file:write( fileContents )
					io.close( file )
				end
			end
			fileContents = ""
		else
			local fileList
			local success, msg = pcall( function() fileList = require( gsub(gsub(filePath .. ".sfxList", "%/", "."), "%\\", ".")) end )

			if not success and msg then
				print( "WARNING: unable to load \"" .. gsub(gsub(filePath .. ".sfxList", "%/", "."), "%\\", ".") .. "\". This likely means you aren't using any audio files in your project." )
			elseif type( fileList ) == "table" then
				for i = 1, #fileList do
					loadFile( fileList[i], directory )
				end
			end
		end
	end
end

-------------------------------------------------------------------------

-- Handle audio function calls that may require a handle by using
-- the filename and path as the handle/key instead of a Lua table.

function audio.play( filename, options )
	if not audioHandle[filename] then
		local directory = system.ResourceDirectory
		local path = system.pathForFile( filename, directory )
		if not path then
			directory = system.DocumentsDirectory
			path = system.pathForFile( filename, directory )
		end
		if path then
			loadFile( filename, directory )
		end
	end
	return _play( audioHandle[filename], options )
end

function audio.loadSound( filename, directory )
	if not audioHandle[filename] then
		audioHandle[filename] = _loadSound( filename, directory )
		audioCount = audioCount+1
	end
end

function audio.loadStream( filename, directory )
	if not audioHandle[filename] then
		audioHandle[filename] = _loadStream( filename, directory )
		audioCount = audioCount+1
	end
end

function audio.rewind( arg )
	arg = type(arg) == "string" and audioHandle[arg] or arg
	return _rewind( arg )
end

function audio.seek( time, arg )
	arg = type(arg) == "string" and audioHandle[arg] or arg
	return _seek( time, arg )
end

function audio.getDuration( filename )
	if audioHandle[filename] then
		return _getDuration( audioHandle[filename] )
	end
end

function audio.dispose( filename )
	if audioHandle[filename] then
		_dispose( audioHandle[filename] )
		audioHandle[filename] = nil
		-- If audio count hits zero, then reset the handle table as well
		-- as the user is likely trying to free up all possible memory.
		audioCount = audioCount-1
		if audioCount == 0 then
			audioHandle = {}
		end
	end
end

function audio.disposeAll()
	for _, handle in pairs( audioHandle ) do
		_dispose( handle )
	end
	audioCount = 0
	audioHandle = {}
end

-------------------------------------------------------------------------

return sfx
