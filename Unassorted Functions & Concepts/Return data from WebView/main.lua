-- Simple test project for returning data from Solar2D's native WebView to Solar2D.

local code = display.newText(
	"Waiting for input...",
	display.contentCenterX,
	display.contentCenterY+120,
	native.systemFont,
	20
)

local function webListener( event )
	local url = event.url

	-- This approach will always trigger an error, so the listener is called twice.
	if not event.errorCode then
		local sendCode = string.find( url, "solar2d:sendCode" )
		if sendCode then
			-- In typical URL parameter style, multiple parameters can be returned.
			local _, codeStart = string.find( url, "?code=" )
			-- Sending data back via form seems to result in the special characters
			-- being automatically encoded (as they are used as an URL).
			code.text = string.sub( url, codeStart+1 )
		end
    end
end

local webView = native.newWebView( display.contentCenterX, display.contentCenterY-20, 400, 200 )
webView:request( "codeForm.html", system.ResourceDirectory )
webView:addEventListener( "urlRequest", webListener )

