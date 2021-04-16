local M = {}

function M.get( t )
    local xVariance = t and t.xVariance or 480
    local angle = t and t.angle or 90
    local speed = t and t.speed or 140
    local absolutePosition = t and t.absolutePosition or false

    local snowParams = {
        minRadius = 0,
        maxRadius = 0,
        duration = -1,
        tangentialAcceleration = 0,
        emitterType = 0,
        radialAcceleration = 0,
        rotatePerSecondVariance = 0,
        speed = speed,
        maxParticles = 400,
        finishColorRed = 1,
        startColorVarianceBlue = 0.2,
        startParticleSize = 4,
        angleVariance = 4,
        rotationStart = 0,
        startColorBlue = 1,
        yCoordFlipped = -1,
        textureFileName = "images/snow.png",
        startColorVarianceGreen = 0,
        finishColorVarianceRed = 0,
        angle = angle,
        finishColorVarianceGreen = 0,
        startParticleSizeVariance = 2,
        tangentialAccelVariance = 0,
        finishColorVarianceAlpha = 0,
        radialAccelVariance = 0,
        speedVariance = 39,
        rotationStartVariance = 0,
        rotationEndVariance = 0,
        gravityy = -40,
        startColorVarianceRed = 0,
        finishParticleSizeVariance = 0,
        rotatePerSecond = 0,
        maxRadiusVariance = 0,
        finishColorVarianceBlue = 0,
        particleLifespan = 2,
        startColorRed = 1,
        finishColorGreen = 1,
        particleLifespanVariance = 0,
        blendFuncSource = 770,
        sourcePositionVariancey = 160,
        startColorVarianceAlpha = 0.2,
        blendFuncDestination = 771,
        minRadiusVariance = 0,
        finishColorBlue = 1,
        finishParticleSize = 4,
        startColorAlpha = 0.34,
        gravityx = 0,
        rotationEnd = 0,
        sourcePositionVariancex = xVariance,
        startColorGreen = 1,
        finishColorAlpha = 0,
        absolutePosition = absolutePosition
    }
    return snowParams
end

return M
