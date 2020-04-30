display.setStatusBar( display.HiddenStatusBar )
if system.getInfo( "platform" ) ~= "html5" then
    local disclaimer = display.newText({
        text = "In order to run this project, you need to create an HTML5 build and deploy it.",
        width = 800,
        x = display.contentCenterX,
        y = display.contentCenterY,
        font = native.systemFontBold,
        align = "center",
    })
else
    local _inputCode = require( "inputCode" )
    local _button
    
    -- Hijack the physics library
    local physics = require("physics")
    local _pState = "stop"
    local _pStart = physics.start 
    local _pPause = physics.pause 
    local _pStop = physics.stop
    function physics.start()
        _pState = "start"
        _pStart()
    end
    function physics.pause()
        _pState = "pause"
        _pPause()
    end
    function physics.stop()
        _pState = "stop"
        _pStop()
    end

    -- To prevent Runtime listeners from hanging around, we insert any newly created
    -- Runtime listeners to a table and remove them if the user explicitly wants to.
    local _addEventListener = Runtime.addEventListener
    local _removeEventListener = Runtime.removeEventListener
    local _runtimeListeners = {}

    function Runtime.addEventListener( ... )
        local t = {...}
        _runtimeListeners[#_runtimeListeners+1] = { t[2], t[3] }
        _addEventListener( ... )
    end

    function Runtime.removeEventListener( ... )
        local t = {...}
        for i = 1, #_runtimeListeners do
            if _runtimeListeners[i][1] == t[1] then
                table.remove( _runtimeListeners, i )
                break
            end
        end
        _removeEventListener( ... )
    end

    -- This demo project relies on loadstring(), so everything that is created will be added
    -- to the global table from where they'll need to be removed upon resubmitting the code.
    local _globals = {}
    for i, j in pairs( _G ) do
        _globals[i] = true
    end

    local function _clearEverything()
        if _pState ~= "stop" then
            physics.stop()
        end
        transition.cancel()
        -- TODO: timer.cancel( "all" ) -- Requires finishing my changes to timer framework.
        
        -- Start by removing Runtime listeners.
        for i = #_runtimeListeners, 1, -1 do
            Runtime:removeEventListener( _runtimeListeners[i][1], _runtimeListeners[i][2] )
        end
        -- Then remove all display objects and variables.
        local functions = {}
        for name, entry in pairs( _G ) do
            if not _globals[name] then
                local t = type( entry )
                if t == "function" then
                    functions[#functions+1] = name
                else
                    if t == "table" then
                        if _G[name].removeSelf then
                            _G[name]:removeSelf()
                        end
                    end
                    _G[name] = nil
                end
            end
        end
        -- And finally remove all functions.
        for i = 1, #functions do
            _G[functions[i]] = nil
        end
        local stage = display.getCurrentStage()
        for i = stage.numChildren, 1, -1 do
            if stage[i] ~= _button then
                stage[i]:removeSelf()
                stage[i] = nil
            end
        end
    end
    
    local function _runCode( event )
        if event.phase == "began" then
            _clearEverything()
            local code = _inputCode.getCode()
            if code then
                code = code:gsub( "local", "" )
                assert(loadstring( code ))()
                _button:toFront()                
            end
        end
        return true
    end
    
    _button = display.newImageRect( "images/button.png", 160, 48 )
    _button.anchorX, _button.anchorY = 0, 0
    _button.x, _button.y = display.screenOriginX+4, display.screenOriginY+4
    _button:addEventListener( "touch", _runCode )
end