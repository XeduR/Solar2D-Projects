local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

local screen = require("classes.screen")

local launchParams = {}
local logoGroup = display.newGroup()
logoGroup.alpha = 0

---------------------------------------------------------------------------

function scene:create( event )
	local sceneGroup = self.view
	sceneGroup:insert( logoGroup )

	if event.params then
		-- Assign values to launchParams.
		for i, v in pairs( event.params ) do
			launchParams[i] = v
		end
	end

	-- Create the logo image (if defined).
	local filename = launchParams.logoFilename
	if filename then
		local width = launchParams.logoWidth or launchParams.logoHeight or 100
		local height = launchParams.logoHeight or width

		local logo = display.newImageRect( logoGroup, filename, width, height )
		logo.x, logo.y = screen.centerX + (launchParams.logoOffsetX or 0), screen.centerY + (launchParams.logoOffsetY or 0)
		logo.anchorX = launchParams.logoAnchorX or 0.5
		logo.anchorY = launchParams.logoAnchorY or 0.5
	end

	-- Create the footer/copyright text (if defined).
	local text = launchParams.text
	if text then
		local options =
		{
			parent = logoGroup,
			text = text,
			x = screen.centerX + (launchParams.textOffsetX or 0),
			y = screen.maxY + (launchParams.textOffsetY or 0),
			width = launchParams.textWidth or screen.width,
			font = launchParams.font or native.systemFont,
			fontSize = launchParams.fontSize or 20,
			align = launchParams.textAlign or "right"
		}

		local copyrightText = display.newText( options )
		copyrightText.anchorX = launchParams.textAnchorX or 0.5
		copyrightText.anchorY = launchParams.textAnchorY or 0.5
	end
end

---------------------------------------------------------------------------

function scene:show( event )
	if event.phase == "did" then
		-- Reveal the logoGroup or skip directly to game scene.
		if launchParams.logo or launchParams.text then
			transition.to( logoGroup, {
				delay = launchParams.showDelay or 250,
				time = launchParams.showTime or 500,
				alpha = 1,
				transition = launchParams.showEasing or easing.inOut,
				onComplete = function()
					-- Hide the logo.
					transition.to( logoGroup, {
						delay = launchParams.hideDelay or 1250,
						time = launchParams.hideTime or 250,
						alpha = 0,
						transition = launchParams.hideEasing or easing.inOut,
						onComplete = function()
							composer.gotoScene( "scenes.game", {
								effect = "fade",
								time = 100,
								params = {
									usesSavedata = launchParams.usesSavedata,
								}
							} )
						end
					})
				end
			})
		else
			composer.gotoScene( "scenes.game", {
				params = {
					usesSavedata = launchParams.usesSavedata,
				}
			})
		end
	end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene