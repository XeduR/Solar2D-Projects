---------------------------------------------------------------------------
--     _____                  _         ______                           --
--    / ___/____  __  _______(_)____   / ____/___ _____ ___  ___  _____  --
--    \__ \/ __ \/ / / / ___/ / ___/  / / __/ __ `/ __ `__ \/ _ \/ ___/  --
--   ___/ / /_/ / /_/ / /  / / /__   / /_/ / /_/ / / / / / /  __(__  )   --
--  /____/ .___/\__, /_/  /_/\___/   \____/\__,_/_/ /_/ /_/\___/____/    --
--      /_/    /____/                                                    --
--                                                                       --
--  © 2021-2022 Spyric Games Ltd.            Last Updated: 29 July 2022  --
---------------------------------------------------------------------------
--  License: MIT                                                         --
---------------------------------------------------------------------------

--[[
	IMPORTANT:

	Spyric Loadsave is a quick and easy to use Solar2D plugin for saving and
	loading data to & from external files across all supported platforms.

	The data is encoded using base64 and it is protected by SHA-256 hash and
	a single feint character. The only function of this feint character is to
	block a naïve base64 decode attempt. This plugin also has a backup feature
	that will attempt to restore save data in the event that the main save file
	has been removed, corrupted or tampered with.

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

-- hash consists of [1]: pepper, [2]: the data being saved or loaded, and [3]: salt.
local hash = {"a4f4bf1c15c61507254b2db0077120d8981d0e39ac03ec6dfcbd86caba5a7d16", "", ""}
local isDataProtected = true
local isDebugMode = false

local json = require("json")
local jsonEncode = json.encode
local jsonDecode = json.decode

-- Localise global functions.
local _pathForFile = system.pathForFile
local _concat = table.concat
local _random = math.random
local _char = string.char
local _sub = string.sub
local _close = io.close
local _open = io.open
local _type = type

-- Forward declare key functions.
local sha256
local unb64
local b64

---------------------------------------------------------------------------

-- Solar2D doesn't include mime (Base64) and crypto (SHA-256) libraries for the browser
-- environment (HTML5 platform), so, to keep things simple, they are handled in pure Lua.
if system.getInfo( "environment" ) == "browser" then
	local setmetatable = setmetatable
	local _floor = math.floor
	local _format = string.format
	local _find = string.find
	local _gsub = string.gsub
	local _byte = string.byte
	local _rep = string.rep
	local _assert = assert

	-- Base64 encode/decode:
	---------------------------------------------------------------------------
	-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
	-- licensed under the terms of the LGPL2
	-- Source: http://lua-users.org/wiki/BaseSixtyFour

	-- NB! The code has been slightly adjusted for improved performance.

	-- Character table string.
	local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

	function b64(data)
		return (_gsub((_gsub( data, '.', function(x)
			local r,b='',_byte(x)
			for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
			return r;
		end)..'0000'), '%d%d%d?%d?%d?%d?', function(x)
			if (#x < 6) then return '' end
			local c=0
			for i=1,6 do c=c+(_sub(x,i,i)=='1' and 2^(6-i) or 0) end
			return _sub(b,c+1,c+1)
		end)..({ '', '==', '=' })[#data%3+1])
	end

	function unb64(data)
		data = _gsub(data, '[^'..b..'=]', '')
		return (_gsub(_gsub( data, '.', function(x)
			if (x == '=') then return '' end
			local r, f='', (_find(b,x)-1)
			for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
			return r
		end), '%d%d%d?%d?%d?%d?%d?%d?', function(x)
			if (#x ~= 8) then return '' end
			local c=0
			for i=1,8 do c=c+(_sub(x,i,i)=='1' and 2^(8-i) or 0) end
			return _char(c)
		end))
	end

	-- SHA-256: pure Lua implementation
	---------------------------------------------------------------------------
	--[[
		LICENSE
		(c) 2022 Eetu Rantanen.
		(c) 2014 MaHuJa.
		(c) 2008-2011 David Manura.  Licensed under the same terms as Lua (MIT).

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in
		all copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
		THE SOFTWARE.
		(end license)

		Original code from:
			https://github.com/davidm/lua-bit-numberlua/blob/master/lmod/bit/numberlua.lua
			https://github.com/MaHuJa/CC-scripts/blob/master/sha256.lua
	]]

	local MOD = 2^32
	local MODM = MOD-1

	local k = {
		0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
		0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
		0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
		0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
		0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
		0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
		0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
		0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
		0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
		0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
		0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
		0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
		0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
		0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
		0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
		0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
	}

	-- Forward declaring functions.
	local memoize, make_bitop_uncached, make_bitop, bxor, band, bnot, rshift1, rshift, lshift, rrotate, str2hexa, num2s, s232num, preproc, initH256, digestblock

	function memoize(f)
		local mt = {}
		local t = setmetatable({}, mt)
		function mt:__index(k)
			local v = f(k)
			t[k] = v
			return v
		end
		return t
	end

	function make_bitop_uncached(t, m)
		local function bitop(a, b)
			local res,p = 0,1
			while a ~= 0 and b ~= 0 do
				local am, bm = a % m, b % m
				res = res + t[am][bm] * p
				a = (a - am) / m
				b = (b - bm) / m
				p = p*m
			end
			res = res + (a + b) * p
			return res
		end
		return bitop
	end

	function make_bitop(t)
		local op1 = make_bitop_uncached(t,2^1)
		local op2 = memoize(function(a)
			return memoize(function(b)
				return op1(a, b)
			end)
		end)
		return make_bitop_uncached(op2, 2 ^ (t.n or 1))
	end

	local bxor1 = make_bitop({[0] = {[0] = 0,[1] = 1}, [1] = {[0] = 1, [1] = 0}, n = 4})

	function bxor(a, b, c, ...)
		local z = nil
		if b then
			a = a % MOD
			b = b % MOD
			z = bxor1(a, b)
			if c then
				z = bxor(z, c, ...)
			end
			return z
		elseif a then
			return a % MOD
		else
			return 0
		end
	end

	function band(a, b, c, ...)
		local z
		if b then
			a = a % MOD
			b = b % MOD
			z = ((a + b) - bxor1(a,b)) / 2
			if c then
				z = band(z, c, ...)
			end
			return z
		elseif a then
			return a % MOD
		else
			return MODM
		end
	end

	function bnot(x)
		return (-1 - x) % MOD
	end

	function rshift1(a, disp)
		if disp < 0 then
			return lshift(a,-disp)
		end
		return _floor(a % 2 ^ 32 / 2 ^ disp)
	end

	function rshift(x, disp)
		if disp > 31 or disp < -31 then
			return 0
		end
		return rshift1(x % MOD, disp)
	end

	function lshift(a, disp)
		if disp < 0 then
			return rshift(a,-disp)
		end
		return (a * 2 ^ disp) % 2 ^ 32
	end

	function rrotate(x, disp)
		x = x % MOD
		disp = disp % 32
		local low = band(x, 2 ^ disp - 1)
		return rshift(x, disp) + lshift(low, 32 - disp)
	end

	function str2hexa(s)
		return (_gsub(s, ".", function(c) return _format("%02x", _byte(c)) end))
	end

	function num2s(l, n)
		local s = ""
		for _ = 1, n do
			local rem = l % 256
			s = _char(rem) .. s
			l = (l - rem) / 256
		end
		return s
	end

	function s232num(s, i)
		local n = 0
		for i = i, i + 3 do
			n = n*256 + _byte(s, i)
		end
		return n
	end

	function preproc(msg, len)
		local extra = 64 - ((len + 9) % 64)
		len = num2s(8 * len, 8)
		msg = msg .. "\128" .. _rep("\0", extra) .. len
		_assert(#msg % 64 == 0)
		return msg
	end

	function initH256(H)
		H[1] = 0x6a09e667
		H[2] = 0xbb67ae85
		H[3] = 0x3c6ef372
		H[4] = 0xa54ff53a
		H[5] = 0x510e527f
		H[6] = 0x9b05688c
		H[7] = 0x1f83d9ab
		H[8] = 0x5be0cd19
		return H
	end

	function digestblock(msg, i, H)
		local w = {}
		for j = 1, 16 do
			w[j] = s232num(msg, i + (j - 1)*4)
		end
		for j = 17, 64 do
			local v = w[j - 15]
			local s0 = bxor(rrotate(v, 7), rrotate(v, 18), rshift(v, 3))
			v = w[j - 2]
			w[j] = w[j - 16] + s0 + w[j - 7] + bxor(rrotate(v, 17), rrotate(v, 19), rshift(v, 10))
		end

		local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
		for i = 1, 64 do
			local s0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
			local maj = bxor(band(a, b), band(a, c), band(b, c))
			local t2 = s0 + maj
			local s1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
			local ch = bxor (band(e, f), band(bnot(e), g))
			local t1 = h + s1 + ch + k[i] + w[i]
			h, g, f, e, d, c, b, a = g, f, e, d + t1, c, b, a, t1 + t2
		end

		H[1] = band(H[1] + a)
		H[2] = band(H[2] + b)
		H[3] = band(H[3] + c)
		H[4] = band(H[4] + d)
		H[5] = band(H[5] + e)
		H[6] = band(H[6] + f)
		H[7] = band(H[7] + g)
		H[8] = band(H[8] + h)
	end

	function sha256(msg)
		msg = preproc(msg, #msg)
		local H = initH256({})
		for i = 1, #msg, 64 do digestblock(msg, i, H) end
		return str2hexa(num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) ..
			num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4) .. num2s(H[8], 4))
	end

	---------------------------------------------------------------------------

else
	-- Standard, non-HTML5 Base64 and SHA-256 implementations:
	local mime = require("mime")
	unb64 = mime.unb64
	b64 = mime.b64

	local crypto = require("crypto")
	local digest = crypto.digest
	local algorithm = crypto.sha256

	-- Create a wrapper for the standard SHA-256 setup
	-- so that it works identical to the HTML5 version.
	function sha256( data )
		return digest( algorithm, data )
	end
end

---------------------------------------------------------------------------

-- Toggle debug mode on or off, and handle a possible method call.
function loadsave.debugMode( input, enable )
	enable = input == loadsave and enable or input
	isDebugMode = type(enable) == "boolean" and enable or false
end

---------------------------------------------------------------------------

-- Toggle encoding and data validation on or off, and handle a possible method call.
function loadsave.protectData( input, enable )
	enable = input == loadsave and enable or input
	isDataProtected = type(enable) == "boolean" and enable or false
end

---------------------------------------------------------------------------

function loadsave.setPepper( pepper )
	if _type(pepper) ~= "string" then
		if isDebugMode then
			print( "WARNING: bad argument #1 to 'setPepper' (string expected, got " .. _type(pepper) .. ")." )
		end
		return
	end
	hash[1] = sha256(pepper)
end

---------------------------------------------------------------------------

local function writeToFile( filename, savedata, directory )
	local path = _pathForFile(filename, directory)
	local file, errorString = _open(path, "w")

	if not file then
		return false, errorString
	end
	file:write(savedata)
	_close(file)

	return true
end

-- Save a string or a table to a file, create a backup of it, and optionally protect the files from tampering.
function loadsave.save( data, filename, salt, directory )
	local typeData = _type(data)
	if typeData ~= "table" and typeData ~= "string" then
		if isDebugMode then
			print( "WARNING: bad argument #1 to 'save' (table or string expected, got " .. typeData .. ")." )
		end
		return false
	end
	if _type(filename) ~= "string" then
		if isDebugMode then
			print( "WARNING: bad argument #2 to 'save' (string expected, got " .. _type(filename) .. ")." )
		end
		return false
	end
	if _type(salt) ~= "string" then
		if isDebugMode then
			print( "WARNING: bad argument #3 to 'save' (string expected, got " .. _type(salt) .. ")." )
		end
		return false
	end

	-- Set the components of the hash.
	local contents = typeData == "table" and jsonEncode(data) or data
	hash[2] = contents
	hash[3] = salt

	-- Create the hash, the feint and base64 encode the save data.
	local t = {true, true, true}
	t[1] = sha256(_concat(hash))
	t[2] = _char(_random(97,122)) -- This'll stop a naïve base64 decode attempt.
	t[3] = b64(contents)

	if not t[3] then
		if isDebugMode then
			print( "WARNING: Write error - argument #1 to 'save' is an empty string." )
		end
		return false
	end

	-- Write the save data to the main and backup save files.
	directory = directory or system.DocumentsDirectory
	local savedata = isDataProtected and _concat(t) or contents
	local didSave, errorMessage = writeToFile( filename, savedata, directory )
	local didSaveBackup, errorMessageBackup = writeToFile( "backup_"..filename, savedata, directory )

	if isDebugMode and (not didSave or not didSaveBackup) then
		-- Only show a single warning if saving to file fails as these is likely caused by the same reason.
		print( "WARNING: Write error in 'save' - " .. (not didSave and errorMessage or errorMessageBackup) )
	end

	return didSave or didSaveBackup or false
end

---------------------------------------------------------------------------

local function readFromFile( filename, directory )
	local path = _pathForFile(filename, directory)
	local file, errorString = _open(path, "r")

	if file then
		local contents = file:read("*a")
		_close(file)

		-- If data isn't protected, then just read and return it.
		if not isDataProtected then
			local output = jsonDecode(contents)
			if not output then
				output = contents
			end
			return output, contents

		-- If the data is protected, then check it for tampering.
		else
			-- Ignore the feint, and retrieve the hash and the encoded data from the file.
			local fileHash = _sub(contents, 1, 64)
			local data = unb64(_sub(contents, 66))
			hash[2] = data
			-- Check for file tampering and then return the data in its original form.
			if not data then
				errorString = "The file has been tampered with (failed to decode data)"
			else
				if sha256(_concat(hash)) ~= fileHash then
					errorString = "The file has been tampered with, or 'salt' and/or 'pepper' are incorrect (hashes didn't match)"
				else
					local output = jsonDecode(data)
					if not output then
						output = data
					end
					-- Return the encoded contents in order to retrieve
					-- possible lost/corrupted/tampered data via backup.
					return output, contents
				end
			end
		end
	end
	return false, errorString
end

-- Load a file or restore from a backup, optionally check it for tampering, and return the decoded string or table.
function loadsave.load( filename, salt, directory )
	-- NB! load() function will attempt to load data based on whether data is protected or not.
	-- It cannot be used to load protected data when isDataProtected is false, and vice versa.
	if _type(filename) ~= "string" then
		if isDebugMode then
			print( "WARNING: bad argument #1 to 'load' (string expected, got " .. _type(filename) .. ")." )
		end
		return false
	end
	if _type(salt) ~= "string" then
		if isDebugMode then
			print( "WARNING: bad argument #2 to 'load' (string expected, got " .. _type(salt) .. ")." )
		end
		return false
	end
	hash[3] = salt

	directory = directory or system.DocumentsDirectory

	-- Read both save files in order to verify them.
	local data, dataEncoded = readFromFile( filename, directory )
	local backupData, backupEncoded = readFromFile( "backup_"..filename, directory )

	-- If data or backupData is false, it means that either the file doesn't exist, or it has been
	-- removed, corrupted or tampered with, so try to use the other save file to resolve the issue.
	if data then
		if not backupData or dataEncoded ~= backupEncoded then
			if isDebugMode then
				--NB! If a save file fails to load, then the "encoded" variables will contain the reason for failure.
				print( "WARNING: Failed to load \"backup_" .. filename .. "\" in 'load'. Reason: " .. backupEncoded )
			end
			writeToFile( "backup_"..filename, dataEncoded, directory )
		end
	else
		if backupData then
			if isDebugMode then
				print( "WARNING: Failed to load \"" .. filename .. "\" in 'load'. Reason: " .. dataEncoded )
			end
			writeToFile( filename, backupEncoded, directory )
		elseif isDebugMode then
			print( "WARNING: Failed to load \"" .. filename .. "\" or its backup in 'load'. Reason: " .. dataEncoded )
		end
	end
	return data or backupData
end

---------------------------------------------------------------------------

return loadsave
