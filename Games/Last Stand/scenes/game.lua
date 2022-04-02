local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require("classes.screen")
local sfx = require("classes.sfx")
local utils = require("libs.utils")
local loadsave, savedata

---------------------------------------------------------------------------

-- Forward declarations & variables.


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