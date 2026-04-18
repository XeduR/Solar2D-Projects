-- CRT/scanlines filter shader for Solar2D.

-- CRT post-process filter: barrel distortion, scanlines, shadow mask,
-- chromatic aberration, rolling hum bar and vignette.

--[[
	How to use:

	local crtShader = require( "assets.shaders.crt_shader" )
	crtShader.define()

	local snapshot = display.newSnapshot( width, height )
	snapshot.fill.effect = "filter.custom.crt"

	local fx = snapshot.fill.effect
	fx.scanlineIntensity = 0.35    -- [0..1] darkness of scanlines (default 0.35)
	fx.scanlineCount = 240         -- [1..2000] scanline pairs across the image (default 240)
	fx.distortion = { 0.08, 0.35 } -- { curvature [0..0.5], vignette [0..1] }
	fx.roll = { 0.25, 0.3 }        -- { strength [0..1] (0 = off), speed in cycles/s }
]]

local crtShader = {}

--------------------------------------------------------------------------------------
-- Forward declarations & variables

local shaderDefined = false

--------------------------------------------------------------------------------------
-- Private functions

local function buildKernel()
	local kernel = {}
	kernel.language = "glsl"
	kernel.category = "filter"
	kernel.name = "crt"

	kernel.uniformData = {
		{
			name = "scanlineIntensity",
			default = 0.35,
			min = 0,
			max = 1,
			type = "scalar",
			index = 0, -- u_UserData0
		},
		{
			name = "scanlineCount",
			default = 240,
			min = 1,
			max = 2000,
			type = "scalar",
			index = 1, -- u_UserData1
		},
		{
			name = "distortion",
			default = { 0.08, 0.35 }, -- curvature, vignette
			min = { 0, 0 },
			max = { 0.5, 1 },
			type = "vec2",
			index = 2, -- u_UserData2
		},
		{
			name = "roll",
			default = { 0.25, 0.3 }, -- strength, speed
			min = { 0, -10 },
			max = { 1, 10 },
			type = "vec2",
			index = 3, -- u_UserData3
		},
	}

	kernel.fragment = [[
uniform P_DEFAULT float u_UserData0; // scanlineIntensity
uniform P_DEFAULT float u_UserData1; // scanlineCount
uniform P_DEFAULT vec2 u_UserData2;  // distortion = (curvature, vignette)
uniform P_DEFAULT vec2 u_UserData3;  // roll = (strength, speed)

// Barrel distortion: push UVs outward towards the edges so the image appears
// bulged like the surface of a CRT tube.
P_UV vec2 curveUV( P_UV vec2 uv, P_DEFAULT float amount )
{
	uv = uv * 2.0 - 1.0;
	P_UV vec2 offset = uv.yx * uv.yx * amount;
	uv = uv + uv * offset;
	return uv * 0.5 + 0.5;
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
	P_UV vec2 uv = curveUV( texCoord, u_UserData2.x );

	// Anything pushed outside the unit square by the curvature is dead bezel.
	if ( uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 ) {
		return CoronaColorScale( vec4( 0.0, 0.0, 0.0, 1.0 ) );
	}

	// Chromatic aberration: per-channel horizontal offset that grows with
	// distance from the screen centre.
	P_DEFAULT float aberration = 0.0025 * length( uv - 0.5 );
	P_COLOR float r = texture2D( CoronaSampler0, uv + vec2( aberration, 0.0 ) ).r;
	P_COLOR float g = texture2D( CoronaSampler0, uv ).g;
	P_COLOR float b = texture2D( CoronaSampler0, uv - vec2( aberration, 0.0 ) ).b;
	P_COLOR vec3 color = vec3( r, g, b );

	// Scanlines: cosine brightness modulation along Y.
	P_DEFAULT float scan = cos( uv.y * u_UserData1 * 6.2831853 );
	scan = 0.5 + 0.5 * scan;
	color = color * ( 1.0 - u_UserData0 * ( 1.0 - scan ) );

	// Aperture grille / shadow mask: tint each screen pixel column towards
	// R, G or B in a repeating 3-column pattern (uses gl_FragCoord so the
	// mask stays crisp regardless of UV scale or curvature).
	P_DEFAULT float maskX = mod( gl_FragCoord.x, 3.0 );
	P_COLOR vec3 mask;
	if ( maskX < 1.0 ) {
		mask = vec3( 1.20, 0.95, 0.95 );
	} else if ( maskX < 2.0 ) {
		mask = vec3( 0.95, 1.20, 0.95 );
	} else {
		mask = vec3( 0.95, 0.95, 1.20 );
	}
	color = color * mask;

	// Rolling hum bar: a smooth horizontal brightness band scrolling over
	// time, mimicking mains hum / vsync beat on analog sets.
	// roll.x = strength (0 disables), roll.y = cycles per second; positive
	// speed rolls downward, negative rolls upward.
	P_DEFAULT float rollY = fract( uv.y - CoronaTotalTime * u_UserData3.y );
	P_DEFAULT float rollD = rollY - 0.5;
	P_DEFAULT float bar = exp( -rollD * rollD * 64.0 );
	color = color * ( 1.0 + u_UserData3.x * bar );

	// Vignette: quadratic falloff from the centre of the curved image.
	P_UV vec2 vig = uv - 0.5;
	P_DEFAULT float v = 1.0 - dot( vig, vig ) * u_UserData2.y * 3.0;
	color = color * clamp( v, 0.0, 1.0 );

	return CoronaColorScale( vec4( color, 1.0 ) );
}
]]

	return kernel
end

--------------------------------------------------------------------------------------
-- Public functions

function crtShader.define()
	if shaderDefined then return end
	graphics.defineEffect( buildKernel() )
	shaderDefined = true
end

return crtShader
