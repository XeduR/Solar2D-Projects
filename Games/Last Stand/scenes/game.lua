local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require("classes.screen")
local sfx = require("classes.sfx")
local utils = require("libs.utils")
local loadsave, savedata

local controls = require("classes.controls")
local physics = physics or require("physics")
physics.setDrawMode( "hybrid" )
physics.start()
physics.setGravity( 0, 0 )

---------------------------------------------------------------------------

-- Forward declarations & variables.
local player

---------------------------------------------------------------------------

-- Functions.


---------------------------------------------------------------------------

function scene:create( event )
    local sceneGroup = self.view
    -- If the project uses savedata, then load existing data or set it up.
    if event.params and event.params.usesSavedata then
        loadsave = require("classes.loadsave")
        savedata = loadsave.load("data.json")
        
        if not savedata then
            -- Assign initial values for save data.
            savedata = {
                
            }
            loadsave.save( savedata, "data.json" )
        end
    end
    
    local ground = display.newCircle( sceneGroup, screen.centerX, screen.centerY + 60, 320 )
    ground:setFillColor( 73/255, 77/255, 126/255 )
    ground.yScale = 0.4
    
    local groundLine = {}
    for i = 1, ground.contentBounds.yMax-ground.contentBounds.yMin do
        -- local line = display.newLine( sceneGroup, )
        -- groundLine[i] = disp
    end
    
    player = display.newRect( screen.centerX, screen.centerY, 40, 80 )
    physics.addBody( player, "dynamic", {
        -- Add the physics body to roughly the player's feet, bottom 25% of the player model.
        box = { halfWidth=player.width*0.5, halfHeight=player.height*0.125, x=0, y=player.height*0.375 }
    } )
    player.isFixedRotation = true
    player.canDash = true
    
    local function resetDash()
        player.canDash = true
    end
    
    function player.dash( time )
        -- Animate the dash somehow and show a countdown until dash is ready again.
        -- Maybe the dash could take longer to recover from per damage taken?
        player.canDash = false
        timer.performWithDelay( time, resetDash )
    end
    
end

---------------------------------------------------------------------------

function scene:show( event )
    local sceneGroup = self.view
    
    if event.phase == "will" then
        -- If coming from launchScreen scene, then start by removing it.
        if composer._previousScene == "scenes.launchScreen" then
            composer.removeScene( "scenes.launchScreen" )
        end
        
    elseif event.phase == "did" then
        controls.init( player )
        controls.start()
        
    end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene