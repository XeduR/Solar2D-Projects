-- The game's only scene: builds every module, routes input, and runs the state machine.

--------------------------------------------------------------------------------------
-- Libraries, classes, scripts, configs, etc.

local composer = require( "composer" )
local screen = require( "classes.screen" )

local config = require( "data.game" )
local speedConfig = require( "data.speed" )
local saveConfig = require( "data.save" )
local soundConfig = require( "data.sound" )
local screensConfig = require( "data.screens" )

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
local sound = require( "classes.sound" )
local controls = require( "classes.controls" )

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

-- Set by muteGame; the master volume stays at zero until the Master slider moves.
local isMuted = false

-- Seconds left until the music returns on the game-over screen, nil when none is pending.
local musicRestartDelay

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

-- The boat thrusts only in phase 2 while the game runs and a thrust key is held.
local function syncThrust()
	local isThrusting = state == "phase2" and not isPaused and controls.isThrustHeld()

	boat:setThrust( isThrusting )
	sound.setLayer( "thrust", isThrusting and 1 or 0 )
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
	sound.play( "launch" )
end

local function startPhase2()
	state = "phase2"
	model:setPhase( 2 )
	model:setAngerFrozen( false )
	field:setActive( true )
	syncGameTransitions()
	syncThrust()

	if not isPaused then
		sound.resumeLoops()
	end
end

-- The card and the Options panel show the same saved setting, so both labels follow every flip.
local function toggleShowInstructions()
	saveData.showInstructions = not saveData.showInstructions
	overlay:setShowInstructions( saveData.showInstructions )
	panel:setShowInstructions( saveData.showInstructions )
	sound.play( "click" )
	save.write( saveData )
end

-- The game holds still under the help card until it is dismissed.
local function showHelp()
	state = "help"
	syncThrust()
	syncGameTransitions()
	sound.pauseLoops()

	overlay:showHelp( startPhase2, {
		showInstructions = saveData.showInstructions,
		onToggle = toggleShowInstructions,
	} )
end

local function showGameOver( theme, cause )
	state = "gameover"

	local runKnots = model:getPeakKnots()
	local rank = board:submit( runKnots )

	saveData.scores = board:getList()
	save.write( saveData )

	bar:showKnots( false )
	sound.play( "jingle" )
	musicRestartDelay = soundConfig.gameOverMusicDelay
	overlay:showGameOver( { theme = theme, cause = cause, list = board:getList(), rank = rank, runKnots = runKnots }, buildGame )
end

local function getFired()
	state = "ending"
	syncThrust()
	boat:setCoasting( true )
	talk:quip( "fired" )

	sound.stopLoops()

	room:playFired( function()
		local centreX, centreY = room:getCenter()

		sound.fadeOutMusic( screensConfig.firedTransition.duration )

		overlay:playFiredTransition( centreX, centreY, function()
			-- Sound updates before the overlay each frame, so the fade still has one frame left when the screen turns fully black.
			sound.cutMusic()
			showGameOver( "fired", "fired" )
		end )
	end )
end

local function crash( hitX, hitY, cause )
	state = "ending"
	syncThrust()
	boat:explode( hitX, hitY )

	sound.stopLoops()
	sound.cutMusic()
	sound.play( "crash" )

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
		if saveData.showInstructions then
			showHelp()
		else
			startPhase2()
		end
	end
end

local function checkWarnings()
	local tier = model:getAngerTier()

	if tier == 0 then
		lastWarnedTier = 0

	elseif tier > lastWarnedTier then
		lastWarnedTier = tier
		talk:warn( tier )
		sound.play( "stinger" .. tier )
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

local function updateMusicRestart( dt )
	if not musicRestartDelay then
		return
	end

	musicRestartDelay = musicRestartDelay - dt

	if musicRestartDelay <= 0 then
		musicRestartDelay = nil
		sound.restartMusic()
	end
end

-- The fire roars from the start view to space.
local function updateLayers( fireLevel )
	sound.setLayer( "roar", fireLevel )
end

local function onEnterFrame()
	if not isRunning then
		return
	end

	local now = getTimer()
	local dt = min( ( now - previousTime ) / 1000, config.maxFrameTime )
	previousTime = now

	-- The music and its cross-fades keep running while Options or the help card holds the game still.
	sound.update( dt )
	updateMusicRestart( dt )

	if isPaused then
		return
	end

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

	if state == "start" or isPlaying() then
		updateLayers( fireLevel )
	end

	if isPlaying() then
		sound.setKnots( knots )
	end

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

-- Shovelling and thrust are on the keyboard; presses outside the engine room only talk to the captain.
local function onCatcherTouch( event )
	if event.phase == "began" and ( state == "start" or state == "phase1" ) and not room:containsPoint( event.x, event.y ) then
		pressWorld()
	end

	return true
end

local function applyVolumes()
	local volume = saveData.volume

	sound.setVolumes( { master = isMuted and 0 or volume.master, music = volume.music, sfx = volume.sfx } )
end

local function setVolume( key, value )
	saveData.volume[key] = value

	if key == "master" then
		isMuted = false
	end

	applyVolumes()
end

local function openOptions()
	if panel:isOpen() then
		panel:close()
		return
	end

	isPaused = true
	syncThrust()
	syncGameTransitions()
	sound.pauseLoops()
	panel:open()
end

local function onOptionsClosed()
	isPaused = false
	previousTime = getTimer()
	syncGameTransitions()
	syncThrust()

	-- The help card keeps the loops paused until it is dismissed.
	if state ~= "help" then
		sound.resumeLoops()
	end
end

local function newLayer( parent )
	local layer = display.newGroup()
	parent:insert( layer )
	return layer
end

-- Options takes only Escape, the help card and the game-over screen take any key, and the game itself takes its bound keys.
local function onKeyDown( action )
	if panel:isOpen() then
		if action == "options" then
			panel:close()
			return true
		end

		return false
	end

	if state == "help" then
		overlay:dismissHelp()
		return true
	end

	if state == "gameover" then
		overlay:pressGameOverKey()
		return true
	end

	if action == "options" then
		openOptions()
		return true
	end

	if action == "shovel" and ( state == "start" or isPlaying() ) then
		shovel()
		return true
	end

	return false
end

-- Reset is a full rebuild: every module is constructed again and the run returns to the start view.
function buildGame()
	display.getCurrentStage():setFocus( nil )
	isPaused = false
	musicRestartDelay = nil

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

			-- A click at the new level makes the effects volume audible.
			if key == "sfx" then
				sound.play( "click" )
			end
		end,

		onToggleInstructions = toggleShowInstructions,
		onClose = onOptionsClosed,
	} )

	panel:setShowInstructions( saveData.showInstructions )

	state = "start"
	lastWarnedTier = 0

	talk:setAnchor( boat:getCaptainPoint() )
	showStartTitle( true )
	room:showTooltip( true )
	bar:showKnots( false )

	sound.reset()
end

--------------------------------------------------------------------------------------
-- Scene functions

local scene = composer.newScene()

function scene:create( event )
	sceneGroup = self.view
	sheets.applyTextureDefaults()

	saveData = save.load()

	local sceneParams = event.params or {}
	isMuted = sceneParams.muteGame == true
	applyVolumes()

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
		controls.start( { onKeyDown = onKeyDown, onThrustChange = syncThrust } )

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
		controls.stop()
		sound.stopLoops()
		sound.cutMusic()
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
