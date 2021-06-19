local loops = {

    -- loop #1
    {
        "0 -- move highlighted elements to",
        "0 -- places that will break the loop",
        "0",
        "0 while *true do",
        "1 print( *false )",
        "0 end",
    },

    -- loop #2
    {
        "0 -- there can be multiple loops",
        "0 Lua = \"awesome\"",
        "0",
        "0 while *true do",
        "1 print( \"this language is \".. *Lua )",
        "0 end",
        "0",
        "0 repeat",
        "1 local var = *true",
        "0 until var == *false",
    },

    -- loop #3
    {
        "0 -- it feels like this is looping",
        "0 *loop , *noloop = true, false",
        "0",
        "0 while loop do",
        "1 print( \"this is *not *magic \" )",
        "0 end",
        "0",
        "0 while *type ( noloop ) do",
        "1 print( \"or is it magic after all?\" )",
        "0 end",
    },

    -- loop #4
    {
        "0 -- this was created using solar2d",
        "0 -- (it's great *2 dimensions)",
        "0",
        "0 *limit = 1000000",
        "0 for n = *1 , limit do",
        "1 if n *+ *100 == *0 then",
        "2 break",
        "1 end",
        "0 end",
        "0",
        "0 -- here's some mathematical stuff:",
        "0 -- *% *- ** */ "
    },


    -- loop #5
    {
        "0 -- making these levels is much more",
        "0 -- time consuming than I expected.",
        "0",
        "0 s = \"definitely not lazy\"",
        "0 repeat",
        "1 dev = s:sub( *1 + *2 , *3 x *4 )",
        "1 print( dev )",
        "0 until dev == \"lazy\"",
        "0",
        "0 -- play with numbers, or something:",
        "0 -- *5 *6 *7 *8 *9 *10 *11 *12 *13 "
    },

}

return loops