# Gone Diggin'
The Gone Diggin' is my COMPO entry for Ludum Dare 48. The theme is "Deeper and deeper".
The game's Ludum Dare page is: TBD

## Overall rating
TBD

# Playable HTML5 version
A playable HTML5 version of the game can be found at https://www.xedur.com/demos/gone-diggin/.

# Closing thoughts
TBD

## Own thoughts for later
Used circular graphics to hide the weird and snappy ring movement beneath them (i.e. masking without using masks). Similarly used particle effects to hide the instant appearance of the segment the player moves to. Also used bitmask tile system, but since the player's movement was restricted to only left, right and down, the types of shapes that the player could do were limited. Finally, the world generation guarantees that each ring/layer has an impassable rock, which prevents the player from entering a segment they've been at from a previously unvisited segment, which further eased the bitmasking operations.

***

XeduR / Eetu Rantanen
