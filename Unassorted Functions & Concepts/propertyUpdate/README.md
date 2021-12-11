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

NOTE: "object" is a proxy and not a display object/group, which means it cannot be directly inserted into any display groups or be used as an argument to Solar2D display API calls. In order to insert "object" into a display group, you need to use: group:insert( object._raw ).

---

You can find more of my personal projects over at my code portfolio site: [www.xedur.com](https://www.xedur.com). I work on all sorts of interesting projects, as well as plugins for Solar2D, in my free time. If you like what I'm doing and wish to support me, then [consider buying me a cup of coffee over at Ko-fi](https://ko-fi.com/xedur).

![alt text](https://www.solar2dplayground.com/img/support-me.png "Support me")

---