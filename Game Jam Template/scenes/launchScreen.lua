local composer = require("composer")
local scene = composer.newScene()

local screen = require("classes.screen")

---------------------------------------------------------------------------

local logo = "assets/images/launchScreen/XeduR.png"
local logoWidth = 512
local logoHeight = 256

local copyright = "© 2021 Eetu Rantanen"
local font = native.systemFontBold
local fontSize = 24
local offset = 10

---------------------------------------------------------------------------

local logoGroup = display.newGroup()
logoGroup.alpha = 0

---------------------------------------------------------------------------

function scene:create( event )
    local sceneGroup = self.view
    sceneGroup:insert( logoGroup )
    
    local logo = display.newImageRect( logoGroup, logo, logoWidth, logoHeight )
    logo.x, logo.y = screen.centerX, screen.centerY
    
    local copyrightText = display.newText( logoGroup, copyright, screen.centerX, screen.maxY - offset, font, fontSize )
    copyrightText.anchorY = 1
end

---------------------------------------------------------------------------

function scene:show( event )
    if event.phase == "did" then
        -- Reveal the logo.
        transition.to( logoGroup, {
            delay = 250,
            time = 500,
            alpha = 1,
            transition = easing.inOut,
            onComplete = function()
                -- Hide the logo.
                transition.to( logoGroup, {
                    delay = 1250,
                    time = 250,
                    alpha = 0,
                    transition = easing.inOut,
                    onComplete = function()
                        composer.gotoScene( "scenes.game", {
                            effect = "fade",
                            time = 100,
                        } )
                    end
                })
            end
        })
    end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene