local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require("classes.screen")
local loadsave = require("classes.loadsave")
local sfx = require("classes.sfx")
local utils = require("libs.utils")

---------------------------------------------------------------------------

-- Forward declarations & variables.


---------------------------------------------------------------------------

-- Functions.


---------------------------------------------------------------------------

function scene:create( event )
    local sceneGroup = self.view
    
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
        
        
    end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene