local levels = {
     -- Heist #1
    {
        player = {x=700,y=500},
        guard = {
            {
                x=300,
                y=300,
                route = {
                    {r=180,delay=500,time=500},
                    {x=200,y=300,delay=500},
                    {r=0,delay=500,time=500},
                    {x=300,y=300,r=0,delay=500}
                }
            }
        },
        camera = {
            {x=300,y=500,time=3500,rotation=0,angle=120}
        },
        loot = {
            {x=400,y=500,rotation=15}
        },
        map = {
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","wall_32","wall_40","wall_40","wall_40","wall_40","wall_7","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","wall_34","floor","floor","floor","floor","wall_34","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","wall_32","wall_40","wall_40","wall_40","wall_40","wall_40","wall_7","empty","empty","empty","wall_35","floor","floor","floor","floor","wall_34","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","wall_34","floor","floor","floor","floor","floor","wall_35","empty","empty","empty","floor","floor","floor","floor","floor","wall_34","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","wall_34","floor","floor","floor","floor","floor","floor","empty","empty","empty","wall_8","floor","floor","floor","floor","wall_34","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","wall_34","floor","floor","floor","floor","floor","wall_8","empty","empty","empty","wall_43","wall_40","wall_40","wall_40","wall_40","wall_33","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","wall_34","floor","floor","wall_8","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","wall_34","floor","floor","wall_34","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","wall_43","wall_40","wall_40","wall_46","wall_40","wall_40","wall_33","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        },
    },
     -- Heist #2
    {
        player = {x=700,y=500},
        guard = {
            {
                x=300,
                y=300,
                route = {
                    {r=180,delay=500,time=500},
                    {x=200,y=300,delay=500},
                    {r=0,delay=500,time=500},
                    {x=300,y=300,r=0,delay=500}
                }
            }
        },
        camera = {
            {x=300,y=500,time=3500,rotation=0,angle=120}
        },
        loot = {
            {x=400,y=500,rotation=15}
        },
        map = {
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","wall_32","wall_2","wall_40","wall_40","wall_40","wall_40","wall_7","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","wall_8","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","wall_32","wall_40","wall_40","wall_40","wall_40","wall_40","wall_7","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","wall_34","floor","floor","floor","floor","floor","wall_35","empty","empty","empty","wall_34","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","wall_34","floor","floor","floor","floor","floor","floor","empty","empty","empty","wall_35","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","wall_34","floor","floor","floor","floor","floor","wall_8","empty","empty","empty","floor","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","wall_34","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","wall_8","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","wall_43","wall_40","wall_40","wall_40","wall_40","wall_40","wall_33","empty","empty","empty","wall_34","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","wall_43","wall_40","wall_40","wall_40","wall_40","wall_40","wall_33","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_32","wall_40","wall_40","wall_40","wall_47","floor","wall_2","wall_7","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_34","floor","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_34","floor","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_34","floor","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_43","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_33","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        },
    },
     -- Heist #3
    {
        player = {x=700,y=500},
        guard = {
            {
                x=300,
                y=300,
                route = {
                    {r=180,delay=500,time=500},
                    {x=200,y=300,delay=500},
                    {r=0,delay=500,time=500},
                    {x=300,y=300,r=0,delay=500}
                }
            }
        },
        camera = {
            {x=300,y=500,time=3500,rotation=0,angle=120}
        },
        loot = {
            {x=400,y=500,rotation=15}
        },
        map = {
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","wall_32","wall_40","wall_40","wall_40","wall_40","wall_3","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_3","wall_40","wall_40","wall_40","wall_40","wall_7","empty","empty","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","floor","floor","wall_34","floor","floor","floor","floor","floor","floor","floor","floor","wall_34","floor","floor","floor","floor","wall_34","empty","empty","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","floor","floor","wall_34","floor","floor","floor","floor","floor","floor","floor","floor","wall_34","floor","floor","floor","floor","wall_34","empty","empty","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","floor","floor","wall_34","floor","floor","floor","floor","floor","floor","floor","floor","wall_34","floor","floor","floor","floor","wall_34","empty","empty","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","floor","floor","wall_34","floor","floor","wall_2","wall_40","wall_40","wall_47","floor","floor","wall_34","floor","floor","floor","floor","wall_34","empty","empty","empty","empty"},
        	{"empty","empty","wall_15","wall_47","floor","floor","wall_2","wall_33","floor","floor","floor","floor","floor","floor","floor","floor","wall_43","wall_47","floor","floor","wall_2","wall_28","empty","empty","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty"},
        	{"empty","empty","wall_43","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_7","floor","floor","wall_32","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_33","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","wall_34","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","wall_34","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","wall_34","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","wall_35","floor","floor","wall_35","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        },
    },
     -- Heist #4
    {
        player = {x=700,y=500},
        guard = {
            {
                x=300,
                y=300,
                route = {
                    {r=180,delay=500,time=500},
                    {x=200,y=300,delay=500},
                    {r=0,delay=500,time=500},
                    {x=300,y=300,r=0,delay=500}
                }
            }
        },
        camera = {
            {x=300,y=500,time=3500,rotation=0,angle=120}
        },
        loot = {
            {x=400,y=500,rotation=15}
        },
        map = {
        	{"empty","empty","empty","empty","empty","empty","empty","empty","wall_2","wall_40","wall_40","wall_7","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","floor","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","wall_32","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_47","floor","wall_43","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_3","wall_40","wall_40","wall_7","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","wall_35","floor","floor","wall_34","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","wall_34","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","wall_32","wall_40","wall_40","wall_40","wall_40","wall_7","floor","floor","floor","floor","floor","floor","floor","floor","floor","wall_8","floor","floor","wall_34","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","wall_35","floor","floor","floor","floor","wall_34","floor","floor","floor","floor","floor","floor","floor","floor","floor","wall_15","wall_40","wall_40","wall_28","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","wall_34","floor","floor","floor","floor","floor","floor","floor","floor","floor","wall_35","floor","floor","wall_34","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","wall_8","floor","floor","floor","floor","wall_34","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","wall_34","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","wall_43","wall_40","wall_40","wall_40","wall_40","wall_33","floor","floor","floor","floor","floor","floor","floor","floor","floor","wall_8","floor","floor","wall_34","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","wall_8","floor","wall_32","wall_40","wall_40","wall_40","wall_46","wall_40","wall_40","wall_33","empty","empty"},
        	{"empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","floor","wall_34","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","wall_43","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_33","floor","wall_35","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        },
    },
     -- Heist #5 (easter egg)
    {
        player = {x=700,y=500},
        guard = {
            {
                x=300,
                y=300,
                route = {
                    {r=180,delay=500,time=500},
                    {x=200,y=300,delay=500},
                    {r=0,delay=500,time=500},
                    {x=300,y=300,r=0,delay=500}
                }
            }
        },
        camera = {
            {x=300,y=500,time=3500,rotation=0,angle=120}
        },
        loot = {
            {x=400,y=500,rotation=15}
        },
        map = {
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","wall_32","wall_40","wall_40","wall_40","wall_7","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_32","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_7","empty","empty","empty","empty","empty","wall_34","floor","floor","floor","wall_34","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty","empty","wall_34","floor","floor","floor","wall_34","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty","empty","wall_34","floor","floor","floor","wall_34","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_34","floor","floor","wall_2","wall_40","wall_47","floor","floor","wall_34","empty","empty","empty","empty","empty","wall_43","wall_47","floor","wall_2","wall_33","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","wall_35","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","floor","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","wall_8","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_34","floor","floor","wall_2","wall_40","wall_47","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_34","floor","floor","floor","floor","floor","floor","floor","wall_34","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","wall_43","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_40","wall_33","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        	{"empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty","empty"},
        },
    },
}

return levels