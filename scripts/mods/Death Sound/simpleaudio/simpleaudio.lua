-- Internal SimpleAudio adapter. The implementation is vendored so Death Sound
-- can be installed as one mod without registering a second dependency mod.
local mod = get_mod("Death Sound")
local persistent = mod:persistent_table("death_sound_internal_audio")

if persistent.api then
	return persistent.api
end

local file_glob = mod:io_dofile("Death Sound/scripts/mods/Death Sound/simpleaudio/file/glob")
local file_info = mod:io_dofile("Death Sound/scripts/mods/Death Sound/simpleaudio/file/info")
local native_runtime = mod:io_dofile("Death Sound/scripts/mods/Death Sound/simpleaudio/runtime/native")
local file_playback = mod:io_dofile("Death Sound/scripts/mods/Death Sound/simpleaudio/playback/file")

local initialized, initialize_error = native_runtime.initialize()

if not initialized then
	local error_message = mod:localize("audio_initialize_failed", initialize_error)
	mod:error(error_message)
	error(error_message)
end

local audio = {}

audio.play_file = file_playback.play_file
audio.set_position = file_playback.set_position
audio.stop_file = native_runtime.stop
audio.is_file_playing = native_runtime.is_playing
audio.glob = file_glob.glob
audio.file_info = file_info.file_info
audio.update = native_runtime.update
audio.shutdown = function()
	native_runtime.shutdown()
	persistent.api = nil
end
persistent.api = audio

return audio
