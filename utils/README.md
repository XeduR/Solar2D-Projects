# utils.lua

utils.lua is my personal collection of all sorts of useful "utility functions" that I use across several of my projects.

utils.lua works by adding functions to existing Lua libraries and Solar2D libraries, such as `table`, `string`, `math` and `display`, as well as to its own global `utils` table for functions that didn't fit in with the other existing libraries.

The following libraries have been extended or added:
- `display`
- `math`
- `string`
- `system`
- `table`
- `utils`

## Change log:

### [1.6] - 4 July 2026

- Add `system.getTruePlatform()`.
- `display.scaleDisplayObject()` now returns the scale that it applied.
- `require("utils")` now returns the global `utils` table instead of an empty placeholder table.
- Fix `display.hex2rgb()`: 3-digit shorthand hex (e.g. "f2a") now expands each digit correctly instead of returning near-zero values.
- Fix `display.rgb2hex()`: output is now zero-padded to 6 digits (green used to return "7f00" instead of "007f00") and channels are rounded instead of truncated, so hex2rgb round-trips are exact.
- Fix `math.randomseed()`: seeds in the range [2^31, 2^32) previously overflowed the signed 32-bit cast inside Lua 5.1's srand; all seeds are now wrapped into range.
- Fix `string.formatThousands()`: multi-character and multi-byte (e.g. UTF-8 NBSP) separators now work, numbers at or above 1e+15 are expanded from exponent notation instead of being truncated to their first digit, and inf/nan no longer crash.
- Fix `string.findLast()` and `string.split()`: separators containing pattern magic characters (e.g. "%") no longer error; both treat the separator as plain text now.
- Fix `system.checkForFile()`: .lua files are checked via require() only for the resource directory, so .lua files in e.g. the documents directory are found via the file system.
- Fix `system.cleanupFolder()`: the directory now defaults to DocumentsDirectory instead of ResourceDirectory, a missing folder or non-string folder argument is a safe no-op instead of a crash (or a wipe of the wrong directory), and folders are removed via lfs.rmdir() on all platforms without shelling out on Windows.
- Fix `system.createFolder()`: creates missing parent folders recursively and no longer changes the process working directory.
- Fix `table.copy()`: cyclic tables no longer cause a stack overflow, and shared subtables keep their shared identity in the copy.
- Fix `table.print()`: boolean/table keys no longer crash it, and a non-table argument prints a warning instead of silently doing nothing.
- Remove a leftover localisation of the removed `display.isValidImage()`. Note: isValidImage was removed and `math.getseed()` was renamed to `math.generateSeed()` in April 2026 without a changelog entry.

### [1.5.2] - 7 November 2023
- Rewrite display.isValid() and change its name to display.isValidImage() to better describe its intended use.

### [1.5.1] - 24 December 2022
- Add the following new functions:
	- `system.cleanupFolder( folder, directory )`
	- `system.createFolder( folder, directory )`
- Refactor `system.checkForFile( filename, directory)` to also check for .lua files on devices
- Other minor style updates

### [1.5.0] - 22 October 2022
- Moved all functions to their related global tables
- Moved the change log to separate README file
- Remove the following function:
	- `utils.timer()`: This was only ever used for benchmarking, but there's a better dedicated benchmarking function

### [1.4.6] - 1 April 2022
- Add the following new functions:
	- `utils.rgb2hex( r, g, b, notNormalised )`
	- `utils.hex2rgb( hex, dontNormalise )`

### [1.4.5] - 8 March 2022
- Add the following new functions:
	- `utils.getScaleFactor()`

### [1.4.4] - 21 November 2021
- Add the following new functions:
	- `utils.addRepeatingFill( target, filename, textureSize, textureScale, textureWrapX, textureWrapY )`
	- `utils.scaleDisplayObject( target, requiredWidth, requiredHeight )`

### [1.4.3] - 11 August 2021
- Add the following new functions:
	- `string.count( s, character )`
- Removed dummy variables via select()

### [1.4.2] - 8 August 2021
- Add the following new functions:
	- `string.findLast( s, character )`

### [1.4.1] - 24 June 2021
- Add the following new functions:
	- `string.formatThousands( number, separator )`
	- `math.getseed()`
- Overwrite the functionality of the following function:
	- `math.randomseed( seed )`

### [1.4] - 24 June 2021
- Add the following new functions:
	- `utils.checkForFile( filename, directory )`
	- `utils.getBoolean( var )`

### [1.3] - 19 June 2021
- Add the following new functions:
	- `utils.benchmark( f, iterations )`

### [1.2] - 19 June 2021
- Add the following new functions:
	- `table.getRandom( t )`
	- `table.count( t )`

### [1.1] - 17 June 2021
- Add two new string functions:
	- `string.split( s, character )`
	- `string.splitInTwo( s, index )`

### [1.0] - 1 June 2021
- Initial release containing the following functions:
	- `utils.timer( printResult )`
	- `display.isValid( object, remove )`
	- `table.copy( t )`
	- `table.getNext( t, shuffle )`
	- `table.shuffle( t, newTable )`
	- `table.print( t )`
