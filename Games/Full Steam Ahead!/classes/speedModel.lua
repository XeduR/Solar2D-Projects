-- Boat speed, furnace fire level and captain anger for one run.

local speedModel = {}

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local modelMethods = {}
modelMethods.__index = modelMethods

--------------------------------------------------------------------------------------
-- Localised functions

local exp = math.exp
local min = math.min
local max = math.max

--------------------------------------------------------------------------------------
-- Public functions

function speedModel.new( config )
	local model = setmetatable( {}, modelMethods )

	model.config = config
	model.phase = config.phases[1]
	model.knots = 0
	model.peakKnots = 0
	model.angerReferenceKnots = 0
	model.fireLevel = 0
	model.anger = 0
	model.hasShovelled = false
	model.isAngerFrozen = false
	model.fired = false

	return model
end

-- Anger measures slowdowns against this reference speed, so resetting it means a phase switch or a frozen stretch never counts as slowing down.
function modelMethods:rebaseAnger()
	self.angerReferenceKnots = self.knots
end

function modelMethods:setPhase( phase )
	self.phase = self.config.phases[phase]
	self:rebaseAnger()
end

function modelMethods:shovel()
	local config = self.config

	self.knots = min( config.maxKnots, self.knots * self.phase.growth + config.firstShovelKnots )
	self.peakKnots = max( self.peakKnots, self.knots )
	self.angerReferenceKnots = max( self.angerReferenceKnots, self.knots )
	self.fireLevel = min( 1, self.fireLevel + config.fireGain )
	self.hasShovelled = true
end

function modelMethods:updateAnger( dt )
	local config = self.config
	local threshold = self.angerReferenceKnots * ( 1 - config.angerTolerance )

	if self.knots < threshold then
		local deficit = 1 - self.knots / threshold
		local rate = config.angerFillMin + ( config.angerFillMax - config.angerFillMin ) * deficit

		self.anger = min( 1, self.anger + rate * dt )

		if self.anger >= 1 then
			self.fired = true
		end
	else
		self.anger = max( 0, self.anger - config.angerDrain * dt )
	end
end

function modelMethods:update( dt )
	self.knots = self.knots * exp( -self.phase.decay * dt )
	self.fireLevel = self.fireLevel * exp( -self.config.fireDecay * dt )

	-- Firing is final, so anger stays full once it gets there.
	if self.hasShovelled and not self.isAngerFrozen and not self.fired then
		self:updateAnger( dt )
	end
end

function modelMethods:setAngerFrozen( isFrozen )
	if self.isAngerFrozen and not isFrozen then
		self:rebaseAnger()
	end

	self.isAngerFrozen = isFrozen
end

function modelMethods:getKnots()
	return self.knots
end

function modelMethods:getPeakKnots()
	return self.peakKnots
end

function modelMethods:getFireLevel()
	return self.fireLevel
end

function modelMethods:getAnger()
	return self.anger
end

function modelMethods:getAngerTier()
	local tierThresholds = self.config.angerTiers
	local tier = 0

	for i = 1, #tierThresholds do
		if self.anger >= tierThresholds[i] then
			tier = i
		end
	end

	return tier
end

function modelMethods:isFired()
	return self.fired
end

function modelMethods:hasEscaped()
	return self.knots >= self.config.escapeKnots
end

return speedModel
