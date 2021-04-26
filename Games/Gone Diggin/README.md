# Gone Diggin'
The Gone Diggin' is my COMPO entry for Ludum Dare 48. The theme is "Deeper and deeper".
The game's Ludum Dare page is: https://ldjam.com/events/ludum-dare/48/gone-diggin

## Overall rating
TBD

# Playable HTML5 version
A playable HTML5 version of the game can be found at https://www.xedur.com/demos/gone-diggin/.

# Closing thoughts
TBD

## Own thoughts for later
Used circular graphics to hide the weird and snappy ring movement beneath them (i.e. masking without using masks). Similarly used particle effects to hide the instant appearance of the segment the player moves to. Also used bitmask tile system, but since the player's movement was restricted to only left, right and down, the types of shapes that the player could do were limited. Finally, the world generation guarantees that each ring/layer has an impassable rock, which prevents the player from entering a segment they've been at from a previously unvisited segment, which further eased the bitmasking operations.

I'm also genuinely impressed at how the floorboards turned out. I created the floorboard part for one of the 14 tiles several hours before the deadline, but I finished the remaining ones a few minutes before the deadline. I had no time to test them, but they were, in my opinion, the perfect finishing touch. They added extra sense of depth to the game and made the pseudo 3D element pop out. When I started on this project, I wasn't intending to create a "circular world" like this, nor did I have any plans for pseudo 3D. That part just kinda happened during the literal final minute as I added the new path tiles with the floorboards and "it just looked like that."

***

XeduR / Eetu Rantanen
