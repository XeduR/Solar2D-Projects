---------------------------------------------------------------------------
--     _____                  _         ______                           --
--    / ___/____  __  _______(_)____   / ____/___ _____ ___  ___  _____  --
--    \__ \/ __ \/ / / / ___/ / ___/  / / __/ __ `/ __ `__ \/ _ \/ ___/  --
--   ___/ / /_/ / /_/ / /  / / /__   / /_/ / /_/ / / / / / /  __(__  )   --
--  /____/ .___/\__, /_/  /_/\___/   \____/\__,_/_/ /_/ /_/\___/____/    --
--      /_/    /____/                                                    --
--                                                                       --
--  © 2021 Spyric Games Ltd.                  Last Updated: 1 June 2021  --
---------------------------------------------------------------------------
--  License: MIT                                                         --
---------------------------------------------------------------------------

--[[
    IMPORTANT:
    
    Spyric Loadsave is a quick and simple Solar2D plugin for saving & loading
    data to & from external files. The data is encoded using base64 and it is
    protected by SHA-256 hash and a single feint character. The only function
    of this feint character is to block a naïve base64 decode attempt. This
    plugin also has a backup feature that will attempt to restore save data in
    the event that the main save file has been removed, corrupted or tampered with.
    
    Whenever a competent "attacker" has physical access to your save data and
    game files, i.e. any and all games/apps where data is stored locally on a
    user's device, the attacker will be able to read and manipulate said data.
    This also applies to secure encryption methods like the AES-256.
    
    The SHA-256 hash function will protect your save data from tampering to a
    point where, even if the attacker can read the save data, they can't edit
    it without reverse engineering your game/app, making changes to the source
    code, or otherwise creating modifications to your game/app which bypass the
    SHA-256 hash function, but at this point there are no local measures which
    would protect your game/app/data from tampering.
    
    The main purpose of this module is to be a fast and easy way to obfuscate
    save files while also providing reasonable protection against data tampering
    and a basic save data backup feature against possible file errors/problems.
]]

---------------------------------------------------------------------------

local loadsave = {}

-- Optional: set to false to stop the plugin from reporting on errors.
loadsave.reportErrors = true

-- hash consists of [1]: pepper, [2]: the data being saved or loaded, and [3]: salt.
local hash = {"a4f4bf1c15c61507254b2db0077120d8981d0e39ac03ec6dfcbd86caba5a7d16", "", ""}

local json = require("json")
local jsonEncode = json.encode
local jsonDecode = json.decode

local crypto = require("crypto")
local digest = crypto.digest
local sha256 = crypto.sha256

local mime = require("mime")
local unb64 = mime.unb64
local b64 = mime.b64

local pathForFile = system.pathForFile
local concat = table.concat
local random = math.random
local char = string.char
local sub = string.sub
local close = io.close
local open = io.open
local type = type

---------------------------------------------------------------------------

function loadsave.setPepper( s )
    if type(s) ~= "string" then
        if loadsave.reportErrors then
            print( "WARNING: bad argument #1 to 'setPepper' (string expected, got " .. type(s) .. ")." )
        end
        return
    end
    hash[1] = digest(sha256, s)
end

---------------------------------------------------------------------------

local function writeToFile( filename, savedata, directory )
    local path = pathForFile(filename, directory)
    local file, errorString = open(path, "w")
    
    if not file then
        if loadsave.reportErrors then
            print( "WARNING: File error - " .. errorString )
        end
        return false
    end
    file:write(savedata)
    close(file)
    
    return true
end

-- Encode a string or a table, secure it with a hash, and save the encoded output to a file.
function loadsave.save( data, filename, salt, directory )
    local typeData = type(data)
    if typeData ~= "table" and typeData ~= "string" then
        if loadsave.reportErrors then
            print( "WARNING: bad argument #1 to 'save' (table or string expected, got " .. typeData .. ")." )
        end
        return false
    end
    if type(filename) ~= "string" then
        if loadsave.reportErrors then
            print( "WARNING: bad argument #2 to 'save' (string expected, got " .. type(filename) .. ")." )
        end
        return false
    end
    if type(salt) ~= "string" then
        if loadsave.reportErrors then
            print( "WARNING: bad argument #3 to 'save' (string expected, got " .. type(salt) .. ")." )
        end
        return false
    end
    
    -- Set the components of the hash.
    local contents = typeData == "table" and jsonEncode(data) or data
    hash[2] = contents
    hash[3] = salt
    
    -- Create the hash, the feint and base64 encode the save data.
    local t = {true, true, true}
    t[1] = digest(sha256, concat(hash))
    t[2] = char(random(97,122)) -- This'll stop a naïve base64 decode attempt.
    t[3] = b64(contents)
    
    if not t[3] then
        if loadsave.reportErrors then
            print( "WARNING: Write error - argument #1 to 'save' is an empty string." )
        end
        return false
    end
    
    -- Write the save data to the main and backup save files.
    local directory = directory or system.DocumentsDirectory
    local savedata = concat(t)
    local didSave = writeToFile( filename, savedata, directory )
    local didSaveBackup = writeToFile( "backup_"..filename, savedata, directory )
    
    return didSave or didSaveBackup or false
end

---------------------------------------------------------------------------

local function readFromFile( filename, directory )
    local path = pathForFile(filename, directory)
    local file, errorString = open(path, "r")
    
    if not file then
        if loadsave.reportErrors then
            print( "WARNING: File error - " .. errorString )
        end
    else
        local contents = file:read("*a")
        close(file)
        -- Ignore the feint, and retrieve the hash and the encoded data from the file.
        local fileHash = sub(contents, 1, 64)
        local data = unb64(sub(contents, 66))
        hash[2] = data
        -- Check for file tampering and then return the data in its original form.
        if data and digest(sha256, concat(hash)) == fileHash then
            local output = jsonDecode(data)
            if not output then
                output = data
            end
            -- Return the encoded contents in order to retrieve
            -- possible lost/corrupted/tampered data via backup.
            return output, contents
        end
    end
    return false
end

-- Load an encoded file, check for file tampering, and return the decoded string or table.
function loadsave.load( filename, salt, directory )
    if type(filename) ~= "string" then
        if loadsave.reportErrors then
            print( "WARNING: bad argument #1 to 'save' (string expected, got " .. type(filename) .. ")." )
        end
        return false
    end
    if type(salt) ~= "string" then
        if loadsave.reportErrors then
            print( "WARNING: bad argument #2 to 'save' (string expected, got " .. type(salt) .. ")." )
        end
        return false
    end
    hash[3] = salt
    
    local directory = directory or system.DocumentsDirectory
    local data = readFromFile( filename, directory )
    if not data then
        -- Main save file has been removed, corrupted or tampered with, so try loading
        -- from the backup instead and use it to restore the main save file's contents.
        local backupData, backupEncoded = readFromFile( "backup_"..filename, directory )
        if backupData then
            writeToFile( filename, backupEncoded, directory )
        end
        return backupData
    end
    return data
end

---------------------------------------------------------------------------

return loadsave