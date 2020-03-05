display.setStatusBar( display.HiddenStatusBar )
local onApprovedDomain = false

--[[
    This is a simple demo project that demonstrates how you can check if your project
    is running on your desired domain(s). This is a very simple form of DRM and it is
    by no means secure. It will, however, prevent people without sufficient technical
    know-how from simply copying your project and adding it to their websites.
]]

if system.getInfo( "platform" ) == "html5" then
    local domain = require( "verifyDomain" )
    -- Add any domains you want to be able to launch your game here.
    local approvedDomains = {
        "https://xedur.github.io/",
        "https://spyric.com/"
    }
    --[[
        If ignoreSubfolders is false, then the retrieved domain has to perfectly match
        a domain in the list above. If ignoreSubfolders is true, then the check will
        ignore subfolders on the domain, i.e. "https://xedur.github.io/getDomain/"
        would still run even if the approved domain is "https://xedur.github.io/".
    ]]
    local ignoreSubfolders = true

    if #approvedDomains > 0 then
        local s = domain.get()
        for i = 1, #approvedDomains do
            local d = approvedDomains[i]
            if d == (ignoreSubfolders and s:sub(1,d:len()) or s) then
                onApprovedDomain = true
                break
            end
        end
    end
else
    print( "WARNING: This project uses JavaScript and you must build for HTML5 for it to work." )
end

local notification = display.newText( "", display.contentCenterX, display.contentCenterY-200, native.systemFont, 30 )
local indicator = display.newRect( display.contentCenterX, display.contentCenterY, 200, 200 )
-- If the platform is HTML5 and domain matches an approved one, then run your project.
if onApprovedDomain then
    -- You could run composer.gotoScene() from here so that the game only loads on approved domains.
    indicator:setFillColor( 0, 0.8, 0 ) -- Turn the indicator green to indicate success.
    notification.text = "This project is running on an approved domain."
else
    indicator:setFillColor( 0.8, 0, 0 ) -- Turn the indicator red to indicate failure.
    notification.text = "This project is trying to run on an unapproved domain."
end
