local M = {}

function M.get( amount, size, lifespan )

    local fireParams = {
		minRadius = 0,
		maxRadius = 0,
		duration = -1,
		tangentialAcceleration = 0,
		emitterType = 0,
		radialAcceleration = 0,
		rotatePerSecondVariance = 0,
		speed = 40,
		maxParticles = amount,
		finishColorRed = 0,
		startColorVarianceBlue = 0,
		startParticleSize = size,
		angleVariance = 10,
		rotationStart = 0,
		startColorBlue = 0.11,
		yCoordFlipped = -1,
		textureFileName = "images/fire.png",
		startColorVarianceGreen = 0,
		finishColorVarianceRed = 0,
		angle = -90,
		finishColorVarianceGreen = 0,
		startParticleSizeVariance = 10,
		tangentialAccelVariance = 0,
		finishColorVarianceAlpha = 0,
		radialAccelVariance = 0,
		speedVariance = 10,
		rotationStartVariance = 0,
		rotationEndVariance = 0,
		gravityy = 0,
		startColorVarianceRed = 0,
		finishParticleSizeVariance = 0,
		rotatePerSecond = 0,
		maxRadiusVariance = 0,
		finishColorVarianceBlue = 0,
		particleLifespan = lifespan,
		startColorRed = 0.75,
		finishColorGreen = 0,
		particleLifespanVariance = 0.25,
		blendFuncSource = 770,
		sourcePositionVariancey = 10,
		startColorVarianceAlpha = 0,
		blendFuncDestination = 1,
		minRadiusVariance = 0,
		finishColorBlue = 0,
		finishParticleSize = -1,
		startColorAlpha = 1,
		gravityx = 0,
		rotationEnd = 0,
		sourcePositionVariancex = 20,
		startColorGreen = 0.25,
		finishColorAlpha = 1,
        absolutePosition = true
	}

    return fireParams
end

return M
