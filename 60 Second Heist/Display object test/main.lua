local getTimer = system.getTimer
local newRect = display.newRect
local newCircle = display.newCircle
local newPolygon = display.newPolygon
local newMesh = display.newMesh

-- mesh:translate( mesh.path:getVertexOffset() )  -- Translate mesh so that vertices have proper world coordinates
-- 
-- mesh.fill = { type="image", filename="cat.png" }
-- 
-- local vertexX, vertexY = mesh.path:getVertex( 3 )
-- mesh.path:setVertex( 3, vertexX, vertexY-10 )

local t = {}
local iterations = 10000
local x, y = display.contentCenterX, display.contentCenterY

-- Star shape copied from https://docs.coronalabs.com/api/library/display/newPolygon.html
local shape = { 0,-110, 27,-35, 105,-35, 43,16, 65,90, 0,45, -65,90, -43,15, -105,-35, -27,-35 }
-- local shape = {-20,-20,20,-20,20,20,-20,20}


local fill = {
    type = "image",
    filename = "fill.png"
}
display.setDefault( "textureWrapX", "repeat" )
display.setDefault( "textureWrapY", "repeat" )

for i = 1, iterations do
    -- t[i] = {}
end

local startTime = getTimer()

-- local rect = newRect( 0, 0, 100, 20 )

for i = 1, iterations do
    -- Creating all display objects is now equally fast.
    
    -- local obj =  newCircle( x, y, 20 )
    -- local obj =  newPolygon( x, y, shape )
    local obj =  display.newPolygon( x, y, shape )
    -- local obj =  newRect( x, y, 40, 40 )
    
    
    -- local obj = newMesh(
    --     {
    --         x = x,
    --         y = y,
    --         mode = "indexed",
    --         vertices = {
    --             0,0, 0,100, 50,10, 100,100, 100,0
    --         },
    --         indices = {
    --             1,2,3,
    --             2,3,4,
    --             3,4,5
    --         }
    --     }
    -- )
    
    
    obj.fill = fill
    obj.fill.scaleX = 128 / obj.width
    obj.fill.scaleY = 128 / obj.height
    obj:setFillColor(1,0,0)
    obj.strokeWidth = 2
    obj:setStrokeColor(0)
    -- 
    t[i] = obj
    -- rect:translate(0,0)
    -- rect.x, rect.y = 0, 0
end

print( "TIME:", getTimer()-startTime )