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
--  © 2021 Eetu Rantanen                 Last Updated: 22 October 2021 --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------

-- A simple sfx module for Solar2D for quickly and easily loading and
-- handling all audio files via just using the filename (and path).

-- NB! To ensure that Solar2D correctly loads your audio files, the
-- filenames should NOT contain any special UTF-8 (or such) characters.

-------------------------------------------------------------------------

local sfx = {}

local lfs = require("lfs")
local lower = string.lower
local gsub = string.gsub
local sub = string.sub
local type = type

local isSimulator = (system.getInfo( "environment" ) == "simulator")

-------------------------------------------------------------------------

local audioFiles = {}

local handle = {}
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

-- Search a folder and all of its subfolders for audio files (on Simulator)
-- and generate a list of them 
local function traverseFolder( folder, directory, audioFilesFound )
    local folder = folder or ""
    local path = system.pathForFile( folder, directory )

    if not path then
        print( "WARNING: folder \"" .. folder .. "\" does not exist in the specified directory." )
    else
        local audioFilesFound = audioFilesFound or false

        for file in lfs.dir( path ) do
            if file ~= "." and file ~= ".." then
                local filePath = folder .."/".. file
                if audioFormats[lower(sub(file,-4))] then
                    fileContents = fileContents .. "\t\"" .. filePath .. "\",\n"
                    handle[filePath] = audio.loadSound( filePath, directory )
                    audioCount = audioCount+1
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
function sfx.listAudioHandles()
    local noHandles = true
    print("\nList of audio handles:\n")
    for i, _ in pairs( handle ) do
        print( "\t[\""..i.."\"]" )
        noHandles = false
    end
    print( noHandles and "\tNo audio handles found.\n" or "" )
end

-- Load a single audio file or all files in a folder and assign them a filePath based handle.
-- If filePath is a folder, then all of its subfolders are also be checked for audio files.
function sfx.loadSound( filePath, directory )
    -- NB! Use DocumentsDirectory with caution. On certain platforms, you may encounter
    -- issues when requiring Lua files from DocumentsDirectory. This module is primarily
    -- intended to be used with prepackaged audio files and to make handling them easier.
    local directory = directory or system.ResourceDirectory

    -- Specific file is being loaded.
    if audioFormats[lower(sub(filePath,-4))] then
        handle[filePath] = audio.loadSound( filePath, directory )
        audioCount = audioCount+1
        
    else -- A folder is being loaded.
        if isSimulator then
            -- On some platforms, like on Android, you can't traverse ResourceDirectory directly. For these
            -- platforms, while on simulator, create separate Lua files with lists of audio files to load.
            fileContents = "local sfx = {\n"
            local audioFilesFound = traverseFolder( filePath, directory )
        
            -- If the folder contains audio files, then create an sfxList.lua file with a list of them in the folder.
            if audioFilesFound then
                fileContents = fileContents .. "}\nreturn sfx"
        
                filePath = filePath .. "/sfxList.lua"
                local file, errorString = io.open( filePath, "w" )
        
                if not file then
                    print( "ERROR: File error - " .. errorString )
                    print( "Try again, or try manually creating the file \"" .. filePath .. "\". The file contents can be empty. Depending on the project location, the OS may be preventing Solar2D from creating new files in the project directory." )
                else
                    file:write( fileContents )
                    io.close( file )
                end
                fileContents = ""
            end
        else
            -- Attempt to load the sfxList.lua file from the specified folder and assign the audio handles and load the sounds.
            local fileList
			local success, msg = pcall( function() fileList = require( gsub(gsub(filePath .. ".sfxList", "%/", "."), "%\\", ".")) end )
            
            if not success and msg then
				error( "ERROR:", msg )
            elseif type( fileList ) == "table" then
                for i = 1, #fileList do
                    local file = fileList[i]
                    handle[file] = audio.loadSound( file, directory )
                    audioCount = audioCount+1
                end
			end
        end
    end
end

-------------------------------------------------------------------------

-- Handle audio function calls that may require a handle by using 
-- the filename and path as the handle/key instead of a Lua table.

function sfx.play( filename, options )
    return audio.play( handle[filename], options )
end

function sfx.rewind( arg )
    -- Argument can be string (audio handle) or table (channel).
    local arg = type(arg) == "string" and handle[arg] or arg
    return audio.rewind( arg )
end

function sfx.seek( time, arg )
    -- Argument can be string (audio handle) or table (channel).
    local arg = type(arg) == "string" and handle[arg] or arg
    return audio.seek( time, arg )
end

function sfx.getDuration( filename )
    return audio.getDuration( handle[filename] )
end

function sfx.dispose( filename )
    if handle[filename] then
        audio.dispose( handle[filename] )
        handle[filename] = nil
        -- If audio count hits zero, then reset the handle table as well,
        -- since the user is likely trying to free up all possible memory.
        audioCount = audioCount-1
        if audioCount == 0 then
            handle = {}
        end
    end
end

function sfx.disposeAll()
    for key, audioHandle in pairs( handle ) do
        audio.dispose( audioHandle )
    end
    audioCount = 0
    handle = {}
end

-------------------------------------------------------------------------

return sfx
