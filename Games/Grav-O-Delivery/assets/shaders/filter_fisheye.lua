-- Link to Corona's Shader Playground where the shader can be viewed: https://f25j6.app.goo.gl/MCLT

local kernel = {}
kernel.category = "filter"
kernel.name = "fisheye"

-- -- Shader code uses time environment variable CoronaTotalTime
-- kernel.isTimeDependent = true

--takes two properties, offX and offY.
--these are 0 to 1, where 1 is the width or height of the texture.
kernel.vertexData =
{
    {
        name = "offX",
        default = 0,
        min = 0,
        max = 1,
        index = 0,  -- This corresponds to "CoronaVertexUserData.x"
    },
    {
        name = "offY",
        default = 0,
        min = 0,
        max = 1,
        index = 1,  -- This corresponds to "CoronaVertexUserData.y"
    },
}

kernel.vertex =
[[
P_POSITION vec2 VertexKernel( P_POSITION vec2 position ) {
    return position;
}
]]

kernel.fragment =
[[
P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord ){
  lowp float PI = 3.14159;
  lowp float aperture = 178.0;
  lowp float apertureHalf = 0.5 * aperture * (PI / 180.0);
  lowp float maxFactor = sin(apertureHalf);

  lowp float offX = CoronaVertexUserData.x;
  lowp float offY = CoronaVertexUserData.y;

  lowp vec2 uv;
  lowp vec2 xy = 2.0 * texCoord.xy - 1.0;
  lowp float d = length(xy);


  if (d < (2.0-maxFactor)) {
    d = length(xy * maxFactor);
    lowp float z = sqrt(1.0 - d * d);
    lowp float r = atan(d, z) / PI;
    lowp float phi = atan(xy.y, xy.x);

    uv.x = r * cos(phi) + 0.5 + offX;
    uv.y = r * sin(phi) + 0.5 + offY;

  } else {
    lowp vec4 empty = vec4(0.0,0.0,0.0,0.0);
    return CoronaColorScale(empty);
  }

  P_COLOR vec4 c = texture2D(CoronaSampler0, uv);
  return CoronaColorScale(c);
}
]]

return kernel
