--
-- created with TexturePacker - https://www.codeandweb.com/texturepacker
--
-- $TexturePacker:SmartUpdate:0666b44928a87f82bded97cf523c736d:84507287d39f4eee6c08c727aee17bf0:fb0165af34cca3914cec437d67311edd$
--
-- local sheetInfo = require("mysheet")
-- local myImageSheet = graphics.newImageSheet( "mysheet.png", sheetInfo:getSheet() )
-- local sprite = display.newSprite( myImageSheet , {frames={sheetInfo:getFrameIndex("sprite")}} )
--

local SheetInfo = {}

SheetInfo.sheet =
{
    frames = {
    
        {
            -- walkLeft1
            x=1,
            y=1,
            width=60,
            height=100,

        },
        {
            -- walkLeft2
            x=1,
            y=103,
            width=60,
            height=100,

        },
        {
            -- walkLeft3
            x=1,
            y=205,
            width=60,
            height=100,

        },
        {
            -- walkLeft4
            x=1,
            y=307,
            width=60,
            height=100,

        },
        {
            -- walkRight1
            x=1,
            y=409,
            width=60,
            height=100,

        },
        {
            -- walkRight2
            x=1,
            y=511,
            width=60,
            height=100,

        },
        {
            -- walkRight3
            x=1,
            y=613,
            width=60,
            height=100,

        },
        {
            -- walkRight4
            x=1,
            y=715,
            width=60,
            height=100,

        },
    },

    sheetContentWidth = 62,
    sheetContentHeight = 816
}

SheetInfo.frameIndex =
{

    ["walkLeft1"] = 1,
    ["walkLeft2"] = 2,
    ["walkLeft3"] = 3,
    ["walkLeft4"] = 4,
    ["walkRight1"] = 5,
    ["walkRight2"] = 6,
    ["walkRight3"] = 7,
    ["walkRight4"] = 8,
}

function SheetInfo:getSheet()
    return self.sheet;
end

function SheetInfo:getFrameIndex(name)
    return self.frameIndex[name];
end

return SheetInfo
