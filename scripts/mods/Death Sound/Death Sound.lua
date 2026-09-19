local mod = get_mod("Death Sound")
local Audio

local supported_extensions = {
	"mp3",
	"wav",
	"ogg",
	"flac",
	"m4a",
	"aac",
	"wma",
	"opus",
	"mp4",
	"webm",
}

local audio_files = {
	downed = {},
	dead = {},
}
local random_bags = {
	downed = {},
	dead = {},
}
local players = {}
local mode_guard = false
local preview_play_id
local warned_no_audio = {
	downed = false,
	dead = false,
}

local function valid_unit(unit)
	if unit and Unit.alive(unit) then
		return unit
	end

	return nil
end

local function copy_files(source)
	local copy = {}

	for i, file_name in ipairs(source) do
		copy[i] = file_name
	end

	return copy
end

local function reset_random_bags()
	for kind in pairs(random_bags) do
		random_bags[kind] = {}
	end
end

local function refresh_audio_files(kind)
	local files = {}
	local seen = {}

	if not Audio or not Audio.glob then
		return
	end

	for _, extension in ipairs(supported_extensions) do
		local ok, result = pcall(Audio.glob, kind .. "/*." .. extension)

		if ok and result then
			local matched = result:list()

			for _, file_name in ipairs(matched) do
				local key = string.lower(file_name)

				if not seen[key] then
					seen[key] = true
					files[#files + 1] = file_name
				end
			end
		end
	end

	table.sort(files, function(a, b)
		return string.lower(a) < string.lower(b)
	end)
	audio_files[kind] = files
	warned_no_audio[kind] = false
	reset_random_bags()
end

local function random_file(kind)
	local bag = random_bags[kind]
	local files = audio_files[kind] or {}

	if #bag == 0 then
		bag = copy_files(files)

		-- Fisher-Yates gives every permutation the same probability. Files are
		-- consumed from the bag, so a full round cannot repeat a file.
		for i = #bag, 2, -1 do
			local j = math.random(1, i)
			bag[i], bag[j] = bag[j], bag[i]
		end

		random_bags[kind] = bag
	end

	local index = #bag
	local file_name = bag[index]
	bag[index] = nil

	return file_name
end

local function contains_file(kind, file_name)
	if type(file_name) ~= "string" or file_name == "" then
		return false
	end

	for _, available_file in ipairs(audio_files[kind] or {}) do
		if string.lower(available_file) == string.lower(file_name) then
			return true
		end
	end

	return false
end

local function is_fixed(kind)
	local fixed = mod:get(kind .. "_sfx_mode_fixed")
	local random = mod:get(kind .. "_sfx_mode_random", false) == true

	if fixed == nil then
		return not random
	end

	return fixed == true
end

local function selected_file(kind)
	local files = audio_files[kind] or {}

	if #files == 0 then
		if not warned_no_audio[kind] then
			mod:error("Death Sound: no supported audio files were found in audio/" .. kind .. ".")
			warned_no_audio[kind] = true
		end

		return nil
	end

	warned_no_audio[kind] = false

	if is_fixed(kind) then
		local configured_file = mod:get(kind .. "_sfx_file", "")

		if contains_file(kind, configured_file) then
			return configured_file
		end

		return files[1]
	end

	return random_file(kind)
end

local function stop_kind(slot, kind)
	local field = "playing_" .. kind
	local play_id = slot[field]

	if play_id and Audio and Audio.is_file_playing and Audio.is_file_playing(play_id) then
		Audio.stop_file(play_id)
	end

	slot[field] = nil
end

local function stop_all(reset_status)
	for _, slot in pairs(players) do
		stop_kind(slot, "downed")
		stop_kind(slot, "dead")

		if reset_status then
			slot.status = nil
		end
	end
end

local function stop_preview()
	if preview_play_id and Audio and Audio.is_file_playing and Audio.is_file_playing(preview_play_id) then
		Audio.stop_file(preview_play_id)
	end

	preview_play_id = nil
end

local function should_play_for_slot(slot, kind)
	if slot.itsme then
		-- The self toggle is independent from the teammate toggle.
		return mod:get(kind .. "_sfx_onlyme", true) == true
	end

	return mod:get(kind .. "_sfx_teammate", true) == true and not slot.bot
end

local function play_preview(kind)
	stop_preview()

	if not Audio then
		return
	end

	local file_name = mod:get(kind .. "_sfx_file", "")

	if not contains_file(kind, file_name) then
		return
	end

	local volume = tonumber(mod:get(kind .. "_sfx_volume", 100)) or 100
	local play_id

	play_id = Audio.play_file(file_name, {
		audio_type = "sfx",
		volume = volume,
		duration = 5,
		on_finished = function(id)
			if preview_play_id == id then
				preview_play_id = nil
			end
		end,
	})

	if play_id then
		preview_play_id = play_id
	end
end

local function update_playback(slot, kind, play_id)
	if slot["playing_" .. kind] ~= play_id then
		return
	end

	local expected_status = kind == "dead" and "dead" or "downed"

	if slot.status ~= expected_status then
		stop_kind(slot, kind)
		return
	end

	local unit = valid_unit(slot.unit)

	if unit and Audio and Audio.set_position then
		Audio.set_position(play_id, unit, 0.025, 8)
	end
end

local function playback_finished(slot, kind, play_id)
	local field = "playing_" .. kind

	if not play_id or slot[field] == play_id then
		slot[field] = nil
	end
end

local function play_kind(slot, kind, unit)
	if mod:get(kind .. "_sfx_toggle", true) ~= true or not Audio or not should_play_for_slot(slot, kind) then
		return
	end

	if slot["playing_" .. kind] then
		return
	end

	local file_name = selected_file(kind)

	if not file_name then
		return
	end

	slot.unit = unit
	local volume = tonumber(mod:get(kind .. "_sfx_volume", 100)) or 100
	local play_id

	play_id = Audio.play_file(file_name, {
		audio_type = "sfx",
		volume = volume,
		on_update = function(id)
			update_playback(slot, kind, id)
		end,
		on_finished = function(id)
			playback_finished(slot, kind, id)
		end,
	}, valid_unit(unit), 0.025, 8)

	if play_id then
		slot["playing_" .. kind] = play_id
	end
end

local function normalize_modes(kind, changed_setting)
	if mode_guard then
		return
	end

	local fixed_setting = kind .. "_sfx_mode_fixed"
	local random_setting = kind .. "_sfx_mode_random"
	local fixed = mod:get(fixed_setting, true) == true
	local random = mod:get(random_setting, false) == true

	mode_guard = true

	if changed_setting == fixed_setting and fixed then
		mod:set(random_setting, false)
	elseif changed_setting == random_setting and random then
		mod:set(fixed_setting, false)
	elseif not fixed and not random then
		-- Keep one mode active so the two checkboxes behave like radio buttons.
		if changed_setting == fixed_setting then
			mod:set(random_setting, true)
		else
			mod:set(fixed_setting, true)
		end
	end

	mode_guard = false
	reset_random_bags()
	stop_preview()
	stop_all(true)
end

local function player_slot(player_id)
	if not player_id then
		return nil
	end

	if not players[player_id] then
		players[player_id] = {
			status = "alive",
		}
	end

	return players[player_id]
end

local function process_player_panel(panel)
	local data = panel and panel._data
	local player = data and data.player
	local player_id = player and player._unique_id
	local slot = player_slot(player_id)

	if not slot then
		return
	end

	local local_player
	local ok = pcall(function()
		local_player = Managers.player:local_player(1)
	end)
	slot.itsme = ok and local_player and local_player._unique_id == player_id or false

	local human_controlled = true
	local human_ok = pcall(function()
		human_controlled = player:is_human_controlled()
	end)
	slot.bot = human_ok and not human_controlled or false

	local dead = panel._player_status == "dead" or panel._dead == true
	local downed = not dead and (panel._player_status == "knocked_down" or panel._knocked_down == true)
	local status = dead and "dead" or downed and "downed" or "alive"

	if slot.status == status then
		return
	end

	slot.status = status
	slot.unit = valid_unit(player.player_unit)

	if status == "dead" then
		stop_kind(slot, "downed")
		play_kind(slot, "dead", slot.unit)
	elseif status == "downed" then
		stop_kind(slot, "dead")
		play_kind(slot, "downed", slot.unit)
	else
		stop_kind(slot, "downed")
		stop_kind(slot, "dead")
	end
end

mod:hook_safe(CLASS.HudElementPersonalPlayerPanel, "_update_player_features", process_player_panel)
mod:hook_safe(CLASS.HudElementTeamPlayerPanel, "_update_player_features", process_player_panel)

mod.on_all_mods_loaded = function()
	local ok, audio_or_error = pcall(function()
		return mod:io_dofile("Death Sound/scripts/mods/Death Sound/simpleaudio/simpleaudio")
	end)

	if ok then
		Audio = audio_or_error
	else
		mod:error(mod:localize("audio_initialize_failed", audio_or_error))
	end

	if not Audio then
		return
	end

	refresh_audio_files("downed")
	refresh_audio_files("dead")
end

mod.update = function(dt)
	if Audio and Audio.update then
		Audio.update(dt)
	end
end

mod.on_setting_changed = function(setting_name)
	if setting_name == "downed_sfx_mode_fixed" or setting_name == "downed_sfx_mode_random" then
		normalize_modes("downed", setting_name)
	elseif setting_name == "dead_sfx_mode_fixed" or setting_name == "dead_sfx_mode_random" then
		normalize_modes("dead", setting_name)
	elseif setting_name == "downed_sfx_file" then
		stop_all(true)
		play_preview("downed")
	elseif setting_name == "dead_sfx_file" then
		stop_all(true)
		play_preview("dead")
	else
		stop_preview()
		stop_all(true)
	end
end

mod:hook_safe(CLASS.StateGameplay, "on_enter", function()
	stop_preview()
	refresh_audio_files("downed")
	refresh_audio_files("dead")
	players = {}
end)

mod:hook_safe(CLASS.StateGameplay, "on_exit", function()
	stop_preview()
	stop_all()
	players = {}
end)

mod.on_unload = function()
	stop_preview()
	stop_all()

	if Audio and Audio.shutdown then
		Audio.shutdown()
		Audio = nil
	end
end
