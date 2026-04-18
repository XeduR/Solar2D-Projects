# The Hunt for Red April

A sonar-based submarine stealth game made for [Ludum Dare 59](https://ldjam.com/).

The theme of LD59 is **Signal**.

## Premise

You command a lone submarine hunting an aircraft carrier escorted by a fleet of destroyers. The ocean is pitch black. Your only tool for seeing the world is sonar, but every ping you send reveals your position to the enemy.

The game started as a sub-vs-sub duel prototype and pivoted to a submarine-vs-surface-fleet design during the jam.

## How to play

- **WASD** to steer and throttle the submarine
- **Space** to emit a sonar ping (reveals terrain, ships, and depth charges, but alerts nearby destroyers)
- **Left click** to fire a torpedo

**Win** by torpedoing the carrier (one hit). **Lose** by getting caught in a depth charge blast or colliding with terrain.

Destroyers patrol the map and escort the carrier. When they detect you (via their own sonar or your ping), they chase your predicted position and drop depth charges. Torpedoes can also destroy destroyers to thin the escort.

## Background

I initially planned on developing a submarine vs submarine type of a duel game, but after finishing the first prototype, I figured it'd be too much work to get the pathfinding and dueling gameplay to work smoothly and feel engaging, so I pivoted to a bit more asymmetric approach.

![the-hunt-proto-1](the-hunt-proto-1.gif)

With ships, they don't need to path around the underwater terrain and I felt that their AI can be significantly simpler as they can just swarm the player's submarine.

## Tools

- [Solar2D](https://solar2d.com/)
- [Tiled](https://www.mapeditor.org/)

## License

Copyright 2026 Eetu Rantanen.
