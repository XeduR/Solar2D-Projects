# rng.lua

A small, dependency-free pseudorandom number generator for Lua. Given the same seed, it produces identical sequences on every platform. Lua's built-in `math.random`'s output depends on the C runtime and can differ across operating systems and builds.

Pure Lua with no external dependencies beyond the standard `math` library, so it drops into any Lua project (Solar2D, other engines, plain Lua, etc.) unchanged.

## Why

Lua 5.1's `math.random` wraps the platform C `rand`, so the same `randomseed` can yield different sequences on different platforms. This module uses a fixed linear congruential generator (LCG) for reproducible results anywhere: procedural generation, replays, deterministic tests, and seeded content.

It is slower than `math.random` and it's not cryptographically secure. Its output is predictable by design, so never use it for anything that needs to be secure or remain a secret.

## Installation

Copy `rng.lua` into your project and require it:

```lua
local rng = require( "rng" )
```

## API

The call signatures mirror `math.random` / `math.randomseed`, so it works as a drop-in replacement.

### `rng.random( [x [, y]] )`

- No arguments: a fraction in `[0, 1)`.
- One argument: an integer in `[1, x]`.
- Two arguments: an integer in `[x, y]`.

Integer ranges are uniform (every value equally likely) and include both endpoints.

### `rng.randomseed( n )`

Sets the seed. `n` is rounded to the nearest non-negative integer. Non-number or non-finite values (NaN, infinity) are rejected with a warning and leave the current seed unchanged. The module starts from a fixed default seed, so it is deterministic out of the box; call `randomseed` to choose your own starting point.

### `rng.getSeed()`

Returns the current seed. Because the seed is the generator's entire state, pairing `getSeed` with `randomseed` lets you snapshot the sequence position and later resume it exactly. This is particularly useful if you want to, for instance, include the seed in your game's/app's save files.

## Example

```lua
local rng = require( "rng" )

rng.randomseed( 20250705 )

print( rng.random() ) -- fraction in [0, 1)
print( rng.random( 6 ) ) -- integer in [1, 6]
print( rng.random( 10, 20 ) ) -- integer in [10, 20]

-- Snapshot the position, then restore it to repeat the same sequence.
local saved = rng.getSeed()
local first = rng.random( 100 )
rng.randomseed( saved )
assert( rng.random( 100 ) == first )
```

## Author

[© 2020-2026 Eetu Rantanen](https://www.erantanen.com)

## License

MIT
