local mod = get_mod("Death Sound")

-- Load the bundled audio adapter while building the settings list. If the
-- native runtime is unavailable, the runtime code will still use its fallback.
local function audio_options(folder)
	local files = {}
	local seen = {}
	local extensions = { "mp3", "wav", "ogg", "flac", "m4a", "aac", "wma", "opus", "mp4", "webm" }
	local audio_mod

	pcall(function()
		audio_mod = mod:io_dofile("Death Sound/scripts/mods/Death Sound/simpleaudio/simpleaudio")
	end)

	if audio_mod and audio_mod.glob then
		for _, extension in ipairs(extensions) do
			local ok, result = pcall(audio_mod.glob, folder .. "/*." .. extension)

			if ok and result then
				local matched = result.list and result:list() or {}

				for _, file_name in ipairs(matched) do
					local key = string.lower(file_name)

					if not seen[key] then
						seen[key] = true
						files[#files + 1] = file_name
					end
				end
			end
		end
	end

	table.sort(files, function(a, b)
		return string.lower(a) < string.lower(b)
	end)

	local options = {}

	for _, file_name in ipairs(files) do
		options[#options + 1] = {
			text = file_name,
			value = file_name,
		}
	end

	if #options == 0 then
		options[1] = {
			text = mod:localize("no_audio_files"),
			value = "",
		}
	end

	return options
end

local downed_options = audio_options("downed")
local dead_options = audio_options("dead")

local function file_widget(setting_id, options)
	return {
		setting_id = setting_id,
		title = setting_id,
		type = "dropdown",
		default_value = options[1].value,
		options = options,
	}
end

local widgets = {
	{
		setting_id = "downed_sfx_toggle",
		title = "downed_sfx_toggle",
		type = "checkbox",
		default_value = true,
		sub_widgets = {
			{
				setting_id = "downed_sfx_onlyme",
				title = "downed_sfx_onlyme",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "downed_sfx_teammate",
				title = "downed_sfx_teammate",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "downed_sfx_volume",
				title = "downed_sfx_volume",
				type = "numeric",
				default_value = 100,
				range = { 1, 300 },
			},
			{
				setting_id = "downed_sfx_mode_fixed",
				title = "downed_sfx_mode_fixed",
				type = "checkbox",
				default_value = true,
				sub_widgets = {
					file_widget("downed_sfx_file", downed_options),
				},
			},
			{
				setting_id = "downed_sfx_mode_random",
				title = "downed_sfx_mode_random",
				type = "checkbox",
				default_value = false,
			},
		},
	},
	{
		setting_id = "dead_sfx_toggle",
		title = "dead_sfx_toggle",
		type = "checkbox",
		default_value = true,
		sub_widgets = {
			{
				setting_id = "dead_sfx_onlyme",
				title = "dead_sfx_onlyme",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "dead_sfx_teammate",
				title = "dead_sfx_teammate",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "dead_sfx_volume",
				title = "dead_sfx_volume",
				type = "numeric",
				default_value = 100,
				range = { 1, 300 },
			},
			{
				setting_id = "dead_sfx_mode_fixed",
				title = "dead_sfx_mode_fixed",
				type = "checkbox",
				default_value = true,
				sub_widgets = {
					file_widget("dead_sfx_file", dead_options),
				},
			},
			{
				setting_id = "dead_sfx_mode_random",
				title = "dead_sfx_mode_random",
				type = "checkbox",
				default_value = false,
			},
		},
	},
}

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = widgets,
	},
}
