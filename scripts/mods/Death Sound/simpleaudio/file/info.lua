local mod = get_mod("Death Sound")

local native_runtime = mod:io_dofile("Death Sound/scripts/mods/Death Sound/simpleaudio/runtime/native")
local paths = mod:io_dofile("Death Sound/scripts/mods/Death Sound/simpleaudio/core/paths")

local file_info = {}

file_info.file_info = function(audio_path)
	if type(audio_path) ~= "string" then
		error(string.format("Audio file path must be a string, got %s", type(audio_path)))
	end

	local resolved_path = paths.resolve_audio_path(audio_path)
	local result, error_message = native_runtime.file_info(resolved_path)

	if not result then
		error(string.format("Failed to read audio file info for %s: %s", resolved_path, error_message))
	end

	return result
end

return file_info
