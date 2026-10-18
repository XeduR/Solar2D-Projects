-- The game's only scene: builds every module, routes input, and runs the state machine.

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local composer = require( "composer" )
local screen = require( "classes.screen" )

local config = require( "data.game" )
local speedConfig = require( "data.speed" )
local saveConfig = require( "data.save" )

local speedModel = require( "classes.speedModel" )
local scores = require( "classes.scores" )
local save = require( "classes.save" )
local engineRoom = require( "classes.engineRoom" )
local world = require( "classes.world" )
local obstacles = require( "classes.obstacles" )
local captain = require( "classes.captain" )
local screens = require( "classes.screens" )
local hud = require( "classes.hud" )
local optionsPanel = require( "classes.optionsPanel" )
local sheets = require( "classes.sheets" )

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local sceneGroup
local gameGroup
local panelLayer
local inputCatcher

local saveData
local board

local model
local view
local boat
local room
local talk
local field
local overlay
local bar
local panel

local state
local isRunning = false
local isPaused = false
local previousTime = 0
local lastWarnedTier = 0
local titleIdleTime = 0
local thrustTouchId

local buildGame

--------------------------------------------------------------------------------------
-- Localised functions

local min = math.min
local getTimer = system.getTimer

--------------------------------------------------------------------------------------
-- Functions

-- Tagged transitions run only while the game itself updates.
local function syncGameTransitions()
	if isPaused or state == "help" then
		transition.pause( config.transitionTag )
	else
		transition.resume( config.transitionTag )
	end
end

local function isPlaying()
	return state == "phase1" or state == "launch" or state == "phase2"
end

local function releaseThrust()
	if thrustTouchId then
		display.getCurrentStage():setFocus( inputCatcher, nil )
		thrustTouchId = nil
	end

	boat:setThrust( false )
end

local function releaseInput()
	display.getCurrentStage():setFocus( nil )
	releaseThrust()
end

-- The credit line is part of the title bubble.
local function showStartTitle( isVisible )
	talk:showTitle( isVisible )
	titleIdleTime = 0
end

local function updateStartTitle( dt )
	if talk:isTitleShowing() or talk:isTalking() then
		titleIdleTime = 0
		return
	end

	titleIdleTime = titleIdleTime + dt

	if titleIdleTime >= config.titleRestoreDelay then
		showStartTitle( true )
	end
end

-- A press clears the title first and never cuts a line short; only an empty sky gets a quip.
local function pressWorld()
	if talk:isTitleShowing() then
		showStartTitle( false )

	elseif not talk:isTalking() then
		talk:quip( "taps" )
	end
end

local function startPhase1()
	state = "phase1"
	model:setPhase( 1 )

	showStartTitle( false )
	room:showTooltip( false )
	bar:showKnots( true )
end

local function shovel()
	if state == "start" then
		startPhase1()
	end

	model:shovel()
	room:shovel()
end

local function startLaunch()
	state = "launch"
	view:startLaunch()
	model:setAngerFrozen( true )
	talk:quip( "launch" )
end

local function startPhase2()
	state = "phase2"
	model:setPhase( 2 )
	model:setAngerFrozen( false )
	field:setActive( true )
	syncGameTransitions()
end

-- The game holds still under the help card until it is dismissed.
local function showHelp()
	state = "help"
	releaseInput()
	syncGameTransitions()
	overlay:showHelp( startPhase2 )
end

local function showGameOver( theme, cause )
	state = "gameover"

	local runKnots = model:getPeakKnots()
	local rank = board:submit( runKnots )

	saveData.scores = board:getList()
	save.write( saveData )

	bar:showKnots( false )
	overlay:showGameOver( { theme = theme, cause = cause, list = board:getList(), rank = rank, runKnots = runKnots }, buildGame )
end

local function getFired()
	state = "ending"
	releaseThrust()
	boat:setCoasting( true )
	talk:quip( "fired" )

	room:playFired( function()
		local centreX, centreY = room:getCenter()

		overlay:playFiredTransition( centreX, centreY, function()
			showGameOver( "fired", "fired" )
		end )
	end )
end

local function crash( hitX, hitY, cause )
	state = "ending"
	releaseThrust()
	boat:explode( hitX, hitY )

	overlay:playCrashTransition( hitX, hitY, function()
		showGameOver( "crash", cause )
	end )
end

-- Order matters: firing beats a crash on the same frame, an obstacle beats an edge, and a crash beats the phase changes.
local function checkTransitions()
	if ( state == "phase1" or state == "phase2" ) and model:isFired() then
		getFired()
		return
	end

	if state == "phase2" then
		local hitX, hitY, kind = field:checkCollision( boat:getCollisionCircle() )

		if hitX then
			crash( hitX, hitY, kind )
			return
		end

		local edge, edgeX, edgeY = boat:getEdgeHit()

		if edge then
			crash( edgeX, edgeY, edge == "top" and "edgeTop" or "edgeBottom" )
			return
		end
	end

	if state == "phase1" and model:hasEscaped() then
		startLaunch()

	elseif state == "launch" and view:isLaunchDone() then
		showHelp()
	end
end

local function checkWarnings()
	local tier = model:getAngerTier()

	if tier == 0 then
		lastWarnedTier = 0

	elseif tier > lastWarnedTier then
		lastWarnedTier = tier
		talk:warn( tier )
	end
end

local function updateCaptainPose()
	if model:getAngerTier() >= config.captainAngryTier then
		boat:setCaptainPose( "angry" )

	elseif talk:isTalking() or talk:isTitleShowing() then
		boat:setCaptainPose( "shout" )

	else
		boat:setCaptainPose( "idle" )
	end
end

local function onEnterFrame()
	if not isRunning or isPaused then
		return
	end

	local now = getTimer()
	local dt = min( ( now - previousTime ) / 1000, config.maxFrameTime )
	previousTime = now

	if state == "help" then
		overlay:update( dt )
		return
	end

	if isPlaying() then
		model:update( dt )
	end

	local knots = model:getKnots()
	local fireLevel = model:getFireLevel()

	room:setFireLevel( fireLevel )
	view:update( dt, knots, fireLevel )
	bar:setKnots( knots )
	talk:setAnchor( boat:getCaptainPoint() )

	room:update( dt )
	talk:update( dt, knots )
	updateCaptainPose()
	field:update( dt, view:getScrollSpeed(), knots )
	overlay:update( dt )
	bar:update( dt )

	if state == "start" then
		updateStartTitle( dt )
	end

	checkTransitions()

	if isPlaying() then
		checkWarnings()
	end
end

local function onCatcherTouch( event )
	local phase = event.phase

	if phase == "began" then
		if not ( state == "start" or isPlaying() ) then
			return true
		end

		if room:containsPoint( event.x, event.y ) then
			shovel()

		elseif state == "start" or state == "phase1" then
			pressWorld()

		elseif state == "phase2" then
			display.getCurrentStage():setFocus( inputCatcher, event.id )
			thrustTouchId = event.id
			boat:setThrust( true )
		end

	elseif ( phase == "ended" or phase == "cancelled" ) and event.id == thrustTouchId then
		releaseThrust()
	end

	return true
end

local function setVolume( key, value )
	saveData.volume[key] = value

	if key == "master" then
		audio.setVolume( value )
	end
end

local function openOptions()
	if panel:isOpen() then
		panel:close()
		return
	end

	isPaused = true
	releaseInput()
	syncGameTransitions()
	panel:open()
end

local function onOptionsClosed()
	isPaused = false
	previousTime = getTimer()
	syncGameTransitions()
end

local function newLayer( parent )
	local layer = display.newGroup()
	parent:insert( layer )
	return layer
end

-- Reset is a full rebuild: every module is constructed again and the run returns to the start view.
function buildGame()
	display.getCurrentStage():setFocus( nil )
	thrustTouchId = nil
	isPaused = false

	if inputCatcher then
		inputCatcher:removeEventListener( "touch", onCatcherTouch )
	end

	transition.cancel( config.transitionTag )
	display.remove( gameGroup )
	display.remove( panelLayer )

	gameGroup = newLayer( sceneGroup )
	panelLayer = newLayer( sceneGroup )

	local worldLayer = newLayer( gameGroup )
	local engineLayer = newLayer( gameGroup )

	inputCatcher = display.newRect( gameGroup, screen.centerX, screen.centerY, screen.width, screen.height )
	inputCatcher.isVisible = false
	inputCatcher.isHitTestable = true
	inputCatcher:addEventListener( "touch", onCatcherTouch )

	local bubbleLayer = newLayer( gameGroup )
	local overlayLayer = newLayer( gameGroup )
	local hudLayer = newLayer( gameGroup )

	model = speedModel.new( speedConfig )
	view = world.new( worldLayer )
	boat = view:getBoat()
	field = obstacles.new( view:getObstacleLayer() )
	room = engineRoom.new( engineLayer )
	talk = captain.new( bubbleLayer )
	overlay = screens.new( overlayLayer )
	bar = hud.new( hudLayer, { onReset = buildGame, onOptions = openOptions } )

	panel = optionsPanel.new( panelLayer, saveData.volume, {
		onChange = setVolume,

		onRelease = function( key, value )
			setVolume( key, value )
			save.write( saveData )
		end,

		onClose = onOptionsClosed,
	} )

	state = "start"
	lastWarnedTier = 0

	talk:setAnchor( boat:getCaptainPoint() )
	showStartTitle( true )
	room:showTooltip( true )
	bar:showKnots( false )
end

--------------------------------------------------------------------------------------
-- Scene functions

local scene = composer.newScene()

function scene:create( event )
	sceneGroup = self.view
	sheets.applyTextureDefaults()

	saveData = save.load()

	local sceneParams = event.params or {}
	audio.setVolume( sceneParams.muteGame and 0 or saveData.volume.master )
	board = scores.new( saveData.scores, saveConfig.maxScores )

	buildGame()
end

function scene:show( event )
	local phase = event.phase

	if phase == "will" then
		if composer._previousScene == "scenes.launchScreen" then
			composer.removeScene( "scenes.launchScreen" )
		end

		Runtime:addEventListener( "enterFrame", onEnterFrame )

	elseif phase == "did" then
		previousTime = getTimer()
		isRunning = true
	end
end

function scene:hide( event )
	local phase = event.phase

	if phase == "will" then
		isRunning = false

	elseif phase == "did" then
		Runtime:removeEventListener( "enterFrame", onEnterFrame )
	end
end

function scene:destroy( event )
	if inputCatcher then
		inputCatcher:removeEventListener( "touch", onCatcherTouch )
	end

	transition.cancel( config.transitionTag )

	sceneGroup = nil
	gameGroup = nil
	panelLayer = nil
	inputCatcher = nil

	model = nil
	view = nil
	boat = nil
	room = nil
	talk = nil
	field = nil
	overlay = nil
	bar = nil
	panel = nil

	saveData = nil
	board = nil
end

--------------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene
