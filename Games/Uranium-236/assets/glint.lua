-- Author: ponywolf (Michael Wilson)
-- source: https://gist.github.com/superqix/50b772c85c2471c69a88cab5bf1e9339

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
-- By default, the group is "custom"
--kernel.group = "custom"
kernel.name = "glint"
kernel.isTimeDependent = true

-- Expose effect parameters using vertex data
kernel.vertexData   = {
  {
    name = "intensity",
    default = 0.65, 
    min = 0,
    max = 1,
    index = 0,  -- This corresponds to "CoronaVertexUserData.x"
  },
  {
    name = "size",
    default = 0.1, 
    min = 0,
    max = 1,
    index = 1,  -- This corresponds to "CoronaVertexUserData.y"
  },
  {
    name = "tilt",
    default = 0.2, 
    min = 0.0,
    max = 2.0,
    index = 2,  -- This corresponds to "CoronaVertexUserData.z"
  },
  {
    name = "speed",
    default = 1.0, 
    min = 0.1,
    max = 10.0,
    index = 3,  -- This corresponds to "CoronaVertexUserData.w"
  },
}

kernel.fragment =
[[
P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    P_COLOR float intensity = CoronaVertexUserData.x;
    P_COLOR vec4 texColor = texture2D( CoronaSampler0, texCoord );
 
    // Grab a float from the total time * speed
    P_COLOR float glint = floor(20.0 * mod(CoronaVertexUserData.w * CoronaTotalTime, 2.0)) * 0.05;
    glint = glint + (CoronaVertexUserData.z * sin(texCoord.y - 0.5));
    
    // Calculate where the glint is at
    P_COLOR float size = CoronaVertexUserData.y * 0.5;
    intensity = (step(texCoord.x, glint + size) - step(texCoord.x, glint - size)) * intensity * texColor.a;
 
    // Add the intensity
    texColor.rgb += intensity;
 
    // Modulate by the display object's combined alpha/tint.
    return CoronaColorScale( texColor );
}
]]

graphics.defineEffect( kernel )