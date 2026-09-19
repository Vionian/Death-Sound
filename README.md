# Death Sound

Death Sound replaces teammate downed and death sounds with local audio files.
It includes the required `SimpleAudio` runtime and does not require a separate
audio-library mod.

## Installation

1. Copy the `Death Sound` folder into the game's `mods` directory.
2. Put downed sounds in `Death Sound/audio/downed/` and death sounds in
   `Death Sound/audio/dead/`.
3. Restart the game after adding files so the settings dropdown can scan them.

Supported extensions are `mp3`, `wav`, `ogg`, `flac`, `m4a`, `aac`, `wma`, `opus`, `mp4`, and `webm`.
Chinese filenames are supported, for example `audio/downed/倒地音效.mp3` and
`audio/dead/死亡音效.wav`.

The settings page contains separate controls for `Downed` and `Dead`. Each has
independent `self` and `teammate` switches, a volume slider, and two mutually
exclusive modes:

- `Fixed replacement` plays the selected file.
- `Random replacement` uses a shuffled bag. Every file is used once per round,
  so files have equal probability and the same file is not selected repeatedly
  until the round is exhausted.

The fixed file dropdown is shown under the fixed mode control and only lists
files from that event's folder. Turning off `self` affects only the local
player; it does not change the teammate switch. The teammate filter targets
human-controlled teammates; bots keep their normal voice.

Selecting a fixed sound automatically plays a short preview. Changing another
setting or entering a mission stops the preview.
