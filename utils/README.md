# utils.lua

utils.lua is my personal collection of all sorts of useful "utility functions" that I used across several of my projects.

utils.lua works by adding functions to existing Lua libraries and Solar2D libraries, such as `table`, `string`, `math` and `display`, as well as to its own global `utils` table for functions that didn't fit in with the other existing libraries.

The following libraries have been extended or added:
- `display`
- `math`
- `string`
- `system`
- `table`
- `utils` 

## Change log:

	[1.5.0] - 1 April 2022
			-   Moved all functions to their related global tables
			-   Moved the change log to separate README file
			-	Remove the following function:
				utils.timer(): This was only ever used for benchmarking, but there's a better dedicated benchmarking function.

	[1.4.6] - 1 April 2022
			-	Add the following new functions:
				utils.rgb2hex( r, g, b, notNormalised )
				utils.hex2rgb( hex, dontNormalise )

	[1.4.5] - 8 March 2022
			-	Add the following new functions:
				utils.getScaleFactor()

	[1.4.4] - 21 November 2021
			-	Add the following new functions:
				utils.addRepeatingFill( target, filename, textureSize, textureScale, textureWrapX, textureWrapY )
				utils.scaleDisplayObject( target, requiredWidth, requiredHeight )

	[1.4.3] - 11 August 2021
			-	Add the following new functions:
				string.count( s, character )
            -   Removed dummy variables via select()

	[1.4.2] - 8 August 2021
			-	Add the following new functions:
				string.findLast( s, character )

	[1.4.1] - 24 June 2021
			-	Add the following new functions:
				string.formatThousands( number, separator )
				math.getseed()
			-	Overwrite the functionality of the following function:
				math.randomseed( seed )

	[1.4] - 24 June 2021
			-	Add the following new functions:
				utils.checkForFile( filename, directory )
				utils.getBoolean( var )

	[1.3] - 19 June 2021
			-	Add the following new functions:
				utils.benchmark( f, iterations )

	[1.2] - 19 June 2021
			-	Add the following new functions:
				table.getRandom( t )
				table.count( t )

	[1.1] - 17 June 2021
			-	Add two new string functions:
				string.split( s, character )
				string.splitInTwo( s, index )

	[1.0] - 1 June 2021
			-	Initial release containing the following functions:
				utils.timer( printResult )
				display.isValid( object, remove )
				table.copy( t )
				table.getNext( t, shuffle )
				table.shuffle( t, newTable )
				table.print( t )
