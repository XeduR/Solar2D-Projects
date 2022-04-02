---

# Game Jam Template
This is a simple and straightforward game template that I personally use during game jams and with game prototypes.

This template features several convenience plugins, modules, libraries, etc. to make developing the project significantly easier and faster, such as preparing all audio files for easy use on launch and setting up other general (and development) use systems.

The template flows from main.lua → launchScreen.lua → game.lua. When working on the Solar2D Simulator, the launchScreen.lua scene is skipped.

You can use the launchScreen scene to add your own logo and copyright disclaimer. The game scene is all set up for you to start writing your game.

---

### Included plugins, modules, libraries, etc.
#### For general use:
- [Loadsave - Spyric](https://github.com/SpyricGames/Solar2D-Plugins-Public/blob/main/Loadsave/spyric/loadsave.lua)
- [Screen - Spyric](https://github.com/SpyricGames/Solar2D-Plugins-Public/blob/main/Screen/spyric/screen.lua)
- [SFX - XeduR](https://github.com/XeduR/Solar2D-Projects/blob/master/sfx/sfx.lua)
- [utils - XeduR](https://github.com/XeduR/Solar2D-Projects/blob/master/utils/utils.lua)

*To be added later (pending license changes)*
- Resolution - Spyric
- BitmapFont - Spyric
- ComposerX - Spyric
- JoyPad - Spyric

#### For development use:
- [eventListenerWrapper - XeduR](https://github.com/XeduR/Solar2D-Projects/blob/master/eventListenerWrapper/eventListenerWrapper.lua)
- [Performance Meter - XeduR](https://github.com/SpyricGames/Solar2D-Plugins-Public/blob/main/Performance/spyric/performance.lua)

---