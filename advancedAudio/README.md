# advancedAudio.lua API Documentation

Advanced audio management library for Solar2D with channel management, priority system, and audio type categorization.

> **Note:** This library overwrites Solar2D's standard `audio.*` functions. Simply `require` it and use `audio.*` as normal.

## Roso Games Template note:

If the `useAdvancedAudio` property inside the `launchParams` table in main.lua is set to `true`, then this library is automatically loaded into the project. In order to disable it, you need to set the property to `false` (not recommended).

## Key Concepts

- **Filename-based handles:** Use filename strings (e.g., `"explosion.wav"`) instead of raw audio handles
- **Audio types:** Group channels by category (e.g., `"sfx"`, `"music"`, `"voice"`)
- **Priority system:** Higher priority sounds preempt lower priority ones when channels are full
- **32 channels:** Solar2D's fixed channel limit; all default to type `"all"`

---

## Setup

```lua
require( "advancedAudio" )

-- Assign channel ranges to types (optional but recommended)
audio.assignChannelTypes( 1, 4, "music" )
audio.assignChannelTypes( 5, 20, "sfx" )
audio.assignChannelTypes( 21, 32, "voice" )
```

---

## Loading Audio

### `audio.loadSound( filename [, directory] )`

Load sound effect(s) into memory. Accepts a single filename or a table of filenames.

```lua
audio.loadSound( "explosion.wav" )
audio.loadSound( { "hit1.wav", "hit2.wav", "hit3.wav" } )
audio.loadSound( "custom.wav", system.DocumentsDirectory )
```

### `audio.loadStream( filename [, directory] )`

Load audio stream(s) for longer files (music, ambient). Same signature as `loadSound`.

```lua
audio.loadStream( "bgm.mp3" )
audio.loadStream( { "ambient1.ogg", "ambient2.ogg" } )
```

---

## Playing Audio

### `audio.play( filename [, options] )`

Play a loaded audio file. Returns channel number or `0` on failure.

**Options:**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `type` | string | `"all"` | Audio type to use for channel selection |
| `priority` | number | `1` | Higher = more important (won't be preempted) |
| `volume` | number | `1` | Multiplier on top of type volume |
| `loops` | number | `0` | Number of loops (`-1` = infinite) |
| `onComplete` | function | `nil` | Callback when playback finishes |

```lua
-- Basic playback
audio.play( "explosion.wav" )

-- With options
audio.play( "bgm.mp3", {
    type = "music",
    priority = 10,
    loops = -1,
    volume = 0.8
} )

-- With completion callback
audio.play( "voice_line.wav", {
    type = "voice",
    priority = 5,
    onComplete = function( event )
        print( "Voice line finished on channel " .. event.channel )
    end
} )
```

**Channel allocation:** If no free channel exists for the requested type, the library stops the lowest-priority, oldest sound of that type.

---

## Stopping Audio

### `audio.stop( channelOrType )`

Stop audio by channel number or by type string.

```lua
audio.stop( 5 )         -- Stop channel 5
audio.stop( "sfx" )     -- Stop all SFX channels
audio.stop()            -- Stop all (standard behavior)
```

### `audio.stopWithDelay( duration, options )`

Stop with fade-out delay. `options` can be a table with `channel` key or a type string.

```lua
audio.stopWithDelay( 1000, { channel = 3 } )  -- Fade out channel 3 over 1 second
audio.stopWithDelay( 500, "music" )           -- Fade out all music channels
```

---

## Volume Control

All volume functions accept either standard Solar2D options or a type string.

### `audio.setVolume( volume, options )`

```lua
audio.setVolume( 0.5, { channel = 1 } )  -- Set channel 1 to 50%
audio.setVolume( 0.7, "music" )          -- Set all music channels to 70%
```

### `audio.getVolume( options )`

```lua
local vol = audio.getVolume( { channel = 1 } )
local musicVol = audio.getVolume( "music" )
```

### `audio.setMaxVolume( volume, options )` / `audio.setMinVolume( volume, options )`

Same pattern—pass type string to affect all channels of that type.

### `audio.getMaxVolume( options )` / `audio.getMinVolume( options )`

Returns value from first channel of the specified type.

---

## Channel Type Management

### `audio.assignChannelTypes( firstChannel, lastChannel, audioType )`

Assign a range of channels to an audio type. Returns `true` on success.

```lua
audio.assignChannelTypes( 1, 4, "music" )
audio.assignChannelTypes( 5, 28, "sfx" )
audio.assignChannelTypes( 29, 32, "voice" )
```

---

## Utility Functions

### `audio.getDuration( filename )`

```lua
local ms = audio.getDuration( "bgm.mp3" )
```

### `audio.rewind( filenameOrChannel )`

```lua
audio.rewind( "bgm.mp3" )
audio.rewind( 3 )
```

### `audio.seek( time, filenameOrChannel )`

```lua
audio.seek( 5000, "bgm.mp3" )  -- Seek to 5 seconds
```

### `audio.dispose( filename )`

Unload a single audio file.

```lua
audio.dispose( "explosion.wav" )
```

### `audio.disposeAll()`

Unload all audio files.

---

## Debug Functions

### `audio.listChannelTypes()`

Print channel type assignments to console.

### `audio.listActiveChannels()`

Print currently playing channels with priority, filename, and elapsed time.

### `audio.listAudioHandles()`

Print all loaded audio filenames.

---

## Example: Complete Setup

```lua
require( "advancedAudio" )

-- Configure channels
audio.assignChannelTypes( 1, 2, "music" )
audio.assignChannelTypes( 3, 24, "sfx" )
audio.assignChannelTypes( 25, 32, "voice" )

-- Load audio
audio.loadStream( "bgm_main.mp3" )
audio.loadSound( { "shoot.wav", "hit.wav", "explode.wav" } )
audio.loadStream( "narrator_intro.ogg" )

-- Set type volumes (acts as master volume per category)
audio.setVolume( 0.6, "music" )
audio.setVolume( 1.0, "sfx" )
audio.setVolume( 0.9, "voice" )

-- Play music (high priority so it won't be interrupted)
audio.play( "bgm_main.mp3", { type = "music", priority = 100, loops = -1 } )

-- Play SFX (low priority, can be preempted if channels fill up)
audio.play( "shoot.wav", { type = "sfx", priority = 1 } )

-- Play voice (medium priority)
audio.play( "narrator_intro.ogg", {
    type = "voice",
    priority = 50,
    onComplete = function() print( "Narration done" ) end
} )
```
