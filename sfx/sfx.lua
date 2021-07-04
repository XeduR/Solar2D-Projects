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
--  © 2021 Eetu Rantanen                     Last Updated: 3 July 2021 --
-------------------------------------------------------------------------
--  License: MIT                                                       --
-------------------------------------------------------------------------

-- A simple sfx module for Solar2D for quickly and easily loading and
-- handling all audio files via just using the filename (and path).

-- NB! This module only handles the audio files/handles, no function
-- calls concerning the audio channels are handled by this module.

-------------------------------------------------------------------------

local sfx = {}

local lfs = require( "lfs" )
local lower = string.lower
local sub = string.sub

-------------------------------------------------------------------------

local handle = {}
local audioCount = 0

-- List of approved audio formats.
local audioFormats = {
    [".wav"] = true,
    [".mp3"] = true,
    [".ogg"] = true,
    [".aac"] = true,
    [".caf"] = true,
    [".aif"] = true
}

-------------------------------------------------------------------------

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
        handle[key] = nil
    end
    audioCount = 0
    handle = {}
end


function sfx.getDuration( filename )
    return audio.getDuration( handle[filename] )
end

-- Lists all audio handles created by the sfx module.
function sfx.listAudioHandles()
    local noHandles = true
    print("\nList of audio handles:\n")
    for i, _ in pairs( handle ) do
        print( "\t[\""..i.."\"]" )
        noHandles = false
    end
    print( noHandles and "\tNo audio handles found." or "")
end

-- Load a single audio file or all files in a folder and assign them a filepath based handle.
-- If filepath is a folder, then all of its subfolders are also be checked for audio files.
function sfx.loadSound( filepath, directory )
    local directory = directory or system.ResourceDirectory

    if audioFormats[lower(sub(filepath,-4))] then
        handle[filepath] = audio.loadSound( filepath, directory )
        audioCount = audioCount+1
    else
        local folder = filepath or ""
        local path = system.pathForFile( folder, directory )
        
        for file in lfs.dir( path ) do
            if file ~= "." and file ~= ".." then
                local filepath = folder .."/".. file
                if audioFormats[lower(sub(file,-4))] then
                    handle[filepath] = audio.loadSound( filepath, directory )
                    audioCount = audioCount+1
                else
                    -- Check if it's a subfolder and recursively check it for audio files.
                    if lfs.attributes( path .. "/" .. file, "mode" ) == "directory" then
                        sfx.loadSound( filepath, directory )
                    end
                end
            end
        end
    end
end

-- Play an audio file using the filename (and path) as the handle/key.
function sfx.play( filename, options )
    return audio.play( handle[filename], options )
end


function sfx.rewind( arg )
    local arg = type(arg) == "string" and handle[arg] or arg
    return audio.rewind( arg )
end


function sfx.seek( time, arg )
    local arg = type(arg) == "string" and handle[arg] or arg
    return audio.seek( time, arg )
end

-------------------------------------------------------------------------

return sfx