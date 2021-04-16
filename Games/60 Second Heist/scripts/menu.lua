local composer = require( "composer" )
local scene = composer.newScene()
local sfx = require( "scripts.sfx" )
local screen = require( "scripts.screen" )
local clock = require( "scripts.clock" )

local level = {}
local buttonAudio
local menuClock
local blockTouch = false

local function gotoGame( event )
    if event.phase == "ended" and not blockTouch then
        blockTouch = true
        composer.gotoScene( "scripts.game", {
            time=500,
            effect="slideLeft",
            params={level=event.target.id}
        } )
    end
end

local function easterEgg( event )
    transition.to( level[#level], {time=1000, alpha=1})
end

-------------------------------
function scene:create( event )
    local sceneGroup = self.view
    
    buttonAudio = display.newRect( screen.xMax-20, screen.yMin+20, 32, 32 )
    buttonAudio:addEventListener( "touch", sfx.toggleAudio )
    
    local background = display.newImageRect( sceneGroup, "images/titlescreen.png", 960, 640 )
    background.x, background.y = screen.xCenter, screen.yCenter
    
    local title = display.newImageRect( sceneGroup, "images/title.png", 762, 74 )
    title.rotation, title.x, title.y = -8, screen.xCenter, screen.yMin+120
    
    local start = display.newText( sceneGroup, "Choose a heist.", 760, screen.yMax-400, "fonts/Action_Man.ttf", 44 )
    start:setFillColor( 0.95, 0.85, 0 )
    
    for i = 1, 5 do
        level[i] = display.newText( sceneGroup, "Heist #"..i, 760, start.y+20+i*50, "fonts/Action_Man.ttf", 36 )
        level[i].id = i
        level[i]:addEventListener( "touch", gotoGame )
    end
    
    menuClock = clock.create( sceneGroup, 220, 440, "menu" )
    
    level[#level+1] = display.newText( sceneGroup, "Secret Heist", 220, 500, "fonts/Action_Man.ttf", 28 )
    level[#level].id = #level
    level[#level]:addEventListener( "touch", gotoGame )
    level[#level]:setFillColor(1,0,0)
    level[#level].alpha = 0
end


function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
    
    if phase == "will" then
        level[#level].alpha = 0
        menuClock:start(easterEgg)
        if event.params then
            transition.to( buttonAudio, {time=400,x=buttonAudio.x+40})
        end

    elseif phase == "did" then
        blockTouch = false
    end
end


function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase

    if phase == "will" then
        if level[#level].alpha ~= 0 then
            transition.to( level[#level], {time=400,alpha=0})
        end
        transition.to( buttonAudio, {time=400,x=buttonAudio.x-40})
        menuClock:stop()
    end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )

return scene