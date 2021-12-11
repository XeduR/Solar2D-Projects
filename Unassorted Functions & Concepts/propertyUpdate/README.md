---

# propertyUpdate
[![License: MIT](http://xedur.com/img/license-MIT-green.svg)](https://github.com/XeduR/Public-Projects/blob/master/LICENSE)

A simple module for adding "propertyUpdate" event listeners to Solar2D display objects/groups.

```lua
local propertyUpdate = require("propertyUpdate")
local object = display.newRect( 100, 100, 100, 100 )

object = propertyUpdate.getProxy( object )

function object:propertyUpdate( event )
	for i, v in pairs( event ) do
		print( i, v )
	end
end
object:addEventListener( "propertyUpdate" )

-- Updating the property "x" will call the "propertyUpdate" listener.
object.x = 200
```

**NOTE 1**: `object` is a proxy and not a display object/group, which means it cannot be directly inserted into any display groups or be used as an argument to Solar2D display API calls. In order to insert `object` into a display group, you need to use: `group:insert(object._raw)`. You can, however, otherwise treat them like regular display objects/groups and use the standard Solar2D methods and functions with them.

**NOTE 2**: If you are looking to use `object` with transition, or other similarly functioning functions, then you can directly transition `object._raw`, which is a reference to the original display object/group. By doing so, you bypass the metamethods.

---

**You can find more of my personal projects over at: [www.xedur.com](https://www.xedur.com).**
